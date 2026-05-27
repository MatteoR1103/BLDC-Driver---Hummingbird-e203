// SPDX-License-Identifier: MIT
// BLDC motor driver peripheral for the Hummingbird E203 ICB bus.
//
// Public contract:
//   - register block at offsets 0x000 and 0x004
//   - six GPIO outputs for the H-bridge driver
//   - active-high BREAK input: 1 = run allowed, 0 = brake

module BLDC_driver #(
    parameter [15:0] DEFAULT_PERIOD   = 16'd0,
    parameter [3:0]  DEFAULT_DEADZONE = 4'd0,
    parameter integer SLOW_DIVIDER    = 400,
    parameter integer ROM_DEPTH       = 16,
    parameter integer ROM_WIDTH       = 8,
    parameter ROM_FILE                = "hardware/rtl/bldc/sine_LUT_table.mem",
    parameter USE_GOWIN_PROM          = 1'b1
) (
    input                   clk,
    input                   rst_n,

    input                   i_icb_cmd_valid,
    output                  i_icb_cmd_ready,
    input  [31:0]           i_icb_cmd_addr,
    input                   i_icb_cmd_read,
    input  [31:0]           i_icb_cmd_wdata,

    output                  i_icb_rsp_valid,
    input                   i_icb_rsp_ready,
    output [31:0]           i_icb_rsp_rdata,

    output                  io_pad_out_0,      // HS_U
    output                  io_pad_out_1,      // LS_U
    output                  io_pad_out_2,      // HS_V
    output                  io_pad_out_3,      // LS_V
    output                  io_pad_out_4,      // HS_W
    output                  io_pad_out_5,      // LS_W

    input                   io_pad_in_BREAK,
    input                   io_pad_in_HAL_A,
    input                   io_pad_in_HAL_B,
    input                   io_pad_in_HAL_C
);

    localparam [1:0] MODE_OC       = 2'b00;
    localparam [1:0] MODE_PWM      = 2'b01;
    localparam [1:0] MODE_PWM_SINE = 2'b10;
    localparam integer SINE_ADDRW  = $clog2(4 * ROM_DEPTH);

    wire        reset = ~rst_n;
    wire        break_n = io_pad_in_BREAK;

    wire [31:0] cfg_reg;
    wire [31:0] time_reg;

    wire        enable    = cfg_reg[0];
    wire [1:0]  mode      = cfg_reg[3:2];
    wire        direction = cfg_reg[4];
    wire [3:0]  deadzone  = cfg_reg[15:12];
    wire [15:0] period    = cfg_reg[31:16];
    wire [15:0] time_1    = time_reg[15:0];
    wire [15:0] time_2    = time_reg[31:16];

    wire slow_clk;
    wire hs_u_oc, hs_v_oc, hs_w_oc;
    wire ls_u_oc, ls_v_oc, ls_w_oc;
    wire hs_u_sine, hs_v_sine, hs_w_sine;
    wire ls_u_sine, ls_v_sine, ls_w_sine;

    reg [15:0] compare_a;
    reg [15:0] compare_b;
    reg        hs_u_pin;
    reg        hs_v_pin;
    reg        hs_w_pin;
    reg        ls_u_pin;
    reg        ls_v_pin;
    reg        ls_w_pin;

    reg [SINE_ADDRW-1:0] sine_id_u;
    reg [SINE_ADDRW-1:0] sine_id_v;
    reg [SINE_ADDRW-1:0] sine_id_w;
    reg [15:0]           sine_counter_u;
    reg [15:0]           sine_period_latched;

    wire [2 * ROM_WIDTH - 1:0] sine_data_u;
    wire [2 * ROM_WIDTH - 1:0] sine_data_v;
    wire [2 * ROM_WIDTH - 1:0] sine_data_w;

    bldc_icb_regs #(
        .DEFAULT_PERIOD(DEFAULT_PERIOD),
        .DEFAULT_DEADZONE(DEFAULT_DEADZONE)
    ) u_regs (
        .clk(clk),
        .rst_n(rst_n),
        .break_n(break_n),
        .hall_a(io_pad_in_HAL_A),
        .hall_b(io_pad_in_HAL_B),
        .hall_c(io_pad_in_HAL_C),
        .i_icb_cmd_valid(i_icb_cmd_valid),
        .i_icb_cmd_ready(i_icb_cmd_ready),
        .i_icb_cmd_addr(i_icb_cmd_addr),
        .i_icb_cmd_read(i_icb_cmd_read),
        .i_icb_cmd_wdata(i_icb_cmd_wdata),
        .i_icb_rsp_valid(i_icb_rsp_valid),
        .i_icb_rsp_ready(i_icb_rsp_ready),
        .i_icb_rsp_rdata(i_icb_rsp_rdata),
        .cfg_reg(cfg_reg),
        .time_reg(time_reg)
    );

    bldc_clock_divider #(
        .DIVIDE_COUNT(SLOW_DIVIDER)
    ) u_slow_tick (
        .clk(clk),
        .rst_n(rst_n),
        .clk_out(slow_clk)
    );

    always @(posedge slow_clk or posedge reset) begin
        if (reset) begin
            sine_counter_u <= 16'd0;
            sine_period_latched <= 16'd0;
        end else begin
            sine_period_latched <= period;

            if (!enable || (sine_counter_u == sine_period_latched)) begin
                sine_counter_u <= 16'd0;
            end else begin
                sine_counter_u <= sine_counter_u + 16'd1;
            end
        end
    end

    always @(posedge slow_clk or posedge reset) begin
        if (reset) begin
            sine_id_u <= {SINE_ADDRW{1'b0}};
            sine_id_v <= ROM_DEPTH + (ROM_DEPTH / 3);
            sine_id_w <= 2 * (ROM_DEPTH + (ROM_DEPTH / 3));
        end else if (enable && (sine_counter_u == sine_period_latched)) begin
            sine_id_u <= (sine_id_u == (4 * ROM_DEPTH - 1)) ? {SINE_ADDRW{1'b0}} : sine_id_u + 1'b1;
            sine_id_v <= (sine_id_v == (4 * ROM_DEPTH - 1)) ? {SINE_ADDRW{1'b0}} : sine_id_v + 1'b1;
            sine_id_w <= (sine_id_w == (4 * ROM_DEPTH - 1)) ? {SINE_ADDRW{1'b0}} : sine_id_w + 1'b1;
        end
    end

    bldc_sine_phase #(
        .ROM_DEPTH(ROM_DEPTH),
        .ROM_WIDTH(ROM_WIDTH),
        .ROM_FILE(ROM_FILE),
        .USE_GOWIN_PROM(USE_GOWIN_PROM)
    ) u_phase (
        .clk(clk),
        .id(sine_id_u),
        .data(sine_data_u)
    );

    bldc_sine_phase #(
        .ROM_DEPTH(ROM_DEPTH),
        .ROM_WIDTH(ROM_WIDTH),
        .ROM_FILE(ROM_FILE),
        .USE_GOWIN_PROM(USE_GOWIN_PROM)
    ) v_phase (
        .clk(clk),
        .id(sine_id_v),
        .data(sine_data_v)
    );

    bldc_sine_phase #(
        .ROM_DEPTH(ROM_DEPTH),
        .ROM_WIDTH(ROM_WIDTH),
        .ROM_FILE(ROM_FILE),
        .USE_GOWIN_PROM(USE_GOWIN_PROM)
    ) w_phase (
        .clk(clk),
        .id(sine_id_w),
        .data(sine_data_w)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            compare_a <= 16'd0;
            compare_b <= 16'd0;
            hs_u_pin <= 1'b0;
            hs_v_pin <= 1'b0;
            hs_w_pin <= 1'b0;
            ls_u_pin <= 1'b0;
            ls_v_pin <= 1'b0;
            ls_w_pin <= 1'b0;
        end else begin
            case (mode)
                MODE_OC: begin
                    compare_a <= time_2;
                    compare_b <= time_2;
                    if (!direction) begin
                        {hs_u_pin, ls_u_pin, hs_v_pin, ls_v_pin, hs_w_pin, ls_w_pin} <=
                            {hs_u_oc, ls_u_oc, hs_v_oc, ls_v_oc, hs_w_oc, ls_w_oc};
                    end else begin
                        {hs_u_pin, ls_u_pin, hs_v_pin, ls_v_pin, hs_w_pin, ls_w_pin} <=
                            {hs_w_oc, ls_w_oc, hs_v_oc, ls_v_oc, hs_u_oc, ls_u_oc};
                    end
                end

                MODE_PWM: begin
                    compare_a <= time_1;
                    compare_b <= time_2;
                    if (!direction) begin
                        {hs_u_pin, ls_u_pin, hs_v_pin, ls_v_pin, hs_w_pin, ls_w_pin} <=
                            {hs_u_oc, ls_u_oc, hs_v_oc, ls_v_oc, hs_w_oc, ls_w_oc};
                    end else begin
                        {hs_u_pin, ls_u_pin, hs_v_pin, ls_v_pin, hs_w_pin, ls_w_pin} <=
                            {hs_w_oc, ls_w_oc, hs_v_oc, ls_v_oc, hs_u_oc, ls_u_oc};
                    end
                end

                MODE_PWM_SINE: begin
                    compare_a <= time_2;
                    compare_b <= time_2;
                    if (!direction) begin
                        {hs_u_pin, ls_u_pin, hs_v_pin, ls_v_pin, hs_w_pin, ls_w_pin} <=
                            {hs_u_sine, ls_u_sine, hs_v_sine, ls_v_sine, hs_w_sine, ls_w_sine};
                    end else begin
                        {hs_u_pin, ls_u_pin, hs_v_pin, ls_v_pin, hs_w_pin, ls_w_pin} <=
                            {hs_w_sine, ls_w_sine, hs_v_sine, ls_v_sine, hs_u_sine, ls_u_sine};
                    end
                end

                default: begin
                    compare_a <= 16'd0;
                    compare_b <= 16'd0;
                    {hs_u_pin, ls_u_pin, hs_v_pin, ls_v_pin, hs_w_pin, ls_w_pin} <= 6'b0;
                end
            endcase
        end
    end

    bldc_output_compare u_output_compare (
        .clk(clk),
        .tick_clk(slow_clk),
        .reset(reset),
        .enable(enable),
        .period(period),
        .deadzone(deadzone),
        .compare_a(compare_a),
        .compare_b(compare_b),
        .hs_u(hs_u_oc),
        .ls_u(ls_u_oc),
        .hs_v(hs_v_oc),
        .ls_v(ls_v_oc),
        .hs_w(hs_w_oc),
        .ls_w(ls_w_oc)
    );

    bldc_sine_pwm #(
        .ROM_WIDTH(ROM_WIDTH)
    ) u_sine_pwm (
        .clk(clk),
        .tick_clk(slow_clk),
        .reset(reset),
        .enable(enable),
        .data_u(sine_data_u),
        .data_v(sine_data_v),
        .data_w(sine_data_w),
        .counter_u(sine_counter_u),
        .period(sine_period_latched),
        .deadzone(deadzone),
        .compare_a(compare_a),
        .compare_b(compare_b),
        .hs_u(hs_u_sine),
        .ls_u(ls_u_sine),
        .hs_v(hs_v_sine),
        .ls_v(ls_v_sine),
        .hs_w(hs_w_sine),
        .ls_w(ls_w_sine)
    );

    assign io_pad_out_0 = enable && break_n && rst_n && !ls_u_pin && hs_u_pin;
    assign io_pad_out_2 = enable && break_n && rst_n && !ls_v_pin && hs_v_pin;
    assign io_pad_out_4 = enable && break_n && rst_n && !ls_w_pin && hs_w_pin;

    assign io_pad_out_1 = !break_n || (enable && rst_n && !hs_u_pin && ls_u_pin);
    assign io_pad_out_3 = !break_n || (enable && rst_n && !hs_v_pin && ls_v_pin);
    assign io_pad_out_5 = !break_n || (enable && rst_n && !hs_w_pin && ls_w_pin);

endmodule
