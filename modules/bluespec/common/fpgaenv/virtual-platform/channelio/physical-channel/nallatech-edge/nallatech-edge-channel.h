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
#include "asim/provides/physical_platform.h"
#include <pthread.h>


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

    // Generate a command for passing data to the FPGA.
    NALLATECH_WORD GenCommand(int h2fRawBufChunks,
                              int f2hRawBufChunks,
                              int waitForDataSpinCycles,
                              bool f2hDataPermitted) const;

  public:

    PHYSICAL_CHANNEL_CLASS(PLATFORMS_MODULE, PHYSICAL_DEVICES);
    ~PHYSICAL_CHANNEL_CLASS();

    void Init();
    
    // interface
    UMF_MESSAGE Read();             // blocking read
    UMF_MESSAGE TryRead();          // non-blocking read
    void        Write(UMF_MESSAGE); // write

    // I/O management, run as a separate thread
    void IOThread();
};

#endif
