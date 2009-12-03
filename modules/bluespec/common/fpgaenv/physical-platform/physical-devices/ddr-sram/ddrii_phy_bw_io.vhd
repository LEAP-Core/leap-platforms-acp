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
--  /   /         Filename           : ddrii_phy_bw_io.vhd
-- /___/   /\     Timestamp          : 08 Apr 2008
-- \   \  /  \    Date Last Modified : $Date: 2009/03/23 16:11:01 $
--  \___\/\___\
--
--Device: Virtex-5
--Design: DDRII
--
--Purpose:
--    This module
--      1. Is the I/O module of the DDR Byte Write control data, using ODDR
--         Flip flops.
--
--Revision History:
--
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity ddrii_phy_bw_io is
  generic
    (
    -- Following parameters are for 72-bit design. Actual values may be
    -- different. Actual parameters values are passed from design top module
    -- mig_31 module. Please refer to the mig_31 module for actual
    -- values.
    BW_WIDTH   : integer := 8
    );
  port (
    clk_0       : in  std_logic;
    bw_n_rise_r : in  std_logic_vector(BW_WIDTH-1 downto 0);
    bw_n_fall_r : in  std_logic_vector(BW_WIDTH-1 downto 0);
    ddrii_bw_n  : out std_logic_vector(BW_WIDTH-1 downto 0)
    );
end entity ddrii_phy_bw_io;

architecture arch_ddrii_phy_bw_io of ddrii_phy_bw_io is

  signal ddrii_bw_n_obuf : std_logic_vector(BW_WIDTH-1 downto 0);

begin
BW_ODDR_INST : for i in 0 to BW_WIDTH-1 generate

  ODDR_DDRII_BW : ODDR
    generic map (
      DDR_CLK_EDGE => "SAME_EDGE"
      )
    port map (
      Q  => ddrii_bw_n_obuf(i),
      C  => clk_0,
      CE => '1',
      D1 => bw_n_fall_r(i),
      D2 => bw_n_rise_r(i),
      R  => '0',
      S  => '0'
      );

  DDR_BW_OBUF : OBUF
    port map (
      I => ddrii_bw_n_obuf(i),
      O => ddrii_bw_n(i)
      );

end generate BW_ODDR_INST;

end architecture arch_ddrii_phy_bw_io;
