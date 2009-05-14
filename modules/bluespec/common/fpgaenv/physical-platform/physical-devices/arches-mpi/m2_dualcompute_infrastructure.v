/****************************************************************************/
/* m2_dualcompute_infrastructure.v                                          */
/* ===============================                                          */
/* apatel                                                                   */
/* 07/23/2008                                                               */
/*                                                                          */
/* This module sets users of the M2 Dual Compute boards up with a default   */
/* platform that ties all unused interfaces off to benign states and proper */
/* I/O standards.                                                           */
/*                                                                          */
/****************************************************************************/

module m2_dualcompute_infrastructure
(
    input           i_fpga_clk0_p,
    input           i_fpga_clk0_n,
    output          o_fpga_clk0_raw,
    output          o_fpga_clk0_bufg,

    input           i_fpga_clk1_p,
    input           i_fpga_clk1_n,
    output          o_fpga_clk1_raw,
    output          o_fpga_clk1_bufg,

    input           i_fpga_clk100_p,
    input           i_fpga_clk100_n,
    output          o_fpga_clk100_raw,
    output          o_fpga_clk100_bufg,

    output          o_fpga_led0_z,
    output          o_fpga_led1_z,
    output          o_fpga_led2_z,
    output          o_fpga_led3_z,
    output          o_ram0_led_z,
    output          o_ram1_led_z,
    output          o_fpga_temp_led_z,
    output          o_fpga_hot_led_z,

    input           b_fpga_scl_I,
    output          b_fpga_scl_O,
    output          b_fpga_scl_T,

    input           b_fpga_sda_I,
    output          b_fpga_sda_O,
    output          b_fpga_sda_T,

    input           i_fpga_reg_en_z,
    input           i_fpga_reg_ads_z,
    input           i_fpga_reg_uds_z,
    input           i_fpga_reg_lds_z,
    input           i_fpga_reg_reset_z,
    input           i_fpga_reg_rd_wr_z,
    output          o_fpga_reg_clk,
    output          o_fpga_intr,
    output          o_fpga_reg_rdy_z,
    input           i_fpga_config_data,

    input           b_ram_pwr_on_I,
    output          b_ram_pwr_on_O,
    output          b_ram_pwr_on_T,

    input   [31: 0] b_ram0_dq_I,
    output  [31: 0] b_ram0_dq_O,
    output  [31: 0] b_ram0_dq_T,
    input   [ 3: 0] b_ram0_dq_p_I,
    output  [ 3: 0] b_ram0_dq_p_O,
    output  [ 3: 0] b_ram0_dq_p_T,
    input           i_ram0_cq,
    input           i_ram0_cq_n,
    output          o_ram0_ld_n,
    output          o_ram0_rw_n,
    output          o_ram0_dll_off_n,
    output          o_ram0_k,
    output          o_ram0_k_n,
    input   [21: 0] b_ram0_addr_I,
    output  [21: 0] b_ram0_addr_O,
    output  [21: 0] b_ram0_addr_T,
    input   [ 3: 0] b_ram0_bw_n_I,
    output  [ 3: 0] b_ram0_bw_n_O,
    output  [ 3: 0] b_ram0_bw_n_T,
    input           i_ram0_mbank_sel,

    input   [31: 0] b_ram1_dq_I,
    output  [31: 0] b_ram1_dq_O,
    output  [31: 0] b_ram1_dq_T,
    input   [ 3: 0] b_ram1_dq_p_I,
    output  [ 3: 0] b_ram1_dq_p_O,
    output  [ 3: 0] b_ram1_dq_p_T,
    input           i_ram1_cq,
    input           i_ram1_cq_n,
    output          o_ram1_ld_n,
    output          o_ram1_rw_n,
    output          o_ram1_dll_off_n,
    output          o_ram1_k,
    output          o_ram1_k_n,
    input   [21: 0] b_ram1_addr_I,
    output  [21: 0] b_ram1_addr_O,
    output  [21: 0] b_ram1_addr_T,
    input   [ 3: 0] b_ram1_bw_n_I,
    output  [ 3: 0] b_ram1_bw_n_O,
    output  [ 3: 0] b_ram1_bw_n_T,
    input           i_ram1_mbank_sel,

    input   [ 0: 7] i_led_override
);


    /* Parameters ***********************************************************/
    parameter C_FPGA_ID         = 0;
    parameter C_TERM_CLK0       = 0;
    parameter C_TERM_CLK1       = 0;
    parameter C_TERM_CLK100     = 0;

    parameter C_BUFG_CLK0       = 0;
    parameter C_BUFG_CLK1       = 0;
    parameter C_BUFG_CLK100     = 0;

    parameter C_TERM_LEDS       = 0;

    parameter C_TERM_I2C        = 0;

    parameter C_TERM_EXPBUS     = 0;

    parameter C_TERM_RAM0       = 0;
    parameter C_TERM_RAM1       = 0;

    parameter C_LD_LANE_WIDTH = 18;
    parameter C_UD_LANE_WIDTH = 18;
    parameter C_AD_LANE_WIDTH = 19;


    /* Registers and Interconnect *******************************************/
    wire                            w_net_gnd;
    wire                            w_net_vcc;

    wire                            w_tristate_fds_q;

    wire                            w_pulse_gnd;
    wire                            w_pulse_vcc;

    wire                            w_fpga_clk0;
    wire                            w_fpga_clk1;
    wire                            w_fpga_clk100;

    wire                            w_bufg_clk0;
    wire                            w_bufg_clk1;
    wire                            w_bufg_clk100;

    wire                            w_ram0_oddr_qp;
    wire                            w_ram0_oddr_d1p;
    wire                            w_ram0_oddr_d2p;

    wire                            w_ram0_oddr_qn;
    wire                            w_ram0_oddr_d1n;
    wire                            w_ram0_oddr_d2n;

    wire                            w_ram1_oddr_qp;
    wire                            w_ram1_oddr_d1p;
    wire                            w_ram1_oddr_d2p;

    wire                            w_ram1_oddr_qn;
    wire                            w_ram1_oddr_d1n;
    wire                            w_ram1_oddr_d2n;

    wire                            w_ibuf_ram1_echoclk_op;
    wire                            w_ibuf_ram1_echoclk_on;


    // IDELAYCTRL element used for IDELAY element
    wire                            w_idelayctrl_rdy;
    wire                            w_idelayctrl_rst;

    // Bit-Slip Control
    wire                            w_lane_ld0_bs;
    wire                            w_lane_ld1_bs;
    wire                            w_lane_ld2_bs;
    wire                            w_lane_ld3_bs;
    wire                            w_lane_ld4_bs;

    wire                            w_lane_ud0_bs;
    wire                            w_lane_ud1_bs;
    wire                            w_lane_ud2_bs;
    wire                            w_lane_ud3_bs;
    wire                            w_lane_ud4_bs;

    wire                            w_lane_ad0_bs;
    wire                            w_lane_ad1_bs;
    wire                            w_lane_ad2_bs;
    wire                            w_lane_ad3_bs;
    wire                            w_lane_ad4_bs;

    genvar                          g;

    /* Assignments **********************************************************/
    assign w_net_gnd = 1'b0;
    assign w_net_vcc = 1'b1;

    assign w_pulse_gnd = w_tristate_fds_q;
    assign w_pulse_vcc = ~w_tristate_fds_q;

    // RAM Clock states
    assign w_ram0_oddr_d1p = w_pulse_vcc;
    assign w_ram0_oddr_d2p = w_pulse_gnd;
    assign w_ram0_oddr_d1n = w_pulse_gnd;
    assign w_ram0_oddr_d2n = w_pulse_vcc;

    assign w_ram1_oddr_d1p = w_pulse_vcc;
    assign w_ram1_oddr_d2p = w_pulse_gnd;
    assign w_ram1_oddr_d1n = w_pulse_gnd;
    assign w_ram1_oddr_d2n = w_pulse_vcc;

    /* Output Assignments ***************************************************/
    // Clock Outputs
    assign o_fpga_clk0_raw = (C_TERM_CLK0 == 1) ? w_fpga_clk0 : 1'b0;
    assign o_fpga_clk1_raw = (C_TERM_CLK1 == 1) ? w_fpga_clk1 : 1'b0;
    assign o_fpga_clk100_raw = (C_TERM_CLK100 == 1) ? w_fpga_clk100 : 1'b0;

    assign o_fpga_clk0_bufg = (C_BUFG_CLK0 == 1) ? w_bufg_clk0 : 1'b0;
    assign o_fpga_clk1_bufg = (C_BUFG_CLK1 == 1) ? w_bufg_clk1 : 1'b0;
    assign o_fpga_clk100_bufg = (C_BUFG_CLK100 == 1) ? w_bufg_clk100 : 1'b0;

    // LED Termination
    generate
        if (C_TERM_LEDS == 1)
        begin : gen_term_leds
            assign o_fpga_led0_z = 1'b0;
            assign o_fpga_led1_z = 1'b0;
            assign o_fpga_led2_z = 1'b0;
            assign o_fpga_led3_z = 1'b0;

            // RAM LEDs are off if the DDR termination is active
            assign o_ram0_led_z = (C_TERM_RAM0 == 1) ? 1'b1 : 1'b0;
            assign o_ram1_led_z = (C_TERM_RAM1 == 1) ? 1'b1 : 1'b0;

            // Turn on the temp and hot leds just in case.
            assign o_fpga_temp_led_z = 1'b0;
            assign o_fpga_hot_led_z  = 1'b0;
        end
        else
        begin : gen_noterm_leds
            if (C_FPGA_ID == 0)
            begin : gen_noterm_leds_f0
                assign o_fpga_temp_led_z = ~i_led_override[0];
                assign o_ram1_led_z      = ~i_led_override[1];
                assign o_fpga_hot_led_z  = ~i_led_override[2];
                assign o_ram0_led_z      = ~i_led_override[3];
                assign o_fpga_led0_z     = ~i_led_override[4];
                assign o_fpga_led1_z     = ~i_led_override[5];
                assign o_fpga_led2_z     = ~i_led_override[6];
                assign o_fpga_led3_z     = ~i_led_override[7];
            end
            else
            begin : gen_noterm_leds_f1
                assign o_fpga_temp_led_z = ~i_led_override[0];
                assign o_ram1_led_z      = ~i_led_override[1];
                assign o_fpga_hot_led_z  = ~i_led_override[2];
                assign o_ram0_led_z      = ~i_led_override[3];
                assign o_fpga_led0_z     = ~i_led_override[4];
                assign o_fpga_led1_z     = ~i_led_override[5];
                assign o_fpga_led2_z     = ~i_led_override[6];
                assign o_fpga_led3_z     = ~i_led_override[7];
            end
        end
    endgenerate

    // C_TERM_I2C
    assign b_fpga_scl_O = 1'b0;
    assign b_fpga_scl_T = 1'b0;

    assign b_fpga_sda_O = 1'b1;
    assign b_fpga_sda_T = 1'b0;

    // C_TERM_EXPBUS
    assign o_fpga_reg_clk = 1'b0;
    assign o_fpga_intr = 1'b0;
    assign o_fpga_reg_rdy_z = 1'b1;

    // C_TERM_RAM0 (non-I/O Buf signals)
    assign b_ram0_dq_O[31:0]    = {32{w_pulse_gnd}};
    assign b_ram0_dq_T[31:0]    = {32{w_pulse_vcc}};
    assign b_ram0_dq_p_O[3:0]   = {4{w_pulse_gnd}};
    assign b_ram0_dq_p_T[3:0]   = {4{w_pulse_vcc}};
    assign o_ram0_ld_n          = w_pulse_vcc;
    assign o_ram0_rw_n          = w_pulse_gnd;
    assign o_ram0_dll_off_n     = (C_TERM_RAM0==1) ? 1'b0 : 1'b1; // 0=DLL_OFF
    assign o_ram0_k             = w_ram0_oddr_qp;
    assign o_ram0_k_n           = w_ram0_oddr_qn;
    assign b_ram0_addr_O[21:0]  = {22{w_pulse_gnd}};
    assign b_ram0_addr_T[21:0]  = {22{w_pulse_vcc}};
    assign b_ram0_bw_n_O[3:0]   = {4{w_pulse_vcc}};
    assign b_ram0_bw_n_T[3:0]   = {4{w_pulse_vcc}};

    assign b_ram1_dq_O[31:0]    = {32{w_pulse_gnd}};
    assign b_ram1_dq_T[31:0]    = {32{w_pulse_vcc}};
    assign b_ram1_dq_p_O[3:0]   = {4{w_pulse_gnd}};
    assign b_ram1_dq_p_T[3:0]   = {4{w_pulse_vcc}};
    assign o_ram1_ld_n          = w_pulse_vcc;
    assign o_ram1_rw_n          = w_pulse_gnd;
    assign o_ram1_dll_off_n     = (C_TERM_RAM1==1) ? 1'b0 : 1'b1; // 0=DLL_OFF
    assign o_ram1_k             = w_ram1_oddr_qp;
    assign o_ram1_k_n           = w_ram1_oddr_qn;
    assign b_ram1_addr_O[21:0]  = {22{w_pulse_gnd}};
    assign b_ram1_addr_T[21:0]  = {22{w_pulse_vcc}};
    assign b_ram1_bw_n_O[3:0]   = {4{w_pulse_vcc}};
    assign b_ram1_bw_n_T[3:0]   = {4{w_pulse_vcc}};

    // RAM Power Activation Signal
    // The issue with this signal is that both FPGAs can drive it, and
    // the winner must be able to enable power and provide 5uA of pull-up
    // current.  So, if one is not using the device, go to tri-state mode, and
    // if they are using the device, drive the signal > 0.8V.  But never drive
    // it low since we don't know what the other FPGA is doing.
    assign b_ram_pwr_on_O = 1'b1; // If used
    assign b_ram_pwr_on_T = ((C_TERM_RAM0==0)||(C_TERM_RAM1==0)) ? 1'b0:1'b1;


    /* Module Instantiations ************************************************/
    //  The FDS primitive outputs high during GSR and then takes on D.
    FDS inst_tristate_fds
    (
        .D(w_net_gnd),
        .C(w_bufg_clk100),
        .Q(w_tristate_fds_q),
        .S(w_net_gnd)
    );

