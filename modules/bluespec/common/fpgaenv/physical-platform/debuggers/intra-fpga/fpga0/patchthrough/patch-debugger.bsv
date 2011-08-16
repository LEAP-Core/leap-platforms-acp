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
`include "asim/provides/clocks_device.bsh"
`include "asim/provides/physical_channel.bsh"

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
    PHYSICAL_CHANNEL physicalChannel <- mkPhysicalChannel(drivers);
    let leds = drivers.ledsDriver; 

        
    Reg#(Bit#(64)) curCycle <- mkReg(0);
    (* no_implicit_conditions *)
    (* fire_when_enabled *)
    rule updateCycle (True);
        curCycle <= curCycle + 1;
    endrule
    
    rule sendToACP0;
      let data <- physicalChannel.read;
      intra_channel.enq(zeroExtend(data));
    endrule

    rule sendToACP1;
      intra_channel.deq;
      physicalChannel.write(truncate(intra_channel.first));
    endrule



endmodule
