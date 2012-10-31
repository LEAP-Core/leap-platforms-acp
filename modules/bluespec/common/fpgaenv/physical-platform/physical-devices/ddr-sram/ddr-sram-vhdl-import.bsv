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
// This module implements a single bank SRAM controller.  To control
// multiple banks it must be instantiated more than once.
//

`include "awb/provides/nallatech_edge_device_params.bsh"

// ddr-sram-vhdl-import

// Import the VHDL device into BSV

// Convenience constants. These can overload the corresponding parameters in the VHDL,
// though it is unknown what effect changing these would have.
`define SRAM_ADDR_WIDTH `DRAM_ADDR_BITS
`define SRAM_BURST_LENGTH 2
`define SRAM_BW_WIDTH 4
`define SRAM_CLK_FREQ `NALLATECH_RAM_CLOCK_FREQ
`define SRAM_CLK_WIDTH 1
`define SRAM_CQ_WIDTH 1
`define SRAM_DATA_WIDTH 36

//
// Data sizes are fixed by the VHDL DRAM controller and the hardware and are
// not flexible.
//

// Number of memory banks.  The controller instantiates a controller for a
// single bank.  It is the responsibility of higher level code to allocate
// one controller for each available bank.
typedef `DRAM_NUM_BANKS FPGA_DDR_BANKS;

// The smallest addressable word:
typedef 32 FPGA_DDR_WORD_SZ;

// The DRAM controller reads and writes multiple dual-edge data values for
// a single request.  The number of dual-edge data values per request is:
typedef `DRAM_MIN_BURST FPGA_DDR_BURST_LENGTH;

