-------------------------------------------------------------------------------
-- $Id: sync_fifo.vhd,v 1.2 2007/05/23 11:41:41 goran Exp $
-------------------------------------------------------------------------------
-- sync_fifo.vhd - Entity and architecture
--
--  ***************************************************************************
--  **  Copyright(C) 2003 by Xilinx, Inc. All rights reserved.               **
--  **                                                                       **
--  **  This text contains proprietary, confidential                         **
--  **  information of Xilinx, Inc. , is distributed by                      **
--  **  under license from Xilinx, Inc., and may be used,                    **
--  **  copied and/or disclosed only pursuant to the terms                   **
--  **  of a valid license agreement with Xilinx, Inc.                       **
--  **                                                                       **
--  **  Unmodified source code is guaranteed to place and route,             **
--  **  function and run at speed according to the datasheet                 **
--  **  specification. Source code is provided "as-is", with no              **
--  **  obligation on the part of Xilinx to provide support.                 **
--  **                                                                       **
--  **  Xilinx Hotline support of source code IP shall only include          **
--  **  standard level Xilinx Hotline support, and will only address         **
--  **  issues and questions related to the standard released Netlist        **
--  **  version of the core (and thus indirectly, the original core source). **
--  **                                                                       **
--  **  The Xilinx Support Hotline does not have access to source            **
--  **  code and therefore cannot answer specific questions related          **
--  **  to source HDL. The Xilinx Support Hotline will only be able          **
--  **  to confirm the problem in the Netlist version of the core.           **
--  **                                                                       **
--  **  This copyright and support notice must be retained as part           **
--  **  of this text at all times.                                           **
--  ***************************************************************************
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Author:          satish
-- Revision:        $Revision: 1.2 $
-- Date:            $Date: 2007/05/23 11:41:41 $
--
-- History:
--   satish  2004-03-24    New Version
--
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x" 
--      reset signals:                          "rst", "rst_n" 
--      generics:                               "C_*" 
--      user defined types:                     "*_TYPE" 
--      state machine next state:               "*_ns" 
--      state machine current state:            "*_cs" 
--      combinatorial signals:                  "*_com" 
--      pipelined or register delay signals:    "*_d#" 
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce" 
--      internal version of output port         "*_i"
--      device pins:                            "*_pin" 
--      ports:                                  - Names begin with Uppercase 
--      processes:                              "*_PROCESS" 
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------
library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.numeric_std.all;

-- library fsl_v20_v2_11_a;
-- use fsl_v20_v2_11_a.all;

entity Sync_FIFO is
  generic (
    C_IMPL_STYLE : integer := 0;
    WordSize     : integer := 8;
    MemSize      : integer := 16
    );
  port (
    Reset : in std_logic;
    Clk   : in std_logic;

    WE      : in  std_logic;
    DataIn  : in  std_logic_vector(WordSize-1 downto 0);
    Full    : out std_logic;
    RD      : in  std_logic;
    DataOut : out std_logic_vector(WordSize-1 downto 0);
    Exists  : out std_logic
    );
end Sync_FIFO;

