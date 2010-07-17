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
-- external_id refers to the target that we communicate with
entity nallatech_intra_vhdl is
        -- these generics allow us to share code with the null module
        generic(local_id_layer: integer;  -- layer i.e. sw is 0, all fpgas have
                                          -- 1
                local_id_fpga: integer;  -- fpga number, within layer (0,1)
                local_id_number: integer;  -- ?? appears to always be 0
                external_id_layer: integer; 
                external_id_fpga: integer;
                external_id_number: integer;
                rx_lanes: integer;
                tx_lanes: integer;
               );
	port( 

        -- top level wires
      
		clk100 : in std_logic;
                srst : in std_logic;
                
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
        
	        
        -- user interface (channel)
        
        tx_data_valid    : in std_logic;
        tx_data          : in std_logic_vector(255 downto 0);
        tx_data_not_full : out std_logic;

        rx_data_read     : in std_logic;
        rx_data_ready    : out std_logic; 
        rx_data          : out std_logic_vector(255 downto 0);

        -- intra fpga interface
        intra_fpga_lvds_ctrl : inout  std_logic_vector(47 downto 0);
		);	
end nallatech_intra_vhdl;

architecture rtl of nallatech_intra_vhdl is
        signal link_complete_c : std_logic;
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
      		clk100 <= clk100,
		srst <= srst,
		link_complete <= link_complete_c,
		lvds_rx_lane_p <= lvds_rx_lane_p,
		lvds_rx_lane_n <= lvds_rx_lane_n, 
		lvds_rx_clk_p <= lvds_rx_clk_p, 
		lvds_rx_clk_n <= lvds_rx_clk_n,
		lvds_tx_lane_p <= lvds_tx_lane_p,
		lvds_tx_lane_n <= lvds_tx_lane_n,
		lvds_tx_clk_p <= lvds_tx_clk_p,
		lvds_tx_clk_n <= lvds_tx_clk_n,
		lvds_comms_control <= intra_fpga_lvds_ctrl,

		sys_clk => ifc_clk,
		tx_data_valid => tx_data_valid_c,
		
		tx_data => tx_data_c,
		tx_data_almost_full => tx_data_almost_full_c,
		rx_data_valid => rx_data_valid_c,	
		rx_data_read=>rx_data_read_c,
		rx_data_empty=>rx_data_empty_c,
		rx_data => rx_data_c
                
		);
	
	---------------------------------------------------------------------------
	-- patch FIFO interface

    -- we made need to observe that the link is complete
    tx_data_valid_c  <= tx_data_valid;
    tx_data_c        <= tx_data;
    tx_data_not_full <= (not tx_data_almost_full_c) and link_complete_c;

    rx_data_read_c   <= rx_data_read;
    rx_data_ready    <= (not rx_data_empty_c) and link_complete_c;
    rx_data          <= rx_data_c;

end rtl;
