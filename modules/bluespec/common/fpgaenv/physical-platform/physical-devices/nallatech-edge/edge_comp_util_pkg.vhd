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
--      Copyright © 1998-2008 Nallatech Limited. All rights reserved.
--------------------------------------------------------------------------------
-- $Id$
--------------------------------------------------------------------------------
-- Title       : edge_comp_util_pkg
-- Project     : m2e
--------------------------------------------------------------------------------
-- Description : This module provides . . .
--
--
--------------------------------------------------------------------------------
-- Known Issues and Omissions:
--
--
--------------------------------------------------------------------------------



library IEEE;
use IEEE.STD_LOGIC_1164.all;  
use IEEE.numeric_std.all;

package edge_comp_util_pkg is	
	
	function DEVICE_ID(module:integer; fpga:integer; afu:integer) return integer;
	
	constant FSB_COMPUTE_MOD_TYPE:integer:=2;
	constant FSB_EXPANSION_MOD_TYPE:integer:=1;
	
	type edge_type_t is (comp_0_base_edge_2rx2tx_t,comp_0_base_edge_4rx0tx_t, comp_1_base_edge_0rx4tx_t,
	exp_0_base_edge_4rx2tx_t, exp_0_sys_edge_2rx2tx_t, sys_edge_0rx0tx_t, not_valid, inter_intra_mod_slv_edge_4rx0tx_t,
	inter_intra_mod_mst_edge_0rx4tx_t, inter_intra_mod_slv_edge_2rx2tx_t, inter_intra_mod_mst_edge_2rx2tx_t); 
	
	--functions to determine the layer and fpga from the device id used in software API
	function determine_layer(device_id:integer) return integer;
	function determine_fpga(device_id:integer) return integer;	 
	
	--function to determine system edge component
	function determine_system_edge_component(
		local_id:integer;
		local_module_type:integer;
		external_id:integer;
		rx_lanes:integer;
		tx_lanes:integer) return edge_type_t; 
		
		--function to determine system edge component
	function determine_non_system_edge_component(
		local_id:integer;
		local_module_type:integer;
		external_id:integer;
		rx_lanes:integer;
		tx_lanes:integer) return edge_type_t;
	
	
end package edge_comp_util_pkg;



