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

//
// pthreads entry point for channel I/O.
//
void *NALChannelIO_Main(void *argv)
{
    PHYSICAL_CHANNEL instance = PHYSICAL_CHANNEL(argv);
    instance->IOThread();
    return NULL;
}


// ============================================
//               Physical Channel              
// ============================================

// constructor
PHYSICAL_CHANNEL_CLASS::PHYSICAL_CHANNEL_CLASS(
    PLATFORMS_MODULE     p,
    PHYSICAL_DEVICES d) :
        PLATFORMS_MODULE_CLASS(p)
{
    nallatechEdgeDevice = d->GetNallatechEdgeDevice();
}

// destructor
PHYSICAL_CHANNEL_CLASS::~PHYSICAL_CHANNEL_CLASS()
{
    pthread_cancel(ioThreadID);
    pthread_join(ioThreadID, NULL);
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

    // Enforce minimum numbers of write and read windows for the ring
    // buffer code.
    VERIFYX(NALLATECH_NUM_WRITE_WINDOWS >= 2);
    VERIFYX(NALLATECH_NUM_READ_WINDOWS >= 3);

    //
    // Initialize shared host/FPGA memory details.
    //
    for (int w = 0; w < NALLATECH_NUM_WRITE_WINDOWS; w++)
    {
        writeWindows[w].data = nallatechEdgeDevice->GetWriteWindow(w);
        VERIFYX(writeWindows[w].data != NULL);

        writeWindows[w].lock = 0;
        // Setting to 1 leaves space for the command word
        writeWindows[w].nWords = 1;
    }

    for (int w = 0; w < NALLATECH_NUM_READ_WINDOWS; w++)
    {
        readWindows[w].data = nallatechEdgeDevice->GetReadWindow(w);
        VERIFYX(readWindows[w].data != NULL);

        readWindows[w].nWords = 0;
        readWindows[w].nextReadWordIdx = 0;
    }

    curReadWindow = 0;
    curWriteWindow = 0;

    // Create the I/O thread
    writeWindows[0].lock = 1;  // I/O thread starts with a write window locked
    VERIFYX(pthread_create(&ioThreadID, NULL, &NALChannelIO_Main, (void *)this) == 0);
}


//
// NextWriteWindow in the ring of write windows.
//
inline
int PHYSICAL_CHANNEL_CLASS::NextWriteWindow(int curWindow)
{
    return ((curWindow + 1) == NALLATECH_NUM_WRITE_WINDOWS) ? 0 : curWindow + 1;
}


//
// NextReadWindow in the ring of read windows.  The last read window is
// reserved for the NULL read transaction.
//
inline
int PHYSICAL_CHANNEL_CLASS::NextReadWindow(int curWindow)
{
    return ((curWindow + 2) == NALLATECH_NUM_READ_WINDOWS) ? 0 : curWindow + 1;
}


//
// BufferedWordsRemaining has two main functions:
//
//     1.  Return the number of valid words left in the current read buffer.
//
//     2.  Detect an empty buffer and clear nWords.  This is the signal
//         to the I/O thread that the buffer is no longer in use and should
//         be filled again.  BufferedWordsRemaining() should be called only
//         when no code is using a pointer to the buffer.  E.g., any
//         pointers returned by RawReadBufferedWords() should no longer be
//         in use.
//
inline
UINT32
PHYSICAL_CHANNEL_CLASS::BufferedWordsRemaining()
{
    UINT32 n_words = readWindows[curReadWindow].nWords;
    UINT32 next_idx = readWindows[curReadWindow].nextReadWordIdx;

    if (next_idx < n_words)
    {
        return n_words - next_idx;
    }
    else if (n_words != 0)
    {
        //
        // This is a key case:  no data remains and the number of valid words
        // in the buffer is non-zero.  Set the number of valid words to 0.
        // This tells the I/O thread that the buffer is unused and should
        // be filled again.
        //
        CompareAndExchange(&readWindows[curReadWindow].nWords, n_words, 0);

        // Move on to the next read window
        curReadWindow = NextReadWindow(curReadWindow);

        return 0;
    }
    else
    {
        return 0;
    }
}


