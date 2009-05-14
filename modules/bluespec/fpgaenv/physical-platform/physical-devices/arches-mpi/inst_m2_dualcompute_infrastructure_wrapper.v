//-----------------------------------------------------------------------------
// inst_m2_dualcompute_infrastructure_wrapper.v
//-----------------------------------------------------------------------------

module inst_m2_dualcompute_infrastructure_wrapper
  (
    i_fpga_clk0_p,
    i_fpga_clk0_n,
    o_fpga_clk0_raw,
    o_fpga_clk0_bufg,
    i_fpga_clk1_p,
    i_fpga_clk1_n,
    o_fpga_clk1_raw,
    o_fpga_clk1_bufg,
    i_fpga_clk100_p,
    i_fpga_clk100_n,
    o_fpga_clk100_raw,
    o_fpga_clk100_bufg,
    o_fpga_led0_z,
    o_fpga_led1_z,
    o_fpga_led2_z,
    o_fpga_led3_z,
    o_ram0_led_z,
    o_ram1_led_z,
    o_fpga_temp_led_z,
    o_fpga_hot_led_z,
    i_fpga_reg_en_z,
    i_fpga_reg_ads_z,
    i_fpga_reg_uds_z,
    i_fpga_reg_lds_z,
    i_fpga_reg_reset_z,
    i_fpga_reg_rd_wr_z,
    o_fpga_reg_clk,
    o_fpga_intr,
    o_fpga_reg_rdy_z,
    i_fpga_config_data,
    i_ram0_cq,
    i_ram0_cq_n,
    o_ram0_ld_n,
    o_ram0_rw_n,
    o_ram0_dll_off_n,
    o_ram0_k,
    o_ram0_k_n,
    i_ram0_mbank_sel,
    i_ram1_cq,
    i_ram1_cq_n,
    o_ram1_ld_n,
    o_ram1_rw_n,
    o_ram1_dll_off_n,
    o_ram1_k,
    o_ram1_k_n,
    i_ram1_mbank_sel,
    i_led_override,
    b_fpga_scl_I,
    b_fpga_scl_O,
    b_fpga_scl_T,
    b_fpga_sda_I,
    b_fpga_sda_O,
    b_fpga_sda_T,
    b_ram_pwr_on_I,
    b_ram_pwr_on_O,
    b_ram_pwr_on_T,
    b_ram0_dq_I,
    b_ram0_dq_O,
    b_ram0_dq_T,
    b_ram0_dq_p_I,
    b_ram0_dq_p_O,
    b_ram0_dq_p_T,
    b_ram0_addr_I,
    b_ram0_addr_O,
    b_ram0_addr_T,
    b_ram0_bw_n_I,
    b_ram0_bw_n_O,
    b_ram0_bw_n_T,
    b_ram1_dq_I,
    b_ram1_dq_O,
    b_ram1_dq_T,
    b_ram1_dq_p_I,
    b_ram1_dq_p_O,
    b_ram1_dq_p_T,
    b_ram1_addr_I,
    b_ram1_addr_O,
    b_ram1_addr_T,
    b_ram1_bw_n_I,
    b_ram1_bw_n_O,
    b_ram1_bw_n_T
  );
  input i_fpga_clk0_p;
  input i_fpga_clk0_n;
  output o_fpga_clk0_raw;
  output o_fpga_clk0_bufg;
  input i_fpga_clk1_p;
  input i_fpga_clk1_n;
  output o_fpga_clk1_raw;
  output o_fpga_clk1_bufg;
  input i_fpga_clk100_p;
  input i_fpga_clk100_n;
  output o_fpga_clk100_raw;
  output o_fpga_clk100_bufg;
  output o_fpga_led0_z;
  output o_fpga_led1_z;
  output o_fpga_led2_z;
  output o_fpga_led3_z;
  output o_ram0_led_z;
  output o_ram1_led_z;
  output o_fpga_temp_led_z;
  output o_fpga_hot_led_z;
  input i_fpga_reg_en_z;
  input i_fpga_reg_ads_z;
  input i_fpga_reg_uds_z;
  input i_fpga_reg_lds_z;
  input i_fpga_reg_reset_z;
  input i_fpga_reg_rd_wr_z;
  output o_fpga_reg_clk;
  output o_fpga_intr;
  output o_fpga_reg_rdy_z;
  input [7:0] i_fpga_config_data;
  input i_ram0_cq;
  input i_ram0_cq_n;
  output o_ram0_ld_n;
  output o_ram0_rw_n;
  output o_ram0_dll_off_n;
  output o_ram0_k;
  output o_ram0_k_n;
  input i_ram0_mbank_sel;
  input i_ram1_cq;
  input i_ram1_cq_n;
  output o_ram1_ld_n;
  output o_ram1_rw_n;
  output o_ram1_dll_off_n;
  output o_ram1_k;
  output o_ram1_k_n;
  input i_ram1_mbank_sel;
  input [0:7] i_led_override;
  input b_fpga_scl_I;
  output b_fpga_scl_O;
  output b_fpga_scl_T;
  input b_fpga_sda_I;
  output b_fpga_sda_O;
  output b_fpga_sda_T;
  input b_ram_pwr_on_I;
  output b_ram_pwr_on_O;
  output b_ram_pwr_on_T;
  input [31:0] b_ram0_dq_I;
  output [31:0] b_ram0_dq_O;
  output b_ram0_dq_T;
  input [3:0] b_ram0_dq_p_I;
  output [3:0] b_ram0_dq_p_O;
  output b_ram0_dq_p_T;
  input [21:0] b_ram0_addr_I;
  output [21:0] b_ram0_addr_O;
  output b_ram0_addr_T;
  input [3:0] b_ram0_bw_n_I;
  output [3:0] b_ram0_bw_n_O;
  output b_ram0_bw_n_T;
  input [31:0] b_ram1_dq_I;
  output [31:0] b_ram1_dq_O;
  output b_ram1_dq_T;
  input [3:0] b_ram1_dq_p_I;
  output [3:0] b_ram1_dq_p_O;
  output b_ram1_dq_p_T;
  input [21:0] b_ram1_addr_I;
  output [21:0] b_ram1_addr_O;
  output b_ram1_addr_T;
  input [3:0] b_ram1_bw_n_I;
  output [3:0] b_ram1_bw_n_O;
  output b_ram1_bw_n_T;

  m2_dualcompute_infrastructure
    #(
      .C_FPGA_ID ( 1 ),
      .C_TERM_CLK0 ( 1 ),
      .C_TERM_CLK1 ( 1 ),
      .C_TERM_CLK100 ( 1 ),
      .C_BUFG_CLK0 ( 0 ),
      .C_BUFG_CLK1 ( 0 ),
      .C_BUFG_CLK100 ( 1 ),
      .C_TERM_LEDS ( 0 ),
      .C_TERM_I2C ( 1 ),
      .C_TERM_EXPBUS ( 1 ),
      .C_TERM_RAM0 ( 1 ),
      .C_TERM_RAM1 ( 1 )
    )
    inst_m2_dualcompute_infrastructure (
      .i_fpga_clk0_p ( i_fpga_clk0_p ),
      .i_fpga_clk0_n ( i_fpga_clk0_n ),
      .o_fpga_clk0_raw ( o_fpga_clk0_raw ),
      .o_fpga_clk0_bufg ( o_fpga_clk0_bufg ),
      .i_fpga_clk1_p ( i_fpga_clk1_p ),
      .i_fpga_clk1_n ( i_fpga_clk1_n ),
      .o_fpga_clk1_raw ( o_fpga_clk1_raw ),
      .o_fpga_clk1_bufg ( o_fpga_clk1_bufg ),
      .i_fpga_clk100_p ( i_fpga_clk100_p ),
      .i_fpga_clk100_n ( i_fpga_clk100_n ),
      .o_fpga_clk100_raw ( o_fpga_clk100_raw ),
      .o_fpga_clk100_bufg ( o_fpga_clk100_bufg ),
      .o_fpga_led0_z ( o_fpga_led0_z ),
      .o_fpga_led1_z ( o_fpga_led1_z ),
      .o_fpga_led2_z ( o_fpga_led2_z ),
      .o_fpga_led3_z ( o_fpga_led3_z ),
      .o_ram0_led_z ( o_ram0_led_z ),
      .o_ram1_led_z ( o_ram1_led_z ),
      .o_fpga_temp_led_z ( o_fpga_temp_led_z ),
      .o_fpga_hot_led_z ( o_fpga_hot_led_z ),
      .i_fpga_reg_en_z ( i_fpga_reg_en_z ),
      .i_fpga_reg_ads_z ( i_fpga_reg_ads_z ),
      .i_fpga_reg_uds_z ( i_fpga_reg_uds_z ),
      .i_fpga_reg_lds_z ( i_fpga_reg_lds_z ),
      .i_fpga_reg_reset_z ( i_fpga_reg_reset_z ),
      .i_fpga_reg_rd_wr_z ( i_fpga_reg_rd_wr_z ),
      .o_fpga_reg_clk ( o_fpga_reg_clk ),
      .o_fpga_intr ( o_fpga_intr ),
      .o_fpga_reg_rdy_z ( o_fpga_reg_rdy_z ),
      .i_fpga_config_data ( i_fpga_config_data ),
      .i_ram0_cq ( i_ram0_cq ),
      .i_ram0_cq_n ( i_ram0_cq_n ),
      .o_ram0_ld_n ( o_ram0_ld_n ),
      .o_ram0_rw_n ( o_ram0_rw_n ),
      .o_ram0_dll_off_n ( o_ram0_dll_off_n ),
      .o_ram0_k ( o_ram0_k ),
      .o_ram0_k_n ( o_ram0_k_n ),
      .i_ram0_mbank_sel ( i_ram0_mbank_sel ),
      .i_ram1_cq ( i_ram1_cq ),
      .i_ram1_cq_n ( i_ram1_cq_n ),
      .o_ram1_ld_n ( o_ram1_ld_n ),
      .o_ram1_rw_n ( o_ram1_rw_n ),
      .o_ram1_dll_off_n ( o_ram1_dll_off_n ),
      .o_ram1_k ( o_ram1_k ),
      .o_ram1_k_n ( o_ram1_k_n ),
      .i_ram1_mbank_sel ( i_ram1_mbank_sel ),
      .i_led_override ( i_led_override ),
      .b_fpga_scl_I ( b_fpga_scl_I ),
      .b_fpga_scl_O ( b_fpga_scl_O ),
      .b_fpga_scl_T ( b_fpga_scl_T ),
      .b_fpga_sda_I ( b_fpga_sda_I ),
      .b_fpga_sda_O ( b_fpga_sda_O ),
      .b_fpga_sda_T ( b_fpga_sda_T ),
      .b_ram_pwr_on_I ( b_ram_pwr_on_I ),
      .b_ram_pwr_on_O ( b_ram_pwr_on_O ),
      .b_ram_pwr_on_T ( b_ram_pwr_on_T ),
      .b_ram0_dq_I ( b_ram0_dq_I ),
      .b_ram0_dq_O ( b_ram0_dq_O ),
      .b_ram0_dq_T ( b_ram0_dq_T ),
      .b_ram0_dq_p_I ( b_ram0_dq_p_I ),
      .b_ram0_dq_p_O ( b_ram0_dq_p_O ),
      .b_ram0_dq_p_T ( b_ram0_dq_p_T ),
      .b_ram0_addr_I ( b_ram0_addr_I ),
      .b_ram0_addr_O ( b_ram0_addr_O ),
      .b_ram0_addr_T ( b_ram0_addr_T ),
      .b_ram0_bw_n_I ( b_ram0_bw_n_I ),
      .b_ram0_bw_n_O ( b_ram0_bw_n_O ),
      .b_ram0_bw_n_T ( b_ram0_bw_n_T ),
      .b_ram1_dq_I ( b_ram1_dq_I ),
      .b_ram1_dq_O ( b_ram1_dq_O ),
      .b_ram1_dq_T ( b_ram1_dq_T ),
      .b_ram1_dq_p_I ( b_ram1_dq_p_I ),
      .b_ram1_dq_p_O ( b_ram1_dq_p_O ),
      .b_ram1_dq_p_T ( b_ram1_dq_p_T ),
      .b_ram1_addr_I ( b_ram1_addr_I ),
      .b_ram1_addr_O ( b_ram1_addr_O ),
      .b_ram1_addr_T ( b_ram1_addr_T ),
      .b_ram1_bw_n_I ( b_ram1_bw_n_I ),
      .b_ram1_bw_n_O ( b_ram1_bw_n_O ),
      .b_ram1_bw_n_T ( b_ram1_bw_n_T )
    );

endmodule

// synthesis attribute x_core_info of inst_m2_dualcompute_infrastructure_wrapper is m2_dualcompute_infrastructure_v1_00_a;