/* Processes ****************************************************************/

// C_TERM_CLK0
generate
    if (C_TERM_CLK0 == 1)
    begin : gen_has_clk0
        IBUFDS
        #(
            .DIFF_TERM("TRUE"),
            .IOSTANDARD("LVDS_25")
         )
        ibufds_clk0
        (
            .I(i_fpga_clk0_p),
            .IB(i_fpga_clk0_n),
            .O(w_fpga_clk0)
        );
    end
endgenerate

// C_TERM_CLK1
generate
    if (C_TERM_CLK1 == 1)
    begin : gen_has_clk1
        IBUFDS
        #(
            .DIFF_TERM("TRUE"),
            .IOSTANDARD("LVDS_25")
         )
        ibufds_clk1
        (
            .I(i_fpga_clk1_p),
            .IB(i_fpga_clk1_n),
            .O(w_fpga_clk1)
        );
    end
endgenerate

// C_TERM_CLK100
generate
    if (C_TERM_CLK100 == 1)
    begin : gen_has_clk100
        IBUFDS
        #(
            .DIFF_TERM("TRUE"),
            .IOSTANDARD("LVDS_25")
         )
        ibufds_clk100
        (
            .I(i_fpga_clk100_p),
            .IB(i_fpga_clk100_n),
            .O(w_fpga_clk100)
        );
    end
