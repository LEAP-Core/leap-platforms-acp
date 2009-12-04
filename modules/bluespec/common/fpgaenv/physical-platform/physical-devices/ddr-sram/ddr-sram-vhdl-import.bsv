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

// Typedefs.

// The SRAM controller uses both clock edges to pass data, which appears to
// be 2 words per cycle.
typedef TMul#(2, `SRAM_DATA_WIDTH) FPGA_SRAM_DUALEDGE_DATA_SZ;
typedef Bit#(FPGA_SRAM_DUALEDGE_DATA_SZ) FPGA_SRAM_DUALEDGE_DATA;

// The SRAM controller reads and writes multiple dual-edge data values for
// a single request.  The number of dual-edge data values per request is:
typedef `SRAM_BURST_LENGTH FPGA_SRAM_BURST_LENGTH;

// Each byte in a write may be disabled for writes using a bit mask.
// !!! NOTE: to conform to the controller, a mask bit is 0 to request a write !!!
typedef `SRAM_BW_WIDTH FPGA_SRAM_WORD_MASK_SZ;
typedef Bit#(FPGA_SRAM_WORD_MASK_SZ) FPGA_SRAM_DUALEDGE_DATA_MASK;

// Capacity of the memory (addressing FPGA_SRAM_WORDs):
typedef `SRAM_ADDR_WIDTH FPGA_SRAM_ADDRESS_SZ;
typedef Bit#(FPGA_SRAM_ADDRESS_SZ) FPGA_SRAM_ADDRESS;


// DDR_SRAM_WIRES

// Wires to be sent to the top level

interface DDR_SRAM_WIRES;

    (* prefix = "" *) interface Inout#(Bit#(`SRAM_DATA_WIDTH)) w_ddrii_dq;

    (* result = "ddrii_sa" *) method Bit#(`SRAM_ADDR_WIDTH) w_ddrii_sa();
    (* result = "ddrii_ld_n" *) method Bit#(1) w_ddrii_ld_n();
    (* result = "ddrii_rw_n" *) method Bit#(1) w_ddrii_rw_n();
    (* result = "ddrii_dll_off_n" *) method Bit#(1) w_ddrii_dll_off_n();
    (* result = "ddrii_bw_n" *) method Bit#(`SRAM_BW_WIDTH) w_ddrii_bw_n();
    (* prefix = "" *) method Action w_masterbank_sel_pin((* port = "masterbank_sel_pin" *) Bit#(1) data);
    
    (* result = "cal_done" *) method Bit#(1) w_cal_done();
    (* prefix = "" *) method Action w_idelay_ctrl_ready((* port = "idelay_ctrl_ready" *) Bit#(1) data);
	
    (* prefix = "" *) method Action w_ddrii_cq((* port = "ddrii_cq" *) Bit#(`SRAM_CQ_WIDTH) data);
    (* prefix = "" *) method Action w_ddrii_cq_n((* port = "ddrii_cq_n" *) Bit#(`SRAM_CQ_WIDTH) data);
    (* result = "ddrii_k" *) method Bit#(`SRAM_CLK_WIDTH) w_ddrii_k();
    (* result = "ddrii_k_n" *) method Bit#(`SRAM_CLK_WIDTH) w_ddrii_k_n();
    (* result = "ddrii_c" *) method Bit#(`SRAM_CLK_WIDTH) w_ddrii_c();
    (* result = "ddrii_c_n" *) method Bit#(`SRAM_CLK_WIDTH) w_ddrii_c_n();

endinterface


// PRIMITIVE_DDR_SRAM_DEVICE

// The primitive vhdl import which we will wrap in a shim to deal with DDR.

interface PRIMITIVE_DDR_SRAM_DEVICE;
    
    //
    // Wires to be sent to the top level
    //

    (* prefix = "" *) interface DDR_SRAM_WIRES wires;
        
    //
    // Methods for the Driver
    //

    // Address, cmd=0 if performing a write, cmd=1 for read.
    method Action enqueue_address(Bit#(`SRAM_ADDR_WIDTH) addr, Bit#(1) cmd);

    // Data rise and fall share a single enable, so it seems we have to make them a single method.
    // If this becomes a problem we can try to separate it into two.
    // Note that the mask is negatively-enabled, so 0=perform write.
    method Action enqueue_data(Bit#(`SRAM_DATA_WIDTH) data_rise, Bit#(`SRAM_BW_WIDTH) bw_mask_rise_n, Bit#(`SRAM_DATA_WIDTH) data_fall, Bit#(`SRAM_BW_WIDTH) bw_mask_fall_n);

    // These share a Ready, but Bluespec has no problem with this. 
    // Alternatively, these could also be combined into a single method which returns a struct.
    method Bit#(`SRAM_DATA_WIDTH) dequeue_data_rise();
    method Bit#(`SRAM_DATA_WIDTH) dequeue_data_fall();

endinterface


// mkPrimitiveDDRSRAMDevice

// Straightforward import of the VHDL into Bluespec.

import "BVI" ddrii_sram = module mkPrimitiveDDRSRAMDevice
    #(Clock ram_clk0,
      Clock ram_clk200,
      Clock ram_clk270,
      Bit#(1) ram_clkLocked)
    // interface:
                 (PRIMITIVE_DDR_SRAM_DEVICE);

    default_clock no_clock; // Note: These perhaps should be ram_clk0 depending on how it affects synchronization.
    default_reset  (sys_rst_n) clocked_by (no_clock);

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
   
    //
    // Wires to be sent to the top level
    //

    interface DDR_SRAM_WIRES wires;
    
        ifc_inout w_ddrii_dq(ddrii_dq);

        method ddrii_sa         w_ddrii_sa();
        method ddrii_ld_n       w_ddrii_ld_n();
        method ddrii_rw_n       w_ddrii_rw_n();
        method ddrii_dll_off_n  w_ddrii_dll_off_n();
        method ddrii_bw_n       w_ddrii_bw_n();
        method cal_done         w_cal_done();

        method w_masterbank_sel_pin(masterbank_sel_pin) enable ((* inhigh *) EN0);
        method w_idelay_ctrl_ready(idelay_ctrl_ready) enable ((* inhigh *) EN1);
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
    
    // XXX is ram_clk0 correct here?

    method enqueue_address(user_addr, user_cmd)
        ready  (addr_fifo_not_full)
        enable (user_addr_wr_en)
        clocked_by (ram_clk0);

    method enqueue_data(user_wr_data_rise, user_bw_n_rise, user_wr_data_fall, user_bw_n_fall)
        ready  (wrdata_fifo_not_full)
        enable (user_wrdata_wr_en)
        clocked_by (ram_clk0);

    method user_rd_data_rise dequeue_data_rise()
        ready (rd_data_valid)
        clocked_by (ram_clk0);

    method user_rd_data_fall dequeue_data_fall()
        ready (rd_data_valid)
        clocked_by (ram_clk0);
                          
    //
    // Scheduling
    //
    
    // Methods are assumed to Conflict unless we tell Bluespec otherwise.

    // First, let's set the top-level wires to not conflict against each other or interface methods

    schedule (wires_w_ddrii_sa, wires_w_ddrii_ld_n, wires_w_ddrii_rw_n, wires_w_ddrii_dll_off_n, wires_w_ddrii_bw_n,
              wires_w_masterbank_sel_pin, wires_w_cal_done, wires_w_ddrii_cq, wires_w_ddrii_cq_n, wires_w_ddrii_k,
              wires_w_ddrii_k_n, wires_w_ddrii_c, wires_w_ddrii_c_n, wires_w_idelay_ctrl_ready)
        
        CF
        
             (wires_w_ddrii_sa, wires_w_ddrii_ld_n, wires_w_ddrii_rw_n, wires_w_ddrii_dll_off_n, wires_w_ddrii_bw_n,
              wires_w_masterbank_sel_pin, wires_w_cal_done, wires_w_ddrii_cq, wires_w_ddrii_cq_n, wires_w_ddrii_k,
              wires_w_ddrii_k_n, wires_w_ddrii_c, wires_w_ddrii_c_n, wires_w_idelay_ctrl_ready,
              enqueue_address, enqueue_data, dequeue_data_rise, dequeue_data_fall);

    schedule enqueue_address C (enqueue_address);
    schedule enqueue_address CF (enqueue_data, dequeue_data_rise, dequeue_data_fall);

    schedule enqueue_data C (enqueue_data);
    schedule enqueue_data CF (dequeue_data_rise, dequeue_data_fall);
    schedule dequeue_data_rise CF (dequeue_data_rise, dequeue_data_fall);
    schedule dequeue_data_fall CF (dequeue_data_fall);
        
endmodule
