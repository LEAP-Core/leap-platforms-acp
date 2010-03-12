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
--  /   /         Filename           : ddrii_top_user_interface.vhd
-- /___/   /\     Timestamp          : 08 Apr 2008
-- \   \  /  \    Date Last Modified : $Date: 2009/05/11 21:13:31 $
--  \___\/\___\
--
--Device: Virtex-5
--Design: DDRII
--
--Purpose:
--    This module
--       1. serves as the interface between the user backend and the phy layer,
--          to store user address, command bit and write data.
--       2. Instantiates the addr_cmd interface and write data interface.
--
--Revision History:
--
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;

entity ddrii_top_user_interface is
  generic(
    -- Following parameters are for 72-bit design. Actual values may be
    -- different. Actual parameters values are passed from design top module
    -- ddr2_sram module. Please refer to the ddr2_sram module for actual
    -- values.
    ADDR_WIDTH   : integer := 19;
    BURST_LENGTH : integer := 4;
    BW_WIDTH     : integer := 8;
    DATA_WIDTH   : integer := 72
    );
  port(
    clk_0              : in std_logic;
    reset_clk_0        : in std_logic;
    user_addr_wr_en    : in std_logic;
    user_wrdata_wr_en  : in std_logic;
    addr_fifo_rd_en    : in std_logic;
    wrdata_fifo_rd_en  : in std_logic;
    cal_done           : in std_logic;
    user_addr_cmd      : in std_logic_vector(ADDR_WIDTH downto 0);
    user_bw_n_rise     : in std_logic_vector(BW_WIDTH-1 downto 0);
    user_bw_n_fall     : in std_logic_vector(BW_WIDTH-1 downto 0);
    user_wr_data_rise  : in std_logic_vector(DATA_WIDTH-1 downto 0);
    user_wr_data_fall  : in std_logic_vector(DATA_WIDTH-1 downto 0);
    ptrn_data_rise_r1  : in std_logic_vector(DATA_WIDTH-1 downto 0);
    ptrn_data_fall_r1  : in std_logic_vector(DATA_WIDTH-1 downto 0);
    ptrn_data_wr_en_r1 : in std_logic;

    addr_fifo_empty    : out std_logic;
    addr_fifo_full     : out std_logic;
    addr_fifo_wr_err   : out std_logic;
    addr_fifo_rd_err   : out std_logic;
    wrdata_fifo_full   : out std_logic;
    wrdata_fifo_empty  : out std_logic;
    wrdata_fifo_wr_err : out std_logic;
    wrdata_fifo_rd_err : out std_logic;
    command_bit        : out std_logic;
    wr_rd_address      : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    bw_n_rise          : out std_logic_vector(BW_WIDTH-1 downto 0);
    bw_n_fall          : out std_logic_vector(BW_WIDTH-1 downto 0);
    wr_data_rise       : out std_logic_vector(DATA_WIDTH-1 downto 0);
    wr_data_fall       : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity ddrii_top_user_interface;

architecture arch_ddrii_top_user_interface of ddrii_top_user_interface is

  component ddrii_top_addr_cmd_interface
    generic(
      ADDR_WIDTH   : integer := ADDR_WIDTH
      );
    port(
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
  end component ddrii_top_addr_cmd_interface;

  component ddrii_top_wr_data_interface
    generic(
      BURST_LENGTH  : integer := BURST_LENGTH;
      BW_WIDTH      : integer := BW_WIDTH;
      DATA_WIDTH    : integer := DATA_WIDTH
      );
    port(
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
  end component ddrii_top_wr_data_interface;

  signal user_wrdata_wr_en_i : std_logic;
  signal user_addr_wr_en_i   : std_logic;
  signal user_wr_data_rise_i : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal user_wr_data_fall_i : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal user_bw_n_rise_i    : std_logic_vector(BW_WIDTH-1 downto 0);
  signal user_bw_n_fall_i    : std_logic_vector(BW_WIDTH-1 downto 0);

begin

  ------------------------------------------------------------------------------
  -- User write data is loaded in to Write Data FIFO only when the Calibration
  -- is complete. Initially, controller writes pattern data in to Write data
  -- FIFO for calibration purpose. So, user is not allowed to write in to write
  -- data FIFO until calibration is complete. Similar is the case with address
  -- FIFO.
  ------------------------------------------------------------------------------
  user_wr_data_rise_i <= user_wr_data_rise when (cal_done = '1') else
                         ptrn_data_rise_r1;
  user_wr_data_fall_i <= user_wr_data_fall when (cal_done = '1') else
                         ptrn_data_fall_r1;
  user_bw_n_rise_i    <= user_bw_n_rise when (cal_done = '1') else
                         (others => '0');
  user_bw_n_fall_i    <= user_bw_n_fall when (cal_done = '1') else
                         (others => '0');
  user_wrdata_wr_en_i <= user_wrdata_wr_en when (cal_done = '1') else
                         ptrn_data_wr_en_r1;

  user_addr_wr_en_i   <= user_addr_wr_en when (cal_done = '1') else
                         '0';

  U_DDRII_TOP_ADDR_CMD_INTERFACE : ddrii_top_addr_cmd_interface
    generic map(
      ADDR_WIDTH         => ADDR_WIDTH
      )
    port map(
      clk_0              => clk_0,
      reset_clk_0        => reset_clk_0,
      user_addr_wr_en    => user_addr_wr_en_i,
      addr_fifo_rd_en    => addr_fifo_rd_en,
      user_addr_cmd      => user_addr_cmd,

      addr_fifo_empty    => addr_fifo_empty,
      addr_fifo_full     => addr_fifo_full,
      addr_fifo_wr_err   => addr_fifo_wr_err,
      addr_fifo_rd_err   => addr_fifo_rd_err,
      command_bit        => command_bit,
      wr_rd_address      => wr_rd_address
      );

  U_DDRII_TOP_WR_DATA_INTERFACE : ddrii_top_wr_data_interface
    generic map(
      BURST_LENGTH  => BURST_LENGTH,
      BW_WIDTH      => BW_WIDTH,
      DATA_WIDTH    => DATA_WIDTH
      )
    port map(
      clk_0              => clk_0,
      reset_clk_0        => reset_clk_0,
      wrdata_fifo_rd_en  => wrdata_fifo_rd_en,
      user_wrdata_wr_en  => user_wrdata_wr_en_i,
      user_bw_n_rise     => user_bw_n_rise_i,
      user_bw_n_fall     => user_bw_n_fall_i,
      user_wr_data_rise  => user_wr_data_rise_i,
      user_wr_data_fall  => user_wr_data_fall_i,

      wrdata_fifo_full   => wrdata_fifo_full,
      wrdata_fifo_empty  => wrdata_fifo_empty,
      wrdata_fifo_wr_err => wrdata_fifo_wr_err,
      wrdata_fifo_rd_err => wrdata_fifo_rd_err,
      bw_n_rise          => bw_n_rise,
      bw_n_fall          => bw_n_fall,
      wr_data_rise       => wr_data_rise,
      wr_data_fall       => wr_data_fall
      );

end architecture arch_ddrii_top_user_interface;