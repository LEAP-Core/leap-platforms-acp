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
-- Title       : fsb_compute_edge_2rx2tx_example
-- Project     : FSB modules
--------------------------------------------------------------------------------
-- Description :  This module provides a loopback using the 
-- fsb_compute_edge_2rx2tx component and is provided as a simple example of 
-- using the base edge component. The design also connects 2 user register slave 
-- interface components, one which implements a block ram 
-- (usr_reg_slave_if_bram_example.vhd) and the other which provides IO which are
-- used to drive the user LEDs and monitor the system monitor alarm inputs 
-- (usr_reg_slave_if_io_example.vhd)
--
--------------------------------------------------------------------------------
-- Known Issues and Omissions:
--
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;



entity nallatech_edge_vhdl is 
	port( 

        -- top level wires
      
        clk100p : in std_logic;
		clk100n : in std_logic;
		reg_clk : in std_logic;
		reg_reset_z : in std_logic;
		config_data : inout std_logic_vector(7 downto 0);
		reg_uds_z : in std_logic;
		reg_lds_z : in std_logic;
		reg_ads_z : in std_logic;
		reg_en_z : in std_logic;
		reg_rdy_z : out std_logic;
		reg_rd_wr_z : in std_logic;
		lvds_rx_lane_p : in std_logic_vector(33 downto 0);
		lvds_rx_lane_n : in std_logic_vector(33 downto 0);
		lvds_rx_clk_p : in std_logic_vector(1 downto 0);
		lvds_rx_clk_n : in std_logic_vector(1 downto 0);
		lvds_tx_lane_p : out std_logic_vector(33 downto 0);
		lvds_tx_lane_n : out std_logic_vector(33 downto 0);
		lvds_tx_clk_p : out std_logic_vector(1 downto 0);
		lvds_tx_clk_n : out std_logic_vector(1 downto 0);
		eeprom_scl : out std_logic;
		eeprom_sda : inout std_logic;
		sys_led_out : out std_logic_vector(5 downto 0);
		ram_pwr_on : out std_logic;
		ram_leds:out std_logic_vector(1 downto 0);
		ram_pg : in std_logic;
		mgt_pg : in std_logic;

        -- output clocks and resets

        raw_clk_out: out std_logic;     -- raw oscillator clock
        clk_out    : out std_logic;     -- interface clock
        rst_n_out  : out std_logic;     -- interface reset
        
        -- user interface
        
        tx_data_valid    : in std_logic;
        tx_data          : in std_logic_vector(255 downto 0);
        tx_data_not_full : out std_logic;

        rx_data_read     : in std_logic;
        rx_data_ready    : out std_logic; 
        rx_data          : out std_logic_vector(255 downto 0)

		);	
end nallatech_edge_vhdl;

