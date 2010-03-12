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
--  /   /         Filename           : ddrii_phy_init_sm.vhd
-- /___/   /\     Timestamp          : 08 Apr 2008
-- \   \  /  \    Date Last Modified : $Date: 2009/05/11 21:13:30 $
--  \___\/\___\
--
--Device: Virtex-5
--Design: DDRII
--
--Purpose:
--    This module
--  1. Is the initialization statemachine generating the Read and Write commands
--     and address to the memory until the delay calibration is complete.
--  2. Generates commands for all the three stage of calibration.
--
--Revision History:
--
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ddrii_phy_init_sm is
  generic(
    -- Following parameters are for 72-bit design. Actual values may be
    -- different. Actual parameters values are passed from design top module
    -- ddr2_sram module. Please refer to the ddr2_sram module for actual
    -- values.
    ADDR_WIDTH   : integer := 19;
    BURST_LENGTH : integer := 4;
    CLK_FREQ     : integer := 300;
    IO_TYPE      : string  := "CIO";
    SIM_ONLY     : integer := 0
    );
  port(
    clk_0           : in  std_logic; -- 0 degrees phase shifted clock from
                                     -- DCM.
    reset_clk_0     : in  std_logic; -- Reset signal derived in clk_0 domain.
    stg1_cal_done   : in  std_logic; -- Relation between read data and the
                                     -- corresponding delayed read clock
                                     -- (CQ) is found.
    stg2_cal_done   : in  std_logic; -- Read data is centre aligned with
                                     -- respect to FPGA clock (clk_0).
    stg3_cal_done   : in  std_logic; -- Read command is delayed for certain
                                     -- number of clocks such that the
                                     -- delayed read command is aligned
                                     -- with the corresponding read data.
    idly_ctrl_ready : in  std_logic; -- IDELAY element's ready signal.
    cal_start       : out std_logic; -- Start the calibration sequence
                                     -- (first and second stage).
    stg3_cal_start  : out std_logic; -- Start the third stage calibration.
                                     -- process.
    cal_ld_n        : out std_logic; -- Synchronous Active low load command
                                     -- during calibration process.
    cal_rw_n        : out std_logic; -- Read/Write control command during
                                     -- calibration process. Read when active HIGH
    cal_addr        : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    -- Memory address location for Read/Write operations during calibration process.
    cal_done        : out std_logic; -- Completion of three stages of calibration.
                                     -- Completon of calibration process.
    init_wait_done  : out std_logic -- Completion of 200 us period of wait
                                    -- time.
    );
end entity ddrii_phy_init_sm;

