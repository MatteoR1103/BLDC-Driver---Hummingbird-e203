// SPDX-License-Identifier: MIT
// Unit testbench for the standalone BLDC driver peripheral.
//
// From the repository root:
//   iverilog -g2005-sv -o build/sim/bldc_tb \
//     hardware/rtl/bldc/tb.sv \
//     hardware/rtl/bldc/BLDC_driver.v \
//     hardware/rtl/bldc/bldc_*.v
//   vvp build/sim/bldc_tb

`timescale 1ns/1ns              // unit time (#) / resolution on gtkwave

module test_bench();
  // Declare inputs as regs and outputs as wires
    reg clk;
    reg rst_n;

    reg                   i_icb_cmd_valid;
    wire                  i_icb_cmd_ready;
    reg  [32-1:0]         i_icb_cmd_addr; 
    reg                   i_icb_cmd_read;

    reg  [32-1:0]         i_icb_cmd_wdata;

    wire                  i_icb_rsp_valid;
    reg                   i_icb_rsp_ready;
    wire [32-1:0]         i_icb_rsp_rdata;

    wire                  io_pad_out_0;      // io_pad_out_HS_U,
    wire                  io_pad_out_1;      // io_pad_out_LS_U,

    wire                  io_pad_out_2;      // io_pad_out_HS_V,
    wire                  io_pad_out_3;      // io_pad_out_LS_V,

    wire                  io_pad_out_4;      // io_pad_out_HS_W,
    wire                  io_pad_out_5;      // io_pad_out_LS_W,

    reg                   io_pad_in_BREAK;

    reg                   io_pad_in_HAL_A;
    reg                   io_pad_in_HAL_B;
    reg                   io_pad_in_HAL_C;
    
parameter BASE_ADDRESS = 20'h10014;

// REGISTER 1:      |                       PERIOD                    |   DEADZONE  |   FREE    |  C   B   A  | DIRECTION |  MODE  | BREAK | ENABLE
//                  | 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 | 15 14 13 12 | 11 10 9 8 |  7 | 6 | 5  |     4     |  3  2  |   1   |   0
parameter  OFFSET_REG_1_ADDRESS   = 12'h000;

// REGISTER 2:      |                     Time 2                      |                Time 1                 |
//                  | 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 | 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0 |
parameter  OFFSET_REG_2_ADDRESS    = 12'h004;

parameter  MODE_OC                 = 2'b00;
parameter  MODE_PWM                = 2'b01;
parameter  MODE_PWM_SINE           = 2'b10;

task send_icb_data(input reg [11:0] address, input reg [31:0] data);
begin
    i_icb_cmd_valid <= 1;
    i_icb_cmd_addr  <= address;
    i_icb_cmd_read <= 0;

    i_icb_cmd_wdata <= data;
    i_icb_rsp_ready <= 1;
    #100;
    i_icb_cmd_addr  <= 32'h0;
    i_icb_cmd_wdata <= 32'b0;
    i_icb_cmd_valid <= 0;
    #100;
    i_icb_rsp_ready <= 0;
    #50;
end
endtask

  // Simulation
  initial begin
    rst_n <= 1;

    i_icb_cmd_valid <= 1'b0;
    i_icb_cmd_addr  <= 1'b0; 
    i_icb_cmd_read  <= 1'b0;
    i_icb_cmd_wdata <= 1'b0;
    i_icb_rsp_ready <= 1'b0;

    io_pad_in_BREAK <= 1'b1;
    io_pad_in_HAL_A <= 1'b0;
    io_pad_in_HAL_B <= 1'b0;
    io_pad_in_HAL_C <= 1'b0;
    #1;
    rst_n <= 0;
    #19
    rst_n <= 1;

    // Static six-step mode.
    send_icb_data({BASE_ADDRESS, OFFSET_REG_1_ADDRESS}, {16'd900, 4'b0100, 4'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0}); // Initialization
    #100;
    send_icb_data({BASE_ADDRESS, OFFSET_REG_2_ADDRESS}, {16'd300, 16'd0}); // Setting time 2
    #100;
    send_icb_data({BASE_ADDRESS, OFFSET_REG_1_ADDRESS}, {16'd900, 4'b0100, 4'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 1'b1}); // ENABLE
    

    // TESTING INPUTS
    #1000000;
    io_pad_in_HAL_A <= 1'b1;
    io_pad_in_HAL_B <= 1'b0;
    io_pad_in_HAL_C <= 1'b0;
    #1000000;
    io_pad_in_HAL_A <= 1'b0;
    io_pad_in_HAL_B <= 1'b1;
    io_pad_in_HAL_C <= 1'b0;
    #1000000;
    io_pad_in_HAL_A <= 1'b0;
    io_pad_in_HAL_B <= 1'b0;
    io_pad_in_HAL_C <= 1'b1;

    #1000000;
    io_pad_in_HAL_A <= 1'b1;
    io_pad_in_HAL_B <= 1'b1;
    io_pad_in_HAL_C <= 1'b0;
    #1000000;
    io_pad_in_HAL_A <= 1'b0;
    io_pad_in_HAL_B <= 1'b1;
    io_pad_in_HAL_C <= 1'b1;
    #1000000;
    io_pad_in_HAL_A <= 1'b1;
    io_pad_in_HAL_B <= 1'b0;
    io_pad_in_HAL_C <= 1'b1;
    #1000000;
    io_pad_in_HAL_A <= 1'b1;
    io_pad_in_HAL_B <= 1'b1;
    io_pad_in_HAL_C <= 1'b1;
    
    #1000000;
    io_pad_in_BREAK <= 0;

    #5000 $finish;
  end

  BLDC_driver #(
    .ROM_FILE("hardware/rtl/bldc/sine_LUT_table.mem"),
    .USE_GOWIN_PROM(1'b0)
  ) DUT (
    .clk                 (clk),
    .rst_n               (rst_n),
    
    .i_icb_cmd_valid    (i_icb_cmd_valid),
    .i_icb_cmd_ready    (i_icb_cmd_ready),
    .i_icb_cmd_addr     (i_icb_cmd_addr),
    .i_icb_cmd_read     (i_icb_cmd_read),
    .i_icb_cmd_wdata    (i_icb_cmd_wdata),
    .i_icb_rsp_valid    (i_icb_rsp_valid),
    .i_icb_rsp_ready    (i_icb_rsp_ready),
    .i_icb_rsp_rdata    (i_icb_rsp_rdata),

    .io_pad_out_0       (io_pad_out_0),
    .io_pad_out_1       (io_pad_out_1),
    .io_pad_out_2       (io_pad_out_2),
    .io_pad_out_3       (io_pad_out_3),
    .io_pad_out_4       (io_pad_out_4),
    .io_pad_out_5       (io_pad_out_5),

    .io_pad_in_HAL_A    (io_pad_in_HAL_A),
    .io_pad_in_HAL_B    (io_pad_in_HAL_B),
    .io_pad_in_HAL_C    (io_pad_in_HAL_C),
    .io_pad_in_BREAK    (io_pad_in_BREAK)
  );

  // Clock generator
  initial begin
    clk = 0;
    forever #31.25 clk = ~clk;
  end

  // Simulator file generator
  initial begin
    $dumpfile("build/sim/bldc_tb.vcd");
    $dumpvars(0, test_bench);
  end
endmodule
