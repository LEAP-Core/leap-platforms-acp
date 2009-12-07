//
// Copyright (C) 2009 Intel Corporation
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

import Clocks::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;
import RWire::*;

// DDR_SRAM_DRIVER

// Inspired by our DDR2_DRAM_DRIVER

interface DDR2_DRIVER;

    method Action readReq(FPGA_DDR_ADDRESS addr);
    method ActionValue#(FPGA_DDR_DUALEDGE_DATA) readRsp();
    method Action writeReq(FPGA_DDR_ADDRESS addr);
    method Action writeData(FPGA_DDR_DUALEDGE_DATA data, FPGA_DDR_DUALEDGE_DATA_MASK mask);

endinterface

// DDR_SRAM_WIRES

// DDR SRAM Wires are defined in the primitive device

// DDR_SRAM_DEVICE

// By convention a Device is a Driver and a Wires

interface DDR2_DEVICE;

    interface DDR2_DRIVER driver;
    interface DDR2_WIRES  wires;
        
endinterface


//
// mkDDR2SRAMDevice
//
// Wrap the primitive device and deal with DDR.

module mkDDR2SRAMDevice
    #(Clock ramClk0,
      Clock ramClk200,
      Clock ramClk270,
      Bit#(1) ramClkLocked,
      Reset topLevelReset)
    // interface:
    (DDR2_DEVICE);

    // Instantiate the primitive device.
    // XXX just use a fake clock now so we can get this to compile.

    PRIMITIVE_DDR_SRAM_DEVICE prim_device <- mkPrimitiveDDRSRAMDevice(ramClk0, ramClk200, ramClk270, ramClkLocked, topLevelReset);

    interface DDR2_DRIVER driver;

        method Action readReq(FPGA_DDR_ADDRESS addr);

        endmethod

        method ActionValue#(FPGA_DDR_DUALEDGE_DATA) readRsp();

            return ?;

        endmethod

        method Action writeReq(FPGA_DDR_ADDRESS addr);

        endmethod

        method Action writeData(FPGA_DDR_DUALEDGE_DATA data, FPGA_DDR_DUALEDGE_DATA_MASK mask);

        endmethod

    endinterface

    // Pass through the wires interface
    
    interface wires = prim_device.wires;
        
endmodule