architecture VHDL_RTL of Sync_FIFO is

  -- signal read_addr_ptr_i      : natural;
  -- signal write_addr_ptr_i     : natural;

  -- purpose: calculate width of used address bits for address range  occupied by the
  -- memory. Requires 2^N sized blocks
  function addr_used_width (
    addr_size : integer)
    return integer is
    variable addr_cnt : integer := 0;
    variable cnt      : integer := 0;
  begin  -- addr_decode_width
    addr_cnt := addr_size;
    while addr_cnt > 0 loop
      addr_cnt := addr_cnt / 2;
      cnt      := cnt + 1;
    end loop;
    return cnt-1;
  end addr_used_width;

  constant AddrWidth   : integer := addr_used_width(MemSize);
  signal Read_Address  : std_logic_vector(0 to AddrWidth-1);
  signal Write_Address : std_logic_vector(0 to AddrWidth-1);

  -- signal read_addr_ptr      : natural;
  -- signal write_addr_ptr     : natural;

  component SRL_FIFO is
    generic (
      C_DATA_BITS : integer;
      C_DEPTH     : integer);
    port (
      Clk         : in  std_logic;
      Reset       : in  std_logic;
      FIFO_Write  : in  std_logic;
      Data_In     : in  std_logic_vector(0 to C_DATA_BITS-1);
      FIFO_Read   : in  std_logic;
      Data_Out    : out std_logic_vector(0 to C_DATA_BITS-1);
      FIFO_Full   : out std_logic;
      -- FIFO_Half_Full  : out std_logic;
      -- FIFO_Half_Empty : out std_logic;
      Data_Exists : out std_logic);
  end component SRL_FIFO;

  component Sync_DPRAM is
    generic (
      C_DWIDTH : integer := 32;
      C_AWIDTH : integer := 16
      );    
    port (
      clk  : in  std_logic;
      we   : in  std_logic;
      a    : in  std_logic_vector(C_AWIDTH-1 downto 0);
      dpra : in  std_logic_vector(C_AWIDTH-1 downto 0);
      di   : in  std_logic_vector(C_DWIDTH-1 downto 0);
      spo  : out std_logic_vector(C_DWIDTH-1 downto 0);
      dpo  : out std_logic_vector(C_DWIDTH-1 downto 0)
      ); 
  end component;

  component Sync_BRAM is
    generic (
      C_DWIDTH : integer := 32;
      C_AWIDTH : integer := 16
      );    
    port (
      clk     : in  std_logic;
      -- Write port
      we      : in  std_logic;
      a       : in  std_logic_vector(C_AWIDTH-1 downto 0);
      di      : in  std_logic_vector(C_DWIDTH-1 downto 0);
      spo     : out std_logic_vector(C_DWIDTH-1 downto 0);
      -- Read port
      dpra_en : in  std_logic;
      dpra    : in  std_logic_vector(C_AWIDTH-1 downto 0);
      dpo     : out std_logic_vector(C_DWIDTH-1 downto 0)
      ); 
  end component;

  signal read_bram_enable : std_logic;

  