architecture arch_ddrii_phy_init_sm of ddrii_phy_init_sm is

  constant ONES : unsigned(10 downto 0) := (others => '1');

  constant INIT_WAIT_ST               : std_logic_vector(16 downto 0)
                                        := "00000000000000001";--1
  constant FIRST_STAGE_CAL_WR_ST      : std_logic_vector(16 downto 0)
                                        := "00000000000000010";--2
  constant FIRST_STAGE_CAL_RD_ST      : std_logic_vector(16 downto 0)
                                        := "00000000000000100";--4
  constant FIRST_STAGE_BURST_WAIT_ST  : std_logic_vector(16 downto 0)
                                        := "00000000000001000";--8
  constant FIRST_STAGE_CIO_WAIT_ST    : std_logic_vector(16 downto 0)
                                        := "00000000000010000";--10
  constant CAL_WAIT_ST                : std_logic_vector(16 downto 0)
                                        := "00000000000100000";--20
  constant SECOND_STAGE_CAL_WR_ST1    : std_logic_vector(16 downto 0)
                                        := "00000000001000000";--40
  constant SECOND_STAGE_CAL_WR_ST2    : std_logic_vector(16 downto 0)
                                        := "00000000010000000";--80
  constant SECOND_STAGE_CAL_RD_ST1    : std_logic_vector(16 downto 0)
                                        := "00000000100000000";--100
  constant SECOND_STAGE_CAL_RD_ST2    : std_logic_vector(16 downto 0)
                                        := "00000001000000000";--200
  constant SECOND_STAGE_BURST_WAIT_ST : std_logic_vector(16 downto 0)
                                        := "00000010000000000";--400
  constant SECOND_STAGE_CIO_WAIT_ST   : std_logic_vector(16 downto 0)
                                        := "00000100000000000";--800
  constant THIRD_STAGE_CAL_START_ST   : std_logic_vector(16 downto 0)
                                        := "00001000000000000";--1000
  constant THIRD_STAGE_CAL_RD_ST1     : std_logic_vector(16 downto 0)
                                        := "00010000000000000";--2000
  constant THIRD_STAGE_CAL_RD_ST2     : std_logic_vector(16 downto 0)
                                        := "00100000000000000";--4000
  constant THIRD_STAGE_CAL_RD_WAIT_ST : std_logic_vector(16 downto 0)
                                        := "01000000000000000";--8000
  constant CAL_DONE_ST                : std_logic_vector(16 downto 0)
                                        := "10000000000000000";--10000

  constant FIRST_STAGE_CAL_ADDR   : std_logic_vector(ADDR_WIDTH-1 downto 0)
                                    := (others => '0');
  constant SECOND_STAGE_CAL_ADDR1 : std_logic_vector(ADDR_WIDTH-1 downto 0)
                                    := (0=>'1',others=>'0');
  constant SECOND_STAGE_CAL_ADDR2 : std_logic_vector(ADDR_WIDTH-1 downto 0)
                                    := (1=>'1',others=>'0');

  signal cal_ld_n_i         : std_logic;
  signal cal_rw_n_i         : std_logic;
  signal cmd_wait_en        : std_logic;
  signal cmd_wait_en_r1     : std_logic;
  signal phy_init_ns        : std_logic_vector(16 downto 0);
  signal phy_init_cs        : std_logic_vector(16 downto 0);
  signal mem_dll_wait_cnt   : unsigned(10 downto 0);
  signal mem_dll_active     : std_logic;
  signal calib_done_r1      : std_logic;
  signal calib_done_2r      : std_logic;
  signal calib_done_3r      : std_logic;
  signal calib_done_4r      : std_logic;
  signal calib_done_5r      : std_logic;
  signal calib_done_6r      : std_logic;
  signal idly_ctrl_ready_r1 : std_logic;
  signal idly_ctrl_ready_2r : std_logic;
  signal init_count         : unsigned(7 downto 0);
  signal init_wait_done_i   : std_logic;
  signal stg3_cal_start_i   : std_logic;
  signal stg1_cal_done_r1   : std_logic;
  signal stg1_cal_done_r2   : std_logic;
  signal stg1_cal_done_r3   : std_logic;
  signal stg1_cal_done_r4   : std_logic;
  signal stg1_cal_done_r5   : std_logic;
  signal cmd_wait_cnt       : unsigned(3 downto 0);
  signal cmd_wait_done      : std_logic;
  signal cmd_wait_done_r1   : std_logic;
  signal init_max_count     : integer range 0 to 350;
  signal cal_start_i        : std_logic;

