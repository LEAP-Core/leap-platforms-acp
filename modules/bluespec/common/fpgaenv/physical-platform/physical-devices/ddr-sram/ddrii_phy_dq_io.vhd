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
--  /   /         Filename           : ddrii_phy_dq_io.vhd
-- /___/   /\     Timestamp          : 08 Apr 2008
-- \   \  /  \    Date Last Modified : $Date: 2009/05/11 21:13:30 $
--  \___\/\___\
--
--Device: Virtex-5
--Design: DDRII
--
--Purpose:
--   This module places the data in the IOBs.
--Revision History:
--   Rev 1.1 - Parameter IODELAY_GRP added and constraint IODELAY_GROUP added
--             on IODELAY primitive. PK. 11/27/08
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity  ddrii_phy_dq_io is
  generic (
    -- Following parameters are for 72-bit design. Actual values may be
    -- different. Actual parameters values are passed from design top module
    -- ddr2_sram module. Please refer to the ddr2_sram module for actual
    -- values.
    BW_WIDTH              : integer := 8;
    CQ_WIDTH              : integer := 2;
    DATA_WIDTH            : integer := 72;
    HIGH_PERFORMANCE_MODE : boolean := TRUE;
    IODELAY_GRP           : string  := "IODELAY_MIG";
    IO_TYPE               : string  := "CIO";
    MEMORY_WIDTH          : integer := 36;
    Q_PER_CQ              : integer := 36
    );
  port(
    clk_0            : in    std_logic; -- 0 degree phase shifted clock from DCM.
    cq_bufio         : in    std_logic_vector(CQ_WIDTH-1 downto 0);
    -- Delay CQ signal from CQ IDELAY element.
    cq_n_bufio       : in    std_logic_vector(CQ_WIDTH-1 downto 0);
    -- Delay CQ# signal from CQ IDELAY element (only for x36 memory controller
    -- designs).
    q_cq_dly_ce      : in    std_logic_vector(CQ_WIDTH-1 downto 0);
    -- Enable signal for the IDELAY element used to delay read data bits which
    -- are associated with CQ.
    q_cq_dly_inc     : in    std_logic_vector(CQ_WIDTH-1 downto 0);
    -- Increment/decrement signal for the IDELAY element used to delay read data
    -- bits which are associated with CQ.
    q_cq_dly_rst     : in    std_logic_vector(CQ_WIDTH-1 downto 0);
    -- Reset signal for the IDELAY element used to delay read data bits which
    -- are associated with CQ.
    q_cq_n_dly_ce    : in    std_logic_vector(CQ_WIDTH-1 downto 0);
    -- Enable signal for the IDELAY element used to delay read data bits which
    -- are associated with CQ# (only for x36 memory controller designs).
    q_cq_n_dly_inc   : in    std_logic_vector(CQ_WIDTH-1 downto 0);
    -- Increment/decrement signal for the IDELAY element used to delay read data
    -- bits which are associated with CQ# (only for x36 memory controller
    -- designs).
    q_cq_n_dly_rst   : in    std_logic_vector(CQ_WIDTH-1 downto 0);
    -- Reset signal for the IDELAY element used to delay read data bits which
    -- are associated with CQ# (only for x36 memory controller designs).
    wr_data_fall_r   : in    std_logic_vector(DATA_WIDTH-1 downto 0);
    -- Write data from phy_write module.
    wr_data_rise_r   : in    std_logic_vector(DATA_WIDTH-1 downto 0);
    -- Write data from phy_write module.
    ddrii_q          : in    std_logic_vector(DATA_WIDTH-1 downto 0);
    -- Read data port from memory (in case of SIO designs only).
    not_write_cmd_r5 : in    std_logic_vector(DATA_WIDTH-1 downto 0);
    -- inverted signal of 5 clocks registered version of write command from the
    -- controller. Used as tri-state enable signal to the Tri-State IOB (only
    -- for CIO designs)
    ddrii_d          : out   std_logic_vector(DATA_WIDTH-1 downto 0);
    -- Write data port to memory (in case of SIO designs only).
    read_data_rise   : out   std_logic_vector(DATA_WIDTH-1 downto 0);
    -- delayed read data captured using ISERDES with rising edge of clk_0
    -- (FPGA clock).
    read_data_fall   : out   std_logic_vector(DATA_WIDTH-1 downto 0);
    -- delayed read data captured using ISERDES with falling edge of clk_0
    -- (FPGA clock).
    ddrii_dq         : inout std_logic_vector(DATA_WIDTH-1 downto 0)
    -- Data bus carring both write/read data to/from the memory (only for CIO
    -- designs).
    );
end entity ddrii_phy_dq_io;

architecture arch_ddrii_phy_dq_io of ddrii_phy_dq_io is

  signal ddrii_d_int       : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal ddrii_q_int       : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal rd_data_in        : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal rd_data_in_delay  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal iserdes_clk_cq    : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal iserdes_clkb_cq   : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal iserdes_clk_cq_n  : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal iserdes_clkb_cq_n : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal data_rise         : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal data_fall         : std_logic_vector(DATA_WIDTH-1 downto 0);

  attribute IODELAY_GROUP : string;

