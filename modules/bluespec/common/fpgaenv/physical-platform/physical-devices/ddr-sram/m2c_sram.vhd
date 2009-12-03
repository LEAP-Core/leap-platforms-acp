----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:38:04 07/23/2009 
-- Design Name: 
-- Module Name:    m2c_sram - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity m2c_sram is
	PORT(	
		-- SRAM 1 physical connections -------
	   masterbank_sel_pin : IN std_logic_vector(0 to 0);
		ddrii_cq : IN std_logic_vector(0 to 0);
		ddrii_cq_n : IN std_logic_vector(0 to 0);    
		ddrii_dq : INOUT std_logic_vector(35 downto 0);      
		ddrii_sa : OUT std_logic_vector(20 downto 0);
		ddrii_ld_n : OUT std_logic;
		ddrii_rw_n : OUT std_logic;
		ddrii_dll_off_n : OUT std_logic;
		ddrii_bw_n : OUT std_logic_vector(3 downto 0);
		ddrii_k : OUT std_logic_vector(0 to 0);
		ddrii_k_n : OUT std_logic_vector(0 to 0);
		cal_done : OUT std_logic;
		compare_error : OUT std_logic; 
				
				
	--- SRAM 2 physical connections -------
		masterbank_sel_pin_2 : IN std_logic_vector(0 to 0);
		ddrii_cq_2 : IN std_logic_vector(0 to 0);
		ddrii_cq_n_2 : IN std_logic_vector(0 to 0);    
		ddrii_dq_2 : INOUT std_logic_vector(35 downto 0);      
		ddrii_sa_2 : OUT std_logic_vector(20 downto 0);
		ddrii_ld_n_2 : OUT std_logic;
		ddrii_rw_n_2 : OUT std_logic;
		ddrii_dll_off_n_2 : OUT std_logic;
		ddrii_bw_n_2 : OUT std_logic_vector(3 downto 0);
		ddrii_k_2 : OUT std_logic_vector(0 to 0);
		ddrii_k_n_2 : OUT std_logic_vector(0 to 0);
		cal_done_2 : OUT std_logic;
		compare_error_2 : OUT std_logic; 
		
				
				
		-- MISC physical connections -----------


		CLK100_P 		: in std_logic;
		CLK100_N			: in std_logic;
		RAM_PWR_ON		: out std_logic;
		LED				: out std_logic_vector(1 downto 0)

);


end m2c_sram;

architecture Behavioral of m2c_sram is


--------- SRAM  Mem Interface ------------
	COMPONENT mig_31
	GENERIC ( IODELAY_GRP    : string  := "IODELAY_MIG" );
	PORT(
		masterbank_sel_pin : IN std_logic_vector(0 to 0);
		sys_rst_n : IN std_logic;
		locked : IN std_logic;
		clk_0 : IN std_logic;
		clk_270 : IN std_logic;
		clk_200 : IN std_logic;
		reset_clk_200 : out 	std_logic;
      idelay_ctrl_ready  : in std_logic;
		ddrii_cq : IN std_logic_vector(0 to 0);
		ddrii_cq_n : IN std_logic_vector(0 to 0);    
		ddrii_dq : INOUT std_logic_vector(35 downto 0);      
		ddrii_sa : OUT std_logic_vector(20 downto 0);
		ddrii_ld_n : OUT std_logic;
		ddrii_rw_n : OUT std_logic;
		ddrii_dll_off_n : OUT std_logic;
		ddrii_bw_n : OUT std_logic_vector(3 downto 0);
		cal_done : OUT std_logic;
		compare_error : OUT std_logic;
		error_count	  : out   std_logic_vector(7 downto 0); --DEBUG
		dbg_compare_rise	  	: out std_logic_vector(35 downto 0);
	   dbg_read_rise		   : out std_logic_vector(35 downto 0);
		dbg_compare_fall	  	: out std_logic_vector(35 downto 0);
	   dbg_read_fall		   : out std_logic_vector(35 downto 0);
		ddrii_k : OUT std_logic_vector(0 to 0);
		ddrii_k_n : OUT std_logic_vector(0 to 0);
		ddrii_c : OUT std_logic_vector(0 to 0);
		ddrii_c_n : OUT std_logic_vector(0 to 0)
		);
	END COMPONENT;

	signal cal_done_mig 			: std_logic;
	signal compare_error_mig 	: std_logic;
   signal sys_rst_n 				:  std_logic;
	signal locked					:  std_logic;
	signal clk_0 					:  std_logic;
	signal clk_270					:  std_logic;
	signal clk_200					:  std_logic;
	
	
	signal cal_done_mig_2 			: std_logic;
	signal compare_error_mig_2 	: std_logic;
   signal sys_rst_n_2 				:  std_logic;
	signal locked_2					:  std_logic;
	signal clk_0_2 					:  std_logic;
	signal clk_270_2					:  std_logic;
	signal clk_200_2					:  std_logic;

	
