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
--  /   /         Filename           : ddrii_phy_dly_cal_sm.vhd
-- /___/   /\     Timestamp          : 08 Apr 2008
-- \   \  /  \    Date Last Modified : $Date: 2009/05/09 16:59:26 $
--  \___\/\___\
--
--Device: Virtex-5
--Design: DDRII
--
--Purpose:
--    This module
--       1. Calibrates the IDELAY tap values for the DDRII_Q and DDRII_CQ inputs
--          to allow direct capture of the read data into the system clock
--          domain.
--
--Revision History:
--
--*****************************************************************************

library ieee;
library unisim;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;

entity ddrii_phy_dly_cal_sm is
  generic(
    -- Following parameters are for 72-bit design. Actual values may be
    -- different. Actual parameters values are passed from design top module
    -- mig_31 module. Please refer to the mig_31 module for actual
    -- values.
    BURST_LENGTH : integer := 4;
    CLK_FREQ     : integer := 300;
    CQ_WIDTH     : integer := 2;
    DATA_WIDTH   : integer := 72;
    DEBUG_EN     : integer := 0;
    Q_PER_CQ_9   : integer := 4;
    Q_PER_CQ     : integer := 36
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
    stg1_cal_done_inst : out std_logic;
    stg2_cal_done_inst : out std_logic;
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
end ddrii_phy_dly_cal_sm;

architecture arch_ddrii_phy_dly_cal_sm of ddrii_phy_dly_cal_sm is

  constant PATTERN_A : std_logic_vector(8 downto 0) := "111111111";
  constant PATTERN_B : std_logic_vector(8 downto 0) := "000000000";
  constant PATTERN_C : std_logic_vector(8 downto 0) := "101010101";
  constant PATTERN_D : std_logic_vector(8 downto 0) := "010101010";

--  constant IDLE         : std_logic_vector(8 downto 0) := "000000001";  --01
--  constant CQ_TAP_INC   : std_logic_vector(8 downto 0) := "000000010";  --02
--  constant CQ_TAP_RST   : std_logic_vector(8 downto 0) := "000000100";  --04
--  constant Q_TAP_INC    : std_logic_vector(8 downto 0) := "000001000";  --08
--  constant Q_TAP_RST    : std_logic_vector(8 downto 0) := "000010000";  --10
--  constant CQ_Q_TAP_INC : std_logic_vector(8 downto 0) := "000100000";  --20
--  constant CQ_Q_TAP_DEC : std_logic_vector(8 downto 0) := "001000000";  --40
--  constant TAP_WAIT     : std_logic_vector(8 downto 0) := "010000000";  --80

  constant IDLE         : std_logic_vector(7 downto 0) := "00000001";  --01
  constant CQ_TAP_INC   : std_logic_vector(7 downto 0) := "00000010";  --02
  constant CQ_TAP_RST   : std_logic_vector(7 downto 0) := "00000100";  --04
  constant Q_TAP_INC    : std_logic_vector(7 downto 0) := "00001000";  --08
  constant Q_TAP_RST    : std_logic_vector(7 downto 0) := "00010000";  --10
  constant CQ_Q_TAP_INC : std_logic_vector(7 downto 0) := "00100000";  --20
  constant CQ_Q_TAP_DEC : std_logic_vector(7 downto 0) := "01000000";  --40
  constant TAP_WAIT     : std_logic_vector(7 downto 0) := "10000000";  --80
  constant DEBUG_ST     : std_logic_vector(7 downto 0) := "00000000";  --00

  constant COMP_1      : std_logic_vector(2 downto 0) := "001";  --001
  constant COMP_2      : std_logic_vector(2 downto 0) := "010";  --002
  constant CAL_DONE_ST : std_logic_vector(2 downto 0) := "100";  --004

  constant Q_ERROR_CHECK : std_logic_vector(3 downto 0) := "0001";  --001
  constant Q_ERROR_1     : std_logic_vector(3 downto 0) := "0010";  --002
  constant Q_ERROR_2     : std_logic_vector(3 downto 0) := "0100";  --004
  constant Q_ERROR_ST    : std_logic_vector(3 downto 0) := "1000";  --008

  constant half_period_taps    : integer := (1000000/(CLK_FREQ*150));

  signal max_window            : unsigned(5 downto 0);
  signal tap_wait_cnt          : unsigned(2 downto 0);
  signal q_tap_range           : unsigned(5 downto 0);
  signal cq_tap_cnt            : unsigned(5 downto 0);
  signal q_tap_cnt             : unsigned(5 downto 0);
  signal cq_tap_range          : unsigned(5 downto 0);
  signal cq_hold_range         : unsigned(5 downto 0);
  signal cq_setup_range        : unsigned(5 downto 0);
  signal cq_tap_range_center   : unsigned(5 downto 0);
  signal cq_tap_range_center_w : unsigned(5 downto 0);
  signal insuff_window_taps    : unsigned(5 downto 0);
  signal cq_final_tap_cnt      : unsigned(5 downto 0);
  signal cq_window_range       : unsigned(5 downto 0);
  signal tap_inc_val           : unsigned(5 downto 0);
  signal tap_inc_range         : unsigned(5 downto 0);
  signal rden_cnt_clk_0        : unsigned(3 downto 0);
  signal rd_stb_cnt            : unsigned(1 downto 0) := (others => '0');
  signal we_cal_cnt            : unsigned(2 downto 0);

  signal read_data_rise_r         : std_logic_vector(Q_PER_CQ-1 downto 0);
  signal read_data_fall_r         : std_logic_vector(Q_PER_CQ-1 downto 0);
  signal cal1_chk                 : std_logic;
  signal cal2_chk_1               : std_logic;
  signal cal2_chk_2               : std_logic;
  signal next_state               : std_logic_vector(7 downto 0);
  signal q_error_state            : std_logic_vector(3 downto 0);
  signal cal_begin                : std_logic;
  signal first_edge_detect        : std_logic;
  signal first_edge_detect_r      : std_logic;
  signal second_edge_detect       : std_logic;
  signal second_edge_detect_r     : std_logic;
  signal cq_q_detect_done         : std_logic;
  signal cq_q_detect_done_r       : std_logic;
  signal cq_q_detect_done_2r      : std_logic;
  signal dvw_detect_done          : std_logic;
  signal dvw_detect_done_r        : std_logic;
  signal insuff_window_detect     : std_logic;
  signal insuff_window_detect_r   : std_logic;
  signal stg2_cal_done_i          : std_logic;
  signal end_of_taps              : std_logic;
  signal tap_wait_en              : std_logic;
  signal cal_start_r              : std_logic;
  signal cal_start_2r             : std_logic;
  signal cal_start_3r             : std_logic;
  signal cal_start_4r             : std_logic;
  signal cal_start_5r             : std_logic;
  signal cal_start_6r             : std_logic;
  signal cal_start_7r             : std_logic;
  signal cal_start_8r             : std_logic;
  signal cal_start_9r             : std_logic;
  signal cal_start_10r            : std_logic;
  signal cal_start_11r            : std_logic;
  signal q_error                  : std_logic;
  signal q_initdelay_inc_done     : std_logic;
  signal q_initdelay_inc_done_r   : std_logic;
  signal stg1_cal_done_inst_i     : std_logic;
  signal cal1_error               : std_logic;
  signal stg1_cal_done_r          : std_logic;
  signal stg1_cal_done_2r         : std_logic;
  signal stg1_cal_done_3r         : std_logic;
  signal stg1_cal_done_4r         : std_logic;
  signal stg1_cal_done_5r         : std_logic;
  signal stg1_cal_done_6r         : std_logic;
  signal q_detect_chk             : std_logic;
  signal cnt_rst                  : std_logic;
  signal insuff_window_detect_p   : std_logic;
  signal q_dly_inc_i              : std_logic;
  signal q_dly_ce_i               : std_logic;
  signal q_dly_rst_i              : std_logic;
  signal cq_dly_ce_i              : std_logic;
  signal cq_dly_inc_i             : std_logic;
  signal cq_dly_rst_i             : std_logic;
  signal cq_initdelay_inc_done    : std_logic;
  signal cq_rst_done              : std_logic;
  signal q_rst_done               : std_logic;
  signal pat_a                    : std_logic_vector(Q_PER_CQ-1 downto 0);
  signal pat_b                    : std_logic_vector(Q_PER_CQ-1 downto 0);
  signal pat_c                    : std_logic_vector(Q_PER_CQ-1 downto 0);
  signal pat_d                    : std_logic_vector(Q_PER_CQ-1 downto 0);
  signal cq_initdelay_inc_done_r  : std_logic;
  signal stg1_cal_done_inst_r     : std_logic;
  signal q_initdelay_inc_done_2r  : std_logic;
  signal cq_initdelay_inc_done_2r : std_logic;
  signal stg1_cal_done_inst_2r    : std_logic;
  signal q_initdelay_done_p       : std_logic;
  signal cq_initdelay_done_p      : std_logic;
  signal q_inc_delay_done_p       : std_logic;
  signal rd_cmd                   : std_logic;
  signal comp_cs                  : std_logic_vector(2 downto 0);
  signal write_cal_start          : std_logic;
  signal rden_srl_clk_0           : std_logic;
  signal stg3_cal_done_i          : std_logic;
  signal data_valid_inst_i        : std_logic;
  signal stg3_cal_done_r          : std_logic;
  signal read_cmd_r               : std_logic;
  signal cq_inc_flag              : std_logic;
  signal q_inc_flag               : std_logic;
  signal reset_clk_0_r            : std_logic;
  signal reset_clk_0_r1           : std_logic;
  signal low_freq_min_window      : unsigned(5 downto 0);

begin

  -- Low frequency window for second stage: For clk_period > 4000ps
  -- if CQ/Q and CLK0 are less than 20 taps apart, insuff_window_detect is asserted.
  -- Then, for frequencies with half period more than 30 taps, CQ and Q are both delayed by a fixed 30 taps.
  -- Else they are both delayed by half period worth of taps so that they are both aligned to the next fpga clock edge
  -- if CQ/Q and CLK0 are more than 40 taps apart, they are then delayed such that CQ/Q are atleast (cq_tap_range/2) taps away from clk0

  low_freq_min_window <= "011110" when (half_period_taps > 30) else
                         TO_UNSIGNED(half_period_taps,6);

  dbg_q_tap_count  <= std_logic_vector(q_tap_cnt);
  dbg_cq_tap_count <= std_logic_vector(cq_tap_cnt);

  q_dly_inc  <= q_dly_inc_i;
  q_dly_ce   <= q_dly_ce_i;
  q_dly_rst  <= q_dly_rst_i;
  cq_dly_ce  <= cq_dly_ce_i;
  cq_dly_inc <= cq_dly_inc_i;
  cq_dly_rst <= cq_dly_rst_i;

  max_window <= "001111" when CLK_FREQ > 250 else
                "010100";

  ASGN : for i in 0 to Q_PER_CQ_9-1 generate
    pat_a(((i+1)*9)-1 downto (9*i)) <= PATTERN_A;
    pat_b(((i+1)*9)-1 downto (9*i)) <= PATTERN_B;
    pat_c(((i+1)*9)-1 downto (9*i)) <= PATTERN_C;
    pat_d(((i+1)*9)-1 downto (9*i)) <= PATTERN_D;
  end generate ASGN;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      reset_clk_0_r1 <= reset_clk_0;
      reset_clk_0_r  <= reset_clk_0_r1;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        read_data_rise_r <= (others => '0');
        read_data_fall_r <= (others => '0');
      else
        read_data_rise_r <= read_data_rise;
        read_data_fall_r <= read_data_fall;
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if((cal_start_11r = '1') and (read_data_rise_r = pat_a) and (read_data_fall_r = pat_b)) then
        cal1_chk <= '1';
      else
        cal1_chk <= '0';
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      --if(reset_clk_0_r = '1') then
      --  cal1_error   <= '0';      els
      if(q_initdelay_inc_done = '1') then
        cal1_error   <= '0';
      --elsif(tap_wait_cnt = "101") then
      elsif(tap_wait_cnt = "110") then
        if(cal1_chk = '1') then
          cal1_error <= '0';
        else
          cal1_error <= '1';
        end if;
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        cal2_chk_1 <= '0';
      elsif ((cal_start_11r = '1') and (read_data_rise_r = pat_a) and (read_data_fall_r = pat_b)) then
        cal2_chk_1 <= '1';
      else
        cal2_chk_1 <= '0';
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        cal2_chk_2 <= '0';
      elsif ((cal_start_11r = '1') and (read_data_rise_r = pat_c) and (read_data_fall_r = pat_d)) then
        cal2_chk_2 <= '1';
      else
        cal2_chk_2 <= '0';
      end if;
    end if;
  end process;

  stg1_cal_done_inst <= stg1_cal_done_inst_i;
  stg2_cal_done_inst <= stg2_cal_done_i;

  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if (reset_clk_0_r = '1') then
        q_error       <= '0';
        q_error_state <= Q_ERROR_CHECK;
      else
        case(q_error_state) is
          when Q_ERROR_CHECK =>
            --if (stg1_cal_done_6r = '1' and tap_wait_cnt = "101") then
            if (stg1_cal_done_6r = '1' and tap_wait_cnt = "110") then
              if (cal2_chk_1 = '1') then
                q_error       <= '0';
                q_error_state <= Q_ERROR_1;
              elsif (cal2_chk_2 = '1') then
                q_error       <= '0';
                q_error_state <= Q_ERROR_2;
              else
                q_error       <= '1';
                q_error_state <= Q_ERROR_ST;
              end if;
            else
              q_error       <= q_error;
              q_error_state <= Q_ERROR_CHECK;
            end if;

          when Q_ERROR_1 =>
            if (cal2_chk_2 = '1') then
              q_error <= '0';
            else
              q_error <= '1';
            end if;
          q_error_state <= Q_ERROR_CHECK;

          when Q_ERROR_2 =>
            if (cal2_chk_1 = '1') then
              q_error <= '0';
            else
              q_error <= '1';
            end if;
          q_error_state <= Q_ERROR_CHECK;

          when Q_ERROR_ST =>
            q_error       <= '1';
            q_error_state <= Q_ERROR_CHECK;

          when others =>
            q_error       <= '0';
            q_error_state <= Q_ERROR_CHECK;

        end case;
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        cal_start_r   <= '0';
        cal_start_2r  <= '0';
        cal_start_3r  <= '0';
        cal_start_4r  <= '0';
        cal_start_5r  <= '0';
        cal_start_6r  <= '0';
        cal_start_7r  <= '0';
        cal_start_8r  <= '0';
        cal_start_9r  <= '0';
        cal_start_10r <= '0';
        cal_start_11r <= '0';
      else
        cal_start_r   <= cal_start;
        cal_start_2r  <= cal_start_r;
        cal_start_3r  <= cal_start_2r;
        cal_start_4r  <= cal_start_3r;
        cal_start_5r  <= cal_start_4r;
        cal_start_6r  <= cal_start_5r;
        cal_start_7r  <= cal_start_6r;
        cal_start_8r  <= cal_start_7r;
        cal_start_9r  <= cal_start_8r;
        cal_start_10r <= cal_start_9r;
        cal_start_11r <= cal_start_10r;
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        stg1_cal_done_r  <= '0';
        stg1_cal_done_2r <= '0';
        stg1_cal_done_3r <= '0';
        stg1_cal_done_4r <= '0';
        stg1_cal_done_5r <= '0';
        stg1_cal_done_6r <= '0';
      else
        stg1_cal_done_r  <= stg1_cal_done;
        stg1_cal_done_2r <= stg1_cal_done_r;
        stg1_cal_done_3r <= stg1_cal_done_2r;
        stg1_cal_done_4r <= stg1_cal_done_3r;
        stg1_cal_done_5r <= stg1_cal_done_4r;
        stg1_cal_done_6r <= stg1_cal_done_5r;
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        cal_begin <= '0';
      elsif((cal_start_10r = '1') and (cal_start_11r = '0')) then
        cal_begin <= '1';
      elsif(q_dly_inc_i = '1') then
        cal_begin <= '0';
      end if;
    end if;
  end process;


--------------------------------------------------------------------------------
-- 1. CQ-Q calibration
--
-- This stage is required since cq is delayed by an amount equal to the bufio
-- delay with respect to the data. This might move CQ towards the end of the
-- data window at higher frequencies. This stage of calibration helps to align
-- data within the CQ window. In this stage, a static data pattern of 1s and 0s
-- are written as rise and fall data respectively. This pattern also helps to
-- eliminate any metastability arising due to the phase alignment of the
-- data output from the ISERDES and the FPGA clock.
-- The stages of this calibration are as follows:
-- 1. Increment the cq taps to determine the hold data window.
-- 2. Reset the CQ taps once the end of window is reached or sufficient window
--    not detected.
-- 3. Increment Q taps to determine the set up window.
-- 4. Reset the q taps.
-- 5. If the hold window detected is greater than the set up window, then no
--    tap increments needed. If the hold window is less than the setup window,
--    data taps are incremented so that CQ is in the center of the
--    data valid window.
--
-- 2. CQ-Q to FPGA clk calibration
--
-- This stage helps to determine the relationship between cq/q with respect to
-- the fpga clk.
-- 1. CQ and Q are incremented and the window detected with respect to the
--    FPGA clk. If there is insufficient window , CQ/Q are both incremented
--    so that they can be aligned to the next rising edge of the FPGA clk.
-- 2. Once sufficient window is detected, CQ and Q are decremented such that
--    they are atleast half the clock period away from the FPGA clock in case of
--    frequencies lower than or equal to 250 MHz and atleast 20 taps away from
--    the FPGA clock for frequencies higher than 250 MHz.
--------------------------------------------------------------------------------

  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if((reset_clk_0_r = '1') or (cal_start = '0')) then
        cq_dly_inc_i <= '0';
        cq_dly_ce_i  <= '0';
        cq_dly_rst_i <= '1';
        q_dly_inc_i  <= '0';
        q_dly_ce_i   <= '0';
        q_dly_rst_i  <= '1';
        tap_wait_en  <= '0';
        next_state   <= IDLE;
      else
        case(next_state) is
          when IDLE =>
            cq_dly_inc_i <= '0';
            cq_dly_ce_i  <= '0';
            cq_dly_rst_i <= '0';
            q_dly_inc_i  <= '0';
            q_dly_ce_i   <= '0';
            q_dly_rst_i  <= '0';
            tap_wait_en  <= '0';

            --if((cal_begin = '1') and (cq_initdelay_inc_done = '0')) then
            if(((cal_begin = '1') and (cq_initdelay_inc_done = '0')) or
               ((q_rst_done = '1') and (cq_inc_flag = '1') and
                (stg1_cal_done_inst_i = '0'))) then
              next_state <= CQ_TAP_INC;
            elsif((cq_initdelay_inc_done_r = '1') and (cq_rst_done = '0')) then
              next_state <= CQ_TAP_RST;
            elsif(((cq_rst_done = '1') and (q_initdelay_inc_done = '0')) or
                  --((q_rst_done = '1') and (stg1_cal_done_inst_i = '0'))) then
                  ((q_rst_done = '1') and (q_inc_flag = '1') and
                   (stg1_cal_done_inst_i = '0'))) then
              next_state <= Q_TAP_INC;
            elsif((q_initdelay_inc_done_r = '1') and (q_rst_done = '0')) then
              next_state <= Q_TAP_RST;
            elsif((stg1_cal_done_6r = '1') and (cq_q_detect_done = '0')) then
              next_state <= CQ_Q_TAP_INC;
            elsif((cq_q_detect_done_2r = '1') and (stg2_cal_done_i = '0')) then
              next_state <= CQ_Q_TAP_DEC;
            --------------------------------------------------------------------
            -- Debug signals state. When DEBUG_EN = 1, then the state machine
            -- enters in to DEBUG_ST. User can increment/decrement Q, CQ/CQ# taps
            -- inorder to delays these signals at IDLEAY elements. Even when the
            -- calibration fails due to some reason, when DEBUG_EN = 1,
            -- state machine always remains in the DEBUG_ST allowing user to
            -- increment/decrement the tap values of above mentioned signals.
            --------------------------------------------------------------------
            elsif((cal_start_11r = '1') and (DEBUG_EN = 1)) then
              if(dbg_sel_idel_q_cq = '1') then
                q_dly_inc_i <= dbg_idel_up_q;
                q_dly_ce_i  <= dbg_idel_up_q or dbg_idel_down_q;
              else
                q_dly_ce_i  <= '0';
              end if;

              if(dbg_sel_idel_cq = '1') then
                cq_dly_inc_i <= dbg_idel_up_cq;
                cq_dly_ce_i  <= dbg_idel_up_cq or dbg_idel_down_cq;
              else
                cq_dly_ce_i  <= '0';
              end if;

              next_state <= DEBUG_ST;
            else
              next_state <= IDLE;
            end if;

          when CQ_TAP_INC =>
            cq_dly_inc_i <= '1';
            cq_dly_ce_i  <= '1';
            cq_dly_rst_i <= '0';
            q_dly_inc_i  <= '0';
            q_dly_ce_i   <= '0';
            q_dly_rst_i  <= '0';
            tap_wait_en  <= '1';
            next_state   <= TAP_WAIT;

          when CQ_TAP_RST =>
            cq_dly_inc_i <= '0';
            cq_dly_ce_i  <= '0';
            cq_dly_rst_i <= '1';
            q_dly_inc_i  <= '0';
            q_dly_ce_i   <= '0';
            q_dly_rst_i  <= '0';
            tap_wait_en  <= '1';
            next_state   <= TAP_WAIT;

          when Q_TAP_INC =>
            cq_dly_inc_i <= '0';
            cq_dly_ce_i  <= '0';
            cq_dly_rst_i <= '0';
            q_dly_inc_i  <= '1';
            q_dly_ce_i   <= '1';
            q_dly_rst_i  <= '0';
            tap_wait_en  <= '1';
            next_state   <= TAP_WAIT;

          when Q_TAP_RST =>
            cq_dly_inc_i <= '0';
            cq_dly_ce_i  <= '0';
            cq_dly_rst_i <= '0';
            q_dly_inc_i  <= '0';
            q_dly_ce_i   <= '0';
            q_dly_rst_i  <= '1';
            tap_wait_en  <= '1';
            next_state   <= TAP_WAIT;

          when CQ_Q_TAP_INC =>
            cq_dly_inc_i <= '1';
            cq_dly_ce_i  <= '1';
            cq_dly_rst_i <= '0';
            q_dly_inc_i  <= '1';
            q_dly_ce_i   <= '1';
            q_dly_rst_i  <= '0';
            tap_wait_en  <= '1';
            next_state   <= TAP_WAIT;

          when CQ_Q_TAP_DEC =>
            cq_dly_inc_i <= '0';
            cq_dly_ce_i  <= '1';
            cq_dly_rst_i <= '0';
            q_dly_inc_i  <= '0';
            q_dly_ce_i   <= '1';
            q_dly_rst_i  <= '0';
            tap_wait_en  <= '1';
            next_state   <= TAP_WAIT;

          when TAP_WAIT =>
            cq_dly_inc_i <= '0';
            cq_dly_ce_i  <= '0';
            cq_dly_rst_i <= '0';
            q_dly_inc_i  <= '0';
            q_dly_ce_i   <= '0';
            q_dly_rst_i  <= '0';
            tap_wait_en  <= '0';

            if (tap_wait_cnt = "111") then
              next_state <= IDLE;
            else
              next_state <= TAP_WAIT;
            end if;

         when DEBUG_ST =>
           cq_dly_inc_i <= '0';
           cq_dly_ce_i  <= '0';
           cq_dly_rst_i <= '0';
           q_dly_inc_i  <= '0';
           q_dly_ce_i   <= '0';
           q_dly_rst_i  <= '0';
           tap_wait_en  <= '1';

           if(dbg_sel_idel_q_cq = '1') then
             q_dly_inc_i <= dbg_idel_up_q;
             q_dly_ce_i  <= dbg_idel_up_q or dbg_idel_down_q;
           else
             q_dly_ce_i  <= '0';
           end if;

           if(dbg_sel_idel_cq = '1') then
             cq_dly_inc_i <= dbg_idel_up_cq;
             cq_dly_ce_i  <= dbg_idel_up_cq or dbg_idel_down_cq;
           else
             cq_dly_ce_i  <= '0';
           end if;

           if((dbg_sel_idel_q_cq = '0') and (dbg_sel_idel_cq = '0')) then
             next_state <= IDLE;
           else
             next_state <= DEBUG_ST;
           end if;

          when others =>
            next_state <= IDLE;

        end case;
      end if;
    end if;
  end process;

  cnt_rst <= reset_clk_0_r or insuff_window_detect_p or q_initdelay_done_p or
             cq_initdelay_done_p or q_inc_delay_done_p;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(cnt_rst = '1') then
        first_edge_detect <= '0';
      elsif(((q_error = '0') and (cal1_error = '0')) and
            (tap_wait_cnt = "111")) then
        first_edge_detect <= '1';
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(cnt_rst = '1') then
        second_edge_detect <= '0';
      elsif((first_edge_detect = '1') and ((q_error = '1') or (cal1_error = '1')
                                           or (end_of_taps = '1'))) then
        second_edge_detect <= '1';
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(cnt_rst = '1') then
        first_edge_detect_r  <= '0';
        second_edge_detect_r <= '0';
      else
        first_edge_detect_r  <= first_edge_detect;
        second_edge_detect_r <= second_edge_detect;
      end if;
    end if;
  end process;

  q_detect_chk <= '1' when ((q_rst_done = '1') and (stg1_cal_done_6r = '0')) else
                  '0';

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(cnt_rst = '1') then
        dvw_detect_done <= '0';
      elsif((second_edge_detect_r = '1') and (insuff_window_detect = '0')
            and (q_detect_chk = '0')) then
        dvw_detect_done <= '1';
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(cnt_rst = '1') then
        dvw_detect_done_r <= '0';
      else
        dvw_detect_done_r <= dvw_detect_done;
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if((reset_clk_0_r = '1') or (cq_dly_rst_i = '1')) then
        cq_tap_cnt <= (others => '0');
      elsif((cq_dly_ce_i = '1') and (cq_dly_inc_i = '1')) then
        cq_tap_cnt <= cq_tap_cnt + 1;
      elsif((cq_dly_ce_i = '1') and (cq_dly_inc_i = '0')) then
        cq_tap_cnt <= cq_tap_cnt - 1;
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if((reset_clk_0_r = '1') or (q_dly_rst_i = '1')) then
        q_tap_cnt <= (others => '0');
      elsif((q_dly_ce_i = '1') and (q_dly_inc_i = '1')) then
        q_tap_cnt <= q_tap_cnt + 1;
      elsif((q_dly_ce_i = '1') and (q_dly_inc_i = '0')) then
        q_tap_cnt <= q_tap_cnt - 1;
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        tap_wait_cnt <= "000";
      elsif((tap_wait_cnt /= "000") or (tap_wait_en = '1')) then
        tap_wait_cnt <= tap_wait_cnt + 1;
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(cnt_rst = '1') then
        cq_tap_range <= (others => '0');
      elsif((cq_dly_inc_i = '1') and (first_edge_detect = '1')) then
        cq_tap_range <= cq_tap_range + 1;
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(cnt_rst = '1') then
        q_tap_range <= (others => '0');
      elsif((q_dly_inc_i = '1') and (first_edge_detect = '1')) then
        q_tap_range <= q_tap_range + 1;
      end if;
    end if;
  end process;

