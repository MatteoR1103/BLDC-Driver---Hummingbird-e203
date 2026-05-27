// SPDX-License-Identifier: MIT
// Six-step output-compare generator used for static and PWM modes.

module bldc_output_compare (
    input         clk,
    input         tick_clk,
    input         reset,
    input         enable,
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
    reg [15:0] counter_u;
    reg [15:0] counter_v;
    reg [15:0] counter_w;
    reg [15:0] compare_a_q;
    reg [15:0] compare_b_q;
    reg [15:0] period_q;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            compare_a_q <= 16'd0;
            compare_b_q <= 16'd0;
            period_q <= 16'd0;
            start_v <= 1'b0;
            start_w <= 1'b0;
        end else begin
            if (counter_u == 16'd0) begin
                period_q <= period;
            end

            compare_a_q <= compare_a;
            compare_b_q <= compare_b;

            if ((compare_b_q == (counter_u + 16'd1)) && enable && (counter_u != 16'd0)) begin
                start_v <= 1'b1;
            end else if (!enable || (counter_v > period_q)) begin
                start_v <= 1'b0;
            end

            if ((compare_b_q == (counter_v + 16'd1)) && enable && (counter_v != 16'd0)) begin
                start_w <= 1'b1;
            end else if (!enable || (counter_w > period_q)) begin
                start_w <= 1'b0;
            end
        end
    end

    always @(posedge tick_clk or posedge reset) begin
        if (reset) begin
            counter_u <= 16'd0;
            counter_v <= 16'd0;
            counter_w <= 16'd0;
            {hs_u, ls_u, hs_v, ls_v, hs_w, ls_w} <= 6'b0;
        end else begin
            if (!enable || (counter_u == (period_q - 16'd1))) begin
                counter_u <= 16'd0;
            end else begin
                counter_u <= counter_u + 16'd1;
            end

            if (start_v && (counter_v != (period_q - 16'd1))) begin
                counter_v <= counter_v + 16'd1;
            end else begin
                counter_v <= 16'd0;
            end

            if (start_w && (counter_w != (period_q - 16'd1))) begin
                counter_w <= counter_w + 16'd1;
            end else begin
                counter_w <= 16'd0;
            end

            hs_u <= !reset && (deadzone <= counter_u) &&
                    ((compare_a_q - deadzone) >= counter_u) &&
                    (compare_a_q >= (2 * deadzone));
            hs_v <= !reset && (deadzone <= counter_v) &&
                    ((compare_a_q - deadzone) >= counter_v) &&
                    (compare_a_q >= (2 * deadzone));
            hs_w <= !reset && (deadzone <= counter_w) &&
                    ((compare_a_q - deadzone) >= counter_w) &&
                    (compare_a_q >= (2 * deadzone));

            ls_v <= !reset && (
                ((counter_u <= (compare_a_q >> 1)) || (counter_w <= compare_a_q)) &&
                (counter_w >= (compare_a_q >> 1)) ||
                (counter_u <= (compare_a_q >> 1) && !start_v && !start_w)
            );
            ls_w <= !reset &&
                ((counter_v <= (compare_a_q >> 1)) || (counter_u <= compare_a_q)) &&
                (counter_u >= (compare_a_q >> 1));
            ls_u <= !reset &&
                ((counter_w <= (compare_a_q >> 1)) || (counter_v <= compare_a_q)) &&
                (counter_v >= (compare_a_q >> 1));
        end
    end

endmodule
