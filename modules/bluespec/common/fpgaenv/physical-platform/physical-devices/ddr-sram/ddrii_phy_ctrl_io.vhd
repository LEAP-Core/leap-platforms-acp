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
--  /   /         Filename           : ddrii_phy_ctrl_io.vhd
-- /___/   /\     Timestamp          : 08 Apr 2008
-- \   \  /  \    Date Last Modified : $Date: 2009/05/11 21:13:29 $
--  \___\/\___\
--
--Device: Virtex-5
--Design: DDRII
--
--Purpose:
--    This module has
--  1. Control logic for controlling the flow of write/read data to/from the
--     memory
--  2. Instantiates the I/O module for generating the addresses, read/write
--     commands, DLL_off_n, clocks to the memory.
--
--Revision History:
--
--*****************************************************************************

library ieee;
library unisim;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;

entity ddrii_phy_ctrl_io is
  generic (
    -- Following parameters are for 72-bit design. Actual values may be
    -- different. Actual parameters values are passed from design top module
    -- ddr2_sram module. Please refer to the ddr2_sram module for actual
    -- values.
    ADDR_WIDTH   : integer := 19;
    BURST_LENGTH : integer := 4;
    CLK_WIDTH    : integer := 2;
    DATA_WIDTH   : integer := 72;
    IO_TYPE      : string  := "CIO"
    );
  port (
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
end entity ddrii_phy_ctrl_io;

architecture arch_ddrii_phy_ctrl_io of ddrii_phy_ctrl_io is

  signal ddrii_sa_obuf    : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal wr_rd_address_r  : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal wr_rd_address_2r : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal wr_rd_address_3r : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal clk_obuf         : std_logic_vector(CLK_WIDTH-1 downto 0);
  signal clk_n_obuf       : std_logic_vector(CLK_WIDTH-1 downto 0);
  signal dll_off_n        : std_logic;
  signal dll_off_n_obuf   : std_logic;
  signal ld_n_i           : std_logic;
  signal rw_n_i           : std_logic;
  signal ld_n_r1          : std_logic;
  signal ld_n_r2          : std_logic;
  signal ld_n_r3          : std_logic;
  signal rw_n_r1          : std_logic;
  signal rw_n_r2          : std_logic;
  signal rw_n_r3          : std_logic;
  signal write_cmd        : std_logic;
  signal write_cmd_r1     : std_logic;
  signal write_cmd_r2     : std_logic;
  signal write_cmd_r3_i   : std_logic;
  signal not_write_cmd_r3 : std_logic;
  signal not_write_cmd_r4 : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal write_cmd_i2     : std_logic;

  attribute syn_useioff : boolean;
  attribute IOB         : string;

  attribute syn_useioff of DDRII_DLL_OFF_FF : label is true;
  attribute IOB of DDRII_DLL_OFF_FF : label is "force";
  attribute syn_useioff of U8_FDRSE : label is true;
  attribute IOB of U8_FDRSE : label is "force";
  attribute syn_useioff of U11_FDRSE : label is true;
  attribute IOB of U11_FDRSE : label is "force";

  -- Angshuman begin
  attribute S : string;
  attribute S of "not_write_cmd_r4" : signal is "TRUE";
  attribute S of "not_write_cmd_r5" : signal is "TRUE";
  attribute keep : string;
  -- Angshuman end

begin
  ------------------------------------------------------------------------------
  -- Read control signal generation from the read commands asserted by both
  -- controller state machine and initilization state machine.
  ------------------------------------------------------------------------------
  read_cmd <= '1' when (((ctrl_ld_n = '0') and (ctrl_rw_n = '1')) or
                        ((cal_ld_n = '0') and (cal_rw_n = '1'))) else '0';

  ------------------------------------------------------------------------------
  -- Write control signal generation from the write commands asserted by both
  -- controller state machine and initilization state machine.
  ------------------------------------------------------------------------------
  write_cmd <= '1' when (((ctrl_ld_n = '0') and (ctrl_rw_n = '0')) or
                         ((cal_ld_n = '0') and (cal_rw_n = '0'))) else '0';

  U1_FDRSE : FDRSE
    generic map (
      INIT => '0'
      )
    port map (
      Q  => write_cmd_r1,
      C  => clk_0,
      CE => '1',
      D  => write_cmd,
      R  => '0',
      S  => '0'
      );

  U2_FDRSE : FDRSE
    generic map (
      INIT => '0'
      )
    port map (
      Q  => write_cmd_r2,
      C  => clk_0,
      CE => '1',
      D  => write_cmd_r1,
      R  => '0',
      S  => '0'
      );

  ------------------------------------------------------------------------------
  -- A single write command is expanded for two clock for burst length 4 design,
  -- in order to read two sets of data (two sets of rise data and fall data)from
  -- to two separate FIFOs (Rise data FIFO and fall data FIFO) for every single
  -- write command. For burst length 2 designs, only one set of rise data and
  -- fall data has to be read from two separate FIFOs for every write single
  -- write command.
  ------------------------------------------------------------------------------
  write_cmd_i2      <= (write_cmd_r1 or write_cmd_r2) when (BURST_LENGTH = 4)
                                                      else
                        write_cmd_r1;

  wrdata_fifo_rd_en <= write_cmd_i2;

  U3_FDRSE : FDRSE
    generic map (
      INIT => '0'
      )
    port map (
      Q  => write_cmd_r3_i,
      C  => clk_0,
      CE => '1',
      D  => write_cmd_i2,
      R  => '0',
      S  => '0'
      );

  write_cmd_r3 <= write_cmd_r3_i;
  not_write_cmd_r3 <= not write_cmd_r3_i;

  CIO_TRI_EN_INST : if(IO_TYPE = "CIO") generate
    TRI_ENA_FF_INST : for t in 0 to DATA_WIDTH-1 generate
    attribute syn_useioff of U5_FDRSE : label is true;
    attribute IOB of U5_FDRSE : label is "force";

    -- Angshu
    attribute keep of U5_FDRSE : label is "true";
    
    begin
      U4_FDRSE : FDRSE
        generic map (
          INIT => '0'
          )
        port map (
          Q  => not_write_cmd_r4(t),
          C  => clk_0,
          CE => '1',
          D  => not_write_cmd_r3,
          R  => '0',
          S  => '0'
          );

      --------------------------------------------------------------------------
      -- when ever there is a write command, write data has to be passed from
      -- controller to the memory (for CIO designs only), hence a tri-state
      -- enable signal generated from the write control signal itself.
      --------------------------------------------------------------------------

      U5_FDRSE : FDRSE
        generic map (
          INIT => '0'
          )
        port map (
          Q  => not_write_cmd_r5(t),
          C  => clk_0,
          CE => '1',
          D  => not_write_cmd_r4(t),
          R  => '0',
          S  => '0'
          );
    end generate TRI_ENA_FF_INST;
  end generate CIO_TRI_EN_INST;

  ------------------------------------------------------------------------------
  -- Clk IOBS instantiation
  ------------------------------------------------------------------------------
  ddrii_c   <= (others => '1');
  ddrii_c_n <= (others => '1');

  ------------------------------------------------------------------------------
  --DDRII_DLL_OFF_N IOB
  ------------------------------------------------------------------------------
  --DDRII_DLL_OFF is asserted high after the 200 us initial count
  process(clk_0)
    begin
      if(rising_edge(clk_0)) then
        if(reset_clk_0 = '1') then
          dll_off_n <= '0';
        elsif(init_wait_done = '1') then
          dll_off_n <= '1';
        end if;
      end if;
  end process;

  DDRII_DLL_OFF_FF : FDRSE
    generic map (
      INIT => '0'
      )
    port map (
      Q  => dll_off_n_obuf,
      C  => clk_0,
      CE => '1',
      D  => dll_off_n,
      R  => reset_clk_0,
      S  => '0'
      );

  OBUF_DLL_OFF_N : OBUF
    port map(
      I => dll_off_n_obuf,
      O => ddrii_dll_off_n
      );
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Memory K/K# clock signal generation and IOB instantiation
  ------------------------------------------------------------------------------
  CLK_INST : for clk_i in 0 to (CLK_WIDTH-1) generate
    ODDR_K_CLK : ODDR
      generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE"
        )
      port map (
        Q  => clk_obuf(clk_i),
        C  => clk_90,
        CE => '1',
        D1 => '1',
        D2 => '0',
        R  => '0',
        S  => '0'
        );

    ODDR_K_CLKB : ODDR
      generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE"
        )
      port map (
        Q  => clk_n_obuf(clk_i),
        C  => clk_90,
        CE => '1',
        D1 => '0',
        D2 => '1',
        R  => '0',
        S  => '0'
        );

    OBUF_K_CLK : OBUF
      port map(
        I => clk_obuf(clk_i),
        O => ddrii_k(clk_i)
        );

    OBUF_K_CLKB : OBUF
      port map(
        I => clk_n_obuf(clk_i),
        O => ddrii_k_n(clk_i)
        );
  end generate CLK_INST;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Address IOBs instantiation
  ------------------------------------------------------------------------------

  process (clk_270)
  begin
    if(rising_edge(clk_270)) then
      wr_rd_address_r <= wr_rd_address;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- Address bits from the user interface are passed to memory only after the
  -- calibration is complete. Before the calibration, address bits are passed to
  -- memory from the phy_init_sm module.
  ------------------------------------------------------------------------------
  process (clk_270)
  begin
    if(rising_edge(clk_270)) then
      if(cal_done = '0') then
        wr_rd_address_2r <= cal_addr;
      else
        wr_rd_address_2r <= wr_rd_address_r;
      end if;
    end if;
  end process;

  process (clk_270)
  begin
    if(rising_edge(clk_270)) then
      wr_rd_address_3r <= wr_rd_address_2r;
    end if;
  end process;

  ADDR_INST : for i in 0 to ADDR_WIDTH-1 generate
  attribute syn_useioff of ADDRESS_FF : label is true;
  attribute IOB of ADDRESS_FF : label is "force";
  begin
    ADDRESS_FF : FDRSE
      generic map (
        INIT => '0'
        )
      port map (
        Q  => ddrii_sa_obuf(i),
        C  => clk_270,
        CE => '1',
        D  => wr_rd_address_3r(i),
        R  => '0',
        S  => '0'
        );

    ADDR_OBUF : OBUF
      port map(
        I => ddrii_sa_obuf(i),
        O => ddrii_sa(i)
        );
  end generate ADDR_INST;
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Command IOBs instantiation
  ------------------------------------------------------------------------------

  ld_n_i  <= ctrl_ld_n and cal_ld_n;
  rw_n_i  <= '0' when ((ctrl_rw_n = '0') or (cal_rw_n = '0')) else
             '1';

  U6_FDRSE : FDRSE
    generic map (
      INIT => '1'
      )
    port map (
      Q  => ld_n_r1,
      C  => clk_270,
      CE => '1',
      D  => ld_n_i,
      R  => '0',
      S  => reset_clk_270
      );

  U7_FDRSE : FDRSE
    generic map (
      INIT => '1'
      )
    port map (
      Q  => ld_n_r2,
      C  => clk_270,
      CE => '1',
      D  => ld_n_r1,
      R  => '0',
      S  => reset_clk_270
      );

  U8_FDRSE : FDRSE
    generic map (
      INIT => '1'
      )
    port map (
      Q  => ld_n_r3,
      C  => clk_270,
      CE => '1',
      D  => ld_n_r2,
      R  => '0',
      S  => reset_clk_270
      );

  LD_N_OBUF_INST : OBUF
    port map(
      I => ld_n_r3,
      O => ddrii_ld_n
      );

  U9_FDRSE : FDRSE
    generic map (
      INIT => '1'
      )
    port map (
      Q  => rw_n_r1,
      C  => clk_270,
      CE => '1',
      D  => rw_n_i,
      R  => '0',
      S  => reset_clk_270
      );

  U10_FDRSE : FDRSE
    generic map (
      INIT => '1'
      )
    port map (
      Q  => rw_n_r2,
      C  => clk_270,
      CE => '1',
      D  => rw_n_r1,
      R  => '0',
      S  => reset_clk_270
      );

  U11_FDRSE : FDRSE
    generic map (
      INIT => '1'
      )
    port map (
      Q  => rw_n_r3,
      C  => clk_270,
      CE => '1',
      D  => rw_n_r2,
      R  => '0',
      S  => reset_clk_270
      );

  RW_N_OBUF_INST : OBUF
    port map(
      I => rw_n_r3,
      O => ddrii_rw_n
      );

  -------------- End of command IOBS instantiation -----------------------------

end architecture arch_ddrii_phy_ctrl_io;
