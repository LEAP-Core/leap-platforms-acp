//
// Copyright (C) 2008 Intel Corporation
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <sys/select.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>
#include <string.h>
#include <iostream>

#include "asim/provides/physical_channel.h"

using namespace std;

// ============================================
//               Physical Channel              
// ============================================

// constructor
PHYSICAL_CHANNEL_CLASS::PHYSICAL_CHANNEL_CLASS(
    PLATFORMS_MODULE     p,
    PHYSICAL_DEVICES d) :
        PLATFORMS_MODULE_CLASS(p)
{
    nallatechEdgeDevice  = d->GetNallatechEdgeDevice();
    incomingMessage = NULL;

    writeWindow = NULL;
    readWindow = NULL;

    alive = true; // LLPI bugfix

    pthread_mutex_init(&deviceLock, NULL);
}

// destructor
PHYSICAL_CHANNEL_CLASS::~PHYSICAL_CHANNEL_CLASS()
{
    alive = false; // LLPI bugfix
}

// init
void
PHYSICAL_CHANNEL_CLASS::Init()
{
    if (sizeof (UMF_CHUNK) != sizeof (NALLATECH_WORD))
    {
        ASIMERROR("UMF_CHUNK and NALLATECH_WORD size mismatch");
        CallbackExit(1);
    }    

    // assume Physical Device has been initialized by now
    writeWindow = nallatechEdgeDevice->GetInputWindow();
    readWindow = nallatechEdgeDevice->GetOutputWindow();

    ASSERTX(writeWindow != NULL && readWindow != NULL);
}

// non-blocking read
UMF_MESSAGE
PHYSICAL_CHANNEL_CLASS::TryRead()
{
    // LLPI bugfix
    if (!alive)
    {
        return NULL;
    }

    pthread_mutex_lock(&deviceLock);

    writeWindow[0] = CHANNEL_REQUEST_F2H;

    // talk to FPGA via Nallatech device
    nallatechEdgeDevice->DoAALTransaction(NALLATECH_TRANSFER_SIZE, NALLATECH_TRANSFER_SIZE);
    
    // see if we actually read any data
    NALLATECH_WORD resp = readWindow[0];

    if (resp == CHANNEL_RESPONSE_NODATA)
    {
        // no data, cleanup and return NULL
        pthread_mutex_unlock(&deviceLock);

        return NULL;
    }

    // sanity check
    if (resp != CHANNEL_RESPONSE_DATA)
    {
        pthread_mutex_unlock(&deviceLock);
        fprintf(stderr, "channel: TryRead: received junk response code: 0x%X\n", resp);
        CallbackExit(1);
    }

    // create a new message
    if (incomingMessage != NULL)
    {
        ASIMERROR("we should be handling entire messages at a time");
        CallbackExit(1);
    }

    incomingMessage = UMF_MESSAGE_CLASS::New();
    incomingMessage->DecodeHeader(readWindow[1]);

    // sanity check on message length
    if ((incomingMessage->GetLength()    +   // raw message length
         sizeof(UMF_CHUNK)               +   // header
         sizeof(NALLATECH_WORD))             // channel command
        > (NALLATECH_TRANSFER_SIZE * sizeof(NALLATECH_WORD)))
    {
        pthread_mutex_unlock(&deviceLock);
        ASIMERROR("tryread: message larger than maximum allowed length\n");
        CallbackExit(1);
    }

    // copy buffer data into message data
    incomingMessage->AppendChunks(incomingMessage->GetLength() / sizeof(UMF_CHUNK),
                                  (UMF_CHUNK*) &readWindow[2]);

    // done with the device, release it
    pthread_mutex_unlock(&deviceLock);

    // we should have a complete message by now
    if (incomingMessage->CanAppend())
    {
        ASIMERROR("we should be handling entire messages at a time");
        CallbackExit(1);
    }

    // all set
    UMF_MESSAGE msg = incomingMessage;
    incomingMessage = NULL;
    return msg;
}

// blocking read
UMF_MESSAGE
PHYSICAL_CHANNEL_CLASS::Read()
{
    //
    // TODO: Implement zero-copy by using the workspace storage directly
    // as message data storage instead of copying back and forth
    //

    UMF_MESSAGE msg;
    do
    {
        msg = TryRead();
    }
    while (msg == NULL);

    return msg;
}

// write
void
PHYSICAL_CHANNEL_CLASS::Write(
    UMF_MESSAGE message)
{
    //
    // TODO: Implement zero-copy by using the workspace storage directly
    // as message data storage instead of copying back and forth
    //

    // sanity checks
    if ((message->GetLength()    +   // raw message length
         sizeof(UMF_CHUNK)       +   // header
         sizeof(NALLATECH_WORD))     // channel command
        > (NALLATECH_TRANSFER_SIZE * sizeof(NALLATECH_WORD)))
    {
        ASIMERROR("message larger than maximum allowed length\n");
        message->Print(cout);
        CallbackExit(1);
    }

    //
    // copy the message into the write window
    //

    pthread_mutex_lock(&deviceLock);

    int index = 0;

    // write the channel command
    writeWindow[index++] = CHANNEL_REQUEST_H2F;

    // construct header
    message->EncodeHeader((unsigned char*) &writeWindow[index++]);

    // write message data to buffer
    // NOTE: hardware demarshaller expects chunk pattern to start from most
    //       significant chunk and end at least significant chunk, so we will
    //       send chunks in reverse order
    message->StartReverseExtract();
    while (message->CanReverseExtract())
    {
        UMF_CHUNK chunk = message->ReverseExtractChunk();
        writeWindow[index++] = chunk;
    }

    // ask the Nallatech device to send the message
    nallatechEdgeDevice->DoAALTransaction(NALLATECH_TRANSFER_SIZE, NALLATECH_TRANSFER_SIZE);

    // verify that we received the ack correctly
    NALLATECH_WORD ack = readWindow[0];
    if (ack != CHANNEL_RESPONSE_ACK)
    {
        pthread_mutex_unlock(&deviceLock);
        fprintf(stderr, "channel: Write: received incorrect Ack: 0x%X\n", ack);
        CallbackExit(1);
    }

    pthread_mutex_unlock(&deviceLock);

    message->Delete();
}
