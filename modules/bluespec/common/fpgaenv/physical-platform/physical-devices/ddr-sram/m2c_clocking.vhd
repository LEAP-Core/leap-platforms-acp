library IEEE;
use IEEE.STD_LOGIC_1164.all;	

library unisim;
use unisim.vcomponents.all;

entity m2c_clocking is		   

	port(
		
		clk100p:in std_logic;
		clk100n:in std_logic;
		
		clk100_raw:out std_logic;
		
		reset_ram_clk:in std_logic;
		clk200mhz:out std_logic;  
		ram_clk0:out std_logic;
	--	ram_clk90:out std_logic;
		ram_clk270:out std_logic;
		ram_clk180:out std_logic;
		--ram_clk400 : out std_logic;
		ram_clk_locked:out std_logic
		

		);
	
end m2c_clocking;

architecture rtl of m2c_clocking is
	
	signal clk100_bufg:std_logic;
	
	
	component PLL_ADV
		generic (
			BANDWIDTH              :     string;
			CLKFBOUT_DESKEW_ADJUST :     string;
			CLKFBOUT_MULT          :     integer;
			CLKFBOUT_PHASE         :     real;
			CLKIN1_PERIOD          :     real;
			CLKIN2_PERIOD          :     real;
			CLKOUT0_DESKEW_ADJUST  :     string;
			CLKOUT0_DIVIDE         :     integer;
			CLKOUT0_DUTY_CYCLE     :     real;
			CLKOUT0_PHASE          :     real;
			CLKOUT1_DESKEW_ADJUST  :     string;
			CLKOUT1_DIVIDE         :     integer;
			CLKOUT1_DUTY_CYCLE     :     real;
			CLKOUT1_PHASE          :     real;
			CLKOUT2_DESKEW_ADJUST  :     string;
			CLKOUT2_DIVIDE         :     integer;
			CLKOUT2_DUTY_CYCLE     :     real;
			CLKOUT2_PHASE          :     real;
			CLKOUT3_DESKEW_ADJUST  :     string;
			CLKOUT3_DIVIDE         :     integer;
			CLKOUT3_DUTY_CYCLE     :     real;
			CLKOUT3_PHASE          :     real;
			CLKOUT4_DESKEW_ADJUST  :     string;
			CLKOUT4_DIVIDE         :     integer;
			CLKOUT4_DUTY_CYCLE     :     real;
			CLKOUT4_PHASE          :     real;
			CLKOUT5_DESKEW_ADJUST  :     string;
			CLKOUT5_DIVIDE         :     integer;
			CLKOUT5_DUTY_CYCLE     :     real;
			CLKOUT5_PHASE          :     real;
			COMPENSATION           :     string;
			DIVCLK_DIVIDE          :     integer;
			EN_REL                 :     boolean;
			PLL_PMCD_MODE          :     boolean;
			REF_JITTER             :     real;
			RESET_ON_LOSS_OF_LOCK  :     boolean;
			RST_DEASSERT_CLK       :     string);
		port (
			CLKFBDCM               : out std_ulogic := '0';
			CLKFBOUT               : out std_ulogic := '0';
			CLKOUT0                : out std_ulogic := '0';
			CLKOUT1                : out std_ulogic := '0';
			CLKOUT2                : out std_ulogic := '0';
			CLKOUT3                : out std_ulogic := '0';
			CLKOUT4                : out std_ulogic := '0';
			CLKOUT5                : out std_ulogic := '0';
			CLKOUTDCM0             : out std_ulogic := '0';
			CLKOUTDCM1             : out std_ulogic := '0';
			CLKOUTDCM2             : out std_ulogic := '0';
			CLKOUTDCM3             : out std_ulogic := '0';
			CLKOUTDCM4             : out std_ulogic := '0';
			CLKOUTDCM5             : out std_ulogic := '0';
			DO                     : out std_logic_vector(15 downto 0);
			DRDY                   : out std_ulogic := '0';
			LOCKED                 : out std_ulogic := '0';
			CLKFBIN                : in  std_ulogic;
			CLKIN1                 : in  std_ulogic;
			CLKIN2                 : in  std_ulogic;
			CLKINSEL               : in  std_ulogic;
			DADDR                  : in  std_logic_vector(4 downto 0);
			DCLK                   : in  std_ulogic;
			DEN                    : in  std_ulogic;
			DI                     : in  std_logic_vector(15 downto 0);
			DWE                    : in  std_ulogic;
			REL                    : in  std_ulogic;
			RST                    : in  std_ulogic);
	end component;
	
	
	component BUFG
		port (
			O : out std_ulogic;
			I : in  std_ulogic);
	end component;
	
	
	signal clk200_pll_fb, clk200_pll, clk200_locked:std_logic; 
	
	signal ram_pll_clkfb, ram_clk0_pll, ram_clk180_pll, ram_clk270_pll, ram_clk90_pll, ram_pll_locked:std_logic;
	--signal ram_clk400_pll : std_logic;
		
	---------------------------------------------------------------------------
	--function to calculate the pll multiplication value for the RAM PLL 
	--depending on the value of ram_speed which is the ram speed in MHz
	function ram_mult_val(ram_speed:integer) return integer is
	begin	

		return (2*ram_speed)/100;					  

	end function ram_mult_val;
	
	
	
