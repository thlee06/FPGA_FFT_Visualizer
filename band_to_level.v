`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Module Name: band_to_level
// Description: Converts one 36-bit band power total into a 0..15 bar level
//              on a log scale.
//
//   msb   = position of the highest set bit = floor(log2(total))
//   level = msb - OFFSET, clamped to 0..15
//
//   Each +1 in msb is 2x the power = +3 dB, so the 15 levels span 45 dB.
//
//   Choosing OFFSET: a full-scale tone gives |X| = 2^20 in the FFT; after
//   band_power's [21:4] slice that's 2^16, and power = 2^32 (msb = 32).
//   OFFSET = 17 puts that at the top (level 15). ADC noise sits around
//   msb ~ 5..12, which lands at level 0. Raise OFFSET for less sensitivity.
//
//   Registered output: level is valid one clock after total changes.
//////////////////////////////////////////////////////////////////////////////////

module band_to_level #(
    parameter integer OFFSET = 17
)(
    input  wire        clk,
    input  wire [35:0] total,
    output reg  [3:0]  level = 4'd0
);
    // Priority encoder: scan upward, the last set bit found wins = highest one
    reg [5:0] msb;
    reg       nonzero;
    integer   b;
    always @(*) begin
        msb     = 6'd0;
        nonzero = 1'b0;
        for (b = 0; b < 36; b = b + 1) begin
            if (total[b]) begin
                msb     = b;
                nonzero = 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        if (!nonzero || msb <= OFFSET)
            level <= 4'd0;
        else if (msb - OFFSET >= 15)
            level <= 4'd15;
        else
            level <= msb - OFFSET;
    end
endmodule

`default_nettype wire
