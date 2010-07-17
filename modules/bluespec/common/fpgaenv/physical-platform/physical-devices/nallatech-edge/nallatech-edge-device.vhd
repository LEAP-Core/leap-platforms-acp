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

use work.edge_comp_defs_pkg.all;
use work.edge_comp_util_pkg.all;

-- local module type is constant here, as edge devices cannot be
-- instantiated on expansion module
-- external_id refers to the target that we comunicate with
entity nallatech_edge_vhdl is
        -- these generics allow us to share code with the null module
        generic(local_id_layer: integer;  -- layer i.e. sw is 0, all fpgas have
                                          -- 1
                local_id_fpga: integer;  -- fpga number, within layer (0,1)
                local_id_number: integer;  -- ?? appears to always be 0
                external_id_layer: integer; 
                external_id_fpga: integer;
                external_id_number: integer;
                rx_lanes: integer;
                tx_lanes: integer
               );
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
        
        -- lvds_link_sc_in  : in  std_logic_vector(4 downto 0);
        -- lvds_link_sc_out : out std_logic_vector(4 downto 0);
        
		eeprom_scl : out std_logic;
		eeprom_sda : inout std_logic;
		sys_led_out : out std_logic_vector(5 downto 0);
		-- moved to SRAM device -- ram_pwr_on : out std_logic;
		-- moved to SRAM device -- ram_leds:out std_logic_vector(1 downto 0);
		ram_pg : in std_logic;
		mgt_pg : in std_logic;

        -- output clocks and resets

        raw_clk_out: out std_logic;     -- raw oscillator clock
        clk_out    : out std_logic;     -- interface clock
        rst_n_out  : out std_logic;     -- interface reset

        ram_clk0   : out std_logic;
        ram_clk200 : out std_logic;
        ram_clk270 : out std_logic;
        ram_clk_locked : out std_logic;
        
        -- user interface (channel)
        
        tx_data_valid    : in std_logic;
        tx_data          : in std_logic_vector(255 downto 0);
        tx_data_not_full : out std_logic;

        rx_data_read     : in std_logic;
        rx_data_ready    : out std_logic; 
        rx_data          : out std_logic_vector(255 downto 0);

        -- user interface (register)

        user_reg_clk_out   : out std_logic;
        user_reg_wdata_out : out std_logic_vector(15 downto 0);
        user_reg_addr_out  : out std_logic_vector(12 downto 0);
        user_reg_rden_out  : out std_logic;
        user_reg_wren_out  : out std_logic;
        user_reg_wrack_in  : in  std_logic;
        user_reg_rdy_in    : in  std_logic;
        user_reg_rdata_in  : in  std_logic_vector(15 downto 0);

        -- intra fpga interface
        intra_fpga_lvds_ctrl : inout  std_logic_vector(47 downto 0)
		);	
end nallatech_edge_vhdl;

