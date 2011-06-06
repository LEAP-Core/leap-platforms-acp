--Revision number:: $Rev: 3456 $ Date:: $Date: 2008-06-20 15:57:17 +0100 (Fri, 20 Jun 2008) $
--------------------------------
--                                                                       --
--     NALLATECH IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"  --
--     BY PROVIDING THIS DESIGN, CODE, OR INFORMATION                    --
--     AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION       --
--     OR STANDARD, NALLATECH IS MAKING NO REPRESENTATION THAT THIS      --
--     IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,           --
--     AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE  --
--     FOR YOUR IMPLEMENTATION.  NALLATECH EXPRESSLY DISCLAIMS ANY       --
--     WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE           --
--     IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR    --
--     REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF   --
--     INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   --
--     FOR A PARTICULAR PURPOSE.                                         --
--                                                                       --
--     Nallatech products are not intended for use in life support       --
--     appliances, devices, or systems. Use in such applications are     --
--     expressly prohibited.                                             --
---------------------------------------------------------------------------
-- Title       : DDR2/QDR2 Memory Clocks Module
-- Project     : DIMEtalk
-- File        : ddr2_clocks_v5.vhd
---------------------------------------------------------------------------
-- Description :
--
-- This module provides the clocks required to interface to DDR2/QDR2 
-- SDRAM and SRAM on V5 products.
--
-- Note the memories run at either 200MHz or 250MHz depending on what the 
-- generic, memory_clk_speed, has been set to.
--
-- If memory_clk_speed is set to 0 (default) then the component will output
-- the clock speed as 200MHz.
-- 
-- If memory_clk_speed is set to 1 then the component will output the clock
-- speed of 250MHz.
--
---------------------------------------------------------------------------
-- Known Issues and Omissions :
--  - none
--
---------------------------------------------------------------------------
--     (c) Copyright 1995-2009 Nallatech Ltd.                            --
--     All rights reserved.                                              --
---------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

-- pragma translate_off
library unisim;
-- pragma translate_on