begin

  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0 = '1') then
        init_count <= (others => '0');
      elsif(init_count = X"C8") then
        init_count <= (others => '0');
      elsif(init_wait_done_i = '0') then
        init_count <= init_count + 1;
      else
        init_count <= init_count;
      end if;
    end if;
  end process;

  --init_max_count generates a 200 us counter based on init_count
  -- an init_max_count of X"C8" refers to a 200 us count
  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0 = '1') then
        if(SIM_ONLY = 1) then
          init_max_count <= CLK_FREQ;
        else
          init_max_count <= 0;
        end if;
      elsif((init_count = X"C8") and (init_wait_done_i = '0')) then
        init_max_count <= init_max_count + 1;
      else
        init_max_count <= init_max_count;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- Intimates the completion of 200 us wait period
  ------------------------------------------------------------------------------
  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0 = '1') then
        init_wait_done_i <= '0';
      elsif(init_max_count = CLK_FREQ) then
        init_wait_done_i <= '1';
      else
        init_wait_done_i <= init_wait_done_i;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- According to the memory intialization specifications, after 200 us wait
  -- period, DDRII_DLL_OFF_n signal should be asserted high and wait for 1024
  -- clock cycles before issuing any valid command (Read/Write).
  ------------------------------------------------------------------------------
  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0 = '1') then
        mem_dll_wait_cnt <= (others => '0');
      elsif((init_wait_done_i = '1') and (mem_dll_wait_cnt /= ONES)) then
        mem_dll_wait_cnt <= mem_dll_wait_cnt + 1;
      else
        mem_dll_wait_cnt <= mem_dll_wait_cnt;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  --Make sure CQ clock is established (1024 clocks) before starting calibration
  ------------------------------------------------------------------------------
  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0 = '1') then
        mem_dll_active <= '0';
      elsif(mem_dll_wait_cnt = ONES) then
        mem_dll_active <= '1';
      else
        mem_dll_active <= mem_dll_active;
      end if;
    end if;
  end process;

  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0 = '1') then
        idly_ctrl_ready_r1 <= '0';
        idly_ctrl_ready_2r <= '0';
      else
        idly_ctrl_ready_r1 <= idly_ctrl_ready;
        idly_ctrl_ready_2r <= idly_ctrl_ready_r1;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- Once the initialization period is complete, which includes 200 us wait
  -- period and 1024 clock cycles wait period, start the calibration sequence
  ------------------------------------------------------------------------------
  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0 = '1') then
        cal_start_i <= '0';
      elsif((mem_dll_active = '1') and (idly_ctrl_ready_2r = '1')) then
        cal_start_i <= '1';
      end if;
    end if;
  end process;

  cal_start <= cal_start_i;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      cmd_wait_en_r1 <= cmd_wait_en;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- A 16 clock period wait counter. This counter is loaded when ever there is a
  -- request (cmd_wait_en = 1, or for every read command in the thirst stage
  -- calibration). The counter is initilized only in one clock period whenever
  -- cmd_wait_en = 1. This counter is utilized in the third stage calibration,
  -- where each read command must be issued after certain period of time (time
  -- to process that particular read command). For CIO designs, this counter is
  -- utilized when ever a write command is issued. For CIO designs, write data
  -- is looped back in to the read data path (calibration logic) due to the
  -- presence of Tri_State IOB.
  ------------------------------------------------------------------------------
  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0 = '1') then
        cmd_wait_cnt <= (others => '0');
      elsif((cmd_wait_en = '1') and (cmd_wait_en_r1 = '0')) then
        cmd_wait_cnt <= (others => '1');
      elsif(cmd_wait_cnt = "0000") then
        cmd_wait_cnt <= cmd_wait_cnt;
      else
        cmd_wait_cnt <= cmd_wait_cnt - 1;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- A status signal is asserted high when ever the counter has wait for 16
  -- clocks wait period.
  ------------------------------------------------------------------------------
  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if((cmd_wait_cnt = "0000") and (cmd_wait_en_r1 = '1')) then
        cmd_wait_done <= '1';
      else
        cmd_wait_done <= '0';
      end if;
    end if;
  end process;

  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      cmd_wait_done_r1 <= cmd_wait_done;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- Calibration done status signal is asserted high only when the third stage
  -- calibration is complete and 16 clocks wait period is complete.
  ------------------------------------------------------------------------------
  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0 = '1') then
        calib_done_r1 <= '0';
      elsif((stg3_cal_done = '1') and (cmd_wait_done = '1')) then
        calib_done_r1 <= '1';
      else
        calib_done_r1 <= calib_done_r1;
      end if;
    end if;
  end process;

  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      calib_done_2r <= calib_done_r1;
      calib_done_3r <= calib_done_2r;
      calib_done_4r <= calib_done_3r;
      calib_done_5r <= calib_done_4r;
      calib_done_6r <= calib_done_5r;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- In order to have better timing results, calibration done signal is
  -- registered for 6 clocks before it is send to other modules
  ------------------------------------------------------------------------------
  cal_done <= calib_done_6r;

  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      stg1_cal_done_r1 <= stg1_cal_done;
      stg1_cal_done_r2 <= stg1_cal_done_r1;
      stg1_cal_done_r3 <= stg1_cal_done_r2;
      stg1_cal_done_r4 <= stg1_cal_done_r3;
      stg1_cal_done_r5 <= stg1_cal_done_r4;
    end if;
  end process;

  cal_ld_n <= cal_ld_n_i;
  cal_rw_n <= cal_rw_n_i;

  init_wait_done <= init_wait_done_i;

  ------------------------------------------------------------------------------
  -- Stage 3 calibration starts once the stage 2 calibration on all the existing
  -- Read data and Read clocks(CQ/CQ#) is complete.
  ------------------------------------------------------------------------------
  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0 = '1') then
        stg3_cal_start_i <= '0';
      elsif(stg2_cal_done = '1') then
        stg3_cal_start_i <= '1';
      else
        stg3_cal_start_i <= stg3_cal_start_i;
      end if;
    end if;
  end process;

  stg3_cal_start <= stg3_cal_start_i;

  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0 = '1') then
        phy_init_cs <= INIT_WAIT_ST;
      else
        phy_init_cs <= phy_init_ns;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- A mealy state machine to issue the read and write commands during the
  -- calibration process.
  ------------------------------------------------------------------------------
  process (phy_init_cs, mem_dll_active, idly_ctrl_ready_2r, stg1_cal_done_r1,
           stg1_cal_done_r5,cmd_wait_done,cmd_wait_done_r1,stg2_cal_done,
           calib_done_6r,stg3_cal_done)
  begin
    cal_ld_n_i  <= '1';
    cal_rw_n_i  <= '1';
    cal_addr    <= (others => '0');
    cmd_wait_en <= '0';

    case (phy_init_cs) is

      --------------------------------------------------------------------------
      -- Initilization Wait State. State machine waits for the initilization
      -- sequence to complete. Wait period includes 200 us wait time as well as
      -- 1024 clock cycles wait after DLL_OFF_n signal is asserted high.
      --------------------------------------------------------------------------
      when INIT_WAIT_ST =>
        cal_ld_n_i <= '1';
        cal_rw_n_i <= '1';
        cal_addr   <= (others => '0');
        if((mem_dll_active = '1') and (idly_ctrl_ready_2r = '1')) then
          phy_init_ns <= FIRST_STAGE_CAL_WR_ST;
        else
          phy_init_ns <= INIT_WAIT_ST;
        end if;

      --------------------------------------------------------------------------
      -- First Stage Calibration-Single Write command.
      -- For CIO memory parts, a read command is issued only a few clocks after
      -- the write command is issued.
      -- For SIO memory parts, write and read commands can be issued
      -- consecutively.
      --------------------------------------------------------------------------
      when FIRST_STAGE_CAL_WR_ST =>
        cal_ld_n_i <= '0';
        cal_rw_n_i <= '0';
        cal_addr   <= FIRST_STAGE_CAL_ADDR;
        if(IO_TYPE = "CIO") then
          phy_init_ns <= FIRST_STAGE_CIO_WAIT_ST;
        elsif(IO_TYPE = "SIO") then
          phy_init_ns <= FIRST_STAGE_CAL_RD_ST;
        end if;

      --------------------------------------------------------------------------
      -- For CIO controller designs, when a write command is issued, the write
      -- data is present on memory bus and even on the read path (calibration
      -- logic) due to the presence of tri-state buffer. To avoid this 16 clocks
      -- of wait period is maintained when ever there is a Read-followed by-Write
      -- condition arises. The 16 clocks wait period counter is started with
      -- cmd_wait_en asserted to '1'. Once the 16 clock wait period is done,
      -- (cmd_wait_done_r1 = 1), issue read commands
      --------------------------------------------------------------------------
      when FIRST_STAGE_CIO_WAIT_ST =>
        cal_ld_n_i  <= '1';
        cal_rw_n_i  <= '1';
        cal_addr    <= (others => '0');
        cmd_wait_en <= '1';
        if(cmd_wait_done_r1 = '1') then
          phy_init_ns <= FIRST_STAGE_CAL_RD_ST;
        else
          phy_init_ns <= FIRST_STAGE_CIO_WAIT_ST;
        end if;

      --------------------------------------------------------------------------
      -- First Stage Calibration- Continous Read commands until first stage
      -- calibration is complete.
      -- For BL4 read commands are issued on alternate clock.
      -- For BL2 read commands are issued on every clock.
      --------------------------------------------------------------------------
      when FIRST_STAGE_CAL_RD_ST =>
        cal_ld_n_i <= '0';
        cal_rw_n_i <= '1';
        cal_addr   <= FIRST_STAGE_CAL_ADDR;
        if(BURST_LENGTH = 2) then
          if(stg1_cal_done_r1 = '1') then
            if(IO_TYPE = "CIO") then
              phy_init_ns <= CAL_WAIT_ST;
            elsif(IO_TYPE = "SIO") then
              phy_init_ns <= SECOND_STAGE_CAL_WR_ST1;
            end if;
          else
            phy_init_ns <= FIRST_STAGE_CAL_RD_ST;
          end if;
        elsif(BURST_LENGTH = 4) then
          phy_init_ns <= FIRST_STAGE_BURST_WAIT_ST;
        end if;

      --------------------------------------------------------------------------
      -- For Burst Length 4 designs, commands are issued on every alternate
      -- clock.
      --------------------------------------------------------------------------
      when FIRST_STAGE_BURST_WAIT_ST =>
        cal_ld_n_i <= '1';
        cal_rw_n_i <= '1';
        cal_addr   <= (others => '0');
        if(stg1_cal_done_r1 = '1') then
          phy_init_ns <= CAL_WAIT_ST;
        else
          phy_init_ns <= FIRST_STAGE_CAL_RD_ST;
        end if;

      --------------------------------------------------------------------------
      -- For CIO components designs, bus turn-over period is always required.
      -- In a Write-followed by-Read scenario, a single clock of wait period is
      -- required between a Read and Write commands in order to associate for
      -- bus turn-over period. Depending on board skew, this bus turn-over period
      -- could be more than one clock period. Hence once First Stage calibration
      -- is complete, a period of 5 clocks (roughly) are waited before starting
      -- second stage calibration process.
      --------------------------------------------------------------------------
      when CAL_WAIT_ST =>
        cal_ld_n_i <= '1';
        cal_rw_n_i <= '1';
        cal_addr   <= (others => '0');
        if(stg1_cal_done_r5 = '1') then
          phy_init_ns <= SECOND_STAGE_CAL_WR_ST1;
        else
          phy_init_ns <= CAL_WAIT_ST;
        end if;

      --------------------------------------------------------------------------
      -- Second Stage Calibration-Write command
      -- For BL4 a single Write command is issued (Four Data Patterns, F-0-A-5).
      -- For BL2 two Write commands are issued (Four Data Patterns, F-0-A-5).
      --------------------------------------------------------------------------
      when SECOND_STAGE_CAL_WR_ST1 =>
         cal_ld_n_i <= '0';
         cal_rw_n_i <= '0';
         cal_addr   <= SECOND_STAGE_CAL_ADDR1;
        if(BURST_LENGTH = 2) then
          phy_init_ns <= SECOND_STAGE_CAL_WR_ST2;
        elsif(BURST_LENGTH = 4) then
          phy_init_ns <= SECOND_STAGE_CIO_WAIT_ST;
        end if;

      when SECOND_STAGE_CAL_WR_ST2 =>
         cal_ld_n_i <= '0';
         cal_rw_n_i <= '0';
         cal_addr   <= SECOND_STAGE_CAL_ADDR2;
        if(IO_TYPE = "CIO") then
          phy_init_ns  <= SECOND_STAGE_CIO_WAIT_ST;
        elsif(IO_TYPE = "SIO") then
          phy_init_ns  <= SECOND_STAGE_CAL_RD_ST1;
        end if;

      --------------------------------------------------------------------------
      -- For CIO controller designs, when a write command is issued, the write
      -- data is present on memory bus and even on the read path (calibration
      -- logic) due to the presence of tri-state buffer. To avoid this 16 clocks
      -- of wait period is maintained when ever there is a Read-followed by-Write
      -- condition arises. The 16 clocks wait period counter is started with
      -- cmd_wait_en asserted to '1'. Once the 16 clock wait period is done,
      -- (cmd_wait_done_r1 = 1), issue read commands
      --------------------------------------------------------------------------
      when SECOND_STAGE_CIO_WAIT_ST =>
        cal_ld_n_i  <= '1';
        cal_rw_n_i  <= '1';
        cal_addr    <= (others => '0');
        cmd_wait_en <= '1';
        if(cmd_wait_done_r1 = '1') then
          phy_init_ns <= SECOND_STAGE_CAL_RD_ST1;
        else
          phy_init_ns <= SECOND_STAGE_CIO_WAIT_ST;
        end if;

      --------------------------------------------------------------------------
      -- Second Stage Calibration-Continous Read Commands until Second stage
      -- calibration is complete.
      -- For BL4 read commands are issued on alternate clocks(Four Data Patterns
      -- for every read command, F-0-A-5).
      -- For BL2 read commands are issued on every clock(Four Data Patterns for
      -- every two read commands, F-0-A-5).
      --------------------------------------------------------------------------
      when SECOND_STAGE_CAL_RD_ST1 =>
        cal_ld_n_i <= '0';
        cal_rw_n_i <= '1';
        cal_addr   <= SECOND_STAGE_CAL_ADDR1;
         if(BURST_LENGTH = 2) then
           phy_init_ns <= SECOND_STAGE_CAL_RD_ST2;
         elsif(BURST_LENGTH = 4) then
           phy_init_ns <= SECOND_STAGE_BURST_WAIT_ST;
         end if;

      when SECOND_STAGE_CAL_RD_ST2 =>
        cal_ld_n_i <= '0';
        cal_rw_n_i <= '1';
        cal_addr   <= SECOND_STAGE_CAL_ADDR2;
        if(stg2_cal_done = '1') then
          phy_init_ns <= THIRD_STAGE_CAL_START_ST;
        else
          phy_init_ns <= SECOND_STAGE_CAL_RD_ST1;
        end if;

      --------------------------------------------------------------------------
       -- For Burst Length 4 designs, commands are issued on every alternate
       -- clock.
      --------------------------------------------------------------------------
      when SECOND_STAGE_BURST_WAIT_ST =>
        cal_ld_n_i <= '1';
        cal_rw_n_i <= '1';
        cal_addr   <= (others => '0');
        if(stg2_cal_done = '1') then
          phy_init_ns <= THIRD_STAGE_CAL_START_ST;
        else
          phy_init_ns <= SECOND_STAGE_CAL_RD_ST1;
        end if;

      --------------------------------------------------------------------------
      -- Third Stage Calibration-Read Enable Calibration start
      --------------------------------------------------------------------------
      when THIRD_STAGE_CAL_START_ST =>
        cal_ld_n_i  <= '1';
        cal_rw_n_i  <= '1';
        cal_addr    <= (others => '0');
        phy_init_ns <= THIRD_STAGE_CAL_RD_WAIT_ST;

      --------------------------------------------------------------------------
      -- Third Stage Calibration-Read commands until Third Stage Calibration
      -- is complete (stg3_cal_done = '1');
      -- For BL4 a single Read command for every cmd_wait_cnt=4'd0.
      -- For BL2, two consecutive Read commands for every cmd_wait_cnt=4'd0.
      --------------------------------------------------------------------------
      when THIRD_STAGE_CAL_RD_ST1 =>
        cal_ld_n_i  <= '0';
        cal_rw_n_i  <= '1';
        cal_addr    <= SECOND_STAGE_CAL_ADDR1;
        if(BURST_LENGTH = 2) then
          phy_init_ns <= THIRD_STAGE_CAL_RD_ST2;
        elsif(BURST_LENGTH = 4) then
          phy_init_ns <= THIRD_STAGE_CAL_RD_WAIT_ST;
        end if;

      when THIRD_STAGE_CAL_RD_ST2 =>
        cal_ld_n_i  <= '0';
        cal_rw_n_i  <= '1';
        cal_addr    <= SECOND_STAGE_CAL_ADDR2;
        phy_init_ns <= THIRD_STAGE_CAL_RD_WAIT_ST;

      --------------------------------------------------------------------------
      -- For the third stage calibration, a 16 clock wait period is maintained
      -- between every read command. This wait period is maintained in order to
      -- complete the calibration process for that particular read command.
      --------------------------------------------------------------------------
      when THIRD_STAGE_CAL_RD_WAIT_ST =>
        cal_ld_n_i  <= '1';
        cal_rw_n_i  <= '1';
        cal_addr    <= (others => '0');
        cmd_wait_en <= '1';
        if(calib_done_6r = '1') then
          phy_init_ns <= CAL_DONE_ST;
        elsif ((stg3_cal_done = '0') and (cmd_wait_done = '1') and
               (cmd_wait_done_r1 = '0')) then
          phy_init_ns <= THIRD_STAGE_CAL_RD_ST1;
        else
          phy_init_ns <= THIRD_STAGE_CAL_RD_WAIT_ST;
        end if;

      --------------------------------------------------------------------------
      -- Once the calibration is complete, state machine remains in this state.
      -- No more commands are issued further.
      --------------------------------------------------------------------------
      when CAL_DONE_ST =>
      cal_ld_n_i  <= '1';
      cal_rw_n_i  <= '1';
      cal_addr    <= (others => '0');
      phy_init_ns <= CAL_DONE_ST;

      when others =>
        cal_ld_n_i  <= '1';
        cal_rw_n_i  <= '1';
        cal_addr    <= (others => '0');
        phy_init_ns <= INIT_WAIT_ST;
    end case;
  end process;

  -- synthesis translate_off
  process(calib_done_6r)
  begin
    if(reset_clk_0 = '0') then
      if(rising_edge(calib_done_6r))then
        report "Calibration completed at time " & time'image(now);
      end if;
    end if;
  end process;
  -- synthesis translate_on

end architecture arch_ddrii_phy_init_sm;