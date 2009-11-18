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

#if (NALLATECH_WORD_SIZE == 32)
typedef UINT32 NALLATECH_WORD;
#else
#error "NALLATECH_WORD must be 32 bits"
#endif

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

  public:

    NALLATECH_EDGE_DEVICE_CLASS(PLATFORMS_MODULE);
    ~NALLATECH_EDGE_DEVICE_CLASS();
    
    void Cleanup();
    void Init();
    void Uninit();

    // interface to device
    NALLATECH_WORD* GetInputWindow();
    NALLATECH_WORD* GetOutputWindow();

    // Write followed by read transaction
    void DoAALTransaction(int writeWords, int readWords);

    // Write only transaction.  Nallatech firmware requires a read response.
    // The dummyReadWords response will be written to a scratch buffer.
    //
    // The function returns the first word of the read response -- useful
    // for returning a status flag from the FPGA.
    NALLATECH_WORD DoAALWriteTransaction(int writeWords, int dummyReadWords);

    // Convert a request size to a legal buffer size
    inline int LegalBufSize(int words) const;
};


inline int
NALLATECH_EDGE_DEVICE_CLASS::LegalBufSize(int words) const
{
    // Messages are transferred in 256 bit chunks but consumed as
    // NALLATECH_WORD_SIZE values.  Message size must be a full group of
    // chunks.
    //
    // *** Writes from the FPGA to the host appear to pass incorrect values
    // *** unless they are in 512 bit chunks!
    int words_per_chunk = 512 / NALLATECH_WORD_SIZE;

    // Round up -- assume powers of 2.
    int r = words_per_chunk - 1;
    ASSERTX((words_per_chunk & r) == 0);

    int msg_size = (words + r) & ~r;

    // Must meet min/max message sizes
    return min(max(msg_size, NALLATECH_MIN_MSG_WORDS), NALLATECH_MAX_MSG_WORDS);
}

#endif
