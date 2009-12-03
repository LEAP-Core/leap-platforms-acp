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
-- \   \   \/     Version            : 3.1
--  \   \         Application        : MIG
--  /   /         Filename           : ddrii_top.vhd
-- /___/   /\     Timestamp          : 08 Apr 2008
-- \   \  /  \    Date Last Modified : $Date: 2009/03/23 16:11:01 $
--  \___\/\___\
--
--Device: Virtex-5
--Design: DDRII
--
--Purpose:
--    This module
--       1. Serves as the top level memory interface module that interfaces to
--          the user backend.
--       2. Instantiates the user interface module, the controller statemachine
--          and the phy layer.
--
--Revision History:
--   Rev 1.1 - Parameter IODELAY_GRP added. PK. 11/27/08
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity ddrii_top is
  generic(
    -- Following parameters are for 72-bit design. Actual values may be
    -- different. Actual parameters values are passed from design top module
    -- mig_31 module. Please refer to the mig_31 module for actual
    -- values.
    ADDR_WIDTH            : integer := 19;
    BURST_LENGTH          : integer := 4;
    BW_WIDTH              : integer := 8;
    CLK_FREQ              : integer := 300;
    CLK_WIDTH             : integer := 2;
    CQ_WIDTH              : integer := 2;
    DATA_WIDTH            : integer := 72;
    DEBUG_EN              : integer := 0;
    HIGH_PERFORMANCE_MODE : boolean := TRUE;
    IODELAY_GRP           : string  := "IODELAY_MIG";
    IO_TYPE               : string  := "CIO";
    MEMORY_WIDTH          : integer := 36;
    BUS_TURNAROUND        : integer := 0;
    SIM_ONLY              : integer := 0
    );
  port(
    clk_0             : in    std_logic;
    clk_90            : in    std_logic;
    clk_270           : in    std_logic;
    reset_clk_0       : in    std_logic;
    reset_clk_270     : in    std_logic;
    user_wrdata_wr_en : in    std_logic;
    user_addr_wr_en   : in    std_logic;
    user_bw_n_rise    : in    std_logic_vector(BW_WIDTH-1 downto 0);
    user_bw_n_fall    : in    std_logic_vector(BW_WIDTH-1 downto 0);
    user_addr_cmd     : in    std_logic_vector(ADDR_WIDTH downto 0);
    user_wr_data_rise : in    std_logic_vector(DATA_WIDTH-1 downto 0);
    user_wr_data_fall : in    std_logic_vector(DATA_WIDTH-1 downto 0);
    wrdata_fifo_full  : out   std_logic;
    addr_fifo_full    : out   std_logic;
    rd_data_valid     : out   std_logic;
    user_rd_data_rise : out   std_logic_vector(DATA_WIDTH-1 downto 0);
    user_rd_data_fall : out   std_logic_vector(DATA_WIDTH-1 downto 0);
    idelay_ctrl_ready : in    std_logic;
    ddrii_q           : in    std_logic_vector(DATA_WIDTH-1 downto 0);
    ddrii_dq          : inout std_logic_vector(DATA_WIDTH-1 downto 0);
    ddrii_cq          : in    std_logic_vector(CQ_WIDTH-1 downto 0);
    ddrii_cq_n        : in    std_logic_vector(CQ_WIDTH-1 downto 0);
    cal_done          : out   std_logic;
    ddrii_c           : out   std_logic_vector(CLK_WIDTH-1 downto 0);
    ddrii_c_n         : out   std_logic_vector(CLK_WIDTH-1 downto 0);
    ddrii_dll_off_n   : out   std_logic;
    ddrii_k           : out   std_logic_vector(CLK_WIDTH-1 downto 0);
    ddrii_k_n         : out   std_logic_vector(CLK_WIDTH-1 downto 0);
    ddrii_sa          : out   std_logic_vector(ADDR_WIDTH-1 downto 0);
    ddrii_bw_n        : out   std_logic_vector(BW_WIDTH-1 downto 0);
    ddrii_rw_n        : out   std_logic;
    ddrii_d           : out   std_logic_vector(DATA_WIDTH-1 downto 0);
    ddrii_ld_n        : out   std_logic;
    -- Debug Signals
    dbg_idel_up_all             : in  std_logic;
    dbg_idel_down_all           : in  std_logic;
    dbg_idel_up_q               : in  std_logic;
    dbg_idel_down_q             : in  std_logic;
    dbg_sel_idel_q_cq           : in  std_logic_vector(CQ_WIDTH-1 downto 0);
    dbg_sel_all_idel_q_cq       : in  std_logic;
    dbg_sel_idel_q_cq_n         : in  std_logic_vector(CQ_WIDTH-1 downto 0);
    dbg_sel_all_idel_q_cq_n     : in  std_logic;
    dbg_idel_up_cq              : in  std_logic;
    dbg_idel_down_cq            : in  std_logic;
    dbg_sel_idel_cq             : in  std_logic_vector(CQ_WIDTH-1 downto 0);
    dbg_sel_all_idel_cq         : in  std_logic;
    dbg_sel_idel_cq_n           : in  std_logic_vector(CQ_WIDTH-1 downto 0);
    dbg_sel_all_idel_cq_n       : in  std_logic;
    dbg_stg1_cal_done_cq_inst   : out std_logic_vector(CQ_WIDTH-1 downto 0);
    dbg_stg1_cal_done_cq_n_inst : out std_logic_vector(CQ_WIDTH-1 downto 0);
    dbg_stg2_cal_done_cq_inst   : out std_logic_vector(CQ_WIDTH-1 downto 0);
    dbg_stg2_cal_done_cq_n_inst : out std_logic_vector(CQ_WIDTH-1 downto 0);
    dbg_stg3_cal_done_cq_inst   : out std_logic_vector(CQ_WIDTH-1 downto 0);
    dbg_stg3_cal_done_cq_n_inst : out std_logic_vector(CQ_WIDTH-1 downto 0);
    dbg_q_tap_count_cq_inst     : out std_logic_vector((6*CQ_WIDTH)-1 downto 0);
    dbg_q_tap_count_cq_n_inst   : out std_logic_vector((6*CQ_WIDTH)-1 downto 0);
    dbg_cq_tap_count_inst       : out std_logic_vector((6*CQ_WIDTH)-1 downto 0);
    dbg_cq_n_tap_count_inst     : out std_logic_vector((6*CQ_WIDTH)-1 downto 0);
    dbg_data_valid_cq_inst      : out std_logic_vector(CQ_WIDTH-1 downto 0);
    dbg_data_valid_cq_n_inst    : out std_logic_vector(CQ_WIDTH-1 downto 0);
    dbg_cal_done                : out std_logic;
    dbg_init_wait_done          : out std_logic;
    dbg_data_valid              : out std_logic
    );