inline
const NALLATECH_WORD *
PHYSICAL_CHANNEL_CLASS::RawReadBufferedWords(int nWords)
{
    UINT32 r_idx = readWindows[curReadWindow].nextReadWordIdx;
    readWindows[curReadWindow].nextReadWordIdx = r_idx + nWords;

    return &(readWindows[curReadWindow].data[r_idx]);
}


// Raw stream of data from the FPGA.  Pass True for newMsg if the read request
// is for the start of a new read attempt.  It is used for managing the
// raw buffer size.
NALLATECH_WORD
PHYSICAL_CHANNEL_CLASS::TryRawReadNextWord()
{
    if (BufferedWordsRemaining() != 0)
    {
        return *RawReadBufferedWords(1);
    }

    return CHANNEL_RESPONSE_NODATA;
}


// Raw stream of data from the FPGA.  Pass True for newMsg if the read request
// is for the start of a new read attempt.  It is used for managing the
// raw buffer size.
NALLATECH_WORD
PHYSICAL_CHANNEL_CLASS::RawReadNextWord()
{
    //
    // Any data left in the current buffer?
    //
    while (true)
    {
        if (BufferedWordsRemaining() != 0)
        {
            return *RawReadBufferedWords(1);
        }

        CpuPause();
    }
}


// non-blocking read
UMF_MESSAGE
PHYSICAL_CHANNEL_CLASS::TryRead()
{
    //
    // See if we actually read any data.  The response will either be
    // 0 (CHANNEL_RESPONSE_NODATA) or the header of the next UMF message.
    // Headers are guaranteed non-zero by writing a 1 to the
    // phyChannelPvt field in the header encoding.
    //
    NALLATECH_WORD resp = TryRawReadNextWord();

    // Consume a chunk of NODATA responses to avoid looping through TryRead().
    while ((resp == CHANNEL_RESPONSE_NODATA) && (BufferedWordsRemaining() != 0))
    {
        resp = RawReadNextWord();
    }

    if (resp == CHANNEL_RESPONSE_NODATA)
    {
        // no data, cleanup and return NULL
        return NULL;
    }

    UMF_MESSAGE incomingMessage = new UMF_MESSAGE_CLASS;
    incomingMessage->DecodeHeader(resp);

    // copy buffer data into message data
    UINT32 n_chunks = incomingMessage->GetLength() / sizeof(UMF_CHUNK);
    while (n_chunks != 0)
    {
        UINT32 w_remaining = BufferedWordsRemaining();
        if (w_remaining != 0)
        {
            // Read as much data from the buffer as we can/want
            UINT32 read_chunks = min(n_chunks, w_remaining);
            incomingMessage->AppendChunks(read_chunks,
                                          (UMF_CHUNK*) RawReadBufferedWords(read_chunks));
            n_chunks -= read_chunks;
        }
        else
        {
            // Incoming buffer is empty.  Get more data.
            NALLATECH_WORD r = RawReadNextWord();
            incomingMessage->AppendChunks(1, (UMF_CHUNK*) &r);
            n_chunks -= 1;
        }
    }

    // Call bufferedWordsRemaining() one last time for its side effects:
    // release current read window if all data has been extracted.
    BufferedWordsRemaining();

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
    // Message chunks is the header + the actual message
    UINT32 msg_chunks = 1 + (message->GetLength() + sizeof(UMF_CHUNK) - 1) / sizeof(UMF_CHUNK);

    // sanity checks
    if (msg_chunks > NALLATECH_MAX_MSG_WORDS)
    {
        ASIMWARNING("message larger than maximum allowed length");
        CallbackExit(1);
    }

    //
    // Spin until we get a write window.  The I/O thread holds and releases
    // locks in an order that guarantees writes will stay in order.
    //
    bool first_pass = true;
    while (1)
    {
        if (CompareAndExchange(&writeWindows[curWriteWindow].lock, 0, 2))
        {
            // Is there enough space in the window?
            if (writeWindows[curWriteWindow].nWords + msg_chunks < NALLATECH_MAX_MSG_WORDS)
            {
                // Looks good
                goto got_window;
            }

            // Give up the lock.  The message doesn't fit.  Go on to the next
            // window.
            CompareAndExchange(&writeWindows[curWriteWindow].lock, 2, 0);
            curWriteWindow = NextWriteWindow(curWriteWindow);
        }
        else if (first_pass)
        {
            // On the first pass it is legal to skip to the next window if
            // the current one is locked.  This still preserves write
            // ordering.
            curWriteWindow = NextWriteWindow(curWriteWindow);
        }

        first_pass = false;
        CpuPause();
    }

  got_window:

    //
    // copy the message into the write window
    //

    int index = writeWindows[curWriteWindow].nWords;

    // construct header
    NALLATECH_WORD* window_data = writeWindows[curWriteWindow].data;
    window_data[index++] = message->EncodeHeaderWithPhyChannelPvt(1);

    // write message data to buffer
    // NOTE: hardware demarshaller expects chunk pattern to start from most
    //       significant chunk and end at least significant chunk, so we will
    //       send chunks in reverse order
    index += message->ReverseExtractAllChunks(&window_data[index]);

    writeWindows[curWriteWindow].nWords = index;
    VERIFYX(index <= NALLATECH_MAX_MSG_WORDS);

    // Unlock the window
    CompareAndExchange(&writeWindows[curWriteWindow].lock, 2, 0);

    delete message;
}


