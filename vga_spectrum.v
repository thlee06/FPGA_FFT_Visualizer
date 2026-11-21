`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Module Name: vga_spectrum
// Description: Draws 8 segmented spectrum bars (VU-meter style) on a
//              640x480 @ 60 Hz VGA screen from band_power's outputs.
//
//   Drop-in for visualizer_top:
//     inputs  = band_totals[287:0] + band_valid straight from band_power
//               (band k = band_totals[36*k +: 36], band 0 in the low bits)
//     outputs = named like the Basys 3 master XDC (vgaRed, vgaGreen,
//               vgaBlue, Hsync, Vsync), so the XDC lines work uncommented.
//
//   Data path:
//     band_valid ─► latch totals ─► band_to_level x8 ─► latch at vblank ─► draw
//     (latching on band_valid means band_power doesn't need to hold its
//      outputs between frames; latching at vblank prevents tearing)
//
//   TEST_PATTERN = 1 ignores the inputs and draws a fixed staircase, so you
//   can check the monitor before band_power is finished.
//
//   Screen layout (all sizes are powers of two, so no dividers):
//      x: 64 px margin | 8 slots x 64 px (6 gap + 52 bar + 6 gap) | 64 px margin
//      y: 15 rows x 32 px counted up from the bottom (28 px block + 4 px gap)
//         rows 0-8 green, 9-11 yellow, 12-14 red; unlit blocks dim gray
//////////////////////////////////////////////////////////////////////////////////

module vga_spectrum #(
    parameter integer LEVEL_OFFSET = 17,   // see band_to_level.v
    parameter integer TEST_PATTERN = 0     // 1 = fixed staircase, ignores inputs
)(
    input  wire         clk,               // 100 MHz
    input  wire         reset,             // active-high, from reset_sync
    input  wire [287:0] band_totals,       // 8 x 36 bits, from band_power
    input  wire         band_valid,        // one-cycle pulse per FFT frame
    output reg  [3:0]   vgaRed   = 4'd0,
    output reg  [3:0]   vgaGreen = 4'd0,
    output reg  [3:0]   vgaBlue  = 4'd0,
    output reg          Hsync    = 1'b1,
    output reg          Vsync    = 1'b1
);

    // ---- Timing ----
    wire       pix_en, active, hsync, vsync;
    wire [9:0] x, y;

    vga_timing u_timing (
        .clk(clk), .reset(reset),
        .pix_en(pix_en), .x(x), .y(y),
        .active(active), .hsync(hsync), .vsync(vsync)
    );

    // ---- Hold the latest frame's totals ----
    reg [287:0] totals_q = 288'd0;
    always @(posedge clk) begin
        if (reset)
            totals_q <= 288'd0;
        else if (band_valid)
            totals_q <= band_totals;
    end

    // ---- 36-bit totals -> 4-bit log levels ----
    wire [31:0] levels_now;
    genvar k;
    generate
        for (k = 0; k < 8; k = k + 1) begin : g_level
            band_to_level #(.OFFSET(LEVEL_OFFSET)) u_level (
                .clk  (clk),
                .total(totals_q[36*k +: 36]),
                .level(levels_now[4*k +: 4])
            );
        end
    endgenerate

    // ---- Freeze levels once per screen frame (start of vertical blanking) ----
    localparam [31:0] STAIRCASE = {4'd15, 4'd13, 4'd11, 4'd9, 4'd7, 4'd5, 4'd3, 4'd1};
    reg [31:0] levels_q = 32'd0;
    always @(posedge clk) begin
        if (reset)
            levels_q <= 32'd0;
        else if (pix_en && x == 10'd0 && y == 10'd480)
            levels_q <= TEST_PATTERN ? STAIRCASE : levels_now;
    end

    // ---- Which band / column? ----
    wire       in_bars = (x >= 10'd64) && (x < 10'd576);
    wire [9:0] xs      = x - 10'd64;        // x relative to the first slot
    wire [2:0] band    = xs[8:6];           // xs / 64
    wire [5:0] col     = xs[5:0];           // xs % 64
    wire       in_col  = (col >= 6'd6) && (col < 6'd58);

    // ---- Which row? (counted from the bottom) ----
    wire [8:0] d       = 9'd479 - y[8:0];   // only meaningful while y < 480
    wire [3:0] row     = d[8:5];            // d / 32 -> 0 (bottom) .. 14 (top)
    wire [4:0] in_row  = d[4:0];            // d % 32
    wire       in_blk  = (in_row >= 5'd4);  // 4 px gap under each block

    wire [3:0] level   = levels_q[band*4 +: 4];
    wire       lit     = (row < level);

    // ---- Pixel color {R, G, B} ----
    reg [11:0] color;
    always @(*) begin
        color = 12'h000;                                // background
        if (active && in_bars && in_col && in_blk) begin
            if (!lit)            color = 12'h222;       // unlit block
            else if (row >= 12)  color = 12'hF00;       // red
            else if (row >= 9)   color = 12'hFF0;       // yellow
            else                 color = 12'h0F0;       // green
        end
    end

    // ---- Output register: color and syncs on the same edge stay aligned ----
    always @(posedge clk) begin
        if (pix_en) begin
            {vgaRed, vgaGreen, vgaBlue} <= color;
            Hsync <= hsync;
            Vsync <= vsync;
        end
    end

endmodule

`default_nettype wire