begin
	
	clk100_ibufgds_inst:ibufgds_lvds_25
	port map(i=>clk100p, ib=>clk100n, o=>clk100_bufg);
	
	clk100_raw<=clk100_bufg;
	
	--multiply up the clk100 to provide clk200 using a pll. 
	clk200_pll_adv_inst : pll_adv
	generic map (
		BANDWIDTH              => "OPTIMIZED",
		CLKFBOUT_DESKEW_ADJUST => "NONE",
		CLKFBOUT_MULT          => 4,
		CLKFBOUT_PHASE         => 0.0,
		CLKIN1_PERIOD          => 10.0,
		CLKIN2_PERIOD          => 1.000,
		CLKOUT0_DESKEW_ADJUST  => "NONE",
		CLKOUT0_DIVIDE         => 2,
		CLKOUT0_DUTY_CYCLE     => 0.5,
		CLKOUT0_PHASE          => 0.0,
		CLKOUT1_DESKEW_ADJUST  => "NONE",
		CLKOUT1_DIVIDE         => 2,
		CLKOUT1_DUTY_CYCLE     => 0.5,
		CLKOUT1_PHASE          => 180.0,
		CLKOUT2_DESKEW_ADJUST  => "NONE",
		CLKOUT2_DIVIDE         => 2,
		CLKOUT2_DUTY_CYCLE     => 0.5,
		CLKOUT2_PHASE          => 270.0,
		CLKOUT3_DESKEW_ADJUST  => "NONE",
		CLKOUT3_DIVIDE         => 2,
		CLKOUT3_DUTY_CYCLE     => 0.5,
		CLKOUT3_PHASE          => 0.0,
		CLKOUT4_DESKEW_ADJUST  => "NONE",
		CLKOUT4_DIVIDE         => 1,
		CLKOUT4_DUTY_CYCLE     => 0.5,
		CLKOUT4_PHASE          => 0.0,
		CLKOUT5_DESKEW_ADJUST  => "NONE",
		CLKOUT5_DIVIDE         => 1,
		CLKOUT5_DUTY_CYCLE     => 0.5,
		CLKOUT5_PHASE          => 0.0,
		COMPENSATION           => "SYSTEM_SYNCHRONOUS",
		DIVCLK_DIVIDE          => 1,
		EN_REL                 => false,
		PLL_PMCD_MODE          => false,
		REF_JITTER             => 0.100,
		RESET_ON_LOSS_OF_LOCK  => false,
		RST_DEASSERT_CLK       => "CLKIN1")
	port map (
		CLKFBDCM               => open,                     -- out 
		CLKFBOUT               => clk200_pll_fb,                -- out 
		CLKOUT0                => clk200_pll,           	  -- out 
		CLKOUT1                => open,            	  -- out 
		CLKOUT2                => open,               -- out 
		CLKOUT3                => open,                     -- out 
		CLKOUT4                => open,                     -- out 
		CLKOUT5                => open,                     -- out 
		CLKOUTDCM0             => open,                     -- out 
		CLKOUTDCM1             => open,                     -- out 
		CLKOUTDCM2             => open,                     -- out 
		CLKOUTDCM3             => open,                     -- out 
		CLKOUTDCM4             => open,                     -- out 
		CLKOUTDCM5             => open,                     -- out 
		DO                     => open,                     -- out 
		DRDY                   => open,                     -- out 
		LOCKED                 => clk200_locked,               -- out 
		CLKFBIN                => clk200_pll_fb,                -- in  
		CLKIN1                 => clk100_bufg,             -- in  
		CLKIN2                 => '0',            -- in  
		CLKINSEL               => '1',                      -- in  
		DADDR                  => (others=>'0'),   -- in  
		DCLK                   => '0',            -- in  
		DEN                    => '0',            -- in  
		DI                     => (others=>'0'),  -- in  
		DWE                    => '0',            -- in  
		REL                    => '0',            -- in  
		RST                    => reset_ram_clk);   
	
	
	
	clk200_inst : BUFG
	port map (I=>clk200_pll,
		O=>clk200mhz);	 
	
	
	
	---------------------------------------------------------------------------
	--ram clocks															   
	ram_pll_adv_inst : PLL_ADV
	generic map (
		BANDWIDTH              => "OPTIMIZED",
		CLKFBOUT_DESKEW_ADJUST => "NONE",
		CLKFBOUT_MULT          => 4,
		CLKFBOUT_PHASE         => 0.0,
		CLKIN1_PERIOD          => 10.0,
		CLKIN2_PERIOD          => 1.000,
		CLKOUT0_DESKEW_ADJUST  => "NONE",
		CLKOUT0_DIVIDE         => 2,
		CLKOUT0_DUTY_CYCLE     => 0.5,
		CLKOUT0_PHASE          => 0.0,
		CLKOUT1_DESKEW_ADJUST  => "NONE",
		CLKOUT1_DIVIDE         => 2,
		CLKOUT1_DUTY_CYCLE     => 0.5,
		CLKOUT1_PHASE          => 180.0,
		CLKOUT2_DESKEW_ADJUST  => "NONE",
		CLKOUT2_DIVIDE         => 2,
		CLKOUT2_DUTY_CYCLE     => 0.5,
		CLKOUT2_PHASE          => 270.0,
		CLKOUT3_DESKEW_ADJUST  => "NONE",
		CLKOUT3_DIVIDE         => 2,
		CLKOUT3_DUTY_CYCLE     => 0.5,
		CLKOUT3_PHASE          => 90.0,
		CLKOUT4_DESKEW_ADJUST  => "NONE",
		CLKOUT4_DIVIDE         => 1,
		CLKOUT4_DUTY_CYCLE     => 0.5,
		CLKOUT4_PHASE          => 0.0,
		CLKOUT5_DESKEW_ADJUST  => "NONE",
		CLKOUT5_DIVIDE         => 1,
		CLKOUT5_DUTY_CYCLE     => 0.5,
		CLKOUT5_PHASE          => 0.0,
		COMPENSATION           => "SYSTEM_SYNCHRONOUS",
		DIVCLK_DIVIDE          => 1,
		EN_REL                 => false,
		PLL_PMCD_MODE          => false,
		REF_JITTER             => 0.100,
		RESET_ON_LOSS_OF_LOCK  => false,
		RST_DEASSERT_CLK       => "CLKIN1")
	port map (
		CLKFBDCM               => open,                     -- out 
		CLKFBOUT               => ram_pll_clkfb,                -- out 
		CLKOUT0                => ram_clk0_pll,           	  -- out 
		CLKOUT1                => ram_clk180_pll,            	  -- out 
		--CLKOUT1					 => open,	
		CLKOUT2                => ram_clk270_pll,               -- out 
--		CLKOUT3                => ram_clk90_pll,                     -- out 
		CLKOUT3                => open,                     -- out 
		CLKOUT4                => open,                     -- out 
		CLKOUT5                => open,                     -- out 
		CLKOUTDCM0             => open,                     -- out 
		CLKOUTDCM1             => open,                     -- out 
		CLKOUTDCM2             => open,                     -- out 
		CLKOUTDCM3             => open,                     -- out 
		CLKOUTDCM4             => open,                     -- out 
		CLKOUTDCM5             => open,                     -- out 
		DO                     => open,                     -- out 
		DRDY                   => open,                     -- out 
		LOCKED                 => ram_pll_locked,               -- out 
		CLKFBIN                => ram_pll_clkfb,                -- in  
		CLKIN1                 => clk100_bufg,             -- in  
		CLKIN2                 => '0',            -- in  
		CLKINSEL               => '1',                      -- in  
		DADDR                  => (others=>'0'),   -- in  
		DCLK                   => '0',            -- in  
		DEN                    => '0',            -- in  
		DI                     => (others=>'0'),  -- in  
		DWE                    => '0',            -- in  
		REL                    => '0',            -- in  
		RST                    => reset_ram_clk);   
	
	ram_clk0_bufg_inst : bufg
	port map (
		O => ram_clk0,                  
		I => ram_clk0_pll);
	
	ram_clk180_bufg_inst : bufg
	port map (
		O => ram_clk180,               
		I => ram_clk180_pll);	
	
	-- ram_clk400_bufg_inst : bufg
--	port map (
	--	O => ram_clk400,               
	--	I => ram_clk400_pll);
	
	
	
	ram_clk270_bufg : bufg
	port map (
		O => ram_clk270,               
		I => ram_clk270_pll);	
	  
		
	--		ram_clk90_bufg : bufg
--	port map (
--		O => ram_clk90,               
--		I => ram_clk90_pll);	
	
	ram_clk_locked_def:ram_clk_locked<=ram_pll_locked and clk200_locked;
		
	
	
end rtl;