------------ Clocking -------------

	COMPONENT m2c_clocking
	PORT(
		clk100p : IN std_logic;
		clk100n : IN std_logic;
		reset_ram_clk : IN std_logic;          
		clk100_raw : OUT std_logic;
		clk200mhz : OUT std_logic;
		ram_clk0 : OUT std_logic;
		ram_clk270 : OUT std_logic;
			ram_clk180 : out std_logic;
	--	ram_clk400 : OUT std_logic;
		ram_clk_locked : OUT std_logic
		);
	END COMPONENT;

signal 	ram_clk180 : std_logic;
--signal ram_clk400 : std_logic;
signal clk200mhz : std_logic;
signal ram_clk0  : std_logic;
signal ram_clk270 : std_logic;
signal reset_ram_clk : std_logic;


--- chipscope --------------
signal error_count	 			 :  std_logic_vector(7 downto 0); --DEBUG
signal error_count_2  			 :  std_logic_vector(7 downto 0); --DEBUG
signal dbg_compare_rise	 :  std_logic_vector(35 downto 0);
signal dbg_read_rise		 :  std_logic_vector(35 downto 0);
signal dbg_compare_rise_2	 :  std_logic_vector(35 downto 0);
signal dbg_read_rise_2		 :  std_logic_vector(35 downto 0);

signal dbg_compare_fall	 :  std_logic_vector(35 downto 0);
signal dbg_read_fall		 :  std_logic_vector(35 downto 0);
signal dbg_compare_fall_2	 :  std_logic_vector(35 downto 0);
signal dbg_read_fall_2		 :  std_logic_vector(35 downto 0);

component icon_control
  PORT (
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL1 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));

end component;

signal CONTROL0 : STD_LOGIC_VECTOR(35 DOWNTO 0);
signal CONTROL1 : STD_LOGIC_VECTOR(35 DOWNTO 0);

component cs_ila
  PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;
    TRIG0 : IN STD_LOGIC_VECTOR(163 DOWNTO 0);
	 TRIG1 : IN STD_LOGIC_VECTOR(143 DOWNTO 0)
	 );
end component;

signal TRIG0 :  STD_LOGIC_VECTOR(163 DOWNTO 0);
signal TRIG1 :  STD_LOGIC_VECTOR(143 DOWNTO 0);
signal TRIG2 :  STD_LOGIC_VECTOR(163 DOWNTO 0);
signal TRIG3 :  STD_LOGIC_VECTOR(143 DOWNTO 0);

----------- IDELAYCTRL Signals ----------------
--constant IODELAY_GRP : string := "IODELAY_MIG_2";
--constant IODELAY_GRP_2 : string := "IODELAY_MIG";

attribute IODELAY_GROUP : string;

attribute IODELAY_GROUP of U_IDELAYCTRL : label is "IODELAY_MIG";
attribute IODELAY_GROUP of U_IDELAYCTRL_2 : label is "IODELAY_MIG_2";

signal	reset_clk_200  : std_logic;
signal	idelay_ctrl_ready : std_logic;
signal 	idlyclk_200			: std_logic;
	
signal	reset_clk_200_2  : std_logic;
signal	idelay_ctrl_ready_2 : std_logic;
signal 	idlyclk_200_2			: std_logic;

begin
----------------------------- BEGIN -----------------------

  U_IDELAYCTRL : IDELAYCTRL
   port map (
     RDY    => idelay_ctrl_ready,
     REFCLK => clk_200,
     RST    => reset_clk_200
     );
	  
	
	  
	  
  U_IDELAYCTRL_2 : IDELAYCTRL
   port map (
     RDY    => idelay_ctrl_ready_2,
     REFCLK => clk_200_2,
     RST    => reset_clk_200_2
     );

idlyclk_200	<= clk200mhz;
idlyclk_200_2	<= clk200mhz;
---------------------------------------

RAM_PWR_ON <= '1'; 

LED(0) <= '1';
LED(1) <= '1';

-------- Clocking Instance ------
	Inst_m2c_clocking: m2c_clocking PORT MAP(
		clk100p => CLK100_P,
		clk100n => CLK100_N,
		clk100_raw => open,
		reset_ram_clk => reset_ram_clk,
		clk200mhz => clk200mhz,
		ram_clk0 => ram_clk0,
		ram_clk270 => ram_clk270,
			ram_clk180 => 	ram_clk180,
		--ram_clk400 => ram_clk400,
		ram_clk_locked => locked 
	);

 reset_ram_clk <= '0'; --gnd clock resets
 
 locked <= locked;				
 clk_0  <=	ram_clk0;	
 clk_270	<=	ram_clk270;
 clk_200	<= clk200mhz;
			
 locked_2 <= locked;				
 clk_0_2  <= ram_clk0;			
 clk_270_2 <= ram_clk270;				
 clk_200_2 <=	clk200mhz;	


