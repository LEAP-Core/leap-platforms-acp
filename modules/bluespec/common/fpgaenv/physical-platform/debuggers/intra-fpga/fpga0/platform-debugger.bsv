//
// INTEL CONFIDENTIAL
// Copyright (c) 2008 Intel Corp.  Recipient is granted a non-sublicensable 
// copyright license under Intel copyrights to copy and distribute this code 
// internally only. This code is provided "AS IS" with no support and with no 
// warranties of any kind, including warranties of MERCHANTABILITY,
// FITNESS FOR ANY PARTICULAR PURPOSE or INTELLECTUAL PROPERTY INFRINGEMENT. 
// By making any use of this code, Recipient agrees that no other licenses 
// to any Intel patents, trade secrets, copyrights or other intellectual 
// property rights are granted herein, and no other licenses shall arise by 
// estoppel, implication or by operation of law. Recipient accepts all risks 
// of use.
//

//
// @file platform-debugger.cpp
// @brief Platform Debugger Application
//
// @author Angshuman Parashar
//

import FIFO::*;
import Vector::*;

`include "asim/provides/virtual_platform.bsh"
`include "asim/provides/virtual_devices.bsh"
`include "asim/provides/physical_platform.bsh"
`include "asim/provides/nallatech_intra_device.bsh"
`include "asim/provides/low_level_platform_interface.bsh"
`include "asim/provides/intra_debugger_common.bsh"
`include "asim/provides/led_device.bsh"
`include "asim/provides/clocks_device.bsh"
`include "asim/rrr/server_stub_PLATFORM_DEBUGGER.bsh"

// types

typedef enum
{
    STATE_idle,
    STATE_running,
    STATE_calibrating
}
STATE
    deriving (Bits, Eq);

// mkApplication

module mkApplication#(VIRTUAL_PLATFORM vp)();
    
    LowLevelPlatformInterface llpi    = vp.llpint;
    PHYSICAL_DRIVERS          drivers = llpi.physicalDrivers;
    let intra_channel = drivers.nallatechIntraDriver;
//    let jtag_channel  = drivers.jtagDriver;
    let leds = drivers.ledsDriver; 
    Reg#(STATE) state <- mkReg(STATE_idle);
    FIFO#(Tuple2#(Bit#(64),IntraTestStruct)) result <- mkFIFO;
    
    // instantiate stubs
    ServerStub_PLATFORM_DEBUGGER serverStub <- mkServerStub_PLATFORM_DEBUGGER(llpi.rrrServer);
    
    Reg#(Bit#(64)) curCycle <- mkReg(0);
    (* no_implicit_conditions *)
    (* fire_when_enabled *)
    rule updateCycle (True);
        curCycle <= curCycle + 1;
    endrule


    // receive the start request from software
    rule start_debug (state == STATE_idle);
        
        let param <- serverStub.acceptRequest_StartDebug();
        serverStub.sendResponse_StartDebug(0);
        state <= STATE_running;
        
    endrule
    
    //
    // Platform-specific debug code goes here.
    //
    rule accept_load_req0 (state == STATE_running);
        
        let addr <- serverStub.acceptRequest_TransferReq();        
        serverStub.sendResponse_TransferReq(0);

        intra_channel.enq(zeroExtend(pack(IntraTestStruct{payload: zeroExtend(addr), payload2: 0, fpga0Timestamp: curCycle, fpga1Timestamp: 0})));

    endrule
    
    rule getResult;
        IntraTestStruct data  = unpack(truncate(intra_channel.first()));
        intra_channel.deq();
        result.enq(tuple2(curCycle,data));
    endrule

    rule accept_load_rsp0 (state == STATE_running);
        
        let dummy <- serverStub.acceptRequest_TransferRsp();

        result.deq;
        let data = tpl_2(result.first);
        serverStub.sendResponse_TransferRsp(tpl_1(result.first), 
                                        data.fpga0Timestamp,
                                        data.fpga1Timestamp,
                                        data.payload, 
                                        data.payload2);
        
    endrule


    // Alternate leds every second from low order reqs to counts
    Reg#(Bit#(TLog#(TMul#(1000000,`MODEL_CLOCK_FREQ)))) ticks <- mkReg(0);
    Reg#(Bool) displayReqs <- mkReg(True);
    Reg#(Bit#(4)) count <- mkReg(0);

    rule tick;
      if(ticks == 1000000*`MODEL_CLOCK_FREQ)
        begin
          ticks <= 0;
          if(!displayReqs)
            begin
              leds.setLEDs('b0101);
            end
          else
            begin
              leds.setLEDs('b1010);               
            end
          displayReqs <= !displayReqs;
        end
      else
        begin
          ticks <= ticks + 1;
        end
   endrule


   // Just to make sure that the JTAG is alive
//   rule dumpJTAG;
//     jtag_channel.send(55); //send an a
//   endrule

//   rule sinkJTAG;
//     let val <- jtag_channel.receive(); //sink things from the jtag
//   endrule
    
endmodule
