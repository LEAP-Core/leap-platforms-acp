--------------------------------------------------------------------------------
--      Nallatech is providing this design, code, or information "as is".
--      solely for use on Nallatech systems and equipment.
--      By providing this design, code, or information
--      as one possible implementation of this feature, application
--      or standard, NALLATECH IS MAKING NO REPRESENTATION THAT THIS
--      IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,
--      AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE
--      FOR YOUR IMPLEMENTATION.  NALLATECH EXPRESSLY DISCLAIMS ANY
--      WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE
--      IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
--      REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF
--      INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
--      FOR A PARTICULAR PURPOSE.
--
--      USE OF SOFTWARE. This software contains elements of software code
--      which are the property of Nallatech Limited (Nallatech Software).
--      Use of the Nallatech Software by you is permitted only if you hold a
--      valid license from Nallatech Limited or a valid sub-license from a
--      licensee of Nallatech Limited. Use of such software shall be governed
--      by the terms of such license or sub-license agreement.
--      The Nallatech software is for use solely on Nallatech hardware
--      unless you hold a license permitting use on other hardware.
--
--      This Nallatech Software is protected by copyright law and
--      international treaties. Unauthorized reproduction or distribution of
--      this software, or any portion of it, may result in severe civil and
--      criminal penalties, and will be prosecuted to the maximum extent
--      possible under law. Nallatech products are covered by one or more
--      patents. Other US and international patents pending.
--      Please see www.nallatech.com for more information
--
--      Nallatech products are not intended for use in life support
--      appliances, devices, or systems. Use in such applications is
--      expressly prohibited.
--
--      Copyright © 1998-2009 Nallatech Limited. All rights reserved.
--------------------------------------------------------------------------------
-- $Id$
--------------------------------------------------------------------------------
-- Title       : usr_reg_slave_if_bram_example
-- Project     : m2e
--------------------------------------------------------------------------------
-- Description : This module provides a demonstration of connecting a 1kx16 
-- block ram to the user register slave interface
--
--
--------------------------------------------------------------------------------
-- Known Issues and Omissions:
--
--
--------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity usr_reg_slave_if_bram_example is	
	port(
	clk:in std_logic;
	user_reg_wdata:in  std_logic_vector(15 downto 0);
	user_reg_addr:in std_logic_vector(12 downto 0);
	user_reg_rden:in std_logic;
	user_reg_wren:in std_logic;
	user_reg_rdata:out std_logic_vector(15 downto 0);
	user_reg_rdy:out std_logic
	);
end usr_reg_slave_if_bram_example;



architecture rtl of usr_reg_slave_if_bram_example is

--define memory type and signal
type mem_t is array (natural range<>) of std_logic_vector(15 downto 0);
signal mem:mem_t(0 to 1023);


begin


	mem_proc:process(clk)
	begin
		if rising_edge(clk) then
			
			--write to memory when the write enable signal is sampled high
			if user_reg_wren='1' then
				mem(to_integer(unsigned(user_reg_addr(9 downto 0))))<=user_reg_wdata;
			end if;
			
			--always read the memory
			user_reg_rdata<=mem(to_integer(unsigned(user_reg_addr(9 downto 0))));
			
			--acknowledge write operation or validate the read by asserting the
			--user_reg_rdy signal
			user_reg_rdy<=user_reg_rden or user_reg_wren;
			
		end if;
	end process;
	


end rtl;
