`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Module Name: vga_timing
// Description: 640x480 @ 60 Hz VGA timing from the 100 MHz board clock.
//
//   The pixel rate is 25 MHz (spec says 25.175; every monitor accepts 25).
//   Instead of making a second clock, everything runs on clk and only
//   advances when pix_en is high (1 clock in 4). One clock domain, no CDC.
//
//   One line  = 640 visible + 16 front porch + 96 sync + 48 back porch = 800 px
//   One frame = 480 visible + 10 front porch +  2 sync + 33 back porch = 525 lines
//
//   Outputs are decoded straight from the counters (combinational), so x, y,
//   active, hsync and vsync all describe the SAME pixel. Whoever uses them
//   should register color + hsync + vsync together.
//////////////////////////////////////////////////////////////////////////////////

module vga_timing (
    input  wire       clk,
    input  wire       reset,
    output reg        pix_en = 1'b0,   // one-clock pulse: "advance one pixel"
    output reg  [9:0] x      = 10'd0,  // 0..799, visible when < 640
    output reg  [9:0] y      = 10'd0,  // 0..524, visible when < 480
    output wire       active,          // (x, y) is inside the visible area
    output wire       hsync,           // active-low
    output wire       vsync            // active-low
);
    // Horizontal timing (pixels)
    localparam H_VISIBLE = 640, H_FRONT = 16, H_SYNC = 96, H_BACK = 48;
    localparam H_TOTAL   = H_VISIBLE + H_FRONT + H_SYNC + H_BACK;   // 800

    // Vertical timing (lines)
    localparam V_VISIBLE = 480, V_FRONT = 10, V_SYNC = 2,  V_BACK = 33;
    localparam V_TOTAL   = V_VISIBLE + V_FRONT + V_SYNC + V_BACK;   // 525

    // ---- 100 MHz / 4 = 25 MHz pixel enable ----
    reg [1:0] div = 2'd0;
    always @(posedge clk) begin
        if (reset) begin
            div    <= 2'd0;
            pix_en <= 1'b0;
        end else begin
            div    <= div + 1'b1;
            pix_en <= (div == 2'd3);
        end
    end

    // ---- Pixel (x) and line (y) counters ----
    always @(posedge clk) begin
        if (reset) begin
            x <= 10'd0;
            y <= 10'd0;
        end else if (pix_en) begin
            if (x == H_TOTAL - 1) begin
                x <= 10'd0;
                y <= (y == V_TOTAL - 1) ? 10'd0 : y + 1'b1;
            end else begin
                x <= x + 1'b1;
            end
        end
    end

    // ---- Decode ----
    assign active = (x < H_VISIBLE) && (y < V_VISIBLE);
    assign hsync  = ~((x >= H_VISIBLE + H_FRONT) && (x < H_VISIBLE + H_FRONT + H_SYNC));
    assign vsync  = ~((y >= V_VISIBLE + V_FRONT) && (y < V_VISIBLE + V_FRONT + V_SYNC));

endmodule

`default_nettype wire
