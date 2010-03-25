--*****************************************************************************
-- DISCLAIMER OF LIABILITY
--
-- This file contains proprietary and confidential information of
-- Xilinx, Inc. ("Xilinx"), that is distributed under a license
-- from Xilinx, and may be used, copied and/or disclosed only
-- pursuant to the terms of a valid license agreement with Xilinx.
--
-- XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION
-- ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
-- EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT
-- LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,
-- MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx
-- does not warrant that functions included in the Materials will
-- meet the requirements of Licensee, or that the operation of the
-- Materials will be uninterrupted or error-free, or that defects
-- in the Materials will be corrected. Furthermore, Xilinx does
-- not warrant or make any representations regarding use, or the
-- results of the use, of the Materials in terms of correctness,
-- accuracy, reliability or otherwise.
--
-- Xilinx products are not designed or intended to be fail-safe,
-- or for use in any application requiring fail-safe performance,
-- such as life-support or safety devices or systems, Class III
-- medical devices, nuclear facilities, applications related to
-- the deployment of airbags, or any other applications that could
-- lead to death, personal injury or severe property or
-- environmental damage (individually and collectively, "critical
-- applications"). Customer assumes the sole risk and liability
-- of any use of Xilinx products in critical applications,
-- subject only to applicable laws and regulations governing
-- limitations on product liability.
--
-- Copyright 2008 Xilinx, Inc.
-- All rights reserved.
--
-- This disclaimer and copyright notice must be retained as part
-- of this file at all times.
--*****************************************************************************
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor             : Xilinx
-- \   \   \/     Version            : 3.2
--  \   \         Application        : MIG
--  /   /         Filename           : ddr2_sram.vhd
-- /___/   /\     Timestamp          : 15 May 2006
-- \   \  /  \    Date Last Modified : $Date: 2009/05/11 21:13:31 $
--  \___\/\___\
--
--Device: Virtex-5
--Design: DDRII
--
--Purpose:
--   Top-level module. Simple model for what the user might use
--   Typically, the user will only instantiate MEM_INTERFACE_TOP in their
--   code, and generate all backend logic (test bench) and all the other infrastructure logic
--    separately.
--   In addition to the memory controller, the module instantiates:
--     1. Reset logic based on user clocks
--     2. IDELAY control block
--
--Revision History:
--   Rev 1.1 - Parameter IODELAY_GRP added. PK. 11/27/08
--*****************************************************************************

library ieee;
library unisim;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;
-- use work.ddrii_chipscope.all;

entity ddr2_sram is
  generic(
   ADDR_WIDTH               : integer := 21; 
                              -- # of memory component address bits.
   BURST_LENGTH             : integer := 2; 
                              -- # = 2 -> Burst Length 2 memory part,
                              -- # = 4 -> Burst Length 4 memory part.
   BUS_TURNAROUND           : integer := 0; 
                              -- Indicates the number of clocks the
                              -- controller should wait before issuing a
                              -- read command after a write command is
                              -- issued. This number cannot be more that 3.
   BW_WIDTH                 : integer := 4; 
                              -- # of Byte Write Control bits.
   CLK_FREQ                 : integer := 200; 
                              -- Core/Memory clock frequency (in MHz).
   CLK_WIDTH                : integer := 1; 
                              -- # of memory clock outputs. Represents the
                              -- number of K, K_n, C, and C_n clocks.
   CQ_WIDTH                 : integer := 1; 
                              -- # of CQ bits.
   DATA_WIDTH               : integer := 36; 
                              -- Design Data Width.
   DEBUG_EN                 : integer := 0; 
                              -- Enable debug signals/controls. When this
                              -- parameter is changed from 0 to 1, make sure to
                              -- uncomment the coregen commands in ise_flow.bat
                              -- or create_ise.bat files in par folder.
   HIGH_PERFORMANCE_MODE    : boolean := TRUE; 
                              -- # = TRUE, the IODELAY performance mode is set to high.
                              -- # = FALSE, the IODELAY performance mode is set to low.
   IO_TYPE                  : string := "CIO"; 
                              -- # = "CIO" -> Common I/O memory part,
                              -- # = "SIO" -> Separate I/O memory part.
   MASTERBANK_PIN_WIDTH     : integer := 1; 
                              -- # of dummy inuput pins for the Master Banks.
                              -- This dummy input pin will appear in the Master
                              -- bank only when it does not have alteast one
                              -- input\inout pins with the IO_STANDARD same as
                              -- the slave banks.
   MEMORY_WIDTH             : integer := 36; 
                              -- # of memory part's data width.
   RST_ACT_LOW              : integer := 1; 
                              -- # = 1 for active low reset, # = 0 for active high.
   SIM_ONLY                 : integer := 0  
                              -- # = 1 to skip SRAM power up delay.
   );
  port(
   ddrii_dq              : inout  std_logic_vector((DATA_WIDTH-1) downto 0);
   ddrii_sa              : out   std_logic_vector((ADDR_WIDTH-1) downto 0);
   ddrii_ld_n            : out   std_logic;
   ddrii_rw_n            : out   std_logic;
   ddrii_dll_off_n       : out   std_logic;
   ddrii_bw_n            : out   std_logic_vector((BW_WIDTH-1) downto 0);
   masterbank_sel_pin    : in    std_logic_vector((MASTERBANK_PIN_WIDTH-1) downto 0);
   -- masterbank_sel_pin_out : out std_logic_vector((MASTERBANK_PIN_WIDTH-1) downto 0);
   sys_rst_n             : in    std_logic;
   cal_done              : out   std_logic;
   locked                : in    std_logic;
   rst0_n_out            : out   std_logic;  -- Angshuman
   clk_0                 : in    std_logic;
   clk0_out              : out   std_logic;  -- Angshuman
   clk_270               : in    std_logic;
   clk_200               : in    std_logic;
   user_addr_wr_en       : in    std_logic;
   user_wrdata_wr_en     : in    std_logic;
   wrdata_fifo_not_full  : out   std_logic;  -- Angshuman
   addr_fifo_not_full    : out   std_logic;  -- Angshuman
   rd_data_valid         : out   std_logic;
   user_wr_data_rise     : in    std_logic_vector((DATA_WIDTH-1) downto 0);
   user_wr_data_fall     : in    std_logic_vector((DATA_WIDTH-1) downto 0);
   user_rd_data_rise     : out   std_logic_vector((DATA_WIDTH-1) downto 0);
   user_rd_data_fall     : out   std_logic_vector((DATA_WIDTH-1) downto 0);
   user_bw_n_rise        : in    std_logic_vector((BW_WIDTH-1) downto 0);
   user_bw_n_fall        : in    std_logic_vector((BW_WIDTH-1) downto 0);

   -- Angshuman
   -- user_addr_cmd         : in    std_logic_vector(ADDR_WIDTH downto 0);
   user_addr            : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
   user_cmd             : in    std_logic;

   ddrii_cq              : in    std_logic_vector((CQ_WIDTH-1) downto 0);
   ddrii_cq_n            : in    std_logic_vector((CQ_WIDTH-1) downto 0);
   ddrii_k               : out   std_logic_vector((CLK_WIDTH-1) downto 0);
   ddrii_k_n             : out   std_logic_vector((CLK_WIDTH-1) downto 0);
   ddrii_c               : out   std_logic_vector((CLK_WIDTH-1) downto 0);
   ddrii_c_n             : out   std_logic_vector((CLK_WIDTH-1) downto 0);

   ram_leds              : out   std_logic_vector(1 downto 0);  -- Angshuman
   ram_pwr_on            : out   std_logic                      -- Angshuman

   );
end entity ddr2_sram;

architecture arc_mem_interface_top of ddr2_sram is

  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of arc_mem_interface_top : ARCHITECTURE IS
    "mig_v3_2_ddrii_sram_v5, Coregen 11.3";

  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of arc_mem_interface_top : ARCHITECTURE IS "ddrii_sram_v5,mig_v3_2,{component_name=ddr2_sram, addr_width = 21, burst_length = 2, bw_width = 4, clk_freq = 250, clk_width = 1, cq_width = 1, data_width = 36, memory_width = 36, rst_act_low = 1}";

  --***************************************************************************
  -- IODELAY Group Name: Replication and placement of IDELAYCTRLs will be
  -- handled automatically by software tools if IDELAYCTRLs have same refclk,
  -- reset and rdy nets. Designs with a unique RESET will commonly create a
  -- unique RDY. Constraint IODELAY_GROUP is associated to a set of IODELAYs
  -- with an IDELAYCTRL. The parameter IODELAY_GRP value can be any string.
  --***************************************************************************

  constant IODELAY_GRP : string := "IODELAY_MIG";
  
  -- Angshuman -- not required (see below)
  --component ddrii_idelay_ctrl
  --  generic (
  --    IODELAY_GRP       : string
  --    );
  --  port (
  --    reset_clk_200        : in    std_logic;
  --    idelay_ctrl_ready    : out   std_logic;
  --    clk_200              : in    std_logic
  --    );
  --end component;

  -- Angshuman end
  
component ddrii_infrastructure
    generic (
      RST_ACT_LOW           : integer

      );
    port (
      sys_rst_n            : in    std_logic;
      locked               : in    std_logic;
      reset_clk_0          : out   std_logic;
      reset_clk_270        : out   std_logic;
      reset_clk_200        : out   std_logic;
      idelay_ctrl_ready    : in    std_logic;
      clk_0                : in    std_logic;
      clk_90               : out   std_logic;
      clk_270              : in    std_logic;
      clk_200              : in    std_logic

      );
  end component;


component ddrii_top
    generic (
      ADDR_WIDTH            : integer;
      BURST_LENGTH          : integer;
      BUS_TURNAROUND        : integer;
      BW_WIDTH              : integer;
      CLK_FREQ              : integer;
      CLK_WIDTH             : integer;
      CQ_WIDTH              : integer;
      DATA_WIDTH            : integer;
      DEBUG_EN              : integer;
      HIGH_PERFORMANCE_MODE   : boolean;
      IODELAY_GRP           : string;
      IO_TYPE               : string;
      MEMORY_WIDTH          : integer;
      SIM_ONLY              : integer
      );
    port (
      ddrii_d              : out std_logic_vector((DATA_WIDTH-1) downto 0);
      ddrii_q              : in std_logic_vector((DATA_WIDTH-1) downto 0);
      ddrii_dq             : inout  std_logic_vector((DATA_WIDTH-1) downto 0);
      ddrii_sa             : out   std_logic_vector((ADDR_WIDTH-1) downto 0);
      ddrii_ld_n           : out   std_logic;
      ddrii_rw_n           : out   std_logic;
      ddrii_dll_off_n      : out   std_logic;
      ddrii_bw_n           : out   std_logic_vector((BW_WIDTH-1) downto 0);
      cal_done             : out   std_logic;
      reset_clk_0          : in    std_logic;
      reset_clk_270        : in    std_logic;
      idelay_ctrl_ready    : in   std_logic;
      clk_0                : in    std_logic;
      clk_90               : in    std_logic;
      clk_270              : in    std_logic;
      user_addr_wr_en      : in    std_logic;
      user_wrdata_wr_en    : in    std_logic;
      wrdata_fifo_full     : out   std_logic;
      addr_fifo_full       : out   std_logic;
      rd_data_valid        : out   std_logic;
      user_wr_data_rise    : in    std_logic_vector((DATA_WIDTH-1) downto 0);
      user_wr_data_fall    : in    std_logic_vector((DATA_WIDTH-1) downto 0);
      user_rd_data_rise    : out   std_logic_vector((DATA_WIDTH-1) downto 0);
      user_rd_data_fall    : out   std_logic_vector((DATA_WIDTH-1) downto 0);
      user_bw_n_rise       : in    std_logic_vector((BW_WIDTH-1) downto 0);
      user_bw_n_fall       : in    std_logic_vector((BW_WIDTH-1) downto 0);
      user_addr_cmd        : in    std_logic_vector(ADDR_WIDTH downto 0);
      ddrii_cq             : in    std_logic_vector((CQ_WIDTH-1) downto 0);
      ddrii_cq_n           : in    std_logic_vector((CQ_WIDTH-1) downto 0);
      ddrii_k              : out   std_logic_vector((CLK_WIDTH-1) downto 0);
      ddrii_k_n            : out   std_logic_vector((CLK_WIDTH-1) downto 0);
      ddrii_c              : out   std_logic_vector((CLK_WIDTH-1) downto 0);
      ddrii_c_n            : out   std_logic_vector((CLK_WIDTH-1) downto 0);
      dbg_stg1_cal_done_cq_inst   : out  std_logic_vector(CQ_WIDTH-1 downto 0);
      dbg_stg1_cal_done_cq_n_inst   : out  std_logic_vector(CQ_WIDTH-1 downto 0);
      dbg_stg2_cal_done_cq_inst   : out  std_logic_vector(CQ_WIDTH-1 downto 0);
      dbg_stg2_cal_done_cq_n_inst   : out  std_logic_vector(CQ_WIDTH-1 downto 0);
      dbg_stg3_cal_done_cq_inst   : out  std_logic_vector(CQ_WIDTH-1 downto 0);
      dbg_stg3_cal_done_cq_n_inst   : out  std_logic_vector(CQ_WIDTH-1 downto 0);
      dbg_q_tap_count_cq_inst   : out  std_logic_vector((6*CQ_WIDTH)-1 downto 0);
      dbg_q_tap_count_cq_n_inst   : out  std_logic_vector((6*CQ_WIDTH)-1 downto 0);
      dbg_cq_tap_count_inst   : out  std_logic_vector((6*CQ_WIDTH)-1 downto 0);
      dbg_cq_n_tap_count_inst   : out  std_logic_vector((6*CQ_WIDTH)-1 downto 0);
      dbg_data_valid_cq_inst   : out  std_logic_vector(CQ_WIDTH-1 downto 0);
      dbg_data_valid_cq_n_inst   : out  std_logic_vector(CQ_WIDTH-1 downto 0);
      dbg_cal_done            : out  std_logic;
      dbg_init_wait_done      : out  std_logic;
      dbg_data_valid          : out  std_logic;
      dbg_idel_up_all         : in  std_logic;
      dbg_idel_down_all       : in  std_logic;
      dbg_idel_up_q           : in  std_logic;
      dbg_idel_down_q         : in  std_logic;
      dbg_sel_idel_q_cq       : in  std_logic_vector(CQ_WIDTH-1 downto 0);
      dbg_sel_all_idel_q_cq   : in  std_logic;
      dbg_sel_idel_q_cq_n     : in  std_logic_vector(CQ_WIDTH-1 downto 0);
      dbg_sel_all_idel_q_cq_n   : in  std_logic;
      dbg_idel_up_cq          : in  std_logic;
      dbg_idel_down_cq        : in  std_logic;
      dbg_sel_idel_cq         : in  std_logic_vector(CQ_WIDTH-1 downto 0);
      dbg_sel_all_idel_cq     : in  std_logic;
      dbg_sel_idel_cq_n       : in  std_logic_vector(CQ_WIDTH-1 downto 0);
      dbg_sel_all_idel_cq_n   : in  std_logic

      );
  end component;




  constant ddrii_q : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

  signal  reset_clk_0            : std_logic;
  signal  reset_clk_270          : std_logic;
  signal  reset_clk_200          : std_logic;
  signal  idelay_ctrl_ready      : std_logic;
  signal  clk_90                 : std_logic;
  signal  i_cal_done           : std_logic;

  -- Angshuman
  signal wrdata_fifo_full : std_logic;
  signal addr_fifo_full   : std_logic;
  signal user_addr_cmd    : std_logic_vector(ADDR_WIDTH downto 0);

  --Debug signals


  signal  dbg_stg1_cal_done_cq_inst  : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal  dbg_stg1_cal_done_cq_n_inst  : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal  dbg_stg2_cal_done_cq_inst  : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal  dbg_stg2_cal_done_cq_n_inst  : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal  dbg_stg3_cal_done_cq_inst  : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal  dbg_stg3_cal_done_cq_n_inst  : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal  dbg_q_tap_count_cq_inst    : std_logic_vector((6*CQ_WIDTH)-1 downto 0);
  signal  dbg_q_tap_count_cq_n_inst  : std_logic_vector((6*CQ_WIDTH)-1 downto 0);
  signal  dbg_cq_tap_count_inst      : std_logic_vector((6*CQ_WIDTH)-1 downto 0);
  signal  dbg_cq_n_tap_count_inst    : std_logic_vector((6*CQ_WIDTH)-1 downto 0);
  signal  dbg_data_valid_cq_inst     : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal  dbg_data_valid_cq_n_inst   : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal  dbg_cal_done               : std_logic;
  signal  dbg_init_wait_done         : std_logic;
  signal  dbg_data_valid             : std_logic;
  signal  dbg_idel_up_all            : std_logic;
  signal  dbg_idel_down_all          : std_logic;
  signal  dbg_idel_up_q              : std_logic;
  signal  dbg_idel_down_q            : std_logic;
  signal  dbg_sel_idel_q_cq          : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal  dbg_sel_all_idel_q_cq      : std_logic;
  signal  dbg_sel_idel_q_cq_n        : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal  dbg_sel_all_idel_q_cq_n    : std_logic;
  signal  dbg_idel_up_cq             : std_logic;
  signal  dbg_idel_down_cq           : std_logic;
  signal  dbg_sel_idel_cq            : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal  dbg_sel_all_idel_cq        : std_logic;
  signal  dbg_sel_idel_cq_n          : std_logic_vector(CQ_WIDTH-1 downto 0);
  signal  dbg_sel_all_idel_cq_n      : std_logic;



  signal control0     : std_logic_vector(35 downto 0);
  signal dbg_sync_out : std_logic_vector(36 downto 0);
  signal dbg_async_in : std_logic_vector(131 downto 0);

  -- Angshuman begin (from Nallatech code)
  signal masterbank_sel_pin_out : std_logic_vector((MASTERBANK_PIN_WIDTH-1) downto 0);
  signal masterbank_sel_pin_ibuf : std_logic_vector((MASTERBANK_PIN_WIDTH-1) downto 0);
  -- signal masterbank_sel_pin_obuf : std_logic_vector((MASTERBANK_PIN_WIDTH-1) downto 0);

  attribute syn_useioff : boolean;
  attribute IOB : string;
  attribute keep : string;
  attribute S : string;
  attribute syn_noprune : boolean;
  attribute syn_keep : boolean;

  attribute S        of masterbank_sel_pin : signal is "TRUE";
  -- attribute keep     of masterbank_sel_pin : signal is "true";
  attribute syn_keep of masterbank_sel_pin : signal is true;

  attribute S        of masterbank_sel_pin_out : signal is "TRUE";
  -- attribute keep     of masterbank_sel_pin_out : signal is "true";  
  attribute syn_keep of masterbank_sel_pin_out : signal is true;

  attribute IODELAY_GROUP : string;
  attribute IODELAY_GROUP of U_IDELAYCTRL : label is "IODELAY_MIG";

  -- Angshuman end
  
begin

  --***************************************************************************
  cal_done   <= i_cal_done;
  wrdata_fifo_not_full <= not wrdata_fifo_full;
  addr_fifo_not_full   <= not addr_fifo_full;
  user_addr_cmd <= user_addr & user_cmd; -- & is concatenation in VHDL
  
  clk0_out    <= clk_0;
  rst0_n_out  <= not reset_clk_0;

  -- start 'er up!

  RAM_PWR_ON_OBUF : OBUF
    port map (
      O => ram_pwr_on,
      I => '1');

  RAM_LEDS_OBUF : for i in 0 to 1 generate
  begin
    RAM_LEDS_OBUF_INST : OBUF
      port map (
        O  => ram_leds(i),
        I  => '1'
        );
  end generate;

  -- ram_pwr_on  <= '1';
  -- ram_leds(0) <= '1';
  -- ram_leds(1) <= '1';
  
  -- Angshuman begin : from Nallatech: dummy INST to guarantee that masterbank_sel_pin
  -- does not get optimized away
  DUMMY_INST1 : for dpw_i in 0 to MASTERBANK_PIN_WIDTH-1 generate
  attribute syn_noprune of DUMMY_INST : label is true;
  attribute keep of DUMMY_INST : label is "true";
  begin
    DUMMY_INST : MUXCY
      port map (
        O  => masterbank_sel_pin_out(dpw_i),
        CI => masterbank_sel_pin_ibuf(dpw_i),
        DI => '0',
        S  => '1'
        );
  end generate;

  MASTERBANK_IBUF : IBUF
      port map (
       I => masterbank_sel_pin(0),
       O => masterbank_sel_pin_ibuf(0)
      );

  --masterbank_sel_pin_obuf(0) <= not masterbank_sel_pin_ibuf(0);
  
  --MASTERBANK_OBUF : OBUF
  --  port map(
  --    I => masterbank_sel_pin_obuf(0),
  --    O => masterbank_sel_pin_out(0)
  --    );

  -- Angshuman end


  -- Angshuman : nallatech's code uses a primitive IDELAYCTRL instantiation instead
  -- of the MIG-generated DDRII_IDELAY_CTRL. The instance is then explicitly placed
  -- in the UCF file.

  --u_ddrii_idelay_ctrl : ddrii_idelay_ctrl
  --  generic map (
  --    IODELAY_GRP        => IODELAY_GRP
  -- )
  --  port map (
  --    reset_clk_200         => reset_clk_200,
  --    idelay_ctrl_ready     => idelay_ctrl_ready,
  --    clk_200               => clk_200
  -- );

   u_idelayctrl : IDELAYCTRL
   port map (
     RDY    => idelay_ctrl_ready,
     REFCLK => clk_200,
     RST    => reset_clk_200
     );

  -- Angshuman end

  u_ddrii_infrastructure : ddrii_infrastructure
    generic map (
      RST_ACT_LOW           => RST_ACT_LOW
   )
    port map (
      sys_rst_n             => sys_rst_n,
      locked                => locked,
      reset_clk_0           => reset_clk_0,
      reset_clk_270         => reset_clk_270,
      reset_clk_200         => reset_clk_200,
      idelay_ctrl_ready     => idelay_ctrl_ready,
      clk_0                 => clk_0,
      clk_90                => clk_90,
      clk_270               => clk_270,
      clk_200               => clk_200
   );


  u_ddrii_top_0 : ddrii_top
    generic map (
      ADDR_WIDTH            => ADDR_WIDTH,
      BURST_LENGTH          => BURST_LENGTH,
      BUS_TURNAROUND        => BUS_TURNAROUND,
      BW_WIDTH              => BW_WIDTH,
      CLK_FREQ              => CLK_FREQ,
      CLK_WIDTH             => CLK_WIDTH,
      CQ_WIDTH              => CQ_WIDTH,
      DATA_WIDTH            => DATA_WIDTH,
      DEBUG_EN              => DEBUG_EN,
      HIGH_PERFORMANCE_MODE   => HIGH_PERFORMANCE_MODE,
      IODELAY_GRP           => IODELAY_GRP,
      IO_TYPE               => IO_TYPE,
      MEMORY_WIDTH          => MEMORY_WIDTH,
      SIM_ONLY              => SIM_ONLY
      )
    port map (
      ddrii_d               => open,
      ddrii_q               => ddrii_q,
      ddrii_dq              => ddrii_dq,
      ddrii_sa              => ddrii_sa,
      ddrii_ld_n            => ddrii_ld_n,
      ddrii_rw_n            => ddrii_rw_n,
      ddrii_dll_off_n       => ddrii_dll_off_n,
      ddrii_bw_n            => ddrii_bw_n,
      cal_done              => i_cal_done,
      reset_clk_0           => reset_clk_0,
      reset_clk_270         => reset_clk_270,
      idelay_ctrl_ready     => idelay_ctrl_ready,
      clk_0                 => clk_0,
      clk_90                => clk_90,
      clk_270               => clk_270,
      user_addr_wr_en       => user_addr_wr_en,
      user_wrdata_wr_en     => user_wrdata_wr_en,
      wrdata_fifo_full      => wrdata_fifo_full,
      addr_fifo_full        => addr_fifo_full,
      rd_data_valid         => rd_data_valid,
      user_wr_data_rise     => user_wr_data_rise,
      user_wr_data_fall     => user_wr_data_fall,
      user_rd_data_rise     => user_rd_data_rise,
      user_rd_data_fall     => user_rd_data_fall,
      user_bw_n_rise        => user_bw_n_rise,
      user_bw_n_fall        => user_bw_n_fall,
      user_addr_cmd         => user_addr_cmd,
      ddrii_cq              => ddrii_cq,
      ddrii_cq_n            => ddrii_cq_n,
      ddrii_k               => ddrii_k,
      ddrii_k_n             => ddrii_k_n,
      ddrii_c               => ddrii_c,
      ddrii_c_n             => ddrii_c_n,

      dbg_stg1_cal_done_cq_inst   => dbg_stg1_cal_done_cq_inst,
      dbg_stg1_cal_done_cq_n_inst   => dbg_stg1_cal_done_cq_n_inst,
      dbg_stg2_cal_done_cq_inst   => dbg_stg2_cal_done_cq_inst,
      dbg_stg2_cal_done_cq_n_inst   => dbg_stg2_cal_done_cq_n_inst,
      dbg_stg3_cal_done_cq_inst   => dbg_stg3_cal_done_cq_inst,
      dbg_stg3_cal_done_cq_n_inst   => dbg_stg3_cal_done_cq_n_inst,
      dbg_q_tap_count_cq_inst   => dbg_q_tap_count_cq_inst,
      dbg_q_tap_count_cq_n_inst   => dbg_q_tap_count_cq_n_inst,
      dbg_cq_tap_count_inst   => dbg_cq_tap_count_inst,
      dbg_cq_n_tap_count_inst   => dbg_cq_n_tap_count_inst,
      dbg_data_valid_cq_inst   => dbg_data_valid_cq_inst,
      dbg_data_valid_cq_n_inst   => dbg_data_valid_cq_n_inst,
      dbg_cal_done            => dbg_cal_done,
      dbg_init_wait_done      => dbg_init_wait_done,
      dbg_data_valid          => dbg_data_valid,
      dbg_idel_up_all         => dbg_idel_up_all,
      dbg_idel_down_all       => dbg_idel_down_all,
      dbg_idel_up_q           => dbg_idel_up_q,
      dbg_idel_down_q         => dbg_idel_down_q,
      dbg_sel_idel_q_cq       => dbg_sel_idel_q_cq,
      dbg_sel_all_idel_q_cq   => dbg_sel_all_idel_q_cq,
      dbg_sel_idel_q_cq_n     => dbg_sel_idel_q_cq_n,
      dbg_sel_all_idel_q_cq_n   => dbg_sel_all_idel_q_cq_n,
      dbg_idel_up_cq          => dbg_idel_up_cq,
      dbg_idel_down_cq        => dbg_idel_down_cq,
      dbg_sel_idel_cq         => dbg_sel_idel_cq,
      dbg_sel_all_idel_cq     => dbg_sel_all_idel_cq,
      dbg_sel_idel_cq_n       => dbg_sel_idel_cq_n,
      dbg_sel_all_idel_cq_n   => dbg_sel_all_idel_cq_n
      );




     --DEBUG_SIGNALS_INST : if(DEBUG_EN = 1) generate
     --begin
     --  ---------------------------------------------------------------------------
     --  -- PHY Debug Port example - see MIG User's Guide
     --  -- NOTES:
     --  --   1. PHY Debug Port demo connects to 1 VIO modules:
     --  --     - The asynchronous inputs
     --  --      * Monitor IDELAY taps for Q, CQ/CQ#
     --  --      * Calibration status
     --  --     - The synchronous outputs
     --  --      * Allow dynamic adjustment of IDELAY taps
     --  --   2. User may need to modify this code to incorporate other
     --  --      chipscope-related modules in their larger design (e.g.if they have
     --  --      other ILA/VIO modules, they will need to for example instantiate a
     --  --      larger ICON module).
     --  --   3. For X36 bit component designs, since 18 bits of data are calibrated
     --  --      using cq and other 18 bits of data are calibration using cq_n,
     --  --      there are debug signals for monitoring/modifying the IDELAY
     --  --      tap values of cq and cq_n and that of data bits related to cq and
     --  --      cq_n.
     --  --
     --  --      But for X18bit component designs, since the calibration is done
     --  --      w.r.t., only cq, all the debug signal related to cq_n (all the
     --  --      debug signals appended with cq_n) must be ignored.
     --  ---------------------------------------------------------------------------
     --  X36_INST : if(MEMORY_WIDTH = 36) generate
     --  begin
     --    dbg_async_in(131 downto (32*CQ_WIDTH)+3) <= (others => '0');
       
     --    dbg_async_in((32*CQ_WIDTH)+2 downto 0)  <= (dbg_stg1_cal_done_cq_inst(CQ_WIDTH-1 downto 0) &
     --                                                dbg_stg1_cal_done_cq_n_inst(CQ_WIDTH-1 downto 0) &
     --                                                dbg_stg2_cal_done_cq_inst(CQ_WIDTH-1 downto 0) &
     --                                                dbg_stg2_cal_done_cq_n_inst(CQ_WIDTH-1 downto 0) &
     --                                                dbg_stg3_cal_done_cq_inst(CQ_WIDTH-1 downto 0) &
     --                                                dbg_stg3_cal_done_cq_n_inst(CQ_WIDTH-1 downto 0) &
     --                                                dbg_q_tap_count_cq_inst((6*CQ_WIDTH)-1 downto 0) &
     --                                                dbg_q_tap_count_cq_n_inst((6*CQ_WIDTH)-1 downto 0) &
     --                                                dbg_cq_tap_count_inst((6*CQ_WIDTH)-1 downto 0) &
     --                                                dbg_cq_n_tap_count_inst((6*CQ_WIDTH)-1 downto 0) &
     --                                                dbg_data_valid_cq_inst(CQ_WIDTH-1 downto 0) &
     --                                                dbg_data_valid_cq_n_inst(CQ_WIDTH-1 downto 0) &
     --                                                dbg_cal_done & dbg_init_wait_done &
     --                                                dbg_data_valid
     --                                               );
       
     --    dbg_sel_idel_q_cq       <= dbg_sync_out(((4*CQ_WIDTH)+9) downto ((3*CQ_WIDTH)+10));
     --    dbg_sel_idel_q_cq_n     <= dbg_sync_out(((3*CQ_WIDTH)+9) downto ((2*CQ_WIDTH)+10));
     --    dbg_sel_idel_cq         <= dbg_sync_out(((2*CQ_WIDTH)+9) downto (CQ_WIDTH+10));
     --    dbg_sel_idel_cq_n       <= dbg_sync_out(CQ_WIDTH+9 downto 10);
     --    dbg_sel_all_idel_q_cq   <= dbg_sync_out(9);
     --    dbg_sel_all_idel_q_cq_n <= dbg_sync_out(8);
     --    dbg_sel_all_idel_cq     <= dbg_sync_out(7);
     --    dbg_sel_all_idel_cq_n   <= dbg_sync_out(6);
     --    dbg_idel_up_cq          <= dbg_sync_out(5);
     --    dbg_idel_down_cq        <= dbg_sync_out(4);
     --    dbg_idel_up_q           <= dbg_sync_out(3);
     --    dbg_idel_down_q         <= dbg_sync_out(2);
     --    dbg_idel_up_all         <= dbg_sync_out(1);
     --    dbg_idel_down_all       <= dbg_sync_out(0);

     --  end generate X36_INST;
       
     --  X18_X9_INST : if(MEMORY_WIDTH /= 36 ) generate
     --  begin
     --    dbg_async_in(131 downto (16*CQ_WIDTH)+3) <= (others => '0');
     --    dbg_async_in((16*CQ_WIDTH)+2 downto 0)  <= (dbg_stg1_cal_done_cq_inst(CQ_WIDTH-1 downto 0) &
     --                                                dbg_stg2_cal_done_cq_inst(CQ_WIDTH-1 downto 0) &
     --                                                dbg_stg3_cal_done_cq_inst(CQ_WIDTH-1 downto 0) &
     --                                                dbg_q_tap_count_cq_inst((6*CQ_WIDTH)-1 downto 0) &
     --                                                dbg_cq_tap_count_inst((6*CQ_WIDTH)-1 downto 0) &
     --                                                dbg_data_valid_cq_inst(CQ_WIDTH-1 downto 0) &
     --                                                dbg_cal_done & dbg_init_wait_done &
     --                                                dbg_data_valid
     --                                                );
       
     --    dbg_sel_idel_q_cq       <= dbg_sync_out(((2*CQ_WIDTH)+7) downto (CQ_WIDTH+8));
     --    dbg_sel_idel_cq         <= dbg_sync_out(CQ_WIDTH+7 downto 8);
     --    dbg_sel_all_idel_q_cq   <= dbg_sync_out(7);
     --    dbg_sel_all_idel_cq     <= dbg_sync_out(6);
     --    dbg_idel_up_cq          <= dbg_sync_out(5);
     --    dbg_idel_down_cq        <= dbg_sync_out(4);
     --    dbg_idel_up_q           <= dbg_sync_out(3);
     --    dbg_idel_down_q         <= dbg_sync_out(2);
     --    dbg_idel_up_all         <= dbg_sync_out(1);
     --    dbg_idel_down_all       <= dbg_sync_out(0);
       
     --  end generate X18_X9_INST;
       
     --  -------------------------------------------------------------------------
     --  -- ICON core instance
     --  -------------------------------------------------------------------------
     --  U_ICON : icon
     --  port map (
     --     CONTROL0 => control0
     --     );
       
     --  -------------------------------------------------------------------------
     --  -- VIO core instance : Dynamically change IDELAY taps using Synchronous
     --  -- output port, and display current IDELAY setting for both CQ/CQ# and Q
     --  -- taps.
     --  -------------------------------------------------------------------------
     --  U_VIO : vio
     --  port map (
     --     CLK      => clk_0,
     --     CONTROL  => control0,
     --     ASYNC_IN => dbg_async_in(130 downto 0),
     --     SYNC_OUT => dbg_sync_out(35 downto 0)
     --     );
     --end generate DEBUG_SIGNALS_INST;

     WITHOUT_DEBUG_SIGNALS_INST : if(DEBUG_EN = 0) generate
     begin
       -------------------------------------------------------------------------
       -- Hooks to prevent sim/syn compilation errors. When DEBUG_EN = 0, all the
       -- debug input signals are floating. To avoid this, they are connected to
       -- all zeros.
       -------------------------------------------------------------------------
       dbg_sel_idel_q_cq       <= (others => '0');
       dbg_sel_idel_q_cq_n     <= (others => '0');
       dbg_sel_idel_cq         <= (others => '0');
       dbg_sel_idel_cq_n       <= (others => '0');
       dbg_sel_all_idel_q_cq   <= '0';
       dbg_sel_all_idel_q_cq_n <= '0';
       dbg_sel_all_idel_cq     <= '0';
       dbg_sel_all_idel_cq_n   <= '0';
       dbg_idel_up_cq          <= '0';
       dbg_idel_down_cq        <= '0';
       dbg_idel_up_q           <= '0';
       dbg_idel_down_q         <= '0';
       dbg_idel_up_all         <= '0';
       dbg_idel_down_all       <= '0';

     end generate WITHOUT_DEBUG_SIGNALS_INST;


end architecture arc_mem_interface_top;