entity qdr2_ddr2_clocks is
  generic (
    idelayctrl_use                                        : boolean := false;
    memory_clk_speed                                      : integer := 0
    );
  port (
    -- Initialization control and reset
    init                                                  : out std_logic;
    pll_rst                                               : in  std_logic;
    -- input memory clock -- Angshuman: single-ended input
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
          attribute dtinfo_sram_if_icon                               : string;
          attribute dtinfo_sram_if_icon of qdr2_ddr2_clocks           : entity is "icon=Memory-QDR2-clock.bmp";
          attribute dtinfo_sram_if_color                              : string;
          attribute dtinfo_sram_if_color of qdr2_ddr2_clocks          : entity is "color=0x00deff00";
          attribute dtinfo_sram_if_description                        : string;
          attribute dtinfo_sram_if_description of qdr2_ddr2_clocks    : entity is "description=Virtex-5 DDR2/QDR2 Memory Clocks Module";
          attribute dtinfo_sram_if_shortdesc                          : string;
          attribute dtinfo_sram_if_shortdesc of qdr2_ddr2_clocks      : entity is "shortdesc=V5 DDR2/QDR2 Memory Clocks Module";
          attribute dtinfo_sram_if_enumerated                         : string;
          attribute dtinfo_sram_if_enumerated of qdr2_ddr2_clocks     : entity is "enumerated=1";
          attribute dtinfo_sram_if_type                               : string;
          attribute dtinfo_sram_if_type of qdr2_ddr2_clocks           : entity is "type=8";
          attribute dtinfo                                            : string;
          attribute dtinfo of init                                    : signal is "usergroup, InitializationControl";
          -- attribute dtinfo of sys_clk_n                               : signal is "usergroup, InputClock";
          attribute dtinfo of mem0_ddr2_clk0                          : signal is "usergroup, DDR2Core0ClockSignals";
          attribute dtinfo of mem1_ddr2_clk0                          : signal is "usergroup, DDR2Core1ClockSignals";
          attribute dtinfo of mem0_qdr2_clk0                          : signal is "usergroup, QDR2Core0ClockSignals";
          attribute dtinfo of mem1_qdr2_clk0                          : signal is "usergroup, QDR2Core1ClockSignals";
end entity qdr2_ddr2_clocks;

architecture rtl of qdr2_ddr2_clocks is

  -------------------------------------------------------------------------------
  -- component declarations
  -------------------------------------------------------------------------------

  component IBUFGDS
    port
      (
        O  : out std_ulogic;
        I  : in  std_ulogic;
        IB : in  std_ulogic
        );
  end component;

  component BUFG
    port
      (
        O : out std_ulogic;
        I : in  std_ulogic
        );
  end component;
  
  component PLL_BASE
  generic (
    BANDWIDTH                 : string;
    CLKFBOUT_MULT             : integer;
    CLKFBOUT_PHASE            : real;
    CLKIN_PERIOD              : real;
    CLKOUT0_DIVIDE            : integer;
    CLKOUT0_DUTY_CYCLE        : real;
    CLKOUT0_PHASE             : real;
    CLKOUT1_DIVIDE            : integer;
    CLKOUT1_DUTY_CYCLE        : real;
    CLKOUT1_PHASE             : real;
    CLKOUT2_DIVIDE            : integer;
    CLKOUT2_DUTY_CYCLE        : real;
    CLKOUT2_PHASE             : real;
    CLKOUT3_DIVIDE            : integer;
    CLKOUT3_DUTY_CYCLE        : real;
    CLKOUT3_PHASE             : real;
    CLKOUT4_DIVIDE            : integer;
    CLKOUT4_DUTY_CYCLE        : real;
    CLKOUT4_PHASE             : real;
    CLKOUT5_DIVIDE            : integer;
    CLKOUT5_DUTY_CYCLE        : real;
    CLKOUT5_PHASE             : real;
    COMPENSATION              : string;
    DIVCLK_DIVIDE             : integer;
    REF_JITTER                : real;
    RESET_ON_LOSS_OF_LOCK     : boolean
    );
  port (
    CLKFBOUT : out std_logic;
    CLKOUT0  : out std_logic;
    CLKOUT1  : out std_logic;
    CLKOUT2  : out std_logic;
    CLKOUT3  : out std_logic;
    CLKOUT4  : out std_logic;
    CLKOUT5  : out std_logic;
    LOCKED   : out std_logic;
    CLKFBIN  : in  std_logic;
    CLKIN    : in  std_logic;
    RST      : in  std_logic
    );
  end component;

  
  component IDELAYCTRL
  port (
    RDY           : out std_ulogic;
    REFCLK        : in  std_ulogic;
    RST           : in  std_ulogic
    );
  end component;
  
  component reset_synchroniser
  generic (
    depth       : integer
    );
  port (
    clock       : in  std_logic;
    async_reset : in  std_logic;
    sync_reset  : out std_logic
    );
  end component;
  
  -------------------------------------------------------------------------------
  -- signal declarations
  -------------------------------------------------------------------------------

  signal clk0_pmcd_in           : std_logic;
  signal clk90_pmcd_in          : std_logic;
  signal clk0_bufg_in           : std_logic;
  signal clk90_bufg_in          : std_logic;
  -- signal sys_clk_in             : std_logic; Angshuman - comes in as an input
  signal idly_clk               : std_logic;
  signal idly_clk_pll_fb        : std_logic;
  signal idly_clk_pll_bufg_in   : std_logic; 
  signal idly_clk_pll_lock      : std_logic;
  signal idly_clk_pll_lock_not  : std_logic;
  signal mem_refresh_clk        : std_logic;
  signal pll_locked_not         : std_logic;
  signal sys_reset              : std_logic;
  signal idlyctrl_rst           : std_logic;
  signal pmcd_pll_fb            : std_logic;
  signal clk180_bufg_in         : std_logic;
  signal clk270_bufg_in         : std_logic;
  signal pmcd_pll_lock          : std_logic;
  signal mem_clk0               : std_logic;
  signal mem_clk90              : std_logic;
  signal mem_clk180             : std_logic;
  signal mem_clk270             : std_logic;
  signal init_i                 : std_logic;
  signal idly_ctrl_rdy          : std_logic;
  
  
begin

  -------------------------------------------------------------------------
  -- The global init signal is asserted for simulation purposes
  -- then released. This is synthesized to a GSR signal.

  -- synthesis translate_off
  init_i <= '1', '0' after 100 ns;
  -- synthesis translate_on

  -- Angshuman - don't need this since input clock is single-ended
  -- lvds_sys_clk_input : IBUFGDS
  --   port map(
  --     I  => sys_clk,
  --     IB => sys_clk_n,
  --     O  => sys_clk_in
  --     );
  
  i_idly_clk_pll : PLL_BASE
  generic map (
    BANDWIDTH             => "OPTIMIZED",           -- string
    CLKFBOUT_MULT         => 4,                     -- integer
    CLKFBOUT_PHASE        => 0.000,                 -- real
    CLKIN_PERIOD          => 10.000,                 -- real
    CLKOUT0_DIVIDE        => 2,                     -- integer
    CLKOUT0_DUTY_CYCLE    => 0.50,                  -- real
    CLKOUT0_PHASE         => 0.0,                   -- real
    CLKOUT1_DIVIDE        => 1,                     -- integer
    CLKOUT1_DUTY_CYCLE    => 0.50,                  -- real
    CLKOUT1_PHASE         => 0.0,                   -- real
    CLKOUT2_DIVIDE        => 1,                     -- integer
    CLKOUT2_DUTY_CYCLE    => 0.50,                  -- real
    CLKOUT2_PHASE         => 0.0,                   -- real    
    CLKOUT3_DIVIDE        => 1,                     -- integer
    CLKOUT3_DUTY_CYCLE    => 0.50,                  -- real
    CLKOUT3_PHASE         => 0.0,                   -- real
    CLKOUT4_DIVIDE        => 1,                     -- integer
    CLKOUT4_DUTY_CYCLE    => 0.50,                  -- real
    CLKOUT4_PHASE         => 0.0,                   -- real
    CLKOUT5_DIVIDE        => 1,                     -- integer
    CLKOUT5_DUTY_CYCLE    => 0.50,                  -- real
    CLKOUT5_PHASE         => 0.0,                   -- real    
    COMPENSATION          => "SYSTEM_SYNCHRONOUS",  -- string
    DIVCLK_DIVIDE         => 1,                     -- integer
    REF_JITTER            => 0.120,                 -- real
    RESET_ON_LOSS_OF_LOCK => FALSE                  -- boolean     
    )
  port map (
    CLKFBOUT        => idly_clk_pll_fb,        -- out std_logic
    CLKOUT0         => idly_clk_pll_bufg_in,   -- out std_logic
    CLKOUT1         => open,                   -- out std_logic
    CLKOUT2         => open,                   -- out std_logic
    CLKOUT3         => open,                   -- out std_logic
    CLKOUT4         => open,                   -- out std_logic
    CLKOUT5         => open,                   -- out std_logic
    LOCKED          => idly_clk_pll_lock,      -- out std_logic
    CLKFBIN         => idly_clk_pll_fb,        -- in  std_logic
    CLKIN           => sys_clk_in,             -- in  std_logic
    RST             => pll_rst                 -- in  std_logic
    );

  i_idly_clk_pll_out : BUFG
  port map (
    O => idly_clk,
    I => idly_clk_pll_bufg_in
    );

 
  -------------------------------------------------------------------------------
  -- The PMCD PLL creates a 0, 90, 180 and 270 degree phase shifted versions of 
  -- the memory clock. The PLL provides clock outputs with matching phase for the
  -- 0 and 90 degree clocks required by the SRAM and SDRAM cores
  -------------------------------------------------------------------------------


  -- Generate PMCD_PLL depending on memory_clk_speed   
  pmcd_pll_250 : if memory_clk_speed = 1 generate

    i_pmcd_pll : PLL_BASE
    generic map (
      BANDWIDTH             => "OPTIMIZED",           -- string
      CLKFBOUT_MULT         => 5,                     -- integer
      CLKFBOUT_PHASE        => 0.000,                 -- real
      CLKIN_PERIOD          => 10.000,                 -- real
      CLKOUT0_DIVIDE        => 2,                     -- integer
      CLKOUT0_DUTY_CYCLE    => 0.50,                  -- real
      CLKOUT0_PHASE         => 0.0,                   -- real      ** 0 degrees
      CLKOUT1_DIVIDE        => 2,                     -- integer
      CLKOUT1_DUTY_CYCLE    => 0.50,                  -- real
      CLKOUT1_PHASE         => 90.0,                  -- real      ** 90 degrees
      CLKOUT2_DIVIDE        => 2,                     -- integer
      CLKOUT2_DUTY_CYCLE    => 0.50,                  -- real
      CLKOUT2_PHASE         => 180.0,                 -- real      ** 180 degrees
      CLKOUT3_DIVIDE        => 2,                     -- integer
      CLKOUT3_DUTY_CYCLE    => 0.50,                  -- real
      CLKOUT3_PHASE         => 270.0,                 -- real      ** 270 degrees
      CLKOUT4_DIVIDE        => 1,                     -- integer
      CLKOUT4_DUTY_CYCLE    => 0.50,                  -- real
      CLKOUT4_PHASE         => 0.0,                   -- real
      CLKOUT5_DIVIDE        => 1,                     -- integer
      CLKOUT5_DUTY_CYCLE    => 0.50,                  -- real
      CLKOUT5_PHASE         => 0.0,                   -- real   
      COMPENSATION          => "SYSTEM_SYNCHRONOUS",  -- string
      DIVCLK_DIVIDE         => 1,                     -- integer
      REF_JITTER            => 0.120,                 -- real
      RESET_ON_LOSS_OF_LOCK => FALSE                  -- boolean     
      )
    port map (
      CLKFBOUT        => pmcd_pll_fb,            -- out std_logic
      CLKOUT0         => clk0_bufg_in,           -- out std_logic
      CLKOUT1         => clk90_bufg_in,          -- out std_logic
      CLKOUT2         => clk180_bufg_in,         -- out std_logic
      CLKOUT3         => clk270_bufg_in,         -- out std_logic
      CLKOUT4         => open,                   -- out std_logic
      CLKOUT5         => open,                   -- out std_logic
      LOCKED          => pmcd_pll_lock,          -- out std_logic
      CLKFBIN         => pmcd_pll_fb,            -- in  std_logic
      CLKIN           => sys_clk_in,             -- in  std_logic
      RST             => pll_rst                 -- in  std_logic
      );

  end generate pmcd_pll_250;

  -- Generate PMCD_PLL depending on memory_clk_speed   
  pmcd_pll_200 : if memory_clk_speed /= 1 generate

    i_pmcd_pll : PLL_BASE
    generic map (
      BANDWIDTH             => "OPTIMIZED",           -- string
      CLKFBOUT_MULT         => 4,                     -- integer
      CLKFBOUT_PHASE        => 0.000,                 -- real
      CLKIN_PERIOD          => 10.000,                 -- real
      CLKOUT0_DIVIDE        => 2,                     -- integer
      CLKOUT0_DUTY_CYCLE    => 0.50,                  -- real
      CLKOUT0_PHASE         => 0.0,                   -- real      ** 0 degrees
      CLKOUT1_DIVIDE        => 2,                     -- integer
      CLKOUT1_DUTY_CYCLE    => 0.50,                  -- real
      CLKOUT1_PHASE         => 90.0,                  -- real      ** 90 degrees
      CLKOUT2_DIVIDE        => 2,                     -- integer
      CLKOUT2_DUTY_CYCLE    => 0.50,                  -- real
      CLKOUT2_PHASE         => 180.0,                 -- real      ** 180 degrees
      CLKOUT3_DIVIDE        => 2,                     -- integer
      CLKOUT3_DUTY_CYCLE    => 0.50,                  -- real
      CLKOUT3_PHASE         => 270.0,                 -- real      ** 270 degrees
      CLKOUT4_DIVIDE        => 1,                     -- integer
      CLKOUT4_DUTY_CYCLE    => 0.50,                  -- real
      CLKOUT4_PHASE         => 0.0,                   -- real
      CLKOUT5_DIVIDE        => 1,                     -- integer
      CLKOUT5_DUTY_CYCLE    => 0.50,                  -- real
      CLKOUT5_PHASE         => 0.0,                   -- real   
      COMPENSATION          => "SYSTEM_SYNCHRONOUS",  -- string
      DIVCLK_DIVIDE         => 1,                     -- integer
      REF_JITTER            => 0.120,                 -- real
      RESET_ON_LOSS_OF_LOCK => FALSE                  -- boolean     
      )
    port map (
      CLKFBOUT        => pmcd_pll_fb,            -- out std_logic
      CLKOUT0         => clk0_bufg_in,           -- out std_logic
      CLKOUT1         => clk90_bufg_in,          -- out std_logic
      CLKOUT2         => clk180_bufg_in,         -- out std_logic
      CLKOUT3         => clk270_bufg_in,         -- out std_logic
      CLKOUT4         => open,                   -- out std_logic
      CLKOUT5         => open,                   -- out std_logic
      LOCKED          => pmcd_pll_lock,          -- out std_logic
      CLKFBIN         => pmcd_pll_fb,            -- in  std_logic
      CLKIN           => sys_clk_in,             -- in  std_logic
      RST             => pll_rst                 -- in  std_logic
      );

  end generate pmcd_pll_200;

  i_pll_clk0_bufg : BUFG
    port map (
      O => mem_clk0,
      I => clk0_bufg_in
      );

  i_pll_clk90_bufg : BUFG
    port map (
      O => mem_clk90,
      I => clk90_bufg_in
      );
      
  i_pll_clk180_bufg : BUFG
    port map (
      O => mem_clk180,
      I => clk180_bufg_in
      );      

  i_pll_clk270_bufg : BUFG
    port map (
      O => mem_clk270,
      I => clk270_bufg_in
      );

  
  
  -- Generate IDELAYCTRL logic when genric has been set to TRUE    
  idelayctrl_switch_on : if idelayctrl_use generate
  
    idly_clk_pll_lock_not <= not idly_clk_pll_lock;

    i_reset_sync_0 : reset_synchroniser
    generic map (
      depth       => 15
      )
    port map (
      clock       => idly_clk,
      async_reset => idly_clk_pll_lock_not,
      sync_reset  => idlyctrl_rst
      );
  
    i_idelayctrl : IDELAYCTRL
    port map (
      RDY          => idly_ctrl_rdy,
      REFCLK       => idly_clk,
      RST          => idlyctrl_rst
      );

  end generate idelayctrl_switch_on;
  
  -- Combine the PLL Locked signals and take into mem_clk0 clock domain.
  pll_locked_not <= not (pmcd_pll_lock and idly_ctrl_rdy) when (idelayctrl_use = true) else
                    not (pmcd_pll_lock);


  i_reset_sync_1 : reset_synchroniser
  generic map (
    depth       => 3
    )
  port map (
    clock       => mem_clk0,
    async_reset => pll_locked_not,
    sync_reset  => sys_reset
    );
  
  
  -------------------------------------------------------------------------------
  -- Fanout the memory clock signals to make it easier for users to supply clocks
  -- to the memory components without using breakouts.
  
  -- Note: idelayctrl_rdy is always a function of the sys_reset signal. Hence, 
  -- the sys_reset signal will only be deasserted when it is stable to proceed with
  -- memory idelay calibration. When idelayctrl_use is set to false the pll_rst 
  -- input signal needs to be a function of the idelayctrl_rdy signal to maintain
  -- this.

  mem0_ddr2_clk0           <= mem_clk0;
  mem0_ddr2_clk90          <= mem_clk90;
  mem0_ddr2_sys_reset      <= sys_reset;
  
  mem1_ddr2_clk0           <= mem_clk0;
  mem1_ddr2_clk90          <= mem_clk90;
  mem1_ddr2_sys_reset      <= sys_reset;

  mem0_qdr2_clk0           <= mem_clk0;
  mem0_qdr2_clk180         <= mem_clk180;
  mem0_qdr2_clk270         <= mem_clk270;
  mem0_qdr2_sys_reset      <= sys_reset;
  
  mem1_qdr2_clk0           <= mem_clk0;
  mem1_qdr2_clk180         <= mem_clk180;
  mem1_qdr2_clk270         <= mem_clk270;  
  mem1_qdr2_sys_reset      <= sys_reset;

  -- Connect output GSR Initialisation signal
  init  <= init_i;


end rtl;
