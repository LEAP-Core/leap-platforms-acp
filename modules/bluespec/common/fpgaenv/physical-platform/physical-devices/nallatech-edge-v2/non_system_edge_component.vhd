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
-- Title       : non_system_edge_component
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
use ieee.numeric_std.all;  


use work.edge_comp_defs_pkg.all;
use work.edge_comp_util_pkg.all;

entity non_system_edge_component is	
	generic(local_id:integer;
		local_module_type:integer;
		external_id:integer;
		rx_lanes:integer;
		tx_lanes:integer
		);
	port(
		clk100 : in STD_LOGIC;
		srst : in STD_LOGIC;
		link_complete : out STD_LOGIC;
		lvds_rx_lane_p : in std_logic_vector((17*rx_lanes)-1 downto 0);
		lvds_rx_lane_n : in std_logic_vector((17*rx_lanes)-1 downto 0);
		lvds_rx_clk_p : in std_logic_vector(rx_lanes-1 downto 0);
		lvds_rx_clk_n : in std_logic_vector(rx_lanes-1 downto 0);
		lvds_tx_lane_p : out std_logic_vector((17*tx_lanes)-1 downto 0);
		lvds_tx_lane_n : out std_logic_vector((17*tx_lanes)-1 downto 0);
		lvds_tx_clk_p : out std_logic_vector(tx_lanes-1 downto 0);
		lvds_tx_clk_n : out std_logic_vector(tx_lanes-1 downto 0); 
		lvds_link_sc_out : out STD_LOGIC_VECTOR(4 downto 0);
		lvds_link_sc_in : in STD_LOGIC_VECTOR(4 downto 0);
		lvds_comms_control : inout STD_LOGIC_VECTOR(47 downto 0);
		
		sys_clk : in STD_LOGIC;
		tx_data_valid : in STD_LOGIC;
		tx_data : in STD_LOGIC_VECTOR(255 downto 0);
		tx_data_almost_full : out STD_LOGIC;
		rx_data_read : in STD_LOGIC;
		rx_data_empty : out STD_LOGIC;
		rx_data_valid : out STD_LOGIC;
		rx_data : out STD_LOGIC_VECTOR(255 downto 0)
		);
end non_system_edge_component;


architecture rtl of non_system_edge_component is 
	
	constant edge_type:edge_type_t:=determine_non_system_edge_component(local_id=>local_id, local_module_type=>local_module_type,
	external_id=>external_id, rx_lanes=>rx_lanes, tx_lanes=>tx_lanes);
	
