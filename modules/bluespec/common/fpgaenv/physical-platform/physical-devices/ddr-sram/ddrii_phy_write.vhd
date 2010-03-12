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
--  /   /         Filename           : ddrii_phy_write.vhd
-- /___/   /\     Timestamp          : 08 Apr 2008
-- \   \  /  \    Date Last Modified : $Date: 2009/05/11 21:13:30 $
--  \___\/\___\
--
--Device: Virtex-5
--Design: DDRIIII
--
--Purpose:
--    This module
--  1. Instantiates a state machine to write the pattern data in to Write data
--     FIFO.
--  2. Process the write data and byte write signals which are to be sent to
--     memory through IOB
--
--Revision History:
--
--*****************************************************************************

library ieee;
library unisim;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;

entity ddrii_phy_write is
  generic(
    -- Following parameters are for 72-bit design. Actual values may be
    -- different. Actual parameters values are passed from design top module
    -- ddr2_sram module. Please refer to the ddr2_sram module for actual
    -- values.
    BURST_LENGTH : integer := 4;
    BW_WIDTH     : integer := 8;
    DATA_WIDTH   : integer := 72
    );
  port(
    clk_0              : in  std_logic; -- 0 degree phase shifted clock from DCM.
    reset_clk_0        : in  std_logic; -- Reset signal derived in clk_0 domain.
    write_cmd_r3       : in  std_logic; -- Three clocks registered version of
                                        -- write command from the controller
                                        -- state machine.
    bw_n_rise          : in  std_logic_vector(BW_WIDTH-1 downto 0);
    -- Active low Byte write enable signals from Byte Write FIFO (will be
    -- associated with rising edge of K clock at IOBs).
    bw_n_fall          : in  std_logic_vector(BW_WIDTH-1 downto 0);
    -- Active low Byte write enable signals from Byte Write FIFO (will be
    -- associated with falling edge of K clock at IOBs).
    wr_data_rise       : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    -- Write data from Write data FIFO (will be associated with rising edge of K
    -- clock at IOBs).
    wr_data_fall       : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    -- Write data from Write data FIFO (will be associated with falling edge of
    -- K clock at IOBs).
    bw_n_rise_r        : out std_logic_vector(BW_WIDTH-1 downto 0);
    -- Single clock registered version of bw_n_rise (tied to zero in the absence
    -- of write commands). Used as Byte write signal at IOBs
    bw_n_fall_r        : out std_logic_vector(BW_WIDTH-1 downto 0);
    -- Single clock registered version of bw_n_fall (tied to zero in the absence
    -- of write commands). Used as Byte write signal at IOBs
    wr_data_rise_r     : out std_logic_vector(DATA_WIDTH-1 downto 0);
    -- Single clock registered version of wr_data_rise (maintained with the last
    -- data in the absence of any write commands). Used as Write data signal at
    -- IOBs
    wr_data_fall_r     : out std_logic_vector(DATA_WIDTH-1 downto 0);
    -- Single clock registered version of wr_data_fall. Used as Write data
    -- signal at IOBs.
    ptrn_data_rise_r1  : out std_logic_vector(DATA_WIDTH-1 downto 0);
    -- A fixed pattern of data written in the Write data FIFO( which are used
    -- during the calibration sequence - associated with rising edge of K clock).
    ptrn_data_fall_r1  : out std_logic_vector(DATA_WIDTH-1 downto 0);
    -- A fixed pattern of data written in the Write data FIFO( which are used
    -- during the calibration sequence - associated with falling edge of K clock).
    ptrn_data_wr_en_r1 : out std_logic
    -- A write enable signal to the Write data FIFO (Write enable signal for
    -- writing the pattern data)
    );
end entity ddrii_phy_write;

