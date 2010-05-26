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
-- Title       : usr_reg_slave_if_io_example
-- Project     : m2e
--------------------------------------------------------------------------------
-- Description : This module provides an example of controlling IO using the 
-- register slave interface. 2 registers are provided: 
--
-- addr 0: LED enable mask - each bit defining wether the led is to be enabled 
--							 or not
-- addr 1: LED sequence    - vector defining the sequence to be adopted,
--					         0 for flashing
--						     1 for count
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

entity usr_reg_slave_if_io_example is
	port(
		-------------------------------
		--user register slave port
		clk:in std_logic;
		user_reg_wdata:in  std_logic_vector(15 downto 0);
		user_reg_addr:in std_logic_vector(12 downto 0);
		user_reg_rden:in std_logic;
		user_reg_wren:in std_logic;
		user_reg_rdata:out std_logic_vector(15 downto 0);
		user_reg_rdy:out std_logic;
		
		-------------------------------
		--for connection to the user led port
		leds:out std_logic_vector(3 downto 0)
		);
end usr_reg_slave_if_io_example;


architecture rtl of usr_reg_slave_if_io_example is
	
	---------------------------------------------------------------------------
	--define the registers used to control the led output	
	constant LED_ENABLE_MASK_ADDR:std_logic_vector(12 downto 0):='0' & x"000";
	signal led_enable_mask_reg:std_logic_vector(15 downto 0); 
	
	constant LED_SEQUENCE_ADDR:std_logic_vector(12 downto 0):='0' & x"001";
	signal led_sequence_reg:std_logic_vector(15 downto 0);
	
	---------------------------------------------------------------------------
	--define the count used for LED sequence
	signal led_seq_cnt:unsigned(25 downto 0);	   
	

begin
	
	---------------------------------------------------------------------------
	--process to manage memory mapped registers. These registers are writable 
	--and readable
	address_decode_proc:process(clk)
	begin
		if rising_edge(clk) then
			
			--decode the address to see which register is being accessed
			--then write to register if user_reg_wren is high . Always
			--read the register onto the user_rdata bus but only validate
			--if user_reg_rden is high
			
			if user_reg_addr = LED_ENABLE_MASK_ADDR then
					if user_reg_wren='1' then
						led_enable_mask_reg<=user_reg_wdata;
					end if;	
					
					user_reg_rdata<=led_enable_mask_reg;
					
					
					
			elsif user_reg_addr = LED_SEQUENCE_ADDR then
					
					if user_reg_wren='1' then
						led_sequence_reg<=user_reg_wdata;
					end if;
					
					user_reg_rdata<=led_sequence_reg;
					
			end if;
			
			--acknowledge write operation or validate the read by asserting the
			--user_reg_rdy signal. Do this for all transactions even if address
			--is not valid to ensure no deadlock situation exists where the 
			--software is waiting to get a response to a register which it has 
			--incorrectly addressed
			user_reg_rdy<=user_reg_rden or user_reg_wren;
			
		end if;
	end process;
	
	---------------------------------------------------------------------------
	--process to define what happens to the led outputs
	led_ouptut_proc:process(clk)					   
	begin
		if rising_edge(clk) then
			
			led_seq_cnt<=led_seq_cnt+1;
			
			if led_sequence_reg=x"0000" then				 
				--assign each led to the 3rd most significant bit if enabled
				for n in leds'range loop
					leds(n)<=led_seq_cnt(led_seq_cnt'left-2) and led_enable_mask_reg(n);
				end loop; 
				
				
			elsif led_sequence_reg=x"0001" then	
				--assign the leds to the top bits of the counter if enabled
				for n in leds'range loop 
					leds(n)<=led_seq_cnt(led_seq_cnt'left-n) and led_enable_mask_reg(n);
				end loop;
			else
				--force leds low if not one of the above sequences
				leds<=(others=>'0');
			end if;
			
		end if;	
	end process;
	
	
	
	
	
	
end rtl;
