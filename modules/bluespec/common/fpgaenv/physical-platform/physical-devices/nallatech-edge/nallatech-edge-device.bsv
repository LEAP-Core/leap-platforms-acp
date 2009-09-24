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

`include "asim/provides/librl_bsv_base.bsh"
`include "asim/provides/fpga_components.bsh"
`include "asim/provides/clocks_device.bsh"

// NALLATECH_EDGE_DRIVER

interface NALLATECH_EDGE_DRIVER;

    method Action              enq(NALLATECH_FIFO_DATA data);
    method NALLATECH_FIFO_DATA first();
    method Action              deq();
        
endinterface

// NALLATECH_EDGE_WIRES

// Nallatech Edge Wires are defined in the primitive device

// NALLATECH_EDGE_DEVICE

// By convention a Device is a Driver and a Wires

interface NALLATECH_EDGE_DEVICE;

    interface NALLATECH_EDGE_DRIVER edge_driver;
    interface NALLATECH_EDGE_WIRES  wires;
    interface CLOCKS_DRIVER         clocks_driver;
        
endinterface


// mkNallatechEdgeDevice

// Take the primitive device import and cross the clock domains into the
// default bluespec domain. Also wrap the raw driver interfaces into
// more structured and readable interfaces.

module mkNallatechEdgeDevice
    // interface:
                 (NALLATECH_EDGE_DEVICE);

    // Instantiate the primitive device.

    PRIMITIVE_NALLATECH_EDGE_DEVICE prim_device <- mkPrimitiveNallatechEdgeDevice();

    // Get the Clock and Reset, and do the required multiplication/division
    
    Clock edgeClock = prim_device.clock;
    Reset edgeReset = prim_device.reset;
    
    Clock rawClock = prim_device.rawClock;
    Reset rawReset = noReset;
    
    let userClockPackage <- mkUserClock_PLL(`CRYSTAL_CLOCK_FREQ,
                                            `MODEL_CLOCK_IN_DIVIDER,
                                            `MODEL_CLOCK_MULTIPLIER,
                                            `MODEL_CLOCK_OUT_DIVIDER,
                                            clocked_by rawClock,
                                            reset_by   rawReset);
    
    Clock modelClock = userClockPackage.clk;

    // Reset transReset <- mkAsyncReset(5, edgeReset, modelClock);
    // Reset modelReset <- mkResetEither(transReset, userClockPackage.rst, clocked_by modelClock);
    Reset modelReset = userClockPackage.rst;
      
    // Synchronizers
    
    SyncFIFOIfc#(NALLATECH_FIFO_DATA) sync_read_q
                                   <- mkSyncFIFO(2, edgeClock, edgeReset, modelClock);
        
    SyncFIFOIfc#(NALLATECH_FIFO_DATA) sync_write_q
                                   <- mkSyncFIFO(2, modelClock, modelReset, edgeClock);
    
    //
    // Rules for synchronizing from Edge to Model domain
    //
        
    rule sync_read (True);
            
        sync_read_q.enq(prim_device.first());
        prim_device.deq();
        
    endrule

    //
    // Rules for synchronizing from Model to Edge domain
    //
    
    rule sync_write (True);
        
        prim_device.enq(sync_write_q.first());
        sync_write_q.deq();
        
    endrule
        
    //
    // Drivers
    //
    
    interface NALLATECH_EDGE_DRIVER edge_driver;
        
        method Action enq(NALLATECH_FIFO_DATA data);
            
            sync_write_q.enq(data);
            
        endmethod
            
        method NALLATECH_FIFO_DATA first();
            
            return sync_read_q.first();
            
        endmethod
            
        method Action deq();
            
            sync_read_q.deq();
            
        endmethod
                
    endinterface
    
    // The Nallatech Edge device currently also provides the Clocks driver
    
    interface CLOCKS_DRIVER clocks_driver;
        
        interface Clock clock = modelClock;
        interface Reset reset = modelReset;
            
        interface Clock rawClock = rawClock;
        interface Reset rawReset = rawReset;
            
    endinterface
    
    // Pass through the wires interface
    
    interface wires = prim_device.wires;
        
endmodule
