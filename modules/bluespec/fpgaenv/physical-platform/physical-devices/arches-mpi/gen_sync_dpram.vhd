-------------------------------------------------------------------------------
-- $Id: gen_sync_dpram.vhd,v 1.1 2007/04/24 12:40:27 rolandp Exp $
-------------------------------------------------------------------------------
-- gen_sync_dpram.vhd - Entity and architecture
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
-- Revision:        $Revision: 1.1 $
-- Date:            $Date: 2007/04/24 12:40:27 $
--
-- History:
--   satish  2004-03-24    New Version
--
-- Description:
-- Code to infer synchronous dual port lut ram
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

entity Sync_DPRAM is 
  generic (
    C_DWIDTH : integer := 32;
    C_AWIDTH : integer := 16
    );    
  port ( 
    clk  : in std_logic; 
    we   : in std_logic; 
    a    : in std_logic_vector(C_AWIDTH-1 downto 0); 
    dpra : in std_logic_vector(C_AWIDTH-1 downto 0); 
    di   : in std_logic_vector(C_DWIDTH-1 downto 0); 
    spo  : out std_logic_vector(C_DWIDTH-1 downto 0); 
    dpo  : out std_logic_vector(C_DWIDTH-1 downto 0) 
    ); 
end Sync_DPRAM; 

architecture syn of Sync_DPRAM is 
  type ram_type is array ((2**C_AWIDTH)-1 downto 0) of std_logic_vector ((C_DWIDTH-1) downto 0); 
  -- signal RAM : ram_type := (others => (others => '0')); 
  signal RAM : ram_type;
begin 
  process (clk) 
    begin 
      if (clk'event and clk = '1') then 
          if (we = '1') then 
              RAM(conv_integer(a)) <= di; 
          end if; 
      end if; 
  end process; 
  spo <= RAM(conv_integer(a)); 
  dpo <= RAM(conv_integer(dpra)); 
end syn; 
