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

#ifndef __NALLATECH_EDGE_DEVICE__
#define __NALLATECH_EDGE_DEVICE__

#include <asim/syntax.h>

#include "ACP_API.h"

#include "asim/provides/umf.h"
#include "platforms-module.h"

typedef UMF_CHUNK NALLATECH_WORD;

#define NALLATECH_MAX_MSG_WORDS (NALLATECH_MAX_MSG_BYTES / sizeof(NALLATECH_WORD))
#define NALLATECH_MIN_MSG_WORDS (NALLATECH_MIN_MSG_BYTES / sizeof(NALLATECH_WORD))

#define NALLATECH_NUM_WRITE_WINDOWS 2
#define NALLATECH_NUM_READ_WINDOWS 3


// ===============================================
//               Nallatech EDGE Device
// ===============================================

typedef class NALLATECH_EDGE_DEVICE_CLASS* NALLATECH_EDGE_DEVICE;

class NALLATECH_EDGE_DEVICE_CLASS: public PLATFORMS_MODULE_CLASS
{
  private:
    // ACP state
    ACP_SOCKET_HANDLE hsocket;
    ACP_AFU_HANDLE    hafu;

    // workspace
    NALLATECH_WORD* workspace;
    UINT64          workspacePA;

    UINT64 WorkspaceBytes() const;

  public:
    NALLATECH_EDGE_DEVICE_CLASS(PLATFORMS_MODULE);
    ~NALLATECH_EDGE_DEVICE_CLASS();
    
    void Cleanup();
    void Init();
    void Uninit();

    //
    // Read and write windows are buffers for transferring data between the
    // host and an FPGA.
    //
    // Pointers to read/write windows
    NALLATECH_WORD* GetWriteWindow(int windowID) const;
    NALLATECH_WORD* GetReadWindow(int windowID) const;

    // Write followed by read transaction
    void DoAALTransaction(int writeWindowID, int writeWords,
                          int readWindowID, int readWords);

    // Convert a request size to a legal buffer size
    inline int LegalBufSize(int words) const;
};


inline int
NALLATECH_EDGE_DEVICE_CLASS::LegalBufSize(int words) const
{
    // Messages are transferred in 32 byte chunks but consumed as
    // NALLATECH_WORD_SIZE values.  Message size must be a full group of
    // chunks.
    //
    // *** Writes from the FPGA to the host appear to pass incorrect values
    // *** unless they are in NALLATECH_MIN_MSG_BYTES chunks!
    int words_per_chunk = NALLATECH_MIN_MSG_BYTES / sizeof(NALLATECH_WORD);

    // Round up -- assume powers of 2.
    int r = words_per_chunk - 1;
    ASSERTX((words_per_chunk & r) == 0);

    int msg_size = (words + r) & ~r;

    // Must meet min/max message sizes
    if (msg_size > NALLATECH_MAX_MSG_WORDS)
    {
        msg_size = NALLATECH_MAX_MSG_WORDS;
    }
    else if (msg_size < NALLATECH_MIN_MSG_WORDS)
    {
        msg_size = NALLATECH_MIN_MSG_WORDS;
    }

    return msg_size;
}

#endif
