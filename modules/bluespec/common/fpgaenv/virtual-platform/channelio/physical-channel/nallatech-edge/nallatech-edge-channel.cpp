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
// Pseudo DMA is a bypass of the normal I/O stack to handle scratchpad I/O
// without having to copy the data.
//
int PHYSICAL_CHANNEL_CLASS::pseudoDMAChannelID = 0;
int PHYSICAL_CHANNEL_CLASS::pseudoDMAServiceID = 0;
PHYSICAL_CHANNEL_CLASS::PSEUDO_DMA_HANDLER PHYSICAL_CHANNEL_CLASS::pseudoDMAHandler = NULL;


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
    PLATFORMS_MODULE p)
    : PLATFORMS_MODULE_CLASS(p),
      correctedH2FErrs(0)
{
    nallatechEdgeDevice = new NALLATECH_EDGE_DEVICE_CLASS(p);
}

// destructor
PHYSICAL_CHANNEL_CLASS::~PHYSICAL_CHANNEL_CLASS()
{
    pthread_cancel(ioThreadID);
    pthread_join(ioThreadID, NULL);

    nallatechEdgeDevice->Uninit();
    delete nallatechEdgeDevice;

    if (correctedH2FErrs != 0)
    {
        cout << "Corrected host -> FPGA data errors: " << correctedH2FErrs << endl;
    }
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

    nallatechEdgeDevice->Init();

    // Enforce minimum numbers of write and read windows for the ring
    // buffer code.
    VERIFYX(NALLATECH_NUM_WRITE_WINDOWS >= 2);
    VERIFYX(NALLATECH_NUM_READ_WINDOWS >= 3);

    //
    // Initialize shared host/FPGA memory details.
    //
    for (int w = 0; w < NALLATECH_NUM_WRITE_WINDOWS; w++)
    {
        writeWindows[w].sharedBuf = nallatechEdgeDevice->GetWriteWindow(w);
        VERIFYX(writeWindows[w].sharedBuf != NULL);

        if (CHANNEL_H2F_FIX_ERRORS)
        {
            // Assume the host -> FPGA channel is lossy.  Check data will be
            // interleaved among the real data.  Messages are initially written
            // later in the buffer.  The buffer data will be interleaved with
            // check data before being written to the FPGA.
            writeWindows[w].data = &writeWindows[w].sharedBuf[NALLATECH_MAX_MSG_WORDS / NALLATECH_RAW_CHUNK_WORDS];
        }
        else
        {
            // No check data will be added.  Messages will be written directly
            // to the host -> FPGA shared memory buffer.
            writeWindows[w].data = writeWindows[w].sharedBuf;
        }
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


inline
const NALLATECH_WORD *
PHYSICAL_CHANNEL_CLASS::RawReadBufferPtr()
{
    UINT32 r_idx = readWindows[curReadWindow].nextReadWordIdx;
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
  repeat:

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


    //
    // Pseudo DMA:  Check an incoming request against the registered pseudo
    // DMA handler.  If it matches the message handling bypasses the normal
    // channel I/O path and is forwarded directly to the registered DMA handler.
    //
    UMF_MESSAGE_CLASS dummyHeader;
    dummyHeader.DecodeHeader(resp);

    UINT32 n_chunks = dummyHeader.GetLength() / sizeof(UMF_CHUNK);

    //
    // Only send a message through the pseudo-DMA path if the full message is
    // in the buffer.  Partial messages traverse the normal RRR path.
    //
    if ((pseudoDMAHandler != NULL) &&
        (dummyHeader.GetChannelID() == pseudoDMAChannelID) &&
        (dummyHeader.GetServiceID() == pseudoDMAServiceID) &&
        (n_chunks <= BufferedWordsRemaining()))
    {
        PSEUDO_DMA_READ_RESP resp;

        // Packet matches.  Call the handler...
        if ((*pseudoDMAHandler)(dummyHeader.GetMethodID(),
                                dummyHeader.GetLength(),
                                RawReadBufferPtr(),
                                resp))
        {
            //
            // Packet was processed by the handler.
            //
            RawReadBufferedWords(n_chunks);
            BufferedWordsRemaining();

            // Is there a response for the FPGA (DMA read)?
            if (resp != NULL)
            {
                WriteRaw(resp->header, resp->msgBytes, resp->msg);
            }

            // Get the next packet in the buffer instead of returning
            goto repeat;
        }
    }


    //
    // Normal (not pseudo-DMA) message flow...
    //

    UMF_MESSAGE incomingMessage = new UMF_MESSAGE_CLASS;
    incomingMessage->SetChannelID(dummyHeader.GetChannelID());
    incomingMessage->SetServiceID(dummyHeader.GetServiceID());
    incomingMessage->SetMethodID(dummyHeader.GetMethodID());
    incomingMessage->SetLength(dummyHeader.GetLength());

    // copy buffer data into message data
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


//
// MaxWriteWords --
//     Maximum words that may be written in a single burst.  The maximum changes
//     depending on whether check bits are being added to the message.
//
inline UINT32
PHYSICAL_CHANNEL_CLASS::MaxWriteWords() const
{
    UINT32 max_words;
    if (CHANNEL_H2F_FIX_ERRORS)
    {
        max_words = (NALLATECH_MAX_MSG_WORDS * (NALLATECH_RAW_CHUNK_WORDS - 1)) /
                    NALLATECH_RAW_CHUNK_WORDS;
    }
    else
    {
        max_words = NALLATECH_MAX_MSG_WORDS;
    }

    return max_words;
}


// Lock a window for writing at most msgChunks chunks
inline void
PHYSICAL_CHANNEL_CLASS::WriteLock(
    UINT32 msgBytes)
{
    // Message chunks is the header + the actual message
    UINT32 msg_chunks = 1 + (msgBytes + sizeof(UMF_CHUNK) - 1) / sizeof(UMF_CHUNK);

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
            if (writeWindows[curWriteWindow].nWords + msg_chunks < MaxWriteWords())
            {
                // Looks good
                return;
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
}

// Unlock the write window
inline void
PHYSICAL_CHANNEL_CLASS::WriteUnlock()
{
    CompareAndExchange(&writeWindows[curWriteWindow].lock, 2, 0);
}


// Write a UMF_MESSAGE to the FPGA
void
PHYSICAL_CHANNEL_CLASS::Write(
    UMF_MESSAGE message)
{
    WriteLock(message->GetLength());

    //
    // copy the message into the write window
    //

    int index = writeWindows[curWriteWindow].nWords;

    // construct header
    NALLATECH_WORD* window_data = writeWindows[curWriteWindow].data;
    window_data[index++] = message->EncodeHeaderWithPhyChannelPvt(1);

    // write message data to buffer
    index += message->ExtractAllChunks(&window_data[index]);

    writeWindows[curWriteWindow].nWords = index;
    VERIFYX(index <= NALLATECH_MAX_MSG_WORDS);

    delete(message);

    // Unlock the window
    WriteUnlock();
}


// Write a raw message (not encapsulated as a UMF_MESSAGE) to the FPGA.
void
PHYSICAL_CHANNEL_CLASS::WriteRaw(
    UMF_CHUNK header,
    UINT32 msgBytes,
    const void *msg)
{
    //
    // Compute the channel ID portion of a UMF header chunk the first time this
    // method is called.
    //
    static UMF_CHUNK header_with_channel_id;
    static bool did_init = false;
    if (! did_init)
    {
        did_init = true;

        UMF_MESSAGE_CLASS dummy_msg;
        dummy_msg.SetChannelID(0);
        dummy_msg.SetServiceID(0);
        dummy_msg.SetMethodID(0);
        dummy_msg.Clear();

        header_with_channel_id = dummy_msg.EncodeHeaderWithPhyChannelPvt(1);
    }

    // Lock the FPGA write buffer
    WriteLock(msgBytes);

    // Set the channel ID in the outgoing message header.
    header |= header_with_channel_id;

    int index = writeWindows[curWriteWindow].nWords;

    // Write the header
    NALLATECH_WORD* window_data = writeWindows[curWriteWindow].data;
    window_data[index++] = header;

    // Copy the message body.  Note that the message body source must have
    // the most significant chunk first.  (The usual way, as opposed to
    // the reversed order in UMF_CHUNKS.)
    memcpy(&window_data[index], msg, msgBytes);

    // Mark the current end of the buffer
    index += (msgBytes + sizeof(UMF_CHUNK) - 1) / sizeof(UMF_CHUNK);
    writeWindows[curWriteWindow].nWords = index;

    VERIFYX(index <= NALLATECH_MAX_MSG_WORDS);

    // Unlock the window
    WriteUnlock();
}


//
// GenCommand --
//     The command chunk at the head of a request to the FPGA.
//
inline void
PHYSICAL_CHANNEL_CLASS::GenCommand(
    int writeWindow,
    int h2fRawBufChunks,
    int f2hRawBufChunks,
    int waitForDataSpinCycles,
    bool f2hDataPermitted)
{
    NALLATECH_WORD cmd;

    cmd = waitForDataSpinCycles;

    cmd <<= 1;
    cmd |= (f2hDataPermitted ? 1 : 0);

    cmd <<= 16;

    // Check bits don't count toward the messages that must be read
    if (CHANNEL_H2F_FIX_ERRORS)
    {
        h2fRawBufChunks = (h2fRawBufChunks * (NALLATECH_RAW_CHUNK_WORDS - 1)) /
                          NALLATECH_RAW_CHUNK_WORDS;
    }
    // Count excludes the leading command chunk
    cmd |= (h2fRawBufChunks - 1);

    cmd <<= 16;
    // Count excludes the trailing last useful data pointer
    cmd |= (f2hRawBufChunks - 1);

    writeWindows[writeWindow].sharedBuf[0] = cmd;

    // Fix check bits
    if (CHANNEL_H2F_FIX_ERRORS)
    {
        //
        // Check bits are a simple checksum.  Fix the checksum for the first
        // chunk.  See IOThread() below for more details.
        //
        NALLATECH_WORD *msg = writeWindows[writeWindow].sharedBuf;
        NALLATECH_WORD check_bits = 0;

        for (int w = 0; w < NALLATECH_RAW_CHUNK_WORDS - 1; w++)
        {
            check_bits += *msg++;
        }

        *msg = check_bits;
    }
}


//
// InsertCheckBits --
//     For lossy host -> FPGA channels, insert a checksum in every chunk
//     being written.  A simple checksum is chosen because the size of I/O
//     buffers has relatively little effect on latency compared to time spent
//     running instructions and the latency of the work to start an I/O
//     transaction.  A compact CRC would require much more time to compute.
//
inline UINT32
PHYSICAL_CHANNEL_CLASS::InsertCheckBits(
    int activeWriteWindow,
    UINT32 inBufWords)
{
    int chunk_idx = 0;
    NALLATECH_WORD *m_src = writeWindows[activeWriteWindow].data;
    NALLATECH_WORD *m_dst = writeWindows[activeWriteWindow].sharedBuf;
    NALLATECH_WORD check_bits = 0;

    //
    // Check bits are very simple:  one word in every raw chunk is
    // a checksum of the other words in the chunk.  That way the FPGA
    // side needs no extra buffering.
    //
    for (UINT32 w = 0; w < inBufWords; w++)
    {
        NALLATECH_WORD s = *m_src++;
        *m_dst++ = s;
        check_bits += s;

        if (++chunk_idx == NALLATECH_RAW_CHUNK_WORDS - 1)
        {
            *m_dst++ = check_bits;
            check_bits = 0;
            chunk_idx = 0;
        }
    }

    // Finish the last chunk
    if (chunk_idx != 0)
    {
        while (++chunk_idx != NALLATECH_RAW_CHUNK_WORDS)
        {
            *m_dst++ = 0;
        }
        *m_dst++ = check_bits;
    }

    // Return the updated write buffer size.
    return m_dst - writeWindows[activeWriteWindow].sharedBuf;
}


//
// ClearSentWords --
//     For lossy host -> FPGA channels following an error, clear the portion
//     of the buffer sent correctly.  This appears to reduce the chances of
//     repeated errors.
//
inline void
PHYSICAL_CHANNEL_CLASS::ClearSentWords(
    int activeWriteWindow,
    UINT32 unsentBufWords)
{
    int chunk_idx = 0;
    NALLATECH_WORD *m_wrd = writeWindows[activeWriteWindow].sharedBuf;

    UINT32 clear_words = (writeWindows[activeWriteWindow].nWords *
                          (NALLATECH_RAW_CHUNK_WORDS - 1)) / NALLATECH_RAW_CHUNK_WORDS -
                         unsentBufWords;
    VERIFY(clear_words <= NALLATECH_MAX_MSG_WORDS,
           "Clear words too large: " << clear_words << ", " << unsentBufWords);

    // Clear data and check bits
    for (UINT32 w = 0; w < clear_words; w++)
    {
        *m_wrd++ = 0;

        if (++chunk_idx == NALLATECH_RAW_CHUNK_WORDS - 1)
        {
            *m_wrd++ = 0;
            chunk_idx = 0;
        }
    }

    // Finish the last chunk
    if (chunk_idx != 0)
    {
        NALLATECH_WORD check_bits = 0;

        while (++chunk_idx != NALLATECH_RAW_CHUNK_WORDS)
        {
            check_bits += *m_wrd++;
        }

        *m_wrd = check_bits;
    }
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
    // Flag for resending messages that arrived with errors.
    //
    bool h2f_resend = false;


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

        if (! h2f_resend)
        {
            // Message must end with a 0 to indicate EOM
            if (w_words < MaxWriteWords())
            {
                writeWindows[active_write_window].data[w_words++] = 0;
            }
        
            //
            // Adding check bits?
            //
            if (CHANNEL_H2F_FIX_ERRORS)
            {
                w_words = InsertCheckBits(active_write_window, w_words);
            }
        }

        int raw_write_buffer_size = nallatechEdgeDevice->LegalBufSize(w_words);
        UINT32 h2f_err_nack = 0;

        if (readWindows[active_read_window].nWords != 0)
        {
            //
            // The read window is busy.  Just write data to the FPGA.
            //
            if (writeWindows[active_write_window].nWords > 1)
            {
                GenCommand(active_write_window,
                           raw_write_buffer_size,
                           NALLATECH_MIN_MSG_WORDS,
                           0,
                           false);

                // Use the dummy read window
                nallatechEdgeDevice->DoAALTransaction(active_write_window,
                                                      raw_write_buffer_size,
                                                      NALLATECH_NUM_READ_WINDOWS - 1,
                                                      NALLATECH_MIN_MSG_WORDS);

                raw_io_cnt += 1;

                // Was there a data error?
                UINT32 resp = readWindows[NALLATECH_NUM_READ_WINDOWS - 1].data[NALLATECH_MIN_MSG_WORDS - 1];
                h2f_err_nack = (resp & 0xffff);
            }
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
            GenCommand(active_write_window,
                       raw_write_buffer_size,
                       raw_read_buffer_size,
                       spin_cycles,
                       true);

            nallatechEdgeDevice->DoAALTransaction(active_write_window,
                                                  raw_write_buffer_size,
                                                  active_read_window,
                                                  raw_read_buffer_size);

            // The last slot in the returned message indicates the useful
            // data in the buffer.
            UINT32 resp = readWindows[active_read_window].data[raw_read_buffer_size - 1];

            // The low 16 bits is the ACK/NACK for the host -> FPGA data being valid.
            // The value is the number of chunks not read from the correctly.
            h2f_err_nack = (resp & 0xffff);

            UINT32 n_words = resp >> 16;
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

        // Did the host -> FPGA message arrive intact?
        if (h2f_err_nack == 0)
        {
            // Host -> FPGA data written successfully
            writeWindows[active_write_window].nWords = 1;

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

            h2f_resend = false;
        }
        else
        {
            // Host -> FPGA data transmission error.  Resend the entire message.
            correctedH2FErrs += 1;
            writeWindows[active_write_window].nWords = raw_write_buffer_size;

            ClearSentWords(active_write_window, h2f_err_nack);

            h2f_resend = true;
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
    }
}


void
PHYSICAL_CHANNEL_CLASS::DebugState()
{
    int check = nallatechEdgeDevice->DebugRegRead(100);
    printf("Check value: 0x%04x (%s)\n", check,
            (check == 0x5309) ? "OK" : "WRONG!");

    printf("Last command: 0x%04x %04x %04x %04x\n",
            nallatechEdgeDevice->DebugRegRead(3),
            nallatechEdgeDevice->DebugRegRead(2),
            nallatechEdgeDevice->DebugRegRead(1),
            nallatechEdgeDevice->DebugRegRead(0));
    printf("Current READ state:  %d\n", nallatechEdgeDevice->DebugRegRead(4));
    printf("READ chunks left:    %d\n", nallatechEdgeDevice->DebugRegRead(6));
    printf("Current WRITE state: %d\n", nallatechEdgeDevice->DebugRegRead(5));
    printf("WRITE chunks left:   %d\n", nallatechEdgeDevice->DebugRegRead(7));

    int fifo_state = nallatechEdgeDevice->DebugRegRead(8);
    printf("readBuffer: %s full\n", (fifo_state & 1) ? "NOT" : "is");
    printf("writeDataQ: %s empty\n", (fifo_state & 2) ? "NOT" : "is");
    printf("\n");

    printf("Corrected errors:  %lld\n", correctedH2FErrs);
}


void
PHYSICAL_CHANNEL_CLASS::RegisterPseudoDMAHandler(
    int channelID,
    int serviceID,
    PSEUDO_DMA_HANDLER handler)
{
    pseudoDMAChannelID = channelID;
    pseudoDMAServiceID = serviceID;
    pseudoDMAHandler = handler;
}
