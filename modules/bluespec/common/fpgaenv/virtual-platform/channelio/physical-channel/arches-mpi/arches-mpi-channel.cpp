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

// TEMPORARY
#define BLOCK_SIZE UMF_CHUNK_BYTES

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
    archesMPIDevice  = d->GetArchesMPIDevice();
    incomingMessage = NULL;
}

// destructor
PHYSICAL_CHANNEL_CLASS::~PHYSICAL_CHANNEL_CLASS()
{
}

// blocking read
UMF_MESSAGE
PHYSICAL_CHANNEL_CLASS::Read()
{
    // blocking loop
    while (true)
    {
        // check if message is ready
        if (incomingMessage && !incomingMessage->CanAppend())
        {
            // message is ready!
            UMF_MESSAGE msg = incomingMessage;
            incomingMessage = NULL;
            return msg;
        }

        // block-read data from pipe
        readPipe();
    }

    // shouldn't be here
    return NULL;
}

// non-blocking read
UMF_MESSAGE
PHYSICAL_CHANNEL_CLASS::TryRead()
{
    // see if we already have a complete message
    if (incomingMessage && !incomingMessage->CanAppend())
    {
        UMF_MESSAGE msg = incomingMessage;
        incomingMessage = NULL;
        return msg;
    }

    // try to read a chunk from the device
    unsigned char chunk[UMF_CHUNK_BYTES];

    if (archesMPIDevice->TryRead(chunk, UMF_CHUNK_BYTES))
    {
        // determine if we are starting a new message
        if (incomingMessage == NULL)
        {
            // create a new message
            incomingMessage = UMF_MESSAGE_CLASS::New();
            incomingMessage->DecodeHeader(chunk);
        }
        else if (!incomingMessage->CanAppend())
        {
            // can't be here
        }
        else
        {
            // append read bytes into message
            incomingMessage->AppendBytes(UMF_CHUNK_BYTES, chunk);
        }
    }

    // now see if we have a complete message
    if (incomingMessage && !incomingMessage->CanAppend())
    {
        UMF_MESSAGE msg = incomingMessage;
        incomingMessage = NULL;
        return msg;
    }

    // message not yet ready
    return NULL;
}

// write
void
PHYSICAL_CHANNEL_CLASS::Write(
    UMF_MESSAGE message)
{
    // construct header
    unsigned char header[UMF_CHUNK_BYTES];
    message->EncodeHeader(header);

    // write header to pipe
    archesMPIDevice->Write(header, UMF_CHUNK_BYTES);

    // write message data to pipe
    // NOTE: hardware demarshaller expects chunk pattern to start from most
    //       significant chunk and end at least significant chunk, so we will
    //       send chunks in reverse order
    message->StartReverseExtract();
    while (message->CanReverseExtract())
    {
        UMF_CHUNK chunk = message->ReverseExtractChunk();
        archesMPIDevice->Write((unsigned char*)&chunk, sizeof(UMF_CHUNK));
    }

    // de-allocate message
    message->Delete();
}

// read un-processed data on the pipe
void
PHYSICAL_CHANNEL_CLASS::readPipe()
{
    // determine if we are starting a new message
    if (incomingMessage == NULL)
    {
        // new message: read header
        unsigned char header[UMF_CHUNK_BYTES];

        archesMPIDevice->Read(header, UMF_CHUNK_BYTES);

        // create a new message
        incomingMessage = UMF_MESSAGE_CLASS::New();
        incomingMessage->DecodeHeader(header);
    }
    else if (!incomingMessage->CanAppend())
    {
        // uh-oh.. we already have a full message, but it hasn't been
        // asked for yet. We will simply not read the pipe, but in
        // future, we might want to include a read buffer.
    }
    else
    {
        // read in some more bytes for the current message
        unsigned char buf[BLOCK_SIZE];
        int bytes_requested = BLOCK_SIZE;

        if (incomingMessage->BytesUnwritten() < BLOCK_SIZE)
        {
            bytes_requested = incomingMessage->BytesUnwritten();
        }

        archesMPIDevice->Read(buf, bytes_requested);

        // append read bytes into message
        incomingMessage->AppendBytes(bytes_requested, buf);
    }
}
