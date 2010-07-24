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


interface NALLATECH_INTRA_DRIVER;

    method Action              enq(NALLATECH_FIFO_DATA data);
    method NALLATECH_FIFO_DATA first();
    method Action              deq();
        
endinterface

// NALLATECH_INTRA_WIRES

// Nallatech Intra Wires are defined in the primitive device

// NALLATECH_INTRA_DEVICE

// By convention a Device is a Driver and a Wires

interface NALLATECH_INTRA_DEVICE;

    interface NALLATECH_INTRA_DRIVER        intra_driver;
    interface NALLATECH_INTRA_WIRES         wires;
    interface NALLATECH_INTRA_COMM_CONTROL  communication_control;
        
endinterface


// mkNallatechIntraDevice

// Really a very thin wrapper - there's not much beyond the fifo interface

module mkNallatechIntraDeviceParametric#(Clock clk100,
                                         Clock clk200,
                                         LOCAL_ID localID,
                                         EXTERNAL_ID externalID,
                                         Integer rxLanes,
                                         Integer txLanes)

    // interface:
                 (NALLATECH_INTRA_DEVICE);

    // Instantiate the primitive device.
 
    Clock clock <- exposeCurrentClock();
    Reset reset <- exposeCurrentReset();

    Reset primitiveReset <- mkAsyncReset(2, reset, clk200);

    FIFO#(NALLATECH_FIFO_DATA) intraReadQ <- mkFIFO(clocked_by clk200, reset_by primitiveReset);

    PRIMITIVE_NALLATECH_INTRA_DEVICE prim_device <- 
        mkPrimitiveNallatechIntraDevice(clk100,
                                        localID,
                                        externalID, 
                                        rxLanes,
                                        txLanes,
                                        clocked_by clk200,
                                        reset_by primitiveReset
                                       );

    SyncFIFOIfc#(NALLATECH_FIFO_DATA) sync_read_q
        <- mkSyncFIFOToCC(6, clk200, primitiveReset);
        
    SyncFIFOIfc#(NALLATECH_FIFO_DATA) sync_write_q
        <- mkSyncFIFOFromCC(6, clk200);

    rule sendToPrim;
        sync_write_q.deq();
        prim_device.enq(sync_write_q.first());
    endrule

    rule getFromPrim;
        prim_device.deq();
        intraReadQ.enq(prim_device.first());
    endrule

    rule getFromReadQ;
      intraReadQ.deq();      
      sync_read_q.enq(intraReadQ.first());
    endrule

    interface NALLATECH_INTRA_DRIVER intra_driver;
        
        method enq = sync_write_q.enq;
            
        method first = sync_read_q.first;

        method deq = sync_read_q.deq;
                
    endinterface

    // Pass through communication control

    interface communication_control = prim_device.communication_control;

    // Pass through the wires interface
    
    interface wires = prim_device.wires;
        
endmodule