//
// GenCommand --
//     The command chunk at the head of a request to the FPGA.
//
inline NALLATECH_WORD
PHYSICAL_CHANNEL_CLASS::GenCommand(
    int h2fRawBufChunks,
    int f2hRawBufChunks,
    int waitForDataSpinCycles,
    bool f2hDataPermitted) const
{
    NALLATECH_WORD cmd;

    cmd = waitForDataSpinCycles;

    cmd <<= 1;
    cmd |= (f2hDataPermitted ? 1 : 0);

    cmd <<= 16;
    // Count excludes the leading command chunk
    cmd |= (h2fRawBufChunks - 1);

    cmd <<= 16;
    // Count excludes the trailing last useful data pointer
    cmd |= (f2hRawBufChunks - 1);

    return cmd;
}


//
// IOThread -- Separate thread handling actual I/O to the hardware.
//
void
PHYSICAL_CHANNEL_CLASS::IOThread()
{
    //
    // This thread starts owning write window 0.
    //
    int active_write_window = 0;
    int active_read_window = 0;

    //
    // Internal counters used for reducing the buffer size if it appears
    // too large.
    //
    UINT32 raw_io_cnt = 0;
    UINT32 raw_read_max_actual_size = 0;

    //
    // The size of the read window changes dynamically, depending on the size
    // of incoming data.  Larger buffers are more efficient but waste time if
    // they are just passing NULL.
    //
    UINT32 raw_read_buffer_size = NALLATECH_MIN_MSG_WORDS;

    //
    // Loop forever, managing all I/O to the FPGA.
    //
    while (true)
    {
        pthread_testcancel();

        //
        // Prepare the write window.  If data is in the write window it
        // will be sent to the FPGA whether or not there is also space for
        // reading data back at the same time.
        //
        UINT32 w_words = writeWindows[active_write_window].nWords;
        int raw_write_buffer_size = nallatechEdgeDevice->LegalBufSize(w_words);
        if (w_words < raw_write_buffer_size)
        {
            writeWindows[active_write_window].data[w_words] = 0;
        }

        // Clear the counter for the write window so the data is written
        // to the FPGA only once.  (1 leaves space for the command word.)
        writeWindows[active_write_window].nWords = 1;

        if (readWindows[active_read_window].nWords != 0)
        {
            //
            // The read window is busy.  Just write data to the FPGA.
            //
            writeWindows[active_write_window].data[0] =
                GenCommand(raw_write_buffer_size,
                           NALLATECH_MIN_MSG_WORDS,
                           0,
                           false);

            // Use the dummy read window
            nallatechEdgeDevice->DoAALTransaction(active_write_window,
                                                  raw_write_buffer_size,
                                                  NALLATECH_NUM_READ_WINDOWS - 1,
                                                  NALLATECH_MIN_MSG_WORDS);

            raw_io_cnt += 1;
        }
        else
        {
            //
            // Bidirectional data transfer.
            //

            // Maximum spin cycles to wait for FPGA-side write data.  Spin
            // when it appears only reads are happening.
            int spin_cycles = 0;
            if (w_words <= 1)
            {
                spin_cycles = NALLATECH_HW_TO_SW_SPIN_CYCLES;
            }

            //
            // Now all the details for the command word are ready.
            //
            writeWindows[active_write_window].data[0] =
                GenCommand(raw_write_buffer_size,
                           raw_read_buffer_size,
                           spin_cycles,
                           true);

            nallatechEdgeDevice->DoAALTransaction(active_write_window,
                                                  raw_write_buffer_size,
                                                  active_read_window,
                                                  raw_read_buffer_size);

            // The last slot in the returned message indicates the useful
            // data in the buffer.
            UINT32 n_words = readWindows[active_read_window].data[raw_read_buffer_size - 1];
            VERIFYX(n_words <= raw_read_buffer_size);

            if (n_words != 0)
            {
                //
                // Data arrived from the FPGA.
                //

                // Hand the read window off to the thread that extracts messages.
                readWindows[active_read_window].nextReadWordIdx = 0;
                CompareAndExchange(&readWindows[active_read_window].nWords, 0, n_words);

                // Was the buffer large enough?  If it was full then grow the
                // read buffer.
                if (n_words >= (raw_read_buffer_size - 1))
                {
                    raw_read_buffer_size = nallatechEdgeDevice->LegalBufSize(
                        raw_read_buffer_size + 2 * NALLATECH_MIN_MSG_WORDS);
                }

                //
                // Move on to the next read window.
                //
                active_read_window = NextReadWindow(active_read_window);

                // Track raw read sizes.  These will later be used to reduce
                // the read buffer size, if appropriate.
                raw_read_max_actual_size = max(raw_read_max_actual_size,
                                               n_words + 1);

                raw_io_cnt += 1;

                //
                // Short incoming messages indicate requests to RRR services
                // that expect responses.  It appears to improve performance a
                // bit to have this thread wait for a possible response from
                // the service monitoring thread to send back to the ACP.
                // This should be revisited.
                //
                if (n_words <= 2 * NALLATECH_MIN_MSG_WORDS)
                {
                    volatile int p = 100;
                    while (--p)
                    {
                        CpuPause();
                    }
                }
            }
        }


        //
        // Try to swap write window.  If the next window is locked just
        // stick with the current one.  It won't have any new write data
        // but can be used to receive new read data from the FPGA on
        // the next loop iteration.
        //

        // Grab the next window, so this thread owns two in a row.
        int next_write_window = NextWriteWindow(active_write_window);
        if (CompareAndExchange(&writeWindows[next_write_window].lock, 0, 1))
        {
            // Got it.  Give up the old window.
            CompareAndExchange(&writeWindows[active_write_window].lock, 1, 0);
            active_write_window = next_write_window;
        }


        // Does the buffer appear to be too large?  If a large buffer hasn't
        // been needed in a while, reduce it.
        if (raw_io_cnt > 500)
        {
            // Must decrease by more than 1/16th of current value to be
            // worth the risk
            if ((raw_read_buffer_size - raw_read_max_actual_size) >
                (raw_read_buffer_size >> 4))
            {
                raw_read_buffer_size = nallatechEdgeDevice->LegalBufSize(raw_read_max_actual_size);
            }

            raw_io_cnt = 0;
            raw_read_max_actual_size = 0;
        }

        CpuPause();
    }
}