architecture rtl of nallatech_edge_vhdl is
	
	---------------------------------------------------------------------------
	-- Component declaration of the "m2e_edge(rtl)" unit
	component fsb_compute_edge_2rx2tx
		port(
			clk100p : in std_logic;
			clk100n : in std_logic;
			reg_clk : in std_logic;
			reg_reset_z : in std_logic;
			config_data : inout std_logic_vector(7 downto 0);
			reg_uds_z : in std_logic;
			reg_lds_z : in std_logic;
			reg_ads_z : in std_logic;
			reg_en_z : in std_logic;
			reg_rdy_z : out std_logic;
			reg_rd_wr_z : in std_logic;
			lvds_rx_lane_p : in std_logic_vector(33 downto 0);
			lvds_rx_lane_n : in std_logic_vector(33 downto 0);
			lvds_rx_clk_p : in std_logic_vector(1 downto 0);
			lvds_rx_clk_n : in std_logic_vector(1 downto 0);
			lvds_tx_lane_p : out std_logic_vector(33 downto 0);
			lvds_tx_lane_n : out std_logic_vector(33 downto 0);
			lvds_tx_clk_p : out std_logic_vector(1 downto 0);
			lvds_tx_clk_n : out std_logic_vector(1 downto 0);
			eeprom_scl : out std_logic;
			eeprom_sda : inout std_logic;
			sys_led_out : out std_logic_vector(5 downto 0);
			ram_leds:out std_logic_vector(1 downto 0);
			ram_pwr_on : out std_logic;
			ram_pg : in std_logic;
			mgt_pg : in std_logic;
			osc_clk: out std_logic;
			ram_clk0 : out std_logic;
			ram_clk180 : out std_logic;
			ram_clk270 : out std_logic;
			clk200mhz : out std_logic;
			ram_clk_locked : out std_logic;
			user_reg_clk : out std_logic;
			user_interupt : in std_logic_vector(3 downto 0);
			user_reg_wdata : out std_logic_vector(15 downto 0);
			user_reg_addr : out std_logic_vector(12 downto 0);
			user_reg_rden : out std_logic_vector(3 downto 0);
			user_reg_wren : out std_logic_vector(3 downto 0);
			user_reg_rdy : in std_logic_vector(3 downto 0);
			user_reg_rdata0 : in std_logic_vector(15 downto 0);
			user_reg_rdata1 : in std_logic_vector(15 downto 0);
			user_reg_rdata2 : in std_logic_vector(15 downto 0);
			user_reg_rdata3 : in std_logic_vector(15 downto 0);
			
			clk : in std_logic;
			tx_data_valid : in std_logic;
			tx_data : in std_logic_vector(255 downto 0);
			tx_data_almost_full : out std_logic;
			
			rx_data_read:in std_logic;
			rx_data_empty:out std_logic; 
			rx_data_valid:out std_logic;
			rx_data : out std_logic_vector(255 downto 0);
					
			sysmon_alarm : out std_logic_vector(3 downto 0);
			leds : in std_logic_vector(3 downto 0)
			);
	end component;
	
	---------------------------------------------------------------------------
	--M2E edge ram clock signals
	signal ram_clk0 : std_logic;
	signal ram_clk180 : std_logic;
	signal ram_clk270 : std_logic;
	signal clk200mhz : std_logic;
	signal ram_clk_locked : std_logic;
	
    -- raw oscillator clock
    signal osc_clk : std_logic;
    signal raw_clk_c : std_logic;
    
    ---------------------------------------------------------------------------
	--M2E user register slave interface signals
	signal user_reg_clk : std_logic;
	signal user_interupt : std_logic_vector(3 downto 0);
	signal user_reg_wdata : std_logic_vector(15 downto 0);
	signal user_reg_addr : std_logic_vector(12 downto 0);
	signal user_reg_rden : std_logic_vector(3 downto 0);
	signal user_reg_wren : std_logic_vector(3 downto 0); 
	signal user_reg_rdy : std_logic_vector(3 downto 0);
	signal user_reg_rdata0 : std_logic_vector(15 downto 0);
	signal user_reg_rdata1 : std_logic_vector(15 downto 0);
	signal user_reg_rdata2 : std_logic_vector(15 downto 0);
	signal user_reg_rdata3 : std_logic_vector(15 downto 0);	 
	
	---------------------------------------------------------------------------
	--AFU V0.7 interface signals
	
	--create an alias of the ram clock ram_clk0 to use as the data clk
	alias clk : std_logic is ram_clk0;	
	
	--write (to fsb) interface						
	signal tx_data_valid_c : std_logic;
	signal tx_data_c : std_logic_vector(255 downto 0);
	signal tx_data_almost_full_c : std_logic;
	
	--read (from fsb) interface	   
	signal rx_data_valid_c : std_logic;
	signal rx_data_c : std_logic_vector(255 downto 0);
	signal rx_data_read_c: std_logic;
	signal rx_data_almost_full_c :std_logic;
	signal rx_data_empty_c:std_logic;

	---------------------------------------------------------------------------
	--LED and alarm signals
	signal sysmon_alarm : std_logic_vector(3 downto 0);
	signal leds : std_logic_vector(3 downto 0);

	
	---------------------------------------------------------------------------
	-- Component declaration of usr_reg_slave_if_bram_example
	component usr_reg_slave_if_bram_example
		port(
			clk : in std_logic;
			user_reg_wdata : in std_logic_vector(15 downto 0);
			user_reg_addr : in std_logic_vector(12 downto 0);
			user_reg_rden : in std_logic;
			user_reg_wren : in std_logic;
			user_reg_rdata : out std_logic_vector(15 downto 0);
			user_reg_rdy : out std_logic);
	end component;	 
	
	
	---------------------------------------------------------------------------
	-- Component declaration of usr_reg_slave_if_io_example
	component usr_reg_slave_if_io_example
		port(
			clk : in std_logic;
			user_reg_wdata : in std_logic_vector(15 downto 0);
			user_reg_addr : in std_logic_vector(12 downto 0);
			user_reg_rden : in std_logic;
			user_reg_wren : in std_logic;
			user_reg_rdata : out std_logic_vector(15 downto 0);
			user_reg_rdy : out std_logic;
			leds : out std_logic_vector(3 downto 0));
	end component;
	
    component IBUFGDS
        port (O  : out STD_ULOGIC;
              I  : in STD_ULOGIC;
              IB : in STD_ULOGIC);
    end component;

