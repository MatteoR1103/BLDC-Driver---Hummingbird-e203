// SPDX-License-Identifier: MIT
// Produces the motor-control tick clock from the SoC peripheral clock.

module bldc_clock_divider #(
    parameter integer DIVIDE_COUNT = 400
) (
    input  clk,
    input  rst_n,
    output reg clk_out
);

    reg [15:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 16'd0;
            clk_out <= 1'b0;
        end else if (count == (DIVIDE_COUNT - 1)) begin
            count <= 16'd0;
            clk_out <= ~clk_out;
        end else begin
            count <= count + 16'd1;
        end
    end

endmodule
