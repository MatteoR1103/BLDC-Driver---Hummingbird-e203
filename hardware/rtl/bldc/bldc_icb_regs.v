// SPDX-License-Identifier: MIT
// Two-register ICB slave for the BLDC driver.

module bldc_icb_regs #(
    parameter [15:0] DEFAULT_PERIOD   = 16'd0,
    parameter [3:0]  DEFAULT_DEADZONE = 4'd0,
    parameter [11:0] REG_CFG_OFFSET   = 12'h000,
    parameter [11:0] REG_TIME_OFFSET  = 12'h004
) (
    input             clk,
    input             rst_n,
    input             break_n,
    input             hall_a,
    input             hall_b,
    input             hall_c,

    input             i_icb_cmd_valid,
    output            i_icb_cmd_ready,
    input      [31:0] i_icb_cmd_addr,
    input             i_icb_cmd_read,
    input      [31:0] i_icb_cmd_wdata,
    output            i_icb_rsp_valid,
    input             i_icb_rsp_ready,
    output     [31:0] i_icb_rsp_rdata,

    output reg [31:0] cfg_reg,
    output reg [31:0] time_reg
);

    wire reset = ~rst_n;
    wire cfg_selected  = (i_icb_cmd_addr[11:0] == REG_CFG_OFFSET);
    wire time_selected = (i_icb_cmd_addr[11:0] == REG_TIME_OFFSET);
    wire selected = cfg_selected || time_selected;
    wire read_en  = i_icb_cmd_valid && i_icb_cmd_read && selected;
    wire write_en = i_icb_cmd_valid && !i_icb_cmd_read && selected;

    reg        rsp_valid_q;
    reg [31:0] rsp_rdata_q;

    assign i_icb_cmd_ready = i_icb_cmd_valid;
    assign i_icb_rsp_valid = i_icb_rsp_ready && rsp_valid_q;
    assign i_icb_rsp_rdata = rsp_rdata_q;

    function [31:0] with_status_bits;
        input [31:0] cfg_value;
        begin
            with_status_bits = cfg_value;
            with_status_bits[7:5] = {hall_c, hall_b, hall_a};
            with_status_bits[1] = ~break_n;
        end
    endfunction

    always @(posedge clk or posedge reset or negedge break_n) begin
        if (reset || !break_n) begin
            cfg_reg <= {
                DEFAULT_PERIOD,
                DEFAULT_DEADZONE,
                4'b0000,
                hall_c,
                hall_b,
                hall_a,
                1'b0,
                2'b00,
                ~break_n,
                1'b0
            };
            time_reg <= 32'd0;
            rsp_valid_q <= 1'b0;
            rsp_rdata_q <= 32'd0;
        end else begin
            cfg_reg <= with_status_bits(cfg_reg);
            rsp_valid_q <= 1'b0;

            if (read_en) begin
                rsp_rdata_q <= cfg_selected ? with_status_bits(cfg_reg) : time_reg;
                rsp_valid_q <= 1'b1;
            end

            if (write_en) begin
                if (cfg_selected) begin
                    cfg_reg <= with_status_bits(i_icb_cmd_wdata);
                end else begin
                    time_reg <= i_icb_cmd_wdata;
                end
                rsp_valid_q <= 1'b1;
            end
        end
    end

endmodule
