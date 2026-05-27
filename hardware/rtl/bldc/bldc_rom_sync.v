// SPDX-License-Identifier: MIT
// Portable synchronous ROM for simulation and vendor-neutral synthesis.

module bldc_rom_sync #(
    parameter integer WIDTH = 8,
    parameter integer DEPTH = 16,
    parameter INIT_FILE = "",
    parameter integer ADDRW = $clog2(DEPTH)
) (
    input                  clk,
    input      [ADDRW-1:0] addr,
    output reg [WIDTH-1:0] data
);

    reg [WIDTH-1:0] memory [0:DEPTH - 1];

    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, memory);
        end
    end

    always @(posedge clk) begin
        data <= memory[addr];
    end

endmodule
