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

//
// Types
//


// ddr-sram-vhdl-import

// Import the VHDL device into BSV

// Convenience constants. These can overload the corresponding parameters in the VHDL,
// though it is unknown what effect changing these would have.
`define SRAM_ADDR_WIDTH 21 
`define SRAM_BURST_LENGTH 2
`define SRAM_BW_WIDTH 4
`define SRAM_CLK_FREQ 200
`define SRAM_CLK_WIDTH 1
`define SRAM_CQ_WIDTH 1
`define SRAM_DATA_WIDTH 36

//
// Data sizes are fixed by the VHDL DRAM controller and the hardware and are
// not flexible.
//

// The smallest addressable word:
typedef 32 FPGA_DDR_WORD_SZ;
typedef Bit#(FPGA_DDR_WORD_SZ) FPGA_DDR_WORD;

// The DRAM controller uses both clock edges to pass data, which appears to
// be 2 words per cycle.  Addresses are little endian, so the low address
// goes in the low bits.  Most of the interfaces in this module pass:
typedef TMul#(2, FPGA_DDR_WORD_SZ) FPGA_DDR_DUALEDGE_DATA_SZ;
typedef Bit#(FPGA_DDR_DUALEDGE_DATA_SZ) FPGA_DDR_DUALEDGE_DATA;

// The DRAM controller reads and writes multiple dual-edge data values for
// a single request.  The number of dual-edge data values per request is:
typedef TDiv#(`SRAM_BURST_LENGTH, 2) FPGA_DDR_BURST_LENGTH;

// Each byte in a write may be disabled for writes using a bit mask.
// !!! NOTE: to conform to the controller, a mask bit is 0 to request a write !!!
typedef Bit#(TDiv#(FPGA_DDR_WORD_SZ, 8)) FPGA_DDR_WORD_MASK;
typedef Bit#(TDiv#(FPGA_DDR_DUALEDGE_DATA_SZ, 8)) FPGA_DDR_DUALEDGE_DATA_MASK;

