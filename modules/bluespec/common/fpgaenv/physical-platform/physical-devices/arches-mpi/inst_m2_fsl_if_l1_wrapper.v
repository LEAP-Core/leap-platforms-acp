//-----------------------------------------------------------------------------
// inst_m2_fsl_if_l1_wrapper.v
//-----------------------------------------------------------------------------

module inst_m2_fsl_if_l1_wrapper
  (
    i_clk_200mhz,
    i_clk_1x,
    i_clk_2x,
    i_clk_2x_90deg,
    i_rst_tx,
    i_rst_rx,
    i_rst_sys,
    i_pll_locked,
    o_rst,
    i_lane_p,
    i_lane_n,
    o_lane_p,
    o_lane_n,
    o_mfsl_clk,
    o_mfsl_write,
    o_mfsl_data,
    o_mfsl_control,
    i_mfsl_full,
    o_sfsl_clk,
    o_sfsl_read,
    i_sfsl_data,
    i_sfsl_control,
    i_sfsl_exists,
    o_dbg_tx,
    o_dbg_rx,
    o_dbg_tx_cnt,
    o_dbg_rx_cnt,
    o_dbg_last_rx,
    o_leds,
    i_opb_clk,
    i_opb_rst,
    i_opb_abus,
    i_opb_be,
    i_opb_dbus,
    i_opb_rnw,
    i_opb_select,
    i_opb_seqaddr,
    o_opb_dbus,
    o_opb_errack,
    o_opb_retry,
    o_opb_toutsup,
    o_opb_xferack
  );
  input i_clk_200mhz;
  input i_clk_1x;
  input i_clk_2x;
  input i_clk_2x_90deg;
  input i_rst_tx;
  input i_rst_rx;
  input i_rst_sys;
  input i_pll_locked;
  output o_rst;
  input [18:1] i_lane_p;
  input [18:1] i_lane_n;
  output [18:1] o_lane_p;
  output [18:1] o_lane_n;
  output o_mfsl_clk;
  output o_mfsl_write;
  output [0:63] o_mfsl_data;
  output o_mfsl_control;
  input i_mfsl_full;
  output o_sfsl_clk;
  output o_sfsl_read;
  input [0:63] i_sfsl_data;
  input i_sfsl_control;
  input i_sfsl_exists;
  output [0:31] o_dbg_tx;
  output [0:31] o_dbg_rx;
  output [0:31] o_dbg_tx_cnt;
  output [0:31] o_dbg_rx_cnt;
  output [0:64] o_dbg_last_rx;
  output [0:7] o_leds;
  input i_opb_clk;
  input i_opb_rst;
  input [0:31] i_opb_abus;
  input [0:3] i_opb_be;
  input [0:31] i_opb_dbus;
  input i_opb_rnw;
  input i_opb_select;
  input i_opb_seqaddr;
  output [0:31] o_opb_dbus;
  output o_opb_errack;
  output o_opb_retry;
  output o_opb_toutsup;
  output o_opb_xferack;

  m2_fsl_if
    #(
      .C_EXT_RESET_HIGH ( 1 ),
      .C_RESET_OUT_HIGH ( 1 ),
      .C_PLL_LOCKED_RST ( 1 ),
      .C_RX_CLKPAIR ( 5 ),
      .C_TX_CLKPAIR ( 9 ),
      .C_TX_POL ( 32'h00000000 ),
      .C_RX_LOCK_LOG_CTR ( 10 ),
      .C_RX_DTCT_CTR_1X ( 22 ),
      .C_RX_DTCT_CTR_200MHZ ( 22 ),
      .C_RX_DTCT_CTR_LOCK ( 8 ),
      .C_BASEADDR ( 32'hFFFFFFFF ),
      .C_HIGHADDR ( 32'h00000000 ),
      .C_OPB_AWIDTH ( 32 ),
      .C_OPB_DWIDTH ( 32 )
    )
    inst_m2_fsl_if_l1 (
      .i_clk_200mhz ( i_clk_200mhz ),
      .i_clk_1x ( i_clk_1x ),
      .i_clk_2x ( i_clk_2x ),
      .i_clk_2x_90deg ( i_clk_2x_90deg ),
      .i_rst_tx ( i_rst_tx ),
      .i_rst_rx ( i_rst_rx ),
      .i_rst_sys ( i_rst_sys ),
      .i_pll_locked ( i_pll_locked ),
      .o_rst ( o_rst ),
      .i_lane_p ( i_lane_p ),
      .i_lane_n ( i_lane_n ),
      .o_lane_p ( o_lane_p ),
      .o_lane_n ( o_lane_n ),
      .o_mfsl_clk ( o_mfsl_clk ),
      .o_mfsl_write ( o_mfsl_write ),
      .o_mfsl_data ( o_mfsl_data ),
      .o_mfsl_control ( o_mfsl_control ),
      .i_mfsl_full ( i_mfsl_full ),
      .o_sfsl_clk ( o_sfsl_clk ),
      .o_sfsl_read ( o_sfsl_read ),
      .i_sfsl_data ( i_sfsl_data ),
      .i_sfsl_control ( i_sfsl_control ),
      .i_sfsl_exists ( i_sfsl_exists ),
      .o_dbg_tx ( o_dbg_tx ),
      .o_dbg_rx ( o_dbg_rx ),
      .o_dbg_tx_cnt ( o_dbg_tx_cnt ),
      .o_dbg_rx_cnt ( o_dbg_rx_cnt ),
      .o_dbg_last_rx ( o_dbg_last_rx ),
      .o_leds ( o_leds ),
      .i_opb_clk ( i_opb_clk ),
      .i_opb_rst ( i_opb_rst ),
      .i_opb_abus ( i_opb_abus ),
      .i_opb_be ( i_opb_be ),
      .i_opb_dbus ( i_opb_dbus ),
      .i_opb_rnw ( i_opb_rnw ),
      .i_opb_select ( i_opb_select ),
      .i_opb_seqaddr ( i_opb_seqaddr ),
      .o_opb_dbus ( o_opb_dbus ),
      .o_opb_errack ( o_opb_errack ),
      .o_opb_retry ( o_opb_retry ),
      .o_opb_toutsup ( o_opb_toutsup ),
      .o_opb_xferack ( o_opb_xferack )
    );

endmodule

// synthesis attribute x_core_info of inst_m2_fsl_if_l1_wrapper is m2_fsl_if_v2_00_a;