--------------------------------------------------------------------------------
-- 1st stage calibration registers
--------------------------------------------------------------------------------

-- either end of window reached or no window detected
  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        cq_initdelay_inc_done <= '0';
      elsif (((cq_initdelay_inc_done = '0') and (dvw_detect_done = '1') and
              (dvw_detect_done_r = '0')) or ((cq_tap_cnt = "000101") and
                                             (first_edge_detect = '0'))) then
        cq_initdelay_inc_done <= '1';
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        q_initdelay_inc_done <= '0';
      elsif ((cq_initdelay_inc_done = '1') and (q_initdelay_inc_done = '0') and
             (dvw_detect_done = '1') and (dvw_detect_done_r = '0') and
             (q_tap_range >= "000101")) then
        q_initdelay_inc_done <= '1';
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        cq_rst_done <= '0';
      elsif ((cq_initdelay_inc_done = '1') and (cq_dly_rst_i = '1')) then
        cq_rst_done <= '1';
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        q_rst_done <= '0';
      elsif ((q_initdelay_inc_done = '1') and (q_dly_rst_i = '1')) then
        q_rst_done <= '1';
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        cq_hold_range <= (others => '0');
      elsif ((cq_initdelay_inc_done = '0') and (cq_dly_inc_i = '1') and
             (first_edge_detect = '1') ) then
        cq_hold_range <= cq_hold_range + 1;
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        cq_setup_range <= (others => '0');
      elsif ((q_initdelay_inc_done = '0') and (q_dly_inc_i = '1') and
             (first_edge_detect = '1') ) then
        cq_setup_range <= cq_setup_range +1;
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        q_initdelay_inc_done_r   <= '0';
        cq_initdelay_inc_done_r  <= '0';
        stg1_cal_done_inst_r     <= '0';
        q_initdelay_inc_done_2r  <= '0';
        cq_initdelay_inc_done_2r <= '0';
        stg1_cal_done_inst_2r    <= '0';
      else
        q_initdelay_inc_done_r   <= q_initdelay_inc_done;
        cq_initdelay_inc_done_r  <= cq_initdelay_inc_done;
        stg1_cal_done_inst_r     <= stg1_cal_done_inst_i;
        q_initdelay_inc_done_2r  <= q_initdelay_inc_done_r;
        cq_initdelay_inc_done_2r <= cq_initdelay_inc_done_r;
        stg1_cal_done_inst_2r    <= stg1_cal_done_inst_r;
      end if;
    end if;
  end process;

  q_initdelay_done_p  <= '1' when ((q_initdelay_inc_done_r = '1') and
                                   (q_initdelay_inc_done_2r = '0')) else '0';
  cq_initdelay_done_p <= '1' when ((cq_initdelay_inc_done_r = '1') and
                                   (cq_initdelay_inc_done_2r = '0')) else '0';
  q_inc_delay_done_p  <= '1' when ((stg1_cal_done_inst_r = '1') and
                                   (stg1_cal_done_inst_2r = '0')) else '0';

  cq_window_range <= (cq_setup_range - cq_hold_range) when (cq_setup_range > cq_hold_range)
                                                      else
                     (cq_hold_range - cq_setup_range);

  --  tap_inc_val <= ('0' & cq_window_range(5 downto 1)) when
  --                 ((q_initdelay_inc_done_r = '1') and
  --                  (cq_setup_range > cq_hold_range)) else
  --                 "000000";

  tap_inc_val <= ('0' & cq_window_range(5 downto 1)) when (q_initdelay_inc_done_r = '1')
                                                     else
                 "000000";

  cq_inc_flag <= '1' when ((q_initdelay_inc_done = '1') and
                           (cq_hold_range  > cq_setup_range)) else
                 '0';

  q_inc_flag  <= '1' when ((q_initdelay_inc_done = '1') and
                           (cq_setup_range >= cq_hold_range)) else
                 '0';


  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        tap_inc_range <= (others => '0');
      else
        tap_inc_range <= tap_inc_val;
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        stg1_cal_done_inst_i <= '0';
      --elsif ((q_rst_done = '1') and (stg1_cal_done_inst_i = '0') and
      --       (q_tap_cnt = tap_inc_range)) then
        elsif ((q_rst_done = '1') and (stg1_cal_done_inst_i = '0') and
               (((cq_inc_flag = '1') and (cq_tap_cnt = tap_inc_range)) or
                ((q_inc_flag = '1') and (q_tap_cnt = tap_inc_range)))) then
        stg1_cal_done_inst_i <= '1';
      end if;
    end if;
  end process;