begin

  DATA_WIDTH_INST : for n in 0 to DATA_WIDTH-1 generate
  begin
    ----------------------------------------------------------------------------
    -- ODDR primitive to convert SDR write data to DDR write data
    ----------------------------------------------------------------------------
    ODDR_DDRII_D : ODDR
      generic map(
        DDR_CLK_EDGE => "SAME_EDGE"
        )
      port map(
        Q  => ddrii_d_int(n),
        C  => clk_0,
        CE => '1',
        D1 => wr_data_rise_r(n),
        D2 => wr_data_fall_r(n),
        R  => '0',
        S  => '0'
        );

    ----------------------------------------------------------------------------
    -- I/O Buffers to transfer write and read to/from the memory bus (only for
    -- SIO designs)
    ----------------------------------------------------------------------------
    SIO_INST: if(IO_TYPE = "SIO") generate
    begin
      DDRII_D_OBUF : OBUF
        port map (
          I => ddrii_d_int(n),
          O => ddrii_d(n)
          );

      DDRII_Q_IBUF : IBUF
         port map(
           I => ddrii_q(n),
           O => ddrii_q_int(n)
           );

    end generate SIO_INST;

    ----------------------------------------------------------------------------
    -- A tri state buffer to transfer either write data or read data to/from the
    -- memory bus (depending on the command sequence issued by the controller
    -- state machine - only for CIO designs).
    ----------------------------------------------------------------------------
    CIO_INST: if(IO_TYPE = "CIO") generate
    begin

      ddrii_d(n) <= '0';

      DDRII_DQ_IOBUF : IOBUF
        port map (
          I  => ddrii_d_int(n),
          O  => ddrii_q_int(n),
          IO => ddrii_dq(n),
          T  => not_write_cmd_r5(n)
          );
    end generate CIO_INST;

    rd_data_in(n)     <= ddrii_q_int(n);
    read_data_rise(n) <= data_rise(n);
    read_data_fall(n) <= data_fall(n);

  end generate DATA_WIDTH_INST;

  MEMORY_WIDTH_36 : if(MEMORY_WIDTH = 36) generate
  begin
    CQ_INST : for i in 0 to CQ_WIDTH-1 generate
      Q_PER_CQ_INST : for k in 0 to Q_PER_CQ-1 generate
        attribute IODELAY_GROUP of U_IODELAY_CQ   : label is IODELAY_GRP;
      begin
        U_IODELAY_CQ : IODELAY
          generic map(
            DELAY_SRC             => "I",
            IDELAY_TYPE           => "VARIABLE",
            HIGH_PERFORMANCE_MODE => HIGH_PERFORMANCE_MODE,
            IDELAY_VALUE          => 0,
            ODELAY_VALUE          => 0
            )
          port map(
            DATAOUT => rd_data_in_delay((Q_PER_CQ*(i*2))+k),
            C       => clk_0,
            CE      => q_cq_dly_ce(i),
            DATAIN  => '0',
            IDATAIN => rd_data_in((Q_PER_CQ*(i*2))+k),
            INC     => q_cq_dly_inc(i),
            ODATAIN => '0',
            RST     => q_cq_dly_rst(i),
            T       => '1'
            );

        iserdes_clk_cq(i)  <= not cq_bufio(i);
        iserdes_clkb_cq(i) <= cq_bufio(i);

        U_ISERDES_NODELAY_CQ : ISERDES_NODELAY
          generic map (
            BITSLIP_ENABLE => FALSE,
            DATA_RATE      => "DDR",
            DATA_WIDTH     => 4,
            INTERFACE_TYPE => "MEMORY",
            NUM_CE         => 2,
            SERDES_MODE    => "MASTER"
            )
          port map(
            Q1        => data_fall((Q_PER_CQ*(i*2))+k),
            Q2        => data_rise((Q_PER_CQ*(i*2))+k),
            Q3        => open,
            Q4        => open,
            Q5        => open,
            Q6        => open,
            SHIFTOUT1 => open,
            SHIFTOUT2 => open,
            BITSLIP   => '0',
            CE1       => '1',
            CE2       => '1',
            CLK       => iserdes_clk_cq(i),
            CLKB      => iserdes_clkb_cq(i),
            CLKDIV    => clk_0,
            D         => rd_data_in_delay((Q_PER_CQ*(i*2))+k),
            OCLK      => clk_0,
            RST       => '0',
            SHIFTIN1  => '0',
            SHIFTIN2  => '0'
            );
      end generate Q_PER_CQ_INST;
    end generate CQ_INST;

    CQ_N_INST : for j in 0 to CQ_WIDTH-1 generate
      Q_PER_CQ_N_INST : for k in 0 to Q_PER_CQ-1 generate
        attribute IODELAY_GROUP of U_IODELAY_CQ_N : label is IODELAY_GRP;
      begin
        U_IODELAY_CQ_N : IODELAY
          generic map(
            DELAY_SRC             => "I",
            IDELAY_TYPE           => "VARIABLE",
            HIGH_PERFORMANCE_MODE => HIGH_PERFORMANCE_MODE,
            IDELAY_VALUE          => 0,
            ODELAY_VALUE          => 0
            )
          port map(
            DATAOUT => rd_data_in_delay((Q_PER_CQ*((j*2)+1))+k),
            C       => clk_0,
            CE      => q_cq_n_dly_ce(j),
            DATAIN  => '0',
            IDATAIN => rd_data_in((Q_PER_CQ*((j*2)+1))+k),
            INC     => q_cq_n_dly_inc(j),
            ODATAIN => '0',
            RST     => q_cq_n_dly_rst(j),
            T       => '1'
            );

        iserdes_clk_cq_n(j)  <= cq_n_bufio(j);
        iserdes_clkb_cq_n(j) <= not cq_n_bufio(j);

        U_ISERDES_NODELAY_CQ_N : ISERDES_NODELAY
          generic map (
            BITSLIP_ENABLE => FALSE,
            DATA_RATE      => "DDR",
            DATA_WIDTH     => 4,
            INTERFACE_TYPE => "MEMORY",
            NUM_CE         => 2,
            SERDES_MODE    => "MASTER"
            )
          port map(
            Q1        => data_fall((Q_PER_CQ*((j*2)+1))+k),
            Q2        => data_rise((Q_PER_CQ*((j*2)+1))+k),
            Q3        => open,
            Q4        => open,
            Q5        => open,
            Q6        => open,
            SHIFTOUT1 => open,
            SHIFTOUT2 => open,
            BITSLIP   => '0',
            CE1       => '1',
            CE2       => '1',
            CLK       => iserdes_clk_cq_n(j),
            CLKB      => iserdes_clkb_cq_n(j),
            CLKDIV    => clk_0,
            D         => rd_data_in_delay((Q_PER_CQ*((j*2)+1))+k),
            OCLK      => clk_0,
            RST       => '0',
            SHIFTIN1  => '0',
            SHIFTIN2  => '0'
            );
      end generate Q_PER_CQ_N_INST;
    end generate CQ_N_INST;
  end generate MEMORY_WIDTH_36;

  MEMORY_WIDTH_18_9 : if(MEMORY_WIDTH /= 36) generate
  begin
    CQ_INST : for i in 0 to CQ_WIDTH-1 generate
      Q_PER_CQ_INST : for k in 0 to Q_PER_CQ-1 generate
        attribute IODELAY_GROUP of U_IODELAY_CQ   : label is IODELAY_GRP;
      begin
        U_IODELAY_CQ : IODELAY
          generic map(
            DELAY_SRC             => "I",
            IDELAY_TYPE           => "VARIABLE",
            HIGH_PERFORMANCE_MODE => HIGH_PERFORMANCE_MODE,
            IDELAY_VALUE          => 0,
            ODELAY_VALUE          => 0
            )
          port map(
            DATAOUT => rd_data_in_delay((Q_PER_CQ*i)+k),
            C       => clk_0,
            CE      => q_cq_dly_ce(i),
            DATAIN  => '0',
            IDATAIN => rd_data_in((Q_PER_CQ*i)+k),
            INC     => q_cq_dly_inc(i),
            ODATAIN => '0',
            RST     => q_cq_dly_rst(i),
            T       => '1'
            );

        iserdes_clk_cq(i)  <= not cq_bufio(i);
        iserdes_clkb_cq(i) <= cq_bufio(i);

        U_ISERDES_NODELAY_CQ : ISERDES_NODELAY
          generic map (
            BITSLIP_ENABLE => FALSE,
            DATA_RATE      => "DDR",
            DATA_WIDTH     => 4,
            INTERFACE_TYPE => "MEMORY",
            NUM_CE         => 2,
            SERDES_MODE    => "MASTER"
            )
          port map(
            Q1        => data_fall((Q_PER_CQ*i)+k),
            Q2        => data_rise((Q_PER_CQ*i)+k),
            Q3        => open,
            Q4        => open,
            Q5        => open,
            Q6        => open,
            SHIFTOUT1 => open,
            SHIFTOUT2 => open,
            BITSLIP   => '0',
            CE1       => '1',
            CE2       => '1',
            CLK       => iserdes_clk_cq(i),
            CLKB      => iserdes_clkb_cq(i),
            CLKDIV    => clk_0,
            D         => rd_data_in_delay((Q_PER_CQ*i)+k),
            OCLK      => clk_0,
            RST       => '0',
            SHIFTIN1  => '0',
            SHIFTIN2  => '0'
            );
      end generate Q_PER_CQ_INST;
    end generate CQ_INST;
  end generate MEMORY_WIDTH_18_9;

end architecture arch_ddrii_phy_dq_io;