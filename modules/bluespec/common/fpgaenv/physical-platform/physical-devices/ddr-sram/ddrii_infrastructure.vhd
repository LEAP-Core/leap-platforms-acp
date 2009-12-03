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
--  /   /         Filename           : ddrii_infrastructure.vhd
-- /___/   /\     Timestamp          : 08 Apr 2008
-- \   \  /  \    Date Last Modified : $Date: 2009/03/23 16:11:01 $
--  \___\/\___\
--
--Device: Virtex-5
--Design: DDRII
--
--Purpose:
--    This module
--       1. Distributes various phases of the system clock
--       2. Generation and distribution of reset from the input clock.
--
--Revision History:
--   Rev 1.1 - Parameter CLK_TYPE added and logic for  DIFFERENTIAL and
--             SINGLE_ENDED added. SR. 6/20/08
--   Rev 1.2 - Loacalparam CLK_GENERATOR added and logic for clocks generation
--             using PLL or DCM added as generic code. PK. 10/14/08
--*****************************************************************************

library ieee;
library unisim;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;

entity ddrii_infrastructure is
  generic(
    -- Following parameters are for 72-bit design. Actual values may be
    -- different. Actual parameters values are passed from design top module
    -- mig_31 module. Please refer to the mig_31 module for actual
    -- values.
    RST_ACT_LOW : integer := 1
    );
  port(
    sys_rst_n         : in  std_logic;
    idelay_ctrl_ready : in  std_logic;
    locked            : in  std_logic;
    clk_0             : in  std_logic;
    clk_270           : in  std_logic;
    clk_200           : in  std_logic;
    clk_90            : out std_logic;
    reset_clk_0       : out std_logic;
    reset_clk_270     : out std_logic;
    reset_clk_200     : out std_logic
    );
end ddrii_infrastructure;

architecture arch_ddrii_infrastructure of ddrii_infrastructure is

  -- # of clock cycles to delay deassertion of reset. Needs to be a fairly
  -- high number not so much for metastability protection, but to give time
  -- for reset (i.e. stable clock cycles) to propagate through all state
  -- machines and to all control signals (i.e. not all control signals have
  -- resets, instead they rely on base state logic being reset, and the effect
  -- of that reset propagating through the logic). Need this because we may not
  -- be getting stable clock cycles while reset asserted (i.e. since reset
  -- depends on PLL/DCM lock status)
  constant RST_SYNC_NUM : integer range 10 to 30 := 25;

  signal rst0_sync_r   : std_logic_vector(RST_SYNC_NUM-1 downto 0);
  signal rst270_sync_r : std_logic_vector(RST_SYNC_NUM-1 downto 0);
  signal rst200_sync_r : std_logic_vector(RST_SYNC_NUM-1 downto 0);
  signal user_reset_in : std_logic;
  signal rst_tmp       : std_logic;
  signal clk0_i        : std_logic;
  signal clk270_i      : std_logic;
  signal clk200_i      : std_logic;

  attribute syn_maxfan : integer;
  attribute max_fanout : integer;
  attribute buffer_type : string;
  attribute syn_maxfan of rst0_sync_r : signal is 10;
  attribute max_fanout of rst0_sync_r : signal is 10;
  attribute buffer_type of rst0_sync_r : signal is "none";
  attribute syn_maxfan of rst270_sync_r : signal is 10;
  attribute max_fanout of rst270_sync_r : signal is 10;
  attribute syn_maxfan of rst200_sync_r : signal is 10;
  attribute max_fanout of rst200_sync_r : signal is 10;

  begin

  clk0_i   <= clk_0;
  clk_90   <= not clk_270;
  clk270_i <= clk_270;
  clk200_i <= clk_200;

  user_reset_in <= not(sys_rst_n) when (RST_ACT_LOW = 1) else sys_rst_n;

  rst_tmp <= (not(locked)) or (not(idelay_ctrl_ready)) or user_reset_in;

  process(clk0_i, rst_tmp)
  begin
    if(rst_tmp = '1') then
      rst0_sync_r <= (others => '1');
    elsif(rising_edge(clk0_i)) then
      rst0_sync_r <= (rst0_sync_r(RST_SYNC_NUM-2 downto 0) & '0');
    end if;
  end process;

  process(clk270_i, rst_tmp)
  begin
    if(rst_tmp = '1') then
      rst270_sync_r <= (others => '1');
    elsif(rising_edge(clk270_i)) then
      rst270_sync_r <= (rst270_sync_r(RST_SYNC_NUM-2 downto 0) & '0');
    end if;
  end process;

  process(clk200_i, locked)
  begin
    if(locked = '0') then
      rst200_sync_r <= (others => '1');
    elsif(rising_edge(clk200_i)) then
      rst200_sync_r <= (rst200_sync_r(RST_SYNC_NUM-2 downto 0) & '0');
    end if;
  end process;

  reset_clk_0   <= rst0_sync_r(RST_SYNC_NUM-1);
  reset_clk_270 <= rst270_sync_r(RST_SYNC_NUM-1);
  reset_clk_200 <= rst200_sync_r(RST_SYNC_NUM-1);

end architecture arch_ddrii_infrastructure;
