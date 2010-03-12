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
--  /   /         Filename           : ddrii_phy_cq_io.vhd
-- /___/   /\     Timestamp          : 08 Apr 2008
-- \   \  /  \    Date Last Modified : $Date: 2009/05/11 21:13:29 $
--  \___\/\___\
--
--Device: Virtex-5
--Design: DDRII
--
--Purpose:
--    This module
--      1. Is the I/O module for the incoming memory read clock (CQ/CQ#).
--      2. Instantiates the IDELAY to delay the clock and routes it through
--         BUFIO.
--
--Revision History:
--   Rev 1.1 - Parameter IODELAY_GRP added and constraint IODELAY_GROUP added
--             on IODELAY primitives. PK. 11/27/08
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity ddrii_phy_cq_io is
  generic
    (
    -- Following parameters are for 72-bit design. Actual values may be
    -- different. Actual parameters values are passed from design top module
    -- ddr2_sram module. Please refer to the ddr2_sram module for actual
    -- values.
    CQ_WIDTH              : integer := 2;
    HIGH_PERFORMANCE_MODE : boolean := TRUE;
    IODELAY_GRP           : string  := "IODELAY_MIG";
    MEMORY_WIDTH          : integer := 36
    );
  port(
    clk_0        : in  std_logic; -- 0 degree phase shifted clock from DCM.
    ddrii_cq     : in  std_logic_vector(CQ_WIDTH-1 downto 0); -- CQ signal from
                                                              -- memory
    ddrii_cq_n   : in  std_logic_vector(CQ_WIDTH-1 downto 0); -- CQ# signal from
                                                              -- memory
    cq_dly_ce    : in  std_logic_vector(CQ_WIDTH-1 downto 0);
    -- Enable signal for the IDELAY element used to delay CQ bits.
    cq_dly_inc   : in  std_logic_vector(CQ_WIDTH-1 downto 0);
    -- Increment/decrement signal for the IDELAY element used to delay CQ bits.
    cq_dly_rst   : in  std_logic_vector(CQ_WIDTH-1 downto 0);
    -- Reset signal for the IDELAY element used to delay CQ bits.
    cq_n_dly_ce  : in  std_logic_vector(CQ_WIDTH-1 downto 0);
    -- Enable signal for the IDELAY element used to delay CQ# bits.
    cq_n_dly_inc : in  std_logic_vector(CQ_WIDTH-1 downto 0);
    -- Increment/decrement signal for the IDELAY element used to delay CQ# bits.
    cq_n_dly_rst : in  std_logic_vector(CQ_WIDTH-1 downto 0);
    -- Reset signal for the IDELAY element used to delay CQ# bits.
    cq_bufio     : out std_logic_vector(CQ_WIDTH-1 downto 0);
    -- Delayed CQ signal from IDELAY element.
    cq_n_bufio   : out std_logic_vector(CQ_WIDTH-1 downto 0)
    -- Delayed CQ# signal from IDELAY element.
    );
end entity ddrii_phy_cq_io;

architecture arch_ddrii_phy_cq_io of ddrii_phy_cq_io is

  signal cq_ibuf      : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal cq_delay     : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal cq_bufio_w   : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal cq_n_ibuf    : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal cq_n_delay   : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal cq_n_bufio_w : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal unused_cq_n  : std_logic_vector(CQ_WIDTH-1 downto 0);

  attribute keep        : string;
  attribute syn_noprune : boolean;
  attribute syn_keep    : boolean;

  attribute keep of unused_cq_n : signal is "true";
  attribute syn_keep of unused_cq_n : signal is true;

  attribute IODELAY_GROUP : string;

begin

  ------------------------------------------------------------------------------
  -- In case of x36 memory designs, first 18 bits of read data, its
  -- corresponding CQ and second 18 bits of read data, its corresponding CQ#
  -- (cq_n) are being captured using FPGA clock separately.
  -- In case of x18/x9 memory designs, all the read data bits and only CQ are
  -- being captured using FPGA clock. CQ# port though present for these designs,
  -- are just tied to dummy logic.
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- CQ path inside the IOB
  ------------------------------------------------------------------------------
  CQ_INST : for cq_i in 0 to CQ_WIDTH-1 generate
    attribute IODELAY_GROUP of U_IODELAY_CQ : label is IODELAY_GRP;
  begin
    DDRII_CQ_IBUF : IBUF
      port map (
       I => ddrii_cq(cq_i),
       O => cq_ibuf(cq_i)
      );

    ----------------------------------------------------------------------------
    -- Delaying CQ bits with the appropriate delay values from the calibration
    -- module.
    ----------------------------------------------------------------------------
    U_IODELAY_CQ : IODELAY
      generic map(
        DELAY_SRC             => "I",
        IDELAY_TYPE           => "VARIABLE",
        HIGH_PERFORMANCE_MODE => HIGH_PERFORMANCE_MODE,
        IDELAY_VALUE          => 0,
        ODELAY_VALUE          => 0
        )
      port map(
        DATAOUT => cq_delay(cq_i),
        C       => clk_0,
        CE      => cq_dly_ce(cq_i),
        DATAIN  => '0',
        IDATAIN => cq_ibuf(cq_i),
        INC     => cq_dly_inc(cq_i),
        ODATAIN => '0',
        RST     => cq_dly_rst(cq_i),
        T       => '1'
        );

--    DDRII_CQ_IDELAY :  IDELAY
--      generic map (
--       IOBDELAY_TYPE  => "VARIABLE",
--       IOBDELAY_VALUE => 0
--       )
--      port map (
--       O   => cq_delay(cq_i),
--       C   => clk_0,
--       CE  => cq_dly_ce(cq_i),
--       I   => cq_ibuf(cq_i),
--       INC => cq_dly_inc(cq_i),
--       RST => cq_dly_rst(cq_i)
--       );

    DDRII_CQ_BUFIO_INST : BUFIO
      port map (
        I => cq_delay(cq_i),
        O => cq_bufio_w(cq_i)
        );

    ----------------------------------------------------------------------------
    -- Imitating the BUFIO delay (approx value) for simulation purpose.
    ----------------------------------------------------------------------------
    cq_bufio(cq_i) <= cq_bufio_w(cq_i) after 1000 ps;

  end generate CQ_INST;

  INST_36 : if(MEMORY_WIDTH = 36) generate
  begin
  ------------------------------------------------------------------------------
  -- CQ# path inside the IOB
  ------------------------------------------------------------------------------
    CQ_N_INST : for cq_n_i in 0 to CQ_WIDTH-1 generate
      attribute IODELAY_GROUP of U_IODELAY_CQ_N : label is IODELAY_GRP;
    begin
      DDRII_CQ_N_IBUF : IBUF
        port map (
         I => ddrii_cq_n(cq_n_i),
         O => cq_n_ibuf(cq_n_i)
        );
      --------------------------------------------------------------------------
      -- Delaying CQ bits with the appropriate delay values from the calibration
      -- module.
      --------------------------------------------------------------------------
      U_IODELAY_CQ_N : IODELAY
        generic map(
          DELAY_SRC             => "I",
          IDELAY_TYPE           => "VARIABLE",
          HIGH_PERFORMANCE_MODE => HIGH_PERFORMANCE_MODE,
          IDELAY_VALUE          => 0,
          ODELAY_VALUE          => 0
          )
        port map(
          DATAOUT => cq_n_delay(cq_n_i),
          C       => clk_0,
          CE      => cq_n_dly_ce(cq_n_i),
          DATAIN  => '0',
          IDATAIN => cq_n_ibuf(cq_n_i),
          INC     => cq_n_dly_inc(cq_n_i),
          ODATAIN => '0',
          RST     => cq_n_dly_rst(cq_n_i),
          T       => '1'
          );

--      DDRII_CQ_N_IDELAY :  IDELAY
--        generic map (
--         IOBDELAY_TYPE  => "VARIABLE",
--         IOBDELAY_VALUE => 0
--         )
--        port map (
--         O   => cq_n_delay(cq_n_i),
--         C   => clk_0,
--         CE  => cq_n_dly_ce(cq_n_i),
--         I   => cq_n_ibuf(cq_n_i),
--         INC => cq_n_dly_inc(cq_n_i),
--         RST => cq_n_dly_rst(cq_n_i)
--         );

      DDRII_CQ_N_BUFIO_INST : BUFIO
        port map (
          I => cq_n_delay(cq_n_i),
          O => cq_n_bufio_w(cq_n_i)
          );

      --------------------------------------------------------------------------
      -- Imitating the BUFIO delay (approx value) for simulation purpose.
      --------------------------------------------------------------------------
      cq_n_bufio(cq_n_i) <= cq_n_bufio_w(cq_n_i) after 1000 ps;

    end generate CQ_N_INST;
  end generate INST_36;

  INST_18_9 : if(MEMORY_WIDTH /= 36) generate
    CQ_N_INST : for cq_n_i in 0 to CQ_WIDTH-1 generate
    attribute syn_noprune of UNUSED_CQ_N_INST : label is true;
    begin
      UNUSED_CQ_N_INST : MUXCY
        port map (
          O  => unused_cq_n(cq_n_i),
          CI => ddrii_cq_n(cq_n_i),
          DI => '0',
          S  => '1'
          );
    end generate CQ_N_INST;
  end generate INST_18_9;

end architecture arch_ddrii_phy_cq_io;
