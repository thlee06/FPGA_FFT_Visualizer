`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2026 06:21:45 PM
// Design Name: 
// Module Name: xadc
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module xadc_capture(
input wire vauxp6,
input wire vauxn6,
input wire vp_in,
input wire vn_in,
input wire clk,
input wire btnC,
output reg [11:0] led,
output wire drdy_out
);


wire [15:0] di_in;
wire [6:0]  daddr_in;
wire        den_in;
wire        dwe_in;
wire [15:0] do_out;
wire [4:0]  channel_out;
wire        eoc_out;

assign di_in = 0;
assign dwe_in = 0;
assign daddr_in = 7'h16;
assign den_in = eoc_out;






xadc_wiz_0 xadc (
  .di_in(di_in),              // input wire [15 : 0] di_in
  .daddr_in(daddr_in),        // input wire [6 : 0] daddr_in
  .den_in(den_in),            // input wire den_in
  .dwe_in(dwe_in),            // input wire dwe_in
  .drdy_out(drdy_out),        // output wire drdy_out
  .do_out(do_out),            // output wire [15 : 0] do_out
  .dclk_in(clk),          // input wire dclk_in
  .reset_in(btnC),        // input wire reset_in
  .vp_in(vp_in),              // input wire vp_in
  .vn_in(vn_in),              // input wire vn_in
  .vauxp6(vauxp6),            // input wire vauxp6
  .vauxn6(vauxn6),            // input wire vauxn6
  .channel_out(channel_out),  // output wire [4 : 0] channel_out
  .eoc_out(eoc_out),          // output wire eoc_out
  .alarm_out(),      // output wire alarm_out
  .eos_out(),          // output wire eos_out
  .busy_out()        // output wire busy_out
);

always @ (posedge clk) begin
    if(drdy_out)
        led <= do_out[15:4];
end
    
    




endmodule
