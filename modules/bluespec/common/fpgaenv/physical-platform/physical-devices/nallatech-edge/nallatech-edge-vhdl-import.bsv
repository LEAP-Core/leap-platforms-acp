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

// NALLATECH_EDGE_WIRES

// Wires to be sent to the top level

interface NALLATECH_EDGE_WIRES;
    
    // clocks and reset
    (* enable = "CLK100P" *) method Action wCLK100P();
    (* enable = "CLK100N" *) method Action wCLK100N();
    
    // config registers
    (* enable = "REG_CLK"     *) method Action             wREG_CLK();
    (* enable = "REG_RESET_Z" *) method Action             wREG_RESET_Z();    
    (* prefix = "REG_CONFIG_DATA" *) interface Inout#(Bit#(8)) wCONFIG_DATA;
    (* enable = "REG_UDS_Z"   *) method Action             wREG_UDS_Z();
    (* enable = "REG_LDS_Z"   *) method Action             wREG_LDS_Z();
    (* enable = "REG_ADS_Z"   *) method Action             wREG_ADS_Z();
    (* enable = "REG_EN_Z"    *) method Action             wREG_EN_Z();
    (* result = "REG_RDY_Z"   *) method Bit#(1)            wREG_RDY_Z();
    (* enable = "REG_RD_WR_Z" *) method Action             wREG_RD_WR_Z();
                                 
    // LVDS lanes and clocks
    (* prefix = "" *) method Action wLVDS_RX_LANE_P((* port = "LVDS_RX_LANE_P" *) Bit#(34) data);
    (* prefix = "" *) method Action wLVDS_RX_LANE_N((* port = "LVDS_RX_LANE_N" *) Bit#(34) data);
    (* prefix = "" *) method Action wLVDS_RX_CLK_P ((* port = "LVDS_RX_CLK_P"  *) Bit#(2)  clk);
    (* prefix = "" *) method Action wLVDS_RX_CLK_N ((* port = "LVDS_RX_CLK_N"  *) Bit#(2)  clk);

    // (* prefix = "" *) method Action wLVDS_RX_CLK_N ((* port = "LVDS_LINK_SC_IN" *) Bit#(5) lvds);
    // (* result = "LVDS_LINK_SC_OUT" *) method Bit#(5) wLVDS_LINK_SC_OUT();

    (* result = "LVDS_TX_LANE_P" *) method Bit#(34) wLVDS_TX_LANE_P();
    (* result = "LVDS_TX_LANE_N" *) method Bit#(34) wLVDS_TX_LANE_N();
    (* result = "LVDS_TX_CLK_P"  *) method Bit#(2)  wLVDS_TX_CLK_P();
    (* result = "LVDS_TX_CLK_N"  *) method Bit#(2)  wLVDS_TX_CLK_N();

    // EEPROMs
    (* result = "EEPROM_SCL" *) method Bit#(1)            wSCL;
    (* prefix = "EEPROM_SDA" *) interface Inout#(Bit#(1)) wSDA;

    // LEDs
    (* result = "SYS_LED_OUT" *) method Bit#(6) wSYS_LED_OUT();
                                     
    // RAM
    // moved to SRAM device (* result = "RAM_PWR_ON" *) method Bit#(1) wRAM_PWR_ON();
    // moved to SRAM device (* result = "RAM_LEDS"   *) method Bit#(2) wRAM_LEDS();
    (* enable = "RAM_PG"     *) method Action  wRAM_PG();
                                    
    // misc
    (* enable = "MGT_PG" *) method Action wMGT_PG();
    
endinterface

// interface NALLATECH_COMM_CONTROL
// This is the inout for controlling the intra FPGA communication lines

typedef Inout#(Bit#(48)) NALLATECH_COMM_CONTROL;

// PRIMITIVE_NALLATECH_EDGE_DEVICE

// The primitive vhdl import which we will wrap in clock-domain synchronizers.

interface PRIMITIVE_NALLATECH_EDGE_DEVICE;
    
    //
    // Exported Clock and Reset
    //
    
    interface Clock clock;
    interface Reset reset;
    
    interface Clock rawClock;
    interface Clock oscClock;

    // Control for intra-fpga channel
  
    interface NALLATECH_COMM_CONTROL communication_control;
    
    //
    // SRAM Clocking
    //
    
    interface Clock ramClk0;
    interface Clock ramClk200;
    interface Clock ramClk270;
    method Bit#(1) ramClkLocked();
    
    //
    // Register Clock
    //
        
    interface Clock regClock;

    //
    // Wires to be sent to the top level
    //

    (* prefix = "" *) interface NALLATECH_EDGE_WIRES wires;
        
    //
    // Methods for the Driver
    //
    
    // channel interface
    method Action              enq(NALLATECH_FIFO_DATA data);
    method NALLATECH_FIFO_DATA first();
    method Action              deq();
              
    // leds input
    method Action setLEDs(Bit#(4) leds);

    // register interface

    // Keep the following in mind while using the register interface:
    // 1. Most methods are un-gated, so use the Booleans regReadReq() and regWriteReq() to
    //    figure out which requests are actually active
    // 2. Be sure to acknowledge a write using regAckWrite(), otherwise the host system could hang!
    //    Reads are automatically acked when you return the read value. Until then the system is
    //    in an unsteady state so finish the read asap!
    // 3. It might not be safe to ack the Write in the same cycle that you receive it (which
    //    creates a combinational path from the ready to the enable), because the Edge VHDL might
    //    use a combinational loop from our ack back into the write ready. Wait one cycle. If you
    //    see that this is not a problem, then regAckWrite() need not be a separate method, the
    //    ack can be hooked to the enable of the writeData() method (making it an ActionValue method).
            
    method NALLATECH_REG_ADDR  regAddr();
    method Bool                regReadReq();
    method Action              regSendReadData(NALLATECH_REG_DATA data);
    method Bool                regWriteReq();
    method NALLATECH_REG_DATA  regWriteData();
    method Action              regAckWrite();
        
endinterface

// typedefs to match the nallatech function names in vhdl

typedef Tuple3#(Integer,Integer,Integer) LOCAL_ID;
typedef Tuple3#(Integer,Integer,Integer) EXTERNAL_ID;

// mkPrimitiveNallatechEDGEDevice

// Straightforward import of the VHDL into Bluespec.

import "BVI" nallatech_edge_vhdl = module mkPrimitiveNallatechEdgeDevice
    #(LOCAL_ID localID,
      EXTERNAL_ID externalID,
      Integer rxLanes,
      Integer txLanes)
    // interface:
                 (PRIMITIVE_NALLATECH_EDGE_DEVICE);

    // parameters to the edge module instantiation
    parameter local_id_layer  = tpl_1(localID);
    parameter local_id_fpga   = tpl_2(localID);
    parameter local_id_number = tpl_3(localID);

    parameter external_id_layer  = tpl_1(externalID);
    parameter external_id_fpga   = tpl_2(externalID);
    parameter external_id_number = tpl_3(externalID);

    parameter rx_lanes = rxLanes;
    parameter tx_lanes = txLanes;

    default_clock no_clock;
    default_reset no_reset;
  
    //
    // Exported Clock and Reset
    //

    output_clock clock (CLK_OUT);
    output_reset reset (RST_N_OUT) clocked_by(clock);
  
    output_clock oscClock (OSC_CLK_OUT);
    output_clock rawClock (RAW_CLK_OUT);


    output_clock ramClk0   (ram_clk0);
    output_clock ramClk200 (ram_clk200);
    output_clock ramClk270 (ram_clk270);

    output_clock regClock (USER_REG_CLK_OUT);

    ifc_inout communication_control (INTRA_FPGA_LVDS_CTRL);	

    method ram_clk_locked ramClkLocked();

    //
    // Wires to be sent to the top level
    //

    interface NALLATECH_EDGE_WIRES wires;
    
        // clocks
        method wCLK100P() enable (CLK100P);
        method wCLK100N() enable (CLK100N);
            
        // config registers
        method           wREG_CLK()     enable (REG_CLK);
        method           wREG_RESET_Z() enable (REG_RESET_Z);
        ifc_inout        wCONFIG_DATA          (CONFIG_DATA);
        method           wREG_UDS_Z()   enable (REG_UDS_Z);
        method           wREG_LDS_Z()   enable (REG_LDS_Z);
        method           wREG_ADS_Z()   enable (REG_ADS_Z);
        method           wREG_EN_Z()    enable (REG_EN_Z);
        method REG_RDY_Z wREG_RDY_Z();
        method           wREG_RD_WR_Z() enable (REG_RD_WR_Z);

        // LVDS lanes and clocks
        method wLVDS_RX_LANE_P(LVDS_RX_LANE_P) enable ((* inhigh *) EN0);
        method wLVDS_RX_LANE_N(LVDS_RX_LANE_N) enable ((* inhigh *) EN1);
        method wLVDS_RX_CLK_P (LVDS_RX_CLK_P)  enable ((* inhigh *) EN2);
        method wLVDS_RX_CLK_N (LVDS_RX_CLK_N)  enable ((* inhigh *) EN3);
            
        method LVDS_TX_LANE_P wLVDS_TX_LANE_P();
        method LVDS_TX_LANE_N wLVDS_TX_LANE_N();
        method LVDS_TX_CLK_P  wLVDS_TX_CLK_P();
        method LVDS_TX_CLK_N  wLVDS_TX_CLK_N();
        
        // EEPROMs
        method EEPROM_SCL wSCL();
        ifc_inout         wSDA(EEPROM_SDA);

        // LEDs
        method SYS_LED_OUT wSYS_LED_OUT();
                                     
        // RAM
        // method RAM_PWR_ON wRAM_PWR_ON();
        // method RAM_LEDS   wRAM_LEDS();
        method            wRAM_PG() enable (RAM_PG);
                                    
        // misc
        method wMGT_PG() enable (MGT_PG);

    endinterface
        
    //
    // Bluespec-VHDL interface
    //
                          
    method enq (TX_DATA)
        ready      (TX_DATA_NOT_FULL)
        enable     (TX_DATA_VALID)
        clocked_by (clock)
        reset_by   (reset);
                              
    method RX_DATA first()
        ready      (RX_DATA_READY)
        clocked_by (clock)
        reset_by   (reset);
        
    method deq()
        ready      (RX_DATA_READY)
        enable     (RX_DATA_READ)
        clocked_by (clock)
        reset_by   (reset);
                          
    // register
    method USER_REG_ADDR_OUT regAddr()
        clocked_by (regClock)
        reset_by (no_reset);
        
    method USER_REG_RDEN_OUT regReadReq()
        clocked_by (regClock)
        reset_by (no_reset);

    method regSendReadData(USER_REG_RDATA_IN)
        enable (USER_REG_RDY_IN)
        clocked_by (regClock)
        reset_by (no_reset);        
        
    method USER_REG_WREN_OUT regWriteReq()
        clocked_by (regClock)
        reset_by (no_reset);        
        
    method USER_REG_WDATA_OUT regWriteData()
        clocked_by (regClock)
        reset_by (no_reset);        

    method regAckWrite()
        enable (USER_REG_WRACK_IN)
        clocked_by (regClock)
        reset_by (no_reset);


    method setLEDs(leds) enable ((* inhigh *) EN_LEDS) clocked_by(clock) reset_by(reset); 


    //
    // Scheduling
    //
    
    // Methods are assumed to Conflict unless we tell Bluespec otherwise.

    // First, let's set the top-level wires to not conflict against each other or interface methods

    schedule (wires_wCLK100P, wires_wCLK100N, wires_wREG_CLK, wires_wREG_RESET_Z, wires_wREG_UDS_Z,
              wires_wREG_LDS_Z, wires_wREG_ADS_Z, wires_wREG_EN_Z, wires_wREG_RDY_Z, wires_wREG_RD_WR_Z,
              wires_wLVDS_RX_LANE_P, wires_wLVDS_RX_LANE_N, wires_wLVDS_RX_CLK_P, wires_wLVDS_RX_CLK_N,
              wires_wLVDS_TX_LANE_P, wires_wLVDS_TX_LANE_N, wires_wLVDS_TX_CLK_P, wires_wLVDS_TX_CLK_N,
              wires_wSCL, wires_wSYS_LED_OUT, /*wires_wRAM_PWR_ON, wires_wRAM_LEDS,*/ wires_wRAM_PG,
              ramClkLocked,
              wires_wMGT_PG)
        
        CF
        
             (wires_wCLK100P, wires_wCLK100N, wires_wREG_CLK, wires_wREG_RESET_Z, wires_wREG_UDS_Z,
              wires_wREG_LDS_Z, wires_wREG_ADS_Z, wires_wREG_EN_Z, wires_wREG_RDY_Z, wires_wREG_RD_WR_Z,
              wires_wLVDS_RX_LANE_P, wires_wLVDS_RX_LANE_N, wires_wLVDS_RX_CLK_P, wires_wLVDS_RX_CLK_N,
              wires_wLVDS_TX_LANE_P, wires_wLVDS_TX_LANE_N, wires_wLVDS_TX_CLK_P, wires_wLVDS_TX_CLK_N,
              wires_wSCL, wires_wSYS_LED_OUT, /*wires_wRAM_PWR_ON, wires_wRAM_LEDS,*/ wires_wRAM_PG,
              wires_wMGT_PG,
              ramClkLocked,
              enq, first, deq, setLEDs);
    
    // setLeds is CF with everything but itself

    schedule (setLEDs)
        
        CF
        
             (wires_wCLK100P, wires_wCLK100N, wires_wREG_CLK, wires_wREG_RESET_Z, wires_wREG_UDS_Z,
              wires_wREG_LDS_Z, wires_wREG_ADS_Z, wires_wREG_EN_Z, wires_wREG_RDY_Z, wires_wREG_RD_WR_Z,
              wires_wLVDS_RX_LANE_P, wires_wLVDS_RX_LANE_N, wires_wLVDS_RX_CLK_P, wires_wLVDS_RX_CLK_N,
              wires_wLVDS_TX_LANE_P, wires_wLVDS_TX_LANE_N, wires_wLVDS_TX_CLK_P, wires_wLVDS_TX_CLK_N,
              wires_wSCL, wires_wSYS_LED_OUT, /*wires_wRAM_PWR_ON, wires_wRAM_LEDS,*/ wires_wRAM_PG,
              wires_wMGT_PG,
              ramClkLocked,
              enq, first, deq);

    schedule (setLEDs) C (setLEDs); 


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
        
    // regAddr()
    schedule regAddr CF (enq, first, deq, regAddr, regReadReq, regSendReadData, regWriteReq, regWriteData, regAckWrite);

    // regReadReq()
    schedule regReadReq CF (enq, first, deq, regReadReq, regSendReadData, regWriteReq, regWriteData, regAckWrite);

    // regSendReadData()
    schedule regSendReadData SBR (regSendReadData);
    schedule regSendReadData CF  (enq, first, deq, regWriteReq, regWriteData, regAckWrite);
        
    // regWriteReq()
    schedule regWriteReq CF (enq, first, deq, regWriteReq, regWriteData, regAckWrite);

    // regWriteData()
    schedule regWriteData CF (enq, first, deq, regWriteData, regAckWrite);
        
    // regAckWrite()
    schedule regAckWrite SBR (regAckWrite);
    schedule regAckWrite CF  (enq, first, deq);

endmodule