--------------------------------------------------------------------------------
-- 2nd stage calibration registers
--------------------------------------------------------------------------------

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        cq_q_detect_done <= '0';
      elsif((stg1_cal_done_6r = '1') and (dvw_detect_done = '1') and
            (dvw_detect_done_r = '0')) then
        cq_q_detect_done <= '1';
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        cq_q_detect_done_r  <= '0';
        cq_q_detect_done_2r <= '0';
      else
        cq_q_detect_done_r  <= cq_q_detect_done;
        cq_q_detect_done_2r <= cq_q_detect_done_r;
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(cnt_rst = '1') then
        insuff_window_detect <= '0';
      elsif((stg1_cal_done_6r = '1') and (second_edge_detect = '1') and
            (cq_tap_range < max_window)) then
        insuff_window_detect <= '1';
      elsif((insuff_window_detect = '1') and (first_edge_detect_r = '1')) then
        insuff_window_detect <= '0';
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        insuff_window_detect_r  <= '0';
      else
        insuff_window_detect_r  <= insuff_window_detect;
      end if;
    end if;
  end process;

  insuff_window_detect_p <= '1' when ((insuff_window_detect = '1') and
                                      (insuff_window_detect_r = '0')) else
                            '0';

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        insuff_window_taps <= (others => '0');
      elsif ((insuff_window_detect = '1') and (insuff_window_detect_r = '0'))then
        insuff_window_taps <= cq_tap_cnt;
      end if;
    end if;
  end process;

  --cq_tap_range_center_w <= "000000" when (cq_tap_range < max_window) else
  --                         (cq_tap_range - max_window) when
  --                         (cq_tap_range < (2 * max_window)) else
  --                         ('0' & cq_tap_range(5 downto 1));

  cq_tap_range_center_w <= "000000" when (cq_tap_range < max_window) else
                           low_freq_min_window when ((cq_tap_range < (2 * max_window)) and (CLK_FREQ < 250) and (insuff_window_taps > 0) ) else
                           (cq_tap_range - max_window) when (cq_tap_range < 2 * max_window) else
                           ('0' & cq_tap_range(5 downto 1));

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        cq_tap_range_center <= (others => '0');
        cq_final_tap_cnt    <= (others => '0');
      else
        cq_tap_range_center <= cq_tap_range_center_w;
        cq_final_tap_cnt    <= insuff_window_taps + cq_tap_range_center;
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(cnt_rst = '1') then
        end_of_taps <= '0';
      elsif(cq_tap_cnt = "110000") then
        end_of_taps <= '1';
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        stg2_cal_done_i <= '0';
      elsif((cq_tap_cnt = cq_final_tap_cnt) and (cq_q_detect_done = '1')) then
        stg2_cal_done_i <= '1';
      end if;
    end if;
  end process;

