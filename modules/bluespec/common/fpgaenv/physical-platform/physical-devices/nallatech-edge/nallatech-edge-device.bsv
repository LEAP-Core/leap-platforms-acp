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
`include "asim/provides/led_device.bsh"

// NALLATECH_EDGE_DRIVER

interface NALLATECH_EDGE_DRIVER;

    method Action              enq(NALLATECH_FIFO_DATA data);
    method NALLATECH_FIFO_DATA first();
    method Action              deq();
        
    //
    // The user register interface is available for debugging.  These registers
    // are connected to user registers, port 3.
    //
    // Host requests update of FPGA state
    method ActionValue#(Tuple2#(NALLATECH_REG_ADDR, NALLATECH_REG_DATA)) regWrite();
    // Host requests read of FPGA state
    method ActionValue#(NALLATECH_REG_ADDR) regReadReq();
    method Action regReadRsp(NALLATECH_REG_DATA data);

endinterface

// NALLATECH_EDGE_WIRES

// Nallatech Edge Wires are defined in the primitive device

// NALLATECH_EDGE_DEVICE

// By convention a Device is a Driver and a Wires

interface NALLATECH_EDGE_DEVICE;

    interface NALLATECH_EDGE_DRIVER         edge_driver;
    interface NALLATECH_EDGE_WIRES          wires;
    interface CLOCKS_DRIVER                 clocks_driver;
    interface SRAM_CLOCKS_DRIVER            sram_clocks_driver;
    interface INTRA_CLOCKS_DRIVER           intra_clocks_driver;
    interface NALLATECH_COMM_CONTROL        communication_control;
    interface LEDS_DRIVER#(4)               leds_driver;
        
endinterface

// Interface SRAM_CLOCKS_DRIVER
// An interface to pass wires from the edge driver to an SRAM device (if present)

interface SRAM_CLOCKS_DRIVER;

    interface Clock ramClk0;
    interface Clock ramClk200;
    interface Clock ramClk270;
    interface Reset ramReset;
    method Bit#(1) ramClkLocked();
        
endinterface


typedef Clock INTRA_CLOCKS_DRIVER;

// mkNallatechEdgeDevice

// Take the primitive device import and cross the clock domains into the
// default bluespec domain. Also wrap the raw driver interfaces into
// more structured and readable interfaces.

module mkNallatechEdgeDeviceParametric#(LOCAL_ID localID,
                                        EXTERNAL_ID externalID,
                                        Integer rxLanes,
                                        Integer txLanes)

    // interface:
                 (NALLATECH_EDGE_DEVICE);

    // Instantiate the primitive device.

    PRIMITIVE_NALLATECH_EDGE_DEVICE prim_device <- mkPrimitiveNallatechEdgeDevice(localID,
                                                                                  externalID, 
                                                                                  rxLanes,
                                                                                  txLanes);

    // Get the Clock and Reset, and do the required multiplication/division
    
    Clock edgeClock = prim_device.clock;
    Reset edgeReset = prim_device.reset;
    
    Clock rawClock = prim_device.rawClock;
    Reset rawReset = noReset;

    Clock userRegClock = prim_device.regClock;
    Reset userRegReset <- mkAsyncReset(2, edgeReset, userRegClock);

    let userClockPackage <- mkUserClock_PLL(`CRYSTAL_CLOCK_FREQ,
                                            `MODEL_CLOCK_FREQ,
                                            clocked_by rawClock,
                                            reset_by   rawReset);

    Clock modelClock = userClockPackage.clk;

    // Combine edge and raw resets
    Reset localEdgeReset <- mkAsyncReset(2, edgeReset, modelClock);
    Reset baseReset <- mkResetEither(localEdgeReset, userClockPackage.rst, clocked_by modelClock);

    // Hold reset for 20 cycles.  The TIG in the UCF file must match this number.
    // (TIG the high bit: cycles minus 1.)
    Reset modelReset <- mkAsyncReset(20, baseReset, modelClock);

    //
    // DDR RAM runs at 200MHz by default. The configuration may specify an
    // alternate frequency.  The RAM requires a main clock and a 270 degree
    // phase shifted copy.  We route even the 200 MHz RAM clock through a
    // PLL so the UCF file always sees the same topology.
    //
    //
    // WARNING                WARNING                WARNING
    //
    //   Some ACP stacks work perfectly with memory speeds other than the
    //   default 200MHz.  Others seem to fail to calibrate the read timing
    //   correctly and return incorrect values.  If you pick a clock other
    //   than the default, you are advised to use sram_debugger_nallatech_acp
    //   in leap/debuggers.
    //
    //   From some experimenting, 150MHz appears to work, though the
    //   calibration returns inconsistent timing.  225MHz appears to work
    //   correctly, though should be tested more.
    //
    // WARNING                WARNING                WARNING
    //
    let ramClock <- mkUserClock_2PhasedPLL(`CRYSTAL_CLOCK_FREQ,
                                           `NALLATECH_RAM_CLOCK_FREQ,
                                           270,
                                           clocked_by rawClock,
                                           reset_by   rawReset);
    Clock ramClock0 = ramClock.clks[0];
    Clock ramClock270 = ramClock.clks[1];
    let prim_ram_rst <- mkAsyncReset(10, ramClock.rst, modelClock);
    let ramReset <- mkResetEither(modelReset, prim_ram_rst, clocked_by modelClock);
    Bit#(1) ramClockLocked = pack(ramClock.locked());

    // Synchronizers
    
    SyncFIFOIfc#(NALLATECH_FIFO_DATA) sync_read_q
        <- mkSyncFIFO(6, edgeClock, edgeReset, modelClock);
        
    SyncFIFOIfc#(NALLATECH_FIFO_DATA) sync_write_q
        <- mkSyncFIFO(6, modelClock, modelReset, edgeClock);
    
    SyncFIFOIfc#(Tuple2#(NALLATECH_REG_ADDR, NALLATECH_REG_DATA)) sync_reg_write_q
        <- mkSyncFIFO(6, userRegClock, userRegReset, modelClock);
    SyncFIFOIfc#(Bool) sync_reg_write_ack_q
        <- mkSyncFIFO(6, modelClock, modelReset, userRegClock);
    
    SyncFIFOIfc#(NALLATECH_REG_ADDR) sync_reg_read_req_q
        <- mkSyncFIFO(6, userRegClock, userRegReset, modelClock);
    SyncFIFOIfc#(NALLATECH_REG_DATA) sync_reg_read_rsp_q
        <- mkSyncFIFO(6, modelClock, modelReset, userRegClock);

    //
    // Rules for synchronizing from Edge to Model domain.  Put a FIFO between
    // between the sync FIFO and the edge to reduce edge timing problems.
    //

    FIFO#(NALLATECH_FIFO_DATA) edgeReadQ <- mkFIFO(clocked_by edgeClock, reset_by edgeReset);

    rule edge_read (True);
        edgeReadQ.enq(prim_device.first());
        prim_device.deq();
    endrule

    rule sync_read (True);
        sync_read_q.enq(edgeReadQ.first());
        edgeReadQ.deq();
    endrule

    //
    // Rules for synchronizing from Model to Edge domain
    //
    
    rule sync_write (True);
        prim_device.enq(sync_write_q.first());
        sync_write_q.deq();
    endrule
        

    //
    // User register write/read.  The protocols are very unforgiving, so we
    // hold state in registers in the edge clock domain before trying to
    // talk to the sync FIFO.
    //
    // Only one write/read request may be outstanding, so temporary registers
    // are sufficient.
    //
    Reg#(Maybe#(Tuple2#(NALLATECH_REG_ADDR, NALLATECH_REG_DATA))) regWriteBuf <-
        mkReg(tagged Invalid, clocked_by userRegClock, reset_by userRegReset);

    rule userRegWrite0 (prim_device.regWriteReq() && ! isValid(regWriteBuf));
        regWriteBuf <= tagged Valid tuple2(prim_device.regAddr(),
                                           prim_device.regWriteData());
    endrule

    rule userRegWrite1 (regWriteBuf matches tagged Valid .w);
        sync_reg_write_q.enq(w);
        regWriteBuf <= tagged Invalid;
    endrule

    rule userRegWriteAck (True);
        prim_device.regAckWrite();
        sync_reg_write_ack_q.deq();
    endrule

    //
    // User register read
    //
    Reg#(Maybe#(NALLATECH_REG_ADDR)) regReadBuf <-
        mkReg(tagged Invalid, clocked_by userRegClock, reset_by userRegReset);

    rule userRegReadReq0 (prim_device.regReadReq() && ! isValid(regReadBuf));
        regReadBuf <= tagged Valid prim_device.regAddr();
    endrule

    rule userRegReadReq1 (regReadBuf matches tagged Valid .r);
        sync_reg_read_req_q.enq(r);
        regReadBuf <= tagged Invalid;
    endrule

    rule userRegReadRsp (True);
        prim_device.regSendReadData(sync_reg_read_rsp_q.first());
        sync_reg_read_rsp_q.deq();
    endrule

    // Handle the leds device
    Reg#(Bit#(4)) ledReg <- mkSyncReg(0, modelClock, modelReset, edgeClock);
    
    rule driveLEDS;
       prim_device.setLEDs(ledReg);
    endrule 

    //
    // Drivers
    //
    
    interface LEDS_DRIVER leds_driver;

	method  Action setLEDs(Bit#(4) leds_in);
            ledReg <= leds_in;
	endmethod
	
    endinterface

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
                
        //
        // Debug registers
        //
        // Host requests update of FPGA state
        method ActionValue#(Tuple2#(NALLATECH_REG_ADDR, NALLATECH_REG_DATA)) regWrite();
            let r = sync_reg_write_q.first();
            sync_reg_write_q.deq();
            
            // Ack the write
            sync_reg_write_ack_q.enq(?);
            
            return r;
        endmethod

        // Host requests read of FPGA state
        method ActionValue#(NALLATECH_REG_ADDR) regReadReq();
            let addr = sync_reg_read_req_q.first();
            sync_reg_read_req_q.deq();
            
            return addr;
        endmethod

        method Action regReadRsp(NALLATECH_REG_DATA data);
            sync_reg_read_rsp_q.enq(data);
        endmethod

    endinterface
    
    // The Nallatech Edge device currently also provides clocks for any SRAM devices present.
    
    interface SRAM_CLOCKS_DRIVER sram_clocks_driver;

        interface Clock ramClk0 = ramClock0;
        interface Clock ramClk200 = prim_device.ramClk200;
        interface Clock ramClk270 = ramClock270;
        interface Reset ramReset = ramReset;
        method Bit#(1)  ramClkLocked() = ramClockLocked;
            
    endinterface
    
    // The Nallatech Edge device currently also provides the Clocks driver
    
    interface CLOCKS_DRIVER clocks_driver;
        
        interface Clock clock = modelClock;
        interface Reset reset = modelReset;
            
        interface Clock rawClock = rawClock;
        interface Reset rawReset = rawReset;
            
    endinterface
    
    // Pass through communication control
    interface communication_control = prim_device.communication_control;
 
    // Pass through oscillator clock (100Mhz)
    interface intra_clocks_driver = prim_device.oscClock;

    // Pass through the wires interface
    
    interface wires = prim_device.wires;
        
endmodule
