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
--  /   /         Filename           : ddrii_phy_io.vhd
-- /___/   /\     Timestamp          : 08 Apr 2008
-- \   \  /  \    Date Last Modified : $Date: 2009/03/23 16:11:01 $
--  \___\/\___\
--
--Device: Virtex-5
--Design: DDRII
--
--Purpose:
--    This module
--  1. Is the top level module for read capture.
--  2. Instantiates the I/O modules for the memory clock and data, the
--     initialization state machine, the delay calibration state machine.,
--
--Revision History:
--   Rev 1.1 - Parameter IODELAY_GRP added. PK. 11/27/08
--*****************************************************************************

library ieee;
library unisim;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;

entity ddrii_phy_io is
  generic(
    -- Following parameters are for 72-bit design. Actual values may be
    -- different. Actual parameters values are passed from design top module
    -- mig_31 module. Please refer to the mig_31 module for actual
    -- values.
    ADDR_WIDTH            : integer := 19;
    BURST_LENGTH          : integer := 4;
    BW_WIDTH              : integer := 8;
    CLK_FREQ              : integer := 300;
    CQ_WIDTH              : integer := 2;
    DATA_WIDTH            : integer := 72;
    DEBUG_EN              : integer := 0;
    HIGH_PERFORMANCE_MODE : boolean := TRUE;
    IODELAY_GRP           : string  := "IODELAY_MIG";
    IO_TYPE               : string  := "CIO";
    MEMORY_WIDTH          : integer := 36;
    Q_PER_CQ              : integer := 36;
    Q_PER_CQ_9            : integer := 4;
    SIM_ONLY              : integer := 0
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
end entity ddrii_phy_io;

architecture arch_ddrii_phy_io of ddrii_phy_io is

  ------------------------------------------------------------------------------
  -- For a 36 bit component design the value is 2*CQ_WIDTH, for 18 bit component
  -- designs the value is CQ_WIDTH. For x36 bit component designs, both CQ and
  -- CQ# are used in calibration. For x18 bit component designs, only CQ is used
  -- in calibration.
  ------------------------------------------------------------------------------
  constant STROBE_WIDTH : integer := ((CQ_WIDTH*(MEMORY_WIDTH/36))+CQ_WIDTH);

  constant ONES : std_logic_vector(CQ_WIDTH-1 downto 0) := (others =>'1');

  signal cal_start               : std_logic;
  signal stg2_cal_done           : std_logic;
  signal stg3_cal_start          : std_logic;
  signal stg3_cal_done           : std_logic;
  signal cal_done_i              : std_logic;
  signal stg1_cal_done           : std_logic;
  signal init_wait_done_i        : std_logic;
  signal stg1_cal_done_cq_inst   : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal stg1_cal_done_cq_n_inst : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal stg2_cal_done_cq_inst   : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal stg2_cal_done_cq_n_inst : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal stg3_cal_done_cq_inst   : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal stg3_cal_done_cq_n_inst : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal q_cq_dly_ce             : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal q_cq_n_dly_ce           : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal q_cq_dly_inc            : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal q_cq_n_dly_inc          : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal q_cq_dly_rst            : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal q_cq_n_dly_rst          : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal cq_dly_ce               : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal cq_n_dly_ce             : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal cq_dly_inc              : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal cq_n_dly_inc            : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal cq_dly_rst              : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal cq_n_dly_rst            : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal read_data_rise_i        : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal read_data_fall_i        : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal read_data_rise_o        : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal read_data_fall_o        : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal data_valid_in           : std_logic_vector(STROBE_WIDTH-1 downto 0);
  signal data_valid_cq_inst      : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal data_valid_cq_n_inst    : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal cq_bufio                : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal cq_n_bufio              : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal srl_count               : std_logic_vector((STROBE_WIDTH*4)-1 downto 0);

  signal dbg_sel_idel_q_cq_i     : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal dbg_sel_idel_q_cq_n_i   : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal dbg_sel_idel_cq_i       : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal dbg_sel_idel_cq_n_i     : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal dbg_idel_up_q_i         : std_logic;
  signal dbg_idel_down_q_i       : std_logic;
  signal dbg_idel_up_cq_i        : std_logic;
  signal dbg_idel_down_cq_i      : std_logic;

  component ddrii_phy_cq_io
    generic
      (
      CQ_WIDTH              : integer := CQ_WIDTH;
      HIGH_PERFORMANCE_MODE : boolean := HIGH_PERFORMANCE_MODE;
      IODELAY_GRP           : string  := IODELAY_GRP;
      MEMORY_WIDTH          : integer := MEMORY_WIDTH
      );
    port(
      clk_0        : in  std_logic;
      ddrii_cq     : in  std_logic_vector(CQ_WIDTH-1 downto 0);
      ddrii_cq_n   : in  std_logic_vector(CQ_WIDTH-1 downto 0);
      cq_dly_ce    : in  std_logic_vector(CQ_WIDTH-1 downto 0);
      cq_dly_inc   : in  std_logic_vector(CQ_WIDTH-1 downto 0);
      cq_dly_rst   : in  std_logic_vector(CQ_WIDTH-1 downto 0);
      cq_n_dly_ce  : in  std_logic_vector(CQ_WIDTH-1 downto 0);
      cq_n_dly_inc : in  std_logic_vector(CQ_WIDTH-1 downto 0);
      cq_n_dly_rst : in  std_logic_vector(CQ_WIDTH-1 downto 0);
      cq_bufio     : out std_logic_vector(CQ_WIDTH-1 downto 0);
      cq_n_bufio   : out std_logic_vector(CQ_WIDTH-1 downto 0)
      );
  end component ddrii_phy_cq_io;

  component ddrii_phy_dq_io
    generic(
      BW_WIDTH              : integer := BW_WIDTH;
      CQ_WIDTH              : integer := CQ_WIDTH;
      DATA_WIDTH            : integer := DATA_WIDTH;
      HIGH_PERFORMANCE_MODE : boolean := HIGH_PERFORMANCE_MODE;
      IODELAY_GRP           : string  := IODELAY_GRP;
      IO_TYPE               : string  := IO_TYPE;
      MEMORY_WIDTH          : integer := MEMORY_WIDTH;
      Q_PER_CQ              : integer := Q_PER_CQ
      );
    port(
      clk_0            : in    std_logic;
      cq_bufio         : in    std_logic_vector(CQ_WIDTH-1 downto 0);
      cq_n_bufio       : in    std_logic_vector(CQ_WIDTH-1 downto 0);
      q_cq_dly_ce      : in    std_logic_vector(CQ_WIDTH-1 downto 0);
      q_cq_dly_inc     : in    std_logic_vector(CQ_WIDTH-1 downto 0);
      q_cq_dly_rst     : in    std_logic_vector(CQ_WIDTH-1 downto 0);
      q_cq_n_dly_ce    : in    std_logic_vector(CQ_WIDTH-1 downto 0);
      q_cq_n_dly_inc   : in    std_logic_vector(CQ_WIDTH-1 downto 0);
      q_cq_n_dly_rst   : in    std_logic_vector(CQ_WIDTH-1 downto 0);
      wr_data_rise_r   : in    std_logic_vector(DATA_WIDTH-1 downto 0);
      wr_data_fall_r   : in    std_logic_vector(DATA_WIDTH-1 downto 0);
      ddrii_q          : in    std_logic_vector(DATA_WIDTH-1 downto 0);
      not_write_cmd_r5 : in    std_logic_vector(DATA_WIDTH-1 downto 0);
      ddrii_d          : out   std_logic_vector(DATA_WIDTH-1 downto 0);
      read_data_rise   : out   std_logic_vector(DATA_WIDTH-1 downto 0);
      read_data_fall   : out   std_logic_vector(DATA_WIDTH-1 downto 0);
      ddrii_dq         : inout std_logic_vector(DATA_WIDTH-1 downto 0)
      );
  end component ddrii_phy_dq_io;

  component ddrii_phy_bw_io
    generic(
      BW_WIDTH   : integer := BW_WIDTH
      );
    port(
      clk_0       : in  std_logic;
      bw_n_rise_r : in  std_logic_vector(BW_WIDTH-1 downto 0);
      bw_n_fall_r : in  std_logic_vector(BW_WIDTH-1 downto 0);
      ddrii_bw_n  : out std_logic_vector(BW_WIDTH-1 downto 0)
      );
  end component ddrii_phy_bw_io;

  component ddrii_phy_init_sm
    generic(
      ADDR_WIDTH   : integer := ADDR_WIDTH;
      BURST_LENGTH : integer := BURST_LENGTH;
      CLK_FREQ     : integer := CLK_FREQ;
      IO_TYPE      : string  := IO_TYPE;
      SIM_ONLY     : integer := SIM_ONLY
      );
    port(
      clk_0           : in  std_logic;
      reset_clk_0     : in  std_logic;
      stg1_cal_done   : in  std_logic;
      stg2_cal_done   : in  std_logic;
      stg3_cal_done   : in  std_logic;
      idly_ctrl_ready : in  std_logic;
      cal_start       : out std_logic;
      stg3_cal_start  : out std_logic;
      cal_ld_n        : out std_logic;
      cal_rw_n        : out std_logic;
      cal_addr        : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      cal_done        : out std_logic;
      init_wait_done  : out std_logic
      );
  end component ddrii_phy_init_sm;

  component ddrii_phy_dly_cal_sm
    generic(
       BURST_LENGTH : integer := BURST_LENGTH;
       CLK_FREQ     : integer := CLK_FREQ;
       CQ_WIDTH     : integer := CQ_WIDTH;
       DATA_WIDTH   : integer := DATA_WIDTH;
       DEBUG_EN     : integer := DEBUG_EN;
       Q_PER_CQ     : integer := Q_PER_CQ;
       Q_PER_CQ_9   : integer := Q_PER_CQ_9
       );
    port(
      clk_0              : in  std_logic;
      reset_clk_0        : in  std_logic;
      cal_start          : in  std_logic;
      read_data_rise     : in  std_logic_vector(Q_PER_CQ-1 downto 0);
      read_data_fall     : in  std_logic_vector(Q_PER_CQ-1 downto 0);
      stg1_cal_done      : in  std_logic;
      read_cmd           : in  std_logic;
      stg3_cal_start     : in  std_logic;
      q_dly_rst          : out std_logic;
      q_dly_ce           : out std_logic;
      q_dly_inc          : out std_logic;
      cq_dly_rst         : out std_logic;
      cq_dly_ce          : out std_logic;
      cq_dly_inc         : out std_logic;
      stg2_cal_done_inst : out std_logic;
      stg1_cal_done_inst : out std_logic;
      data_valid_inst    : out std_logic;
      stg3_cal_done_inst : out std_logic;
      srl_count          : out std_logic_vector(3 downto 0);
      -- Debug Signals
      dbg_idel_up_q      : in  std_logic;
      dbg_idel_down_q    : in  std_logic;
      dbg_sel_idel_q_cq  : in  std_logic;
      dbg_idel_up_cq     : in  std_logic;
      dbg_idel_down_cq   : in  std_logic;
      dbg_sel_idel_cq    : in  std_logic;
      dbg_q_tap_count    : out std_logic_vector(5 downto 0);
      dbg_cq_tap_count   : out std_logic_vector(5 downto 0)
      );
  end component ddrii_phy_dly_cal_sm;

 component ddrii_phy_en is
  generic(
     DATA_WIDTH      : integer := DATA_WIDTH;
     CQ_WIDTH        : integer := CQ_WIDTH;
     Q_PER_CQ        : integer := Q_PER_CQ;
     STROBE_WIDTH    : integer := STROBE_WIDTH
     );
  port(
    clk_0            : in  std_logic;
    reset_clk_0      : in  std_logic;
    stg3_cal_done    : in  std_logic;
    read_data_rise_i : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    read_data_fall_i : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    data_valid_in    : in  std_logic_vector(STROBE_WIDTH-1 downto 0);
    srl_count        : in  std_logic_vector((STROBE_WIDTH*4)-1 downto 0);
    read_data_rise_o : out std_logic_vector(DATA_WIDTH-1 downto 0);
    read_data_fall_o : out std_logic_vector(DATA_WIDTH-1 downto 0);
    data_valid       : out std_logic
    );
end component ddrii_phy_en;

begin

  ------------------------------------------------------------------------------
  -- This logic is added to increment/decrement the tap delay count of CQ, CQ#
  -- and the respective Data(Q) bits associated with CQ/CQ# manually. You can
  -- increment/decrement the tap delay values for CQ/CQ# and the corresponding
  -- Data(Q) bits individually or all-together based on the input selection.
  -- You can increment/decrement the tap delay values through VIO (Virtual I/O)
  -- module of Chipscope. Refer to the MIG user guide for more information on
  -- debug port signals.
  --
  -- Note: For DDRII, idelay tap count values are applied on all the Data(Q)
  -- bits which are associated with the correspondng CQ/CQ#. You cannot change
  -- the tap value for each individual Data(Q) bit.
  ------------------------------------------------------------------------------

  dbg_sel_idel_q_cq_i   <= (others => '1') when (dbg_idel_up_all = '1' or dbg_idel_down_all = '1' or
                                                 dbg_sel_all_idel_q_cq = '1')
                                           else
                           dbg_sel_idel_q_cq;

  dbg_sel_idel_q_cq_n_i <= (others => '1') when (dbg_idel_up_all = '1' or dbg_idel_down_all = '1' or
                                                 dbg_sel_all_idel_q_cq_n = '1')
                                           else
                           dbg_sel_idel_q_cq_n;

  dbg_sel_idel_cq_i     <= (others => '1') when (dbg_idel_up_all = '1' or dbg_idel_down_all = '1' or
                                                 dbg_sel_all_idel_cq = '1')
                                           else
                           dbg_sel_idel_cq;

  dbg_sel_idel_cq_n_i   <= (others => '1') when (dbg_idel_up_all = '1' or dbg_idel_down_all = '1' or
                                                 dbg_sel_all_idel_cq_n = '1')
                                           else
                           dbg_sel_idel_cq_n;

  dbg_idel_up_q_i     <= dbg_idel_up_all or dbg_idel_up_q;
  dbg_idel_down_q_i   <= dbg_idel_down_all or dbg_idel_down_q;
  dbg_idel_up_cq_i    <= dbg_idel_up_all or dbg_idel_up_cq;
  dbg_idel_down_cq_i  <= dbg_idel_down_all or dbg_idel_down_cq;


  dbg_stg1_cal_done_cq_inst   <= stg1_cal_done_cq_inst;
  dbg_stg1_cal_done_cq_n_inst <= stg1_cal_done_cq_n_inst;
  dbg_stg2_cal_done_cq_inst   <= stg2_cal_done_cq_inst;
  dbg_stg2_cal_done_cq_n_inst <= stg2_cal_done_cq_n_inst;
  dbg_stg3_cal_done_cq_inst   <= stg3_cal_done_cq_inst;
  dbg_stg3_cal_done_cq_n_inst <= stg3_cal_done_cq_n_inst;
  dbg_data_valid_cq_inst      <= data_valid_cq_inst;
  dbg_data_valid_cq_n_inst    <= data_valid_cq_n_inst;
  dbg_cal_done                <= cal_done_i;

  cal_done       <= cal_done_i;
  read_data_rise <= read_data_rise_o;
  read_data_fall <= read_data_fall_o;

  D_V_36 : if(MEMORY_WIDTH = 36) generate
    D_V_SIG : for we_i in 0 to CQ_WIDTH-1 generate
      data_valid_in(((2*we_i)+1) downto (2*we_i)) <= (data_valid_cq_n_inst(we_i) &
                                                      data_valid_cq_inst(we_i));
    end generate D_V_SIG;
  end generate D_V_36;

  D_V_18_9 : if(MEMORY_WIDTH /= 36) generate
    data_valid_in <= data_valid_cq_inst;
  end generate D_V_18_9;

  FLAG_36 : if(MEMORY_WIDTH = 36) generate
    stg1_cal_done <= '1' when ((stg1_cal_done_cq_inst = ones) and
                               (stg1_cal_done_cq_n_inst = ones)) else
                     '0';
    stg2_cal_done <= '1' when ((stg2_cal_done_cq_inst = ones) and
                               (stg2_cal_done_cq_n_inst = ones)) else
                     '0';
    stg3_cal_done <= '1' when ((stg3_cal_done_cq_inst = ones) and
                               (stg3_cal_done_cq_n_inst = ones)) else
                     '0';
  end generate FLAG_36;

  FLAG_18_9 : if(MEMORY_WIDTH /= 36) generate
    stg1_cal_done <= '1' when (stg1_cal_done_cq_inst = ones) else '0';
    stg2_cal_done <= '1' when (stg2_cal_done_cq_inst = ones) else '0';
    stg3_cal_done <= '1' when (stg3_cal_done_cq_inst = ones) else '0';
  end generate FLAG_18_9;

  init_wait_done  <= init_wait_done_i;

  U_DDRII_PHY_CQ_IO : ddrii_phy_cq_io
    generic map
      (
      CQ_WIDTH              => CQ_WIDTH,
      HIGH_PERFORMANCE_MODE => HIGH_PERFORMANCE_MODE,
      IODELAY_GRP           => IODELAY_GRP,
      MEMORY_WIDTH          => MEMORY_WIDTH
      )
    port map(
      clk_0        => clk_0,
      ddrii_cq     => ddrii_cq,
      ddrii_cq_n   => ddrii_cq_n,
      cq_dly_ce    => cq_dly_ce,
      cq_dly_inc   => cq_dly_inc,
      cq_dly_rst   => cq_dly_rst,
      cq_n_dly_ce  => cq_n_dly_ce,
      cq_n_dly_inc => cq_n_dly_inc,
      cq_n_dly_rst => cq_n_dly_rst,
      cq_bufio     => cq_bufio,
      cq_n_bufio   => cq_n_bufio
      );

  ------------------------------------------------------------------------------
  -- DDR Q IO instantiations
  ------------------------------------------------------------------------------
  --clocked by CQ_0_P(BYTES 0,2)

  U_DDRII_PHY_DQ_IO : ddrii_phy_dq_io
     generic map(
       BW_WIDTH              => BW_WIDTH,
       DATA_WIDTH            => DATA_WIDTH,
       CQ_WIDTH              => CQ_WIDTH,
       HIGH_PERFORMANCE_MODE => HIGH_PERFORMANCE_MODE,
       IODELAY_GRP           => IODELAY_GRP,
       IO_TYPE               => IO_TYPE,
       MEMORY_WIDTH          => MEMORY_WIDTH,
       Q_PER_CQ              => Q_PER_CQ
       )
     port map(
       clk_0            => clk_0,
       ddrii_q          => ddrii_q,
       ddrii_d          => ddrii_d,
       ddrii_dq         => ddrii_dq,
       wr_data_rise_r   => wr_data_rise_r,
       wr_data_fall_r   => wr_data_fall_r,
       not_write_cmd_r5 => not_write_cmd_r5,
       cq_bufio         => cq_bufio,
       cq_n_bufio       => cq_n_bufio,
       q_cq_dly_ce      => q_cq_dly_ce,
       q_cq_dly_inc     => q_cq_dly_inc,
       q_cq_dly_rst     => q_cq_dly_rst,
       q_cq_n_dly_ce    => q_cq_n_dly_ce,
       q_cq_n_dly_inc   => q_cq_n_dly_inc,
       q_cq_n_dly_rst   => q_cq_n_dly_rst,
       read_data_rise   => read_data_rise_i,
       read_data_fall   => read_data_fall_i
       );

   -----------------------------------------------------------------------------
   -- DDR BW IO instantiations
   -----------------------------------------------------------------------------

  U_DDRII_PHY_BW_IO : ddrii_phy_bw_io
     generic map(
       BW_WIDTH    => BW_WIDTH
       )
     port map(
       clk_0       => clk_0,
       bw_n_rise_r => bw_n_rise_r,
       bw_n_fall_r => bw_n_fall_r,
       ddrii_bw_n  => ddrii_bw_n
       );

  ------------------------------------------------------------------------------
  -- Memory initialization state machine
  ------------------------------------------------------------------------------

  U_DDRII_PHY_INIT_SM : ddrii_phy_init_sm
    generic map(
      ADDR_WIDTH   => ADDR_WIDTH,
      BURST_LENGTH => BURST_LENGTH,
      CLK_FREQ     => CLK_FREQ,
      IO_TYPE      => IO_TYPE,
      SIM_ONLY     => SIM_ONLY
      )
    port map(
      clk_0           => clk_0,
      reset_clk_0     => reset_clk_0,
      stg1_cal_done   => stg1_cal_done,
      stg2_cal_done   => stg2_cal_done,
      stg3_cal_done   => stg3_cal_done,
      idly_ctrl_ready => idly_ctrl_ready,
      cal_start       => cal_start,
      stg3_cal_start  => stg3_cal_start,
      cal_ld_n        => cal_ld_n,
      cal_rw_n        => cal_rw_n,
      cal_addr        => cal_addr,
      cal_done        => cal_done_i,
      init_wait_done  => init_wait_done_i
      );

  CAL_INST_36 : if(MEMORY_WIDTH = 36) generate
    CAL_INST_CQ : for cqi in 0 to CQ_WIDTH-1 generate
      ----------------------------------------------------------------------------
      -- Delay calibration module CQ instantiation for 36 bit component
      ----------------------------------------------------------------------------
      U_DDRII_PHY_DLY_CAL_SM_CQ : ddrii_phy_dly_cal_sm
        generic map(
          BURST_LENGTH => BURST_LENGTH,
          CQ_WIDTH     => CQ_WIDTH,
          DATA_WIDTH   => DATA_WIDTH,
          DEBUG_EN     => DEBUG_EN,
          Q_PER_CQ     => Q_PER_CQ,
          Q_PER_CQ_9   => Q_PER_CQ_9
          )
        port map(
          clk_0              => clk_0,
          reset_clk_0        => reset_clk_0,
          cal_start          => cal_start,
          read_data_rise     => read_data_rise_i((((2*cqi)+1)*Q_PER_CQ)-1 downto
                                                 (2*cqi*Q_PER_CQ)),
          read_data_fall     => read_data_fall_i((((2*cqi)+1)*Q_PER_CQ)-1 downto
                                                 (2*cqi*Q_PER_CQ)),
          read_cmd           => read_cmd,
          stg3_cal_start     => stg3_cal_start,
          q_dly_rst          => q_cq_dly_rst(cqi),
          q_dly_ce           => q_cq_dly_ce(cqi),
          q_dly_inc          => q_cq_dly_inc(cqi),
          cq_dly_rst         => cq_dly_rst(cqi),
          cq_dly_ce          => cq_dly_ce(cqi),
          cq_dly_inc         => cq_dly_inc(cqi),
          stg1_cal_done_inst => stg1_cal_done_cq_inst(cqi),
          stg1_cal_done      => stg1_cal_done,
          stg2_cal_done_inst => stg2_cal_done_cq_inst(cqi),
          data_valid_inst    => data_valid_cq_inst(cqi),
          stg3_cal_done_inst => stg3_cal_done_cq_inst(cqi),
          srl_count          => srl_count((((2*cqi)+1)*4)-1 downto (2*cqi*4)),
          -- Debug Signals
          dbg_idel_up_q      => dbg_idel_up_q_i,
          dbg_idel_down_q    => dbg_idel_down_q_i,
          dbg_sel_idel_q_cq  => dbg_sel_idel_q_cq_i(cqi),
          dbg_idel_up_cq     => dbg_idel_up_cq_i,
          dbg_idel_down_cq   => dbg_idel_down_cq_i,
          dbg_sel_idel_cq    => dbg_sel_idel_cq_i(cqi),
          dbg_q_tap_count    => dbg_q_tap_count_cq_inst((6*(cqi+1))-1 downto 6*cqi),
          dbg_cq_tap_count   => dbg_cq_tap_count_inst((6*(cqi+1))-1 downto 6*cqi)
          );
    end generate CAL_INST_CQ;

    CAL_INST_CQ_N : for cq_ni in 0 to CQ_WIDTH-1 generate
      ----------------------------------------------------------------------------
      -- Delay calibration module CQ# instantiation for 36 bit component
      ----------------------------------------------------------------------------
      U_DDRII_PHY_DLY_CAL_SM_CQ_N : ddrii_phy_dly_cal_sm
        generic map(
          BURST_LENGTH => BURST_LENGTH,
          CQ_WIDTH     => CQ_WIDTH,
          DATA_WIDTH   => DATA_WIDTH,
          DEBUG_EN     => DEBUG_EN,
          Q_PER_CQ     => Q_PER_CQ,
          Q_PER_CQ_9   => Q_PER_CQ_9
          )
        port map(
          clk_0              => clk_0,
          reset_clk_0        => reset_clk_0,
          cal_start          => cal_start,
          read_data_rise     => read_data_rise_i((((2*cq_ni)+2)*Q_PER_CQ)-1 downto
                                                 (((2*cq_ni)+1)*Q_PER_CQ)),
          read_data_fall     => read_data_fall_i((((2*cq_ni)+2)*Q_PER_CQ)-1 downto
                                                 (((2*cq_ni)+1)*Q_PER_CQ)),
          read_cmd           => read_cmd,
          stg3_cal_start     => stg3_cal_start,
          q_dly_rst          => q_cq_n_dly_rst(cq_ni),
          q_dly_ce           => q_cq_n_dly_ce(cq_ni),
          q_dly_inc          => q_cq_n_dly_inc(cq_ni),
          cq_dly_rst         => cq_n_dly_rst(cq_ni),
          cq_dly_ce          => cq_n_dly_ce(cq_ni),
          cq_dly_inc         => cq_n_dly_inc(cq_ni),
          stg1_cal_done_inst => stg1_cal_done_cq_n_inst(cq_ni),
          stg1_cal_done      => stg1_cal_done,
          stg2_cal_done_inst => stg2_cal_done_cq_n_inst(cq_ni),
          data_valid_inst    => data_valid_cq_n_inst(cq_ni),
          stg3_cal_done_inst => stg3_cal_done_cq_n_inst(cq_ni),
          srl_count          => srl_count((((2*cq_ni)+2)*4)-1 downto
                                          (((2*cq_ni)+1)*4)),
          --Debug Signals
          dbg_idel_up_q      => dbg_idel_up_q_i,
          dbg_idel_down_q    => dbg_idel_down_q_i,
          dbg_sel_idel_q_cq  => dbg_sel_idel_q_cq_n_i(cq_ni),
          dbg_idel_up_cq     => dbg_idel_up_cq_i,
          dbg_idel_down_cq   => dbg_idel_down_cq_i,
          dbg_sel_idel_cq    => dbg_sel_idel_cq_n_i(cq_ni),
          dbg_q_tap_count    => dbg_q_tap_count_cq_n_inst((6*(cq_ni+1))-1 downto 6*cq_ni),
          dbg_cq_tap_count   => dbg_cq_n_tap_count_inst((6*(cq_ni+1))-1 downto 6*cq_ni)
          );
    end generate CAL_INST_CQ_N;
  end generate CAL_INST_36;

  CAL_INST_18_9 : if(MEMORY_WIDTH /= 36) generate
    CAL_INST_CQ : for cqi in 0 to CQ_WIDTH-1 generate
      --------------------------------------------------------------------------
      -- Delay calibration module CQ instantiation for 18bit & 9bit component
      --------------------------------------------------------------------------
      U_DDRII_PHY_DLY_CAL_SM_CQ : ddrii_phy_dly_cal_sm
        generic map(
          BURST_LENGTH => BURST_LENGTH,
          CQ_WIDTH     => CQ_WIDTH,
          DATA_WIDTH   => DATA_WIDTH,
          DEBUG_EN     => DEBUG_EN,
          Q_PER_CQ     => Q_PER_CQ,
          Q_PER_CQ_9   => Q_PER_CQ_9
          )
        port map(
          clk_0              => clk_0,
          reset_clk_0        => reset_clk_0,
          cal_start          => cal_start,
          read_data_rise     => read_data_rise_i(((cqi+1)*Q_PER_CQ)-1 downto
                                                 (cqi*Q_PER_CQ)),
          read_data_fall     => read_data_fall_i(((cqi+1)*Q_PER_CQ)-1 downto
                                                 (cqi*Q_PER_CQ)),
          read_cmd           => read_cmd,
          stg3_cal_start     => stg3_cal_start,
          q_dly_rst          => q_cq_dly_rst(cqi),
          q_dly_ce           => q_cq_dly_ce(cqi),
          q_dly_inc          => q_cq_dly_inc(cqi),
          cq_dly_rst         => cq_dly_rst(cqi),
          cq_dly_ce          => cq_dly_ce(cqi),
          cq_dly_inc         => cq_dly_inc(cqi),
          stg1_cal_done_inst => stg1_cal_done_cq_inst(cqi),
          stg1_cal_done      => stg1_cal_done,
          stg2_cal_done_inst => stg2_cal_done_cq_inst(cqi),
          data_valid_inst    => data_valid_cq_inst(cqi),
          stg3_cal_done_inst => stg3_cal_done_cq_inst(cqi),
          srl_count          => srl_count(((cqi+1)*4)-1 downto cqi*4),
          -- Debug Signals
          dbg_idel_up_q      => dbg_idel_up_q_i,
          dbg_idel_down_q    => dbg_idel_down_q_i,
          dbg_sel_idel_q_cq  => dbg_sel_idel_q_cq_i(cqi),
          dbg_idel_up_cq     => dbg_idel_up_cq_i,
          dbg_idel_down_cq   => dbg_idel_down_cq_i,
          dbg_sel_idel_cq    => dbg_sel_idel_cq_i(cqi),
          dbg_q_tap_count    => dbg_q_tap_count_cq_inst((6*(cqi+1))-1 downto 6*cqi),
          dbg_cq_tap_count   => dbg_cq_tap_count_inst((6*(cqi+1))-1 downto 6*cqi)
          );
    end generate CAL_INST_CQ;
  end generate CAL_INST_18_9;

  U_DDRII_PHY_EN : ddrii_phy_en
    generic map (
      DATA_WIDTH       => DATA_WIDTH,
      CQ_WIDTH         => CQ_WIDTH,
      Q_PER_CQ         => Q_PER_CQ,
      STROBE_WIDTH     => STROBE_WIDTH
      )
    port map(
      clk_0            => clk_0,
      reset_clk_0      => reset_clk_0,
      stg3_cal_done    => stg3_cal_done,
      read_data_rise_i => read_data_rise_i,
      read_data_fall_i => read_data_fall_i,
      data_valid_in    => data_valid_in(STROBE_WIDTH-1 downto 0),
      srl_count        => srl_count((STROBE_WIDTH*4)-1 downto 0),
      read_data_rise_o => read_data_rise_o,
      read_data_fall_o => read_data_fall_o,
      data_valid       => data_valid
      );

  -- synthesis translate_off
  process(init_wait_done_i)
  begin
    if(reset_clk_0 = '0') then
      if(rising_edge(init_wait_done_i))then
        report "INITIALIZATION PERIOD OF 200uSec IS COMPLETE at time " & time'image(now);
      end if;
    end if;
  end process;

  process(stg1_cal_done)
  begin
    if(reset_clk_0 = '0') then
      if(rising_edge(stg1_cal_done))then
        report "FIRST STAGE CALIBRATION COMPLETE at time " & time'image(now);
      end if;
    end if;
  end process;

  process(stg2_cal_done)
  begin
    if(reset_clk_0 = '0') then
      if(rising_edge(stg2_cal_done))then
        report "SECOND STAGE CALIBRATION COMPLETE at time " & time'image(now);
      end if;
    end if;
  end process;

  process(stg3_cal_done)
  begin
    if(reset_clk_0 = '0') then
      if(rising_edge(stg3_cal_done))then
        report "READ ENABLE CALIBRATION COMPLETE at time " & time'image(now);
       end if;
    end if;
  end process;

  -- synthesis translate_on

end architecture arch_ddrii_phy_io;
