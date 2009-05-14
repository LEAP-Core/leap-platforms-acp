-------------------------------------------------------------------------------
-- system.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity system is
  port (

    -- Top-Level Wires

    FPGA1_CLK0_P : in std_logic;
    FPGA1_CLK0_N : in std_logic;
    FPGA1_CLK1_P : in std_logic;
    FPGA1_CLK1_N : in std_logic;
    FPGA1_CLK100_P : in std_logic;
    FPGA1_CLK100_N : in std_logic;
    FPGA1_LED0_Z : out std_logic;
    FPGA1_LED1_Z : out std_logic;
    FPGA1_LED2_Z : out std_logic;
    FPGA1_LED3_Z : out std_logic;
    RAM5_LED_Z : out std_logic;
    RAM6_LED_Z : out std_logic;
    FPGA1_TEMP_LED_Z : out std_logic;
    FPGA1_HOT_LED_Z : out std_logic;
    FPGA1_SCL : inout std_logic;
    FPGA1_SDA : inout std_logic;
    FPGA1_REG_EN_Z : in std_logic;
    FPGA1_REG_ADS_Z : in std_logic;
    FPGA1_REG_UDS_Z : in std_logic;
    FPGA1_REG_LDS_Z : in std_logic;
    FPGA1_REG_RESET_Z : in std_logic;
    FPGA1_REG_RD_WR_Z : in std_logic;
    FPGA1_REG_CLK : out std_logic;
    FPGA1_INTR : out std_logic;
    FPGA1_REG_RDY_Z : out std_logic;
    FPGA1_CONFIG_DATA : in std_logic_vector(7 downto 0);
    RAM_PWR_ON : inout std_logic;
    RAM5_DQ : inout std_logic_vector(31 downto 0);
    RAM5_DQ_P : inout std_logic_vector(3 downto 0);
    RAM5_CQ : in std_logic;
    RAM5_CQ_N : in std_logic;
    RAM5_LD_N : out std_logic;
    RAM5_RW_N : out std_logic;
    RAM5_DLL_OFF_N : out std_logic;
    RAM5_K : out std_logic;
    RAM5_K_N : out std_logic;
    RAM5_ADDR : inout std_logic_vector(21 downto 0);
    RAM5_BW_N : inout std_logic_vector(3 downto 0);
    RAM5_MBANK_SEL : in std_logic;
    RAM6_DQ : inout std_logic_vector(31 downto 0);
    RAM6_DQ_P : inout std_logic_vector(3 downto 0);
    RAM6_CQ : in std_logic;
    RAM6_CQ_N : in std_logic;
    RAM6_LD_N : out std_logic;
    RAM6_RW_N : out std_logic;
    RAM6_DLL_OFF_N : out std_logic;
    RAM6_K : out std_logic;
    RAM6_K_N : out std_logic;
    RAM6_ADDR : inout std_logic_vector(21 downto 0);
    RAM6_BW_N : inout std_logic_vector(3 downto 0);
    RAM6_MBANK_SEL : in std_logic;
    LANE_6_DP_P : in std_logic_vector(18 downto 0);
    LANE_6_DP_N : in std_logic_vector(18 downto 0);
    LANE_7_DP_P : out std_logic_vector(18 downto 0);
    LANE_7_DP_N : out std_logic_vector(18 downto 0);

    -- Interface with Bluespec Model

    clk_out   : out std_logic;
    rst_n_out : out std_logic;

    fsl_mpecmd_to_vacc_FSL_S_Control : out std_logic;
    fsl_mpecmd_to_vacc_FSL_S_Data : out std_logic_vector(0 to 31);
    fsl_mpecmd_to_vacc_FSL_S_Exists : out std_logic;
    fsl_mpecmd_to_vacc_FSL_S_Read : in std_logic;
    
    fsl_mpedata_to_vacc_FSL_S_Control : out std_logic;
    fsl_mpedata_to_vacc_FSL_S_Data : out std_logic_vector(0 to 31);
    fsl_mpedata_to_vacc_FSL_S_Exists : out std_logic;
    fsl_mpedata_to_vacc_FSL_S_Read : in std_logic;
    
    fsl_vacc_to_mpecmd_FSL_M_Control : in std_logic;
    fsl_vacc_to_mpecmd_FSL_M_Data : in std_logic_vector(0 to 31);
    fsl_vacc_to_mpecmd_FSL_M_NotFull : out std_logic;
    fsl_vacc_to_mpecmd_FSL_M_Write : in std_logic;
    
    fsl_vacc_to_mpedata_FSL_M_Control : in std_logic;
    fsl_vacc_to_mpedata_FSL_M_Data : in std_logic_vector(0 to 31);
    fsl_vacc_to_mpedata_FSL_M_NotFull : out std_logic;
    fsl_vacc_to_mpedata_FSL_M_Write : in std_logic

    );
end system;

