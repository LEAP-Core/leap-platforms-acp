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
--  /   /         Filename           : ddrii_top_ctrl_sm.vhd
-- /___/   /\     Timestamp          : 08 Apr 2008
-- \   \  /  \    Date Last Modified : $Date: 2009/05/11 21:13:31 $
--  \___\/\___\
--
--Device: Virtex-5
--Design: DDRII
--
--Purpose:
--    This module
--       1. Monitors Read / Write queue status from User Interface FIFOs and
--          generates strobe signals to launch Read / Write requests to
--          DDR II device.
--
--Revision History:
--
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity ddrii_top_ctrl_sm is
  generic (
    -- Following parameters are for 72-bit design. Actual values may be
    -- different. Actual parameters values are passed from design top module
    -- ddr2_sram module. Please refer to the ddr2_sram module for actual
    -- values.
    BURST_LENGTH     : integer := 4;
    IO_TYPE          : string  := "CIO";
    BUS_TURNAROUND   : integer := 0
    );
  port (
    clk_0             : in  std_logic; -- 0 degree phase shifted clock from DCM.
    reset_clk_0       : in  std_logic; -- Reset signal derived in clk_0 domain.
    addr_fifo_empty   : in  std_logic; -- Address FIFO empty signal.
    wrdata_fifo_empty : in  std_logic; -- Write data FIFO (Rise data FIFO and
                                       -- Fall data FIFO) empty signal.
    cal_done          : in  std_logic; -- Calibration complete signal.
    command_bit       : in  std_logic; -- command bit derived from address FIFO
                                       -- output bits.
    addr_fifo_rd_en   : out std_logic; -- Address FIFO read enable signal.
    ctrl_ld_n         : out std_logic; -- Active Low Load signal. A Read/Write
                                       -- command is valid only when the value
                                       -- of this signal is 0
    ctrl_rw_n         : out std_logic  -- Active Low Read/Write signal.
                                       -- =0, when Write; and = 1 when Read.
    );
end entity ddrii_top_ctrl_sm;

architecture arch_ddrii_top_ctrl_sm of ddrii_top_ctrl_sm is

  constant CAL_WAIT_ST         : std_logic_vector(6 downto 0) := "0000001";
  constant FIFO_EMPTY_ST       : std_logic_vector(6 downto 0) := "0000010";
  constant BL2_ST              : std_logic_vector(6 downto 0) := "0000100";
  constant BL4_ST              : std_logic_vector(6 downto 0) := "0001000";
  constant BURST_WAIT_ST       : std_logic_vector(6 downto 0) := "0010000";
  constant CMD_WAIT_ST         : std_logic_vector(6 downto 0) := "0100000";
  constant RD_TO_WR_LATENCY_ST : std_logic_vector(6 downto 0) := "1000000";

  signal current_state      : std_logic_vector(6 downto 0);
  signal next_state         : std_logic_vector(6 downto 0);
  signal addr_fifo_rd_en_i  : std_logic;
  signal addr_fifo_rd_en_r1 : std_logic;
  signal command_bit_r1     : std_logic;
  signal cmd_wait           : std_logic;
  signal shift_en           : std_logic;
  signal shift_en_r1        : std_logic;
  signal latency_value      : std_logic_vector(2 downto 0);
  signal latency            : std_logic_vector(2 downto 0);

