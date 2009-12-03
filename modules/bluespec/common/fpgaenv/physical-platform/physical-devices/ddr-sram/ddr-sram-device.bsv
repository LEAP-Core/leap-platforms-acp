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

interface DDR_SRAM_DRIVER;

    method Action readReq(FPGA_SRAM_ADDRESS addr);
    method ActionValue#(FPGA_SRAM_DUALEDGE_DATA) readRsp();
    method Action writeReq(FPGA_SRAM_ADDRESS addr);
    method Action writeData(FPGA_SRAM_DUALEDGE_DATA data, FPGA_SRAM_DUALEDGE_DATA_MASK mask);

endinterface

// DDR_SRAM_WIRES

// DDR SRAM Wires are defined in the primitive device

// DDR_SRAM_DEVICE

// By convention a Device is a Driver and a Wires

interface DDR_SRAM_DEVICE;

    interface DDR_SRAM_DRIVER sram_driver;
    interface DDR_SRAM_WIRES  wires;
        
endinterface


//
// mkDDRSRAMDevice
//
// Wrap the primitive device and deal with DDR.

module mkDDRSRAMDevice
    // interface:
                 (DDR_SRAM_DEVICE);

    // Instantiate the primitive device.
    // XXX just use a fake clock now so we can get this to compile.

    
    Clock modelClock <- exposeCurrentClock();
    Reset modelReset <- exposeCurrentReset();
    MakeClockIfc#(Bit#(1)) fakeclock <- mkUngatedClock(0);
    
    PRIMITIVE_DDR_SRAM_DEVICE prim_device <- mkPrimitiveDDRSRAMDevice(fakeclock.new_clk, fakeclock.new_clk, fakeclock.new_clk, modelReset, modelReset);

    interface DDR_SRAM_DRIVER sram_driver;

        method Action readReq(FPGA_SRAM_ADDRESS addr);

        endmethod

        method ActionValue#(FPGA_SRAM_DUALEDGE_DATA) readRsp();

            return ?;

        endmethod

        method Action writeReq(FPGA_SRAM_ADDRESS addr);

        endmethod

        method Action writeData(FPGA_SRAM_DUALEDGE_DATA data, FPGA_SRAM_DUALEDGE_DATA_MASK mask);

        endmethod

    endinterface

    // Pass through the wires interface
    
    interface wires = prim_device.wires;
        
endmodule
