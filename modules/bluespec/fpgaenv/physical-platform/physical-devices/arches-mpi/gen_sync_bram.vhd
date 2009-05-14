-------------------------------------------------------------------------------
-- $Id: gen_sync_bram.vhd,v 1.2 2007/05/23 11:41:41 goran Exp $
-------------------------------------------------------------------------------
-- gen_sync_bram.vhd - Entity and architecture
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
-- Description:
-- Code to infer synchronous dual port bram and separate read/write clock dual
-- port bram
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity Sync_BRAM is
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
end Sync_BRAM;

architecture syn of Sync_BRAM is 
  type ram_type is array ((2**C_AWIDTH)-1 downto 0) of std_logic_vector ((C_DWIDTH-1) downto 0); 
  -- signal ram_mem : ram_type := (others => (others => '0')); 
  signal ram_mem : ram_type;
  signal read_a : std_logic_vector(C_AWIDTH-1 downto 0); 
  signal read_dpra : std_logic_vector(C_AWIDTH-1 downto 0); 
begin 
  process (clk) 
  begin 
    if (clk'event and clk = '1') then 
      if (we = '1') then 
        ram_mem(conv_integer(a)) <= di; 
      end if; 
      read_a <= a;
      if (dpra_en = '1') then
        read_dpra <= dpra;         
      end if;
    end if; 
  end process; 
  spo <= ram_mem(conv_integer(read_a)); 
  dpo <= ram_mem(conv_integer(read_dpra)); 
end syn; 



