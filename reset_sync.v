`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/20/2026 11:36:52 PM
// Design Name: 
// Module Name: reset_sync
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


module reset_sync(
    input reset,
    input clk,
    output reg out = 1'b0
    );


reg hold1 = 0;
reg hold2 = 0;
always @(posedge clk) begin
    hold1 <= reset;
    hold2 <= hold1;
    out <= hold2;
end
endmodule