architecture STRUCTURE of system is

  component inst_m2_dualcompute_infrastructure_wrapper is
    port (
      i_fpga_clk0_p : in std_logic;
      i_fpga_clk0_n : in std_logic;
      o_fpga_clk0_raw : out std_logic;
      o_fpga_clk0_bufg : out std_logic;
      i_fpga_clk1_p : in std_logic;
      i_fpga_clk1_n : in std_logic;
      o_fpga_clk1_raw : out std_logic;
      o_fpga_clk1_bufg : out std_logic;
      i_fpga_clk100_p : in std_logic;
      i_fpga_clk100_n : in std_logic;
      o_fpga_clk100_raw : out std_logic;
      o_fpga_clk100_bufg : out std_logic;
      o_fpga_led0_z : out std_logic;
      o_fpga_led1_z : out std_logic;
      o_fpga_led2_z : out std_logic;
      o_fpga_led3_z : out std_logic;
      o_ram0_led_z : out std_logic;
      o_ram1_led_z : out std_logic;
      o_fpga_temp_led_z : out std_logic;
      o_fpga_hot_led_z : out std_logic;
      i_fpga_reg_en_z : in std_logic;
      i_fpga_reg_ads_z : in std_logic;
      i_fpga_reg_uds_z : in std_logic;
      i_fpga_reg_lds_z : in std_logic;
      i_fpga_reg_reset_z : in std_logic;
      i_fpga_reg_rd_wr_z : in std_logic;
      o_fpga_reg_clk : out std_logic;
      o_fpga_intr : out std_logic;
      o_fpga_reg_rdy_z : out std_logic;
      i_fpga_config_data : in std_logic_vector(7 downto 0);
      i_ram0_cq : in std_logic;
      i_ram0_cq_n : in std_logic;
      o_ram0_ld_n : out std_logic;
      o_ram0_rw_n : out std_logic;
      o_ram0_dll_off_n : out std_logic;
      o_ram0_k : out std_logic;
      o_ram0_k_n : out std_logic;
      i_ram0_mbank_sel : in std_logic;
      i_ram1_cq : in std_logic;
      i_ram1_cq_n : in std_logic;
      o_ram1_ld_n : out std_logic;
      o_ram1_rw_n : out std_logic;
      o_ram1_dll_off_n : out std_logic;
      o_ram1_k : out std_logic;
      o_ram1_k_n : out std_logic;
      i_ram1_mbank_sel : in std_logic;
      i_led_override : in std_logic_vector(0 to 7);
      b_fpga_scl_I : in std_logic;
      b_fpga_scl_O : out std_logic;
      b_fpga_scl_T : out std_logic;
      b_fpga_sda_I : in std_logic;
      b_fpga_sda_O : out std_logic;
      b_fpga_sda_T : out std_logic;
      b_ram_pwr_on_I : in std_logic;
      b_ram_pwr_on_O : out std_logic;
      b_ram_pwr_on_T : out std_logic;
      b_ram0_dq_I : in std_logic_vector(31 downto 0);
      b_ram0_dq_O : out std_logic_vector(31 downto 0);
      b_ram0_dq_T : out std_logic;
      b_ram0_dq_p_I : in std_logic_vector(3 downto 0);
      b_ram0_dq_p_O : out std_logic_vector(3 downto 0);
      b_ram0_dq_p_T : out std_logic;
      b_ram0_addr_I : in std_logic_vector(21 downto 0);
      b_ram0_addr_O : out std_logic_vector(21 downto 0);
      b_ram0_addr_T : out std_logic;
      b_ram0_bw_n_I : in std_logic_vector(3 downto 0);
      b_ram0_bw_n_O : out std_logic_vector(3 downto 0);
      b_ram0_bw_n_T : out std_logic;
      b_ram1_dq_I : in std_logic_vector(31 downto 0);
      b_ram1_dq_O : out std_logic_vector(31 downto 0);
      b_ram1_dq_T : out std_logic;
      b_ram1_dq_p_I : in std_logic_vector(3 downto 0);
      b_ram1_dq_p_O : out std_logic_vector(3 downto 0);
      b_ram1_dq_p_T : out std_logic;
      b_ram1_addr_I : in std_logic_vector(21 downto 0);
      b_ram1_addr_O : out std_logic_vector(21 downto 0);
      b_ram1_addr_T : out std_logic;
      b_ram1_bw_n_I : in std_logic_vector(3 downto 0);
      b_ram1_bw_n_O : out std_logic_vector(3 downto 0);
      b_ram1_bw_n_T : out std_logic
    );
  end component;

  component inst_util_srl_reset_clk0_wrapper is
    port (
      i_clk : in std_logic;
      i_en : in std_logic;
      o_rst : out std_logic
    );
  end component;

  component inst_util_clk100_pll_wrapper is
    port (
      i_raw_clk : in std_logic;
      i_pll_rst : in std_logic;
      i_pll_clk_fbin : in std_logic;
      o_pll_clk_fbout : out std_logic;
      o_pll_clk0 : out std_logic;
      o_pll_clk1 : out std_logic;
      o_pll_clk2 : out std_logic;
      o_pll_clk3 : out std_logic;
      o_pll_clk4 : out std_logic;
      o_pll_clk5 : out std_logic;
      o_pll_locked : out std_logic
    );
  end component;

  component inst_util_clk0_pll_wrapper is
    port (
      i_raw_clk : in std_logic;
      i_pll_rst : in std_logic;
      i_pll_clk_fbin : in std_logic;
      o_pll_clk_fbout : out std_logic;
      o_pll_clk0 : out std_logic;
      o_pll_clk1 : out std_logic;
      o_pll_clk2 : out std_logic;
      o_pll_clk3 : out std_logic;
      o_pll_clk4 : out std_logic;
      o_pll_clk5 : out std_logic;
      o_pll_locked : out std_logic
    );
  end component;

  component inst_m2_fsl_if_l1_wrapper is
    port (
      i_clk_200mhz : in std_logic;
      i_clk_1x : in std_logic;
      i_clk_2x : in std_logic;
      i_clk_2x_90deg : in std_logic;
      i_rst_tx : in std_logic;
      i_rst_rx : in std_logic;
      i_rst_sys : in std_logic;
      i_pll_locked : in std_logic;
      o_rst : out std_logic;
      i_lane_p : in std_logic_vector(18 downto 1);
      i_lane_n : in std_logic_vector(18 downto 1);
      o_lane_p : out std_logic_vector(18 downto 1);
      o_lane_n : out std_logic_vector(18 downto 1);
      o_mfsl_clk : out std_logic;
      o_mfsl_write : out std_logic;
      o_mfsl_data : out std_logic_vector(0 to 63);
      o_mfsl_control : out std_logic;
      i_mfsl_full : in std_logic;
      o_sfsl_clk : out std_logic;
      o_sfsl_read : out std_logic;
      i_sfsl_data : in std_logic_vector(0 to 63);
      i_sfsl_control : in std_logic;
      i_sfsl_exists : in std_logic;
      o_dbg_tx : out std_logic_vector(0 to 31);
      o_dbg_rx : out std_logic_vector(0 to 31);
      o_dbg_tx_cnt : out std_logic_vector(0 to 31);
      o_dbg_rx_cnt : out std_logic_vector(0 to 31);
      o_dbg_last_rx : out std_logic_vector(0 to 64);
      o_leds : out std_logic_vector(0 to 7);
      i_opb_clk : in std_logic;
      i_opb_rst : in std_logic;
      i_opb_abus : in std_logic_vector(0 to 31);
      i_opb_be : in std_logic_vector(0 to 3);
      i_opb_dbus : in std_logic_vector(0 to 31);
      i_opb_rnw : in std_logic;
      i_opb_select : in std_logic;
      i_opb_seqaddr : in std_logic;
      o_opb_dbus : out std_logic_vector(0 to 31);
      o_opb_errack : out std_logic;
      o_opb_retry : out std_logic;
      o_opb_toutsup : out std_logic;
      o_opb_xferack : out std_logic
    );
  end component;

  component fsl_mpe_to_l1_wrapper is
    port (
      FSL_Clk : in std_logic;
      SYS_Rst : in std_logic;
      FSL_Rst : out std_logic;
      FSL_M_Clk : in std_logic;
      FSL_M_Data : in std_logic_vector(0 to 63);
      FSL_M_Control : in std_logic;
      FSL_M_Write : in std_logic;
      FSL_M_Full : out std_logic;
      FSL_S_Clk : in std_logic;
      FSL_S_Data : out std_logic_vector(0 to 63);
      FSL_S_Control : out std_logic;
      FSL_S_Read : in std_logic;
      FSL_S_Exists : out std_logic;
      FSL_Full : out std_logic;
      FSL_Has_Data : out std_logic;
      FSL_Control_IRQ : out std_logic
    );
  end component;

  component fsl_l1_to_mpe_wrapper is
    port (
      FSL_Clk : in std_logic;
      SYS_Rst : in std_logic;
      FSL_Rst : out std_logic;
      FSL_M_Clk : in std_logic;
      FSL_M_Data : in std_logic_vector(0 to 63);
      FSL_M_Control : in std_logic;
      FSL_M_Write : in std_logic;
      FSL_M_Full : out std_logic;
      FSL_S_Clk : in std_logic;
      FSL_S_Data : out std_logic_vector(0 to 63);
      FSL_S_Control : out std_logic;
      FSL_S_Read : in std_logic;
      FSL_S_Exists : out std_logic;
      FSL_Full : out std_logic;
      FSL_Has_Data : out std_logic;
      FSL_Control_IRQ : out std_logic
    );
  end component;

  component fsl_mpecmd_to_vacc_wrapper is
    port (
      FSL_Clk : in std_logic;
      SYS_Rst : in std_logic;
      FSL_Rst : out std_logic;
      FSL_M_Clk : in std_logic;
      FSL_M_Data : in std_logic_vector(0 to 31);
      FSL_M_Control : in std_logic;
      FSL_M_Write : in std_logic;
      FSL_M_Full : out std_logic;
      FSL_S_Clk : in std_logic;
      FSL_S_Data : out std_logic_vector(0 to 31);
      FSL_S_Control : out std_logic;
      FSL_S_Read : in std_logic;
      FSL_S_Exists : out std_logic;
      FSL_Full : out std_logic;
      FSL_Has_Data : out std_logic;
      FSL_Control_IRQ : out std_logic
    );
  end component;

  component fsl_vacc_to_mpecmd_wrapper is
    port (
      FSL_Clk : in std_logic;
      SYS_Rst : in std_logic;
      FSL_Rst : out std_logic;
      FSL_M_Clk : in std_logic;
      FSL_M_Data : in std_logic_vector(0 to 31);
      FSL_M_Control : in std_logic;
      FSL_M_Write : in std_logic;
      FSL_M_Full : out std_logic;
      FSL_S_Clk : in std_logic;
      FSL_S_Data : out std_logic_vector(0 to 31);
      FSL_S_Control : out std_logic;
      FSL_S_Read : in std_logic;
      FSL_S_Exists : out std_logic;
      FSL_Full : out std_logic;
      FSL_Has_Data : out std_logic;
      FSL_Control_IRQ : out std_logic
    );
  end component;

  component fsl_mpedata_to_vacc_wrapper is
    port (
      FSL_Clk : in std_logic;
      SYS_Rst : in std_logic;
      FSL_Rst : out std_logic;
      FSL_M_Clk : in std_logic;
      FSL_M_Data : in std_logic_vector(0 to 31);
      FSL_M_Control : in std_logic;
      FSL_M_Write : in std_logic;
      FSL_M_Full : out std_logic;
      FSL_S_Clk : in std_logic;
      FSL_S_Data : out std_logic_vector(0 to 31);
      FSL_S_Control : out std_logic;
      FSL_S_Read : in std_logic;
      FSL_S_Exists : out std_logic;
      FSL_Full : out std_logic;
      FSL_Has_Data : out std_logic;
      FSL_Control_IRQ : out std_logic
    );
  end component;

  component fsl_vacc_to_mpedata_wrapper is
    port (
      FSL_Clk : in std_logic;
      SYS_Rst : in std_logic;
      FSL_Rst : out std_logic;
      FSL_M_Clk : in std_logic;
      FSL_M_Data : in std_logic_vector(0 to 31);
      FSL_M_Control : in std_logic;
      FSL_M_Write : in std_logic;
      FSL_M_Full : out std_logic;
      FSL_S_Clk : in std_logic;
      FSL_S_Data : out std_logic_vector(0 to 31);
      FSL_S_Control : out std_logic;
      FSL_S_Read : in std_logic;
      FSL_S_Exists : out std_logic;
      FSL_Full : out std_logic;
      FSL_Has_Data : out std_logic;
      FSL_Control_IRQ : out std_logic
    );
  end component;

  component mb_mba_wrapper is
    port (
      CLK : in std_logic;
      RESET : in std_logic;
      MB_RESET : in std_logic;
      INTERRUPT : in std_logic;
      EXT_BRK : in std_logic;
      EXT_NM_BRK : in std_logic;
      DBG_STOP : in std_logic;
      MB_Halted : out std_logic;
      INSTR : in std_logic_vector(0 to 31);
      I_ADDRTAG : out std_logic_vector(0 to 3);
      IREADY : in std_logic;
      IWAIT : in std_logic;
      INSTR_ADDR : out std_logic_vector(0 to 31);
      IFETCH : out std_logic;
      I_AS : out std_logic;
      IPLB_M_ABort : out std_logic;
      IPLB_M_ABus : out std_logic_vector(0 to 31);
      IPLB_M_UABus : out std_logic_vector(0 to 31);
      IPLB_M_BE : out std_logic_vector(0 to 3);
      IPLB_M_busLock : out std_logic;
      IPLB_M_lockErr : out std_logic;
      IPLB_M_MSize : out std_logic_vector(0 to 1);
      IPLB_M_priority : out std_logic_vector(0 to 1);
      IPLB_M_rdBurst : out std_logic;
      IPLB_M_request : out std_logic;
      IPLB_M_RNW : out std_logic;
      IPLB_M_size : out std_logic_vector(0 to 3);
      IPLB_M_TAttribute : out std_logic_vector(0 to 15);
      IPLB_M_type : out std_logic_vector(0 to 2);
      IPLB_M_wrBurst : out std_logic;
      IPLB_M_wrDBus : out std_logic_vector(0 to 31);
      IPLB_MBusy : in std_logic;
      IPLB_MRdErr : in std_logic;
      IPLB_MWrErr : in std_logic;
      IPLB_MIRQ : in std_logic;
      IPLB_MWrBTerm : in std_logic;
      IPLB_MWrDAck : in std_logic;
      IPLB_MAddrAck : in std_logic;
      IPLB_MMRdBTerm : in std_logic;
      IPLB_MRdDAck : in std_logic;
      IPLB_MRdDBus : in std_logic_vector(0 to 31);
      IPLB_MRdWdAddr : in std_logic_vector(0 to 3);
      IPLB_MRearbitrate : in std_logic;
      IPLB_MSSize : in std_logic_vector(0 to 1);
      IPLB_MTimeout : in std_logic;
      DATA_READ : in std_logic_vector(0 to 31);
      DREADY : in std_logic;
      DWAIT : in std_logic;
      DATA_WRITE : out std_logic_vector(0 to 31);
      DATA_ADDR : out std_logic_vector(0 to 31);
      D_ADDRTAG : out std_logic_vector(0 to 3);
      D_AS : out std_logic;
      READ_STROBE : out std_logic;
      WRITE_STROBE : out std_logic;
      BYTE_ENABLE : out std_logic_vector(0 to 3);
      DM_ABUS : out std_logic_vector(0 to 31);
      DM_BE : out std_logic_vector(0 to 3);
      DM_BUSLOCK : out std_logic;
      DM_DBUS : out std_logic_vector(0 to 31);
      DM_REQUEST : out std_logic;
      DM_RNW : out std_logic;
      DM_SELECT : out std_logic;
      DM_SEQADDR : out std_logic;
      DOPB_DBUS : in std_logic_vector(0 to 31);
      DOPB_ERRACK : in std_logic;
      DOPB_MGRANT : in std_logic;
      DOPB_RETRY : in std_logic;
      DOPB_TIMEOUT : in std_logic;
      DOPB_XFERACK : in std_logic;
      DPLB_M_ABort : out std_logic;
      DPLB_M_ABus : out std_logic_vector(0 to 31);
      DPLB_M_UABus : out std_logic_vector(0 to 31);
      DPLB_M_BE : out std_logic_vector(0 to 3);
      DPLB_M_busLock : out std_logic;
      DPLB_M_lockErr : out std_logic;
      DPLB_M_MSize : out std_logic_vector(0 to 1);
      DPLB_M_priority : out std_logic_vector(0 to 1);
      DPLB_M_rdBurst : out std_logic;
      DPLB_M_request : out std_logic;
      DPLB_M_RNW : out std_logic;
      DPLB_M_size : out std_logic_vector(0 to 3);
      DPLB_M_TAttribute : out std_logic_vector(0 to 15);
      DPLB_M_type : out std_logic_vector(0 to 2);
      DPLB_M_wrBurst : out std_logic;
      DPLB_M_wrDBus : out std_logic_vector(0 to 31);
      DPLB_MBusy : in std_logic;
      DPLB_MRdErr : in std_logic;
      DPLB_MWrErr : in std_logic;
      DPLB_MIRQ : in std_logic;
      DPLB_MWrBTerm : in std_logic;
      DPLB_MWrDAck : in std_logic;
      DPLB_MAddrAck : in std_logic;
      DPLB_MMRdBTerm : in std_logic;
      DPLB_MRdDAck : in std_logic;
      DPLB_MRdDBus : in std_logic_vector(0 to 31);
      DPLB_MRdWdAddr : in std_logic_vector(0 to 3);
      DPLB_MRearbitrate : in std_logic;
      DPLB_MSSize : in std_logic_vector(0 to 1);
      DPLB_MTimeout : in std_logic;
      IM_ABUS : out std_logic_vector(0 to 31);
      IM_BE : out std_logic_vector(0 to 3);
      IM_BUSLOCK : out std_logic;
      IM_DBUS : out std_logic_vector(0 to 31);
      IM_REQUEST : out std_logic;
      IM_RNW : out std_logic;
      IM_SELECT : out std_logic;
      IM_SEQADDR : out std_logic;
      IOPB_DBUS : in std_logic_vector(0 to 31);
      IOPB_ERRACK : in std_logic;
      IOPB_MGRANT : in std_logic;
      IOPB_RETRY : in std_logic;
      IOPB_TIMEOUT : in std_logic;
      IOPB_XFERACK : in std_logic;
      DBG_CLK : in std_logic;
      DBG_TDI : in std_logic;
      DBG_TDO : out std_logic;
      DBG_REG_EN : in std_logic_vector(0 to 4);
      DBG_SHIFT : in std_logic;
      DBG_CAPTURE : in std_logic;
      DBG_UPDATE : in std_logic;
      DEBUG_RST : in std_logic;
      Trace_Instruction : out std_logic_vector(0 to 31);
      Trace_Valid_Instr : out std_logic;
      Trace_PC : out std_logic_vector(0 to 31);
      Trace_Reg_Write : out std_logic;
      Trace_Reg_Addr : out std_logic_vector(0 to 4);
      Trace_MSR_Reg : out std_logic_vector(0 to 14);
      Trace_PID_Reg : out std_logic_vector(0 to 7);
      Trace_New_Reg_Value : out std_logic_vector(0 to 31);
      Trace_Exception_Taken : out std_logic;
      Trace_Exception_Kind : out std_logic_vector(0 to 4);
      Trace_Jump_Taken : out std_logic;
      Trace_Delay_Slot : out std_logic;
      Trace_Data_Address : out std_logic_vector(0 to 31);
      Trace_Data_Access : out std_logic;
      Trace_Data_Read : out std_logic;
      Trace_Data_Write : out std_logic;
      Trace_Data_Write_Value : out std_logic_vector(0 to 31);
      Trace_Data_Byte_Enable : out std_logic_vector(0 to 3);
      Trace_DCache_Req : out std_logic;
      Trace_DCache_Hit : out std_logic;
      Trace_ICache_Req : out std_logic;
      Trace_ICache_Hit : out std_logic;
      Trace_OF_PipeRun : out std_logic;
      Trace_EX_PipeRun : out std_logic;
      Trace_MEM_PipeRun : out std_logic;
      Trace_MB_Halted : out std_logic;
      FSL0_S_CLK : out std_logic;
      FSL0_S_READ : out std_logic;
      FSL0_S_DATA : in std_logic_vector(0 to 31);
      FSL0_S_CONTROL : in std_logic;
      FSL0_S_EXISTS : in std_logic;
      FSL0_M_CLK : out std_logic;
      FSL0_M_WRITE : out std_logic;
      FSL0_M_DATA : out std_logic_vector(0 to 31);
      FSL0_M_CONTROL : out std_logic;
      FSL0_M_FULL : in std_logic;
      FSL1_S_CLK : out std_logic;
      FSL1_S_READ : out std_logic;
      FSL1_S_DATA : in std_logic_vector(0 to 31);
      FSL1_S_CONTROL : in std_logic;
      FSL1_S_EXISTS : in std_logic;
      FSL1_M_CLK : out std_logic;
      FSL1_M_WRITE : out std_logic;
      FSL1_M_DATA : out std_logic_vector(0 to 31);
      FSL1_M_CONTROL : out std_logic;
      FSL1_M_FULL : in std_logic;
      FSL2_S_CLK : out std_logic;
      FSL2_S_READ : out std_logic;
      FSL2_S_DATA : in std_logic_vector(0 to 31);
      FSL2_S_CONTROL : in std_logic;
      FSL2_S_EXISTS : in std_logic;
      FSL2_M_CLK : out std_logic;
      FSL2_M_WRITE : out std_logic;
      FSL2_M_DATA : out std_logic_vector(0 to 31);
      FSL2_M_CONTROL : out std_logic;
      FSL2_M_FULL : in std_logic;
      FSL3_S_CLK : out std_logic;
      FSL3_S_READ : out std_logic;
      FSL3_S_DATA : in std_logic_vector(0 to 31);
      FSL3_S_CONTROL : in std_logic;
      FSL3_S_EXISTS : in std_logic;
      FSL3_M_CLK : out std_logic;
      FSL3_M_WRITE : out std_logic;
      FSL3_M_DATA : out std_logic_vector(0 to 31);
      FSL3_M_CONTROL : out std_logic;
      FSL3_M_FULL : in std_logic;
      FSL4_S_CLK : out std_logic;
      FSL4_S_READ : out std_logic;
      FSL4_S_DATA : in std_logic_vector(0 to 31);
      FSL4_S_CONTROL : in std_logic;
      FSL4_S_EXISTS : in std_logic;
      FSL4_M_CLK : out std_logic;
      FSL4_M_WRITE : out std_logic;
      FSL4_M_DATA : out std_logic_vector(0 to 31);
      FSL4_M_CONTROL : out std_logic;
      FSL4_M_FULL : in std_logic;
      FSL5_S_CLK : out std_logic;
      FSL5_S_READ : out std_logic;
      FSL5_S_DATA : in std_logic_vector(0 to 31);
      FSL5_S_CONTROL : in std_logic;
      FSL5_S_EXISTS : in std_logic;
      FSL5_M_CLK : out std_logic;
      FSL5_M_WRITE : out std_logic;
      FSL5_M_DATA : out std_logic_vector(0 to 31);
      FSL5_M_CONTROL : out std_logic;
      FSL5_M_FULL : in std_logic;
      FSL6_S_CLK : out std_logic;
      FSL6_S_READ : out std_logic;
      FSL6_S_DATA : in std_logic_vector(0 to 31);
      FSL6_S_CONTROL : in std_logic;
      FSL6_S_EXISTS : in std_logic;
      FSL6_M_CLK : out std_logic;
      FSL6_M_WRITE : out std_logic;
      FSL6_M_DATA : out std_logic_vector(0 to 31);
      FSL6_M_CONTROL : out std_logic;
      FSL6_M_FULL : in std_logic;
      FSL7_S_CLK : out std_logic;
      FSL7_S_READ : out std_logic;
      FSL7_S_DATA : in std_logic_vector(0 to 31);
      FSL7_S_CONTROL : in std_logic;
      FSL7_S_EXISTS : in std_logic;
      FSL7_M_CLK : out std_logic;
      FSL7_M_WRITE : out std_logic;
      FSL7_M_DATA : out std_logic_vector(0 to 31);
      FSL7_M_CONTROL : out std_logic;
      FSL7_M_FULL : in std_logic;
      FSL8_S_CLK : out std_logic;
      FSL8_S_READ : out std_logic;
      FSL8_S_DATA : in std_logic_vector(0 to 31);
      FSL8_S_CONTROL : in std_logic;
      FSL8_S_EXISTS : in std_logic;
      FSL8_M_CLK : out std_logic;
      FSL8_M_WRITE : out std_logic;
      FSL8_M_DATA : out std_logic_vector(0 to 31);
      FSL8_M_CONTROL : out std_logic;
      FSL8_M_FULL : in std_logic;
      FSL9_S_CLK : out std_logic;
      FSL9_S_READ : out std_logic;
      FSL9_S_DATA : in std_logic_vector(0 to 31);
      FSL9_S_CONTROL : in std_logic;
      FSL9_S_EXISTS : in std_logic;
      FSL9_M_CLK : out std_logic;
      FSL9_M_WRITE : out std_logic;
      FSL9_M_DATA : out std_logic_vector(0 to 31);
      FSL9_M_CONTROL : out std_logic;
      FSL9_M_FULL : in std_logic;
      FSL10_S_CLK : out std_logic;
      FSL10_S_READ : out std_logic;
      FSL10_S_DATA : in std_logic_vector(0 to 31);
      FSL10_S_CONTROL : in std_logic;
      FSL10_S_EXISTS : in std_logic;
      FSL10_M_CLK : out std_logic;
      FSL10_M_WRITE : out std_logic;
      FSL10_M_DATA : out std_logic_vector(0 to 31);
      FSL10_M_CONTROL : out std_logic;
      FSL10_M_FULL : in std_logic;
      FSL11_S_CLK : out std_logic;
      FSL11_S_READ : out std_logic;
      FSL11_S_DATA : in std_logic_vector(0 to 31);
      FSL11_S_CONTROL : in std_logic;
      FSL11_S_EXISTS : in std_logic;
      FSL11_M_CLK : out std_logic;
      FSL11_M_WRITE : out std_logic;
      FSL11_M_DATA : out std_logic_vector(0 to 31);
      FSL11_M_CONTROL : out std_logic;
      FSL11_M_FULL : in std_logic;
      FSL12_S_CLK : out std_logic;
      FSL12_S_READ : out std_logic;
      FSL12_S_DATA : in std_logic_vector(0 to 31);
      FSL12_S_CONTROL : in std_logic;
      FSL12_S_EXISTS : in std_logic;
      FSL12_M_CLK : out std_logic;
      FSL12_M_WRITE : out std_logic;
      FSL12_M_DATA : out std_logic_vector(0 to 31);
      FSL12_M_CONTROL : out std_logic;
      FSL12_M_FULL : in std_logic;
      FSL13_S_CLK : out std_logic;
      FSL13_S_READ : out std_logic;
      FSL13_S_DATA : in std_logic_vector(0 to 31);
      FSL13_S_CONTROL : in std_logic;
      FSL13_S_EXISTS : in std_logic;
      FSL13_M_CLK : out std_logic;
      FSL13_M_WRITE : out std_logic;
      FSL13_M_DATA : out std_logic_vector(0 to 31);
      FSL13_M_CONTROL : out std_logic;
      FSL13_M_FULL : in std_logic;
      FSL14_S_CLK : out std_logic;
      FSL14_S_READ : out std_logic;
      FSL14_S_DATA : in std_logic_vector(0 to 31);
      FSL14_S_CONTROL : in std_logic;
      FSL14_S_EXISTS : in std_logic;
      FSL14_M_CLK : out std_logic;
      FSL14_M_WRITE : out std_logic;
      FSL14_M_DATA : out std_logic_vector(0 to 31);
      FSL14_M_CONTROL : out std_logic;
      FSL14_M_FULL : in std_logic;
      FSL15_S_CLK : out std_logic;
      FSL15_S_READ : out std_logic;
      FSL15_S_DATA : in std_logic_vector(0 to 31);
      FSL15_S_CONTROL : in std_logic;
      FSL15_S_EXISTS : in std_logic;
      FSL15_M_CLK : out std_logic;
      FSL15_M_WRITE : out std_logic;
      FSL15_M_DATA : out std_logic_vector(0 to 31);
      FSL15_M_CONTROL : out std_logic;
      FSL15_M_FULL : in std_logic;
      ICACHE_FSL_IN_CLK : out std_logic;
      ICACHE_FSL_IN_READ : out std_logic;
      ICACHE_FSL_IN_DATA : in std_logic_vector(0 to 31);
      ICACHE_FSL_IN_CONTROL : in std_logic;
      ICACHE_FSL_IN_EXISTS : in std_logic;
      ICACHE_FSL_OUT_CLK : out std_logic;
      ICACHE_FSL_OUT_WRITE : out std_logic;
      ICACHE_FSL_OUT_DATA : out std_logic_vector(0 to 31);
      ICACHE_FSL_OUT_CONTROL : out std_logic;
      ICACHE_FSL_OUT_FULL : in std_logic;
      DCACHE_FSL_IN_CLK : out std_logic;
      DCACHE_FSL_IN_READ : out std_logic;
      DCACHE_FSL_IN_DATA : in std_logic_vector(0 to 31);
      DCACHE_FSL_IN_CONTROL : in std_logic;
      DCACHE_FSL_IN_EXISTS : in std_logic;
      DCACHE_FSL_OUT_CLK : out std_logic;
      DCACHE_FSL_OUT_WRITE : out std_logic;
      DCACHE_FSL_OUT_DATA : out std_logic_vector(0 to 31);
      DCACHE_FSL_OUT_CONTROL : out std_logic;
      DCACHE_FSL_OUT_FULL : in std_logic
    );
  end component;

  component plb_bus_mba_wrapper is
    port (
      PLB_Clk : in std_logic;
      SYS_Rst : in std_logic;
      PLB_Rst : out std_logic;
      SPLB_Rst : out std_logic_vector(0 to 1);
      MPLB_Rst : out std_logic_vector(0 to 1);
      PLB_dcrAck : out std_logic;
      PLB_dcrDBus : out std_logic_vector(0 to 31);
      DCR_ABus : in std_logic_vector(0 to 9);
      DCR_DBus : in std_logic_vector(0 to 31);
      DCR_Read : in std_logic;
      DCR_Write : in std_logic;
      M_ABus : in std_logic_vector(0 to 63);
      M_UABus : in std_logic_vector(0 to 63);
      M_BE : in std_logic_vector(0 to 7);
      M_RNW : in std_logic_vector(0 to 1);
      M_abort : in std_logic_vector(0 to 1);
      M_busLock : in std_logic_vector(0 to 1);
      M_TAttribute : in std_logic_vector(0 to 31);
      M_lockErr : in std_logic_vector(0 to 1);
      M_MSize : in std_logic_vector(0 to 3);
      M_priority : in std_logic_vector(0 to 3);
      M_rdBurst : in std_logic_vector(0 to 1);
      M_request : in std_logic_vector(0 to 1);
      M_size : in std_logic_vector(0 to 7);
      M_type : in std_logic_vector(0 to 5);
      M_wrBurst : in std_logic_vector(0 to 1);
      M_wrDBus : in std_logic_vector(0 to 63);
      Sl_addrAck : in std_logic_vector(0 to 1);
      Sl_MRdErr : in std_logic_vector(0 to 3);
      Sl_MWrErr : in std_logic_vector(0 to 3);
      Sl_MBusy : in std_logic_vector(0 to 3);
      Sl_rdBTerm : in std_logic_vector(0 to 1);
      Sl_rdComp : in std_logic_vector(0 to 1);
      Sl_rdDAck : in std_logic_vector(0 to 1);
      Sl_rdDBus : in std_logic_vector(0 to 63);
      Sl_rdWdAddr : in std_logic_vector(0 to 7);
      Sl_rearbitrate : in std_logic_vector(0 to 1);
      Sl_SSize : in std_logic_vector(0 to 3);
      Sl_wait : in std_logic_vector(0 to 1);
      Sl_wrBTerm : in std_logic_vector(0 to 1);
      Sl_wrComp : in std_logic_vector(0 to 1);
      Sl_wrDAck : in std_logic_vector(0 to 1);
      Sl_MIRQ : in std_logic_vector(0 to 3);
      PLB_MIRQ : out std_logic_vector(0 to 1);
      PLB_ABus : out std_logic_vector(0 to 31);
      PLB_UABus : out std_logic_vector(0 to 31);
      PLB_BE : out std_logic_vector(0 to 3);
      PLB_MAddrAck : out std_logic_vector(0 to 1);
      PLB_MTimeout : out std_logic_vector(0 to 1);
      PLB_MBusy : out std_logic_vector(0 to 1);
      PLB_MRdErr : out std_logic_vector(0 to 1);
      PLB_MWrErr : out std_logic_vector(0 to 1);
      PLB_MRdBTerm : out std_logic_vector(0 to 1);
      PLB_MRdDAck : out std_logic_vector(0 to 1);
      PLB_MRdDBus : out std_logic_vector(0 to 63);
      PLB_MRdWdAddr : out std_logic_vector(0 to 7);
      PLB_MRearbitrate : out std_logic_vector(0 to 1);
      PLB_MWrBTerm : out std_logic_vector(0 to 1);
      PLB_MWrDAck : out std_logic_vector(0 to 1);
      PLB_MSSize : out std_logic_vector(0 to 3);
      PLB_PAValid : out std_logic;
      PLB_RNW : out std_logic;
      PLB_SAValid : out std_logic;
      PLB_abort : out std_logic;
      PLB_busLock : out std_logic;
      PLB_TAttribute : out std_logic_vector(0 to 15);
      PLB_lockErr : out std_logic;
      PLB_masterID : out std_logic_vector(0 to 0);
      PLB_MSize : out std_logic_vector(0 to 1);
      PLB_rdPendPri : out std_logic_vector(0 to 1);
      PLB_wrPendPri : out std_logic_vector(0 to 1);
      PLB_rdPendReq : out std_logic;
      PLB_wrPendReq : out std_logic;
      PLB_rdBurst : out std_logic;
      PLB_rdPrim : out std_logic_vector(0 to 1);
      PLB_reqPri : out std_logic_vector(0 to 1);
      PLB_size : out std_logic_vector(0 to 3);
      PLB_type : out std_logic_vector(0 to 2);
      PLB_wrBurst : out std_logic;
      PLB_wrDBus : out std_logic_vector(0 to 31);
      PLB_wrPrim : out std_logic_vector(0 to 1);
      PLB_SaddrAck : out std_logic;
      PLB_SMRdErr : out std_logic_vector(0 to 1);
      PLB_SMWrErr : out std_logic_vector(0 to 1);
      PLB_SMBusy : out std_logic_vector(0 to 1);
      PLB_SrdBTerm : out std_logic;
      PLB_SrdComp : out std_logic;
      PLB_SrdDAck : out std_logic;
      PLB_SrdDBus : out std_logic_vector(0 to 31);
      PLB_SrdWdAddr : out std_logic_vector(0 to 3);
      PLB_Srearbitrate : out std_logic;
      PLB_Sssize : out std_logic_vector(0 to 1);
      PLB_Swait : out std_logic;
      PLB_SwrBTerm : out std_logic;
      PLB_SwrComp : out std_logic;
      PLB_SwrDAck : out std_logic;
      PLB2OPB_rearb : in std_logic_vector(0 to 1);
      Bus_Error_Det : out std_logic
    );
  end component;

  component ilmb_mba_wrapper is
    port (
      LMB_Clk : in std_logic;
      SYS_Rst : in std_logic;
      LMB_Rst : out std_logic;
      M_ABus : in std_logic_vector(0 to 31);
      M_ReadStrobe : in std_logic;
      M_WriteStrobe : in std_logic;
      M_AddrStrobe : in std_logic;
      M_DBus : in std_logic_vector(0 to 31);
      M_BE : in std_logic_vector(0 to 3);
      Sl_DBus : in std_logic_vector(0 to 31);
      Sl_Ready : in std_logic_vector(0 to 0);
      LMB_ABus : out std_logic_vector(0 to 31);
      LMB_ReadStrobe : out std_logic;
      LMB_WriteStrobe : out std_logic;
      LMB_AddrStrobe : out std_logic;
      LMB_ReadDBus : out std_logic_vector(0 to 31);
      LMB_WriteDBus : out std_logic_vector(0 to 31);
      LMB_Ready : out std_logic;
      LMB_BE : out std_logic_vector(0 to 3)
    );
  end component;

  component dlmb_mba_wrapper is
    port (
      LMB_Clk : in std_logic;
      SYS_Rst : in std_logic;
      LMB_Rst : out std_logic;
      M_ABus : in std_logic_vector(0 to 31);
      M_ReadStrobe : in std_logic;
      M_WriteStrobe : in std_logic;
      M_AddrStrobe : in std_logic;
      M_DBus : in std_logic_vector(0 to 31);
      M_BE : in std_logic_vector(0 to 3);
      Sl_DBus : in std_logic_vector(0 to 31);
      Sl_Ready : in std_logic_vector(0 to 0);
      LMB_ABus : out std_logic_vector(0 to 31);
      LMB_ReadStrobe : out std_logic;
      LMB_WriteStrobe : out std_logic;
      LMB_AddrStrobe : out std_logic;
      LMB_ReadDBus : out std_logic_vector(0 to 31);
      LMB_WriteDBus : out std_logic_vector(0 to 31);
      LMB_Ready : out std_logic;
      LMB_BE : out std_logic_vector(0 to 3)
    );
  end component;

  component dlmb_cntlr_mba_wrapper is
    port (
      LMB_Clk : in std_logic;
      LMB_Rst : in std_logic;
      LMB_ABus : in std_logic_vector(0 to 31);
      LMB_WriteDBus : in std_logic_vector(0 to 31);
      LMB_AddrStrobe : in std_logic;
      LMB_ReadStrobe : in std_logic;
      LMB_WriteStrobe : in std_logic;
      LMB_BE : in std_logic_vector(0 to 3);
      Sl_DBus : out std_logic_vector(0 to 31);
      Sl_Ready : out std_logic;
      BRAM_Rst_A : out std_logic;
      BRAM_Clk_A : out std_logic;
      BRAM_EN_A : out std_logic;
      BRAM_WEN_A : out std_logic_vector(0 to 3);
      BRAM_Addr_A : out std_logic_vector(0 to 31);
      BRAM_Din_A : in std_logic_vector(0 to 31);
      BRAM_Dout_A : out std_logic_vector(0 to 31)
    );
  end component;

  component ilmb_cntlr_mba_wrapper is
    port (
      LMB_Clk : in std_logic;
      LMB_Rst : in std_logic;
      LMB_ABus : in std_logic_vector(0 to 31);
      LMB_WriteDBus : in std_logic_vector(0 to 31);
      LMB_AddrStrobe : in std_logic;
      LMB_ReadStrobe : in std_logic;
      LMB_WriteStrobe : in std_logic;
      LMB_BE : in std_logic_vector(0 to 3);
      Sl_DBus : out std_logic_vector(0 to 31);
      Sl_Ready : out std_logic;
      BRAM_Rst_A : out std_logic;
      BRAM_Clk_A : out std_logic;
      BRAM_EN_A : out std_logic;
      BRAM_WEN_A : out std_logic_vector(0 to 3);
      BRAM_Addr_A : out std_logic_vector(0 to 31);
      BRAM_Din_A : in std_logic_vector(0 to 31);
      BRAM_Dout_A : out std_logic_vector(0 to 31)
    );
  end component;

  component lmb_bram_mba_wrapper is
    port (
      BRAM_Rst_A : in std_logic;
      BRAM_Clk_A : in std_logic;
      BRAM_EN_A : in std_logic;
      BRAM_WEN_A : in std_logic_vector(0 to 3);
      BRAM_Addr_A : in std_logic_vector(0 to 31);
      BRAM_Din_A : out std_logic_vector(0 to 31);
      BRAM_Dout_A : in std_logic_vector(0 to 31);
      BRAM_Rst_B : in std_logic;
      BRAM_Clk_B : in std_logic;
      BRAM_EN_B : in std_logic;
      BRAM_WEN_B : in std_logic_vector(0 to 3);
      BRAM_Addr_B : in std_logic_vector(0 to 31);
      BRAM_Din_B : out std_logic_vector(0 to 31);
      BRAM_Dout_B : in std_logic_vector(0 to 31)
    );
  end component;

  component plb_gpio_monitor_mba_wrapper is
    port (
      SPLB_Clk : in std_logic;
      SPLB_Rst : in std_logic;
      PLB_ABus : in std_logic_vector(0 to 31);
      PLB_UABus : in std_logic_vector(0 to 31);
      PLB_PAValid : in std_logic;
      PLB_SAValid : in std_logic;
      PLB_rdPrim : in std_logic;
      PLB_wrPrim : in std_logic;
      PLB_masterID : in std_logic_vector(0 to 0);
      PLB_abort : in std_logic;
      PLB_busLock : in std_logic;
      PLB_RNW : in std_logic;
      PLB_BE : in std_logic_vector(0 to 3);
      PLB_MSize : in std_logic_vector(0 to 1);
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_lockErr : in std_logic;
      PLB_wrDBus : in std_logic_vector(0 to 31);
      PLB_wrBurst : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_wrPendReq : in std_logic;
      PLB_rdPendReq : in std_logic;
      PLB_wrPendPri : in std_logic_vector(0 to 1);
      PLB_rdPendPri : in std_logic_vector(0 to 1);
      PLB_reqPri : in std_logic_vector(0 to 1);
      PLB_TAttribute : in std_logic_vector(0 to 15);
      Sl_addrAck : out std_logic;
      Sl_SSize : out std_logic_vector(0 to 1);
      Sl_wait : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck : out std_logic;
      Sl_wrComp : out std_logic;
      Sl_wrBTerm : out std_logic;
      Sl_rdDBus : out std_logic_vector(0 to 31);
      Sl_rdWdAddr : out std_logic_vector(0 to 3);
      Sl_rdDAck : out std_logic;
      Sl_rdComp : out std_logic;
      Sl_rdBTerm : out std_logic;
      Sl_MBusy : out std_logic_vector(0 to 1);
      Sl_MWrErr : out std_logic_vector(0 to 1);
      Sl_MRdErr : out std_logic_vector(0 to 1);
      Sl_MIRQ : out std_logic_vector(0 to 1);
      IP2INTC_Irpt : out std_logic;
      GPIO_IO_I : in std_logic_vector(0 to 16);
      GPIO_IO_O : out std_logic_vector(0 to 16);
      GPIO_IO_T : out std_logic_vector(0 to 16);
      GPIO_in : in std_logic_vector(0 to 16);
      GPIO_d_out : out std_logic_vector(0 to 16);
      GPIO_t_out : out std_logic_vector(0 to 16);
      GPIO2_IO_I : in std_logic_vector(0 to 16);
      GPIO2_IO_O : out std_logic_vector(0 to 16);
      GPIO2_IO_T : out std_logic_vector(0 to 16);
      GPIO2_in : in std_logic_vector(0 to 16);
      GPIO2_d_out : out std_logic_vector(0 to 16);
      GPIO2_t_out : out std_logic_vector(0 to 16)
    );
  end component;

  component plb_mdm_mba_wrapper is
    port (
      Interrupt : out std_logic;
      Debug_SYS_Rst : out std_logic;
      Ext_BRK : out std_logic;
      Ext_NM_BRK : out std_logic;
      SPLB_Clk : in std_logic;
      SPLB_Rst : in std_logic;
      PLB_ABus : in std_logic_vector(0 to 31);
      PLB_UABus : in std_logic_vector(0 to 31);
      PLB_PAValid : in std_logic;
      PLB_SAValid : in std_logic;
      PLB_rdPrim : in std_logic;
      PLB_wrPrim : in std_logic;
      PLB_masterID : in std_logic_vector(0 to 0);
      PLB_abort : in std_logic;
      PLB_busLock : in std_logic;
      PLB_RNW : in std_logic;
      PLB_BE : in std_logic_vector(0 to 3);
      PLB_MSize : in std_logic_vector(0 to 1);
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_lockErr : in std_logic;
      PLB_wrDBus : in std_logic_vector(0 to 31);
      PLB_wrBurst : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_wrPendReq : in std_logic;
      PLB_rdPendReq : in std_logic;
      PLB_wrPendPri : in std_logic_vector(0 to 1);
      PLB_rdPendPri : in std_logic_vector(0 to 1);
      PLB_reqPri : in std_logic_vector(0 to 1);
      PLB_TAttribute : in std_logic_vector(0 to 15);
      Sl_addrAck : out std_logic;
      Sl_SSize : out std_logic_vector(0 to 1);
      Sl_wait : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck : out std_logic;
      Sl_wrComp : out std_logic;
      Sl_wrBTerm : out std_logic;
      Sl_rdDBus : out std_logic_vector(0 to 31);
      Sl_rdWdAddr : out std_logic_vector(0 to 3);
      Sl_rdDAck : out std_logic;
      Sl_rdComp : out std_logic;
      Sl_rdBTerm : out std_logic;
      Sl_MBusy : out std_logic_vector(0 to 1);
      Sl_MWrErr : out std_logic_vector(0 to 1);
      Sl_MRdErr : out std_logic_vector(0 to 1);
      Sl_MIRQ : out std_logic_vector(0 to 1);
      OPB_Clk : in std_logic;
      OPB_Rst : in std_logic;
      OPB_ABus : in std_logic_vector(0 to 31);
      OPB_BE : in std_logic_vector(0 to 3);
      OPB_RNW : in std_logic;
      OPB_select : in std_logic;
      OPB_seqAddr : in std_logic;
      OPB_DBus : in std_logic_vector(0 to 31);
      MDM_DBus : out std_logic_vector(0 to 31);
      MDM_errAck : out std_logic;
      MDM_retry : out std_logic;
      MDM_toutSup : out std_logic;
      MDM_xferAck : out std_logic;
      Dbg_Clk_0 : out std_logic;
      Dbg_TDI_0 : out std_logic;
      Dbg_TDO_0 : in std_logic;
      Dbg_Reg_En_0 : out std_logic_vector(0 to 4);
      Dbg_Capture_0 : out std_logic;
      Dbg_Shift_0 : out std_logic;
      Dbg_Update_0 : out std_logic;
      Dbg_Rst_0 : out std_logic;
      Dbg_Clk_1 : out std_logic;
      Dbg_TDI_1 : out std_logic;
      Dbg_TDO_1 : in std_logic;
      Dbg_Reg_En_1 : out std_logic_vector(0 to 4);
      Dbg_Capture_1 : out std_logic;
      Dbg_Shift_1 : out std_logic;
      Dbg_Update_1 : out std_logic;
      Dbg_Rst_1 : out std_logic;
      Dbg_Clk_2 : out std_logic;
      Dbg_TDI_2 : out std_logic;
      Dbg_TDO_2 : in std_logic;
      Dbg_Reg_En_2 : out std_logic_vector(0 to 4);
      Dbg_Capture_2 : out std_logic;
      Dbg_Shift_2 : out std_logic;
      Dbg_Update_2 : out std_logic;
      Dbg_Rst_2 : out std_logic;
      Dbg_Clk_3 : out std_logic;
      Dbg_TDI_3 : out std_logic;
      Dbg_TDO_3 : in std_logic;
      Dbg_Reg_En_3 : out std_logic_vector(0 to 4);
      Dbg_Capture_3 : out std_logic;
      Dbg_Shift_3 : out std_logic;
      Dbg_Update_3 : out std_logic;
      Dbg_Rst_3 : out std_logic;
      Dbg_Clk_4 : out std_logic;
      Dbg_TDI_4 : out std_logic;
      Dbg_TDO_4 : in std_logic;
      Dbg_Reg_En_4 : out std_logic_vector(0 to 4);
      Dbg_Capture_4 : out std_logic;
      Dbg_Shift_4 : out std_logic;
      Dbg_Update_4 : out std_logic;
      Dbg_Rst_4 : out std_logic;
      Dbg_Clk_5 : out std_logic;
      Dbg_TDI_5 : out std_logic;
      Dbg_TDO_5 : in std_logic;
      Dbg_Reg_En_5 : out std_logic_vector(0 to 4);
      Dbg_Capture_5 : out std_logic;
      Dbg_Shift_5 : out std_logic;
      Dbg_Update_5 : out std_logic;
      Dbg_Rst_5 : out std_logic;
      Dbg_Clk_6 : out std_logic;
      Dbg_TDI_6 : out std_logic;
      Dbg_TDO_6 : in std_logic;
      Dbg_Reg_En_6 : out std_logic_vector(0 to 4);
      Dbg_Capture_6 : out std_logic;
      Dbg_Shift_6 : out std_logic;
      Dbg_Update_6 : out std_logic;
      Dbg_Rst_6 : out std_logic;
      Dbg_Clk_7 : out std_logic;
      Dbg_TDI_7 : out std_logic;
      Dbg_TDO_7 : in std_logic;
      Dbg_Reg_En_7 : out std_logic_vector(0 to 4);
      Dbg_Capture_7 : out std_logic;
      Dbg_Shift_7 : out std_logic;
      Dbg_Update_7 : out std_logic;
      Dbg_Rst_7 : out std_logic;
      bscan_tdi : out std_logic;
      bscan_reset : out std_logic;
      bscan_shift : out std_logic;
      bscan_update : out std_logic;
      bscan_capture : out std_logic;
      bscan_sel1 : out std_logic;
      bscan_drck1 : out std_logic;
      bscan_tdo1 : in std_logic;
      FSL0_S_CLK : out std_logic;
      FSL0_S_READ : out std_logic;
      FSL0_S_DATA : in std_logic_vector(0 to 31);
      FSL0_S_CONTROL : in std_logic;
      FSL0_S_EXISTS : in std_logic;
      FSL0_M_CLK : out std_logic;
      FSL0_M_WRITE : out std_logic;
      FSL0_M_DATA : out std_logic_vector(0 to 31);
      FSL0_M_CONTROL : out std_logic;
      FSL0_M_FULL : in std_logic;
      Ext_JTAG_DRCK : out std_logic;
      Ext_JTAG_RESET : out std_logic;
      Ext_JTAG_SEL : out std_logic;
      Ext_JTAG_CAPTURE : out std_logic;
      Ext_JTAG_SHIFT : out std_logic;
      Ext_JTAG_UPDATE : out std_logic;
      Ext_JTAG_TDI : out std_logic;
      Ext_JTAG_TDO : in std_logic
    );
  end component;

  component inst_proc_sys_reset_wrapper is
    port (
      Slowest_sync_clk : in std_logic;
      Ext_Reset_In : in std_logic;
      Aux_Reset_In : in std_logic;
      MB_Debug_Sys_Rst : in std_logic;
      Core_Reset_Req_0 : in std_logic;
      Chip_Reset_Req_0 : in std_logic;
      System_Reset_Req_0 : in std_logic;
      Core_Reset_Req_1 : in std_logic;
      Chip_Reset_Req_1 : in std_logic;
      System_Reset_Req_1 : in std_logic;
      Dcm_locked : in std_logic;
      RstcPPCresetcore_0 : out std_logic;
      RstcPPCresetchip_0 : out std_logic;
      RstcPPCresetsys_0 : out std_logic;
      RstcPPCresetcore_1 : out std_logic;
      RstcPPCresetchip_1 : out std_logic;
      RstcPPCresetsys_1 : out std_logic;
      MB_Reset : out std_logic;
      Bus_Struct_Reset : out std_logic_vector(0 to 0);
      Peripheral_Reset : out std_logic_vector(0 to 0)
    );
  end component;

  component tmd_mpe_vacc_wrapper is
    port (
      mpe_error : out std_logic;
      clk : in std_logic;
      rst : in std_logic;
      mpe_busy_tx : out std_logic;
      mpe_busy_rx : out std_logic;
      mpe_ila_control : in std_logic_vector(35 downto 0);
      dbg_tx_fsm : out std_logic_vector(3 downto 0);
      dbg_rx_fsm : out std_logic_vector(4 downto 0);
      dbg_index : out std_logic_vector(7 downto 0);
      dbg_clr2snd : out std_logic;
      dbg_nif_full : out std_logic;
      dbg_nif_exists : out std_logic;
      dbg_rx_src : out std_logic_vector(7 downto 0);
      dbg_rx_src_tmp : out std_logic_vector(7 downto 0);
      dbg_tx_dest : out std_logic_vector(7 downto 0);
      from_host_read : out std_logic;
      from_host_data : in std_logic_vector(0 to 31);
      from_host_ctrl : in std_logic;
      from_host_exists : in std_logic;
      to_host_data : out std_logic_vector(0 to 31);
      to_host_write : out std_logic;
      to_host_ctrl : out std_logic;
      to_host_full : in std_logic;
      from_net_if_read : out std_logic;
      from_net_if_data : in std_logic_vector(0 to 31);
      from_net_if_ctrl : in std_logic;
      from_net_if_exists : in std_logic;
      to_net_if_data : out std_logic_vector(0 to 31);
      to_net_if_write : out std_logic;
      to_net_if_ctrl : out std_logic;
      to_net_if_full : in std_logic;
      cmd_in_read : out std_logic;
      cmd_in_data : in std_logic_vector(0 to 31);
      cmd_in_ctrl : in std_logic;
      cmd_in_exists : in std_logic;
      cmd_out_data : out std_logic_vector(0 to 31);
      cmd_out_write : out std_logic;
      cmd_out_ctrl : out std_logic;
      cmd_out_full : in std_logic
    );
  end component;

  --component vacc_wrapper is
  --  port (
  --    Clk : in std_logic;
  --    Rst : in std_logic;
  --    Math_error : out std_logic;
  --    Buffer_error : out std_logic;
  --    Instr_error : out std_logic;
  --    From_mpe_data_read : out std_logic;
  --    From_mpe_data_data : in std_logic_vector(0 to 31);
  --    From_mpe_data_ctrl : in std_logic;
  --    From_mpe_data_exists : in std_logic;
  --    To_mpe_data_data : out std_logic_vector(0 to 31);
  --    To_mpe_data_write : out std_logic;
  --    To_mpe_data_ctrl : out std_logic;
  --    To_mpe_data_full : in std_logic;
  --    From_mpe_cmd_read : out std_logic;
  --    From_mpe_cmd_data : in std_logic_vector(0 to 31);
  --    From_mpe_cmd_ctrl : in std_logic;
  --    From_mpe_cmd_exists : in std_logic;
  --    To_mpe_cmd_data : out std_logic_vector(0 to 31);
  --    To_mpe_cmd_write : out std_logic;
  --    To_mpe_cmd_ctrl : out std_logic;
  --    To_mpe_cmd_full : in std_logic
  --  );
  --end component;

  component IOBUF is
    port (
      I : in std_logic;
      IO : inout std_logic;
      O : out std_logic;
      T : in std_logic
    );
  end component;

  -- Internal signals

  signal Buffer_error : std_logic;
  signal Ext_BRK : std_logic;
  signal Ext_NM_BRK : std_logic;
  signal Instr_error : std_logic;
  signal Math_error : std_logic;
  signal RAM5_ADDR_I : std_logic_vector(21 downto 0);
  signal RAM5_ADDR_O : std_logic_vector(21 downto 0);
  signal RAM5_ADDR_T : std_logic;
  signal RAM5_BW_N_I : std_logic_vector(3 downto 0);
  signal RAM5_BW_N_O : std_logic_vector(3 downto 0);
  signal RAM5_BW_N_T : std_logic;
  signal RAM5_DQ_I : std_logic_vector(31 downto 0);
  signal RAM5_DQ_O : std_logic_vector(31 downto 0);
  signal RAM5_DQ_P_I : std_logic_vector(3 downto 0);
  signal RAM5_DQ_P_O : std_logic_vector(3 downto 0);
  signal RAM5_DQ_P_T : std_logic;
  signal RAM5_DQ_T : std_logic;
  signal RAM6_ADDR_I : std_logic_vector(21 downto 0);
  signal RAM6_ADDR_O : std_logic_vector(21 downto 0);
  signal RAM6_ADDR_T : std_logic;
  signal RAM6_BW_N_I : std_logic_vector(3 downto 0);
  signal RAM6_BW_N_O : std_logic_vector(3 downto 0);
  signal RAM6_BW_N_T : std_logic;
  signal RAM6_DQ_I : std_logic_vector(31 downto 0);
  signal RAM6_DQ_O : std_logic_vector(31 downto 0);
  signal RAM6_DQ_P_I : std_logic_vector(3 downto 0);
  signal RAM6_DQ_P_O : std_logic_vector(3 downto 0);
  signal RAM6_DQ_P_T : std_logic;
  signal RAM6_DQ_T : std_logic;
  signal RAM_PWR_ON_I : std_logic;
  signal RAM_PWR_ON_O : std_logic;
  signal RAM_PWR_ON_T : std_logic;
  signal dbg_index : std_logic_vector(7 downto 0);
  signal dbg_rx_fsm : std_logic_vector(4 downto 0);
  signal dbg_tx_fsm : std_logic_vector(3 downto 0);
  signal dlmb_mba_LMB_ABus : std_logic_vector(0 to 31);
  signal dlmb_mba_LMB_AddrStrobe : std_logic;
  signal dlmb_mba_LMB_BE : std_logic_vector(0 to 3);
  signal dlmb_mba_LMB_ReadDBus : std_logic_vector(0 to 31);
  signal dlmb_mba_LMB_ReadStrobe : std_logic;
  signal dlmb_mba_LMB_Ready : std_logic;
  signal dlmb_mba_LMB_WriteDBus : std_logic_vector(0 to 31);
  signal dlmb_mba_LMB_WriteStrobe : std_logic;
  signal dlmb_mba_M_ABus : std_logic_vector(0 to 31);
  signal dlmb_mba_M_AddrStrobe : std_logic;
  signal dlmb_mba_M_BE : std_logic_vector(0 to 3);
  signal dlmb_mba_M_DBus : std_logic_vector(0 to 31);
  signal dlmb_mba_M_ReadStrobe : std_logic;
  signal dlmb_mba_M_WriteStrobe : std_logic;
  signal dlmb_mba_OPB_Rst : std_logic;
  signal dlmb_mba_Sl_DBus : std_logic_vector(0 to 31);
  signal dlmb_mba_Sl_Ready : std_logic_vector(0 to 0);
  signal dlmb_port_mba_BRAM_Addr : std_logic_vector(0 to 31);
  signal dlmb_port_mba_BRAM_Din : std_logic_vector(0 to 31);
  signal dlmb_port_mba_BRAM_Dout : std_logic_vector(0 to 31);
  signal dlmb_port_mba_BRAM_EN : std_logic;
  signal dlmb_port_mba_BRAM_Rst : std_logic;
  signal dlmb_port_mba_BRAM_WEN : std_logic_vector(0 to 3);
  signal fpga1_clk0_raw : std_logic;
  signal fpga1_clk100_raw : std_logic;
  signal fpga_config_data : std_logic_vector(7 downto 0);
  signal fpga_hot_led_z : std_logic;
  signal fpga_intr : std_logic;
  signal fpga_led0_z : std_logic;
  signal fpga_led1_z : std_logic;
  signal fpga_led2_z : std_logic;
  signal fpga_led3_z : std_logic;
  signal fpga_reg_ads_z : std_logic;
  signal fpga_reg_clk : std_logic;
  signal fpga_reg_en_z : std_logic;
  signal fpga_reg_lds_z : std_logic;
  signal fpga_reg_rd_wr_z : std_logic;
  signal fpga_reg_rdy_z : std_logic;
  signal fpga_reg_reset_z : std_logic;
  signal fpga_reg_uds_z : std_logic;
  signal fpga_scl_I : std_logic;
  signal fpga_scl_O : std_logic;
  signal fpga_scl_T : std_logic;
  signal fpga_sda_I : std_logic;
  signal fpga_sda_O : std_logic;
  signal fpga_sda_T : std_logic;
  signal fpga_temp_led_z : std_logic;
  signal fsl_l1_to_mpe_FSL_M_Control : std_logic;
  signal fsl_l1_to_mpe_FSL_M_Data : std_logic_vector(0 to 63);
  signal fsl_l1_to_mpe_FSL_M_Full : std_logic;
  signal fsl_l1_to_mpe_FSL_M_Write : std_logic;
  signal fsl_l1_to_mpe_FSL_S_Control : std_logic;
  signal fsl_l1_to_mpe_FSL_S_Data : std_logic_vector(0 to 63);
  signal fsl_l1_to_mpe_FSL_S_Exists : std_logic;
  signal fsl_l1_to_mpe_FSL_S_Read : std_logic;
  signal fsl_mpe_to_l1_FSL_M_Control : std_logic;
  signal fsl_mpe_to_l1_FSL_M_Data : std_logic_vector(0 to 63);
  signal fsl_mpe_to_l1_FSL_M_Full : std_logic;
  signal fsl_mpe_to_l1_FSL_M_Write : std_logic;
  signal fsl_mpe_to_l1_FSL_S_Control : std_logic;
  signal fsl_mpe_to_l1_FSL_S_Data : std_logic_vector(0 to 63);
  signal fsl_mpe_to_l1_FSL_S_Exists : std_logic;
  signal fsl_mpe_to_l1_FSL_S_Read : std_logic;
  signal fsl_mpecmd_to_vacc_FSL_M_Control : std_logic;
  signal fsl_mpecmd_to_vacc_FSL_M_Data : std_logic_vector(0 to 31);
  signal fsl_mpecmd_to_vacc_FSL_M_Full : std_logic;
  signal fsl_mpecmd_to_vacc_FSL_M_Write : std_logic;
  -- signal fsl_mpecmd_to_vacc_FSL_S_Control : std_logic;
  -- signal fsl_mpecmd_to_vacc_FSL_S_Data : std_logic_vector(0 to 31);
  -- signal fsl_mpecmd_to_vacc_FSL_S_Exists : std_logic;
  -- signal fsl_mpecmd_to_vacc_FSL_S_Read : std_logic;
  signal fsl_mpedata_to_vacc_FSL_M_Control : std_logic;
  signal fsl_mpedata_to_vacc_FSL_M_Data : std_logic_vector(0 to 31);
  signal fsl_mpedata_to_vacc_FSL_M_Full : std_logic;
  signal fsl_mpedata_to_vacc_FSL_M_Write : std_logic;
  -- signal fsl_mpedata_to_vacc_FSL_S_Control : std_logic;
  -- signal fsl_mpedata_to_vacc_FSL_S_Data : std_logic_vector(0 to 31);
  -- signal fsl_mpedata_to_vacc_FSL_S_Exists : std_logic;
  -- signal fsl_mpedata_to_vacc_FSL_S_Read : std_logic;
  -- signal fsl_vacc_to_mpecmd_FSL_M_Control : std_logic;
  -- signal fsl_vacc_to_mpecmd_FSL_M_Data : std_logic_vector(0 to 31);
  signal fsl_vacc_to_mpecmd_FSL_M_Full : std_logic;
  -- signal fsl_vacc_to_mpecmd_FSL_M_Write : std_logic;
  signal fsl_vacc_to_mpecmd_FSL_S_Control : std_logic;
  signal fsl_vacc_to_mpecmd_FSL_S_Data : std_logic_vector(0 to 31);
  signal fsl_vacc_to_mpecmd_FSL_S_Exists : std_logic;
  signal fsl_vacc_to_mpecmd_FSL_S_Read : std_logic;
  -- signal fsl_vacc_to_mpedata_FSL_M_Control : std_logic;
  -- signal fsl_vacc_to_mpedata_FSL_M_Data : std_logic_vector(0 to 31);
  signal fsl_vacc_to_mpedata_FSL_M_Full : std_logic;
  -- signal fsl_vacc_to_mpedata_FSL_M_Write : std_logic;
  signal fsl_vacc_to_mpedata_FSL_S_Control : std_logic;
  signal fsl_vacc_to_mpedata_FSL_S_Data : std_logic_vector(0 to 31);
  signal fsl_vacc_to_mpedata_FSL_S_Exists : std_logic;
  signal fsl_vacc_to_mpedata_FSL_S_Read : std_logic;
  signal ilmb_mba_LMB_ABus : std_logic_vector(0 to 31);
  signal ilmb_mba_LMB_AddrStrobe : std_logic;
  signal ilmb_mba_LMB_BE : std_logic_vector(0 to 3);
  signal ilmb_mba_LMB_ReadDBus : std_logic_vector(0 to 31);
  signal ilmb_mba_LMB_ReadStrobe : std_logic;
  signal ilmb_mba_LMB_Ready : std_logic;
  signal ilmb_mba_LMB_WriteDBus : std_logic_vector(0 to 31);
  signal ilmb_mba_LMB_WriteStrobe : std_logic;
  signal ilmb_mba_M_ABus : std_logic_vector(0 to 31);
  signal ilmb_mba_M_AddrStrobe : std_logic;
  signal ilmb_mba_M_ReadStrobe : std_logic;
  signal ilmb_mba_OPB_Rst : std_logic;
  signal ilmb_mba_Sl_DBus : std_logic_vector(0 to 31);
  signal ilmb_mba_Sl_Ready : std_logic_vector(0 to 0);
  signal ilmb_port_mba_BRAM_Addr : std_logic_vector(0 to 31);
  signal ilmb_port_mba_BRAM_Din : std_logic_vector(0 to 31);
  signal ilmb_port_mba_BRAM_Dout : std_logic_vector(0 to 31);
  signal ilmb_port_mba_BRAM_EN : std_logic;
  signal ilmb_port_mba_BRAM_Rst : std_logic;
  signal ilmb_port_mba_BRAM_WEN : std_logic_vector(0 to 3);
  signal mba_rst_133mhz : std_logic;
  signal mdm_dbgrst_mba : std_logic;
  signal net_gnd0 : std_logic;
  signal net_gnd2 : std_logic_vector(0 to 1);
  signal net_gnd4 : std_logic_vector(0 to 3);
  signal net_gnd5 : std_logic_vector(0 to 4);
  signal net_gnd10 : std_logic_vector(0 to 9);
  signal net_gnd17 : std_logic_vector(0 to 16);
  signal net_gnd32 : std_logic_vector(0 to 31);
  signal net_gnd36 : std_logic_vector(35 downto 0);
  signal net_vcc0 : std_logic;
  signal pgassign1 : std_logic_vector(0 to 7);
  signal pgassign2 : std_logic_vector(0 to 16);
  signal plb_bus_mba_M_ABort : std_logic_vector(0 to 1);
  signal plb_bus_mba_M_ABus : std_logic_vector(0 to 63);
  signal plb_bus_mba_M_BE : std_logic_vector(0 to 7);
  signal plb_bus_mba_M_MSize : std_logic_vector(0 to 3);
  signal plb_bus_mba_M_RNW : std_logic_vector(0 to 1);
  signal plb_bus_mba_M_TAttribute : std_logic_vector(0 to 31);
  signal plb_bus_mba_M_UABus : std_logic_vector(0 to 63);
  signal plb_bus_mba_M_busLock : std_logic_vector(0 to 1);
  signal plb_bus_mba_M_lockErr : std_logic_vector(0 to 1);
  signal plb_bus_mba_M_priority : std_logic_vector(0 to 3);
  signal plb_bus_mba_M_rdBurst : std_logic_vector(0 to 1);
  signal plb_bus_mba_M_request : std_logic_vector(0 to 1);
  signal plb_bus_mba_M_size : std_logic_vector(0 to 7);
  signal plb_bus_mba_M_type : std_logic_vector(0 to 5);
  signal plb_bus_mba_M_wrBurst : std_logic_vector(0 to 1);
  signal plb_bus_mba_M_wrDBus : std_logic_vector(0 to 63);
  signal plb_bus_mba_PLB_ABus : std_logic_vector(0 to 31);
  signal plb_bus_mba_PLB_BE : std_logic_vector(0 to 3);
  signal plb_bus_mba_PLB_MAddrAck : std_logic_vector(0 to 1);
  signal plb_bus_mba_PLB_MBusy : std_logic_vector(0 to 1);
  signal plb_bus_mba_PLB_MIRQ : std_logic_vector(0 to 1);
  signal plb_bus_mba_PLB_MRdDAck : std_logic_vector(0 to 1);
  signal plb_bus_mba_PLB_MRdDBus : std_logic_vector(0 to 63);
  signal plb_bus_mba_PLB_MRdErr : std_logic_vector(0 to 1);
  signal plb_bus_mba_PLB_MRdWdAddr : std_logic_vector(0 to 7);
  signal plb_bus_mba_PLB_MRearbitrate : std_logic_vector(0 to 1);
  signal plb_bus_mba_PLB_MSSize : std_logic_vector(0 to 3);
  signal plb_bus_mba_PLB_MSize : std_logic_vector(0 to 1);
  signal plb_bus_mba_PLB_MTimeout : std_logic_vector(0 to 1);
  signal plb_bus_mba_PLB_MWrBTerm : std_logic_vector(0 to 1);
  signal plb_bus_mba_PLB_MWrDAck : std_logic_vector(0 to 1);
  signal plb_bus_mba_PLB_MWrErr : std_logic_vector(0 to 1);
  signal plb_bus_mba_PLB_PAValid : std_logic;
  signal plb_bus_mba_PLB_RNW : std_logic;
  signal plb_bus_mba_PLB_SAValid : std_logic;
  signal plb_bus_mba_PLB_TAttribute : std_logic_vector(0 to 15);
  signal plb_bus_mba_PLB_UABus : std_logic_vector(0 to 31);
  signal plb_bus_mba_PLB_abort : std_logic;
  signal plb_bus_mba_PLB_busLock : std_logic;
  signal plb_bus_mba_PLB_lockErr : std_logic;
  signal plb_bus_mba_PLB_masterID : std_logic_vector(0 to 0);
  signal plb_bus_mba_PLB_rdBurst : std_logic;
  signal plb_bus_mba_PLB_rdPendPri : std_logic_vector(0 to 1);
  signal plb_bus_mba_PLB_rdPendReq : std_logic;
  signal plb_bus_mba_PLB_rdPrim : std_logic_vector(0 to 1);
  signal plb_bus_mba_PLB_reqPri : std_logic_vector(0 to 1);
  signal plb_bus_mba_PLB_size : std_logic_vector(0 to 3);
  signal plb_bus_mba_PLB_type : std_logic_vector(0 to 2);
  signal plb_bus_mba_PLB_wrBurst : std_logic;
  signal plb_bus_mba_PLB_wrDBus : std_logic_vector(0 to 31);
  signal plb_bus_mba_PLB_wrPendPri : std_logic_vector(0 to 1);
  signal plb_bus_mba_PLB_wrPendReq : std_logic;
  signal plb_bus_mba_PLB_wrPrim : std_logic_vector(0 to 1);
  signal plb_bus_mba_SPLB_Rst : std_logic_vector(0 to 1);
  signal plb_bus_mba_Sl_MBusy : std_logic_vector(0 to 3);
  signal plb_bus_mba_Sl_MIRQ : std_logic_vector(0 to 3);
  signal plb_bus_mba_Sl_MRdErr : std_logic_vector(0 to 3);
  signal plb_bus_mba_Sl_MWrErr : std_logic_vector(0 to 3);
  signal plb_bus_mba_Sl_SSize : std_logic_vector(0 to 3);
  signal plb_bus_mba_Sl_addrAck : std_logic_vector(0 to 1);
  signal plb_bus_mba_Sl_rdBTerm : std_logic_vector(0 to 1);
  signal plb_bus_mba_Sl_rdComp : std_logic_vector(0 to 1);
  signal plb_bus_mba_Sl_rdDAck : std_logic_vector(0 to 1);
  signal plb_bus_mba_Sl_rdDBus : std_logic_vector(0 to 63);
  signal plb_bus_mba_Sl_rdWdAddr : std_logic_vector(0 to 7);
  signal plb_bus_mba_Sl_rearbitrate : std_logic_vector(0 to 1);
  signal plb_bus_mba_Sl_wait : std_logic_vector(0 to 1);
  signal plb_bus_mba_Sl_wrBTerm : std_logic_vector(0 to 1);
  signal plb_bus_mba_Sl_wrComp : std_logic_vector(0 to 1);
  signal plb_bus_mba_Sl_wrDAck : std_logic_vector(0 to 1);
  signal plb_rst_133mhz : std_logic_vector(0 to 0);
  signal pll_clk0_fb : std_logic;
  signal pll_clk0_locked : std_logic;
  signal pll_clk100_fb : std_logic;
  signal srl_rst_clk0 : std_logic;
  signal sys_clk_100mhz : std_logic;
  signal sys_clk_133mhz : std_logic;
  signal sys_clk_200mhz : std_logic;
  signal sys_clk_266mhz : std_logic;
  signal sys_clk_266mhz_90deg : std_logic;
  signal sys_rst_133mhz : std_logic;

  signal LANE_6_DP_P_TRUNC : std_logic_vector(18 downto 1);
  signal LANE_6_DP_N_TRUNC : std_logic_vector(18 downto 1);
  signal LANE_7_DP_P_TRUNC : std_logic_vector(18 downto 1);
  signal LANE_7_DP_N_TRUNC : std_logic_vector(18 downto 1);

  attribute BOX_TYPE : STRING;
  -- attribute BOX_TYPE of inst_m2_dualcompute_infrastructure_wrapper : component is "black_box";
  attribute BOX_TYPE of inst_util_srl_reset_clk0_wrapper : component is "black_box";
  attribute BOX_TYPE of inst_util_clk100_pll_wrapper : component is "black_box";
  attribute BOX_TYPE of inst_util_clk0_pll_wrapper : component is "black_box";
  -- attribute BOX_TYPE of inst_m2_fsl_if_l1_wrapper : component is "black_box";
  attribute BOX_TYPE of fsl_mpe_to_l1_wrapper : component is "black_box";
  attribute BOX_TYPE of fsl_l1_to_mpe_wrapper : component is "black_box";
  attribute BOX_TYPE of fsl_mpecmd_to_vacc_wrapper : component is "black_box";
  attribute BOX_TYPE of fsl_vacc_to_mpecmd_wrapper : component is "black_box";
  attribute BOX_TYPE of fsl_mpedata_to_vacc_wrapper : component is "black_box";
  attribute BOX_TYPE of fsl_vacc_to_mpedata_wrapper : component is "black_box";
  attribute BOX_TYPE of mb_mba_wrapper : component is "black_box";
  attribute BOX_TYPE of plb_bus_mba_wrapper : component is "black_box";
  attribute BOX_TYPE of ilmb_mba_wrapper : component is "black_box";
  attribute BOX_TYPE of dlmb_mba_wrapper : component is "black_box";
  attribute BOX_TYPE of dlmb_cntlr_mba_wrapper : component is "black_box";
  attribute BOX_TYPE of ilmb_cntlr_mba_wrapper : component is "black_box";
  attribute BOX_TYPE of lmb_bram_mba_wrapper : component is "black_box";
  attribute BOX_TYPE of plb_gpio_monitor_mba_wrapper : component is "black_box";
  attribute BOX_TYPE of plb_mdm_mba_wrapper : component is "black_box";
  attribute BOX_TYPE of inst_proc_sys_reset_wrapper : component is "black_box";
  attribute BOX_TYPE of tmd_mpe_vacc_wrapper : component is "black_box";
  -- attribute BOX_TYPE of vacc_wrapper : component is "black_box";