--------------------------------------------------------------------------------
-- Third stage calibration statemachine.
-- Intermittent reads are issued to the same address. This stage of calibration
-- is used to align the read valid signal to the read data. The read valid
-- signal is generated from the read command by registering the command using a
-- shift register using SRL16. 'rden_cnt_clk_0' is used to determine the number
-- of stages the read command needed to be registered to align with the read
-- data.
--------------------------------------------------------------------------------
  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        stg3_cal_done_i <= '0';
        comp_cs       <= COMP_1;
      else
        case(comp_cs) is
          when COMP_1 =>
            if((data_valid_inst_i = '1') and (write_cal_start = '1')) then
              if (cal2_chk_1 = '1') then
                stg3_cal_done_i <= '0';
                comp_cs       <= COMP_2;
              else
                stg3_cal_done_i <= '0';
                comp_cs       <= COMP_1;
              end if;
            else
              stg3_cal_done_i <= '0';
              comp_cs       <= COMP_1;
            end if;

          when COMP_2 =>
            if (cal2_chk_2 = '1') then
              stg3_cal_done_i <= '1';
              comp_cs       <= CAL_DONE_ST;
            else
              stg3_cal_done_i <= '0';
              comp_cs       <= COMP_1;
            end if;

          when CAL_DONE_ST =>
            stg3_cal_done_i <= '1';
            comp_cs       <= CAL_DONE_ST;

          when others =>
            stg3_cal_done_i <= '0';
            comp_cs       <= COMP_1;
        end case;
      end if;
    end if;
  end process;

  stg3_cal_done_inst <= stg3_cal_done_i;

  BL4_INST : if(BURST_LENGTH = 4) generate
  -- For BL4 design, when a single read command is issued, 4 bursts of data is
  -- received. The same read command is expanded for two clock cycles and
  -- then the comparision of read data with pattern data is done in this
  -- particular two clock command window. Until the read data is matched with
  -- the pattern data, the two clock command window is shifted using SRL.
    process (clk_0)
    begin
      if(rising_edge(clk_0)) then
        if (reset_clk_0_r = '1') then
          rd_stb_cnt <= "00";
        elsif (read_cmd = '1') then
          rd_stb_cnt <= "10";
        elsif (rd_stb_cnt /= "00") then
          rd_stb_cnt <= rd_stb_cnt - 1;
        else
          rd_stb_cnt <= rd_stb_cnt;
        end if;
      end if;
    end process;

    process (clk_0)
    begin
      if(rising_edge(clk_0)) then
        if(reset_clk_0_r = '1') then
          rd_cmd <= '0';
        elsif(rd_stb_cnt /= "00") then
          rd_cmd <= '1';
        else
          rd_cmd <= '0';
        end if;
      end if;
    end process;
  end generate;

  BL2_INST : if(BURST_LENGTH = 2) generate

  -- For BL2 design, when two consecutive read commands are issued, 4 bursts
  -- of data is received. The read data is compared with pattern data in this
  -- particular two clock command window. Until the read data is matched with
  -- the pattern data, the two clock command window is shifted using SRL.
    process(clk_0)
    begin
      if(rising_edge(clk_0)) then
        if(reset_clk_0_r = '1') then
          rd_stb_cnt <= "00"; -- just driving to zeros, since it is no where
                              -- used for BL2 designs.
          rd_cmd <= '0';
        elsif(read_cmd = '1') then
          rd_cmd <= '1';
        else
          rd_cmd <= '0';
        end if;
      end if;
    end process;

    process(clk_0)
    begin
      if(rising_edge(clk_0)) then
        read_cmd_r <= not read_cmd;
      end if;
    end process;
  end generate;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        rden_cnt_clk_0 <= "0000";
      -- Increment count for SRL. This count determines the number of clocks
      -- two clock command window is delayed until the Read data is matched
      -- with pattern data.
      elsif((rd_stb_cnt = "01") and (write_cal_start = '1') and
            (stg3_cal_done_i = '0') and (BURST_LENGTH = 4)) then
        rden_cnt_clk_0 <= rden_cnt_clk_0 + 1;
      elsif((read_cmd = '1') and (read_cmd_r = '0') and (write_cal_start = '1') and
            (stg3_cal_done_i = '0') and (BURST_LENGTH = 2)) then
        rden_cnt_clk_0 <= rden_cnt_clk_0 + 1;
      elsif ((stg3_cal_done_i = '1') and (stg3_cal_done_r = '0')) then
        rden_cnt_clk_0 <= rden_cnt_clk_0 - 1;
      else
        rden_cnt_clk_0 <= rden_cnt_clk_0;
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        stg3_cal_done_r <= '0';
      else
        stg3_cal_done_r <= stg3_cal_done_i;
      end if;
    end if;
  end process;

  SRL_RDEN_CLK_0 : SRL16
    port map(
      Q   => rden_srl_clk_0,
      A0  => std_logic(rden_cnt_clk_0(0)),
      A1  => std_logic(rden_cnt_clk_0(1)),
      A2  => std_logic(rden_cnt_clk_0(2)),
      A3  => std_logic(rden_cnt_clk_0(3)),
      CLK => clk_0,
      D   => rd_cmd
      );

  WE_CLK_0_INST : FDRSE
    generic map (
      INIT => '0'
      )
    port map (
      Q  => data_valid_inst_i,
      C  => clk_0,
      CE => '1',
      D  => rden_srl_clk_0,
      R  => '0',
      S  => '0'
      );

  data_valid_inst <= data_valid_inst_i;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        we_cal_cnt <= "000";
      elsif((stg3_cal_start = '1') or (we_cal_cnt /= "000")) then
        we_cal_cnt <= we_cal_cnt + 1;
      else
        we_cal_cnt <= we_cal_cnt;
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0_r = '1') then
        write_cal_start <= '0';
      elsif(we_cal_cnt = "111") then
        write_cal_start <= '1';
      else
        write_cal_start <= write_cal_start;
      end if;
    end if;
  end process;

  srl_count <= std_logic_vector(rden_cnt_clk_0);

end arch_ddrii_phy_dly_cal_sm;