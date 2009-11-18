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

    writeWindow = NULL;
    readWindow = NULL;

    alive = true; // LLPI bugfix

    rawReadBufferSize = NALLATECH_MIN_MSG_WORDS;
    nextRawReadPos = NALLATECH_MIN_MSG_WORDS;
    maxRawReadPos = 0;

    writeCount = 0;

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


// Raw stream of data from the FPGA.  Pass True for newMsg if the read request
// is for the start of a new read attempt.  It is used for managing the
// raw buffer size.
NALLATECH_WORD
PHYSICAL_CHANNEL_CLASS::RawReadNextWord(bool newMsg)
{
    // Internal counters used for reducing the buffer size if it appears
    // too large.
    static int raw_read_cnt = 0;
    static int raw_read_empty_cnt = 0;
    static int raw_read_max_actual_size = 0;

    if (nextRawReadPos < maxRawReadPos)
    {
        // More data left from previous transaction
        return readWindow[nextRawReadPos++];
    }

    if (! newMsg)
    {
        // Overflowed the raw buffer in the middle of a message.
        // Grow the buffer.
        rawReadBufferSize = nallatechEdgeDevice->LegalBufSize(rawReadBufferSize +
                                                              NALLATECH_MIN_MSG_WORDS);
        raw_read_cnt = 0;
    }

    // Need to get another chunk from the FPGA
    pthread_mutex_lock(&deviceLock);

    // talk to FPGA via Nallatech device
    writeWindow[0] = CHANNEL_REQUEST_F2H;

    // FPGA-side write buffer size
    writeWindow[1] = rawReadBufferSize - 1;

    // Maximum spin cycles to wait for FPGA-side write data.  This doesn't seem
    // to affect performance much.
    if (writeCount > (raw_read_cnt >> 1))
    {
        // Not mixing reads and writes
        writeWindow[2] = NALLATECH_HW_TO_SW_SPIN_CYCLES;
    }
    else 
    {
        // Mixed reads and writes.  No waiting on the hardware side.
        writeWindow[2] = 0;
    }

    nallatechEdgeDevice->DoAALTransaction(NALLATECH_MIN_MSG_WORDS, rawReadBufferSize);

    // The last slot in the returned message indicates the useful data in the
    // buffer.
    maxRawReadPos = readWindow[rawReadBufferSize - 1];
    VERIFYX((maxRawReadPos != 0) && (maxRawReadPos <= rawReadBufferSize));

    // Count failed read attempts
    if (maxRawReadPos <= 2)
    {
        raw_read_empty_cnt += 1;
    }
    else
    {
        raw_read_cnt += 1;
    }

    nextRawReadPos = 1;

    // Does the buffer appear to be too large?  If a large buffer hasn't been
    // needed in a while, reduce it.
    raw_read_max_actual_size = max(raw_read_max_actual_size, maxRawReadPos + 1);
    if ((raw_read_cnt + writeCount) > 5000)
    {
        // A lot of empty reads could indicate a need for a smaller buffer
        if ((raw_read_empty_cnt > 200) && (writeCount > 100))
        {
            rawReadBufferSize = nallatechEdgeDevice->LegalBufSize(rawReadBufferSize -
                                                                  NALLATECH_MIN_MSG_WORDS);
        }

        // Must decrease by more than 1/16th of current value to be worth the risk
        else if ((rawReadBufferSize - raw_read_max_actual_size) >
                 (rawReadBufferSize >> 4))
        {
            rawReadBufferSize = nallatechEdgeDevice->LegalBufSize(raw_read_max_actual_size);
        }

        raw_read_cnt = 0;
        raw_read_empty_cnt = 0;
        writeCount = 0;
    }

    pthread_mutex_unlock(&deviceLock);
    
    return readWindow[0];
}


inline
int
PHYSICAL_CHANNEL_CLASS::BufferedWordsRemaining()
{
    return (maxRawReadPos - nextRawReadPos);
}


inline
const NALLATECH_WORD *
PHYSICAL_CHANNEL_CLASS::RawReadBufferedWords(int nWords)
{
    const NALLATECH_WORD *r = &readWindow[nextRawReadPos];
    nextRawReadPos += nWords;

    return r;
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

    // see if we actually read any data
    NALLATECH_WORD resp = RawReadNextWord(true);

    // Consume a chunk of NODATA responses to avoid looping through TryRead().
    while ((resp == CHANNEL_RESPONSE_NODATA) && (BufferedWordsRemaining() != 0))
    {
        resp = RawReadNextWord(true);
    }

    if (resp == CHANNEL_RESPONSE_NODATA)
    {
        // no data, cleanup and return NULL
        return NULL;
    }

    // sanity check
    if (resp != CHANNEL_RESPONSE_DATA)
    {
        fprintf(stderr, "channel: TryRead: received junk response code: 0x%X\n", resp);
        CallbackExit(1);
    }

    UMF_MESSAGE incomingMessage = UMF_MESSAGE_CLASS::New();
    incomingMessage->DecodeHeader(RawReadNextWord(false));

    // copy buffer data into message data
    int n_chunks = incomingMessage->GetLength() / sizeof(UMF_CHUNK);
    while (n_chunks != 0)
    {
        if (BufferedWordsRemaining() != 0)
        {
            // Read as much data from the buffer as we can/want
            int read_chunks = min(n_chunks, BufferedWordsRemaining());
            incomingMessage->AppendChunks(read_chunks,
                                          (UMF_CHUNK*) RawReadBufferedWords(read_chunks));
            n_chunks -= read_chunks;
        }
        else
        {
            // Incoming buffer is empty.  Get more data.
            NALLATECH_WORD r = RawReadNextWord(false);
            incomingMessage->AppendChunks(1, (UMF_CHUNK*) &r);
            n_chunks -= 1;
        }
    }

    // we should have a complete message by now
    if (incomingMessage->CanAppend())
    {
        ASIMERROR("we should be handling entire messages at a time");
        CallbackExit(1);
    }

    return incomingMessage;
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
         sizeof(NALLATECH_WORD)  +   // buffer length following channel command
         sizeof(NALLATECH_WORD))     // channel command
        > (NALLATECH_MAX_MSG_WORDS * sizeof(NALLATECH_WORD)))
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

    // buffer length will be written later
    index++;

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

    // Messages are transferred in chunks.  Get the smallest legal chunk that
    // can hold this message.
    int msg_size = nallatechEdgeDevice->LegalBufSize(index);

    // Set the size in the message
    writeWindow[1] = msg_size - 2;

    // ask the Nallatech device to send the message
    NALLATECH_WORD ack = nallatechEdgeDevice->DoAALWriteTransaction(msg_size,
                                                                    NALLATECH_MIN_MSG_WORDS);

    writeCount += 1;

    pthread_mutex_unlock(&deviceLock);

    // verify that we received the ack correctly
    if (ack != CHANNEL_RESPONSE_ACK)
    {
        fprintf(stderr, "channel: Write: received incorrect Ack: 0x%X\n", ack);
        CallbackExit(1);
    }

    message->Delete();
}
