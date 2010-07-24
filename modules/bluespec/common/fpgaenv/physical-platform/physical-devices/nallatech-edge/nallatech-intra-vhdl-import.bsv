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

import Clocks::*;

//
// Types
//

typedef Bit#(256) NALLATECH_FIFO_DATA;
typedef Bit#(16)  NALLATECH_REG_DATA;
typedef Bit#(13)  NALLATECH_REG_ADDR;

// nallatech-edge-vhdl-import

// Import the VHDL device into BSV

// NALLATECH_INTRA_WIRES

// Wires to be sent to the top level

interface NALLATECH_INTRA_WIRES;
    
                                 
    // LVDS lanes and clocks
    (* prefix = "" *) method Action wLVDS_RX_LANE_P((* port = "LVDS_RX_LANE_P" *) Bit#(34) data);
    (* prefix = "" *) method Action wLVDS_RX_LANE_N((* port = "LVDS_RX_LANE_N" *) Bit#(34) data);
    (* prefix = "" *) method Action wLVDS_RX_CLK_P ((* port = "LVDS_RX_CLK_P"  *) Bit#(2)  clk);
    (* prefix = "" *) method Action wLVDS_RX_CLK_N ((* port = "LVDS_RX_CLK_N"  *) Bit#(2)  clk);

    (* result = "LVDS_TX_LANE_P" *) method Bit#(34) wLVDS_TX_LANE_P();
    (* result = "LVDS_TX_LANE_N" *) method Bit#(34) wLVDS_TX_LANE_N();
    (* result = "LVDS_TX_CLK_P"  *) method Bit#(2)  wLVDS_TX_CLK_P();
    (* result = "LVDS_TX_CLK_N"  *) method Bit#(2)  wLVDS_TX_CLK_N();

endinterface

// interface NALLATECH_INTRA_COMM_CONTROL
// This is the inout for controlling the intra FPGA communication lines

typedef Inout#(Bit#(48)) NALLATECH_INTRA_COMM_CONTROL;

// PRIMITIVE_NALLATECH_INTRA_DEVICE

// The primitive vhdl import which we will wrap in clock-domain synchronizers.

interface PRIMITIVE_NALLATECH_INTRA_DEVICE;
    
  
    interface NALLATECH_INTRA_COMM_CONTROL communication_control;
    
    //
    // Wires to be sent to the top level
    //

    (* prefix = "" *) interface NALLATECH_INTRA_WIRES wires;
        
    //
    // Methods for the Driver
    //
    
    // channel interface
    method Action              enq(NALLATECH_FIFO_DATA data);
    method NALLATECH_FIFO_DATA first();
    method Action              deq();
              
endinterface

// typedefs to match the nallatech function names in vhdl

typedef Tuple3#(Integer,Integer,Integer) LOCAL_ID;
typedef Tuple3#(Integer,Integer,Integer) EXTERNAL_ID;

// mkPrimitiveNallatechIntraDevice

// Straightforward import of the VHDL into Bluespec.

import "BVI" nallatech_intra_vhdl = module mkPrimitiveNallatechIntraDevice
    #(Clock clk100In,
      LOCAL_ID localID,
      EXTERNAL_ID externalID,
      Integer rxLanes,
      Integer txLanes)
    // interface:
                 (PRIMITIVE_NALLATECH_INTRA_DEVICE);

    // parameters to the edge module instantiation
    parameter local_id_layer  = tpl_1(localID);
    parameter local_id_fpga   = tpl_2(localID);
    parameter local_id_number = tpl_3(localID);

    parameter external_id_layer  = tpl_1(externalID);
    parameter external_id_fpga   = tpl_2(externalID);
    parameter external_id_number = tpl_3(externalID);

    parameter rx_lanes = rxLanes;
    parameter tx_lanes = txLanes;

    default_clock sysClk(sys_clk, (*unused*) sysClkGate) <- exposeCurrentClock();
    default_reset sRst(srst) <- exposeCurrentReset();
  
    //
    // Exported Clock and Reset
    //

    input_clock sysClk100 (clk100,(*unused*) clk100Gate) = clk100In; 

    ifc_inout communication_control (INTRA_FPGA_LVDS_CTRL) clocked_by(no_clock) reset_by(no_reset);	

    //
    // Wires to be sent to the top level
    //

    interface NALLATECH_INTRA_WIRES wires;
    
        // LVDS lanes and clocks
        method wLVDS_RX_LANE_P(LVDS_RX_LANE_P) enable ((* inhigh *) EN0) clocked_by(no_clock) reset_by(no_reset);
        method wLVDS_RX_LANE_N(LVDS_RX_LANE_N) enable ((* inhigh *) EN1) clocked_by(no_clock) reset_by(no_reset);
        method wLVDS_RX_CLK_P (LVDS_RX_CLK_P)  enable ((* inhigh *) EN2) clocked_by(no_clock) reset_by(no_reset);
        method wLVDS_RX_CLK_N (LVDS_RX_CLK_N)  enable ((* inhigh *) EN3) clocked_by(no_clock) reset_by(no_reset);
            
        method LVDS_TX_LANE_P wLVDS_TX_LANE_P() clocked_by(no_clock) reset_by(no_reset);
        method LVDS_TX_LANE_N wLVDS_TX_LANE_N() clocked_by(no_clock) reset_by(no_reset);
        method LVDS_TX_CLK_P  wLVDS_TX_CLK_P() clocked_by(no_clock) reset_by(no_reset);
        method LVDS_TX_CLK_N  wLVDS_TX_CLK_N() clocked_by(no_clock) reset_by(no_reset);
        
    endinterface
        
    //
    // Bluespec-VHDL interface
    //
                          
    method enq (TX_DATA)
        ready      (TX_DATA_NOT_FULL)
        enable     (TX_DATA_VALID);
                              
    method RX_DATA first()
        ready      (RX_DATA_READY);
        
    method deq()
        ready      (RX_DATA_READY)
        enable     (RX_DATA_READ);

    //
    // Scheduling
    //
    
    // Methods are assumed to Conflict unless we tell Bluespec otherwise.

    // First, let's set the top-level wires to not conflict against each other or interface methods

    schedule (wires_wLVDS_RX_LANE_P, wires_wLVDS_RX_LANE_N, wires_wLVDS_RX_CLK_P, wires_wLVDS_RX_CLK_N,
              wires_wLVDS_TX_LANE_P, wires_wLVDS_TX_LANE_N, wires_wLVDS_TX_CLK_P, wires_wLVDS_TX_CLK_N)
        
        CF
        
             (wires_wLVDS_RX_LANE_P, wires_wLVDS_RX_LANE_N, wires_wLVDS_RX_CLK_P, wires_wLVDS_RX_CLK_N,
              wires_wLVDS_TX_LANE_P, wires_wLVDS_TX_LANE_N, wires_wLVDS_TX_CLK_P, wires_wLVDS_TX_CLK_N,
              enq, first, deq);
    
    // enq
    // SBR with itself (a time-honored Bluespec convention)
    // CF with everything else (except itself)
    schedule enq SBR (enq);
    schedule enq CF  (first, deq);
        
    // first
    // CF with everything (EXPLICITLY including itself)
    schedule first CF (first, deq);

    // data_deq
    // SBR with itself
    // CF with everything else (except itself)
    schedule deq SBR (deq);
        
endmodule