end entity ddrii_top;

architecture arch_ddrii_top of ddrii_top is

  ------------------------------------------------------------------------------
  -- constant Q_PER_CQ : integer := DATA_WIDTH/((CQ_WIDTH*(MEMORY_WIDTH/36))+CQ_WIDTH);
  -- Number of read data bits associated with a single read strobe. For a 36 bit
  -- component the value is always 18 because it is defined as number of
  -- read data bits associated with CQ and CQ#. For 18 bit components the value
  -- is always DATA_WIDTH/CQ_WIDTH, because it is defined as number of read data
  -- bits associated with CQ.
  ------------------------------------------------------------------------------
  constant Q_PER_CQ : integer := DATA_WIDTH/((CQ_WIDTH*(MEMORY_WIDTH/36))+CQ_WIDTH);

  component ddrii_top_ctrl_sm
    generic(
      BURST_LENGTH     : integer := BURST_LENGTH;
      IO_TYPE          : string  := IO_TYPE;
      BUS_TURNAROUND   : integer := BUS_TURNAROUND
      );
    port(
      clk_0             : in  std_logic;
      reset_clk_0       : in  std_logic;
      addr_fifo_empty   : in  std_logic;
      wrdata_fifo_empty : in  std_logic;
      cal_done          : in  std_logic;
      command_bit       : in  std_logic;
      addr_fifo_rd_en   : out std_logic;
      ctrl_ld_n         : out std_logic;
      ctrl_rw_n         : out std_logic
      );
  end component ddrii_top_ctrl_sm;

  component ddrii_top_user_interface
    generic(
      ADDR_WIDTH   : integer := ADDR_WIDTH;
      BURST_LENGTH : integer := BURST_LENGTH;
      BW_WIDTH     : integer := BW_WIDTH;
      DATA_WIDTH   : integer := DATA_WIDTH
      );
    port(
      clk_0              : in std_logic;
      reset_clk_0        : in std_logic;
      user_addr_wr_en    : in std_logic;
      user_wrdata_wr_en  : in std_logic;
      addr_fifo_rd_en    : in std_logic;
      wrdata_fifo_rd_en  : in std_logic;
      cal_done           : in std_logic;
      ptrn_data_wr_en_r1 : in std_logic;
      user_addr_cmd      : in std_logic_vector(ADDR_WIDTH downto 0);
      user_bw_n_rise     : in std_logic_vector(BW_WIDTH-1 downto 0);
      user_bw_n_fall     : in std_logic_vector(BW_WIDTH-1 downto 0);
      user_wr_data_rise  : in std_logic_vector(DATA_WIDTH-1 downto 0);
      user_wr_data_fall  : in std_logic_vector(DATA_WIDTH-1 downto 0);
      ptrn_data_rise_r1  : in std_logic_vector(DATA_WIDTH-1 downto 0);
      ptrn_data_fall_r1  : in std_logic_vector(DATA_WIDTH-1 downto 0);

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
  end component ddrii_top_user_interface;

  component ddrii_phy_top
     generic (
       ADDR_WIDTH            : integer := ADDR_WIDTH;
       BURST_LENGTH          : integer := BURST_LENGTH;
       BW_WIDTH              : integer := BW_WIDTH;
       CLK_FREQ              : integer := CLK_FREQ;
       CLK_WIDTH             : integer := CLK_WIDTH;
       CQ_WIDTH              : integer := CQ_WIDTH;
       DATA_WIDTH            : integer := DATA_WIDTH;
       DEBUG_EN              : integer := DEBUG_EN;
       HIGH_PERFORMANCE_MODE : boolean := HIGH_PERFORMANCE_MODE;
       IODELAY_GRP           : string  := IODELAY_GRP;
       IO_TYPE               : string  := IO_TYPE;
       MEMORY_WIDTH          : integer := MEMORY_WIDTH;
       Q_PER_CQ              : integer := Q_PER_CQ;
       SIM_ONLY              : integer := SIM_ONLY
       );
     port (
       clk_0              : in    std_logic;
       clk_90             : in    std_logic;
       clk_270            : in    std_logic;
       reset_clk_0        : in    std_logic;
       reset_clk_270      : in    std_logic;
       ctrl_ld_n          : in    std_logic;
       ctrl_rw_n          : in    std_logic;
       wr_rd_address      : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
       bw_n_rise          : in    std_logic_vector(BW_WIDTH-1 downto 0);
       bw_n_fall          : in    std_logic_vector(BW_WIDTH-1 downto 0);
       wr_data_rise       : in    std_logic_vector(DATA_WIDTH-1 downto 0);
       wr_data_fall       : in    std_logic_vector(DATA_WIDTH-1 downto 0);
       idelay_ctrl_ready  : in    std_logic;
       read_data_rise     : out   std_logic_vector(DATA_WIDTH-1 downto 0);
       read_data_fall     : out   std_logic_vector(DATA_WIDTH-1 downto 0);
       data_valid         : out   std_logic;
       cal_done           : out   std_logic;
       wrdata_fifo_rd_en  : out   std_logic;
       ptrn_data_rise_r1  : out   std_logic_vector(DATA_WIDTH-1 downto 0);
       ptrn_data_fall_r1  : out   std_logic_vector(DATA_WIDTH-1 downto 0);
       ptrn_data_wr_en_r1 : out   std_logic;
       ddrii_q            : in    std_logic_vector(DATA_WIDTH-1 downto 0);
       ddrii_dq           : inout std_logic_vector(DATA_WIDTH-1 downto 0);
       ddrii_cq           : in    std_logic_vector(CQ_WIDTH-1 downto 0);
       ddrii_cq_n         : in    std_logic_vector(CQ_WIDTH-1 downto 0);
       ddrii_c            : out   std_logic_vector(CLK_WIDTH-1 downto 0);
       ddrii_c_n          : out   std_logic_vector(CLK_WIDTH-1 downto 0);
       ddrii_dll_off_n    : out   std_logic;
       ddrii_k            : out   std_logic_vector(CLK_WIDTH-1 downto 0);
       ddrii_k_n          : out   std_logic_vector(CLK_WIDTH-1 downto 0);
       ddrii_sa           : out   std_logic_vector(ADDR_WIDTH-1 downto 0);
       ddrii_bw_n         : out   std_logic_vector(BW_WIDTH-1 downto 0);
       ddrii_rw_n         : out   std_logic;
       ddrii_d            : out   std_logic_vector(DATA_WIDTH-1 downto 0);
       ddrii_ld_n         : out   std_logic;
       -- Debug Signals
       dbg_idel_up_all             : in  std_logic;
       dbg_idel_down_all           : in  std_logic;
       dbg_idel_up_q               : in  std_logic;
       dbg_idel_down_q             : in  std_logic;
       dbg_sel_idel_q_cq           : in  std_logic_vector(CQ_WIDTH-1 downto 0);
       dbg_sel_all_idel_q_cq       : in  std_logic;
       dbg_sel_idel_q_cq_n         : in  std_logic_vector(CQ_WIDTH-1 downto 0);
       dbg_sel_all_idel_q_cq_n     : in  std_logic;
       dbg_idel_up_cq              : in  std_logic;
       dbg_idel_down_cq            : in  std_logic;
       dbg_sel_idel_cq             : in  std_logic_vector(CQ_WIDTH-1 downto 0);
       dbg_sel_all_idel_cq         : in  std_logic;
       dbg_sel_idel_cq_n           : in  std_logic_vector(CQ_WIDTH-1 downto 0);
       dbg_sel_all_idel_cq_n       : in  std_logic;
       dbg_stg1_cal_done_cq_inst   : out std_logic_vector(CQ_WIDTH-1 downto 0);
       dbg_stg1_cal_done_cq_n_inst : out std_logic_vector(CQ_WIDTH-1 downto 0);
       dbg_stg2_cal_done_cq_inst   : out std_logic_vector(CQ_WIDTH-1 downto 0);
       dbg_stg2_cal_done_cq_n_inst : out std_logic_vector(CQ_WIDTH-1 downto 0);
       dbg_stg3_cal_done_cq_inst   : out std_logic_vector(CQ_WIDTH-1 downto 0);
       dbg_stg3_cal_done_cq_n_inst : out std_logic_vector(CQ_WIDTH-1 downto 0);
       dbg_q_tap_count_cq_inst     : out std_logic_vector((6*CQ_WIDTH)-1 downto 0);
       dbg_q_tap_count_cq_n_inst   : out std_logic_vector((6*CQ_WIDTH)-1 downto 0);
       dbg_cq_tap_count_inst       : out std_logic_vector((6*CQ_WIDTH)-1 downto 0);
       dbg_cq_n_tap_count_inst     : out std_logic_vector((6*CQ_WIDTH)-1 downto 0);
       dbg_data_valid_cq_inst      : out std_logic_vector(CQ_WIDTH-1 downto 0);
       dbg_data_valid_cq_n_inst    : out std_logic_vector(CQ_WIDTH-1 downto 0);
       dbg_cal_done                : out std_logic;
       dbg_init_wait_done          : out std_logic
       );
  end component ddrii_phy_top;

  signal ctrl_ld_n             : std_logic;
  signal ctrl_rw_n             : std_logic;
  signal wrdata_fifo_rd_en     : std_logic;
  signal bw_n_rise             : std_logic_vector(BW_WIDTH-1 downto 0);
  signal bw_n_fall             : std_logic_vector(BW_WIDTH-1 downto 0);
  signal wr_data_rise          : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal wr_data_fall          : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal read_data_rise        : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal read_data_fall        : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal cal_done_i            : std_logic;
  signal cal_done_r            : std_logic;
  signal ptrn_data_rise_r1     : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal ptrn_data_fall_r1     : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal ptrn_data_wr_en_r1    : std_logic;
  signal data_valid            : std_logic;
  signal addr_fifo_empty       : std_logic;
  signal addr_fifo_wr_err      : std_logic;
  signal addr_fifo_rd_err      : std_logic;
  signal wrdata_fifo_empty     : std_logic;
  signal wrdata_fifo_wr_err    : std_logic;
  signal wrdata_fifo_rd_err    : std_logic;
  signal command_bit           : std_logic;
  signal wr_rd_address         : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal addr_fifo_rd_en       : std_logic;
  signal addr_fifo_wr_err_r1   : std_logic := '0';
  signal addr_fifo_rd_err_r1   : std_logic := '0';
  signal wrdata_fifo_wr_err_r1 : std_logic := '0';
  signal wrdata_fifo_rd_err_r1 : std_logic := '0';

begin

  dbg_data_valid    <= data_valid when (cal_done_r = '1') else '0';

  user_rd_data_rise <= read_data_rise;
  user_rd_data_fall <= read_data_fall;
  rd_data_valid     <= data_valid when (cal_done_r = '1') else '0';
  cal_done          <= cal_done_i;

  U1_CAL_DONE : FDRSE
    generic map (
      INIT => '0'
      )
    port map (
      Q  => cal_done_r,
      C  => clk_0,
      CE => '1',
      D  => cal_done_i,
      R  => '0',
      S  => '0'
      );

  U_DDRII_TOP_USER_INTERFACE : ddrii_top_user_interface
    generic map(
      ADDR_WIDTH   => ADDR_WIDTH,
      BURST_LENGTH => BURST_LENGTH,
      BW_WIDTH     => BW_WIDTH,
      DATA_WIDTH   => DATA_WIDTH
      )
    port map(
      clk_0              => clk_0,
      reset_clk_0        => reset_clk_0,
      user_addr_wr_en    => user_addr_wr_en,
      user_wrdata_wr_en  => user_wrdata_wr_en,
      addr_fifo_rd_en    => addr_fifo_rd_en,
      wrdata_fifo_rd_en  => wrdata_fifo_rd_en,
      cal_done           => cal_done_i,
      ptrn_data_wr_en_r1 => ptrn_data_wr_en_r1,
      user_addr_cmd      => user_addr_cmd,
      user_bw_n_rise     => user_bw_n_rise,
      user_bw_n_fall     => user_bw_n_fall,
      user_wr_data_rise  => user_wr_data_rise,
      user_wr_data_fall  => user_wr_data_fall,
      ptrn_data_rise_r1  => ptrn_data_rise_r1,
      ptrn_data_fall_r1  => ptrn_data_fall_r1,

      addr_fifo_empty    => addr_fifo_empty,
      addr_fifo_full     => addr_fifo_full,
      addr_fifo_wr_err   => addr_fifo_wr_err,
      addr_fifo_rd_err   => addr_fifo_rd_err,
      wrdata_fifo_full   => wrdata_fifo_full,
      wrdata_fifo_empty  => wrdata_fifo_empty,
      wrdata_fifo_wr_err => wrdata_fifo_wr_err,
      wrdata_fifo_rd_err => wrdata_fifo_rd_err,

      command_bit        => command_bit,
      wr_rd_address      => wr_rd_address,
      bw_n_rise          => bw_n_rise,
      bw_n_fall          => bw_n_fall,
      wr_data_rise       => wr_data_rise,
      wr_data_fall       => wr_data_fall
      );

  U_DDRII_TOP_CTRL_SM : ddrii_top_ctrl_sm
    generic map(
      BURST_LENGTH      => BURST_LENGTH,
      IO_TYPE           => IO_TYPE,
      BUS_TURNAROUND    => BUS_TURNAROUND
      )
    port map(
      clk_0             => clk_0,
      reset_clk_0       => reset_clk_0,
      addr_fifo_empty   => addr_fifo_empty,
      wrdata_fifo_empty => wrdata_fifo_empty,
      cal_done          => cal_done_i,
      command_bit       => command_bit,
      addr_fifo_rd_en   => addr_fifo_rd_en,
      ctrl_ld_n         => ctrl_ld_n,
      ctrl_rw_n         => ctrl_rw_n
      );

  U_DDRII_PHY_TOP : ddrii_phy_top
    generic map(
      ADDR_WIDTH            => ADDR_WIDTH,
      BURST_LENGTH          => BURST_LENGTH,
      BW_WIDTH              => BW_WIDTH,
      CLK_FREQ              => CLK_FREQ,
      CLK_WIDTH             => CLK_WIDTH,
      CQ_WIDTH              => CQ_WIDTH,
      DATA_WIDTH            => DATA_WIDTH,
      DEBUG_EN              => DEBUG_EN,
      HIGH_PERFORMANCE_MODE => HIGH_PERFORMANCE_MODE,
      IODELAY_GRP           => IODELAY_GRP,
      IO_TYPE               => IO_TYPE,
      MEMORY_WIDTH          => MEMORY_WIDTH,
      Q_PER_CQ              => Q_PER_CQ,
      SIM_ONLY              => SIM_ONLY
      )
    port map(
      clk_0              => clk_0,
      clk_90             => clk_90,
      clk_270            => clk_270,
      reset_clk_0        => reset_clk_0,
      reset_clk_270      => reset_clk_270,
      cal_done           => cal_done_i,
      ctrl_ld_n          => ctrl_ld_n,
      ctrl_rw_n          => ctrl_rw_n,
      wr_rd_address      => wr_rd_address,
      bw_n_rise          => bw_n_rise,
      bw_n_fall          => bw_n_fall,
      wr_data_rise       => wr_data_rise,
      wr_data_fall       => wr_data_fall,
      idelay_ctrl_ready  => idelay_ctrl_ready,
      read_data_rise     => read_data_rise,
      read_data_fall     => read_data_fall,
      data_valid         => data_valid,
      wrdata_fifo_rd_en  => wrdata_fifo_rd_en,
      ptrn_data_rise_r1  => ptrn_data_rise_r1,
      ptrn_data_fall_r1  => ptrn_data_fall_r1,
      ptrn_data_wr_en_r1 => ptrn_data_wr_en_r1,
      ddrii_c            => ddrii_c,
      ddrii_c_n          => ddrii_c_n,
      ddrii_dll_off_n    => ddrii_dll_off_n,
      ddrii_k            => ddrii_k,
      ddrii_k_n          => ddrii_k_n,
      ddrii_sa           => ddrii_sa,
      ddrii_bw_n         => ddrii_bw_n,
      ddrii_rw_n         => ddrii_rw_n,
      ddrii_d            => ddrii_d,
      ddrii_ld_n         => ddrii_ld_n,
      ddrii_q            => ddrii_q,
      ddrii_dq           => ddrii_dq,
      ddrii_cq           => ddrii_cq,
      ddrii_cq_n         => ddrii_cq_n,
      -- Debug signals
      dbg_idel_up_all             => dbg_idel_up_all,
      dbg_idel_down_all           => dbg_idel_down_all,
      dbg_idel_up_q               => dbg_idel_up_q,
      dbg_idel_down_q             => dbg_idel_down_q,
      dbg_sel_idel_q_cq           => dbg_sel_idel_q_cq,
      dbg_sel_all_idel_q_cq       => dbg_sel_all_idel_q_cq,
      dbg_sel_idel_q_cq_n         => dbg_sel_idel_q_cq_n,
      dbg_sel_all_idel_q_cq_n     => dbg_sel_all_idel_q_cq_n,
      dbg_idel_up_cq              => dbg_idel_up_cq,
      dbg_idel_down_cq            => dbg_idel_down_cq,
      dbg_sel_idel_cq             => dbg_sel_idel_cq,
      dbg_sel_all_idel_cq         => dbg_sel_all_idel_cq,
      dbg_sel_idel_cq_n           => dbg_sel_idel_cq_n,
      dbg_sel_all_idel_cq_n       => dbg_sel_all_idel_cq_n,
      dbg_stg1_cal_done_cq_inst   => dbg_stg1_cal_done_cq_inst,
      dbg_stg1_cal_done_cq_n_inst => dbg_stg1_cal_done_cq_n_inst,
      dbg_stg2_cal_done_cq_inst   => dbg_stg2_cal_done_cq_inst,
      dbg_stg2_cal_done_cq_n_inst => dbg_stg2_cal_done_cq_n_inst,
      dbg_stg3_cal_done_cq_inst   => dbg_stg3_cal_done_cq_inst,
      dbg_stg3_cal_done_cq_n_inst => dbg_stg3_cal_done_cq_n_inst,
      dbg_q_tap_count_cq_inst     => dbg_q_tap_count_cq_inst,
      dbg_q_tap_count_cq_n_inst   => dbg_q_tap_count_cq_n_inst,
      dbg_cq_tap_count_inst       => dbg_cq_tap_count_inst,
      dbg_cq_n_tap_count_inst     => dbg_cq_n_tap_count_inst,
      dbg_data_valid_cq_inst      => dbg_data_valid_cq_inst,
      dbg_data_valid_cq_n_inst    => dbg_data_valid_cq_n_inst,
      dbg_cal_done                => dbg_cal_done,
      dbg_init_wait_done          => dbg_init_wait_done
      );

  --synthesis translate_off

  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0 = '1') then
        wrdata_fifo_wr_err_r1 <= '0';
      elsif(wrdata_fifo_wr_err = '1') then
        wrdata_fifo_wr_err_r1 <= '1';
      else
        wrdata_fifo_wr_err_r1 <= wrdata_fifo_wr_err_r1;
      end if;
    end if;
  end process;

  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0 = '0') then
        assert (wrdata_fifo_wr_err_r1 = '0')
          report "WRITE DATA OR BYTE WRITE FIFO'S WRITE ERROR at time " & time'image(now);
      end if;
    end if;
  end process;

  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0 = '1') then
        wrdata_fifo_rd_err_r1 <= '0';
      elsif(wrdata_fifo_rd_err = '1') then
        wrdata_fifo_rd_err_r1 <= '1';
      else
        wrdata_fifo_rd_err_r1 <= wrdata_fifo_rd_err_r1;
      end if;
    end if;
  end process;

  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0 = '0') then
        assert (wrdata_fifo_rd_err_r1 = '0')
          report "WRITE DATA OR BYTE WRITE FIFO'S READ ERROR at time " & time'image(now);
      end if;
    end if;
  end process;

  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0 = '1') then
        addr_fifo_wr_err_r1 <= '0';
      elsif(addr_fifo_wr_err = '1') then
        addr_fifo_wr_err_r1 <= '1';
      else
        addr_fifo_wr_err_r1 <= addr_fifo_wr_err_r1;
      end if;
    end if;
  end process;

  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0 = '0') then
        assert (addr_fifo_wr_err_r1 = '0')
          report "ADDRESS FIFO WRITE ERROR at time " & time'image(now);
      end if;
    end if;
  end process;

  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0 = '1') then
        addr_fifo_rd_err_r1 <= '0';
      elsif(addr_fifo_rd_err = '1') then
        addr_fifo_rd_err_r1 <= '1';
      else
        addr_fifo_rd_err_r1 <= addr_fifo_rd_err_r1;
      end if;
    end if;
  end process;

  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0 = '0') then
        assert (addr_fifo_rd_err_r1 = '0')
          report "ADDRESS FIFO READ ERROR at time " & time'image(now);
      end if;
    end if;
  end process;

  --synthesis translate_on

end architecture arch_ddrii_top;
