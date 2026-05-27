// SPDX-License-Identifier: MIT
// Maps a full-cycle phase id onto a quarter-wave sine lookup table.

module bldc_sine_phase #(
    parameter integer ROM_DEPTH = 16,
    parameter integer ROM_WIDTH = 8,
    parameter ROM_FILE = "hardware/rtl/bldc/sine_LUT_table.mem",
    parameter USE_GOWIN_PROM = 1'b0
) (
    input  clk,
    input  [$clog2(4 * ROM_DEPTH)-1:0] id,
    output [2 * ROM_WIDTH - 1:0] data
);

    localparam integer ADDRW = $clog2(4 * ROM_DEPTH);
    localparam integer ROM_ADDRW = $clog2(ROM_DEPTH);
    localparam [ADDRW-1:0] ID_TOP = ROM_DEPTH;
    localparam [ADDRW-1:0] ID_BOTTOM = 3 * ROM_DEPTH;
    localparam [ROM_ADDRW:0] ROM_DEPTH_VALUE = ROM_DEPTH;

    reg [1:0] quadrant;
    reg [ROM_ADDRW-1:0] quadrant_index;
    reg [ROM_ADDRW-1:0] rom_addr;
    reg [2 * ROM_WIDTH - 1:0] data_q;

    wire [ROM_WIDTH-1:0] rom_data;
    wire [ROM_WIDTH:0] inverted_data =
        ({1'b1, {ROM_WIDTH{1'b0}}} - {1'b0, rom_data});
    wire [ROM_ADDRW:0] mirrored_index =
        ROM_DEPTH_VALUE - {1'b0, quadrant_index};

    generate
        if (USE_GOWIN_PROM) begin : g_gowin_prom
            Gowin_pROM u_sine_rom (
                .dout(rom_data),
                .clk(clk),
                .oce(1'b1),
                .ce(1'b1),
                .reset(1'b0),
                .ad(rom_addr)
            );
        end else begin : g_generic_rom
            bldc_rom_sync #(
                .WIDTH(ROM_WIDTH),
                .DEPTH(ROM_DEPTH),
                .INIT_FILE(ROM_FILE)
            ) u_sine_rom (
                .clk(clk),
                .addr(rom_addr),
                .data(rom_data)
            );
        end
    endgenerate

    always @* begin
        quadrant = id[ADDRW-1:ADDRW-2];
        quadrant_index = id[ROM_ADDRW-1:0];

        case (quadrant)
            2'b00: rom_addr = quadrant_index;
            2'b01: rom_addr = mirrored_index[ROM_ADDRW-1:0];
            2'b10: rom_addr = quadrant_index;
            default: rom_addr = mirrored_index[ROM_ADDRW-1:0];
        endcase
    end

    always @(posedge clk) begin
        if (id == ID_TOP) begin
            data_q <= {{(ROM_WIDTH - 1){1'b0}}, 1'b1, {ROM_WIDTH{1'b0}}};
        end else if (id == ID_BOTTOM) begin
            data_q <= {2 * ROM_WIDTH{1'b0}};
        end else if (!quadrant[1]) begin
            data_q <= {{ROM_WIDTH{1'b0}}, rom_data};
        end else begin
            data_q <= {{ROM_WIDTH{1'b0}}, inverted_data[ROM_WIDTH-1:0]};
        end
    end

    assign data = data_q;

endmodule