architecture arch_ddrii_phy_write of ddrii_phy_write is

  constant PATTERN_A : std_logic_vector(8 downto 0) := "111111111";
  constant PATTERN_B : std_logic_vector(8 downto 0) := "000000000";
  constant PATTERN_C : std_logic_vector(8 downto 0) := "101010101";
  constant PATTERN_D : std_logic_vector(8 downto 0) := "010101010";

  constant IDLE      : std_logic_vector(5 downto 0) := "000001";
  constant WR_1      : std_logic_vector(5 downto 0) := "000010";
  constant WR_2      : std_logic_vector(5 downto 0) := "000100";
  constant WR_3      : std_logic_vector(5 downto 0) := "001000";
  constant WR_4      : std_logic_vector(5 downto 0) := "010000";
  constant WR_DONE   : std_logic_vector(5 downto 0) := "100000";

  signal ptrn_data_wr_en : std_logic;
  signal Next_datagen_st : std_logic_vector(5 downto 0);
  signal PAT_A           : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal PAT_B           : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal PAT_C           : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal PAT_D           : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal ptrn_data_rise  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal ptrn_data_fall  : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

  ASGN : for i in 0 to BW_WIDTH-1 generate
    PAT_A(((i+1)*9)-1 downto (9*i)) <= PATTERN_A;
    PAT_B(((i+1)*9)-1 downto (9*i)) <= PATTERN_B;
    PAT_C(((i+1)*9)-1 downto (9*i)) <= PATTERN_C;
    PAT_D(((i+1)*9)-1 downto (9*i)) <= PATTERN_D;
  end generate ASGN;

  ------------------------------------------------------------------------------
  -- For Calibration purpose, a sequence of pattern datas are written in to
  -- Write Data FIFOs. Write data FIFO write enable signal is also generated.
  -- For BL4, a pattern of F-0, F-0, F-0, 5-A are written into Write Data FIFOs.
  -- For BL2, a pattern of F-0, F-0, 5-A are written into Write Data FIFOs.
  ------------------------------------------------------------------------------
  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0 = '1') then
        ptrn_data_rise  <= (others => '0');
        ptrn_data_fall  <= (others => '0');
        ptrn_data_wr_en <= '0';
        Next_datagen_st <= IDLE;
      else
        case (Next_datagen_st) is
          when IDLE =>
            ptrn_data_rise  <= (others => '0');
            ptrn_data_fall  <= (others => '0');
            ptrn_data_wr_en <= '0';
            Next_datagen_st <= WR_1;

          when WR_1 =>
            ptrn_data_rise  <= PAT_A;
            ptrn_data_fall  <= PAT_B;
            ptrn_data_wr_en <= '1';
            if(BURST_LENGTH = 4) then
              Next_datagen_st <= WR_2;
            elsif(BURST_LENGTH = 2) then
              Next_datagen_st <= WR_3;
            end if;

          when WR_2 =>
            ptrn_data_rise  <= PAT_A;
            ptrn_data_fall  <= PAT_B;
            ptrn_data_wr_en <= '1';
            Next_datagen_st <= WR_3;

          when WR_3 =>
            ptrn_data_rise  <= PAT_A;
            ptrn_data_fall  <= PAT_B;
            ptrn_data_wr_en <= '1';
            Next_datagen_st <= WR_4;

          when WR_4 =>
            ptrn_data_rise  <= PAT_C;
            ptrn_data_fall  <= PAT_D;
            ptrn_data_wr_en <= '1';
            Next_datagen_st <= WR_DONE;

          when WR_DONE =>
            ptrn_data_rise  <= (others => '0');
            ptrn_data_fall  <= (others => '0');
            ptrn_data_wr_en <= '0';
            Next_datagen_st <= WR_DONE;

          when others =>
            ptrn_data_rise  <= (others => '0');
            ptrn_data_fall  <= (others => '0');
            ptrn_data_wr_en <= '0';
            Next_datagen_st <= IDLE;

        end case;
      end if;
    end if;
  end process;

  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      ptrn_data_rise_r1  <= ptrn_data_rise;
      ptrn_data_fall_r1  <= ptrn_data_fall;
      ptrn_data_wr_en_r1 <= ptrn_data_wr_en;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- Generate Byte Write Logic
  -- Byte write enable signal for both rise and fall data is sent to memory only
  -- when there is write command, in other words byte write enable signal is
  -- sent to memory in sync with write data (according to memory specifications).
  -- In the absence of a write command, zeros are driven on to the bus. Since
  -- Byte write enable signal is a double data rated signal, in the absence of
  -- write data, a constant data (zeros) has to be maintained at the ODDR input.
  -- If not, the Byte write enable bus to the memory keeps on toggling.
  ------------------------------------------------------------------------------
  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if (write_cmd_r3 = '1') then
        bw_n_rise_r <= bw_n_rise;
        bw_n_fall_r <= bw_n_fall;
      else
        bw_n_rise_r <= (others => '0');
        bw_n_fall_r <= (others => '0');
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- Generate Write Burst Logic
  -- Since the Write data is double data rated signal, in the absence of write
  -- command, the data bus to the momory must not toggle. That is why the write
  -- data bus is maintained with the last data written on to the bus in the
  -- absence of write command.
  ------------------------------------------------------------------------------
  process (clk_0 )
  begin
    if(rising_edge(clk_0)) then
        wr_data_fall_r <= wr_data_fall;
      if(write_cmd_r3 = '1') then
        wr_data_rise_r <= wr_data_rise;
      else
        wr_data_rise_r <= wr_data_fall;
      end if;
    end if;
  end process;

end architecture arch_ddrii_phy_write;