endgenerate


// C_BUFG_CLK0
generate
    if (C_BUFG_CLK0 == 1)
    begin : gen_has_bufg0
        BUFG bufg_clk0
        (
            .I(w_fpga_clk0),
            .O(w_bufg_clk0)
        );
    end
endgenerate

// C_BUFG_CLK1
generate
    if (C_BUFG_CLK1 == 1)
    begin : gen_has_bufg1
        BUFG bufg_clk1
        (
            .I(w_fpga_clk1),
            .O(w_bufg_clk1)
        );
    end
endgenerate

// C_BUFG_CLK100
generate
    if (C_BUFG_CLK100 == 1)
    begin : gen_has_bufg100
        BUFG bufg_clk100
        (
            .I(w_fpga_clk100),
            .O(w_bufg_clk100)
        );
    end
endgenerate

// C_TERM_RAM0
generate
    if (C_TERM_RAM0 == 1)
    begin : gen_term_ram0
        ODDR
        #(
            .DDR_CLK_EDGE("OPPOSITE_EDGE"),
            .INIT(0),
            .SRTYPE("SYNC")
         )
        inst_ram0_oddr_p
        (
            .Q(w_ram0_oddr_qp),
            .C(w_bufg_clk100),
            .CE(w_net_vcc),
            .D1(w_ram0_oddr_d1p),
            .D2(w_ram0_oddr_d2p),
            .R(w_net_gnd),
            .S(w_net_gnd)
        );

        ODDR
        #(
            .DDR_CLK_EDGE("OPPOSITE_EDGE"),
            .INIT(1),
            .SRTYPE("SYNC")
         )
        inst_ram0_oddr_n
        (
            .Q(w_ram0_oddr_qn),
            .C(w_bufg_clk100),
            .CE(w_net_vcc),
            .D1(w_ram0_oddr_d1n),
            .D2(w_ram0_oddr_d2n),
            .R(w_net_gnd),
            .S(w_net_gnd)
        );

    end
