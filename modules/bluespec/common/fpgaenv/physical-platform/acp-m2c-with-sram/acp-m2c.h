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

//
// This file is shared among the several diffent ACP physical configurations using symlinks.
//

#ifndef __PHYSICAL_PLATFORM__
#define __PHYSICAL_PLATFORM__

#include "asim/syntax.h"
#include "asim/provides/physical_channel.h"
#include "awb/provides/physical_platform_utils.h"


// ====================================================
//       ACP M2 Compute Module Physical Platform
// ====================================================

// This class is a collection of all physical devices
// present on the ACP M2C
typedef class PHYSICAL_DEVICES_CLASS* PHYSICAL_DEVICES;
class PHYSICAL_DEVICES_CLASS: public PLATFORMS_MODULE_CLASS
{
  private:

    // Nallatech Edge Device
    NALLATECH_EDGE_PHYSICAL_CHANNEL_CLASS nallatechEdgeDevice;

  public:

    // constructor-destructor
    PHYSICAL_DEVICES_CLASS(PLATFORMS_MODULE);
    ~PHYSICAL_DEVICES_CLASS();

    void Init();

    // accessors to individual devices
    PHYSICAL_CHANNEL GetLegacyPhysicalChannel() { return &nallatechEdgeDevice; }
};

#endif