begin
	
	
	assert edge_type/=not_valid 
	report "Error no appropraite edge component found, check generics" severity failure;
	
	
	inter_intra_mod_slv_edge_4rx0tx_gen:if edge_type=inter_intra_mod_slv_edge_4rx0tx_t generate
		
		assert false report "generating inter_intra_mod_slv_edge_4rx0tx edge" severity note;
		
		edge_inst : inter_intra_mod_slv_edge_4rx0tx
		port map(
			clk100 => clk100,
			srst => srst,
			link_complete => link_complete,
			lvds_rx_lane_p => lvds_rx_lane_p,
			lvds_rx_lane_n => lvds_rx_lane_n,
			lvds_rx_clk_p => lvds_rx_clk_p,
			lvds_rx_clk_n => lvds_rx_clk_n,
			lvds_comms_control => lvds_comms_control,
			lvds_link_sc_out => lvds_link_sc_out,
			lvds_link_sc_in => lvds_link_sc_in,
			sys_clk => sys_clk,
			tx_data_valid => tx_data_valid,
			tx_data => tx_data,
			tx_data_almost_full => tx_data_almost_full,
			rx_data_read => rx_data_read,
			rx_data_empty => rx_data_empty,
			rx_data_valid => rx_data_valid,
			rx_data => rx_data
			);
		
	end generate;  
	
	inter_intra_mod_mst_edge_0rx4tx_gen:if edge_type=inter_intra_mod_mst_edge_0rx4tx_t generate
		
		assert false report "generating inter_intra_mod_mst_edge_0rx4tx edge" severity note;
		
		edge_inst : inter_intra_mod_mst_edge_0rx4tx
		port map(
			clk100 => clk100,
			srst => srst,
			link_complete => link_complete,
			lvds_tx_lane_p => lvds_tx_lane_p,
			lvds_tx_lane_n => lvds_tx_lane_n,
			lvds_tx_clk_p => lvds_tx_clk_p,
			lvds_tx_clk_n => lvds_tx_clk_n,
			lvds_comms_control => lvds_comms_control,
			lvds_link_sc_out => lvds_link_sc_out,
			lvds_link_sc_in => lvds_link_sc_in,
			sys_clk => sys_clk,
			tx_data_valid => tx_data_valid,
			tx_data => tx_data,
			tx_data_almost_full => tx_data_almost_full,
			rx_data_read => rx_data_read,
			rx_data_empty => rx_data_empty,
			rx_data_valid => rx_data_valid,
			rx_data => rx_data
			);
		
	end generate;
	
	inter_intra_mod_mst_edge_2rx2tx_gen:if edge_type=inter_intra_mod_mst_edge_2rx2tx_t generate
		
		assert false report "generating inter_intra_mod_mst_edge_2rx2tx edge" severity note;
		
		edge_inst : inter_intra_mod_mst_edge_2rx2tx
		port map(
			clk100 => clk100,
			srst => srst,
			link_complete => link_complete,
			lvds_tx_lane_p => lvds_tx_lane_p,
			lvds_tx_lane_n => lvds_tx_lane_n,
			lvds_tx_clk_p => lvds_tx_clk_p,
			lvds_tx_clk_n => lvds_tx_clk_n,
			lvds_rx_lane_p => lvds_rx_lane_p,
			lvds_rx_lane_n => lvds_rx_lane_n,
			lvds_rx_clk_p => lvds_rx_clk_p,
			lvds_rx_clk_n => lvds_rx_clk_n,
			lvds_comms_control => lvds_comms_control,
			lvds_link_sc_out => lvds_link_sc_out,
			lvds_link_sc_in => lvds_link_sc_in,
			sys_clk => sys_clk,
			tx_data_valid => tx_data_valid,
			tx_data => tx_data,
			tx_data_almost_full => tx_data_almost_full,
			rx_data_read => rx_data_read,
			rx_data_empty => rx_data_empty,
			rx_data_valid => rx_data_valid,
			rx_data => rx_data
			);
		
	end generate;	
	
	inter_intra_mod_slvt_edge_2rx2tx_gen:if edge_type=inter_intra_mod_slv_edge_2rx2tx_t generate
		
		assert false report "generating inter_intra_mod_slv_edge_2rx2tx edge" severity note;
		
		edge_inst : inter_intra_mod_slv_edge_2rx2tx
		port map(
			clk100 => clk100,
			srst => srst,
			link_complete => link_complete,
			lvds_tx_lane_p => lvds_tx_lane_p,
			lvds_tx_lane_n => lvds_tx_lane_n,
			lvds_tx_clk_p => lvds_tx_clk_p,
			lvds_tx_clk_n => lvds_tx_clk_n,
			lvds_rx_lane_p => lvds_rx_lane_p,
			lvds_rx_lane_n => lvds_rx_lane_n,
			lvds_rx_clk_p => lvds_rx_clk_p,
			lvds_rx_clk_n => lvds_rx_clk_n,
			lvds_comms_control => lvds_comms_control,
			lvds_link_sc_out => lvds_link_sc_out,
			lvds_link_sc_in => lvds_link_sc_in,
			sys_clk => sys_clk,
			tx_data_valid => tx_data_valid,
			tx_data => tx_data,
			tx_data_almost_full => tx_data_almost_full,
			rx_data_read => rx_data_read,
			rx_data_empty => rx_data_empty,
			rx_data_valid => rx_data_valid,
			rx_data => rx_data
			);
		
	end generate;
	
	
	
	
end rtl;
