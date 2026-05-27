// SPDX-License-Identifier: MIT
// Sine-modulated PWM generator for the three BLDC phases.

module bldc_sine_pwm #(
    parameter integer ROM_WIDTH = 8
) (
    input         clk,
    input         tick_clk,
    input         reset,
    input         enable,
    input  [2 * ROM_WIDTH - 1:0] data_u,
    input  [2 * ROM_WIDTH - 1:0] data_v,
    input  [2 * ROM_WIDTH - 1:0] data_w,
    input  [15:0] counter_u,
    input  [15:0] period,
    input  [3:0]  deadzone,
    input  [15:0] compare_a,
    input  [15:0] compare_b,
    output reg    hs_u,
    output reg    ls_u,
    output reg    hs_v,
    output reg    ls_v,
    output reg    hs_w,
    output reg    ls_w
);

    reg        start_v;
    reg        start_w;
    reg [15:0] counter_v;
    reg [15:0] counter_w;
    reg [15:0] compare_u_q;
    reg [15:0] compare_v_q;
    reg [15:0] compare_w_q;
    reg [15:0] compare_b_q;
    reg [31:0] product_u;
    reg [31:0] product_v;
    reg [31:0] product_w;

    wire [31:0] product_u_next =
        {16'd0, compare_a} * {{(32 - ROM_WIDTH){1'b0}}, data_u[ROM_WIDTH-1:0]};
    wire [31:0] product_v_next =
        {16'd0, compare_a} * {{(32 - ROM_WIDTH){1'b0}}, data_v[ROM_WIDTH-1:0]};
    wire [31:0] product_w_next =
        {16'd0, compare_a} * {{(32 - ROM_WIDTH){1'b0}}, data_w[ROM_WIDTH-1:0]};

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            compare_u_q <= 16'd0;
            compare_v_q <= 16'd0;
            compare_w_q <= 16'd0;
            compare_b_q <= 16'd0;
            product_u <= 32'd0;
            product_v <= 32'd0;
            product_w <= 32'd0;
        end else if (counter_u == 16'd0) begin
            product_u <= product_u_next;
            product_v <= product_v_next;
            product_w <= product_w_next;

            compare_u_q <= data_u[ROM_WIDTH] ? compare_a : product_u_next[23:8];
            compare_v_q <= data_v[ROM_WIDTH] ? compare_a : product_v_next[23:8];
            compare_w_q <= data_w[ROM_WIDTH] ? compare_a : product_w_next[23:8];
            compare_b_q <= compare_b;
        end
    end

    always @(posedge tick_clk or posedge reset) begin
        if (reset) begin
            start_v <= 1'b0;
            start_w <= 1'b0;
            counter_v <= 16'd0;
            counter_w <= 16'd0;
            {hs_u, ls_u, hs_v, ls_v, hs_w, ls_w} <= 6'b0;
        end else begin
            if ((compare_b_q - 16'd1 == counter_u) && enable && (counter_u != 16'd0)) begin
                start_v <= 1'b1;
            end else if (!enable || (counter_v > period)) begin
                start_v <= 1'b0;
            end

            if ((compare_b_q - 16'd1 == counter_v) && enable && (counter_v != 16'd0)) begin
                start_w <= 1'b1;
            end else if (!enable || (counter_w > period)) begin
                start_w <= 1'b0;
            end

            if (start_v && (counter_v != period)) begin
                counter_v <= counter_v + 16'd1;
            end else begin
                counter_v <= 16'd0;
            end

            if (start_w && (counter_w != period)) begin
                counter_w <= counter_w + 16'd1;
            end else begin
                counter_w <= 16'd0;
            end

            hs_u <= !reset && (deadzone <= counter_u) &&
                    ((compare_u_q - deadzone) >= counter_u) &&
                    (compare_u_q >= (2 * deadzone));
            hs_v <= !reset && (deadzone <= counter_v) &&
                    ((compare_v_q - deadzone) >= counter_v) &&
                    (compare_v_q >= (2 * deadzone));
            hs_w <= !reset && (deadzone <= counter_w) &&
                    ((compare_w_q - deadzone) >= counter_w) &&
                    (compare_w_q >= (2 * deadzone));

            ls_v <= !reset && (
                ((counter_u <= (compare_u_q >> 1)) || (counter_w <= compare_w_q)) &&
                (counter_w >= (compare_w_q >> 1)) ||
                (counter_u <= (compare_u_q >> 1) && !start_v && !start_w)
            );
            ls_w <= !reset &&
                ((counter_v <= (compare_v_q >> 1)) || (counter_u <= compare_u_q)) &&
                (counter_u >= (compare_u_q >> 1));
            ls_u <= !reset &&
                ((counter_w <= (compare_w_q >> 1)) || (counter_v <= compare_v_q)) &&
                (counter_v >= (compare_v_q >> 1));
        end
    end

endmodule