package body edge_comp_util_pkg is
	
	
	
	function DEVICE_ID(module:integer; fpga:integer; afu:integer) return integer is
	variable module_un, fpga_un:unsigned(3 downto 0);
	variable afu_un:unsigned(7 downto 0);
	begin
		
		module_un:=to_unsigned(module,4);
		fpga_un:=to_unsigned(fpga,4);
		afu_un:=to_unsigned(afu,8);
		
		return to_integer(module_un & fpga_un & afu_un);
	end function DEVICE_ID;
	
	function determine_layer(device_id:integer) return integer is
		variable device_id_unsigned:unsigned(31 downto 0);
	begin
		device_id_unsigned:=to_unsigned(device_id,32);
		return to_integer(device_id_unsigned(15 downto 12));
	end function determine_layer;
	
	function determine_fpga(device_id:integer) return integer is
		variable device_id_unsigned:unsigned(31 downto 0);
	begin
		device_id_unsigned:=to_unsigned(device_id,32);
		return to_integer(device_id_unsigned(11 downto 8));
	end function determine_fpga;
	
	
	
	
	function determine_system_edge_component(
		local_id:integer;
		local_module_type:integer;
		external_id:integer;
		rx_lanes:integer;
		tx_lanes:integer) return edge_type_t is
		
		constant local_layer:integer:=determine_layer(local_id);
		constant local_fpga:integer:=determine_fpga(local_id);
		constant external_layer:integer:=determine_layer(external_id);
		constant external_fpga:integer:=determine_fpga(external_id);
		
	begin
		
		--are we talking about a base edge		
		if external_layer=0 then
			
			--check we are talking to fpag0 on base
			if external_fpga/=0 or local_layer=0  then
				
				report "external fpga id  or local layer is incorrect for base edge component" severity warning;
				return not_valid; 
				
			else
				if local_module_type=FSB_COMPUTE_MOD_TYPE then
					
					if local_fpga=0 then
						if rx_lanes=2 and tx_lanes=2  then
							return comp_0_base_edge_2rx2tx_t;
						elsif rx_lanes=4 and tx_lanes=0 then
							return comp_0_base_edge_4rx0tx_t; 
						elsif rx_lanes=0 and tx_lanes=0 then
							return sys_edge_0rx0tx_t;
						else
							report "no valid core found" severity warning;
							return not_valid;
						end if;
						
					elsif local_fpga=1 then
						if rx_lanes=0 and tx_lanes=4 then
							return comp_1_base_edge_0rx4tx_t;
						elsif rx_lanes=0 and tx_lanes=0 then
							return sys_edge_0rx0tx_t;
						else
							report "no valid core found" severity warning;
							return not_valid;
						end if;
					else
						report "FPGA id is incorrect" severity warning;
						return not_valid;
					end if;
					
				elsif local_module_type=FSB_EXPANSION_MOD_TYPE then
					
					if local_fpga=0 then
						
						if rx_lanes=4 and tx_lanes=2 then
							return exp_0_base_edge_4rx2tx_t;	
						elsif rx_lanes=0 and tx_lanes=0 then
							return sys_edge_0rx0tx_t;
						else
							report "no valid core found" severity warning;
							return not_valid;
						end if;
					else
						report "FPGA id is incorrect" severity warning;
						return not_valid;
					end if;
				else
					report "module type incorrect" severity warning;
					return not_valid;
				end if;
				
				
			end if;
			
			
		else
			
			--talking about a system edge
			if local_module_type=FSB_EXPANSION_MOD_TYPE then
				
				if local_fpga=0 then
					if rx_lanes=2 and tx_lanes=2 then
						return exp_0_sys_edge_2rx2tx_t;
					elsif rx_lanes=0 and tx_lanes=0 then
						return sys_edge_0rx0tx_t;
					else
						report "no valid core found" severity warning;
						return not_valid;
					end if;
				else
					report "FPGA id is incorrect" severity warning;
					return not_valid;
				end if;
			else
				report "module type incorrect" severity warning;
				return not_valid;
			end if; 
			
			
			
		end if;
		
	end function determine_system_edge_component; 
	
	
	
	function determine_non_system_edge_component(
		local_id:integer;
		local_module_type:integer;
		external_id:integer;
		rx_lanes:integer;
		tx_lanes:integer) return edge_type_t is
		
		constant local_layer:integer:=determine_layer(local_id);
		constant local_fpga:integer:=determine_fpga(local_id);
		constant external_layer:integer:=determine_layer(external_id);
		constant external_fpga:integer:=determine_fpga(external_id);
		
	begin
		
		if external_layer=0 then
			--should be a system edge component
				report "talking to layer 0 and so should be system edge" severity warning;
				return not_valid;
		end if;
		
		if local_layer=0 then
			--not valid
			report "invalid layer id" severity warning;
			return not_valid;
		end if;

		if rx_lanes=0 and tx_lanes=4 then
			
			return inter_intra_mod_mst_edge_0rx4tx_t;
		elsif rx_lanes=4 and tx_lanes=0 then
			
			return inter_intra_mod_slv_edge_4rx0tx_t;
		elsif rx_lanes=2 and tx_lanes=2 then
			
			--master to lower fpga and lower module in stack
			
		
				
			if local_layer<external_layer then
				return inter_intra_mod_slv_edge_2rx2tx_t;
			elsif local_layer=external_layer then
				
				if local_module_type=FSB_COMPUTE_MOD_TYPE then 
					if local_fpga=0 and external_fpga=1 then
				
						--want a master link
						return	inter_intra_mod_mst_edge_2rx2tx_t;
				
					elsif local_fpga=1 and external_fpga=0 then
						--want a slave link
						return inter_intra_mod_slv_edge_2rx2tx_t;
					else
						report "no valid core" severity warning;
						return not_valid;
					end if;
				else
					report "no valid core" severity warning;
				end if;
			else
				if local_module_type=FSB_COMPUTE_MOD_TYPE then
					return inter_intra_mod_mst_edge_2rx2tx_t;
				else
					report "no valid core" severity warning;
					return not_valid;
				end if;
			end if;
		else						 
			
			report "no valid core" severity warning;
		end if;
		
		end function determine_non_system_edge_component; 	
				
					
				
end package body edge_comp_util_pkg;