architecture rtl of nallatech_edge_vhdl is
	
	---------------------------------------------------------------------------
	-- Component declaration of the "m2e_edge(rtl)" unit
	component system_edge_component
      generic(local_id:integer;
              local_module_type:integer;
              external_id:integer;
              rx_lanes:integer;
              tx_lanes:integer
              );
		port(
			clk100p : in std_logic;
			clk100n : in std_logic;

            --expansion bus interface
			reg_clk : in std_logic;
			reg_reset_z : in std_logic;
			config_data : inout std_logic_vector(7 downto 0);
			reg_uds_z : in std_logic;
			reg_lds_z : in std_logic;
			reg_ads_z : in std_logic;
			reg_en_z : in std_logic;
			reg_rdy_z : out std_logic;
			reg_rd_wr_z : in std_logic;


            --high speed lvds downto the m2b
            lvds_rx_lane_p : in std_logic_vector(33 downto 0);
			lvds_rx_lane_n : in std_logic_vector(33 downto 0);
			lvds_rx_clk_p : in std_logic_vector(1 downto 0);
			lvds_rx_clk_n : in std_logic_vector(1 downto 0);
			lvds_tx_lane_p : out std_logic_vector(33 downto 0);
			lvds_tx_lane_n : out std_logic_vector(33 downto 0);
			lvds_tx_clk_p : out std_logic_vector(1 downto 0);
			lvds_tx_clk_n : out std_logic_vector(1 downto 0);

            lvds_link_sc_out : out STD_LOGIC_VECTOR(4 downto 0);
            lvds_link_sc_in : in STD_LOGIC_VECTOR(4 downto 0); 

            
            intra_mod_lvds_comms_control:inout std_logic_vector(47 downto 0);
            upper_mod_lvds_comms_control:inout std_logic_vector(47 downto 0);

            --serial eeprom interface
            eeprom_scl : out std_logic;
			eeprom_sda : inout std_logic;
            
			sys_led_out : out std_logic_vector(5 downto 0);
			ram_leds:out std_logic_vector(1 downto 0);
			ram_pwr_on : out std_logic;
			ram_pg : in std_logic;
			mgt_pg : in std_logic;

            -----------------------------------------------------------------------
            --user interface
		
            --ram clocks -- Angshuman - not RAM clocks
			osc_clk: out std_logic;
            clk200mhz : out std_logic;
            clk200mhz_locked : out std_logic;
            
            -- Angshuman -- RAM clocks moved to separate component
			--ram_clk0 : out std_logic;
			--ram_clk180 : out std_logic;
			--ram_clk270 : out std_logic;
			--ram_clk_locked : out std_logic;

            --user reg clocks 
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

            --afu interface
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
	
    component qdr2_ddr2_clocks is
      port (
        -- Initialization control and reset
        init                                                  : out std_logic;
        pll_rst                                               : in  std_logic;
        -- input memory clock
        sys_clk_in                                            : in  std_logic;
        -- sys_clk_n                                             : in  std_logic;
        -- sys_clk                                               : in  std_logic;
        -- ddr2 clock signals node 0
        mem0_ddr2_clk0                                        : out std_logic;
        mem0_ddr2_clk90                                       : out std_logic;
        mem0_ddr2_sys_reset                                   : out std_logic;
        -- ddr2 clock signals node 1
        mem1_ddr2_clk0                                        : out std_logic;
        mem1_ddr2_clk90                                       : out std_logic;
        mem1_ddr2_sys_reset                                   : out std_logic;  
        -- qdr2 clock signals node 0
        mem0_qdr2_clk0                                        : out std_logic;
        mem0_qdr2_clk180                                      : out std_logic;
        mem0_qdr2_clk270                                      : out std_logic;
        mem0_qdr2_sys_reset                                   : out std_logic;
        -- qdr2 clock signals node 0
        mem1_qdr2_clk0                                        : out std_logic;         
        mem1_qdr2_clk180                                      : out std_logic;       
        mem1_qdr2_clk270                                      : out std_logic;
        mem1_qdr2_sys_reset                                   : out std_logic
        );
    end component;

  ---------------------------------------------------------------------------
	--M2E edge ram clock signals, now outputs:
	--signal ram_clk0 : std_logic;
	--signal ram_clk180 : std_logic;
	--signal ram_clk270 : std_logic;
	signal clk200mhz : std_logic;
    signal clk200mhz_locked : std_logic;
	signal i_ram_clk_locked_n : std_logic;
	
    -- raw oscillator clock
    signal osc_clk_c : std_logic;
    -- signal raw_clk_c : std_logic;
    
    -- the clock at which the Bluespec-Edge interface will be clocked
    --alias ifc_clk   : std_logic is osc_clk_c;
    alias ifc_clk   : std_logic is clk200mhz;
    alias ifc_rst_n : std_logic is clk200mhz_locked;
            
    -- Angshuman - we seem to need these IBUFs
    signal ram_pg_buf : std_logic;
    signal mgt_pg_buf : std_logic;

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

    signal upper_mod_lvds_comms_control: std_logic_vector(47 downto 0);

	---------------------------------------------------------------------------
	--LED and alarm signals
	signal sysmon_alarm : std_logic_vector(3 downto 0);
	signal leds : std_logic_vector(3 downto 0);

    -- Angshuman -- dummy signals to catch non-functional RAM signals from edge
    -- core. We'll let these dangle
    signal ram_pwr_on: std_logic;
    signal ram_leds  : std_logic_vector(1 downto 0);
	
	---------------------------------------------------------------------------
	-- Component declaration of usr_reg_slave_if_bram_example
	--component usr_reg_slave_if_bram_example
	--	port(
	--		clk : in std_logic;
	--		user_reg_wdata : in std_logic_vector(15 downto 0);
	--		user_reg_addr : in std_logic_vector(12 downto 0);
	--		user_reg_rden : in std_logic;
	--		user_reg_wren : in std_logic;
	--		user_reg_rdata : out std_logic_vector(15 downto 0);
	--		user_reg_rdy : out std_logic);
	--end component;	 
	
	
	---------------------------------------------------------------------------
	-- Component declaration of usr_reg_slave_if_io_example
	--component usr_reg_slave_if_io_example
	--	port(
	--		clk : in std_logic;
	--		user_reg_wdata : in std_logic_vector(15 downto 0);
	--		user_reg_addr : in std_logic_vector(12 downto 0);
	--		user_reg_rden : in std_logic;
	--		user_reg_wren : in std_logic;
	--		user_reg_rdata : out std_logic_vector(15 downto 0);
	--		user_reg_rdy : out std_logic;
	--		leds : out std_logic_vector(3 downto 0));
	--end component;
	
    component IBUFGDS
        port (O  : out STD_ULOGIC;
              I  : in STD_ULOGIC;
              IB : in STD_ULOGIC);
    end component;

    component IBUF
        port (O  : out STD_LOGIC;
              I  : in STD_LOGIC);
    end component;

begin  
	
	
	---------------------------------------------------------------------------
	--instantiate the M2E edge component configured for 4 transmit LVDS banks
	--to the M2B, 2 recieve LVDS banks from the M2B and a ram speed of 200MHz
	fsb_compute_edge_inst : system_edge_component
    generic map(
		local_id => DEVICE_ID(local_id_layer,local_id_fpga,local_id_number),
		local_module_type => FSB_COMPUTE_MOD_TYPE,
		external_id => DEVICE_ID(external_id_layer,external_id_fpga,external_id_number),
		rx_lanes => rx_lanes,
		tx_lanes => tx_lanes
        )
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

        lvds_link_sc_out => open,
        lvds_link_sc_in => (others => '0'),
		
        intra_mod_lvds_comms_control => intra_fpga_lvds_ctrl,
        upper_mod_lvds_comms_control => upper_mod_lvds_comms_control,

        eeprom_scl => eeprom_scl,
		eeprom_sda => eeprom_sda,
		sys_led_out => sys_led_out,
		ram_pwr_on => ram_pwr_on,
		ram_pg => ram_pg_buf,           -- Angshuman
		mgt_pg => mgt_pg_buf,           -- Angshuman
		
		
		-------------------------------
		--User interfaces to the M2E edge component
		-------------------------------
		--RAM clock interface -- Angshuman - these aren't RAM clocks
		osc_clk => osc_clk_c,
		clk200mhz => clk200mhz,
        clk200mhz_locked => clk200mhz_locked,

        -- Angshuman - the real RAM clocks that used to be exported from
        -- the previous version of the edge component. Now we synthesize
        -- them using a separate clocks module
		--ram_clk0 => ram_clk0,
		--ram_clk180 => ram_clk180,
		--ram_clk270 => ram_clk270,
        --ram_clk_locked => i_ram_clk_locked, 
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
		clk => ifc_clk,
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
	
    sram_clocks_module: qdr2_ddr2_clocks
    port map (
        -- Initialization control and reset
        init => open,
        pll_rst => '0',
        -- input memory clock
        sys_clk_in => osc_clk_c,
        -- sys_clk_n => clk100n,
        -- sys_clk => clk100p,
        -- ddr2 clock signals node 0
        mem0_ddr2_clk0 => open,
        mem0_ddr2_clk90 => open,
        mem0_ddr2_sys_reset => open,
        -- ddr2 clock signals node 1
        mem1_ddr2_clk0 => open,
        mem1_ddr2_clk90 => open,
        mem1_ddr2_sys_reset => open,
        -- qdr2 clock signals node 0
        mem0_qdr2_clk0 => ram_clk0,
        mem0_qdr2_clk180 => open,
        mem0_qdr2_clk270 => ram_clk270,
        mem0_qdr2_sys_reset => i_ram_clk_locked_n,
        -- qdr2 clock signals node 0
        mem1_qdr2_clk0 => open,
        mem1_qdr2_clk180 => open,
        mem1_qdr2_clk270 => open,
        mem1_qdr2_sys_reset => open
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

    -- ifc_clk is an alias of some other clock net (grep this file)

    clk_out     <= ifc_clk;
    rst_n_out   <= ifc_rst_n;
    raw_clk_out <= ifc_clk;             -- for some reason we send NOT the real
                                        -- 100MHz raw clock but the cooked 200MHz
                                        -- clock out as the "raw" clock
    ram_clk_locked <= not i_ram_clk_locked_n;
    ram_clk200     <= clk200MHz;

	-- Must tie unused lvds communications control bus slice (46 downto 30) to '0'
	upper_mod_lvds_comms_control(46 downto 30)<=(others=>'0');
	

    -- Angshuman - we seem to need these explicit IBUFs
    RAM_PG_IBUF : IBUF
      port map (
        I => ram_pg,
        O => ram_pg_buf
        );

    MGT_PG_IBUF : IBUF
      port map (
        I => mgt_pg,
        O => mgt_pg_buf
        );
    -- Angshuman end

    -- clk_ibufgds_inst : ibufgds
    -- port map (
    --   o  => raw_clk_c,
    --   i  => clk100p,
    --   ib => clk100n);
    
	---------------------------------------------------------------------------
	--User register slave interface connections
	
	--connect up the block ram example to user register port 0
	--usr_reg_slave_if_bram_example_inst : usr_reg_slave_if_bram_example
	--port map(
	--	clk => user_reg_clk,
	--	user_reg_wdata => user_reg_wdata,
	--	user_reg_addr => user_reg_addr,
	--	user_reg_rden => user_reg_rden(0),
	--	user_reg_wren => user_reg_wren(0),
	--	user_reg_rdata => user_reg_rdata0,
	--	user_reg_rdy => user_reg_rdy(0)
	--	);
	--Tie off reg_rdy instead of instantiating if_bram_example
	user_reg_rdy(0)<='0';
	
	--connect up the IO example to user register port 1
	--usr_reg_slave_if_io_example_inst : usr_reg_slave_if_io_example
	--port map(
	--	clk => user_reg_clk,
	--	user_reg_wdata => user_reg_wdata,
	--	user_reg_addr => user_reg_addr,
	--	user_reg_rden => user_reg_rden(1),
	--	user_reg_wren => user_reg_wren(1),
	--	user_reg_rdata => user_reg_rdata1,
	--	user_reg_rdy => user_reg_rdy(1),
	--	leds => leds
	--	);
	--Tie off reg_rdy instead of instantiating if_io_example
	user_reg_rdy(1)<='0';
	
    -- expose user register port 2 to Bluespec
    user_reg_clk_out   <= user_reg_clk;
    user_reg_wdata_out <= user_reg_wdata;
    user_reg_addr_out  <= user_reg_addr;
    user_reg_rden_out  <= user_reg_rden(2);
    user_reg_wren_out  <= user_reg_wren(2);
    user_reg_rdy(2)    <= user_reg_rdy_in or user_reg_wrack_in;
    user_reg_rdata2    <= user_reg_rdata_in;
    
	--tie off the user register interface port rdy signals (port 3).
	--By doing do ensuring that if port 3 is accidently accessed by
	--software that the controlling state machine within the edge and M2B
	--does not hang waiting for a response.
	user_reg_rdy(3)<='0';
	
	
end rtl;
