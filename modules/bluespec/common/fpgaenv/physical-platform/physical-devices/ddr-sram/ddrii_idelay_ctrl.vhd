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
--  /   /         Filename           : ddrii_idelay_ctrl.vhd
-- /___/   /\     Timestamp          : 08 Apr 2008
-- \   \  /  \    Date Last Modified : $Date: 2009/05/11 21:13:29 $
--  \___\/\___\
--
--Device: Virtex-5
--Design: DDRII
--
--Purpose:
--    This module
--       1. instantiates IDELAYCTRL primitives to generate the IDELAY ready
--          signal. This uses the 200 MHz reference clock input.
--Revision History:
--   Rev 1.1 - Parameter IODELAY_GRP added and constraint IODELAY_GROUP added
--             on IOELAYCTRL primitive. Generate logic on IDELAYCTRL removed
--             since tools will replicate idelactrl primitives.PK. 11/27/08
--*****************************************************************************

library ieee;
library unisim;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;

entity ddrii_idelay_ctrl is
  generic(
    -- Following parameters are for 72-bit design. Actual values may be
    -- different. Actual parameters values are passed from design top module
    -- ddr2_sram module. Please refer to the ddr2_sram module for actual
    -- values.
    IODELAY_GRP    : string  := "IODELAY_MIG"
   );
  port(
   clk_200           : in  std_logic;
   reset_clk_200     : in  std_logic;
   idelay_ctrl_ready : out std_logic
   );
end entity ddrii_idelay_ctrl;

architecture arch_ddrii_idelay_ctrl of  ddrii_idelay_ctrl is

  attribute IODELAY_GROUP : string;
  attribute IODELAY_GROUP of U_IDELAYCTRL : label is IODELAY_GRP;

begin

  U_IDELAYCTRL : IDELAYCTRL
   port map (
     RDY    => idelay_ctrl_ready,
     REFCLK => clk_200,
     RST    => reset_clk_200
     );

end architecture arch_ddrii_idelay_ctrl;