begin

  FSL_Flag_Handle : if ((MemSize > 16) or (C_IMPL_STYLE /= 0)) generate
    signal read_addr_ptr  : natural range 0 to MemSize-1;
    signal write_addr_ptr : natural range 0 to MemSize-1;

    signal full_i                    : std_logic;
    signal exists_i                  : std_logic;
    signal read_addr_incr            : std_logic;
    signal first_write_on_empty_fifo : std_logic;
    signal last_word                 : std_logic;

    signal fifo_length : natural range 0 to MemSize;
  begin

    -- FIFO length handling
    Fifo_Length_Handle : process (Clk)
    begin
      if (Clk'event and Clk = '1') then
        if (Reset = '1') then
          fifo_length <= 0;
        else
          -- write and no read => increment length
          -- don't increment length when FULL
          if (WE = '1' and RD = '0' and full_i = '0') then
            fifo_length <= fifo_length + 1;
          -- read and no write => decrement length
          -- don't decrement length when EMPTY
          elsif (WE = '0' and RD = '1' and exists_i = '1') then
            fifo_length <= fifo_length - 1;
          end if;
        end if;
      end if;
    end process Fifo_Length_Handle;

    ---------------------------------------------------------------------------
    -- Need special handling for BRAM based fifo since there is one extra delay
    -- reading out data from it.
    -- We are pipelining the reading by making read_addr be one read ahead and
    -- are holding the data on the BRAM output by enabling/disabling the BRAM
    -- enable signal
    ---------------------------------------------------------------------------
    Rd_Delay_For_Bram : if (C_IMPL_STYLE /= 0) generate

      -------------------------------------------------------------------------
      -- Need to detect when writing into an empty FIFO, 
      -------------------------------------------------------------------------
      First_Write : process (Clk) is
      begin  -- process First_Write
        if Clk'event and Clk = '1' then  -- rising clock edge
          if Reset = '1' then            -- synchronous reset (active high)
            first_write_on_empty_fifo <= '0';
          else
            first_write_on_empty_fifo <= WE and not exists_i;
          end if;
        end if;
      end process First_Write;

      -------------------------------------------------------------------------
      -- Read out BRAM contents on the first word written in an empty FIFO and
      -- all other FIFO read except when the last word is read since the "real"
      -- FIFO is actually empty at this time since the last word is on the
      -- output of the BRAM
      -------------------------------------------------------------------------
      last_word        <= '1' when (fifo_length = 1) else '0';
      read_bram_enable <= first_write_on_empty_fifo or (RD and (not last_word or WE));

      read_addr_incr <= read_bram_enable;

      -------------------------------------------------------------------------
      -- The exists flag is now if the BRAM output has valid data and not the
      -- content of the FIFO
      -------------------------------------------------------------------------
      FIFO_Exists_DFF : process (Clk) is
      begin  -- process FIFO_Exists_DFF
        if Clk'event and Clk = '1' then  -- rising clock edge
          if Reset = '1' then            -- synchronous reset (active high)
            Exists <= '0';
          else
            if (first_write_on_empty_fifo = '1') then
              Exists <= '1';
            elsif ((RD = '1') and (WE = '0') and (last_word = '1')) then
              Exists <= '0';
            end if;
          end if;
        end if;
      end process FIFO_Exists_DFF;
    end generate Rd_Delay_For_Bram;

    Rd_No_Delay : if (C_IMPL_STYLE = 0) generate
      read_addr_incr <= RD;
      Exists         <= exists_i;
    end generate Rd_No_Delay;

    -- Set Full and empty flags
    full_i   <= '1' when (fifo_length = MemSize) else '0';
    exists_i <= '1' when (fifo_length /= 0)      else '0';

    Full <= full_i;

    -- Increment Read Address Pointer
    Read_Addr_Handle : process (Clk)
    begin
      if (Clk'event and Clk = '1') then
        if (Reset = '1') then
          read_addr_ptr <= 0;
        elsif (read_addr_incr = '1') then
          read_addr_ptr <= (read_addr_ptr + 1) mod (2 ** AddrWidth);
        end if;
      end if;
    end process Read_Addr_Handle;

    -- Increment Write Address Pointer
    Write_Addr_Handle : process (Clk)
    begin
      if (Clk'event and Clk = '1') then
        if (Reset = '1') then
          write_addr_ptr <= 0;
        elsif (WE = '1') then
          write_addr_ptr <= (write_addr_ptr + 1) mod (2 ** AddrWidth);
        end if;
      end if;
    end process Write_Addr_Handle;

    Write_Address <= std_logic_vector(to_unsigned(write_addr_ptr, AddrWidth));
    Read_Address  <= std_logic_vector(to_unsigned(read_addr_ptr, AddrWidth));
    
  end generate FSL_Flag_Handle;


  Sync_FIFO_I : if (C_IMPL_STYLE = 0) generate
    srl_fifo_i : if (MemSize <= 16) generate
      FSL_FIFO : SRL_FIFO
        generic map (
          C_DATA_BITS => WordSize,
          C_DEPTH     => MemSize)
        port map (
          Clk         => Clk,
          Reset       => Reset,
          FIFO_Write  => WE,            -- Master Write Signal
          Data_In     => DataIn,        -- Master Data
          FIFO_Read   => RD,            -- Slave Read Signal
          Data_Out    => DataOut,       -- Slave Data
          FIFO_Full   => Full,          -- FIFO full signal
          -- FIFO_Half_Full  => open,
          -- FIFO_Half_Empty => open,
          Data_Exists => Exists);       -- Slave Data exists      
    end generate srl_fifo_i;

    dpram_fifo_i : if (MemSize > 16) generate
      DPRAM_FIFO : SYNC_DPRAM
        generic map (
          C_DWIDTH => WordSize,
          C_AWIDTH => AddrWidth)
        port map (
          clk  => Clk,
          we   => WE,
          a    => Write_Address,
          dpra => Read_Address,
          di   => DataIn,
          spo  => open,
          dpo  => DataOut);
    end generate dpram_fifo_i;

  end generate Sync_FIFO_I;

  Sync_BRAM_FIFO : if (C_IMPL_STYLE /= 0) generate
    Sync_BRAM_I1 : Sync_BRAM
      generic map (
        C_DWIDTH => WordSize,           -- [integer]
        C_AWIDTH => AddrWidth)          -- [integer]
      port map (
        clk => Clk,                     -- [in  std_logic]

        -- Write port
        we  => WE,                      -- [in  std_logic]
        a   => Write_Address,  -- [in  std_logic_vector(C_AWIDTH-1 downto 0)]
        di  => DataIn,         -- [in  std_logic_vector(C_DWIDTH-1 downto 0)]
        spo => open,           -- [out std_logic_vector(C_DWIDTH-1 downto 0)]

        -- Read port
        dpra_en => read_bram_enable,    -- [in  std_logic]
        dpra    => Read_Address,  -- [in  std_logic_vector(C_AWIDTH-1 downto 0)]
        dpo     => DataOut);  -- [out std_logic_vector(C_DWIDTH-1 downto 0)]
  end generate Sync_BRAM_FIFO;
  
end VHDL_RTL;

