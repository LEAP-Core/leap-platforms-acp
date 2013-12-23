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

#ifndef __PHYSICAL_CHANNEL__
#define __PHYSICAL_CHANNEL__

#include "asim/provides/umf.h"
#include "asim/provides/nallatech_edge_device.h"
#include <pthread.h>


//
// Until real DMA is available we have a pseudo-DMA hack for faster processing
// of scratchpad memory references.  The scratchpad RRR service can register
// with this channel driver.  It will be called directly from the driver
// instead of having messages traverse the full channel I/O and RRR stack.
//
#define PSEUDO_DMA_ENABLED 1


// ============================================
//               Physical Channel              
// ============================================

typedef class PHYSICAL_CHANNEL_CLASS *PHYSICAL_CHANNEL;

class PHYSICAL_CHANNEL_CLASS: public PLATFORMS_MODULE_CLASS,
                              public TRACEABLE_CLASS
{
  private:
    // cached links to useful physical devices
    NALLATECH_EDGE_DEVICE nallatechEdgeDevice;
    
    // thread management
    pthread_t ioThreadID;

    //
    // System/FPGA shared memory window management
    //
    struct
    {
        NALLATECH_WORD* data;
        NALLATECH_WORD* sharedBuf;
        UINT32 lock;
        UINT32 nWords;
    }
    writeWindows[NALLATECH_NUM_WRITE_WINDOWS];

    struct
    {
        NALLATECH_WORD* data;
        UINT32 nWords;
        UINT32 nextReadWordIdx;
    }
    readWindows[NALLATECH_NUM_READ_WINDOWS];

    // Current read and write windows for RawReadNextWord(), etc.
    int curReadWindow;
    int curWriteWindow;

    // Walk through read/write buffers
    int NextReadWindow(int curWindow);
    int NextWriteWindow(int curWindow);

    // Stream of data coming from the FPGA
    UINT32 BufferedWordsRemaining();
    NALLATECH_WORD TryRawReadNextWord();
    NALLATECH_WORD RawReadNextWord();

    // Return nWords words from the current buffer.  nWords must be <=
    // BufferedWordsRemaining().
    const NALLATECH_WORD *RawReadBufferedWords(int nWords);
    const NALLATECH_WORD *RawReadBufferPtr();

    UINT32 MaxWriteWords() const;

    // Generate a command for passing data to the FPGA.
    void GenCommand(int writeWindow,
                    int h2fRawBufChunks,
                    int f2hRawBufChunks,
                    int waitForDataSpinCycles,
                    bool f2hDataPermitted);

    void WriteLock(UINT32 msgBytes);
    void WriteUnlock();
    void WriteRaw(UMF_CHUNK header, UINT32 msgBytes, const void *msg);

    UINT32 InsertCheckBits(int activeWriteWindow, UINT32 inBufWords);
    void ClearSentWords(int activeWriteWindow, UINT32 unsentBufWords);

    UINT64 correctedH2FErrs;

    void DebugState();

  public:

    PHYSICAL_CHANNEL_CLASS(PLATFORMS_MODULE);
    ~PHYSICAL_CHANNEL_CLASS();

    void Init();

    // interface
    UMF_MESSAGE Read();             // blocking read
    UMF_MESSAGE TryRead();          // non-blocking read
    void        Write(UMF_MESSAGE); // write

    // I/O management, run as a separate thread
    void IOThread();



    // ====================================================================
    //
    // Hack for a pseudo-DMA path for memory access that bypasses the
    // UMF / channel I/O / RRR stack.
    //
    // ====================================================================
  public:
    //
    // Read response from DMA handler the components of a UMF message.
    // The message will be copied directly to the buffer destined for
    // the FPGA.
    //
    typedef struct
    {
        UMF_CHUNK header;
        UINT32 msgBytes;
        const void *msg;
    }
    PSEUDO_DMA_READ_RESP_CLASS;
    typedef PSEUDO_DMA_READ_RESP_CLASS *PSEUDO_DMA_READ_RESP;

    //
    // Pointer to a function that handles pseudo-DMA.  This function will
    // most likely be implemented in the scratchpad service.
    //
    typedef bool (*PSEUDO_DMA_HANDLER)(int methodID,
                                       int length,
                                       const void *msg,
                                       PSEUDO_DMA_READ_RESP &resp);

    //
    // Call into this driver to register a pseudo-DMA handler.  At most one
    // driver may be active.
    //
    static void RegisterPseudoDMAHandler(int channelID,
                                         int serviceID,
                                         PSEUDO_DMA_HANDLER handler);

  private:
    static int pseudoDMAChannelID;
    static int pseudoDMAServiceID;
    static PSEUDO_DMA_HANDLER pseudoDMAHandler;
};

#endif
