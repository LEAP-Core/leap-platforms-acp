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

// NALLATECH_EDGE_WIRES

// Nallatech Edge Wires are defined in the primitive device

// NALLATECH_EDGE_DEVICE

// By convention a Device is a Driver and a Wires

interface NALLATECH_INTRA_DEVICE;

    interface NALLATECH_INTRA_DRIVER        intra_driver;
    interface NALLATECH_INTRA_WIRES         wires;
    interface NALLATECH_COMM_CONTROL        communication_control;
        
endinterface

// Interface SRAM_CLOCKS_DRIVER
// An interface to pass wires from the edge driver to an SRAM device (if present)

interface SRAM_CLOCKS_DRIVER;

    interface Clock ramClk0;
    interface Clock ramClk200;
    interface Clock ramClk270;
    method Bit#(1) ramClkLocked();
        
endinterface


// mkNallatechEdgeDevice

// Take the primitive device import and cross the clock domains into the
// default bluespec domain. Also wrap the raw driver interfaces into
// more structured and readable interfaces.

module mkNallatechEdgeDeviceParametric#(Clock clk100,
                                        LOCAL_ID localID,
                                        EXTERNAL_ID externalID,
                                        Integer rxLanes,
                                        Integer txLanes)

    // interface:
                 (NALLATECH_EDGE_DEVICE);

    // Instantiate the primitive device.

    PRIMITIVE_NALLATECH_INTRA_DEVICE prim_device <- mkPrimitiveNallatechIntraDevice(clk100,
                                                                                    localID,
                                                                                    externalID, 
                                                                                    rxLanes,
                                                                                    txLanes);


    //
    // Rules for synchronizing from Edge to Model domain.  Put a FIFO between
    // between the sync FIFO and the edge to reduce edge timing problems.
    // maybe retaining this is a good idea?
    //

    FIFO#(NALLATECH_FIFO_DATA) edgeReadQ <- mkFIFO(clocked_by edgeClock, reset_by edgeReset);

    rule edge_read (True);
        edgeReadQ.enq(prim_device.first());
        prim_device.deq();
    endrule

    interface NALLATECH_EDGE_DRIVER edge_driver;
        
        method Action enq(NALLATECH_FIFO_DATA data);
            
            prim_device.enq(data);
            
        endmethod
            
        method NALLATECH_FIFO_DATA first();
            
            return sync_read_q.first();
            
        endmethod
            
        method Action deq();
            
            edgeReadQ.deq();
            
        endmethod
                
    endinterface
    
    // Pass through the wires interface
    
    interface wires = prim_device.wires;
        
endmodule
