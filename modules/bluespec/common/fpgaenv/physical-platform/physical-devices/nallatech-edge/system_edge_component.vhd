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
-- Title       : system_edge_component
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

entity system_edge_component is
	generic(local_id:integer;
		local_module_type:integer;
		external_id:integer;
		rx_lanes:integer;
		tx_lanes:integer
		);
	port(					   
		clk100p:in std_logic;
		clk100n:in std_logic;
		
		--expansion bus interface
		reg_clk:in std_logic;
		reg_reset_z:in std_logic;
		config_data:inout std_logic_vector(7 downto 0);
		reg_uds_z:in std_logic;
		reg_lds_z:in std_logic;
		reg_ads_z:in std_logic;
		reg_en_z:in std_logic;
		reg_rdy_z:out std_logic;
		reg_rd_wr_z:in std_logic;
		
		
		
		--high speed lvds downto the m2b
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
		
		
		intra_mod_lvds_comms_control:inout std_logic_vector(47 downto 0);
		upper_mod_lvds_comms_control:inout std_logic_vector(47 downto 0);
		
		--serial eeprom interface
		eeprom_scl:out std_logic;
		eeprom_sda:inout std_logic;	
		
		sys_led_out:out std_logic_vector(5 downto 0);
		ram_leds:out std_logic_vector(1 downto 0);
		ram_pwr_on:out std_logic;
		ram_pg:in std_logic;
		mgt_pg:in std_logic;
		
		-----------------------------------------------------------------------
		--user interface
		
		--ram clocks 
		osc_clk:out std_logic;
		clk200mhz:out std_logic;
		clk200mhz_locked:out std_logic; 
		
		
		--user reg clocks 
		user_reg_clk:out std_logic;
		user_interupt : in std_logic_vector(3 downto 0);
		user_reg_wdata : out std_logic_vector(15 downto 0);
		user_reg_addr : out std_logic_vector(12 downto 0);
		user_reg_rden : out std_logic_vector(3 downto 0);
		user_reg_wren : out std_logic_vector(3 downto 0);
		user_reg_rdy:in std_logic_vector(3 downto 0);
		user_reg_rdata0 : in std_logic_vector(15 downto 0);
		user_reg_rdata1 : in std_logic_vector(15 downto 0);
		user_reg_rdata2 : in std_logic_vector(15 downto 0);
		user_reg_rdata3 : in std_logic_vector(15 downto 0);
		
		--afu interface
		clk : in std_logic;	 
		
		tx_data_valid : in std_logic;
		tx_data : in std_logic_vector(255 downto 0);
		tx_data_almost_full : out std_logic;
		
		rx_data_read:in std_logic;
		rx_data_empty:out std_logic; 
		rx_data_valid:out std_logic;
		rx_data : out std_logic_vector(255 downto 0);
		
		
		sysmon_alarm:out std_logic_vector(3 downto 0);
		leds:in std_logic_vector(3 downto 0)
		
		);
end system_edge_component;


architecture rtl of system_edge_component is	 
	
	constant edge_type:edge_type_t:=determine_system_edge_component(local_id=>local_id, local_module_type=>local_module_type,
	external_id=>external_id, rx_lanes=>rx_lanes, tx_lanes=>tx_lanes);

