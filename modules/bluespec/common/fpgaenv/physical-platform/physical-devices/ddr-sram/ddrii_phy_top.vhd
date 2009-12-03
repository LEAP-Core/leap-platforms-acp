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
--  /   /         Filename           : ddrii_phy_top.vhd
-- /___/   /\     Timestamp          : 08 Apr 2008
-- \   \  /  \    Date Last Modified : $Date: 2009/03/23 16:11:01 $
--  \___\/\___\
--
--Device: Virtex-5
--Design: DDRII
--
--Purpose:
--    This module
--       1. serves as the top level phy layer. The phy layer serves as the main
--          interface section between the FPGA and the memory.
--       2. Instantiates all the interface modules to the memory, including the
--          clocks, address, commands, write interface and read data interface.

--Revision History:
--   Rev 1.1 - Parameter IODELAY_GRP added. PK. 11/27/08
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;

entity ddrii_phy_top is
  generic (
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
    IO_TYPE               : string  := "CIO";
    HIGH_PERFORMANCE_MODE : boolean := TRUE;
    IODELAY_GRP           : string  := "IODELAY_MIG";
    MEMORY_WIDTH          : integer := 36;
    Q_PER_CQ              : integer := 18;
    SIM_ONLY              : integer := 0
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
    ddrii_c            : out   std_logic_vector(CLK_WIDTH-1 downto 0);
    ddrii_c_n          : out   std_logic_vector(CLK_WIDTH-1 downto 0);
    ddrii_dll_off_n    : out   std_logic;
    ddrii_k            : out   std_logic_vector(CLK_WIDTH-1 downto 0);
    ddrii_k_n          : out   std_logic_vector(CLK_WIDTH-1 downto 0);
    ddrii_sa           : out   std_logic_vector(ADDR_WIDTH-1 downto 0);
    ddrii_rw_n         : out   std_logic;
    ddrii_d            : out   std_logic_vector(DATA_WIDTH-1 downto 0);
    ddrii_q            : in    std_logic_vector(DATA_WIDTH-1 downto 0);
    ddrii_dq           : inout std_logic_vector(DATA_WIDTH-1 downto 0);
    ddrii_bw_n         : out   std_logic_vector(BW_WIDTH-1 downto 0);
    ddrii_ld_n         : out   std_logic;
    ddrii_cq           : in    std_logic_vector(CQ_WIDTH-1 downto 0);
    ddrii_cq_n         : in    std_logic_vector(CQ_WIDTH-1 downto 0);

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
end entity ddrii_phy_top;

architecture arch_ddrii_phy_top of ddrii_phy_top is

  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of arch_ddrii_phy_top : architecture is
    "mig_v3_1_ddrii_sram_v5, Coregen 11.2";
  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of arch_ddrii_phy_top : architecture is "ddrii_sram_v5,mig_v3_1,{component_name=mig_31, addr_width = 21, burst_length = 2, bw_width = 4, clk_freq = 200, clk_width = 1, cq_width = 1, data_width = 36, memory_width = 36, rst_act_low = 1}";

  constant Q_PER_CQ_9 : integer := Q_PER_CQ/9; -- Number of sets of 9 bits in
                                               -- every read data bits associated
                                               -- with the corresponding read strobe
                                               -- (CQ) bit.

  signal cal_ld_n         : std_logic;
  signal cal_rw_n         : std_logic;
  signal write_cmd_r3     : std_logic;
  signal not_write_cmd_r5 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal cal_addr         : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal read_cmd         : std_logic;
  signal init_wait_done   : std_logic;
  signal cal_done_i       : std_logic;
  signal bw_n_rise_r      : std_logic_vector(BW_WIDTH-1 downto 0);
  signal bw_n_fall_r      : std_logic_vector(BW_WIDTH-1 downto 0);
  signal wr_data_rise_r   : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal wr_data_fall_r   : std_logic_vector(DATA_WIDTH-1 downto 0);

  component ddrii_phy_ctrl_io
    generic(
      ADDR_WIDTH        : integer := ADDR_WIDTH;
      BURST_LENGTH      : integer := BURST_LENGTH;
      CLK_WIDTH         : integer := CLK_WIDTH;
      DATA_WIDTH        : integer := DATA_WIDTH;
      IO_TYPE           : string  := IO_TYPE
      );
    port(
      clk_0             : in  std_logic;
      clk_90            : in  std_logic;
      clk_270           : in  std_logic;
      reset_clk_0       : in  std_logic;
      reset_clk_270     : in  std_logic;
      ctrl_ld_n         : in  std_logic;
      ctrl_rw_n         : in  std_logic;
      cal_ld_n          : in  std_logic;
      cal_rw_n          : in  std_logic;
      init_wait_done    : in  std_logic;
      cal_done          : in  std_logic;
      cal_addr          : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      wr_rd_address     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      read_cmd          : out std_logic;
      wrdata_fifo_rd_en : out std_logic;
      write_cmd_r3      : out std_logic;
      not_write_cmd_r5  : out std_logic_vector(DATA_WIDTH-1 downto 0);
      ddrii_ld_n        : out std_logic;
      ddrii_rw_n        : out std_logic;
      ddrii_dll_off_n   : out std_logic;
      ddrii_c           : out std_logic_vector(CLK_WIDTH-1 downto 0);
      ddrii_c_n         : out std_logic_vector(CLK_WIDTH-1 downto 0);
      ddrii_k           : out std_logic_vector(CLK_WIDTH-1 downto 0);
      ddrii_k_n         : out std_logic_vector(CLK_WIDTH-1 downto 0);
      ddrii_sa          : out std_logic_vector(ADDR_WIDTH-1 downto 0)
      );
  end component ddrii_phy_ctrl_io;

  component ddrii_phy_write
    generic(
      BURST_LENGTH     : integer := BURST_LENGTH;
      DATA_WIDTH       : integer := DATA_WIDTH;
      BW_WIDTH         : integer := BW_WIDTH
      );
    port(
      clk_0              : in  std_logic;
      reset_clk_0        : in  std_logic;
      write_cmd_r3       : in  std_logic;
      bw_n_rise          : in  std_logic_vector(BW_WIDTH-1 downto 0);
      bw_n_fall          : in  std_logic_vector(BW_WIDTH-1 downto 0);
      wr_data_rise       : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      wr_data_fall       : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      bw_n_rise_r        : out std_logic_vector(BW_WIDTH-1 downto 0);
      bw_n_fall_r        : out std_logic_vector(BW_WIDTH-1 downto 0);
      wr_data_rise_r     : out std_logic_vector(DATA_WIDTH-1 downto 0);
      wr_data_fall_r     : out std_logic_vector(DATA_WIDTH-1 downto 0);
      ptrn_data_rise_r1  : out std_logic_vector(DATA_WIDTH-1 downto  0);
      ptrn_data_fall_r1  : out std_logic_vector(DATA_WIDTH-1 downto  0);
      ptrn_data_wr_en_r1 : out std_logic
      );
  end component ddrii_phy_write;

  component ddrii_phy_io
   generic(
     ADDR_WIDTH            : integer := ADDR_WIDTH;
     BURST_LENGTH          : integer := BURST_LENGTH;
     BW_WIDTH              : integer := BW_WIDTH;
     CLK_FREQ              : integer := CLK_FREQ;
     CQ_WIDTH              : integer := CQ_WIDTH;
     DATA_WIDTH            : integer := DATA_WIDTH;
     DEBUG_EN              : integer := DEBUG_EN;
     IO_TYPE               : string  := IO_TYPE;
     HIGH_PERFORMANCE_MODE : boolean := HIGH_PERFORMANCE_MODE;
     IODELAY_GRP           : string  := IODELAY_GRP;
     MEMORY_WIDTH          : integer := MEMORY_WIDTH;
     Q_PER_CQ              : integer := Q_PER_CQ;
     Q_PER_CQ_9            : integer := Q_PER_CQ_9;
     SIM_ONLY              : integer := SIM_ONLY
     );
   port(
     clk_0                       : in    std_logic;
     reset_clk_0                 : in    std_logic;
     idly_ctrl_ready             : in    std_logic;
     read_cmd                    : in    std_logic;
     not_write_cmd_r5            : in    std_logic_vector(DATA_WIDTH-1 downto 0);
     wr_data_rise_r              : in    std_logic_vector(DATA_WIDTH-1 downto 0);
     wr_data_fall_r              : in    std_logic_vector(DATA_WIDTH-1 downto 0);
     bw_n_rise_r                 : in    std_logic_vector(BW_WIDTH-1 downto 0);
     bw_n_fall_r                 : in    std_logic_vector(BW_WIDTH-1 downto 0);
     ddrii_q                     : in    std_logic_vector(DATA_WIDTH-1 downto 0);
     ddrii_cq                    : in    std_logic_vector(CQ_WIDTH-1 downto 0);
     ddrii_cq_n                  : in    std_logic_vector(CQ_WIDTH-1 downto 0);
     ddrii_d                     : out   std_logic_vector(DATA_WIDTH-1 downto 0);
     ddrii_bw_n                  : out   std_logic_vector(BW_WIDTH-1 downto 0);
     read_data_rise              : out   std_logic_vector(DATA_WIDTH-1 downto 0);
     read_data_fall              : out   std_logic_vector(DATA_WIDTH-1 downto 0);
     cal_addr                    : out   std_logic_vector(ADDR_WIDTH-1 downto 0);
     data_valid                  : out   std_logic;
     cal_ld_n                    : out   std_logic;
     cal_rw_n                    : out   std_logic;
     cal_done                    : out   std_logic;
     init_wait_done              : out   std_logic;
     ddrii_dq                    : inout std_logic_vector(DATA_WIDTH-1 downto 0);
     -- Debug Signals
     dbg_idel_up_all             : in    std_logic;
     dbg_idel_down_all           : in    std_logic;
     dbg_idel_up_q               : in    std_logic;
     dbg_idel_down_q             : in    std_logic;
     dbg_sel_idel_q_cq           : in    std_logic_vector(CQ_WIDTH-1 downto 0);
     dbg_sel_all_idel_q_cq       : in    std_logic;
     dbg_sel_idel_q_cq_n         : in    std_logic_vector(CQ_WIDTH-1 downto 0);
     dbg_sel_all_idel_q_cq_n     : in    std_logic;
     dbg_idel_up_cq              : in    std_logic;
     dbg_idel_down_cq            : in    std_logic;
     dbg_sel_idel_cq             : in    std_logic_vector(CQ_WIDTH-1 downto 0);
     dbg_sel_all_idel_cq         : in    std_logic;
     dbg_sel_idel_cq_n           : in    std_logic_vector(CQ_WIDTH-1 downto 0);
     dbg_sel_all_idel_cq_n       : in    std_logic;
     dbg_stg1_cal_done_cq_inst   : out   std_logic_vector(CQ_WIDTH-1 downto 0);
     dbg_stg1_cal_done_cq_n_inst : out   std_logic_vector(CQ_WIDTH-1 downto 0);
     dbg_stg2_cal_done_cq_inst   : out   std_logic_vector(CQ_WIDTH-1 downto 0);
     dbg_stg2_cal_done_cq_n_inst : out   std_logic_vector(CQ_WIDTH-1 downto 0);
     dbg_stg3_cal_done_cq_inst   : out   std_logic_vector(CQ_WIDTH-1 downto 0);
     dbg_stg3_cal_done_cq_n_inst : out   std_logic_vector(CQ_WIDTH-1 downto 0);
     dbg_q_tap_count_cq_inst     : out   std_logic_vector((6*CQ_WIDTH)-1 downto 0);
     dbg_q_tap_count_cq_n_inst   : out   std_logic_vector((6*CQ_WIDTH)-1 downto 0);
     dbg_cq_tap_count_inst       : out   std_logic_vector((6*CQ_WIDTH)-1 downto 0);
     dbg_cq_n_tap_count_inst     : out   std_logic_vector((6*CQ_WIDTH)-1 downto 0);
     dbg_data_valid_cq_inst      : out   std_logic_vector(CQ_WIDTH-1 downto 0);
     dbg_data_valid_cq_n_inst    : out   std_logic_vector(CQ_WIDTH-1 downto 0);
     dbg_cal_done                : out   std_logic
     );
  end component ddrii_phy_io;

begin

  cal_done           <= cal_done_i;
  dbg_init_wait_done <= init_wait_done;

  U_DDRII_PHY_CTRL_IO : ddrii_phy_ctrl_io
    generic map (
      ADDR_WIDTH        => ADDR_WIDTH,
      BURST_LENGTH      => BURST_LENGTH,
      CLK_WIDTH         => CLK_WIDTH,
      DATA_WIDTH        => DATA_WIDTH,
      IO_TYPE           => IO_TYPE
      )
    port map (
      clk_0             => clk_0,
      clk_90            => clk_90,
      clk_270           => clk_270,
      reset_clk_0       => reset_clk_0,
      reset_clk_270     => reset_clk_270,
      init_wait_done    => init_wait_done,
      ctrl_ld_n         => ctrl_ld_n,
      ctrl_rw_n         => ctrl_rw_n,
      cal_ld_n          => cal_ld_n,
      cal_rw_n          => cal_rw_n,
      cal_addr          => cal_addr,
      wr_rd_address     => wr_rd_address,
      read_cmd          => read_cmd,
      wrdata_fifo_rd_en => wrdata_fifo_rd_en,
      write_cmd_r3      => write_cmd_r3,
      not_write_cmd_r5  => not_write_cmd_r5,
      ddrii_ld_n        => ddrii_ld_n,
      ddrii_rw_n        => ddrii_rw_n,
      cal_done          => cal_done_i,
      ddrii_sa          => ddrii_sa,
      ddrii_c           => ddrii_c,
      ddrii_c_n         => ddrii_c_n,
      ddrii_k           => ddrii_k,
      ddrii_k_n         => ddrii_k_n,
      ddrii_dll_off_n   => ddrii_dll_off_n
      );

  U_DDRII_PHY_WRITE : ddrii_phy_write
    generic map (
      BURST_LENGTH        => BURST_LENGTH,
      DATA_WIDTH          => DATA_WIDTH,
      BW_WIDTH            => BW_WIDTH
      )
    port map (
       clk_0              => clk_0,
       reset_clk_0        => reset_clk_0,
       write_cmd_r3       => write_cmd_r3,
       bw_n_rise          => bw_n_rise,
       bw_n_fall          => bw_n_fall,
       wr_data_rise       => wr_data_rise,
       wr_data_fall       => wr_data_fall,
       bw_n_rise_r        => bw_n_rise_r,
       bw_n_fall_r        => bw_n_fall_r,
       wr_data_rise_r     => wr_data_rise_r,
       wr_data_fall_r     => wr_data_fall_r,
       ptrn_data_rise_r1  => ptrn_data_rise_r1,
       ptrn_data_fall_r1  => ptrn_data_fall_r1,
       ptrn_data_wr_en_r1 => ptrn_data_wr_en_r1
       );

  U_DDRII_PHY_IO : ddrii_phy_io
    generic map (
      BURST_LENGTH                => BURST_LENGTH,
      BW_WIDTH                    => BW_WIDTH,
      CLK_FREQ                    => CLK_FREQ,
      CQ_WIDTH                    => CQ_WIDTH,
      DATA_WIDTH                  => DATA_WIDTH,
      DEBUG_EN                    => DEBUG_EN,
      IO_TYPE                     => IO_TYPE,
      HIGH_PERFORMANCE_MODE       => HIGH_PERFORMANCE_MODE,
      IODELAY_GRP                 => IODELAY_GRP,
      MEMORY_WIDTH                => MEMORY_WIDTH,
      Q_PER_CQ                    => Q_PER_CQ,
      Q_PER_CQ_9                  => Q_PER_CQ_9,
      SIM_ONLY                    => SIM_ONLY
      )
    port map (
      clk_0                       => clk_0,
      reset_clk_0                 => reset_clk_0,
      idly_ctrl_ready             => idelay_ctrl_ready,
      read_cmd                    => read_cmd,
      not_write_cmd_r5            => not_write_cmd_r5,
      bw_n_rise_r                 => bw_n_rise_r,
      bw_n_fall_r                 => bw_n_fall_r,
      wr_data_rise_r              => wr_data_rise_r,
      wr_data_fall_r              => wr_data_fall_r,
      ddrii_q                     => ddrii_q,
      ddrii_cq                    => ddrii_cq,
      ddrii_cq_n                  => ddrii_cq_n,
      ddrii_d                     => ddrii_d,
      ddrii_bw_n                  => ddrii_bw_n,
      read_data_rise              => read_data_rise,
      read_data_fall              => read_data_fall,
      cal_addr                    => cal_addr,
      data_valid                  => data_valid,
      cal_ld_n                    => cal_ld_n,
      cal_rw_n                    => cal_rw_n,
      cal_done                    => cal_done_i,
      init_wait_done              => init_wait_done,
      ddrii_dq                    => ddrii_dq,
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
      dbg_cal_done                => dbg_cal_done
      );

end architecture arch_ddrii_phy_top;