begin

  addr_fifo_rd_en <= addr_fifo_rd_en_i;

  ctrl_ld_n <= not(addr_fifo_rd_en_r1);
  ctrl_rw_n <= command_bit_r1 when (addr_fifo_rd_en_r1 = '1') else
               '1';

  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      addr_fifo_rd_en_r1 <= addr_fifo_rd_en_i;
    end if;
  end process;

  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      shift_en_r1 <= shift_en;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- Programmable latency values is loaded in to this register and shifted to
  -- Right until all the bits are shifted out.
  ------------------------------------------------------------------------------
  process(clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(shift_en_r1 = '1') then
        latency(1 downto 0) <= latency(2 downto 1);
        latency(2)          <= '0';
      else
        latency <= latency_value;
      end if;
    end if;
  end process;

  --  process (clk_0)
  --  begin
  --    if(rising_edge(clk_0)) then
  --      if(reset_clk_0 = '1') then
  --        command_bit_r1 <= '1';
  --      else
  --        command_bit_r1 <= command_bit;
  --      end if;
  --    end if;
  --  end process;

  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(addr_fifo_empty = '1') then
        command_bit_r1 <= '0';
      else
        command_bit_r1 <= command_bit;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- This signal is asserted HIGH when the present command is Write command and
  -- the previous command is Read command (A Read-followed by-Write condition).
  -- Address fifo empty signal is considered to validate the commands.
  ------------------------------------------------------------------------------
  --  cmd_wait <= '1' when ((command_bit_r1 = '1') and (command_bit = '0') and
  --                        (addr_fifo_empty = '0')) else
  --              '0';

  cmd_wait <= '1' when ((command_bit_r1 = '1') and (command_bit = '0')) else
              '0';

  process (clk_0)
  begin
    if(rising_edge(clk_0)) then
      if(reset_clk_0 = '1') then
        current_state <= CAL_WAIT_ST;
      else
        current_state <= next_state;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- This is a Moore state mahcine for issuing user commands to memory
  ------------------------------------------------------------------------------
  process(current_state, addr_fifo_empty, cal_done, cmd_wait, latency)
  begin
    addr_fifo_rd_en_i <= '0';
    latency_value     <= "000";
    shift_en          <= '0';
    case(current_state) is

      --------------------------------------------------------------------------
      -- Calibration wait state : Initial state, until the calibration is not
      -- done state machine remains in this state.
      -- Once the calibration is done and the address FIFO is not empty,
      -- depending on the BURST LENGTH parameter, state machine either goes to
      -- BL2 state or BL4 state. Since the Address FIFO is in FWFT mode, the
      -- first address and command bits are on the output bus of FIFO when the
      -- address FIFO empty signal is de-asserted.
      -- For BURST LENGTH = 2, commands are to be Read on every clock.
      -- For BURST LENGTH = 4, commands are to be Read on every alterate clock.
      --------------------------------------------------------------------------
      when CAL_WAIT_ST =>
        if(cal_done = '1') then
          if((BURST_LENGTH = 4) and (addr_fifo_empty = '0')) then
            addr_fifo_rd_en_i <= '0';
            next_state        <= BL4_ST;
          elsif((BURST_LENGTH = 2) and (addr_fifo_empty = '0')) then
            addr_fifo_rd_en_i <= '1';
            next_state        <= BL2_ST;
          else
            addr_fifo_rd_en_i <= '0';
            next_state        <= FIFO_EMPTY_ST;
          end if;
        else
          addr_fifo_rd_en_i <= '0';
          next_state        <= CAL_WAIT_ST;
        end if;

      --------------------------------------------------------------------------
      -- When ever the Address FIFO is empty, state machine remains in this
      -- state.
      --------------------------------------------------------------------------
      when FIFO_EMPTY_ST =>
        if(addr_fifo_empty = '1') then
          addr_fifo_rd_en_i <= '0';
          next_state        <= FIFO_EMPTY_ST;
        else
          if(BURST_LENGTH = 4) then
            addr_fifo_rd_en_i <= '0';
            next_state        <= BL4_ST;
          elsif(BURST_LENGTH = 2) then
            addr_fifo_rd_en_i <= '1';
            next_state        <= BL2_ST;
          end if;
        end if;

      --------------------------------------------------------------------------
      -- It is a BURST LENGTH 2 state. Address FIFO read enable signal is
      -- asserted HIGH for every clock. When there is Read-Followed by-Write
      -- condition, Address FIFO is not read and the state machine goes to
      -- CMD_WAIT_ST. For SIO designs, this Read-Followed by-Write condition is
      -- not valid (because of separate bus for Read data and Write data).
      --------------------------------------------------------------------------
      when BL2_ST =>
        if(addr_fifo_empty = '1') then
          addr_fifo_rd_en_i <= '0';
          next_state        <= FIFO_EMPTY_ST;
        elsif((cmd_wait = '1') and (IO_TYPE = "CIO")) then
          addr_fifo_rd_en_i <= '0';
          next_state        <= CMD_WAIT_ST;
        else
          addr_fifo_rd_en_i <= '1';
          next_state        <= BL2_ST;
        end if;

      --------------------------------------------------------------------------
      -- It is a BURST LENGTH 4 state. Address FIFO read enable signal is
      -- asserted HIGH for every alternate clock
      --------------------------------------------------------------------------
      when BL4_ST =>
        if(addr_fifo_empty = '1') then
          addr_fifo_rd_en_i <= '0';
          next_state        <= FIFO_EMPTY_ST;
        else
          addr_fifo_rd_en_i <= '1';
          next_state        <= BURST_WAIT_ST;
        end if;

      --------------------------------------------------------------------------
      -- It is a Burst wait state for reading address FIFO in every alternate
      -- clock. When there is Read-Followed by-Write condition, Address FIFO is
      -- not read and the state machine goes to CMD_WAIT_ST.
      --------------------------------------------------------------------------
      when BURST_WAIT_ST =>
        if(addr_fifo_empty = '1') then
          addr_fifo_rd_en_i <= '0';
          next_state        <= FIFO_EMPTY_ST;
        elsif(cmd_wait = '1') then
          addr_fifo_rd_en_i <= '0';
          next_state        <= CMD_WAIT_ST;
        else
          addr_fifo_rd_en_i <= '0';
          next_state        <= BL4_ST;
        end if;

      --------------------------------------------------------------------------
      -- It is a wait state for one clock period for a Read-Followed by-Write
      -- condition. when BUS_TURNAROUND parameter is non-zero, then the
      -- corresponding value is loaded in to the shift register and the state
      -- machine goes to RD_TO_WR_LATENCY_ST. when the BUS_TURNAROUND is zero
      -- then the state machine goes to either BL2_ST or BL4_ST depending on
      -- BURST LENGTH parameter
      --------------------------------------------------------------------------
      when CMD_WAIT_ST =>
        if(BUS_TURNAROUND /= 0) then
          if(BUS_TURNAROUND = 1) then
            latency_value <= "001";
          elsif(BUS_TURNAROUND = 2) then
            latency_value <= "011";
          elsif(BUS_TURNAROUND = 3) then
            latency_value <= "111";
          else
            latency_value <= "111";
          end if;
          shift_en          <= '1';
          addr_fifo_rd_en_i <= '0';
          next_state        <= RD_TO_WR_LATENCY_ST;
        else
          latency_value   <= (others => '0');
          if(BURST_LENGTH = 4) then
            addr_fifo_rd_en_i <= '0';
            next_state        <= BL4_ST;
          elsif(BURST_LENGTH = 2) then
            addr_fifo_rd_en_i <= '1';
            next_state        <= BL2_ST;
          end if;
        end if;

      --------------------------------------------------------------------------
      -- BUS_TURNAROUND parameter is an integer. Its value cannot be more than
      -- 3. The parameter value represents the number of extra clocks the state
      -- machine has to wait whenever there is a Read-Followed by-Write condition
      -- Until all the bits in the shift register is shifted out towards Right,
      -- state machine waits in this state itself.
      --------------------------------------------------------------------------
      when RD_TO_WR_LATENCY_ST =>
        if(latency(1) = '0') then
          shift_en <= '0';
          if(addr_fifo_empty = '1') then
            addr_fifo_rd_en_i <= '0';
            next_state        <= FIFO_EMPTY_ST;
          else
            if(BURST_LENGTH = 4) then
              addr_fifo_rd_en_i <= '0';
              next_state        <=  BL4_ST;
            elsif(BURST_LENGTH = 2) then
              addr_fifo_rd_en_i <= '1';
              next_state        <=  BL2_ST;
            end if;
          end if;
        else
          addr_fifo_rd_en_i <= '0';
          shift_en          <= '1';
          next_state        <= RD_TO_WR_LATENCY_ST;
        end if;

      when others =>
        next_state <= CAL_WAIT_ST;

    end case;
  end process;

end architecture arch_ddrii_top_ctrl_sm;