begin

	
	assert edge_type/=not_valid 
	report "Error no appropraite edge component found, check generics" severity failure;
		
		
	comp_0_base_edge_2rx2tx_gen:if edge_type=comp_0_base_edge_2rx2tx_t generate
		
		assert false report "generating comp_0_base_edge_2rx2tx edge" severity note;
		
		base_edge_inst : comp_0_base_edge_2rx2tx
	port map(
		clk100p => clk100p,
		clk100n => clk100n,
		reg_clk => reg_clk,
		reg_reset_z => reg_reset_z,
		config_data => config_data,
		reg_uds_z => reg_uds_z,
		reg_lds_z => reg_lds_z,
		reg_ads_z => reg_ads_z,
		reg_en_z => reg_en_z,
		reg_rdy_z => reg_rdy_z,
		reg_rd_wr_z => reg_rd_wr_z,
		lvds_rx_lane_p => lvds_rx_lane_p,
		lvds_rx_lane_n => lvds_rx_lane_n,
		lvds_rx_clk_p => lvds_rx_clk_p,
		lvds_rx_clk_n => lvds_rx_clk_n,
		lvds_tx_lane_p => lvds_tx_lane_p,
		lvds_tx_lane_n => lvds_tx_lane_n,
		lvds_tx_clk_p => lvds_tx_clk_p,
		lvds_tx_clk_n => lvds_tx_clk_n,
		intra_mod_lvds_comms_control => intra_mod_lvds_comms_control,
		upper_mod_lvds_comms_control => upper_mod_lvds_comms_control,
		eeprom_scl => eeprom_scl,
		eeprom_sda => eeprom_sda,
		sys_led_out => sys_led_out,
		ram_leds => ram_leds,
		ram_pwr_on => ram_pwr_on,
		ram_pg => ram_pg,
		mgt_pg => mgt_pg,
		osc_clk => osc_clk,
		clk200mhz => clk200mhz,
		clk200mhz_locked => clk200mhz_locked,
		user_reg_clk => user_reg_clk,
		user_interupt => user_interupt,
		user_reg_wdata => user_reg_wdata,
		user_reg_addr => user_reg_addr,
		user_reg_rden => user_reg_rden,
		user_reg_wren => user_reg_wren,
		user_reg_rdy => user_reg_rdy,
		user_reg_rdata0 => user_reg_rdata0,
		user_reg_rdata1 => user_reg_rdata1,
		user_reg_rdata2 => user_reg_rdata2,
		user_reg_rdata3 => user_reg_rdata3,
		clk => clk,
		tx_data_valid => tx_data_valid,
		tx_data => tx_data,
		tx_data_almost_full => tx_data_almost_full,
		rx_data_read => rx_data_read,
		rx_data_empty => rx_data_empty,
		rx_data_valid => rx_data_valid,
		rx_data => rx_data,
		sysmon_alarm => sysmon_alarm,
		leds => leds
	);
		
	end generate;  
	
	
	
	comp_0_base_edge_4rx0tx_gen:if edge_type=comp_0_base_edge_4rx0tx_t generate	 

			assert false report "generating comp_0_base_edge_4rx0tx edge" severity note;
		

		 base_edge_inst : comp_0_base_edge_4rx0tx
	port map(
		clk100p => clk100p,
		clk100n => clk100n,
		reg_clk => reg_clk,
		reg_reset_z => reg_reset_z,
		config_data => config_data,
		reg_uds_z => reg_uds_z,
		reg_lds_z => reg_lds_z,
		reg_ads_z => reg_ads_z,
		reg_en_z => reg_en_z,
		reg_rdy_z => reg_rdy_z,
		reg_rd_wr_z => reg_rd_wr_z,
		lvds_rx_lane_p => lvds_rx_lane_p,
		lvds_rx_lane_n => lvds_rx_lane_n,
		lvds_rx_clk_p => lvds_rx_clk_p,
		lvds_rx_clk_n => lvds_rx_clk_n,
		lvds_link_sc_out => lvds_link_sc_out,
		lvds_link_sc_in => lvds_link_sc_in,
		intra_mod_lvds_comms_control => intra_mod_lvds_comms_control,
		upper_mod_lvds_comms_control => upper_mod_lvds_comms_control,
		eeprom_scl => eeprom_scl,
		eeprom_sda => eeprom_sda,
		sys_led_out => sys_led_out,
		ram_leds => ram_leds,
		ram_pwr_on => ram_pwr_on,
		ram_pg => ram_pg,
		mgt_pg => mgt_pg,
		osc_clk => osc_clk,
		clk200mhz => clk200mhz,
		clk200mhz_locked => clk200mhz_locked,
		user_reg_clk => user_reg_clk,
		user_interupt => user_interupt,
		user_reg_wdata => user_reg_wdata,
		user_reg_addr => user_reg_addr,
		user_reg_rden => user_reg_rden,
		user_reg_wren => user_reg_wren,
		user_reg_rdy => user_reg_rdy,
		user_reg_rdata0 => user_reg_rdata0,
		user_reg_rdata1 => user_reg_rdata1,
		user_reg_rdata2 => user_reg_rdata2,
		user_reg_rdata3 => user_reg_rdata3,
		clk => clk,
		tx_data_valid => tx_data_valid,
		tx_data => tx_data,
		tx_data_almost_full => tx_data_almost_full,
		rx_data_read => rx_data_read,
		rx_data_empty => rx_data_empty,
		rx_data_valid => rx_data_valid,
		rx_data => rx_data,
		sysmon_alarm => sysmon_alarm,
		leds => leds
	);
	
	end generate;
	
	
	
	comp_1_base_edge_0rx4tx_t_gen:if edge_type= comp_1_base_edge_0rx4tx_t generate
		
		assert false report "generating comp_1_base_edge_0rx4tx edge" severity note;
		
		
		base_edge_inst : comp_1_base_edge_0rx4tx
	port map(
		clk100p => clk100p,
		clk100n => clk100n,
		reg_clk => reg_clk,
		reg_reset_z => reg_reset_z,
		config_data => config_data,
		reg_uds_z => reg_uds_z,
		reg_lds_z => reg_lds_z,
		reg_ads_z => reg_ads_z,
		reg_en_z => reg_en_z,
		reg_rdy_z => reg_rdy_z,
		reg_rd_wr_z => reg_rd_wr_z,
		lvds_tx_lane_p => lvds_tx_lane_p,
		lvds_tx_lane_n => lvds_tx_lane_n,
		lvds_tx_clk_p => lvds_tx_clk_p,
		lvds_tx_clk_n => lvds_tx_clk_n,
		lvds_link_sc_out => lvds_link_sc_out,
		lvds_link_sc_in => lvds_link_sc_in,
		intra_mod_lvds_comms_control => intra_mod_lvds_comms_control,
		upper_mod_lvds_comms_control => upper_mod_lvds_comms_control,
		eeprom_scl => eeprom_scl,
		eeprom_sda => eeprom_sda,
		sys_led_out => sys_led_out,
		ram_leds => ram_leds,
		ram_pwr_on => ram_pwr_on,
		ram_pg => ram_pg,
		mgt_pg => mgt_pg,
		osc_clk => osc_clk,
		clk200mhz => clk200mhz,
		clk200mhz_locked => clk200mhz_locked,
		user_reg_clk => user_reg_clk,
		user_interupt => user_interupt,
		user_reg_wdata => user_reg_wdata,
		user_reg_addr => user_reg_addr,
		user_reg_rden => user_reg_rden,
		user_reg_wren => user_reg_wren,
		user_reg_rdy => user_reg_rdy,
		user_reg_rdata0 => user_reg_rdata0,
		user_reg_rdata1 => user_reg_rdata1,
		user_reg_rdata2 => user_reg_rdata2,
		user_reg_rdata3 => user_reg_rdata3,
		clk => clk,
		tx_data_valid => tx_data_valid,
		tx_data => tx_data,
		tx_data_almost_full => tx_data_almost_full,
		rx_data_read => rx_data_read,
		rx_data_empty => rx_data_empty,
		rx_data_valid => rx_data_valid,
		rx_data => rx_data,
		sysmon_alarm => sysmon_alarm,
		leds => leds
	);
	
	end generate comp_1_base_edge_0rx4tx_t_gen;
	
	
	
	exp_0_base_edge_4rx2tx_t_gen:if edge_type=exp_0_base_edge_4rx2tx_t generate
		
		assert false report "generating exp_0_base_edge_4rx2tx edge" severity note;
		
		
		 base_edge_inst : exp_0_base_edge_4rx2tx
	port map(
		clk100p => clk100p,
		clk100n => clk100n,
		reg_clk => reg_clk,
		reg_reset_z => reg_reset_z,
		config_data => config_data,
		reg_uds_z => reg_uds_z,
		reg_lds_z => reg_lds_z,
		reg_ads_z => reg_ads_z,
		reg_en_z => reg_en_z,
		reg_rdy_z => reg_rdy_z,
		reg_rd_wr_z => reg_rd_wr_z,
		lvds_rx_lane_p => lvds_rx_lane_p,
		lvds_rx_lane_n => lvds_rx_lane_n,
		lvds_rx_clk_p => lvds_rx_clk_p,
		lvds_rx_clk_n => lvds_rx_clk_n,
		lvds_tx_lane_p => lvds_tx_lane_p,
		lvds_tx_lane_n => lvds_tx_lane_n,
		lvds_tx_clk_p => lvds_tx_clk_p,
		lvds_tx_clk_n => lvds_tx_clk_n,
		eeprom_scl => eeprom_scl,
		eeprom_sda => eeprom_sda,
		sys_led_out => sys_led_out,
		ram_pwr_on => ram_pwr_on,
		ram_pg => ram_pg,
		mgt_pg => mgt_pg,
		osc_clk => osc_clk,
		clk200mhz => clk200mhz,
		clk200mhz_locked => clk200mhz_locked,
		user_reg_clk => user_reg_clk,
		user_interupt => user_interupt,
		user_reg_wdata => user_reg_wdata,
		user_reg_addr => user_reg_addr,
		user_reg_rden => user_reg_rden,
		user_reg_wren => user_reg_wren,
		user_reg_rdy => user_reg_rdy,
		user_reg_rdata0 => user_reg_rdata0,
		user_reg_rdata1 => user_reg_rdata1,
		user_reg_rdata2 => user_reg_rdata2,
		user_reg_rdata3 => user_reg_rdata3,
		clk => clk,
		tx_data_valid => tx_data_valid,
		tx_data => tx_data,
		tx_data_almost_full => tx_data_almost_full,
		rx_data_read => rx_data_read,
		rx_data_empty => rx_data_empty,
		rx_data_valid => rx_data_valid,
		rx_data => rx_data,
		sysmon_alarm => sysmon_alarm,
		leds => leds
	);
		
	end generate exp_0_base_edge_4rx2tx_t_gen;	  
	
	
	exp_0_sys_edge_2rx2tx_t_gen:if edge_type = exp_0_sys_edge_2rx2tx_t generate
	
		assert false report "generating exp_0_sys_edge_2rx2tx edge" severity note;
		
		base_edge_inst : exp_0_inter_sys_edge_2rx2tx
	port map(
		clk100p => clk100p,
		clk100n => clk100n,
		reg_clk => reg_clk,
		reg_reset_z => reg_reset_z,
		config_data => config_data,
		reg_uds_z => reg_uds_z,
		reg_lds_z => reg_lds_z,
		reg_ads_z => reg_ads_z,
		reg_en_z => reg_en_z,
		reg_rdy_z => reg_rdy_z,
		reg_rd_wr_z => reg_rd_wr_z,
		lvds_rx_lane_p => lvds_rx_lane_p,
		lvds_rx_lane_n => lvds_rx_lane_n,
		lvds_rx_clk_p => lvds_rx_clk_p,
		lvds_rx_clk_n => lvds_rx_clk_n,
		lvds_tx_lane_p => lvds_tx_lane_p,
		lvds_tx_lane_n => lvds_tx_lane_n,
		lvds_tx_clk_p => lvds_tx_clk_p,
		lvds_tx_clk_n => lvds_tx_clk_n,
		intra_mod_lvds_comms_control => intra_mod_lvds_comms_control,
		upper_mod_lvds_comms_control => upper_mod_lvds_comms_control,
		eeprom_scl => eeprom_scl,
		eeprom_sda => eeprom_sda,
		sys_led_out => sys_led_out,
		ram_leds => ram_leds,
		ram_pwr_on => ram_pwr_on,
		ram_pg => ram_pg,
		mgt_pg => mgt_pg,
		osc_clk => osc_clk,
		clk200mhz => clk200mhz,
		clk200mhz_locked => clk200mhz_locked,
		user_reg_clk => user_reg_clk,
		user_interupt => user_interupt,
		user_reg_wdata => user_reg_wdata,
		user_reg_addr => user_reg_addr,
		user_reg_rden => user_reg_rden,
		user_reg_wren => user_reg_wren,
		user_reg_rdy => user_reg_rdy,
		user_reg_rdata0 => user_reg_rdata0,
		user_reg_rdata1 => user_reg_rdata1,
		user_reg_rdata2 => user_reg_rdata2,
		user_reg_rdata3 => user_reg_rdata3,
		clk => clk,
		tx_data_valid => tx_data_valid,
		tx_data => tx_data,
		tx_data_almost_full => tx_data_almost_full,
		rx_data_read => rx_data_read,
		rx_data_empty => rx_data_empty,
		rx_data_valid => rx_data_valid,
		rx_data => rx_data,
		sysmon_alarm => sysmon_alarm,
		leds => leds
	);
		
	end generate exp_0_sys_edge_2rx2tx_t_gen;
	
	
	sys_edge_0rx0tx_t_gen:if edge_type = sys_edge_0rx0tx_t generate
	
		assert false report "generating sys_edge_0rx0tx edge" severity note;
		
		base_edge_inst : sys_edge_0rx0tx
	port map(
		clk100p => clk100p,
		clk100n => clk100n,
		reg_clk => reg_clk,
		reg_reset_z => reg_reset_z,
		config_data => config_data,
		reg_uds_z => reg_uds_z,
		reg_lds_z => reg_lds_z,
		reg_ads_z => reg_ads_z,
		reg_en_z => reg_en_z,
		reg_rdy_z => reg_rdy_z,
		reg_rd_wr_z => reg_rd_wr_z,
		intra_mod_lvds_comms_control => intra_mod_lvds_comms_control,
		upper_mod_lvds_comms_control => upper_mod_lvds_comms_control,
		eeprom_scl => eeprom_scl,
		eeprom_sda => eeprom_sda,
		sys_led_out => sys_led_out,
		ram_leds => ram_leds,
		ram_pwr_on => ram_pwr_on,
		ram_pg => ram_pg,
		mgt_pg => mgt_pg,
		osc_clk => osc_clk,
		clk200mhz => clk200mhz,
		clk200mhz_locked => clk200mhz_locked,
		user_reg_clk => user_reg_clk,
		user_interupt => user_interupt,
		user_reg_wdata => user_reg_wdata,
		user_reg_addr => user_reg_addr,
		user_reg_rden => user_reg_rden,
		user_reg_wren => user_reg_wren,
		user_reg_rdy => user_reg_rdy,
		user_reg_rdata0 => user_reg_rdata0,
		user_reg_rdata1 => user_reg_rdata1,
		user_reg_rdata2 => user_reg_rdata2,
		user_reg_rdata3 => user_reg_rdata3,
		sysmon_alarm => sysmon_alarm,
		leds => leds
	);
		
	end generate;
	
	
	
end rtl;
