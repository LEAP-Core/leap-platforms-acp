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
--  /   /         Filename           : ddrii_top_wr_data_interface.vhd
-- /___/   /\     Timestamp          : 08 Apr 2008
-- \   \  /  \    Date Last Modified : $Date: 2009/05/11 21:13:31 $
--  \___\/\___\
--
--Device: Virtex-5
--Design: DDRII
--
--Purpose:
--    This module
--       1. Responsible for storing the Write data written by the user design.
--          Instantiates the FIFOs for storing the write data.
--
--Revision History:
--
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity ddrii_top_wr_data_interface is
  generic (
    -- Following parameters are for 72-bit design. Actual values may be
    -- different. Actual parameters values are passed from design top module
    -- ddr2_sram module. Please refer to the ddr2_sram module for actual
    -- values.
    BURST_LENGTH  : integer := 4;
    BW_WIDTH      : integer := 8;
    DATA_WIDTH    : integer := 72
    );
  port (
    clk_0              : in  std_logic;
    reset_clk_0        : in  std_logic;
    wrdata_fifo_rd_en  : in  std_logic;
    user_wrdata_wr_en  : in  std_logic;
    user_bw_n_rise     : in  std_logic_vector(BW_WIDTH-1 downto 0);
    user_bw_n_fall     : in  std_logic_vector(BW_WIDTH-1 downto 0);
    user_wr_data_rise  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    user_wr_data_fall  : in  std_logic_vector(DATA_WIDTH-1 downto 0);

    wrdata_fifo_full   : out std_logic;
    wrdata_fifo_empty  : out std_logic;
    wrdata_fifo_wr_err : out std_logic;
    wrdata_fifo_rd_err : out std_logic;
    bw_n_rise          : out std_logic_vector(BW_WIDTH-1 downto 0);
    bw_n_fall          : out std_logic_vector(BW_WIDTH-1 downto 0);
    wr_data_rise       : out std_logic_vector(DATA_WIDTH-1 downto 0);
    wr_data_fall       : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity ddrii_top_wr_data_interface;

architecture arch_ddrii_top_wr_data_interface of ddrii_top_wr_data_interface is

  constant ZEROS : std_logic_vector(71 downto DATA_WIDTH) := (others => '0');

  signal rise_data_fifo_empty  : std_logic;
  signal fall_data_fifo_empty  : std_logic;
  signal rise_data_fifo_full   : std_logic;
  signal fall_data_fifo_full   : std_logic;
  signal rise_data_fifo_wr_err : std_logic;
  signal fall_data_fifo_wr_err : std_logic;
  signal rise_data_fifo_rd_err : std_logic;
  signal fall_data_fifo_rd_err : std_logic;
  signal bw_n_empty            : std_logic;
  signal bw_n_full             : std_logic;
  signal bw_n_wr_err           : std_logic;
  signal bw_n_rd_err           : std_logic;
  signal user_bw_n             : std_logic_vector(15 downto 0);
  signal bw_n                  : std_logic_vector(15 downto 0);
  signal user_wr_data_rise_i   : std_logic_vector(71 downto 0);
  signal user_wr_data_fall_i   : std_logic_vector(71 downto 0);
  signal wr_data_rise_i        : std_logic_vector(71 downto 0);
  signal wr_data_fall_i        : std_logic_vector(71 downto 0);

begin

  user_bw_n((2*BW_WIDTH)-1 downto 0) <= (user_bw_n_fall & user_bw_n_rise);
  bw_n_rise  <= bw_n(2*BW_WIDTH -1 downto BW_WIDTH);
  bw_n_fall  <= bw_n(BW_WIDTH-1 downto 0);

  wrdata_fifo_empty  <= fall_data_fifo_empty or rise_data_fifo_empty or bw_n_empty;
  wrdata_fifo_full   <= fall_data_fifo_full or rise_data_fifo_full or bw_n_full;
  wrdata_fifo_wr_err <= fall_data_fifo_wr_err or rise_data_fifo_wr_err or bw_n_wr_err;
  wrdata_fifo_rd_err <= fall_data_fifo_rd_err or rise_data_fifo_rd_err or bw_n_rd_err;

  DW_72_INST : if(DATA_WIDTH = 72) generate
    user_wr_data_rise_i <= user_wr_data_rise;
    user_wr_data_fall_i <= user_wr_data_fall;
  end generate DW_72_INST;

  DW_NOT_72_INST : if(DATA_WIDTH /= 72) generate
    user_wr_data_rise_i <= (ZEROS(71 downto DATA_WIDTH) & user_wr_data_rise);
    user_wr_data_fall_i <= (ZEROS(71 downto DATA_WIDTH) & user_wr_data_fall);
  end generate DW_NOT_72_INST;

  wr_data_rise <= wr_data_rise_i(DATA_WIDTH-1 downto 0);
  wr_data_fall <= wr_data_fall_i(DATA_WIDTH-1 downto 0);


  ----------------------------------------------------------------------------
  -- Write Data FIFO - Low Word
  ----------------------------------------------------------------------------
  U_FIFO_FALL_DATA : FIFO36_72
    generic map(
      almost_full_offset      => X"0080",
      almost_empty_offset     => X"0080",
      first_word_fall_through => FALSE,
      do_reg                  => 1,
      en_syn                  => FALSE
      )
    port map(
      di          => user_wr_data_fall_i(63 downto 0),
      dip         => user_wr_data_fall_i(71 downto 64),
      rdclk       => clk_0,
      rden        => wrdata_fifo_rd_en,
      rst         => reset_clk_0,
      wrclk       => clk_0,
      wren        => user_wrdata_wr_en,
      dbiterr     => open,
      eccparity   => open,
      sbiterr     => open,
      almostempty => open,
      almostfull  => fall_data_fifo_full,
      do          => wr_data_fall_i(63 downto 0),
      dop         => wr_data_fall_i(71 downto 64),
      empty       => fall_data_fifo_empty,
      full        => open,
      rdcount     => open,
      rderr       => fall_data_fifo_rd_err,
      wrcount     => open,
      wrerr       => fall_data_fifo_wr_err
      );

  ----------------------------------------------------------------------------
  -- Write Data FIFO - High Word
  ----------------------------------------------------------------------------
  U_FIFO_RISE_DATA : FIFO36_72
    generic map(
      almost_full_offset      => X"0080",
      almost_empty_offset     => X"0080",
      first_word_fall_through => FALSE,
      do_reg                  => 1,
      en_syn                  => FALSE
      )
    port map(
      di          => user_wr_data_rise_i(63 downto 0),
      dip         => user_wr_data_rise_i(71 downto 64),
      rdclk       => clk_0,
      rden        => wrdata_fifo_rd_en,
      rst         => reset_clk_0,
      wrclk       => clk_0,
      wren        => user_wrdata_wr_en,
      dbiterr     => open,
      eccparity   => open,
      sbiterr     => open,
      almostempty => open,
      almostfull  => rise_data_fifo_full,
      do          => wr_data_rise_i(63 downto 0),
      dop         => wr_data_rise_i(71 downto 64),
      empty       => rise_data_fifo_empty,
      full        => open,
      rdcount     => open,
      rderr       => rise_data_fifo_rd_err,
      wrcount     => open,
      wrerr       => rise_data_fifo_wr_err
      );

  ------------------------------------------------------------------------------
  -- Byte write FIFO instantiation
  ------------------------------------------------------------------------------
  U_FIFO_BW : FIFO18
    generic map(
      almost_full_offset      => X"0080",
      almost_empty_offset     => X"0080",
      data_width              => 18,
      first_word_fall_through => FALSE,
      do_reg                  => 1,
      en_syn                  => FALSE
      )
    port map(
      di          => user_bw_n,
      dip         => "00",
      rdclk       => clk_0,
      rden        => wrdata_fifo_rd_en,
      rst         => reset_clk_0,
      wrclk       => clk_0,
      wren        => user_wrdata_wr_en,
      almostempty => open,
      almostfull  => bw_n_full,
      do          => bw_n(15 downto 0),
      dop         => open,
      empty       => bw_n_empty,
      full        => open,
      rdcount     => open,
      rderr       => bw_n_rd_err,
      wrcount     => open,
      wrerr       => bw_n_wr_err
      );

end architecture arch_ddrii_top_wr_data_interface;