endgenerate

// C_TERM_RAM1
generate
    if (C_TERM_RAM1 == 1)
    begin : gen_term_ram1
        ODDR
        #(
            .DDR_CLK_EDGE("OPPOSITE_EDGE"),
            .INIT(0),
            .SRTYPE("SYNC")
         )
        inst_ram1_oddr_p
        (
            .Q(w_ram1_oddr_qp),
            .C(w_bufg_clk100),
            .CE(w_net_vcc),
            .D1(w_ram1_oddr_d1p),
            .D2(w_ram1_oddr_d2p),
            .R(w_net_gnd),
            .S(w_net_gnd)
        );

        ODDR
        #(
            .DDR_CLK_EDGE("OPPOSITE_EDGE"),
            .INIT(1),
            .SRTYPE("SYNC")
         )
        inst_ram1_oddr_n
        (
            .Q(w_ram1_oddr_qn),
            .C(w_bufg_clk100),
            .CE(w_net_vcc),
            .D1(w_ram1_oddr_d1n),
            .D2(w_ram1_oddr_d2n),
            .R(w_net_gnd),
            .S(w_net_gnd)
        );
    end
endgenerate

/****************************************************************************/



/*************************** SIMULATION AIDS ********************************/
// synopsys translate_off
// synopsys translate_on
/****************************************************************************/

endmodule
/****************************************************************************/


