--*****************************************************************************
-- DISCLAIMER OF LIABILITY
--
-- This file contains proprietary and confidential information of
-- Xilinx, Inc. ("Xilinx"), that is distributed under a license
-- from Xilinx, and may be used, copied and/or disclosed only
-- pursuant to the terms of a valid license agreement with Xilinx.
--
-- XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION
-- ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
-- EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT
-- LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,
-- MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx
-- does not warrant that functions included in the Materials will
-- meet the requirements of Licensee, or that the operation of the
-- Materials will be uninterrupted or error-free, or that defects
-- in the Materials will be corrected. Furthermore, Xilinx does
-- not warrant or make any representations regarding use, or the
-- results of the use, of the Materials in terms of correctness,
-- accuracy, reliability or otherwise.
--
-- Xilinx products are not designed or intended to be fail-safe,
-- or for use in any application requiring fail-safe performance,
-- such as life-support or safety devices or systems, Class III
-- medical devices, nuclear facilities, applications related to
-- the deployment of airbags, or any other applications that could
-- lead to death, personal injury or severe property or
-- environmental damage (individually and collectively, "critical
-- applications"). Customer assumes the sole risk and liability
-- of any use of Xilinx products in critical applications,
-- subject only to applicable laws and regulations governing
-- limitations on product liability.
--
-- Copyright 2008 Xilinx, Inc.
-- All rights reserved.
--
-- This disclaimer and copyright notice must be retained as part
-- of this file at all times.
--*****************************************************************************
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor             : Xilinx
-- \   \   \/     Version            : 3.2
--  \   \         Application        : MIG
--  /   /         Filename           : ddrii_top_addr_cmd_interface.vhd
-- /___/   /\     Timestamp          : 08 Apr 2008
-- \   \  /  \    Date Last Modified : $Date: 2009/05/11 21:13:30 $
--  \___\/\___\
--
--Device: Virtex-5
--Design: DDRII
--
--Purpose:
--    This module
--   1. Responsible for storing the Write requests made by the user design.
--      Instantiates the FIFOs for Write address and control storage.
--
--Revision History:
--
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity ddrii_top_addr_cmd_interface is
  generic (
    -- Following parameters are for 72-bit design. Actual values may be
    -- different. Actual parameters values are passed from design top module
    -- ddr2_sram module. Please refer to the ddr2_sram module for actual
    -- values.
    ADDR_WIDTH : integer := 19
    );
  port (
    clk_0            : in  std_logic;
    reset_clk_0      : in  std_logic;
    user_addr_wr_en  : in  std_logic;
    addr_fifo_rd_en  : in  std_logic;
    user_addr_cmd    : in  std_logic_vector(ADDR_WIDTH downto 0);

    addr_fifo_empty  : out std_logic;
    addr_fifo_full   : out std_logic;
    addr_fifo_wr_err : out std_logic;
    addr_fifo_rd_err : out std_logic;
    command_bit      : out std_logic;
    wr_rd_address    : out std_logic_vector(ADDR_WIDTH-1 downto 0)
    );
end entity ddrii_top_addr_cmd_interface;

architecture arch_ddrii_top_addr_cmd_interface of ddrii_top_addr_cmd_interface is

   signal fifo_address_input  : std_logic_vector(31 downto 0);
   signal fifo_address_output : std_logic_vector(31 downto 0);

begin

   fifo_address_input(ADDR_WIDTH downto 0) <= user_addr_cmd;
   fifo_address_input(31 downto ADDR_WIDTH+1) <= (others => '0');

   wr_rd_address <= fifo_address_output(ADDR_WIDTH downto 1);
   command_bit   <= fifo_address_output(0);

   U_FIFO36 : FIFO36
     generic map (
       ALMOST_FULL_OFFSET      => X"0080",
       ALMOST_EMPTY_OFFSET     => X"0080",
       DATA_WIDTh              => 36,
       FIRST_WORD_FALL_THROUGH => TRUE,
       DO_REG                  => 1,
       EN_SYN                  => FALSE
       )
     port map (
       di          => fifo_address_input,
       dip         => "0000",
       rdclk       => clk_0,
       rden        => addr_fifo_rd_en,
       rst         => reset_clk_0,
       wrclk       => clk_0,
       wren        => user_addr_wr_en,
       almostempty => open,
       almostfull  => addr_fifo_full,
       do          => fifo_address_output,
       dop         => open,
       empty       => addr_fifo_empty,
       full        => open,
       rdcount     => open,
       rderr       => addr_fifo_rd_err,
       wrcount     => open,
       wrerr       => addr_fifo_wr_err
       );

end architecture arch_ddrii_top_addr_cmd_interface;