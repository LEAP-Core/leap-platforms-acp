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

typedef Bit#(32) MPI_DATA;
typedef Bit#(1)  MPI_CONTROL;

// arches-mpi-vhdl-import

// Import the VHDL device into BSV

// ARCHES_MPI_WIRES

// Wires to be sent to the top level

interface ARCHES_MPI_WIRES;
    
    // clocks
    (* enable = "FPGA1_CLK0_P"   *) method Action wFPGA1_CLK0_P();
    (* enable = "FPGA1_CLK0_N"   *) method Action wFPGA1_CLK0_N();
    (* enable = "FPGA1_CLK1_P"   *) method Action wFPGA1_CLK1_P();
    (* enable = "FPGA1_CLK1_N"   *) method Action wFPGA1_CLK1_N();
    (* enable = "FPGA1_CLK100_P" *) method Action wFPGA1_CLK100_P();
    (* enable = "FPGA1_CLK100_N" *) method Action wFPGA1_CLK100_N();
        
    // LEDs
    (* result = "FPGA1_LED0_Z"     *) method Bit#(1) wFPGA1_LED0_Z();
    (* result = "FPGA1_LED1_Z"     *) method Bit#(1) wFPGA1_LED1_Z();
    (* result = "FPGA1_LED2_Z"     *) method Bit#(1) wFPGA1_LED2_Z();
    (* result = "FPGA1_LED3_Z"     *) method Bit#(1) wFPGA1_LED3_Z();
    (* result = "RAM5_LED_Z"       *) method Bit#(1) wRAM5_LED_Z();
    (* result = "RAM6_LED_Z"       *) method Bit#(1) wRAM6_LED_Z();
    (* result = "FPGA1_TEMP_LED_Z" *) method Bit#(1) wFPGA1_TEMP_LED_Z();
    (* result = "FPGA1_HOT_LED_Z"  *) method Bit#(1) wFPGA1_HOT_LED_Z();
        
    // no clue what these are
    (* prefix = "" *) interface Inout#(Bit#(1)) wFPGA1_SCL;
    (* prefix = "" *) interface Inout#(Bit#(1)) wFPGA1_SDA;

    (* enable = "FPGA1_REG_EN_Z"    *) method Action wFPGA1_REG_EN_Z();
    (* enable = "FPGA1_REG_ADS_Z"   *) method Action wFPGA1_REG_ADS_Z();
    (* enable = "FPGA1_REG_UDS_Z"   *) method Action wFPGA1_REG_UDS_Z();
    (* enable = "FPGA1_REG_LDS_Z"   *) method Action wFPGA1_REG_LDS_Z();
    (* enable = "FPGA1_REG_RESET_Z" *) method Action wFPGA1_REG_RESET_Z();
    (* enable = "FPGA1_REG_RD_WR_Z" *) method Action wFPGA1_REG_RD_WR_Z();

    (* result = "FPGA1_REG_CLK"   *) method Bit#(1) wFPGA1_REG_CLK();
    (* result = "FPGA1_INTR"      *) method Bit#(1) wFPGA1_INTR();
    (* result = "FPGA1_REG_RDY_Z" *) method Bit#(1) wFPGA1_REG_RDY_Z();

    (* prefix = "" *) method Action wFPGA1_CONFIG_DATA((* port = "FPGA1_CONFIG_DATA" *) Bit#(8) data);
    
    // SRAM(s)
    (* prefix = ""               *) interface Inout#(Bit#(1))  wRAM_PWR_ON;
        
    (* prefix = ""               *) interface Inout#(Bit#(32)) wRAM5_DQ;
    (* prefix = ""               *) interface Inout#(Bit#(4))  wRAM5_DQ_P;
    (* enable = "RAM5_CQ"        *) method Action              wRAM5_CQ();
    (* enable = "RAM5_CQ_N"      *) method Action              wRAM5_CQ_N();
    (* result = "RAM5_LD_N"      *) method Bit#(1)             wRAM5_LD_N();
    (* result = "RAM5_RW_N"      *) method Bit#(1)             wRAM5_RW_N();
    (* result = "RAM5_DLL_OFF_N" *) method Bit#(1)             wRAM5_DLL_OFF_N();
    (* result = "RAM5_K"         *) method Bit#(1)             wRAM5_K();
    (* result = "RAM5_K_N"       *) method Bit#(1)             wRAM5_K_N();
    (* prefix = ""               *) interface Inout#(Bit#(22)) wRAM5_ADDR;
    (* prefix = ""               *) interface Inout#(Bit#(4))  wRAM5_BW_N;
    (* enable = "RAM5_MBANK_SEL" *) method Action              wRAM5_MBANK_SEL();
        
    (* prefix = ""               *) interface Inout#(Bit#(32)) wRAM6_DQ;
    (* prefix = ""               *) interface Inout#(Bit#(4))  wRAM6_DQ_P;
    (* enable = "RAM6_CQ"        *) method Action              wRAM6_CQ();
    (* enable = "RAM6_CQ_N"      *) method Action              wRAM6_CQ_N();
    (* result = "RAM6_LD_N"      *) method Bit#(1)             wRAM6_LD_N();
    (* result = "RAM6_RW_N"      *) method Bit#(1)             wRAM6_RW_N();
    (* result = "RAM6_DLL_OFF_N" *) method Bit#(1)             wRAM6_DLL_OFF_N();
    (* result = "RAM6_K"         *) method Bit#(1)             wRAM6_K();
    (* result = "RAM6_K_N"       *) method Bit#(1)             wRAM6_K_N();
    (* prefix = ""               *) interface Inout#(Bit#(22)) wRAM6_ADDR;
    (* prefix = ""               *) interface Inout#(Bit#(4))  wRAM6_BW_N;
    (* enable = "RAM6_MBANK_SEL" *) method Action              wRAM6_MBANK_SEL();
    
    // LVDS Lanes
    (* prefix = ""            *) method Action wLANE_6_DP_P((* port = "LANE_6_DP_P" *) Bit#(19) data);
    (* prefix = ""            *) method Action wLANE_6_DP_N((* port = "LANE_6_DP_N" *) Bit#(19) data);
    (* result = "LANE_7_DP_P" *) method Bit#(19) wLANE_7_DP_P();
    (* result = "LANE_7_DP_N" *) method Bit#(19) wLANE_7_DP_N();

endinterface


// PRIMITIVE_ARCHES_MPI_DEVICE

// The primitive vhdl import which we will wrap in clock-domain synchronizers.

interface PRIMITIVE_ARCHES_MPI_DEVICE;
    
    //
    // Exported Clock and Reset
    //
    
    interface Clock clock;
    interface Reset reset;
    
    //
    // Wires to be sent to the top level
    //

    (* prefix = "" *) interface ARCHES_MPI_WIRES wires;
        
    //
    // Methods for the Driver
    //
    
    method MPI_DATA    data_value();
    method MPI_CONTROL data_control();                          
    method Action      data_deq();
        
    method MPI_DATA    cmd_value();
    method MPI_CONTROL cmd_control();
    method Action      cmd_deq();
    
    method Action      data_enq(MPI_DATA data, MPI_CONTROL control);
    method Action      cmd_enq (MPI_DATA data, MPI_CONTROL control);

endinterface


// mkPrimitiveArchesMPIDevice

// Straightforward import of the VHDL into Bluespec.

import "BVI" system = module mkPrimitiveArchesMPIDevice
    // interface:
                 (PRIMITIVE_ARCHES_MPI_DEVICE);

    default_clock no_clock;
    default_reset no_reset;
  
    //
    // Exported Clock and Reset
    //

    output_clock clock (CLK_OUT);
    output_reset reset (RST_N_OUT) clocked_by(clock);
  
    //
    // Wires to be sent to the top level
    //

    interface ARCHES_MPI_WIRES wires;
    
        // clocks
        method wFPGA1_CLK0_P()   enable (FPGA1_CLK0_P);
        method wFPGA1_CLK0_N()   enable (FPGA1_CLK0_N);
        method wFPGA1_CLK1_P()   enable (FPGA1_CLK1_P);
        method wFPGA1_CLK1_N()   enable (FPGA1_CLK1_N);
        method wFPGA1_CLK100_P() enable (FPGA1_CLK100_P);
        method wFPGA1_CLK100_N() enable (FPGA1_CLK100_N);
            
        // LEDs
        method FPGA1_LED0_Z     wFPGA1_LED0_Z();
        method FPGA1_LED1_Z     wFPGA1_LED1_Z();
        method FPGA1_LED2_Z     wFPGA1_LED2_Z();
        method FPGA1_LED3_Z     wFPGA1_LED3_Z();
        method RAM5_LED_Z       wRAM5_LED_Z();
        method RAM6_LED_Z       wRAM6_LED_Z();
        method FPGA1_TEMP_LED_Z wFPGA1_TEMP_LED_Z();
        method FPGA1_HOT_LED_Z  wFPGA1_HOT_LED_Z();
        
        // no clue what these are
        ifc_inout wFPGA1_SCL (FPGA1_SCL);
        ifc_inout wFPGA1_SDA (FPGA1_SDA);

        method wFPGA1_REG_EN_Z()    enable (FPGA1_REG_EN_Z);
        method wFPGA1_REG_ADS_Z()   enable (FPGA1_REG_ADS_Z);
        method wFPGA1_REG_UDS_Z()   enable (FPGA1_REG_UDS_Z);
        method wFPGA1_REG_LDS_Z()   enable (FPGA1_REG_LDS_Z);
        method wFPGA1_REG_RESET_Z() enable (FPGA1_REG_RESET_Z);
        method wFPGA1_REG_RD_WR_Z() enable (FPGA1_REG_RD_WR_Z);

        method FPGA1_REG_CLK   wFPGA1_REG_CLK();
        method FPGA1_INTR      wFPGA1_INTR();
        method FPGA1_REG_RDY_Z wFPGA1_REG_RDY_Z();

        method wFPGA1_CONFIG_DATA(FPGA1_CONFIG_DATA) enable ((* inhigh *) EN0);
    
        // SRAM(s)
        ifc_inout wRAM_PWR_ON (RAM_PWR_ON);
        
        ifc_inout                wRAM5_DQ (RAM5_DQ);
        ifc_inout                wRAM5_DQ_P (RAM5_DQ_P);
        method                   wRAM5_CQ()              enable (RAM5_CQ);
        method                   wRAM5_CQ_N()            enable (RAM5_CQ_N);
        method    RAM5_LD_N      wRAM5_LD_N();
        method    RAM5_RW_N      wRAM5_RW_N();
        method    RAM5_DLL_OFF_N wRAM5_DLL_OFF_N();
        method    RAM5_K         wRAM5_K();
        method    RAM5_K_N       wRAM5_K_N();
        ifc_inout                wRAM5_ADDR (RAM5_ADDR);
        ifc_inout                wRAM5_BW_N (RAM5_BW_N);
        method                   wRAM5_MBANK_SEL()       enable (RAM5_MBANK_SEL);
        
        ifc_inout                wRAM6_DQ (RAM6_DQ);
        ifc_inout                wRAM6_DQ_P (RAM6_DQ_P);
        method                   wRAM6_CQ()              enable (RAM6_CQ);
        method                   wRAM6_CQ_N()            enable (RAM6_CQ_N);
        method    RAM6_LD_N      wRAM6_LD_N();
        method    RAM6_RW_N      wRAM6_RW_N();
        method    RAM6_DLL_OFF_N wRAM6_DLL_OFF_N();
        method    RAM6_K         wRAM6_K();
        method    RAM6_K_N       wRAM6_K_N();
        ifc_inout                wRAM6_ADDR (RAM6_ADDR);
        ifc_inout                wRAM6_BW_N (RAM6_BW_N);
        method                   wRAM6_MBANK_SEL()       enable (RAM6_MBANK_SEL);
            
        // LVDS Lanes
        method             wLANE_6_DP_P(LANE_6_DP_P) enable ((* inhigh *) EN1);
        method             wLANE_6_DP_N(LANE_6_DP_N) enable ((* inhigh *) EN2);
        method LANE_7_DP_P wLANE_7_DP_P();
        method LANE_7_DP_N wLANE_7_DP_N();
        
    endinterface
        
    //
    // Bluespec-VHDL interface
    //
                          
    // data read methods
    method fsl_mpedata_to_vacc_FSL_S_Data
        data_value()
        ready(fsl_mpedata_to_vacc_FSL_S_Exists)
        clocked_by (clock)
        reset_by (reset);
                              
    method fsl_mpedata_to_vacc_FSL_S_Control
        data_control()
        ready(fsl_mpedata_to_vacc_FSL_S_Exists)
        clocked_by (clock)
        reset_by (reset);
                              
    method
        data_deq()
        ready(fsl_mpedata_to_vacc_FSL_S_Exists)
        enable(fsl_mpedata_to_vacc_FSL_S_Read)
        clocked_by (clock)
        reset_by (reset);
                              
    // cmd read methods
    method fsl_mpecmd_to_vacc_FSL_S_Data
        cmd_value()
        ready(fsl_mpecmd_to_vacc_FSL_S_Exists)
        clocked_by (clock)
        reset_by (reset);
                              
    method fsl_mpecmd_to_vacc_FSL_S_Control
        cmd_control()
        ready(fsl_mpecmd_to_vacc_FSL_S_Exists)
        clocked_by (clock)
        reset_by (reset);
                              
    method
        cmd_deq()
        ready(fsl_mpecmd_to_vacc_FSL_S_Exists)
        enable(fsl_mpecmd_to_vacc_FSL_S_Read)
        clocked_by (clock)
        reset_by (reset);
                              
    // data write methods
    method
        data_enq(fsl_vacc_to_mpedata_FSL_M_Data, fsl_vacc_to_mpedata_FSL_M_Control)
        ready(fsl_vacc_to_mpedata_FSL_M_NotFull)
        enable(fsl_vacc_to_mpedata_FSL_M_Write)
        clocked_by (clock)
        reset_by (reset);
    
    // cmd write methods
    method
        cmd_enq(fsl_vacc_to_mpecmd_FSL_M_Data, fsl_vacc_to_mpecmd_FSL_M_Control)
        ready(fsl_vacc_to_mpecmd_FSL_M_NotFull)
        enable(fsl_vacc_to_mpecmd_FSL_M_Write)
        clocked_by (clock)
        reset_by (reset);

    //
    // Scheduling
    //
    
    // Methods are assumed to Conflict unless we tell Bluespec otherwise.

    // First, lets set the top-level wires to not conflict against each other

    schedule (wires_wFPGA1_CLK0_P, wires_wFPGA1_CLK0_N, wires_wFPGA1_CLK1_P, wires_wFPGA1_CLK1_N,
              wires_wFPGA1_CLK100_P, wires_wFPGA1_CLK100_N, wires_wFPGA1_LED0_Z, wires_wFPGA1_LED1_Z,
              wires_wFPGA1_LED2_Z, wires_wFPGA1_LED3_Z, wires_wRAM5_LED_Z, wires_wRAM6_LED_Z, wires_wFPGA1_TEMP_LED_Z,
              wires_wFPGA1_HOT_LED_Z, wires_wFPGA1_REG_EN_Z, wires_wFPGA1_REG_ADS_Z, wires_wFPGA1_REG_UDS_Z,
              wires_wFPGA1_REG_LDS_Z, wires_wFPGA1_REG_RESET_Z, wires_wFPGA1_REG_RD_WR_Z, wires_wFPGA1_REG_CLK,
              wires_wFPGA1_INTR, wires_wFPGA1_REG_RDY_Z, wires_wFPGA1_CONFIG_DATA,
              wires_wRAM5_CQ, wires_wRAM5_CQ_N, wires_wRAM5_LD_N, wires_wRAM5_RW_N,
              wires_wRAM5_RW_N, wires_wRAM5_DLL_OFF_N, wires_wRAM5_K, wires_wRAM5_K_N,
              wires_wRAM5_MBANK_SEL,
              wires_wRAM6_CQ, wires_wRAM6_CQ_N, wires_wRAM6_LD_N, wires_wRAM6_RW_N,
              wires_wRAM6_RW_N, wires_wRAM6_DLL_OFF_N, wires_wRAM6_K, wires_wRAM6_K_N,
              wires_wRAM6_MBANK_SEL,
              wires_wLANE_6_DP_P, wires_wLANE_6_DP_N, wires_wLANE_7_DP_P, wires_wLANE_7_DP_N)
        CF
             (wires_wFPGA1_CLK0_P, wires_wFPGA1_CLK0_N, wires_wFPGA1_CLK1_P, wires_wFPGA1_CLK1_N,
              wires_wFPGA1_CLK100_P, wires_wFPGA1_CLK100_N, wires_wFPGA1_LED0_Z, wires_wFPGA1_LED1_Z,
              wires_wFPGA1_LED2_Z, wires_wFPGA1_LED3_Z, wires_wRAM5_LED_Z, wires_wRAM6_LED_Z, wires_wFPGA1_TEMP_LED_Z,
              wires_wFPGA1_HOT_LED_Z, wires_wFPGA1_REG_EN_Z, wires_wFPGA1_REG_ADS_Z, wires_wFPGA1_REG_UDS_Z,
              wires_wFPGA1_REG_LDS_Z, wires_wFPGA1_REG_RESET_Z, wires_wFPGA1_REG_RD_WR_Z, wires_wFPGA1_REG_CLK,
              wires_wFPGA1_INTR, wires_wFPGA1_REG_RDY_Z, wires_wFPGA1_CONFIG_DATA,
              wires_wRAM5_CQ, wires_wRAM5_CQ_N, wires_wRAM5_LD_N, wires_wRAM5_RW_N,
              wires_wRAM5_RW_N, wires_wRAM5_DLL_OFF_N, wires_wRAM5_K, wires_wRAM5_K_N,
              wires_wRAM5_MBANK_SEL,
              wires_wRAM6_CQ, wires_wRAM6_CQ_N, wires_wRAM6_LD_N, wires_wRAM6_RW_N,
              wires_wRAM6_RW_N, wires_wRAM6_DLL_OFF_N, wires_wRAM6_K, wires_wRAM6_K_N,
              wires_wRAM6_MBANK_SEL,
              wires_wLANE_6_DP_P, wires_wLANE_6_DP_N, wires_wLANE_7_DP_P, wires_wLANE_7_DP_N,
              
              data_value,
              data_control,
              data_deq,
              cmd_value,
              cmd_control,
              cmd_deq,
              data_enq,
              cmd_enq);
         
    // data_value
    // CF with everything (EXPLICITLY including itself)
    schedule data_value CF (data_value,
                            data_control,
                            data_deq,
                            cmd_value,
                            cmd_control,
                            cmd_deq,
                            data_enq,
                            cmd_enq);

    // data_control
    // CF with everything (EXPLICITLY including itself)
    schedule data_control CF (data_control,
                              data_deq,
                              cmd_value,
                              cmd_control,
                              cmd_deq,
                              data_enq,
                              cmd_enq);
        
    // data_deq
    // SBR with itself
    // CF with everything else (except itself)
    schedule data_deq SBR (data_deq);
    schedule data_deq CF  (cmd_value,
                           cmd_control,
                           cmd_deq,
                           data_enq,
                           cmd_enq);

    // data_enq
    // SBR with itself (a time-honored Bluespec convention)
    // CF with everything else (except itself)
    schedule data_enq SBR (data_enq);
    schedule data_enq CF  (cmd_value,
                           cmd_control,
                           cmd_deq,
                           cmd_enq);

    // cmd_value
    // CF with everything (EXPLICITLY including itself)
    schedule cmd_value CF (cmd_value,
                           cmd_control,
                           cmd_deq,
                           cmd_enq);

    // cmd_control
    // CF with everything (EXPLICITLY including itself)
    schedule cmd_control CF (cmd_control,
                             cmd_deq,
                             cmd_enq);
        
    // cmd_deq
    // SBR with itself
    // CF with everything else (except itself)
    schedule cmd_deq SBR (cmd_deq);
    schedule cmd_deq CF  (cmd_enq);

    // cmd_enq
    // SBR with itself (a time-honored Bluespec convention)
    // CF with everything else (except itself)
    schedule cmd_enq SBR (cmd_enq);
        
endmodule