// Capacity of the memory (addressing FPGA_DDR_WORDs):
typedef `SRAM_ADDR_WIDTH FPGA_DDR_ADDRESS_SZ;
typedef Bit#(FPGA_DDR_ADDRESS_SZ) FPGA_DDR_ADDRESS;

typedef enum {
	      WRITE = 0,
	      READ  = 1
	      } DDR2Command deriving(Bits, Eq);



// DDR2_WIRES

// Wires to be sent to the top level

interface DDR2_WIRES;

    // global
    (* result = "ram_pwr_on" *) method Bit#(1) w_ram_pwr_on();
    (* result = "ram_leds"   *) method Bit#(2) w_ram_leds();

    // RAM 1 or 5
    (* prefix = "" *) interface Inout#(Bit#(`SRAM_DATA_WIDTH)) w_ddrii_dq;

    (* result = "ddrii_sa" *) method Bit#(`SRAM_ADDR_WIDTH) w_ddrii_sa();
    (* result = "ddrii_ld_n" *) method Bit#(1) w_ddrii_ld_n();
    (* result = "ddrii_rw_n" *) method Bit#(1) w_ddrii_rw_n();
    (* result = "ddrii_dll_off_n" *) method Bit#(1) w_ddrii_dll_off_n();
    (* result = "ddrii_bw_n" *) method Bit#(`SRAM_BW_WIDTH) w_ddrii_bw_n();
    (* prefix = "" *) method Action w_masterbank_sel_pin((* port = "masterbank_sel_pin" *) Bit#(1) data);
    // (* result = "masterbank_sel_pin_out" *) method Bit#(1) w_masterbank_sel_pin_out();

    (* result = "cal_done" *) method Bit#(1) w_cal_done();
    // (* prefix = "" *) method Action w_idelay_ctrl_ready((* port = "idelay_ctrl_ready" *) Bit#(1) data);

    (* prefix = "" *) method Action w_ddrii_cq((* port = "ddrii_cq" *) Bit#(`SRAM_CQ_WIDTH) data);
    (* prefix = "" *) method Action w_ddrii_cq_n((* port = "ddrii_cq_n" *) Bit#(`SRAM_CQ_WIDTH) data);
    (* result = "ddrii_k" *) method Bit#(`SRAM_CLK_WIDTH) w_ddrii_k();
    (* result = "ddrii_k_n" *) method Bit#(`SRAM_CLK_WIDTH) w_ddrii_k_n();
    (* result = "ddrii_c" *) method Bit#(`SRAM_CLK_WIDTH) w_ddrii_c();
    (* result = "ddrii_c_n" *) method Bit#(`SRAM_CLK_WIDTH) w_ddrii_c_n();
/*
    // RAM 2 or 6
    (* prefix = "" *) interface Inout#(Bit#(`SRAM_DATA_WIDTH)) w_ddrii_dq_2;

    (* result = "ddrii_sa_2" *) method Bit#(`SRAM_ADDR_WIDTH) w_ddrii_sa_2();
    (* result = "ddrii_ld_n_2" *) method Bit#(1) w_ddrii_ld_n_2();
    (* result = "ddrii_rw_n_2" *) method Bit#(1) w_ddrii_rw_n_2();
    (* result = "ddrii_dll_off_n_2" *) method Bit#(1) w_ddrii_dll_off_n_2();
    (* result = "ddrii_bw_n_2" *) method Bit#(`SRAM_BW_WIDTH) w_ddrii_bw_n_2();
    (* prefix = "" *) method Action w_masterbank_sel_pin_2((* port = "masterbank_sel_pin_2" *) Bit#(1) data);

    (* result = "cal_done_2" *) method Bit#(1) w_cal_done_2();
    // (* prefix = "" *) method Action w_idelay_ctrl_ready_2((* port = "idelay_ctrl_ready_2" *) Bit#(1) data);

    (* prefix = "" *) method Action w_ddrii_cq_2((* port = "ddrii_cq_2" *) Bit#(`SRAM_CQ_WIDTH) data);
    (* prefix = "" *) method Action w_ddrii_cq_n_2((* port = "ddrii_cq_n_2" *) Bit#(`SRAM_CQ_WIDTH) data);
    (* result = "ddrii_k_2" *) method Bit#(`SRAM_CLK_WIDTH) w_ddrii_k_2();
    (* result = "ddrii_k_n_2" *) method Bit#(`SRAM_CLK_WIDTH) w_ddrii_k_n_2();
    (* result = "ddrii_c_2" *) method Bit#(`SRAM_CLK_WIDTH) w_ddrii_c_2();
    (* result = "ddrii_c_n_2" *) method Bit#(`SRAM_CLK_WIDTH) w_ddrii_c_n_2();
*/
endinterface

interface DDR2_PRIM_DRIVER;

    // Address, cmd=0 if performing a write, cmd=1 for read.
    method Action enqueue_address(FPGA_DDR_ADDRESS addr, DDR2Command cmd);
    method Bool   enqueue_address_RDY();

    // Data rise and fall share a single enable, so it seems we have to make them a single method.
    // If this becomes a problem we can try to separate it into two.
    // Note that the mask is negatively-enabled, so 0=perform write.
    method Action enqueue_data(Bit#(`SRAM_DATA_WIDTH) data_rise, Bit#(`SRAM_BW_WIDTH) bw_mask_rise_n, Bit#(`SRAM_DATA_WIDTH) data_fall, Bit#(`SRAM_BW_WIDTH) bw_mask_fall_n);
    method Bool   enqueue_data_RDY();

    // These share a Ready, but Bluespec has no problem with this. 
    // Alternatively, these could also be combined into a single method which returns a struct.
    method Bit#(`SRAM_DATA_WIDTH) dequeue_data_rise();
    method Bit#(`SRAM_DATA_WIDTH) dequeue_data_fall();
    method Bool dequeue_data_RDY();

endinterface

// PRIMITIVE_DDR_SRAM_DEVICE

// The primitive vhdl import which we will wrap in a shim to deal with DDR.

interface PRIMITIVE_DDR_SRAM_DEVICE;

    //
    // Wires to be sent to the top level
    //

    (* prefix = "" *) interface DDR2_WIRES wires;

    // exported clock and reset
    interface Clock clk_out;
    interface Reset rst_out;

    // Two drivers for Blusepec-VHDL-interaction, one for each SRAM.
    (* prefix = "" *) interface DDR2_PRIM_DRIVER ram1;
    // (* prefix = "" *) interface DDR2_PRIM_DRIVER ram2;

endinterface


// mkPrimitiveDDRSRAMDevice

// Straightforward import of the VHDL into Bluespec.

import "BVI" ddr2_sram = module mkPrimitiveDDRSRAMDevice
    #(Clock ram_clk0,
      Clock ram_clk200,
      Clock ram_clk270,
      Bit#(1) ram_clkLocked,
      Reset topLevelReset)
    // interface:
                 (PRIMITIVE_DDR_SRAM_DEVICE);

    default_clock no_clock;
    default_reset (sys_rst_n) clocked_by (no_clock) = topLevelReset;

    parameter ADDR_WIDTH = `SRAM_ADDR_WIDTH;
    parameter BURST_LENGTH = `SRAM_BURST_LENGTH;
    parameter BW_WIDTH = `SRAM_BW_WIDTH;
    parameter CLK_FREQ = `SRAM_CLK_FREQ;
    parameter CLK_WIDTH = `SRAM_CLK_WIDTH;
    parameter CQ_WIDTH = `SRAM_CQ_WIDTH;
    parameter DATA_WIDTH = `SRAM_DATA_WIDTH;

    //
    // Input Clocks from the Edge device.
    //

    input_clock   (clk_0)      = ram_clk0;
    input_clock   (clk_200)    = ram_clk200;
    input_clock   (clk_270)    = ram_clk270;

    // RAM clk_locked port. Could also do this as a method, but that could get messy.
    port locked = ram_clkLocked;

    // By sending the clock and reset out we make the bluespec compiler more happy.
    output_clock clk_out(clk0_out);
    output_reset rst_out(rst0_n_out) clocked_by (clk_out);
    
    //
    // Wires to be sent to the top level
    //

    interface DDR2_WIRES wires;
        
        // global
        method ram_pwr_on w_ram_pwr_on();
        method ram_leds   w_ram_leds();
        
        // RAM 1 or 5
        ifc_inout w_ddrii_dq(ddrii_dq);

        method ddrii_sa         w_ddrii_sa();
        method ddrii_ld_n       w_ddrii_ld_n();
        method ddrii_rw_n       w_ddrii_rw_n();
        method ddrii_dll_off_n  w_ddrii_dll_off_n();
        method ddrii_bw_n       w_ddrii_bw_n();
        method cal_done         w_cal_done();

        method w_masterbank_sel_pin(masterbank_sel_pin) enable ((* inhigh *) EN0);
        // method masterbank_sel_pin_out w_masterbank_sel_pin_out();

        // method w_idelay_ctrl_ready(idelay_ctrl_ready) enable ((* inhigh *) EN1);
        method w_ddrii_cq(ddrii_cq) enable ((* inhigh *) EN2);
        method w_ddrii_cq_n(ddrii_cq_n) enable ((* inhigh *) EN3);

        method ddrii_k          w_ddrii_k();
        method ddrii_k_n        w_ddrii_k_n();
        method ddrii_c          w_ddrii_c();
        method ddrii_c_n        w_ddrii_c_n();

        // RAM 2 or 6
/*
        ifc_inout w_ddrii_dq_2(ddrii_dq_2);

        method ddrii_sa_2         w_ddrii_sa_2();
        method ddrii_ld_n_2       w_ddrii_ld_n_2();
        method ddrii_rw_n_2       w_ddrii_rw_n_2();
        method ddrii_dll_off_n_2  w_ddrii_dll_off_n_2();
        method ddrii_bw_n_2       w_ddrii_bw_n_2();
        method cal_done_2         w_cal_done_2();

        method w_masterbank_sel_pin_2(masterbank_sel_pin_2) enable ((* inhigh *) EN4);
        // method w_idelay_ctrl_ready_2(idelay_ctrl_ready_2) enable ((* inhigh *) EN5);
        method w_ddrii_cq_2(ddrii_cq_2) enable ((* inhigh *) EN6);
        method w_ddrii_cq_n_2(ddrii_cq_n_2) enable ((* inhigh *) EN7);

        method ddrii_k_2          w_ddrii_k_2();
        method ddrii_k_n_2        w_ddrii_k_n_2();
        method ddrii_c_2          w_ddrii_c_2();
        method ddrii_c_n_2        w_ddrii_c_n_2();
*/
 
     endinterface

    //
    // Bluespec-VHDL interface
    //
    interface DDR2_PRIM_DRIVER ram1;

        method enqueue_address(user_addr, user_cmd)
            enable (user_addr_wr_en)
            clocked_by (clk_out)
            reset_by (rst_out);

        method addr_fifo_not_full enqueue_address_RDY()
            clocked_by (clk_out)
            reset_by (rst_out);

        method enqueue_data(user_wr_data_rise, user_bw_n_rise, user_wr_data_fall, user_bw_n_fall)
            enable (user_wrdata_wr_en)
            clocked_by (clk_out)
            reset_by (rst_out);
            
        method wrdata_fifo_not_full enqueue_data_RDY()
            clocked_by (clk_out)
            reset_by (rst_out);

        method user_rd_data_rise dequeue_data_rise()
            clocked_by (clk_out)
            reset_by (rst_out);

        method user_rd_data_fall dequeue_data_fall()
            clocked_by (clk_out)
            reset_by (rst_out);

        method rd_data_valid dequeue_data_RDY()
            clocked_by (clk_out)
            reset_by (rst_out);

    endinterface
/*
    interface DDR2_PRIM_DRIVER ram2;

        method enqueue_address(user_addr_2, user_cmd_2)
            ready  (addr_fifo_not_full_2)
            enable (user_addr_wr_en_2)
            clocked_by (clk_out)
            reset_by (rst_out);

        method enqueue_data(user_wr_data_rise_2, user_bw_n_rise_2, user_wr_data_fall_2, user_bw_n_fall_2)
            ready  (wrdata_fifo_not_full_2)
            enable (user_wrdata_wr_en_2)
            clocked_by (clk_out)
            reset_by (rst_out);

        method user_rd_data_rise_2 dequeue_data_rise()
            ready (rd_data_valid_2)
            clocked_by (clk_out)
            reset_by (rst_out);

        method user_rd_data_fall_2 dequeue_data_fall()
            ready (rd_data_valid_2)
            clocked_by (clk_out)
            reset_by (rst_out);

    endinterface
*/
 
    //
    // Scheduling
    //

    // Methods are assumed to Conflict unless we tell Bluespec otherwise.

    // First, let's set the top-level wires to not conflict against each other or interface methods

    schedule (wires_w_ram_pwr_on, wires_w_ram_leds,
              wires_w_ddrii_sa, wires_w_ddrii_ld_n, wires_w_ddrii_rw_n, wires_w_ddrii_dll_off_n, wires_w_ddrii_bw_n,
              wires_w_masterbank_sel_pin,// wires_w_masterbank_sel_pin_out,
              wires_w_cal_done, wires_w_ddrii_cq, wires_w_ddrii_cq_n, wires_w_ddrii_k,
              wires_w_ddrii_k_n, wires_w_ddrii_c, wires_w_ddrii_c_n /*,
              wires_w_ddrii_sa_2, wires_w_ddrii_ld_n_2, wires_w_ddrii_rw_n_2, wires_w_ddrii_dll_off_n_2, wires_w_ddrii_bw_n_2,
              wires_w_masterbank_sel_pin_2, wires_w_cal_done_2, wires_w_ddrii_cq_2, wires_w_ddrii_cq_n_2, wires_w_ddrii_k_2,
              wires_w_ddrii_k_n_2, wires_w_ddrii_c_2, wires_w_ddrii_c_n_2)*/)
        CF
             (wires_w_ram_pwr_on, wires_w_ram_leds,
              wires_w_ddrii_sa, wires_w_ddrii_ld_n, wires_w_ddrii_rw_n, wires_w_ddrii_dll_off_n, wires_w_ddrii_bw_n,
              wires_w_masterbank_sel_pin,// wires_w_masterbank_sel_pin_out,
              wires_w_cal_done, wires_w_ddrii_cq, wires_w_ddrii_cq_n, wires_w_ddrii_k,
              wires_w_ddrii_k_n, wires_w_ddrii_c, wires_w_ddrii_c_n,/*
              wires_w_ddrii_sa_2, wires_w_ddrii_ld_n_2, wires_w_ddrii_rw_n_2, wires_w_ddrii_dll_off_n_2, wires_w_ddrii_bw_n_2,
              wires_w_masterbank_sel_pin_2, wires_w_cal_done_2, wires_w_ddrii_cq_2, wires_w_ddrii_cq_n_2, wires_w_ddrii_k_2,
              wires_w_ddrii_k_n_2, wires_w_ddrii_c_2, wires_w_ddrii_c_n_2,*/
              ram1_enqueue_address, ram1_enqueue_data, ram1_dequeue_data_rise, ram1_dequeue_data_fall,
                                      ram1_enqueue_address_RDY, ram1_enqueue_data_RDY, ram1_dequeue_data_RDY);
//              ram2_enqueue_address, ram2_enqueue_data, ram2_dequeue_data_rise, ram2_dequeue_data_fall);

    schedule ram1_enqueue_address C (ram1_enqueue_address);
    schedule ram1_enqueue_address CF (ram1_enqueue_data, ram1_dequeue_data_rise, ram1_dequeue_data_fall,
                                      ram1_enqueue_address_RDY, ram1_enqueue_data_RDY, ram1_dequeue_data_RDY);
//                                      ram2_enqueue_address,ram2_enqueue_data, ram2_dequeue_data_rise, ram2_dequeue_data_fall);
    schedule ram1_enqueue_data C (ram1_enqueue_data);
    schedule ram1_enqueue_data CF (ram1_dequeue_data_rise, ram1_dequeue_data_fall,
                                      ram1_enqueue_address_RDY, ram1_enqueue_data_RDY, ram1_dequeue_data_RDY);
//                                   ram2_enqueue_address, ram2_enqueue_data, ram2_dequeue_data_rise, ram2_dequeue_data_fall);
    schedule ram1_dequeue_data_rise CF (ram1_dequeue_data_rise, ram1_dequeue_data_fall,
                                      ram1_enqueue_address_RDY, ram1_enqueue_data_RDY, ram1_dequeue_data_RDY);
//                                        ram2_enqueue_address, ram2_enqueue_data, ram2_dequeue_data_rise, ram2_dequeue_data_fall);
    schedule ram1_dequeue_data_fall CF (ram1_dequeue_data_fall,
                                      ram1_enqueue_address_RDY, ram1_enqueue_data_RDY, ram1_dequeue_data_RDY);
//                                        ram2_enqueue_address, ram2_enqueue_data, ram2_dequeue_data_rise, ram2_dequeue_data_fall);
    schedule ram1_enqueue_address_RDY CF (ram1_enqueue_address_RDY, ram1_enqueue_data_RDY, ram1_dequeue_data_RDY);
    schedule ram1_enqueue_data_RDY CF (ram1_enqueue_data_RDY, ram1_dequeue_data_RDY);
    schedule ram1_dequeue_data_RDY CF ram1_dequeue_data_RDY;
/*
    schedule ram2_enqueue_address C (ram2_enqueue_address);
    schedule ram2_enqueue_address CF (ram2_enqueue_data, ram2_dequeue_data_rise, ram2_dequeue_data_fall);
    schedule ram2_enqueue_data C (ram2_enqueue_data);
    schedule ram2_enqueue_data CF (ram2_dequeue_data_rise, ram2_dequeue_data_fall);
    schedule ram2_dequeue_data_rise CF (ram2_dequeue_data_rise, ram2_dequeue_data_fall);
    schedule ram2_dequeue_data_fall CF (ram2_dequeue_data_fall);
*/
                             
endmodule
