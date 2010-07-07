---------------------------------------------------------------------------
--
--     NALLATECH IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"
--     BY PROVIDING THIS DESIGN, CODE, OR INFORMATION
--     AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION
--     OR STANDARD, NALLATECH IS MAKING NO REPRESENTATION THAT THIS
--     IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,
--     AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE
--     FOR YOUR IMPLEMENTATION.  NALLATECH EXPRESSLY DISCLAIMS ANY
--     WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE
--     IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
--     REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF
--     INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
--     FOR A PARTICULAR PURPOSE.
--
--     Nallatech products are not intended for use in life support
--     appliances, devices, or systems. Use in such applications is
--     expressly prohibited.
--
---------------------------------------------------------------------------
-- Title       : Reset Synchroniser
-- Project     : 
---------------------------------------------------------------------------
-- Description :
--
--   Reset Synchroniser
--   ------------------
--
-- In cases where a design requires a reset (a lot of designs don't) to be present
-- after configuration synchronous resets are recommended by Xilinx (WP248)
-- principally because they can be collapsed in with control terms thereby in certain
-- cases saving a level of logic.
--
-- One of the potential issues with synchronous resets is that they require a
-- clock to be present in order to ensure the circuit they are resetting actually
-- sees the reset. The circuit below is goes aynchronously into reset condition
-- and synchronously out. The clock needs to be present to clock the reset state
-- out so this will ensure that all downstream registers (on this clock) are covered.
--
-- Of course, this sync_reset register can become very high fanout and can place
-- a burden on the place and route tools in high frequesncy designs - for this reason
-- a max_fanout synthesis constraint is placed on it to ensure that is replicated
-- thereby aiding timing closure. Note buffer type is set to "none" to ensure
-- that this high fanout net is not routed on a clock buffer.
--
-- Note, ensure your synthesis settings are set to ensure that this register
-- replication is maintained.
--
--
--
---------------------------------------------------------------------------
-- Known Issues and Omissions:
--
--
---------------------------------------------------------------------------
-- Copyright © 2007 Nallatech Ltd. All rights reserved.
-----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity reset_synchroniser is
  generic (
    depth       :     integer := 2);    -- depth of reset_synchroniser shift
                                        -- register (in clock
                                        -- cycles)
  port (
    clock       : in  std_logic;
    async_reset : in  std_logic;
    sync_reset  : out std_logic);

end reset_synchroniser;

architecture rtl of reset_synchroniser is

  signal sync_reset_r : std_logic_vector(depth-1 downto 0);

  attribute buffer_type                 : string;
  attribute buffer_type of sync_reset_r : signal is "none";

  attribute max_fanout                  : string;
  attribute max_fanout of sync_reset_r  : signal is "10";

begin

  process (async_reset, clock) is

  begin
    if (async_reset = '1') then
      sync_reset_r <= (others => '1');
    elsif rising_edge(clock) then
      sync_reset_r <= sync_reset_r(depth-2 downto 0) & '0';
    end if;
  end process;

  sync_reset <= sync_reset_r(depth-1);

end rtl;




