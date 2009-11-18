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

class PHYSICAL_CHANNEL_CLASS: public PLATFORMS_MODULE_CLASS,
                              public TRACEABLE_CLASS
{

  private:

    // cached links to useful physical devices
    NALLATECH_EDGE_DEVICE nallatechEdgeDevice;
    
    // lock
    pthread_mutex_t deviceLock;

    // cache pointers to I/O windows
    NALLATECH_WORD* readWindow;
    NALLATECH_WORD* writeWindow;

    // misc
    bool alive;

    // Count writes -- used for tuning read buffer size
    int writeCount;

    // Stream of data coming from the FPGA
    int nextRawReadPos;
    int maxRawReadPos;
    int rawReadBufferSize;
    int BufferedWordsRemaining();
    NALLATECH_WORD RawReadNextWord(bool newMsg);

    // Return nWords words from the current buffer.  nWords must be <=
    // BufferedWordsRemaining().
    const NALLATECH_WORD *RawReadBufferedWords(int nWords);

  public:

    PHYSICAL_CHANNEL_CLASS(PLATFORMS_MODULE, PHYSICAL_DEVICES);
    ~PHYSICAL_CHANNEL_CLASS();

    void Init();
    
    // interface
    UMF_MESSAGE Read();             // blocking read
    UMF_MESSAGE TryRead();          // non-blocking read
    void        Write(UMF_MESSAGE); // write
};

#endif