begin  
	
	
	---------------------------------------------------------------------------
	--instantiate the M2E edge component configured for 4 transmit LVDS banks
	--to the M2B, 2 recieve LVDS banks from the M2B and a ram speed of 200MHz
	fsb_compute_edge_inst :fsb_compute_edge_2rx2tx
	port map(
		-------------------------------
		--system interface (should be connected to top level ports)	
		-------------------------------
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
		
		
		-------------------------------
		--User interfaces to the M2E edge component
		-------------------------------
		--RAM clock interface 
		osc_clk => osc_clk,
		ram_clk0 => ram_clk0,
		ram_clk180 => ram_clk180,
		ram_clk270 => ram_clk270,
		clk200mhz => clk200mhz,
		ram_clk_locked => ram_clk_locked, 
		-------------------------------
		--user register slave interface
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
		-------------------------------
		--AFU v0.7 interface
		clk => clk,
		tx_data_valid => tx_data_valid_c,
		
		tx_data => tx_data_c,
		tx_data_almost_full => tx_data_almost_full_c,
		rx_data_valid => rx_data_valid_c,	
		rx_data_read=>rx_data_read_c,
		rx_data_empty=>rx_data_empty_c,
		rx_data => rx_data_c,
		-------------------------------
		--LED and system monitor alarm interface
		sysmon_alarm => sysmon_alarm,
		leds => leds,  
		ram_leds=>ram_leds
		);
	
	
	
	---------------------------------------------------------------------------
	-- patch FIFO interface

    tx_data_valid_c  <= tx_data_valid;
    tx_data_c        <= tx_data;
    tx_data_not_full <= not tx_data_almost_full_c;

    rx_data_read_c   <= rx_data_read;
    rx_data_ready    <= not rx_data_empty_c;
    rx_data          <= rx_data_c;

    -- export clocks and reset

    -- raw_clk_out <= osc_clk;
    -- raw_clk_out <= raw_clk_c;
    raw_clk_out <= clk;
    clk_out     <= clk;
    rst_n_out   <= ram_clk_locked;

    -- clk_ibufgds_inst : ibufgds
    -- port map (
    --   o  => raw_clk_c,
    --   i  => clk100p,
    --   ib => clk100n);
    
	---------------------------------------------------------------------------
	--User register slave interface connections
	
	--connect up the block ram example to user register port 0
	usr_reg_slave_if_bram_example_inst : usr_reg_slave_if_bram_example
	port map(
		clk => user_reg_clk,
		user_reg_wdata => user_reg_wdata,
		user_reg_addr => user_reg_addr,
		user_reg_rden => user_reg_rden(0),
		user_reg_wren => user_reg_wren(0),
		user_reg_rdata => user_reg_rdata0,
		user_reg_rdy => user_reg_rdy(0)
		);
	
	--connect up the IO example to user register port 1
	usr_reg_slave_if_io_example_inst : usr_reg_slave_if_io_example
	port map(
		clk => user_reg_clk,
		user_reg_wdata => user_reg_wdata,
		user_reg_addr => user_reg_addr,
		user_reg_rden => user_reg_rden(1),
		user_reg_wren => user_reg_wren(1),
		user_reg_rdata => user_reg_rdata1,
		user_reg_rdy => user_reg_rdy(1),
		leds => leds
		);
	
		
	--tie off the user register interface port rdy signals (ports 2 and 3).
	--By doing do ensuring that if port 2 or 3 is accidently accessed by
	--software that the controlling state machine within the edge and M2B
	--does not hang waiting for a response.
	user_reg_rdy(3 downto 2)<="00";
	
	
end rtl;