------ SRAM for RAM 1 or RAM 6 instance ----
	Inst_mig_31_1: mig_31
	generic map ( IODELAY_GRP => "IODELAY_MIG"	)
	PORT MAP(
		ddrii_dq => ddrii_dq,
		ddrii_sa => ddrii_sa,
		ddrii_ld_n => ddrii_ld_n,
		ddrii_rw_n => ddrii_rw_n,
		ddrii_dll_off_n => ddrii_dll_off_n,
		ddrii_bw_n => ddrii_bw_n,
		masterbank_sel_pin => masterbank_sel_pin,
		sys_rst_n => sys_rst_n,
		cal_done => cal_done_mig,
		compare_error => compare_error_mig,
		error_count	=> error_count, --DEBUG
		dbg_compare_rise	 => dbg_compare_rise,
	   dbg_read_rise		 => dbg_read_rise,
		dbg_compare_fall	 => dbg_compare_fall,
	   dbg_read_fall		 => dbg_read_fall,
		locked => locked,
		clk_0 => clk_0,
		clk_270 => clk_270,
		clk_200 => clk_200,
		reset_clk_200  =>	reset_clk_200,
		idelay_ctrl_ready => idelay_ctrl_ready,	
		ddrii_cq => ddrii_cq,
		ddrii_cq_n => ddrii_cq_n,
		ddrii_k => ddrii_k,
		ddrii_k_n => ddrii_k_n, 		
		ddrii_c => open,
		ddrii_c_n => open 
	);
sys_rst_n <= '1'; -- mig reset
cal_done_2 <= cal_done_mig_2; -- from mig to pin
compare_error_2 <= compare_error_mig_2; -- from mig to pin

------ SRAM for RAM 2 or RAM 5 instance ----
	Inst_mig_31_2: mig_31
	generic map ( IODELAY_GRP => "IODELAY_MIG_2"	)
	PORT MAP(
		ddrii_dq => ddrii_dq_2,
		ddrii_sa => ddrii_sa_2,
		ddrii_ld_n => ddrii_ld_n_2,
		ddrii_rw_n => ddrii_rw_n_2,
		ddrii_dll_off_n => ddrii_dll_off_n_2,
		ddrii_bw_n => ddrii_bw_n_2,
		masterbank_sel_pin => masterbank_sel_pin_2,
		sys_rst_n => sys_rst_n_2,
		cal_done => cal_done_mig_2,
		compare_error => compare_error_mig_2,
		locked => locked_2,
		error_count	=> error_count_2, --DEBUG
		dbg_compare_rise	=> dbg_compare_rise_2,
	   dbg_read_rise	 => dbg_read_rise_2,
		dbg_compare_fall	=> dbg_compare_fall_2,
	   dbg_read_fall	 => dbg_read_fall_2,
		clk_0 => clk_0_2,
		clk_270 => clk_270_2,
		clk_200 => clk_200_2,
		reset_clk_200  =>	reset_clk_200_2,
		idelay_ctrl_ready => idelay_ctrl_ready_2,
		ddrii_cq => ddrii_cq_2,
		ddrii_cq_n => ddrii_cq_n_2,
		ddrii_k => ddrii_k_2,
		ddrii_k_n => ddrii_k_n_2,
		ddrii_c => open,
		ddrii_c_n => open 
	);
sys_rst_n_2 <= '1'; -- mig reset
cal_done <= cal_done_mig; -- from mig to pin
compare_error <= compare_error_mig; -- from mig to pin


----------- chipscope instances ------
the_icon : icon_control
  port map (
    CONTROL0 => CONTROL0,
    CONTROL1 => CONTROL1);


debug_ila : cs_ila
  port map (
    CONTROL => CONTROL0,
    CLK => CLK_0,
	-- CLK => ram_clk400,
	--CLK => ram_clk180,
    TRIG0 => TRIG0,
	 TRIG1 => TRIG1
	 );
	 
debug_ila_2 : cs_ila
  port map (
    CONTROL => CONTROL1,
   -- CLK => CLK_0,
	-- CLK => ram_clk400,
	CLK => ram_clk180,
    TRIG0 => TRIG2,
	 TRIG1 => TRIG3
	 );
	 
-- TRIG0 is 163 downto 0, so MSB first -- 
TRIG0 <= cal_done_mig & compare_error_mig & error_count & dbg_compare_rise & dbg_read_rise
				& cal_done_mig_2 & compare_error_mig_2 & error_count_2 & dbg_compare_rise_2 & dbg_read_rise_2;
-- TRIG0 is 143 downto 0, so MSB first -- 
TRIG3 <= (others=>'0');
TRIG2 <= (others=>'0');
TRIG1 <=	dbg_read_fall & dbg_compare_fall & dbg_read_fall_2 &	dbg_compare_fall_2;
	   
			
	 
------------------------------------------------------
end Behavioral;

