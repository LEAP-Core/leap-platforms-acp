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
-- Title       : edge_comp_defs_pkg
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

package edge_comp_defs_pkg is	
	
	
	---------------------------------------------------------------------------
	--WRAPPER COMPONENTS
	
	-- Component declaration of the "system_edge_component(rtl)" unit defined in
	-- file: "./src/system_edge_component.vhd"
	component system_edge_component
	generic(
		local_id : INTEGER;
		local_module_type : INTEGER;
		external_id : INTEGER;
		rx_lanes : INTEGER;
		tx_lanes : INTEGER);
	port(
		clk100p : in STD_LOGIC;
		clk100n : in STD_LOGIC;
		reg_clk : in STD_LOGIC;
		reg_reset_z : in STD_LOGIC;
		config_data : inout STD_LOGIC_VECTOR(7 downto 0);
		reg_uds_z : in STD_LOGIC;
		reg_lds_z : in STD_LOGIC;
		reg_ads_z : in STD_LOGIC;
		reg_en_z : in STD_LOGIC;
		reg_rdy_z : out STD_LOGIC;
		reg_rd_wr_z : in STD_LOGIC;
		lvds_rx_lane_p : in STD_LOGIC_VECTOR((17*rx_lanes)-1 downto 0);
		lvds_rx_lane_n : in STD_LOGIC_VECTOR((17*rx_lanes)-1 downto 0);
		lvds_rx_clk_p : in STD_LOGIC_VECTOR(rx_lanes-1 downto 0);
		lvds_rx_clk_n : in STD_LOGIC_VECTOR(rx_lanes-1 downto 0);
		lvds_tx_lane_p : out STD_LOGIC_VECTOR((17*tx_lanes)-1 downto 0);
		lvds_tx_lane_n : out STD_LOGIC_VECTOR((17*tx_lanes)-1 downto 0);
		lvds_tx_clk_p : out STD_LOGIC_VECTOR(tx_lanes-1 downto 0);
		lvds_tx_clk_n : out STD_LOGIC_VECTOR(tx_lanes-1 downto 0);
		lvds_link_sc_out : out STD_LOGIC_VECTOR(4 downto 0);
		lvds_link_sc_in : in STD_LOGIC_VECTOR(4 downto 0);
		intra_mod_lvds_comms_control : inout STD_LOGIC_VECTOR(47 downto 0);
		upper_mod_lvds_comms_control : inout STD_LOGIC_VECTOR(47 downto 0);
		eeprom_scl : out STD_LOGIC;
		eeprom_sda : inout STD_LOGIC;
		sys_led_out : out STD_LOGIC_VECTOR(5 downto 0);
		ram_leds : out STD_LOGIC_VECTOR(1 downto 0);
		ram_pwr_on : out STD_LOGIC;
		ram_pg : in STD_LOGIC;
		mgt_pg : in STD_LOGIC;
		osc_clk : out STD_LOGIC;
		clk200mhz : out STD_LOGIC;
		clk200mhz_locked : out STD_LOGIC;
		user_reg_clk : out STD_LOGIC;
		user_interupt : in STD_LOGIC_VECTOR(3 downto 0);
		user_reg_wdata : out STD_LOGIC_VECTOR(15 downto 0);
		user_reg_addr : out STD_LOGIC_VECTOR(12 downto 0);
		user_reg_rden : out STD_LOGIC_VECTOR(3 downto 0);
		user_reg_wren : out STD_LOGIC_VECTOR(3 downto 0);
		user_reg_rdy : in STD_LOGIC_VECTOR(3 downto 0);
		user_reg_rdata0 : in STD_LOGIC_VECTOR(15 downto 0);
		user_reg_rdata1 : in STD_LOGIC_VECTOR(15 downto 0);
		user_reg_rdata2 : in STD_LOGIC_VECTOR(15 downto 0);
		user_reg_rdata3 : in STD_LOGIC_VECTOR(15 downto 0);
		clk : in STD_LOGIC;
		tx_data_valid : in STD_LOGIC;
		tx_data : in STD_LOGIC_VECTOR(255 downto 0);
		tx_data_almost_full : out STD_LOGIC;
		rx_data_read : in STD_LOGIC;
		rx_data_empty : out STD_LOGIC;
		rx_data_valid : out STD_LOGIC;
		rx_data : out STD_LOGIC_VECTOR(255 downto 0);
		sysmon_alarm : out STD_LOGIC_VECTOR(3 downto 0);
		leds : in STD_LOGIC_VECTOR(3 downto 0));
	end component;
	
		-- Component declaration of the "non_system_edge_component(rtl)" unit defined in
	-- file: "./src/non_system_edge_component.vhd"
	component non_system_edge_component
	generic(
		local_id : INTEGER;
		local_module_type : INTEGER;
		external_id : INTEGER;
		rx_lanes : INTEGER;
		tx_lanes : INTEGER);
	port(
		clk100 : in STD_LOGIC;
		srst : in STD_LOGIC;
		link_complete : out STD_LOGIC;
		lvds_rx_lane_p : in STD_LOGIC_VECTOR((17*rx_lanes)-1 downto 0);
		lvds_rx_lane_n : in STD_LOGIC_VECTOR((17*rx_lanes)-1 downto 0);
		lvds_rx_clk_p : in STD_LOGIC_VECTOR(rx_lanes-1 downto 0);
		lvds_rx_clk_n : in STD_LOGIC_VECTOR(rx_lanes-1 downto 0);
		lvds_tx_lane_p : out STD_LOGIC_VECTOR((17*tx_lanes)-1 downto 0);
		lvds_tx_lane_n : out STD_LOGIC_VECTOR((17*tx_lanes)-1 downto 0);
		lvds_tx_clk_p : out STD_LOGIC_VECTOR(tx_lanes-1 downto 0);
		lvds_tx_clk_n : out STD_LOGIC_VECTOR(tx_lanes-1 downto 0);
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
		rx_data : out STD_LOGIC_VECTOR(255 downto 0));
	end component;

	
	
	---------------------------------------------------------------------------
	--EDGE COMPONENTS
	
	
	-- Component declaration of the "comp_0_base_edge_4rx0tx(rtl)" unit defined in
	-- file: "./../../m2e/src/comp_0_base_edge_4rx0tx.vhd"
	component comp_0_base_edge_4rx0tx
	port(
		clk100p : in STD_LOGIC;
		clk100n : in STD_LOGIC;
		reg_clk : in STD_LOGIC;
		reg_reset_z : in STD_LOGIC;
		config_data : inout STD_LOGIC_VECTOR(7 downto 0);
		reg_uds_z : in STD_LOGIC;
		reg_lds_z : in STD_LOGIC;
		reg_ads_z : in STD_LOGIC;
		reg_en_z : in STD_LOGIC;
		reg_rdy_z : out STD_LOGIC;
		reg_rd_wr_z : in STD_LOGIC;
		lvds_rx_lane_p : in STD_LOGIC_VECTOR(67 downto 0);
		lvds_rx_lane_n : in STD_LOGIC_VECTOR(67 downto 0);
		lvds_rx_clk_p : in STD_LOGIC_VECTOR(3 downto 0);
		lvds_rx_clk_n : in STD_LOGIC_VECTOR(3 downto 0);
		lvds_link_sc_out : out STD_LOGIC_VECTOR(4 downto 0);
		lvds_link_sc_in : in STD_LOGIC_VECTOR(4 downto 0);
		intra_mod_lvds_comms_control : inout STD_LOGIC_VECTOR(47 downto 0);
		upper_mod_lvds_comms_control : inout STD_LOGIC_VECTOR(47 downto 0);
		eeprom_scl : out STD_LOGIC;
		eeprom_sda : inout STD_LOGIC;
		sys_led_out : out STD_LOGIC_VECTOR(5 downto 0);
		ram_leds : out STD_LOGIC_VECTOR(1 downto 0);
		ram_pwr_on : out STD_LOGIC;
		ram_pg : in STD_LOGIC;
		mgt_pg : in STD_LOGIC;
		osc_clk : out STD_LOGIC;
		clk200mhz : out STD_LOGIC;
		clk200mhz_locked : out STD_LOGIC;
		user_reg_clk : out STD_LOGIC;
		user_interupt : in STD_LOGIC_VECTOR(3 downto 0);
		user_reg_wdata : out STD_LOGIC_VECTOR(15 downto 0);
		user_reg_addr : out STD_LOGIC_VECTOR(12 downto 0);
		user_reg_rden : out STD_LOGIC_VECTOR(3 downto 0);
		user_reg_wren : out STD_LOGIC_VECTOR(3 downto 0);
		user_reg_rdy : in STD_LOGIC_VECTOR(3 downto 0);
		user_reg_rdata0 : in STD_LOGIC_VECTOR(15 downto 0);
		user_reg_rdata1 : in STD_LOGIC_VECTOR(15 downto 0);
		user_reg_rdata2 : in STD_LOGIC_VECTOR(15 downto 0);
		user_reg_rdata3 : in STD_LOGIC_VECTOR(15 downto 0);
		clk : in STD_LOGIC;
		tx_data_valid : in STD_LOGIC;
		tx_data : in STD_LOGIC_VECTOR(255 downto 0);
		tx_data_almost_full : out STD_LOGIC;
		rx_data_read : in STD_LOGIC;
		rx_data_empty : out STD_LOGIC;
		rx_data_valid : out STD_LOGIC;
		rx_data : out STD_LOGIC_VECTOR(255 downto 0);
		sysmon_alarm : out STD_LOGIC_VECTOR(3 downto 0);
		leds : in STD_LOGIC_VECTOR(3 downto 0));
	end component;

	 	-- Component declaration of the "comp_0_base_edge_2rx2tx(rtl)" unit defined in
	-- file: "./../../m2e/src/comp_0_base_edge_2rx2tx.vhd"
	component comp_0_base_edge_2rx2tx
	port(
		clk100p : in STD_LOGIC;
		clk100n : in STD_LOGIC;
		reg_clk : in STD_LOGIC;
		reg_reset_z : in STD_LOGIC;
		config_data : inout STD_LOGIC_VECTOR(7 downto 0);
		reg_uds_z : in STD_LOGIC;
		reg_lds_z : in STD_LOGIC;
		reg_ads_z : in STD_LOGIC;
		reg_en_z : in STD_LOGIC;
		reg_rdy_z : out STD_LOGIC;
		reg_rd_wr_z : in STD_LOGIC;
		lvds_rx_lane_p : in STD_LOGIC_VECTOR(33 downto 0);
		lvds_rx_lane_n : in STD_LOGIC_VECTOR(33 downto 0);
		lvds_rx_clk_p : in STD_LOGIC_VECTOR(1 downto 0);
		lvds_rx_clk_n : in STD_LOGIC_VECTOR(1 downto 0);
		lvds_tx_lane_p : out STD_LOGIC_VECTOR(33 downto 0);
		lvds_tx_lane_n : out STD_LOGIC_VECTOR(33 downto 0);
		lvds_tx_clk_p : out STD_LOGIC_VECTOR(1 downto 0);
		lvds_tx_clk_n : out STD_LOGIC_VECTOR(1 downto 0);
		intra_mod_lvds_comms_control : inout STD_LOGIC_VECTOR(47 downto 0);
		upper_mod_lvds_comms_control : inout STD_LOGIC_VECTOR(47 downto 0);
		eeprom_scl : out STD_LOGIC;
		eeprom_sda : inout STD_LOGIC;
		sys_led_out : out STD_LOGIC_VECTOR(5 downto 0);
		ram_leds : out STD_LOGIC_VECTOR(1 downto 0);
		ram_pwr_on : out STD_LOGIC;
		ram_pg : in STD_LOGIC;
		mgt_pg : in STD_LOGIC;
		osc_clk : out STD_LOGIC;
		clk200mhz : out STD_LOGIC;
		clk200mhz_locked : out STD_LOGIC;
		user_reg_clk : out STD_LOGIC;
		user_interupt : in STD_LOGIC_VECTOR(3 downto 0);
		user_reg_wdata : out STD_LOGIC_VECTOR(15 downto 0);
		user_reg_addr : out STD_LOGIC_VECTOR(12 downto 0);
		user_reg_rden : out STD_LOGIC_VECTOR(3 downto 0);
		user_reg_wren : out STD_LOGIC_VECTOR(3 downto 0);
		user_reg_rdy : in STD_LOGIC_VECTOR(3 downto 0);
		user_reg_rdata0 : in STD_LOGIC_VECTOR(15 downto 0);
		user_reg_rdata1 : in STD_LOGIC_VECTOR(15 downto 0);
		user_reg_rdata2 : in STD_LOGIC_VECTOR(15 downto 0);
		user_reg_rdata3 : in STD_LOGIC_VECTOR(15 downto 0);
		clk : in STD_LOGIC;
		tx_data_valid : in STD_LOGIC;
		tx_data : in STD_LOGIC_VECTOR(255 downto 0);
		tx_data_almost_full : out STD_LOGIC;
		rx_data_read : in STD_LOGIC;
		rx_data_empty : out STD_LOGIC;
		rx_data_valid : out STD_LOGIC;
		rx_data : out STD_LOGIC_VECTOR(255 downto 0);
		sysmon_alarm : out STD_LOGIC_VECTOR(3 downto 0);
		leds : in STD_LOGIC_VECTOR(3 downto 0));
	end component;

	
		-- Component declaration of the "comp_1_base_edge_0rx4tx(rtl)" unit defined in
	-- file: "./../../m2e/src/comp_1_base_edge_0rx4tx.vhd"
	component comp_1_base_edge_0rx4tx
	port(
		clk100p : in STD_LOGIC;
		clk100n : in STD_LOGIC;
		reg_clk : in STD_LOGIC;
		reg_reset_z : in STD_LOGIC;
		config_data : inout STD_LOGIC_VECTOR(7 downto 0);
		reg_uds_z : in STD_LOGIC;
		reg_lds_z : in STD_LOGIC;
		reg_ads_z : in STD_LOGIC;
		reg_en_z : in STD_LOGIC;
		reg_rdy_z : out STD_LOGIC;
		reg_rd_wr_z : in STD_LOGIC;
		lvds_tx_lane_p : out STD_LOGIC_VECTOR(67 downto 0);
		lvds_tx_lane_n : out STD_LOGIC_VECTOR(67 downto 0);
		lvds_tx_clk_p : out STD_LOGIC_VECTOR(3 downto 0);
		lvds_tx_clk_n : out STD_LOGIC_VECTOR(3 downto 0);
		lvds_link_sc_out : out STD_LOGIC_VECTOR(4 downto 0);
		lvds_link_sc_in : in STD_LOGIC_VECTOR(4 downto 0);
		intra_mod_lvds_comms_control : inout STD_LOGIC_VECTOR(47 downto 0);
		upper_mod_lvds_comms_control : inout STD_LOGIC_VECTOR(47 downto 0);
		eeprom_scl : out STD_LOGIC;
		eeprom_sda : inout STD_LOGIC;
		sys_led_out : out STD_LOGIC_VECTOR(5 downto 0);
		ram_leds : out STD_LOGIC_VECTOR(1 downto 0);
		ram_pwr_on : out STD_LOGIC;
		ram_pg : in STD_LOGIC;
		mgt_pg : in STD_LOGIC;
		osc_clk : out STD_LOGIC;
		clk200mhz : out STD_LOGIC;
		clk200mhz_locked : out STD_LOGIC;
		user_reg_clk : out STD_LOGIC;
		user_interupt : in STD_LOGIC_VECTOR(3 downto 0);
		user_reg_wdata : out STD_LOGIC_VECTOR(15 downto 0);
		user_reg_addr : out STD_LOGIC_VECTOR(12 downto 0);
		user_reg_rden : out STD_LOGIC_VECTOR(3 downto 0);
		user_reg_wren : out STD_LOGIC_VECTOR(3 downto 0);
		user_reg_rdy : in STD_LOGIC_VECTOR(3 downto 0);
		user_reg_rdata0 : in STD_LOGIC_VECTOR(15 downto 0);
		user_reg_rdata1 : in STD_LOGIC_VECTOR(15 downto 0);
		user_reg_rdata2 : in STD_LOGIC_VECTOR(15 downto 0);
		user_reg_rdata3 : in STD_LOGIC_VECTOR(15 downto 0);
		clk : in STD_LOGIC;
		tx_data_valid : in STD_LOGIC;
		tx_data : in STD_LOGIC_VECTOR(255 downto 0);
		tx_data_almost_full : out STD_LOGIC;
		rx_data_read : in STD_LOGIC;
		rx_data_empty : out STD_LOGIC;
		rx_data_valid : out STD_LOGIC;
		rx_data : out STD_LOGIC_VECTOR(255 downto 0);
		sysmon_alarm : out STD_LOGIC_VECTOR(3 downto 0);
		leds : in STD_LOGIC_VECTOR(3 downto 0));
	end component;

	
	
		-- Component declaration of the "exp_0_inter_sys_edge_2rx2tx(rtl)" unit defined in
	-- file: "./../../m2e/src/exp_0_inter_sys_edge_2rx2tx.vhd"
	component exp_0_inter_sys_edge_2rx2tx
	port(
		clk100p : in STD_LOGIC;
		clk100n : in STD_LOGIC;
		reg_clk : in STD_LOGIC;
		reg_reset_z : in STD_LOGIC;
		config_data : inout STD_LOGIC_VECTOR(7 downto 0);
		reg_uds_z : in STD_LOGIC;
		reg_lds_z : in STD_LOGIC;
		reg_ads_z : in STD_LOGIC;
		reg_en_z : in STD_LOGIC;
		reg_rdy_z : out STD_LOGIC;
		reg_rd_wr_z : in STD_LOGIC;
		lvds_rx_lane_p : in STD_LOGIC_VECTOR(33 downto 0);
		lvds_rx_lane_n : in STD_LOGIC_VECTOR(33 downto 0);
		lvds_rx_clk_p : in STD_LOGIC_VECTOR(1 downto 0);
		lvds_rx_clk_n : in STD_LOGIC_VECTOR(1 downto 0);
		lvds_tx_lane_p : out STD_LOGIC_VECTOR(33 downto 0);
		lvds_tx_lane_n : out STD_LOGIC_VECTOR(33 downto 0);
		lvds_tx_clk_p : out STD_LOGIC_VECTOR(1 downto 0);
		lvds_tx_clk_n : out STD_LOGIC_VECTOR(1 downto 0);
		intra_mod_lvds_comms_control : inout STD_LOGIC_VECTOR(47 downto 0);
		upper_mod_lvds_comms_control : inout STD_LOGIC_VECTOR(47 downto 0);
		eeprom_scl : out STD_LOGIC;
		eeprom_sda : inout STD_LOGIC;
		sys_led_out : out STD_LOGIC_VECTOR(5 downto 0);
		ram_leds : out STD_LOGIC_VECTOR(1 downto 0);
		ram_pwr_on : out STD_LOGIC;
		ram_pg : in STD_LOGIC;
		mgt_pg : in STD_LOGIC;
		osc_clk : out STD_LOGIC;
		clk200mhz : out STD_LOGIC;
		clk200mhz_locked : out STD_LOGIC;
		user_reg_clk : out STD_LOGIC;
		user_interupt : in STD_LOGIC_VECTOR(3 downto 0);
		user_reg_wdata : out STD_LOGIC_VECTOR(15 downto 0);
		user_reg_addr : out STD_LOGIC_VECTOR(12 downto 0);
		user_reg_rden : out STD_LOGIC_VECTOR(3 downto 0);
		user_reg_wren : out STD_LOGIC_VECTOR(3 downto 0);
		user_reg_rdy : in STD_LOGIC_VECTOR(3 downto 0);
		user_reg_rdata0 : in STD_LOGIC_VECTOR(15 downto 0);
		user_reg_rdata1 : in STD_LOGIC_VECTOR(15 downto 0);
		user_reg_rdata2 : in STD_LOGIC_VECTOR(15 downto 0);
		user_reg_rdata3 : in STD_LOGIC_VECTOR(15 downto 0);
		clk : in STD_LOGIC;
		tx_data_valid : in STD_LOGIC;
		tx_data : in STD_LOGIC_VECTOR(255 downto 0);
		tx_data_almost_full : out STD_LOGIC;
		rx_data_read : in STD_LOGIC;
		rx_data_empty : out STD_LOGIC;
		rx_data_valid : out STD_LOGIC;
		rx_data : out STD_LOGIC_VECTOR(255 downto 0);
		sysmon_alarm : out STD_LOGIC_VECTOR(3 downto 0);
		leds : in STD_LOGIC_VECTOR(3 downto 0));
	end component;

		-- Component declaration of the "exp_0_base_edge_4rx2tx(rtl)" unit defined in
	-- file: "./../../m2e/src/exp_0_base_edge_4rx2tx.vhd"
	component exp_0_base_edge_4rx2tx
	port(
		clk100p : in STD_LOGIC;
		clk100n : in STD_LOGIC;
		reg_clk : in STD_LOGIC;
		reg_reset_z : in STD_LOGIC;
		config_data : inout STD_LOGIC_VECTOR(7 downto 0);
		reg_uds_z : in STD_LOGIC;
		reg_lds_z : in STD_LOGIC;
		reg_ads_z : in STD_LOGIC;
		reg_en_z : in STD_LOGIC;
		reg_rdy_z : out STD_LOGIC;
		reg_rd_wr_z : in STD_LOGIC;
		lvds_rx_lane_p : in STD_LOGIC_VECTOR(67 downto 0);
		lvds_rx_lane_n : in STD_LOGIC_VECTOR(67 downto 0);
		lvds_rx_clk_p : in STD_LOGIC_VECTOR(3 downto 0);
		lvds_rx_clk_n : in STD_LOGIC_VECTOR(3 downto 0);
		lvds_tx_lane_p : out STD_LOGIC_VECTOR(33 downto 0);
		lvds_tx_lane_n : out STD_LOGIC_VECTOR(33 downto 0);
		lvds_tx_clk_p : out STD_LOGIC_VECTOR(1 downto 0);
		lvds_tx_clk_n : out STD_LOGIC_VECTOR(1 downto 0);
		eeprom_scl : out STD_LOGIC;
		eeprom_sda : inout STD_LOGIC;
		sys_led_out : out STD_LOGIC_VECTOR(5 downto 0);
		ram_pwr_on : out STD_LOGIC;
		ram_pg : in STD_LOGIC;
		mgt_pg : in STD_LOGIC;
		osc_clk : out STD_LOGIC;
		clk200mhz : out STD_LOGIC;
		clk200mhz_locked : out STD_LOGIC;
		user_reg_clk : out STD_LOGIC;
		user_interupt : in STD_LOGIC_VECTOR(3 downto 0);
		user_reg_wdata : out STD_LOGIC_VECTOR(15 downto 0);
		user_reg_addr : out STD_LOGIC_VECTOR(12 downto 0);
		user_reg_rden : out STD_LOGIC_VECTOR(3 downto 0);
		user_reg_wren : out STD_LOGIC_VECTOR(3 downto 0);
		user_reg_rdy : in STD_LOGIC_VECTOR(3 downto 0);
		user_reg_rdata0 : in STD_LOGIC_VECTOR(15 downto 0);
		user_reg_rdata1 : in STD_LOGIC_VECTOR(15 downto 0);
		user_reg_rdata2 : in STD_LOGIC_VECTOR(15 downto 0);
		user_reg_rdata3 : in STD_LOGIC_VECTOR(15 downto 0);
		clk : in STD_LOGIC;
		tx_data_valid : in STD_LOGIC;
		tx_data : in STD_LOGIC_VECTOR(255 downto 0);
		tx_data_almost_full : out STD_LOGIC;
		rx_data_read : in STD_LOGIC;
		rx_data_empty : out STD_LOGIC;
		rx_data_valid : out STD_LOGIC;
		rx_data : out STD_LOGIC_VECTOR(255 downto 0);
		sysmon_alarm : out STD_LOGIC_VECTOR(3 downto 0);
		leds : in STD_LOGIC_VECTOR(3 downto 0));
	end component;

	
		-- Component declaration of the "sys_edge_0rx0tx(rtl)" unit defined in
	-- file: "./../../m2e/src/sys_edge_0rx0tx.vhd"
	component sys_edge_0rx0tx
	port(
		clk100p : in STD_LOGIC;
		clk100n : in STD_LOGIC;
		reg_clk : in STD_LOGIC;
		reg_reset_z : in STD_LOGIC;
		config_data : inout STD_LOGIC_VECTOR(7 downto 0);
		reg_uds_z : in STD_LOGIC;
		reg_lds_z : in STD_LOGIC;
		reg_ads_z : in STD_LOGIC;
		reg_en_z : in STD_LOGIC;
		reg_rdy_z : out STD_LOGIC;
		reg_rd_wr_z : in STD_LOGIC;
		intra_mod_lvds_comms_control : inout STD_LOGIC_VECTOR(47 downto 0);
		upper_mod_lvds_comms_control : inout STD_LOGIC_VECTOR(47 downto 0);
		eeprom_scl : out STD_LOGIC;
		eeprom_sda : inout STD_LOGIC;
		sys_led_out : out STD_LOGIC_VECTOR(5 downto 0);
		ram_leds : out STD_LOGIC_VECTOR(1 downto 0);
		ram_pwr_on : out STD_LOGIC;
		ram_pg : in STD_LOGIC;
		mgt_pg : in STD_LOGIC;
		osc_clk : out STD_LOGIC;
		clk200mhz : out STD_LOGIC;
		clk200mhz_locked : out STD_LOGIC;
		user_reg_clk : out STD_LOGIC;
		user_interupt : in STD_LOGIC_VECTOR(3 downto 0);
		user_reg_wdata : out STD_LOGIC_VECTOR(15 downto 0);
		user_reg_addr : out STD_LOGIC_VECTOR(12 downto 0);
		user_reg_rden : out STD_LOGIC_VECTOR(3 downto 0);
		user_reg_wren : out STD_LOGIC_VECTOR(3 downto 0);
		user_reg_rdy : in STD_LOGIC_VECTOR(3 downto 0);
		user_reg_rdata0 : in STD_LOGIC_VECTOR(15 downto 0);
		user_reg_rdata1 : in STD_LOGIC_VECTOR(15 downto 0);
		user_reg_rdata2 : in STD_LOGIC_VECTOR(15 downto 0);
		user_reg_rdata3 : in STD_LOGIC_VECTOR(15 downto 0);
		sysmon_alarm : out STD_LOGIC_VECTOR(3 downto 0);
		leds : in STD_LOGIC_VECTOR(3 downto 0));
	end component; 
	
		-- Component declaration of the "inter_intra_mod_slv_edge_4rx0tx(rtl)" unit defined in
	-- file: "./../../m2e/src/inter_intra_mod_slv_edge_4rx0tx.vhd"
	component inter_intra_mod_slv_edge_4rx0tx
	port(
		clk100 : in STD_LOGIC;
		srst : in STD_LOGIC;
		link_complete : out STD_LOGIC;
		lvds_rx_lane_p : in STD_LOGIC_VECTOR(67 downto 0);
		lvds_rx_lane_n : in STD_LOGIC_VECTOR(67 downto 0);
		lvds_rx_clk_p : in STD_LOGIC_VECTOR(3 downto 0);
		lvds_rx_clk_n : in STD_LOGIC_VECTOR(3 downto 0);
		lvds_comms_control : inout STD_LOGIC_VECTOR(47 downto 0);
		lvds_link_sc_out : out STD_LOGIC_VECTOR(4 downto 0);
		lvds_link_sc_in : in STD_LOGIC_VECTOR(4 downto 0);
		sys_clk : in STD_LOGIC;
		tx_data_valid : in STD_LOGIC;
		tx_data : in STD_LOGIC_VECTOR(255 downto 0);
		tx_data_almost_full : out STD_LOGIC;
		rx_data_read : in STD_LOGIC;
		rx_data_empty : out STD_LOGIC;
		rx_data_valid : out STD_LOGIC;
		rx_data : out STD_LOGIC_VECTOR(255 downto 0));
	end component;

	
		-- Component declaration of the "inter_intra_mod_mst_edge_0rx4tx(rtl)" unit defined in
	-- file: "./../../m2e/src/inter_intra_mod_mst_edge_0rx4tx.vhd"
	component inter_intra_mod_mst_edge_0rx4tx
	port(
		clk100 : in STD_LOGIC;
		srst : in STD_LOGIC;
		link_complete : out STD_LOGIC;
		lvds_tx_lane_p : out STD_LOGIC_VECTOR(67 downto 0);
		lvds_tx_lane_n : out STD_LOGIC_VECTOR(67 downto 0);
		lvds_tx_clk_p : out STD_LOGIC_VECTOR(3 downto 0);
		lvds_tx_clk_n : out STD_LOGIC_VECTOR(3 downto 0);
		lvds_comms_control : inout STD_LOGIC_VECTOR(47 downto 0);
		lvds_link_sc_out : out STD_LOGIC_VECTOR(4 downto 0);
		lvds_link_sc_in : in STD_LOGIC_VECTOR(4 downto 0);
		sys_clk : in STD_LOGIC;
		tx_data_valid : in STD_LOGIC;
		tx_data : in STD_LOGIC_VECTOR(255 downto 0);
		tx_data_almost_full : out STD_LOGIC;
		rx_data_read : in STD_LOGIC;
		rx_data_empty : out STD_LOGIC;
		rx_data_valid : out STD_LOGIC;
		rx_data : out STD_LOGIC_VECTOR(255 downto 0));
	end component;

		-- Component declaration of the "inter_intra_mod_mst_edge_2rx2tx(rtl)" unit defined in
	-- file: "./../../m2e/src/inter_intra_mod_mst_edge_2rx2tx.vhd"
	component inter_intra_mod_mst_edge_2rx2tx
	port(
		clk100 : in STD_LOGIC;
		srst : in STD_LOGIC;
		link_complete : out STD_LOGIC;
		lvds_tx_lane_p : out STD_LOGIC_VECTOR(33 downto 0);
		lvds_tx_lane_n : out STD_LOGIC_VECTOR(33 downto 0);
		lvds_tx_clk_p : out STD_LOGIC_VECTOR(1 downto 0);
		lvds_tx_clk_n : out STD_LOGIC_VECTOR(1 downto 0);
		lvds_rx_lane_p : in STD_LOGIC_VECTOR(33 downto 0);
		lvds_rx_lane_n : in STD_LOGIC_VECTOR(33 downto 0);
		lvds_rx_clk_p : in STD_LOGIC_VECTOR(1 downto 0);
		lvds_rx_clk_n : in STD_LOGIC_VECTOR(1 downto 0);
		lvds_comms_control : inout STD_LOGIC_VECTOR(47 downto 0);
		lvds_link_sc_out : out STD_LOGIC_VECTOR(4 downto 0);
		lvds_link_sc_in : in STD_LOGIC_VECTOR(4 downto 0);
		sys_clk : in STD_LOGIC;
		tx_data_valid : in STD_LOGIC;
		tx_data : in STD_LOGIC_VECTOR(255 downto 0);
		tx_data_almost_full : out STD_LOGIC;
		rx_data_read : in STD_LOGIC;
		rx_data_empty : out STD_LOGIC;
		rx_data_valid : out STD_LOGIC;
		rx_data : out STD_LOGIC_VECTOR(255 downto 0));
	end component;

		-- Component declaration of the "inter_intra_mod_slv_edge_2rx2tx(rtl)" unit defined in
	-- file: "./../../m2e/src/inter_intra_mod_slv_edge_2rx2tx.vhd"
	component inter_intra_mod_slv_edge_2rx2tx
	port(
		clk100 : in STD_LOGIC;
		srst : in STD_LOGIC;
		link_complete : out STD_LOGIC;
		lvds_tx_lane_p : out STD_LOGIC_VECTOR(33 downto 0);
		lvds_tx_lane_n : out STD_LOGIC_VECTOR(33 downto 0);
		lvds_tx_clk_p : out STD_LOGIC_VECTOR(1 downto 0);
		lvds_tx_clk_n : out STD_LOGIC_VECTOR(1 downto 0);
		lvds_rx_lane_p : in STD_LOGIC_VECTOR(33 downto 0);
		lvds_rx_lane_n : in STD_LOGIC_VECTOR(33 downto 0);
		lvds_rx_clk_p : in STD_LOGIC_VECTOR(1 downto 0);
		lvds_rx_clk_n : in STD_LOGIC_VECTOR(1 downto 0);
		lvds_comms_control : inout STD_LOGIC_VECTOR(47 downto 0);
		lvds_link_sc_out : out STD_LOGIC_VECTOR(4 downto 0);
		lvds_link_sc_in : in STD_LOGIC_VECTOR(4 downto 0);
		sys_clk : in STD_LOGIC;
		tx_data_valid : in STD_LOGIC;
		tx_data : in STD_LOGIC_VECTOR(255 downto 0);
		tx_data_almost_full : out STD_LOGIC;
		rx_data_read : in STD_LOGIC;
		rx_data_empty : out STD_LOGIC;
		rx_data_valid : out STD_LOGIC;
		rx_data : out STD_LOGIC_VECTOR(255 downto 0));
	end component;


end package edge_comp_defs_pkg;

