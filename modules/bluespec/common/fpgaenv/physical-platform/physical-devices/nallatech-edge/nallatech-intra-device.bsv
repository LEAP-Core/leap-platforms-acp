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


//
// LVDS links between FPGAs within a single Nallatech FPGA module stack.
//
// Nallatech calls the inter-FPGA links within a single module
// inter-intra-module LVDS links.  We shorten this to NALLATECH_INTRA.
//


import Clocks::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;
import RWire::*;
import GetPut::*;
import Connectable::*;


`include "awb/provides/librl_bsv_base.bsh"
`include "awb/provides/fpga_components.bsh"
`include "awb/provides/clocks_device.bsh"
`include "awb/provides/umf.bsh"

interface NALLATECH_INTRA_DRIVER;

    method Action              enq(NALLATECH_FIFO_DATA data);
    method NALLATECH_FIFO_DATA first();
    method Action              deq();
        
endinterface

interface NALLATECH_UMF_INTRA_DRIVER;

    method Action              write(NALLATECH_FIFO_DATA data);
    method Bool                write_ready();
    method NALLATECH_FIFO_DATA first();
    method Action              deq();

endinterface

// NALLATECH_INTRA_WIRES

// Nallatech Intra Wires are defined in the primitive device

// NALLATECH_INTRA_DEVICE

// By convention a Device is a Driver and a Wires

interface NALLATECH_INTRA_DEVICE;

    interface NALLATECH_INTRA_DRIVER        intra_driver;
    interface NALLATECH_UMF_INTRA_DRIVER    umf_intra_driver;
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

    //
    // FIFOs on the edge of the device interface in the fast clock domain
    // relax timing constraints and add only one cycle of fast clock latency.
    //
    FIFO#(NALLATECH_FIFO_DATA) intraWriteQ <- mkFIFO(clocked_by clk200, reset_by primitiveReset);
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

    //
    // Modules don't wait for all other modules to be initialized before
    // sending data.  From our reading of the Nallatech documentation, there
    // doesn't seem to be an exposed signal to detect the end of system
    // configuration.  We could use a user register set by the software.
    // For now we use the knowledge that FPGA0 is programmed first and
    // must wait for FPGA1 to send a message.
    //

    Reg#(Bool) initialized <- mkReg(False);

    rule doInit (! initialized);
        if (`NALLATECH_MODULE_FPGA_ID == 0)
        begin
            //
            // FPGA0 is set up first.  Wait for a message from FPGA1.
            //
            sync_read_q.deq();
        end
        else
        begin
            //
            // FPGA1 is set up last.  Tell FPGA0 the module is ready.
            //
            sync_write_q.enq(?);
        end

        initialized <= True;
    endrule

    // Connections from sync FIFOs to the device
    mkConnection(toGet(sync_write_q), toPut(intraWriteQ));

    rule sendToPrim (True);
        prim_device.enq(intraWriteQ.first());
        intraWriteQ.deq();
    endrule


    rule getFromPrim (True);
        intraReadQ.enq(prim_device.first());
        prim_device.deq();
    endrule

    mkConnection(toGet(intraReadQ), toPut(sync_read_q));


    interface NALLATECH_INTRA_DRIVER intra_driver;
        
        method Action enq(NALLATECH_FIFO_DATA data) if (initialized);
            sync_write_q.enq(data);
        endmethod

        method NALLATECH_FIFO_DATA first() if (initialized);
            return sync_read_q.first();
        endmethod

        method Action deq() if (initialized);
            sync_read_q.deq();
        endmethod
                
    endinterface

    interface NALLATECH_UMF_INTRA_DRIVER umf_intra_driver;
        
        method Action write(NALLATECH_FIFO_DATA data) if (initialized);
            sync_write_q.enq(zeroExtend(data));
        endmethod

        method Bool write_ready = sync_write_q.notFull && initialized;
                
        method NALLATECH_FIFO_DATA first() if (initialized);
            return sync_read_q.first();
        endmethod

        method Action deq() if (initialized);
            sync_read_q.deq();
        endmethod
            
    endinterface

    // Pass through communication control

    interface communication_control = prim_device.communication_control;

    // Pass through the wires interface
    
    interface wires = prim_device.wires;
        
endmodule