begin

  -- Global clock and reset out

  clk_out   <= sys_clk_133mhz;
  rst_n_out <= not sys_rst_133mhz;

  -- other transformations

  fsl_vacc_to_mpecmd_FSL_M_NotFull <= not fsl_vacc_to_mpecmd_FSL_M_Full;
  fsl_vacc_to_mpedata_FSL_M_NotFull <= not fsl_vacc_to_mpedata_FSL_M_Full;

  LANE_6_DP_P_TRUNC <= LANE_6_DP_P(18 downto 1);
  LANE_6_DP_N_TRUNC <= LANE_6_DP_N(18 downto 1);
  
  LANE_7_DP_P(18 downto 1) <= LANE_7_DP_P_TRUNC;
  LANE_7_DP_P(0)           <= '0';
  LANE_7_DP_N(18 downto 1) <= LANE_7_DP_N_TRUNC;
  LANE_7_DP_N(0)           <= '0';
  
  -- Internal assignments

  FPGA1_LED0_Z <= fpga_led0_z;
  FPGA1_LED1_Z <= fpga_led1_z;
  FPGA1_LED2_Z <= fpga_led2_z;
  FPGA1_LED3_Z <= fpga_led3_z;
  FPGA1_TEMP_LED_Z <= fpga_temp_led_z;
  FPGA1_HOT_LED_Z <= fpga_hot_led_z;
  fpga_reg_en_z <= FPGA1_REG_EN_Z;
  fpga_reg_ads_z <= FPGA1_REG_ADS_Z;
  fpga_reg_uds_z <= FPGA1_REG_UDS_Z;
  fpga_reg_lds_z <= FPGA1_REG_LDS_Z;
  fpga_reg_reset_z <= FPGA1_REG_RESET_Z;
  fpga_reg_rd_wr_z <= FPGA1_REG_RD_WR_Z;
  FPGA1_REG_CLK <= fpga_reg_clk;
  FPGA1_INTR <= fpga_intr;
  FPGA1_REG_RDY_Z <= fpga_reg_rdy_z;
  fpga_config_data <= FPGA1_CONFIG_DATA;
  fsl_mpe_to_l1_FSL_M_Data(32 to 63) <= B"00000000000000000000000000000000";
  pgassign1(0) <= Math_error;
  pgassign1(1) <= Instr_error;
  pgassign1(2) <= Buffer_error;
  pgassign1(3) <= sys_rst_133mhz;
  pgassign2(0 to 3) <= dbg_tx_fsm(3 downto 0);
  pgassign2(4 to 8) <= dbg_rx_fsm(4 downto 0);
  pgassign2(9 to 16) <= dbg_index(7 downto 0);
  net_gnd0 <= '0';
  net_gnd10(0 to 9) <= B"0000000000";
  net_gnd17(0 to 16) <= B"00000000000000000";
  net_gnd2(0 to 1) <= B"00";
  net_gnd32(0 to 31) <= B"00000000000000000000000000000000";
  net_gnd36(35 downto 0) <= B"000000000000000000000000000000000000";
  net_gnd4(0 to 3) <= B"0000";
  net_gnd5(0 to 4) <= B"00000";
  net_vcc0 <= '1';

  inst_m2_dualcompute_infrastructure : inst_m2_dualcompute_infrastructure_wrapper
    port map (
      i_fpga_clk0_p => FPGA1_CLK0_P,
      i_fpga_clk0_n => FPGA1_CLK0_N,
      o_fpga_clk0_raw => fpga1_clk0_raw,
      o_fpga_clk0_bufg => open,
      i_fpga_clk1_p => FPGA1_CLK1_P,
      i_fpga_clk1_n => FPGA1_CLK1_N,
      o_fpga_clk1_raw => open,
      o_fpga_clk1_bufg => open,
      i_fpga_clk100_p => FPGA1_CLK100_P,
      i_fpga_clk100_n => FPGA1_CLK100_N,
      o_fpga_clk100_raw => fpga1_clk100_raw,
      o_fpga_clk100_bufg => sys_clk_100mhz,
      o_fpga_led0_z => fpga_led0_z,
      o_fpga_led1_z => fpga_led1_z,
      o_fpga_led2_z => fpga_led2_z,
      o_fpga_led3_z => fpga_led3_z,
      o_ram0_led_z => RAM5_LED_Z,
      o_ram1_led_z => RAM6_LED_Z,
      o_fpga_temp_led_z => fpga_temp_led_z,
      o_fpga_hot_led_z => fpga_hot_led_z,
      i_fpga_reg_en_z => fpga_reg_en_z,
      i_fpga_reg_ads_z => fpga_reg_ads_z,
      i_fpga_reg_uds_z => fpga_reg_uds_z,
      i_fpga_reg_lds_z => fpga_reg_lds_z,
      i_fpga_reg_reset_z => fpga_reg_reset_z,
      i_fpga_reg_rd_wr_z => fpga_reg_rd_wr_z,
      o_fpga_reg_clk => fpga_reg_clk,
      o_fpga_intr => fpga_intr,
      o_fpga_reg_rdy_z => fpga_reg_rdy_z,
      i_fpga_config_data => fpga_config_data,
      i_ram0_cq => RAM5_CQ,
      i_ram0_cq_n => RAM5_CQ_N,
      o_ram0_ld_n => RAM5_LD_N,
      o_ram0_rw_n => RAM5_RW_N,
      o_ram0_dll_off_n => RAM5_DLL_OFF_N,
      o_ram0_k => RAM5_K,
      o_ram0_k_n => RAM5_K_N,
      i_ram0_mbank_sel => RAM5_MBANK_SEL,
      i_ram1_cq => RAM6_CQ,
      i_ram1_cq_n => RAM6_CQ_N,
      o_ram1_ld_n => RAM6_LD_N,
      o_ram1_rw_n => RAM6_RW_N,
      o_ram1_dll_off_n => RAM6_DLL_OFF_N,
      o_ram1_k => RAM6_K,
      o_ram1_k_n => RAM6_K_N,
      i_ram1_mbank_sel => RAM6_MBANK_SEL,
      i_led_override => pgassign1,
      b_fpga_scl_I => fpga_scl_I,
      b_fpga_scl_O => fpga_scl_O,
      b_fpga_scl_T => fpga_scl_T,
      b_fpga_sda_I => fpga_sda_I,
      b_fpga_sda_O => fpga_sda_O,
      b_fpga_sda_T => fpga_sda_T,
      b_ram_pwr_on_I => RAM_PWR_ON_I,
      b_ram_pwr_on_O => RAM_PWR_ON_O,
      b_ram_pwr_on_T => RAM_PWR_ON_T,
      b_ram0_dq_I => RAM5_DQ_I,
      b_ram0_dq_O => RAM5_DQ_O,
      b_ram0_dq_T => RAM5_DQ_T,
      b_ram0_dq_p_I => RAM5_DQ_P_I,
      b_ram0_dq_p_O => RAM5_DQ_P_O,
      b_ram0_dq_p_T => RAM5_DQ_P_T,
      b_ram0_addr_I => RAM5_ADDR_I,
      b_ram0_addr_O => RAM5_ADDR_O,
      b_ram0_addr_T => RAM5_ADDR_T,
      b_ram0_bw_n_I => RAM5_BW_N_I,
      b_ram0_bw_n_O => RAM5_BW_N_O,
      b_ram0_bw_n_T => RAM5_BW_N_T,
      b_ram1_dq_I => RAM6_DQ_I,
      b_ram1_dq_O => RAM6_DQ_O,
      b_ram1_dq_T => RAM6_DQ_T,
      b_ram1_dq_p_I => RAM6_DQ_P_I,
      b_ram1_dq_p_O => RAM6_DQ_P_O,
      b_ram1_dq_p_T => RAM6_DQ_P_T,
      b_ram1_addr_I => RAM6_ADDR_I,
      b_ram1_addr_O => RAM6_ADDR_O,
      b_ram1_addr_T => RAM6_ADDR_T,
      b_ram1_bw_n_I => RAM6_BW_N_I,
      b_ram1_bw_n_O => RAM6_BW_N_O,
      b_ram1_bw_n_T => RAM6_BW_N_T
    );

  inst_util_srl_reset_clk0 : inst_util_srl_reset_clk0_wrapper
    port map (
      i_clk => sys_clk_100mhz,
      i_en => net_vcc0,
      o_rst => srl_rst_clk0
    );

  inst_util_clk100_pll : inst_util_clk100_pll_wrapper
    port map (
      i_raw_clk => fpga1_clk100_raw,
      i_pll_rst => net_gnd0,
      i_pll_clk_fbin => pll_clk100_fb,
      o_pll_clk_fbout => pll_clk100_fb,
      o_pll_clk0 => sys_clk_200mhz,
      o_pll_clk1 => open,
      o_pll_clk2 => open,
      o_pll_clk3 => open,
      o_pll_clk4 => open,
      o_pll_clk5 => open,
      o_pll_locked => open
    );

  inst_util_clk0_pll : inst_util_clk0_pll_wrapper
    port map (
      i_raw_clk => fpga1_clk0_raw,
      i_pll_rst => srl_rst_clk0,
      i_pll_clk_fbin => pll_clk0_fb,
      o_pll_clk_fbout => pll_clk0_fb,
      o_pll_clk0 => sys_clk_266mhz,
      o_pll_clk1 => sys_clk_266mhz_90deg,
      o_pll_clk2 => sys_clk_133mhz,
      o_pll_clk3 => open,
      o_pll_clk4 => open,
      o_pll_clk5 => open,
      o_pll_locked => pll_clk0_locked
    );

  inst_m2_fsl_if_l1 : inst_m2_fsl_if_l1_wrapper
    port map (
      i_clk_200mhz => sys_clk_200mhz,
      i_clk_1x => sys_clk_133mhz,
      i_clk_2x => sys_clk_266mhz,
      i_clk_2x_90deg => sys_clk_266mhz_90deg,
      i_rst_tx => net_gnd0,
      i_rst_rx => net_gnd0,
      i_rst_sys => net_gnd0,
      i_pll_locked => pll_clk0_locked,
      o_rst => sys_rst_133mhz,
      i_lane_p => LANE_6_DP_P_TRUNC,
      i_lane_n => LANE_6_DP_N_TRUNC,
      o_lane_p => LANE_7_DP_P_TRUNC,
      o_lane_n => LANE_7_DP_N_TRUNC,
      o_mfsl_clk => open,
      o_mfsl_write => fsl_l1_to_mpe_FSL_M_Write,
      o_mfsl_data => fsl_l1_to_mpe_FSL_M_Data,
      o_mfsl_control => fsl_l1_to_mpe_FSL_M_Control,
      i_mfsl_full => fsl_l1_to_mpe_FSL_M_Full,
      o_sfsl_clk => open,
      o_sfsl_read => fsl_mpe_to_l1_FSL_S_Read,
      i_sfsl_data => fsl_mpe_to_l1_FSL_S_Data,
      i_sfsl_control => fsl_mpe_to_l1_FSL_S_Control,
      i_sfsl_exists => fsl_mpe_to_l1_FSL_S_Exists,
      o_dbg_tx => open,
      o_dbg_rx => open,
      o_dbg_tx_cnt => open,
      o_dbg_rx_cnt => open,
      o_dbg_last_rx => open,
      o_leds => open,
      i_opb_clk => net_gnd0,
      i_opb_rst => net_gnd0,
      i_opb_abus => net_gnd32,
      i_opb_be => net_gnd4,
      i_opb_dbus => net_gnd32,
      i_opb_rnw => net_gnd0,
      i_opb_select => net_gnd0,
      i_opb_seqaddr => net_gnd0,
      o_opb_dbus => open,
      o_opb_errack => open,
      o_opb_retry => open,
      o_opb_toutsup => open,
      o_opb_xferack => open
    );

  fsl_mpe_to_l1 : fsl_mpe_to_l1_wrapper
    port map (
      FSL_Clk => sys_clk_133mhz,
      SYS_Rst => sys_rst_133mhz,
      FSL_Rst => open,
      FSL_M_Clk => net_gnd0,
      FSL_M_Data => fsl_mpe_to_l1_FSL_M_Data,
      FSL_M_Control => fsl_mpe_to_l1_FSL_M_Control,
      FSL_M_Write => fsl_mpe_to_l1_FSL_M_Write,
      FSL_M_Full => fsl_mpe_to_l1_FSL_M_Full,
      FSL_S_Clk => net_gnd0,
      FSL_S_Data => fsl_mpe_to_l1_FSL_S_Data,
      FSL_S_Control => fsl_mpe_to_l1_FSL_S_Control,
      FSL_S_Read => fsl_mpe_to_l1_FSL_S_Read,
      FSL_S_Exists => fsl_mpe_to_l1_FSL_S_Exists,
      FSL_Full => open,
      FSL_Has_Data => open,
      FSL_Control_IRQ => open
    );

  fsl_l1_to_mpe : fsl_l1_to_mpe_wrapper
    port map (
      FSL_Clk => sys_clk_133mhz,
      SYS_Rst => sys_rst_133mhz,
      FSL_Rst => open,
      FSL_M_Clk => net_gnd0,
      FSL_M_Data => fsl_l1_to_mpe_FSL_M_Data,
      FSL_M_Control => fsl_l1_to_mpe_FSL_M_Control,
      FSL_M_Write => fsl_l1_to_mpe_FSL_M_Write,
      FSL_M_Full => fsl_l1_to_mpe_FSL_M_Full,
      FSL_S_Clk => net_gnd0,
      FSL_S_Data => fsl_l1_to_mpe_FSL_S_Data,
      FSL_S_Control => fsl_l1_to_mpe_FSL_S_Control,
      FSL_S_Read => fsl_l1_to_mpe_FSL_S_Read,
      FSL_S_Exists => fsl_l1_to_mpe_FSL_S_Exists,
      FSL_Full => open,
      FSL_Has_Data => open,
      FSL_Control_IRQ => open
    );

  fsl_mpeCmd_to_vacc : fsl_mpecmd_to_vacc_wrapper
    port map (
      FSL_Clk => sys_clk_133mhz,
      SYS_Rst => sys_rst_133mhz,
      FSL_Rst => open,
      FSL_M_Clk => net_gnd0,
      FSL_M_Data => fsl_mpecmd_to_vacc_FSL_M_Data,
      FSL_M_Control => fsl_mpecmd_to_vacc_FSL_M_Control,
      FSL_M_Write => fsl_mpecmd_to_vacc_FSL_M_Write,
      FSL_M_Full => fsl_mpecmd_to_vacc_FSL_M_Full,
      FSL_S_Clk => net_gnd0,
      FSL_S_Data => fsl_mpecmd_to_vacc_FSL_S_Data,
      FSL_S_Control => fsl_mpecmd_to_vacc_FSL_S_Control,
      FSL_S_Read => fsl_mpecmd_to_vacc_FSL_S_Read,
      FSL_S_Exists => fsl_mpecmd_to_vacc_FSL_S_Exists,
      FSL_Full => open,
      FSL_Has_Data => open,
      FSL_Control_IRQ => open
    );

  fsl_vacc_to_mpeCmd : fsl_vacc_to_mpecmd_wrapper
    port map (
      FSL_Clk => sys_clk_133mhz,
      SYS_Rst => sys_rst_133mhz,
      FSL_Rst => open,
      FSL_M_Clk => net_gnd0,
      FSL_M_Data => fsl_vacc_to_mpecmd_FSL_M_Data,
      FSL_M_Control => fsl_vacc_to_mpecmd_FSL_M_Control,
      FSL_M_Write => fsl_vacc_to_mpecmd_FSL_M_Write,
      FSL_M_Full => fsl_vacc_to_mpecmd_FSL_M_Full,
      FSL_S_Clk => net_gnd0,
      FSL_S_Data => fsl_vacc_to_mpecmd_FSL_S_Data,
      FSL_S_Control => fsl_vacc_to_mpecmd_FSL_S_Control,
      FSL_S_Read => fsl_vacc_to_mpecmd_FSL_S_Read,
      FSL_S_Exists => fsl_vacc_to_mpecmd_FSL_S_Exists,
      FSL_Full => open,
      FSL_Has_Data => open,
      FSL_Control_IRQ => open
    );

  fsl_mpeData_to_vacc : fsl_mpedata_to_vacc_wrapper
    port map (
      FSL_Clk => sys_clk_133mhz,
      SYS_Rst => sys_rst_133mhz,
      FSL_Rst => open,
      FSL_M_Clk => net_gnd0,
      FSL_M_Data => fsl_mpedata_to_vacc_FSL_M_Data,
      FSL_M_Control => fsl_mpedata_to_vacc_FSL_M_Control,
      FSL_M_Write => fsl_mpedata_to_vacc_FSL_M_Write,
      FSL_M_Full => fsl_mpedata_to_vacc_FSL_M_Full,
      FSL_S_Clk => net_gnd0,
      FSL_S_Data => fsl_mpedata_to_vacc_FSL_S_Data,
      FSL_S_Control => fsl_mpedata_to_vacc_FSL_S_Control,
      FSL_S_Read => fsl_mpedata_to_vacc_FSL_S_Read,
      FSL_S_Exists => fsl_mpedata_to_vacc_FSL_S_Exists,
      FSL_Full => open,
      FSL_Has_Data => open,
      FSL_Control_IRQ => open
    );

  fsl_vacc_to_mpeData : fsl_vacc_to_mpedata_wrapper
    port map (
      FSL_Clk => sys_clk_133mhz,
      SYS_Rst => sys_rst_133mhz,
      FSL_Rst => open,
      FSL_M_Clk => net_gnd0,
      FSL_M_Data => fsl_vacc_to_mpedata_FSL_M_Data,
      FSL_M_Control => fsl_vacc_to_mpedata_FSL_M_Control,
      FSL_M_Write => fsl_vacc_to_mpedata_FSL_M_Write,
      FSL_M_Full => fsl_vacc_to_mpedata_FSL_M_Full,
      FSL_S_Clk => net_gnd0,
      FSL_S_Data => fsl_vacc_to_mpedata_FSL_S_Data,
      FSL_S_Control => fsl_vacc_to_mpedata_FSL_S_Control,
      FSL_S_Read => fsl_vacc_to_mpedata_FSL_S_Read,
      FSL_S_Exists => fsl_vacc_to_mpedata_FSL_S_Exists,
      FSL_Full => open,
      FSL_Has_Data => open,
      FSL_Control_IRQ => open
    );

  mb_mba : mb_mba_wrapper
    port map (
      CLK => sys_clk_133mhz,
      RESET => dlmb_mba_OPB_Rst,
      MB_RESET => mba_rst_133mhz,
      INTERRUPT => net_gnd0,
      EXT_BRK => Ext_BRK,
      EXT_NM_BRK => Ext_NM_BRK,
      DBG_STOP => net_gnd0,
      MB_Halted => open,
      INSTR => ilmb_mba_LMB_ReadDBus,
      I_ADDRTAG => open,
      IREADY => ilmb_mba_LMB_Ready,
      IWAIT => net_gnd0,
      INSTR_ADDR => ilmb_mba_M_ABus,
      IFETCH => ilmb_mba_M_ReadStrobe,
      I_AS => ilmb_mba_M_AddrStrobe,
      IPLB_M_ABort => plb_bus_mba_M_ABort(1),
      IPLB_M_ABus => plb_bus_mba_M_ABus(32 to 63),
      IPLB_M_UABus => plb_bus_mba_M_UABus(32 to 63),
      IPLB_M_BE => plb_bus_mba_M_BE(4 to 7),
      IPLB_M_busLock => plb_bus_mba_M_busLock(1),
      IPLB_M_lockErr => plb_bus_mba_M_lockErr(1),
      IPLB_M_MSize => plb_bus_mba_M_MSize(2 to 3),
      IPLB_M_priority => plb_bus_mba_M_priority(2 to 3),
      IPLB_M_rdBurst => plb_bus_mba_M_rdBurst(1),
      IPLB_M_request => plb_bus_mba_M_request(1),
      IPLB_M_RNW => plb_bus_mba_M_RNW(1),
      IPLB_M_size => plb_bus_mba_M_size(4 to 7),
      IPLB_M_TAttribute => plb_bus_mba_M_TAttribute(16 to 31),
      IPLB_M_type => plb_bus_mba_M_type(3 to 5),
      IPLB_M_wrBurst => plb_bus_mba_M_wrBurst(1),
      IPLB_M_wrDBus => plb_bus_mba_M_wrDBus(32 to 63),
      IPLB_MBusy => plb_bus_mba_PLB_MBusy(1),
      IPLB_MRdErr => plb_bus_mba_PLB_MRdErr(1),
      IPLB_MWrErr => plb_bus_mba_PLB_MWrErr(1),
      IPLB_MIRQ => plb_bus_mba_PLB_MIRQ(1),
      IPLB_MWrBTerm => plb_bus_mba_PLB_MWrBTerm(1),
      IPLB_MWrDAck => plb_bus_mba_PLB_MWrDAck(1),
      IPLB_MAddrAck => plb_bus_mba_PLB_MAddrAck(1),
      IPLB_MMRdBTerm => net_gnd0,
      IPLB_MRdDAck => plb_bus_mba_PLB_MRdDAck(1),
      IPLB_MRdDBus => plb_bus_mba_PLB_MRdDBus(32 to 63),
      IPLB_MRdWdAddr => plb_bus_mba_PLB_MRdWdAddr(4 to 7),
      IPLB_MRearbitrate => plb_bus_mba_PLB_MRearbitrate(1),
      IPLB_MSSize => plb_bus_mba_PLB_MSSize(2 to 3),
      IPLB_MTimeout => plb_bus_mba_PLB_MTimeout(1),
      DATA_READ => dlmb_mba_LMB_ReadDBus,
      DREADY => dlmb_mba_LMB_Ready,
      DWAIT => net_gnd0,
      DATA_WRITE => dlmb_mba_M_DBus,
      DATA_ADDR => dlmb_mba_M_ABus,
      D_ADDRTAG => open,
      D_AS => dlmb_mba_M_AddrStrobe,
      READ_STROBE => dlmb_mba_M_ReadStrobe,
      WRITE_STROBE => dlmb_mba_M_WriteStrobe,
      BYTE_ENABLE => dlmb_mba_M_BE,
      DM_ABUS => open,
      DM_BE => open,
      DM_BUSLOCK => open,
      DM_DBUS => open,
      DM_REQUEST => open,
      DM_RNW => open,
      DM_SELECT => open,
      DM_SEQADDR => open,
      DOPB_DBUS => net_gnd32,
      DOPB_ERRACK => net_gnd0,
      DOPB_MGRANT => net_gnd0,
      DOPB_RETRY => net_gnd0,
      DOPB_TIMEOUT => net_gnd0,
      DOPB_XFERACK => net_gnd0,
      DPLB_M_ABort => plb_bus_mba_M_ABort(0),
      DPLB_M_ABus => plb_bus_mba_M_ABus(0 to 31),
      DPLB_M_UABus => plb_bus_mba_M_UABus(0 to 31),
      DPLB_M_BE => plb_bus_mba_M_BE(0 to 3),
      DPLB_M_busLock => plb_bus_mba_M_busLock(0),
      DPLB_M_lockErr => plb_bus_mba_M_lockErr(0),
      DPLB_M_MSize => plb_bus_mba_M_MSize(0 to 1),
      DPLB_M_priority => plb_bus_mba_M_priority(0 to 1),
      DPLB_M_rdBurst => plb_bus_mba_M_rdBurst(0),
      DPLB_M_request => plb_bus_mba_M_request(0),
      DPLB_M_RNW => plb_bus_mba_M_RNW(0),
      DPLB_M_size => plb_bus_mba_M_size(0 to 3),
      DPLB_M_TAttribute => plb_bus_mba_M_TAttribute(0 to 15),
      DPLB_M_type => plb_bus_mba_M_type(0 to 2),
      DPLB_M_wrBurst => plb_bus_mba_M_wrBurst(0),
      DPLB_M_wrDBus => plb_bus_mba_M_wrDBus(0 to 31),
      DPLB_MBusy => plb_bus_mba_PLB_MBusy(0),
      DPLB_MRdErr => plb_bus_mba_PLB_MRdErr(0),
      DPLB_MWrErr => plb_bus_mba_PLB_MWrErr(0),
      DPLB_MIRQ => plb_bus_mba_PLB_MIRQ(0),
      DPLB_MWrBTerm => plb_bus_mba_PLB_MWrBTerm(0),
      DPLB_MWrDAck => plb_bus_mba_PLB_MWrDAck(0),
      DPLB_MAddrAck => plb_bus_mba_PLB_MAddrAck(0),
      DPLB_MMRdBTerm => net_gnd0,
      DPLB_MRdDAck => plb_bus_mba_PLB_MRdDAck(0),
      DPLB_MRdDBus => plb_bus_mba_PLB_MRdDBus(0 to 31),
      DPLB_MRdWdAddr => plb_bus_mba_PLB_MRdWdAddr(0 to 3),
      DPLB_MRearbitrate => plb_bus_mba_PLB_MRearbitrate(0),
      DPLB_MSSize => plb_bus_mba_PLB_MSSize(0 to 1),
      DPLB_MTimeout => plb_bus_mba_PLB_MTimeout(0),
      IM_ABUS => open,
      IM_BE => open,
      IM_BUSLOCK => open,
      IM_DBUS => open,
      IM_REQUEST => open,
      IM_RNW => open,
      IM_SELECT => open,
      IM_SEQADDR => open,
      IOPB_DBUS => net_gnd32,
      IOPB_ERRACK => net_gnd0,
      IOPB_MGRANT => net_gnd0,
      IOPB_RETRY => net_gnd0,
      IOPB_TIMEOUT => net_gnd0,
      IOPB_XFERACK => net_gnd0,
      DBG_CLK => net_gnd0,
      DBG_TDI => net_gnd0,
      DBG_TDO => open,
      DBG_REG_EN => net_gnd5,
      DBG_SHIFT => net_gnd0,
      DBG_CAPTURE => net_gnd0,
      DBG_UPDATE => net_gnd0,
      DEBUG_RST => net_gnd0,
      Trace_Instruction => open,
      Trace_Valid_Instr => open,
      Trace_PC => open,
      Trace_Reg_Write => open,
      Trace_Reg_Addr => open,
      Trace_MSR_Reg => open,
      Trace_PID_Reg => open,
      Trace_New_Reg_Value => open,
      Trace_Exception_Taken => open,
      Trace_Exception_Kind => open,
      Trace_Jump_Taken => open,
      Trace_Delay_Slot => open,
      Trace_Data_Address => open,
      Trace_Data_Access => open,
      Trace_Data_Read => open,
      Trace_Data_Write => open,
      Trace_Data_Write_Value => open,
      Trace_Data_Byte_Enable => open,
      Trace_DCache_Req => open,
      Trace_DCache_Hit => open,
      Trace_ICache_Req => open,
      Trace_ICache_Hit => open,
      Trace_OF_PipeRun => open,
      Trace_EX_PipeRun => open,
      Trace_MEM_PipeRun => open,
      Trace_MB_Halted => open,
      FSL0_S_CLK => open,
      FSL0_S_READ => open,
      FSL0_S_DATA => net_gnd32,
      FSL0_S_CONTROL => net_gnd0,
      FSL0_S_EXISTS => net_gnd0,
      FSL0_M_CLK => open,
      FSL0_M_WRITE => open,
      FSL0_M_DATA => open,
      FSL0_M_CONTROL => open,
      FSL0_M_FULL => net_gnd0,
      FSL1_S_CLK => open,
      FSL1_S_READ => open,
      FSL1_S_DATA => net_gnd32,
      FSL1_S_CONTROL => net_gnd0,
      FSL1_S_EXISTS => net_gnd0,
      FSL1_M_CLK => open,
      FSL1_M_WRITE => open,
      FSL1_M_DATA => open,
      FSL1_M_CONTROL => open,
      FSL1_M_FULL => net_gnd0,
      FSL2_S_CLK => open,
      FSL2_S_READ => open,
      FSL2_S_DATA => net_gnd32,
      FSL2_S_CONTROL => net_gnd0,
      FSL2_S_EXISTS => net_gnd0,
      FSL2_M_CLK => open,
      FSL2_M_WRITE => open,
      FSL2_M_DATA => open,
      FSL2_M_CONTROL => open,
      FSL2_M_FULL => net_gnd0,
      FSL3_S_CLK => open,
      FSL3_S_READ => open,
      FSL3_S_DATA => net_gnd32,
      FSL3_S_CONTROL => net_gnd0,
      FSL3_S_EXISTS => net_gnd0,
      FSL3_M_CLK => open,
      FSL3_M_WRITE => open,
      FSL3_M_DATA => open,
      FSL3_M_CONTROL => open,
      FSL3_M_FULL => net_gnd0,
      FSL4_S_CLK => open,
      FSL4_S_READ => open,
      FSL4_S_DATA => net_gnd32,
      FSL4_S_CONTROL => net_gnd0,
      FSL4_S_EXISTS => net_gnd0,
      FSL4_M_CLK => open,
      FSL4_M_WRITE => open,
      FSL4_M_DATA => open,
      FSL4_M_CONTROL => open,
      FSL4_M_FULL => net_gnd0,
      FSL5_S_CLK => open,
      FSL5_S_READ => open,
      FSL5_S_DATA => net_gnd32,
      FSL5_S_CONTROL => net_gnd0,
      FSL5_S_EXISTS => net_gnd0,
      FSL5_M_CLK => open,
      FSL5_M_WRITE => open,
      FSL5_M_DATA => open,
      FSL5_M_CONTROL => open,
      FSL5_M_FULL => net_gnd0,
      FSL6_S_CLK => open,
      FSL6_S_READ => open,
      FSL6_S_DATA => net_gnd32,
      FSL6_S_CONTROL => net_gnd0,
      FSL6_S_EXISTS => net_gnd0,
      FSL6_M_CLK => open,
      FSL6_M_WRITE => open,
      FSL6_M_DATA => open,
      FSL6_M_CONTROL => open,
      FSL6_M_FULL => net_gnd0,
      FSL7_S_CLK => open,
      FSL7_S_READ => open,
      FSL7_S_DATA => net_gnd32,
      FSL7_S_CONTROL => net_gnd0,
      FSL7_S_EXISTS => net_gnd0,
      FSL7_M_CLK => open,
      FSL7_M_WRITE => open,
      FSL7_M_DATA => open,
      FSL7_M_CONTROL => open,
      FSL7_M_FULL => net_gnd0,
      FSL8_S_CLK => open,
      FSL8_S_READ => open,
      FSL8_S_DATA => net_gnd32,
      FSL8_S_CONTROL => net_gnd0,
      FSL8_S_EXISTS => net_gnd0,
      FSL8_M_CLK => open,
      FSL8_M_WRITE => open,
      FSL8_M_DATA => open,
      FSL8_M_CONTROL => open,
      FSL8_M_FULL => net_gnd0,
      FSL9_S_CLK => open,
      FSL9_S_READ => open,
      FSL9_S_DATA => net_gnd32,
      FSL9_S_CONTROL => net_gnd0,
      FSL9_S_EXISTS => net_gnd0,
      FSL9_M_CLK => open,
      FSL9_M_WRITE => open,
      FSL9_M_DATA => open,
      FSL9_M_CONTROL => open,
      FSL9_M_FULL => net_gnd0,
      FSL10_S_CLK => open,
      FSL10_S_READ => open,
      FSL10_S_DATA => net_gnd32,
      FSL10_S_CONTROL => net_gnd0,
      FSL10_S_EXISTS => net_gnd0,
      FSL10_M_CLK => open,
      FSL10_M_WRITE => open,
      FSL10_M_DATA => open,
      FSL10_M_CONTROL => open,
      FSL10_M_FULL => net_gnd0,
      FSL11_S_CLK => open,
      FSL11_S_READ => open,
      FSL11_S_DATA => net_gnd32,
      FSL11_S_CONTROL => net_gnd0,
      FSL11_S_EXISTS => net_gnd0,
      FSL11_M_CLK => open,
      FSL11_M_WRITE => open,
      FSL11_M_DATA => open,
      FSL11_M_CONTROL => open,
      FSL11_M_FULL => net_gnd0,
      FSL12_S_CLK => open,
      FSL12_S_READ => open,
      FSL12_S_DATA => net_gnd32,
      FSL12_S_CONTROL => net_gnd0,
      FSL12_S_EXISTS => net_gnd0,
      FSL12_M_CLK => open,
      FSL12_M_WRITE => open,
      FSL12_M_DATA => open,
      FSL12_M_CONTROL => open,
      FSL12_M_FULL => net_gnd0,
      FSL13_S_CLK => open,
      FSL13_S_READ => open,
      FSL13_S_DATA => net_gnd32,
      FSL13_S_CONTROL => net_gnd0,
      FSL13_S_EXISTS => net_gnd0,
      FSL13_M_CLK => open,
      FSL13_M_WRITE => open,
      FSL13_M_DATA => open,
      FSL13_M_CONTROL => open,
      FSL13_M_FULL => net_gnd0,
      FSL14_S_CLK => open,
      FSL14_S_READ => open,
      FSL14_S_DATA => net_gnd32,
      FSL14_S_CONTROL => net_gnd0,
      FSL14_S_EXISTS => net_gnd0,
      FSL14_M_CLK => open,
      FSL14_M_WRITE => open,
      FSL14_M_DATA => open,
      FSL14_M_CONTROL => open,
      FSL14_M_FULL => net_gnd0,
      FSL15_S_CLK => open,
      FSL15_S_READ => open,
      FSL15_S_DATA => net_gnd32,
      FSL15_S_CONTROL => net_gnd0,
      FSL15_S_EXISTS => net_gnd0,
      FSL15_M_CLK => open,
      FSL15_M_WRITE => open,
      FSL15_M_DATA => open,
      FSL15_M_CONTROL => open,
      FSL15_M_FULL => net_gnd0,
      ICACHE_FSL_IN_CLK => open,
      ICACHE_FSL_IN_READ => open,
      ICACHE_FSL_IN_DATA => net_gnd32,
      ICACHE_FSL_IN_CONTROL => net_gnd0,
      ICACHE_FSL_IN_EXISTS => net_gnd0,
      ICACHE_FSL_OUT_CLK => open,
      ICACHE_FSL_OUT_WRITE => open,
      ICACHE_FSL_OUT_DATA => open,
      ICACHE_FSL_OUT_CONTROL => open,
      ICACHE_FSL_OUT_FULL => net_gnd0,
      DCACHE_FSL_IN_CLK => open,
      DCACHE_FSL_IN_READ => open,
      DCACHE_FSL_IN_DATA => net_gnd32,
      DCACHE_FSL_IN_CONTROL => net_gnd0,
      DCACHE_FSL_IN_EXISTS => net_gnd0,
      DCACHE_FSL_OUT_CLK => open,
      DCACHE_FSL_OUT_WRITE => open,
      DCACHE_FSL_OUT_DATA => open,
      DCACHE_FSL_OUT_CONTROL => open,
      DCACHE_FSL_OUT_FULL => net_gnd0
    );

  plb_bus_mba : plb_bus_mba_wrapper
    port map (
      PLB_Clk => sys_clk_133mhz,
      SYS_Rst => plb_rst_133mhz(0),
      PLB_Rst => open,
      SPLB_Rst => plb_bus_mba_SPLB_Rst,
      MPLB_Rst => open,
      PLB_dcrAck => open,
      PLB_dcrDBus => open,
      DCR_ABus => net_gnd10,
      DCR_DBus => net_gnd32,
      DCR_Read => net_gnd0,
      DCR_Write => net_gnd0,
      M_ABus => plb_bus_mba_M_ABus,
      M_UABus => plb_bus_mba_M_UABus,
      M_BE => plb_bus_mba_M_BE,
      M_RNW => plb_bus_mba_M_RNW,
      M_abort => plb_bus_mba_M_ABort,
      M_busLock => plb_bus_mba_M_busLock,
      M_TAttribute => plb_bus_mba_M_TAttribute,
      M_lockErr => plb_bus_mba_M_lockErr,
      M_MSize => plb_bus_mba_M_MSize,
      M_priority => plb_bus_mba_M_priority,
      M_rdBurst => plb_bus_mba_M_rdBurst,
      M_request => plb_bus_mba_M_request,
      M_size => plb_bus_mba_M_size,
      M_type => plb_bus_mba_M_type,
      M_wrBurst => plb_bus_mba_M_wrBurst,
      M_wrDBus => plb_bus_mba_M_wrDBus,
      Sl_addrAck => plb_bus_mba_Sl_addrAck,
      Sl_MRdErr => plb_bus_mba_Sl_MRdErr,
      Sl_MWrErr => plb_bus_mba_Sl_MWrErr,
      Sl_MBusy => plb_bus_mba_Sl_MBusy,
      Sl_rdBTerm => plb_bus_mba_Sl_rdBTerm,
      Sl_rdComp => plb_bus_mba_Sl_rdComp,
      Sl_rdDAck => plb_bus_mba_Sl_rdDAck,
      Sl_rdDBus => plb_bus_mba_Sl_rdDBus,
      Sl_rdWdAddr => plb_bus_mba_Sl_rdWdAddr,
      Sl_rearbitrate => plb_bus_mba_Sl_rearbitrate,
      Sl_SSize => plb_bus_mba_Sl_SSize,
      Sl_wait => plb_bus_mba_Sl_wait,
      Sl_wrBTerm => plb_bus_mba_Sl_wrBTerm,
      Sl_wrComp => plb_bus_mba_Sl_wrComp,
      Sl_wrDAck => plb_bus_mba_Sl_wrDAck,
      Sl_MIRQ => plb_bus_mba_Sl_MIRQ,
      PLB_MIRQ => plb_bus_mba_PLB_MIRQ,
      PLB_ABus => plb_bus_mba_PLB_ABus,
      PLB_UABus => plb_bus_mba_PLB_UABus,
      PLB_BE => plb_bus_mba_PLB_BE,
      PLB_MAddrAck => plb_bus_mba_PLB_MAddrAck,
      PLB_MTimeout => plb_bus_mba_PLB_MTimeout,
      PLB_MBusy => plb_bus_mba_PLB_MBusy,
      PLB_MRdErr => plb_bus_mba_PLB_MRdErr,
      PLB_MWrErr => plb_bus_mba_PLB_MWrErr,
      PLB_MRdBTerm => open,
      PLB_MRdDAck => plb_bus_mba_PLB_MRdDAck,
      PLB_MRdDBus => plb_bus_mba_PLB_MRdDBus,
      PLB_MRdWdAddr => plb_bus_mba_PLB_MRdWdAddr,
      PLB_MRearbitrate => plb_bus_mba_PLB_MRearbitrate,
      PLB_MWrBTerm => plb_bus_mba_PLB_MWrBTerm,
      PLB_MWrDAck => plb_bus_mba_PLB_MWrDAck,
      PLB_MSSize => plb_bus_mba_PLB_MSSize,
      PLB_PAValid => plb_bus_mba_PLB_PAValid,
      PLB_RNW => plb_bus_mba_PLB_RNW,
      PLB_SAValid => plb_bus_mba_PLB_SAValid,
      PLB_abort => plb_bus_mba_PLB_abort,
      PLB_busLock => plb_bus_mba_PLB_busLock,
      PLB_TAttribute => plb_bus_mba_PLB_TAttribute,
      PLB_lockErr => plb_bus_mba_PLB_lockErr,
      PLB_masterID => plb_bus_mba_PLB_masterID(0 to 0),
      PLB_MSize => plb_bus_mba_PLB_MSize,
      PLB_rdPendPri => plb_bus_mba_PLB_rdPendPri,
      PLB_wrPendPri => plb_bus_mba_PLB_wrPendPri,
      PLB_rdPendReq => plb_bus_mba_PLB_rdPendReq,
      PLB_wrPendReq => plb_bus_mba_PLB_wrPendReq,
      PLB_rdBurst => plb_bus_mba_PLB_rdBurst,
      PLB_rdPrim => plb_bus_mba_PLB_rdPrim,
      PLB_reqPri => plb_bus_mba_PLB_reqPri,
      PLB_size => plb_bus_mba_PLB_size,
      PLB_type => plb_bus_mba_PLB_type,
      PLB_wrBurst => plb_bus_mba_PLB_wrBurst,
      PLB_wrDBus => plb_bus_mba_PLB_wrDBus,
      PLB_wrPrim => plb_bus_mba_PLB_wrPrim,
      PLB_SaddrAck => open,
      PLB_SMRdErr => open,
      PLB_SMWrErr => open,
      PLB_SMBusy => open,
      PLB_SrdBTerm => open,
      PLB_SrdComp => open,
      PLB_SrdDAck => open,
      PLB_SrdDBus => open,
      PLB_SrdWdAddr => open,
      PLB_Srearbitrate => open,
      PLB_Sssize => open,
      PLB_Swait => open,
      PLB_SwrBTerm => open,
      PLB_SwrComp => open,
      PLB_SwrDAck => open,
      PLB2OPB_rearb => net_gnd2,
      Bus_Error_Det => open
    );

  ilmb_mba : ilmb_mba_wrapper
    port map (
      LMB_Clk => sys_clk_133mhz,
      SYS_Rst => plb_rst_133mhz(0),
      LMB_Rst => ilmb_mba_OPB_Rst,
      M_ABus => ilmb_mba_M_ABus,
      M_ReadStrobe => ilmb_mba_M_ReadStrobe,
      M_WriteStrobe => net_gnd0,
      M_AddrStrobe => ilmb_mba_M_AddrStrobe,
      M_DBus => net_gnd32,
      M_BE => net_gnd4,
      Sl_DBus => ilmb_mba_Sl_DBus,
      Sl_Ready => ilmb_mba_Sl_Ready(0 to 0),
      LMB_ABus => ilmb_mba_LMB_ABus,
      LMB_ReadStrobe => ilmb_mba_LMB_ReadStrobe,
      LMB_WriteStrobe => ilmb_mba_LMB_WriteStrobe,
      LMB_AddrStrobe => ilmb_mba_LMB_AddrStrobe,
      LMB_ReadDBus => ilmb_mba_LMB_ReadDBus,
      LMB_WriteDBus => ilmb_mba_LMB_WriteDBus,
      LMB_Ready => ilmb_mba_LMB_Ready,
      LMB_BE => ilmb_mba_LMB_BE
    );

  dlmb_mba : dlmb_mba_wrapper
    port map (
      LMB_Clk => sys_clk_133mhz,
      SYS_Rst => plb_rst_133mhz(0),
      LMB_Rst => dlmb_mba_OPB_Rst,
      M_ABus => dlmb_mba_M_ABus,
      M_ReadStrobe => dlmb_mba_M_ReadStrobe,
      M_WriteStrobe => dlmb_mba_M_WriteStrobe,
      M_AddrStrobe => dlmb_mba_M_AddrStrobe,
      M_DBus => dlmb_mba_M_DBus,
      M_BE => dlmb_mba_M_BE,
      Sl_DBus => dlmb_mba_Sl_DBus,
      Sl_Ready => dlmb_mba_Sl_Ready(0 to 0),
      LMB_ABus => dlmb_mba_LMB_ABus,
      LMB_ReadStrobe => dlmb_mba_LMB_ReadStrobe,
      LMB_WriteStrobe => dlmb_mba_LMB_WriteStrobe,
      LMB_AddrStrobe => dlmb_mba_LMB_AddrStrobe,
      LMB_ReadDBus => dlmb_mba_LMB_ReadDBus,
      LMB_WriteDBus => dlmb_mba_LMB_WriteDBus,
      LMB_Ready => dlmb_mba_LMB_Ready,
      LMB_BE => dlmb_mba_LMB_BE
    );

  dlmb_cntlr_mba : dlmb_cntlr_mba_wrapper
    port map (
      LMB_Clk => sys_clk_133mhz,
      LMB_Rst => dlmb_mba_OPB_Rst,
      LMB_ABus => dlmb_mba_LMB_ABus,
      LMB_WriteDBus => dlmb_mba_LMB_WriteDBus,
      LMB_AddrStrobe => dlmb_mba_LMB_AddrStrobe,
      LMB_ReadStrobe => dlmb_mba_LMB_ReadStrobe,
      LMB_WriteStrobe => dlmb_mba_LMB_WriteStrobe,
      LMB_BE => dlmb_mba_LMB_BE,
      Sl_DBus => dlmb_mba_Sl_DBus,
      Sl_Ready => dlmb_mba_Sl_Ready(0),
      BRAM_Rst_A => dlmb_port_mba_BRAM_Rst,
      BRAM_Clk_A => open,
      BRAM_EN_A => dlmb_port_mba_BRAM_EN,
      BRAM_WEN_A => dlmb_port_mba_BRAM_WEN,
      BRAM_Addr_A => dlmb_port_mba_BRAM_Addr,
      BRAM_Din_A => dlmb_port_mba_BRAM_Din,
      BRAM_Dout_A => dlmb_port_mba_BRAM_Dout
    );

  ilmb_cntlr_mba : ilmb_cntlr_mba_wrapper
    port map (
      LMB_Clk => sys_clk_133mhz,
      LMB_Rst => ilmb_mba_OPB_Rst,
      LMB_ABus => ilmb_mba_LMB_ABus,
      LMB_WriteDBus => ilmb_mba_LMB_WriteDBus,
      LMB_AddrStrobe => ilmb_mba_LMB_AddrStrobe,
      LMB_ReadStrobe => ilmb_mba_LMB_ReadStrobe,
      LMB_WriteStrobe => ilmb_mba_LMB_WriteStrobe,
      LMB_BE => ilmb_mba_LMB_BE,
      Sl_DBus => ilmb_mba_Sl_DBus,
      Sl_Ready => ilmb_mba_Sl_Ready(0),
      BRAM_Rst_A => ilmb_port_mba_BRAM_Rst,
      BRAM_Clk_A => open,
      BRAM_EN_A => ilmb_port_mba_BRAM_EN,
      BRAM_WEN_A => ilmb_port_mba_BRAM_WEN,
      BRAM_Addr_A => ilmb_port_mba_BRAM_Addr,
      BRAM_Din_A => ilmb_port_mba_BRAM_Din,
      BRAM_Dout_A => ilmb_port_mba_BRAM_Dout
    );

  lmb_bram_mba : lmb_bram_mba_wrapper
    port map (
      BRAM_Rst_A => ilmb_port_mba_BRAM_Rst,
      BRAM_Clk_A => sys_clk_133mhz,
      BRAM_EN_A => ilmb_port_mba_BRAM_EN,
      BRAM_WEN_A => ilmb_port_mba_BRAM_WEN,
      BRAM_Addr_A => ilmb_port_mba_BRAM_Addr,
      BRAM_Din_A => ilmb_port_mba_BRAM_Din,
      BRAM_Dout_A => ilmb_port_mba_BRAM_Dout,
      BRAM_Rst_B => dlmb_port_mba_BRAM_Rst,
      BRAM_Clk_B => sys_clk_133mhz,
      BRAM_EN_B => dlmb_port_mba_BRAM_EN,
      BRAM_WEN_B => dlmb_port_mba_BRAM_WEN,
      BRAM_Addr_B => dlmb_port_mba_BRAM_Addr,
      BRAM_Din_B => dlmb_port_mba_BRAM_Din,
      BRAM_Dout_B => dlmb_port_mba_BRAM_Dout
    );

  plb_gpio_monitor_mba : plb_gpio_monitor_mba_wrapper
    port map (
      SPLB_Clk => sys_clk_133mhz,
      SPLB_Rst => plb_bus_mba_SPLB_Rst(0),
      PLB_ABus => plb_bus_mba_PLB_ABus,
      PLB_UABus => plb_bus_mba_PLB_UABus,
      PLB_PAValid => plb_bus_mba_PLB_PAValid,
      PLB_SAValid => plb_bus_mba_PLB_SAValid,
      PLB_rdPrim => plb_bus_mba_PLB_rdPrim(0),
      PLB_wrPrim => plb_bus_mba_PLB_wrPrim(0),
      PLB_masterID => plb_bus_mba_PLB_masterID(0 to 0),
      PLB_abort => plb_bus_mba_PLB_abort,
      PLB_busLock => plb_bus_mba_PLB_busLock,
      PLB_RNW => plb_bus_mba_PLB_RNW,
      PLB_BE => plb_bus_mba_PLB_BE,
      PLB_MSize => plb_bus_mba_PLB_MSize,
      PLB_size => plb_bus_mba_PLB_size,
      PLB_type => plb_bus_mba_PLB_type,
      PLB_lockErr => plb_bus_mba_PLB_lockErr,
      PLB_wrDBus => plb_bus_mba_PLB_wrDBus,
      PLB_wrBurst => plb_bus_mba_PLB_wrBurst,
      PLB_rdBurst => plb_bus_mba_PLB_rdBurst,
      PLB_wrPendReq => plb_bus_mba_PLB_wrPendReq,
      PLB_rdPendReq => plb_bus_mba_PLB_rdPendReq,
      PLB_wrPendPri => plb_bus_mba_PLB_wrPendPri,
      PLB_rdPendPri => plb_bus_mba_PLB_rdPendPri,
      PLB_reqPri => plb_bus_mba_PLB_reqPri,
      PLB_TAttribute => plb_bus_mba_PLB_TAttribute,
      Sl_addrAck => plb_bus_mba_Sl_addrAck(0),
      Sl_SSize => plb_bus_mba_Sl_SSize(0 to 1),
      Sl_wait => plb_bus_mba_Sl_wait(0),
      Sl_rearbitrate => plb_bus_mba_Sl_rearbitrate(0),
      Sl_wrDAck => plb_bus_mba_Sl_wrDAck(0),
      Sl_wrComp => plb_bus_mba_Sl_wrComp(0),
      Sl_wrBTerm => plb_bus_mba_Sl_wrBTerm(0),
      Sl_rdDBus => plb_bus_mba_Sl_rdDBus(0 to 31),
      Sl_rdWdAddr => plb_bus_mba_Sl_rdWdAddr(0 to 3),
      Sl_rdDAck => plb_bus_mba_Sl_rdDAck(0),
      Sl_rdComp => plb_bus_mba_Sl_rdComp(0),
      Sl_rdBTerm => plb_bus_mba_Sl_rdBTerm(0),
      Sl_MBusy => plb_bus_mba_Sl_MBusy(0 to 1),
      Sl_MWrErr => plb_bus_mba_Sl_MWrErr(0 to 1),
      Sl_MRdErr => plb_bus_mba_Sl_MRdErr(0 to 1),
      Sl_MIRQ => plb_bus_mba_Sl_MIRQ(0 to 1),
      IP2INTC_Irpt => open,
      GPIO_IO_I => net_gnd17,
      GPIO_IO_O => open,
      GPIO_IO_T => open,
      GPIO_in => pgassign2,
      GPIO_d_out => open,
      GPIO_t_out => open,
      GPIO2_IO_I => net_gnd17,
      GPIO2_IO_O => open,
      GPIO2_IO_T => open,
      GPIO2_in => net_gnd17,
      GPIO2_d_out => open,
      GPIO2_t_out => open
    );

  plb_mdm_mba : plb_mdm_mba_wrapper
    port map (
      Interrupt => open,
      Debug_SYS_Rst => mdm_dbgrst_mba,
      Ext_BRK => Ext_BRK,
      Ext_NM_BRK => Ext_NM_BRK,
      SPLB_Clk => sys_clk_133mhz,
      SPLB_Rst => plb_bus_mba_SPLB_Rst(1),
      PLB_ABus => plb_bus_mba_PLB_ABus,
      PLB_UABus => plb_bus_mba_PLB_UABus,
      PLB_PAValid => plb_bus_mba_PLB_PAValid,
      PLB_SAValid => plb_bus_mba_PLB_SAValid,
      PLB_rdPrim => plb_bus_mba_PLB_rdPrim(1),
      PLB_wrPrim => plb_bus_mba_PLB_wrPrim(1),
      PLB_masterID => plb_bus_mba_PLB_masterID(0 to 0),
      PLB_abort => plb_bus_mba_PLB_abort,
      PLB_busLock => plb_bus_mba_PLB_busLock,
      PLB_RNW => plb_bus_mba_PLB_RNW,
      PLB_BE => plb_bus_mba_PLB_BE,
      PLB_MSize => plb_bus_mba_PLB_MSize,
      PLB_size => plb_bus_mba_PLB_size,
      PLB_type => plb_bus_mba_PLB_type,
      PLB_lockErr => plb_bus_mba_PLB_lockErr,
      PLB_wrDBus => plb_bus_mba_PLB_wrDBus,
      PLB_wrBurst => plb_bus_mba_PLB_wrBurst,
      PLB_rdBurst => plb_bus_mba_PLB_rdBurst,
      PLB_wrPendReq => plb_bus_mba_PLB_wrPendReq,
      PLB_rdPendReq => plb_bus_mba_PLB_rdPendReq,
      PLB_wrPendPri => plb_bus_mba_PLB_wrPendPri,
      PLB_rdPendPri => plb_bus_mba_PLB_rdPendPri,
      PLB_reqPri => plb_bus_mba_PLB_reqPri,
      PLB_TAttribute => plb_bus_mba_PLB_TAttribute,
      Sl_addrAck => plb_bus_mba_Sl_addrAck(1),
      Sl_SSize => plb_bus_mba_Sl_SSize(2 to 3),
      Sl_wait => plb_bus_mba_Sl_wait(1),
      Sl_rearbitrate => plb_bus_mba_Sl_rearbitrate(1),
      Sl_wrDAck => plb_bus_mba_Sl_wrDAck(1),
      Sl_wrComp => plb_bus_mba_Sl_wrComp(1),
      Sl_wrBTerm => plb_bus_mba_Sl_wrBTerm(1),
      Sl_rdDBus => plb_bus_mba_Sl_rdDBus(32 to 63),
      Sl_rdWdAddr => plb_bus_mba_Sl_rdWdAddr(4 to 7),
      Sl_rdDAck => plb_bus_mba_Sl_rdDAck(1),
      Sl_rdComp => plb_bus_mba_Sl_rdComp(1),
      Sl_rdBTerm => plb_bus_mba_Sl_rdBTerm(1),
      Sl_MBusy => plb_bus_mba_Sl_MBusy(2 to 3),
      Sl_MWrErr => plb_bus_mba_Sl_MWrErr(2 to 3),
      Sl_MRdErr => plb_bus_mba_Sl_MRdErr(2 to 3),
      Sl_MIRQ => plb_bus_mba_Sl_MIRQ(2 to 3),
      OPB_Clk => net_gnd0,
      OPB_Rst => net_gnd0,
      OPB_ABus => net_gnd32,
      OPB_BE => net_gnd4,
      OPB_RNW => net_gnd0,
      OPB_select => net_gnd0,
      OPB_seqAddr => net_gnd0,
      OPB_DBus => net_gnd32,
      MDM_DBus => open,
      MDM_errAck => open,
      MDM_retry => open,
      MDM_toutSup => open,
      MDM_xferAck => open,
      Dbg_Clk_0 => open,
      Dbg_TDI_0 => open,
      Dbg_TDO_0 => net_gnd0,
      Dbg_Reg_En_0 => open,
      Dbg_Capture_0 => open,
      Dbg_Shift_0 => open,
      Dbg_Update_0 => open,
      Dbg_Rst_0 => open,
      Dbg_Clk_1 => open,
      Dbg_TDI_1 => open,
      Dbg_TDO_1 => net_gnd0,
      Dbg_Reg_En_1 => open,
      Dbg_Capture_1 => open,
      Dbg_Shift_1 => open,
      Dbg_Update_1 => open,
      Dbg_Rst_1 => open,
      Dbg_Clk_2 => open,
      Dbg_TDI_2 => open,
      Dbg_TDO_2 => net_gnd0,
      Dbg_Reg_En_2 => open,
      Dbg_Capture_2 => open,
      Dbg_Shift_2 => open,
      Dbg_Update_2 => open,
      Dbg_Rst_2 => open,
      Dbg_Clk_3 => open,
      Dbg_TDI_3 => open,
      Dbg_TDO_3 => net_gnd0,
      Dbg_Reg_En_3 => open,
      Dbg_Capture_3 => open,
      Dbg_Shift_3 => open,
      Dbg_Update_3 => open,
      Dbg_Rst_3 => open,
      Dbg_Clk_4 => open,
      Dbg_TDI_4 => open,
      Dbg_TDO_4 => net_gnd0,
      Dbg_Reg_En_4 => open,
      Dbg_Capture_4 => open,
      Dbg_Shift_4 => open,
      Dbg_Update_4 => open,
      Dbg_Rst_4 => open,
      Dbg_Clk_5 => open,
      Dbg_TDI_5 => open,
      Dbg_TDO_5 => net_gnd0,
      Dbg_Reg_En_5 => open,
      Dbg_Capture_5 => open,
      Dbg_Shift_5 => open,
      Dbg_Update_5 => open,
      Dbg_Rst_5 => open,
      Dbg_Clk_6 => open,
      Dbg_TDI_6 => open,
      Dbg_TDO_6 => net_gnd0,
      Dbg_Reg_En_6 => open,
      Dbg_Capture_6 => open,
      Dbg_Shift_6 => open,
      Dbg_Update_6 => open,
      Dbg_Rst_6 => open,
      Dbg_Clk_7 => open,
      Dbg_TDI_7 => open,
      Dbg_TDO_7 => net_gnd0,
      Dbg_Reg_En_7 => open,
      Dbg_Capture_7 => open,
      Dbg_Shift_7 => open,
      Dbg_Update_7 => open,
      Dbg_Rst_7 => open,
      bscan_tdi => open,
      bscan_reset => open,
      bscan_shift => open,
      bscan_update => open,
      bscan_capture => open,
      bscan_sel1 => open,
      bscan_drck1 => open,
      bscan_tdo1 => net_gnd0,
      FSL0_S_CLK => open,
      FSL0_S_READ => open,
      FSL0_S_DATA => net_gnd32,
      FSL0_S_CONTROL => net_gnd0,
      FSL0_S_EXISTS => net_gnd0,
      FSL0_M_CLK => open,
      FSL0_M_WRITE => open,
      FSL0_M_DATA => open,
      FSL0_M_CONTROL => open,
      FSL0_M_FULL => net_gnd0,
      Ext_JTAG_DRCK => open,
      Ext_JTAG_RESET => open,
      Ext_JTAG_SEL => open,
      Ext_JTAG_CAPTURE => open,
      Ext_JTAG_SHIFT => open,
      Ext_JTAG_UPDATE => open,
      Ext_JTAG_TDI => open,
      Ext_JTAG_TDO => net_gnd0
    );

  inst_proc_sys_reset : inst_proc_sys_reset_wrapper
    port map (
      Slowest_sync_clk => sys_clk_133mhz,
      Ext_Reset_In => sys_rst_133mhz,
      Aux_Reset_In => net_gnd0,
      MB_Debug_Sys_Rst => mdm_dbgrst_mba,
      Core_Reset_Req_0 => net_gnd0,
      Chip_Reset_Req_0 => net_gnd0,
      System_Reset_Req_0 => net_gnd0,
      Core_Reset_Req_1 => net_gnd0,
      Chip_Reset_Req_1 => net_gnd0,
      System_Reset_Req_1 => net_gnd0,
      Dcm_locked => net_vcc0,
      RstcPPCresetcore_0 => open,
      RstcPPCresetchip_0 => open,
      RstcPPCresetsys_0 => open,
      RstcPPCresetcore_1 => open,
      RstcPPCresetchip_1 => open,
      RstcPPCresetsys_1 => open,
      MB_Reset => mba_rst_133mhz,
      Bus_Struct_Reset => plb_rst_133mhz(0 to 0),
      Peripheral_Reset => open
    );

  tmd_mpe_vacc : tmd_mpe_vacc_wrapper
    port map (
      mpe_error => open,
      clk => sys_clk_133mhz,
      rst => sys_rst_133mhz,
      mpe_busy_tx => open,
      mpe_busy_rx => open,
      mpe_ila_control => net_gnd36,
      dbg_tx_fsm => dbg_tx_fsm,
      dbg_rx_fsm => dbg_rx_fsm,
      dbg_index => dbg_index,
      dbg_clr2snd => open,
      dbg_nif_full => open,
      dbg_nif_exists => open,
      dbg_rx_src => open,
      dbg_rx_src_tmp => open,
      dbg_tx_dest => open,
      from_host_read => fsl_vacc_to_mpedata_FSL_S_Read,
      from_host_data => fsl_vacc_to_mpedata_FSL_S_Data,
      from_host_ctrl => fsl_vacc_to_mpedata_FSL_S_Control,
      from_host_exists => fsl_vacc_to_mpedata_FSL_S_Exists,
      to_host_data => fsl_mpedata_to_vacc_FSL_M_Data,
      to_host_write => fsl_mpedata_to_vacc_FSL_M_Write,
      to_host_ctrl => fsl_mpedata_to_vacc_FSL_M_Control,
      to_host_full => fsl_mpedata_to_vacc_FSL_M_Full,
      from_net_if_read => fsl_l1_to_mpe_FSL_S_Read,
      from_net_if_data => fsl_l1_to_mpe_FSL_S_Data(0 to 31),
      from_net_if_ctrl => fsl_l1_to_mpe_FSL_S_Control,
      from_net_if_exists => fsl_l1_to_mpe_FSL_S_Exists,
      to_net_if_data => fsl_mpe_to_l1_FSL_M_Data(0 to 31),
      to_net_if_write => fsl_mpe_to_l1_FSL_M_Write,
      to_net_if_ctrl => fsl_mpe_to_l1_FSL_M_Control,
      to_net_if_full => fsl_mpe_to_l1_FSL_M_Full,
      cmd_in_read => fsl_vacc_to_mpecmd_FSL_S_Read,
      cmd_in_data => fsl_vacc_to_mpecmd_FSL_S_Data,
      cmd_in_ctrl => fsl_vacc_to_mpecmd_FSL_S_Control,
      cmd_in_exists => fsl_vacc_to_mpecmd_FSL_S_Exists,
      cmd_out_data => fsl_mpecmd_to_vacc_FSL_M_Data,
      cmd_out_write => fsl_mpecmd_to_vacc_FSL_M_Write,
      cmd_out_ctrl => fsl_mpecmd_to_vacc_FSL_M_Control,
      cmd_out_full => fsl_mpecmd_to_vacc_FSL_M_Full
    );

  --vacc : vacc_wrapper
  --  port map (
  --    Clk => sys_clk_133mhz,
  --    Rst => sys_rst_133mhz,
  --    Math_error => Math_error,
  --    Buffer_error => Buffer_error,
  --    Instr_error => Instr_error,
  --    From_mpe_data_read => fsl_mpedata_to_vacc_FSL_S_Read,
  --    From_mpe_data_data => fsl_mpedata_to_vacc_FSL_S_Data,
  --    From_mpe_data_ctrl => fsl_mpedata_to_vacc_FSL_S_Control,
  --    From_mpe_data_exists => fsl_mpedata_to_vacc_FSL_S_Exists,
  --    To_mpe_data_data => fsl_vacc_to_mpedata_FSL_M_Data,
  --    To_mpe_data_write => fsl_vacc_to_mpedata_FSL_M_Write,
  --    To_mpe_data_ctrl => fsl_vacc_to_mpedata_FSL_M_Control,
  --    To_mpe_data_full => fsl_vacc_to_mpedata_FSL_M_Full,
  --    From_mpe_cmd_read => fsl_mpecmd_to_vacc_FSL_S_Read,
  --    From_mpe_cmd_data => fsl_mpecmd_to_vacc_FSL_S_Data,
  --    From_mpe_cmd_ctrl => fsl_mpecmd_to_vacc_FSL_S_Control,
  --    From_mpe_cmd_exists => fsl_mpecmd_to_vacc_FSL_S_Exists,
  --    To_mpe_cmd_data => fsl_vacc_to_mpecmd_FSL_M_Data,
  --    To_mpe_cmd_write => fsl_vacc_to_mpecmd_FSL_M_Write,
  --    To_mpe_cmd_ctrl => fsl_vacc_to_mpecmd_FSL_M_Control,
  --    To_mpe_cmd_full => fsl_vacc_to_mpecmd_FSL_M_Full
  --  );

  iobuf_0 : IOBUF
    port map (
      I => fpga_scl_O,
      IO => FPGA1_SCL,
      O => fpga_scl_I,
      T => fpga_scl_T
    );

  iobuf_1 : IOBUF
    port map (
      I => fpga_sda_O,
      IO => FPGA1_SDA,
      O => fpga_sda_I,
      T => fpga_sda_T
    );

  iobuf_2 : IOBUF
    port map (
      I => RAM_PWR_ON_O,
      IO => RAM_PWR_ON,
      O => RAM_PWR_ON_I,
      T => RAM_PWR_ON_T
    );

  iobuf_3 : IOBUF
    port map (
      I => RAM5_DQ_O(31),
      IO => RAM5_DQ(31),
      O => RAM5_DQ_I(31),
      T => RAM5_DQ_T
    );

  iobuf_4 : IOBUF
    port map (
      I => RAM5_DQ_O(30),
      IO => RAM5_DQ(30),
      O => RAM5_DQ_I(30),
      T => RAM5_DQ_T
    );

  iobuf_5 : IOBUF
    port map (
      I => RAM5_DQ_O(29),
      IO => RAM5_DQ(29),
      O => RAM5_DQ_I(29),
      T => RAM5_DQ_T
    );

  iobuf_6 : IOBUF
    port map (
      I => RAM5_DQ_O(28),
      IO => RAM5_DQ(28),
      O => RAM5_DQ_I(28),
      T => RAM5_DQ_T
    );

  iobuf_7 : IOBUF
    port map (
      I => RAM5_DQ_O(27),
      IO => RAM5_DQ(27),
      O => RAM5_DQ_I(27),
      T => RAM5_DQ_T
    );

  iobuf_8 : IOBUF
    port map (
      I => RAM5_DQ_O(26),
      IO => RAM5_DQ(26),
      O => RAM5_DQ_I(26),
      T => RAM5_DQ_T
    );

  iobuf_9 : IOBUF
    port map (
      I => RAM5_DQ_O(25),
      IO => RAM5_DQ(25),
      O => RAM5_DQ_I(25),
      T => RAM5_DQ_T
    );

  iobuf_10 : IOBUF
    port map (
      I => RAM5_DQ_O(24),
      IO => RAM5_DQ(24),
      O => RAM5_DQ_I(24),
      T => RAM5_DQ_T
    );

  iobuf_11 : IOBUF
    port map (
      I => RAM5_DQ_O(23),
      IO => RAM5_DQ(23),
      O => RAM5_DQ_I(23),
      T => RAM5_DQ_T
    );

  iobuf_12 : IOBUF
    port map (
      I => RAM5_DQ_O(22),
      IO => RAM5_DQ(22),
      O => RAM5_DQ_I(22),
      T => RAM5_DQ_T
    );

  iobuf_13 : IOBUF
    port map (
      I => RAM5_DQ_O(21),
      IO => RAM5_DQ(21),
      O => RAM5_DQ_I(21),
      T => RAM5_DQ_T
    );

  iobuf_14 : IOBUF
    port map (
      I => RAM5_DQ_O(20),
      IO => RAM5_DQ(20),
      O => RAM5_DQ_I(20),
      T => RAM5_DQ_T
    );

  iobuf_15 : IOBUF
    port map (
      I => RAM5_DQ_O(19),
      IO => RAM5_DQ(19),
      O => RAM5_DQ_I(19),
      T => RAM5_DQ_T
    );

  iobuf_16 : IOBUF
    port map (
      I => RAM5_DQ_O(18),
      IO => RAM5_DQ(18),
      O => RAM5_DQ_I(18),
      T => RAM5_DQ_T
    );

  iobuf_17 : IOBUF
    port map (
      I => RAM5_DQ_O(17),
      IO => RAM5_DQ(17),
      O => RAM5_DQ_I(17),
      T => RAM5_DQ_T
    );

  iobuf_18 : IOBUF
    port map (
      I => RAM5_DQ_O(16),
      IO => RAM5_DQ(16),
      O => RAM5_DQ_I(16),
      T => RAM5_DQ_T
    );

  iobuf_19 : IOBUF
    port map (
      I => RAM5_DQ_O(15),
      IO => RAM5_DQ(15),
      O => RAM5_DQ_I(15),
      T => RAM5_DQ_T
    );

  iobuf_20 : IOBUF
    port map (
      I => RAM5_DQ_O(14),
      IO => RAM5_DQ(14),
      O => RAM5_DQ_I(14),
      T => RAM5_DQ_T
    );

  iobuf_21 : IOBUF
    port map (
      I => RAM5_DQ_O(13),
      IO => RAM5_DQ(13),
      O => RAM5_DQ_I(13),
      T => RAM5_DQ_T
    );

  iobuf_22 : IOBUF
    port map (
      I => RAM5_DQ_O(12),
      IO => RAM5_DQ(12),
      O => RAM5_DQ_I(12),
      T => RAM5_DQ_T
    );

  iobuf_23 : IOBUF
    port map (
      I => RAM5_DQ_O(11),
      IO => RAM5_DQ(11),
      O => RAM5_DQ_I(11),
      T => RAM5_DQ_T
    );

  iobuf_24 : IOBUF
    port map (
      I => RAM5_DQ_O(10),
      IO => RAM5_DQ(10),
      O => RAM5_DQ_I(10),
      T => RAM5_DQ_T
    );

  iobuf_25 : IOBUF
    port map (
      I => RAM5_DQ_O(9),
      IO => RAM5_DQ(9),
      O => RAM5_DQ_I(9),
      T => RAM5_DQ_T
    );

  iobuf_26 : IOBUF
    port map (
      I => RAM5_DQ_O(8),
      IO => RAM5_DQ(8),
      O => RAM5_DQ_I(8),
      T => RAM5_DQ_T
    );

  iobuf_27 : IOBUF
    port map (
      I => RAM5_DQ_O(7),
      IO => RAM5_DQ(7),
      O => RAM5_DQ_I(7),
      T => RAM5_DQ_T
    );

  iobuf_28 : IOBUF
    port map (
      I => RAM5_DQ_O(6),
      IO => RAM5_DQ(6),
      O => RAM5_DQ_I(6),
      T => RAM5_DQ_T
    );

  iobuf_29 : IOBUF
    port map (
      I => RAM5_DQ_O(5),
      IO => RAM5_DQ(5),
      O => RAM5_DQ_I(5),
      T => RAM5_DQ_T
    );

  iobuf_30 : IOBUF
    port map (
      I => RAM5_DQ_O(4),
      IO => RAM5_DQ(4),
      O => RAM5_DQ_I(4),
      T => RAM5_DQ_T
    );

  iobuf_31 : IOBUF
    port map (
      I => RAM5_DQ_O(3),
      IO => RAM5_DQ(3),
      O => RAM5_DQ_I(3),
      T => RAM5_DQ_T
    );

  iobuf_32 : IOBUF
    port map (
      I => RAM5_DQ_O(2),
      IO => RAM5_DQ(2),
      O => RAM5_DQ_I(2),
      T => RAM5_DQ_T
    );

  iobuf_33 : IOBUF
    port map (
      I => RAM5_DQ_O(1),
      IO => RAM5_DQ(1),
      O => RAM5_DQ_I(1),
      T => RAM5_DQ_T
    );

  iobuf_34 : IOBUF
    port map (
      I => RAM5_DQ_O(0),
      IO => RAM5_DQ(0),
      O => RAM5_DQ_I(0),
      T => RAM5_DQ_T
    );

  iobuf_35 : IOBUF
    port map (
      I => RAM5_DQ_P_O(3),
      IO => RAM5_DQ_P(3),
      O => RAM5_DQ_P_I(3),
      T => RAM5_DQ_P_T
    );

  iobuf_36 : IOBUF
    port map (
      I => RAM5_DQ_P_O(2),
      IO => RAM5_DQ_P(2),
      O => RAM5_DQ_P_I(2),
      T => RAM5_DQ_P_T
    );

  iobuf_37 : IOBUF
    port map (
      I => RAM5_DQ_P_O(1),
      IO => RAM5_DQ_P(1),
      O => RAM5_DQ_P_I(1),
      T => RAM5_DQ_P_T
    );

  iobuf_38 : IOBUF
    port map (
      I => RAM5_DQ_P_O(0),
      IO => RAM5_DQ_P(0),
      O => RAM5_DQ_P_I(0),
      T => RAM5_DQ_P_T
    );

  iobuf_39 : IOBUF
    port map (
      I => RAM5_ADDR_O(21),
      IO => RAM5_ADDR(21),
      O => RAM5_ADDR_I(21),
      T => RAM5_ADDR_T
    );

  iobuf_40 : IOBUF
    port map (
      I => RAM5_ADDR_O(20),
      IO => RAM5_ADDR(20),
      O => RAM5_ADDR_I(20),
      T => RAM5_ADDR_T
    );

  iobuf_41 : IOBUF
    port map (
      I => RAM5_ADDR_O(19),
      IO => RAM5_ADDR(19),
      O => RAM5_ADDR_I(19),
      T => RAM5_ADDR_T
    );

  iobuf_42 : IOBUF
    port map (
      I => RAM5_ADDR_O(18),
      IO => RAM5_ADDR(18),
      O => RAM5_ADDR_I(18),
      T => RAM5_ADDR_T
    );

  iobuf_43 : IOBUF
    port map (
      I => RAM5_ADDR_O(17),
      IO => RAM5_ADDR(17),
      O => RAM5_ADDR_I(17),
      T => RAM5_ADDR_T
    );

  iobuf_44 : IOBUF
    port map (
      I => RAM5_ADDR_O(16),
      IO => RAM5_ADDR(16),
      O => RAM5_ADDR_I(16),
      T => RAM5_ADDR_T
    );

  iobuf_45 : IOBUF
    port map (
      I => RAM5_ADDR_O(15),
      IO => RAM5_ADDR(15),
      O => RAM5_ADDR_I(15),
      T => RAM5_ADDR_T
    );

  iobuf_46 : IOBUF
    port map (
      I => RAM5_ADDR_O(14),
      IO => RAM5_ADDR(14),
      O => RAM5_ADDR_I(14),
      T => RAM5_ADDR_T
    );

  iobuf_47 : IOBUF
    port map (
      I => RAM5_ADDR_O(13),
      IO => RAM5_ADDR(13),
      O => RAM5_ADDR_I(13),
      T => RAM5_ADDR_T
    );

  iobuf_48 : IOBUF
    port map (
      I => RAM5_ADDR_O(12),
      IO => RAM5_ADDR(12),
      O => RAM5_ADDR_I(12),
      T => RAM5_ADDR_T
    );

  iobuf_49 : IOBUF
    port map (
      I => RAM5_ADDR_O(11),
      IO => RAM5_ADDR(11),
      O => RAM5_ADDR_I(11),
      T => RAM5_ADDR_T
    );

  iobuf_50 : IOBUF
    port map (
      I => RAM5_ADDR_O(10),
      IO => RAM5_ADDR(10),
      O => RAM5_ADDR_I(10),
      T => RAM5_ADDR_T
    );

  iobuf_51 : IOBUF
    port map (
      I => RAM5_ADDR_O(9),
      IO => RAM5_ADDR(9),
      O => RAM5_ADDR_I(9),
      T => RAM5_ADDR_T
    );

  iobuf_52 : IOBUF
    port map (
      I => RAM5_ADDR_O(8),
      IO => RAM5_ADDR(8),
      O => RAM5_ADDR_I(8),
      T => RAM5_ADDR_T
    );

  iobuf_53 : IOBUF
    port map (
      I => RAM5_ADDR_O(7),
      IO => RAM5_ADDR(7),
      O => RAM5_ADDR_I(7),
      T => RAM5_ADDR_T
    );

  iobuf_54 : IOBUF
    port map (
      I => RAM5_ADDR_O(6),
      IO => RAM5_ADDR(6),
      O => RAM5_ADDR_I(6),
      T => RAM5_ADDR_T
    );

  iobuf_55 : IOBUF
    port map (
      I => RAM5_ADDR_O(5),
      IO => RAM5_ADDR(5),
      O => RAM5_ADDR_I(5),
      T => RAM5_ADDR_T
    );

  iobuf_56 : IOBUF
    port map (
      I => RAM5_ADDR_O(4),
      IO => RAM5_ADDR(4),
      O => RAM5_ADDR_I(4),
      T => RAM5_ADDR_T
    );

  iobuf_57 : IOBUF
    port map (
      I => RAM5_ADDR_O(3),
      IO => RAM5_ADDR(3),
      O => RAM5_ADDR_I(3),
      T => RAM5_ADDR_T
    );

  iobuf_58 : IOBUF
    port map (
      I => RAM5_ADDR_O(2),
      IO => RAM5_ADDR(2),
      O => RAM5_ADDR_I(2),
      T => RAM5_ADDR_T
    );

  iobuf_59 : IOBUF
    port map (
      I => RAM5_ADDR_O(1),
      IO => RAM5_ADDR(1),
      O => RAM5_ADDR_I(1),
      T => RAM5_ADDR_T
    );

  iobuf_60 : IOBUF
    port map (
      I => RAM5_ADDR_O(0),
      IO => RAM5_ADDR(0),
      O => RAM5_ADDR_I(0),
      T => RAM5_ADDR_T
    );

  iobuf_61 : IOBUF
    port map (
      I => RAM5_BW_N_O(3),
      IO => RAM5_BW_N(3),
      O => RAM5_BW_N_I(3),
      T => RAM5_BW_N_T
    );

  iobuf_62 : IOBUF
    port map (
      I => RAM5_BW_N_O(2),
      IO => RAM5_BW_N(2),
      O => RAM5_BW_N_I(2),
      T => RAM5_BW_N_T
    );

  iobuf_63 : IOBUF
    port map (
      I => RAM5_BW_N_O(1),
      IO => RAM5_BW_N(1),
      O => RAM5_BW_N_I(1),
      T => RAM5_BW_N_T
    );

  iobuf_64 : IOBUF
    port map (
      I => RAM5_BW_N_O(0),
      IO => RAM5_BW_N(0),
      O => RAM5_BW_N_I(0),
      T => RAM5_BW_N_T
    );

  iobuf_65 : IOBUF
    port map (
      I => RAM6_DQ_O(31),
      IO => RAM6_DQ(31),
      O => RAM6_DQ_I(31),
      T => RAM6_DQ_T
    );

  iobuf_66 : IOBUF
    port map (
      I => RAM6_DQ_O(30),
      IO => RAM6_DQ(30),
      O => RAM6_DQ_I(30),
      T => RAM6_DQ_T
    );

  iobuf_67 : IOBUF
    port map (
      I => RAM6_DQ_O(29),
      IO => RAM6_DQ(29),
      O => RAM6_DQ_I(29),
      T => RAM6_DQ_T
    );

  iobuf_68 : IOBUF
    port map (
      I => RAM6_DQ_O(28),
      IO => RAM6_DQ(28),
      O => RAM6_DQ_I(28),
      T => RAM6_DQ_T
    );

  iobuf_69 : IOBUF
    port map (
      I => RAM6_DQ_O(27),
      IO => RAM6_DQ(27),
      O => RAM6_DQ_I(27),
      T => RAM6_DQ_T
    );

  iobuf_70 : IOBUF
    port map (
      I => RAM6_DQ_O(26),
      IO => RAM6_DQ(26),
      O => RAM6_DQ_I(26),
      T => RAM6_DQ_T
    );

  iobuf_71 : IOBUF
    port map (
      I => RAM6_DQ_O(25),
      IO => RAM6_DQ(25),
      O => RAM6_DQ_I(25),
      T => RAM6_DQ_T
    );

  iobuf_72 : IOBUF
    port map (
      I => RAM6_DQ_O(24),
      IO => RAM6_DQ(24),
      O => RAM6_DQ_I(24),
      T => RAM6_DQ_T
    );

  iobuf_73 : IOBUF
    port map (
      I => RAM6_DQ_O(23),
      IO => RAM6_DQ(23),
      O => RAM6_DQ_I(23),
      T => RAM6_DQ_T
    );

  iobuf_74 : IOBUF
    port map (
      I => RAM6_DQ_O(22),
      IO => RAM6_DQ(22),
      O => RAM6_DQ_I(22),
      T => RAM6_DQ_T
    );

  iobuf_75 : IOBUF
    port map (
      I => RAM6_DQ_O(21),
      IO => RAM6_DQ(21),
      O => RAM6_DQ_I(21),
      T => RAM6_DQ_T
    );

  iobuf_76 : IOBUF
    port map (
      I => RAM6_DQ_O(20),
      IO => RAM6_DQ(20),
      O => RAM6_DQ_I(20),
      T => RAM6_DQ_T
    );

  iobuf_77 : IOBUF
    port map (
      I => RAM6_DQ_O(19),
      IO => RAM6_DQ(19),
      O => RAM6_DQ_I(19),
      T => RAM6_DQ_T
    );

  iobuf_78 : IOBUF
    port map (
      I => RAM6_DQ_O(18),
      IO => RAM6_DQ(18),
      O => RAM6_DQ_I(18),
      T => RAM6_DQ_T
    );

  iobuf_79 : IOBUF
    port map (
      I => RAM6_DQ_O(17),
      IO => RAM6_DQ(17),
      O => RAM6_DQ_I(17),
      T => RAM6_DQ_T
    );

  iobuf_80 : IOBUF
    port map (
      I => RAM6_DQ_O(16),
      IO => RAM6_DQ(16),
      O => RAM6_DQ_I(16),
      T => RAM6_DQ_T
    );

  iobuf_81 : IOBUF
    port map (
      I => RAM6_DQ_O(15),
      IO => RAM6_DQ(15),
      O => RAM6_DQ_I(15),
      T => RAM6_DQ_T
    );

  iobuf_82 : IOBUF
    port map (
      I => RAM6_DQ_O(14),
      IO => RAM6_DQ(14),
      O => RAM6_DQ_I(14),
      T => RAM6_DQ_T
    );

  iobuf_83 : IOBUF
    port map (
      I => RAM6_DQ_O(13),
      IO => RAM6_DQ(13),
      O => RAM6_DQ_I(13),
      T => RAM6_DQ_T
    );

  iobuf_84 : IOBUF
    port map (
      I => RAM6_DQ_O(12),
      IO => RAM6_DQ(12),
      O => RAM6_DQ_I(12),
      T => RAM6_DQ_T
    );

  iobuf_85 : IOBUF
    port map (
      I => RAM6_DQ_O(11),
      IO => RAM6_DQ(11),
      O => RAM6_DQ_I(11),
      T => RAM6_DQ_T
    );

  iobuf_86 : IOBUF
    port map (
      I => RAM6_DQ_O(10),
      IO => RAM6_DQ(10),
      O => RAM6_DQ_I(10),
      T => RAM6_DQ_T
    );

  iobuf_87 : IOBUF
    port map (
      I => RAM6_DQ_O(9),
      IO => RAM6_DQ(9),
      O => RAM6_DQ_I(9),
      T => RAM6_DQ_T
    );

  iobuf_88 : IOBUF
    port map (
      I => RAM6_DQ_O(8),
      IO => RAM6_DQ(8),
      O => RAM6_DQ_I(8),
      T => RAM6_DQ_T
    );

  iobuf_89 : IOBUF
    port map (
      I => RAM6_DQ_O(7),
      IO => RAM6_DQ(7),
      O => RAM6_DQ_I(7),
      T => RAM6_DQ_T
    );

  iobuf_90 : IOBUF
    port map (
      I => RAM6_DQ_O(6),
      IO => RAM6_DQ(6),
      O => RAM6_DQ_I(6),
      T => RAM6_DQ_T
    );

  iobuf_91 : IOBUF
    port map (
      I => RAM6_DQ_O(5),
      IO => RAM6_DQ(5),
      O => RAM6_DQ_I(5),
      T => RAM6_DQ_T
    );

  iobuf_92 : IOBUF
    port map (
      I => RAM6_DQ_O(4),
      IO => RAM6_DQ(4),
      O => RAM6_DQ_I(4),
      T => RAM6_DQ_T
    );

  iobuf_93 : IOBUF
    port map (
      I => RAM6_DQ_O(3),
      IO => RAM6_DQ(3),
      O => RAM6_DQ_I(3),
      T => RAM6_DQ_T
    );

  iobuf_94 : IOBUF
    port map (
      I => RAM6_DQ_O(2),
      IO => RAM6_DQ(2),
      O => RAM6_DQ_I(2),
      T => RAM6_DQ_T
    );

  iobuf_95 : IOBUF
    port map (
      I => RAM6_DQ_O(1),
      IO => RAM6_DQ(1),
      O => RAM6_DQ_I(1),
      T => RAM6_DQ_T
    );

  iobuf_96 : IOBUF
    port map (
      I => RAM6_DQ_O(0),
      IO => RAM6_DQ(0),
      O => RAM6_DQ_I(0),
      T => RAM6_DQ_T
    );

  iobuf_97 : IOBUF
    port map (
      I => RAM6_DQ_P_O(3),
      IO => RAM6_DQ_P(3),
      O => RAM6_DQ_P_I(3),
      T => RAM6_DQ_P_T
    );

  iobuf_98 : IOBUF
    port map (
      I => RAM6_DQ_P_O(2),
      IO => RAM6_DQ_P(2),
      O => RAM6_DQ_P_I(2),
      T => RAM6_DQ_P_T
    );

  iobuf_99 : IOBUF
    port map (
      I => RAM6_DQ_P_O(1),
      IO => RAM6_DQ_P(1),
      O => RAM6_DQ_P_I(1),
      T => RAM6_DQ_P_T
    );

  iobuf_100 : IOBUF
    port map (
      I => RAM6_DQ_P_O(0),
      IO => RAM6_DQ_P(0),
      O => RAM6_DQ_P_I(0),
      T => RAM6_DQ_P_T
    );

  iobuf_101 : IOBUF
    port map (
      I => RAM6_ADDR_O(21),
      IO => RAM6_ADDR(21),
      O => RAM6_ADDR_I(21),
      T => RAM6_ADDR_T
    );

  iobuf_102 : IOBUF
    port map (
      I => RAM6_ADDR_O(20),
      IO => RAM6_ADDR(20),
      O => RAM6_ADDR_I(20),
      T => RAM6_ADDR_T
    );

  iobuf_103 : IOBUF
    port map (
      I => RAM6_ADDR_O(19),
      IO => RAM6_ADDR(19),
      O => RAM6_ADDR_I(19),
      T => RAM6_ADDR_T
    );

  iobuf_104 : IOBUF
    port map (
      I => RAM6_ADDR_O(18),
      IO => RAM6_ADDR(18),
      O => RAM6_ADDR_I(18),
      T => RAM6_ADDR_T
    );

  iobuf_105 : IOBUF
    port map (
      I => RAM6_ADDR_O(17),
      IO => RAM6_ADDR(17),
      O => RAM6_ADDR_I(17),
      T => RAM6_ADDR_T
    );

  iobuf_106 : IOBUF
    port map (
      I => RAM6_ADDR_O(16),
      IO => RAM6_ADDR(16),
      O => RAM6_ADDR_I(16),
      T => RAM6_ADDR_T
    );

  iobuf_107 : IOBUF
    port map (
      I => RAM6_ADDR_O(15),
      IO => RAM6_ADDR(15),
      O => RAM6_ADDR_I(15),
      T => RAM6_ADDR_T
    );

  iobuf_108 : IOBUF
    port map (
      I => RAM6_ADDR_O(14),
      IO => RAM6_ADDR(14),
      O => RAM6_ADDR_I(14),
      T => RAM6_ADDR_T
    );

  iobuf_109 : IOBUF
    port map (
      I => RAM6_ADDR_O(13),
      IO => RAM6_ADDR(13),
      O => RAM6_ADDR_I(13),
      T => RAM6_ADDR_T
    );

  iobuf_110 : IOBUF
    port map (
      I => RAM6_ADDR_O(12),
      IO => RAM6_ADDR(12),
      O => RAM6_ADDR_I(12),
      T => RAM6_ADDR_T
    );

  iobuf_111 : IOBUF
    port map (
      I => RAM6_ADDR_O(11),
      IO => RAM6_ADDR(11),
      O => RAM6_ADDR_I(11),
      T => RAM6_ADDR_T
    );

  iobuf_112 : IOBUF
    port map (
      I => RAM6_ADDR_O(10),
      IO => RAM6_ADDR(10),
      O => RAM6_ADDR_I(10),
      T => RAM6_ADDR_T
    );

  iobuf_113 : IOBUF
    port map (
      I => RAM6_ADDR_O(9),
      IO => RAM6_ADDR(9),
      O => RAM6_ADDR_I(9),
      T => RAM6_ADDR_T
    );

  iobuf_114 : IOBUF
    port map (
      I => RAM6_ADDR_O(8),
      IO => RAM6_ADDR(8),
      O => RAM6_ADDR_I(8),
      T => RAM6_ADDR_T
    );

  iobuf_115 : IOBUF
    port map (
      I => RAM6_ADDR_O(7),
      IO => RAM6_ADDR(7),
      O => RAM6_ADDR_I(7),
      T => RAM6_ADDR_T
    );

  iobuf_116 : IOBUF
    port map (
      I => RAM6_ADDR_O(6),
      IO => RAM6_ADDR(6),
      O => RAM6_ADDR_I(6),
      T => RAM6_ADDR_T
    );

  iobuf_117 : IOBUF
    port map (
      I => RAM6_ADDR_O(5),
      IO => RAM6_ADDR(5),
      O => RAM6_ADDR_I(5),
      T => RAM6_ADDR_T
    );

  iobuf_118 : IOBUF
    port map (
      I => RAM6_ADDR_O(4),
      IO => RAM6_ADDR(4),
      O => RAM6_ADDR_I(4),
      T => RAM6_ADDR_T
    );

  iobuf_119 : IOBUF
    port map (
      I => RAM6_ADDR_O(3),
      IO => RAM6_ADDR(3),
      O => RAM6_ADDR_I(3),
      T => RAM6_ADDR_T
    );

  iobuf_120 : IOBUF
    port map (
      I => RAM6_ADDR_O(2),
      IO => RAM6_ADDR(2),
      O => RAM6_ADDR_I(2),
      T => RAM6_ADDR_T
    );

  iobuf_121 : IOBUF
    port map (
      I => RAM6_ADDR_O(1),
      IO => RAM6_ADDR(1),
      O => RAM6_ADDR_I(1),
      T => RAM6_ADDR_T
    );

  iobuf_122 : IOBUF
    port map (
      I => RAM6_ADDR_O(0),
      IO => RAM6_ADDR(0),
      O => RAM6_ADDR_I(0),
      T => RAM6_ADDR_T
    );

  iobuf_123 : IOBUF
    port map (
      I => RAM6_BW_N_O(3),
      IO => RAM6_BW_N(3),
      O => RAM6_BW_N_I(3),
      T => RAM6_BW_N_T
    );

  iobuf_124 : IOBUF
    port map (
      I => RAM6_BW_N_O(2),
      IO => RAM6_BW_N(2),
      O => RAM6_BW_N_I(2),
      T => RAM6_BW_N_T
    );

  iobuf_125 : IOBUF
    port map (
      I => RAM6_BW_N_O(1),
      IO => RAM6_BW_N(1),
      O => RAM6_BW_N_I(1),
      T => RAM6_BW_N_T
    );

  iobuf_126 : IOBUF
    port map (
      I => RAM6_BW_N_O(0),
      IO => RAM6_BW_N(0),
      O => RAM6_BW_N_I(0),
      T => RAM6_BW_N_T
    );

end architecture STRUCTURE;