// Capacity of the memory (addressing FPGA_DDR_WORDs):
typedef `SRAM_ADDR_WIDTH FPGA_DDR_ADDRESS_SZ;

typedef enum {
    WRITE = 0,
    READ  = 1
}
DDR2_COMMAND
    deriving(Bits, Eq);


//
// DDR_WIRES
//
// Wires to be sent to the top level
//
interface DDR_WIRES;
    // global
    (* result = "ram_pwr_on" *) method Bit#(1) w_ram_pwr_on();
    (* result = "ram_leds"   *) method Bit#(2) w_ram_leds();

    // RAM 1 or 5
    (* prefix = "w_ddrii_dq" *) interface Inout#(Bit#(`SRAM_DATA_WIDTH)) w_ddrii_dq;

    (* result = "ddrii_sa" *) method Bit#(`SRAM_ADDR_WIDTH) w_ddrii_sa();
    (* result = "ddrii_ld_n" *) method Bit#(1) w_ddrii_ld_n();
    (* result = "ddrii_rw_n" *) method Bit#(1) w_ddrii_rw_n();
    (* result = "ddrii_dll_off_n" *) method Bit#(1) w_ddrii_dll_off_n();
    (* result = "ddrii_bw_n" *) method Bit#(`SRAM_BW_WIDTH) w_ddrii_bw_n();
    (* prefix = "" *) method Action w_masterbank_sel_pin((* port = "masterbank_sel_pin" *) Bit#(1) data);

    (* prefix = "" *) method Action w_ddrii_cq((* port = "ddrii_cq" *) Bit#(`SRAM_CQ_WIDTH) data);
    (* prefix = "" *) method Action w_ddrii_cq_n((* port = "ddrii_cq_n" *) Bit#(`SRAM_CQ_WIDTH) data);
    (* result = "ddrii_k" *) method Bit#(`SRAM_CLK_WIDTH) w_ddrii_k();
    (* result = "ddrii_k_n" *) method Bit#(`SRAM_CLK_WIDTH) w_ddrii_k_n();
    (* result = "ddrii_c" *) method Bit#(`SRAM_CLK_WIDTH) w_ddrii_c();
    (* result = "ddrii_c_n" *) method Bit#(`SRAM_CLK_WIDTH) w_ddrii_c_n();
endinterface


interface DDR2_PRIM_DRIVER;
    // Address, cmd=0 if performing a write, cmd=1 for read.
    method Action enqueue_address(FPGA_DDR_ADDRESS addr, DDR2_COMMAND cmd);
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

    // Set after the controller completes initialization.
    method Bool ddr_device_RDY();
endinterface


//
// PRIMITIVE_DDR_SRAM_DEVICE
//
// The primitive vhdl import which we will wrap in a shim to deal with DDR.
//
interface PRIMITIVE_DDR_SRAM_DEVICE;
    //
    // Wires to be sent to the top level
    //
    (* prefix = "" *) interface DDR_WIRES wires;

    // exported clock and reset
    interface Clock clk_out;
    interface Reset rst_out;

    // One bank of memory
    interface DDR2_PRIM_DRIVER ram;
endinterface


//
// mkPrimitiveDDRSRAMDevice
//
// Straightforward import of the VHDL RAM bank controller into Bluespec.
//
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

    interface DDR_WIRES wires;
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

        method w_masterbank_sel_pin(masterbank_sel_pin) enable ((* inhigh *) EN0);
        // method masterbank_sel_pin_out w_masterbank_sel_pin_out();

        // method w_idelay_ctrl_ready(idelay_ctrl_ready) enable ((* inhigh *) EN1);
        method w_ddrii_cq(ddrii_cq) enable ((* inhigh *) EN2);
        method w_ddrii_cq_n(ddrii_cq_n) enable ((* inhigh *) EN3);

        method ddrii_k          w_ddrii_k();
        method ddrii_k_n        w_ddrii_k_n();
        method ddrii_c          w_ddrii_c();
        method ddrii_c_n        w_ddrii_c_n();
     endinterface

    //
    // Bluespec-VHDL interface
    //
    interface DDR2_PRIM_DRIVER ram;
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

        method cal_done ddr_device_RDY()
            clocked_by (clk_out)
            reset_by (rst_out);
    endinterface

 
    //
    // Scheduling
    //

    // Methods are assumed to Conflict unless we tell Bluespec otherwise.

    // First, let's set the top-level wires to not conflict against each
    // other or interface methods
    schedule (wires_w_ram_pwr_on, wires_w_ram_leds,
              wires_w_ddrii_sa, wires_w_ddrii_ld_n, wires_w_ddrii_rw_n, wires_w_ddrii_dll_off_n, wires_w_ddrii_bw_n,
              wires_w_masterbank_sel_pin,
              wires_w_ddrii_cq, wires_w_ddrii_cq_n, wires_w_ddrii_k,
              wires_w_ddrii_k_n, wires_w_ddrii_c, wires_w_ddrii_c_n,
              ram_ddr_device_RDY)
        CF
             (wires_w_ram_pwr_on, wires_w_ram_leds,
              wires_w_ddrii_sa, wires_w_ddrii_ld_n, wires_w_ddrii_rw_n, wires_w_ddrii_dll_off_n, wires_w_ddrii_bw_n,
              wires_w_masterbank_sel_pin,
              wires_w_ddrii_cq, wires_w_ddrii_cq_n, wires_w_ddrii_k,
              wires_w_ddrii_k_n, wires_w_ddrii_c, wires_w_ddrii_c_n,
              ram_enqueue_address, ram_enqueue_data, ram_dequeue_data_rise, ram_dequeue_data_fall,
              ram_enqueue_address_RDY, ram_enqueue_data_RDY, ram_dequeue_data_RDY,
              ram_ddr_device_RDY);

    schedule ram_enqueue_address C (ram_enqueue_address);
    schedule ram_enqueue_address CF (ram_enqueue_data, ram_dequeue_data_rise, ram_dequeue_data_fall,
                                      ram_enqueue_address_RDY, ram_enqueue_data_RDY, ram_dequeue_data_RDY);
    schedule ram_enqueue_data C (ram_enqueue_data);
    schedule ram_enqueue_data CF (ram_dequeue_data_rise, ram_dequeue_data_fall,
                                      ram_enqueue_address_RDY, ram_enqueue_data_RDY, ram_dequeue_data_RDY);
    schedule ram_dequeue_data_rise CF (ram_dequeue_data_rise, ram_dequeue_data_fall,
                                      ram_enqueue_address_RDY, ram_enqueue_data_RDY, ram_dequeue_data_RDY);
    schedule ram_dequeue_data_fall CF (ram_dequeue_data_fall,
                                      ram_enqueue_address_RDY, ram_enqueue_data_RDY, ram_dequeue_data_RDY);
    schedule ram_enqueue_address_RDY CF (ram_enqueue_address_RDY, ram_enqueue_data_RDY, ram_dequeue_data_RDY);
    schedule ram_enqueue_data_RDY CF (ram_enqueue_data_RDY, ram_dequeue_data_RDY);
    schedule ram_dequeue_data_RDY CF ram_dequeue_data_RDY;
endmodule
