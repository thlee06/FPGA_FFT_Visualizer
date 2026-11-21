`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/03/2026 02:13:30 PM
// Design Name: 
// Module Name: band_power
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


module band_power( 
input wire clk,
input wire [23:0] fft_re_in,
input wire [23:0] fft_im_in,
input wire [9:0]  fft_index,
input wire        fft_valid,
input wire        fft_last,
input wire        reset,
output reg [287:0] band_totals,
output reg         band_valid

    );

reg [2:0] bin_num;
reg band_en;

//Multiplication Registers
reg [35:0] power  = 36'b0;
wire signed [17:0] re = fft_re_in[21:4];
wire signed [17:0] im = fft_im_in[21:4];

reg signed [17:0] re_d;
reg signed [17:0] im_d;
reg signed [35:0] re_sq;
reg signed [35:0] im_sq;

//Delay Logic Registers
reg [2:0] valid_d = 3'b0;
reg [2:0] valid_last = 3'b0;
reg [2:0] band_en_d = 3'b0;
reg [8:0] bin_num_d = 9'b0;

reg [35:0] total [0:7];

//Initialize total to 0
integer i;
initial begin
    for(i =0; i < 8; i = i+1) begin 
        total[i] = 36'd0;
    end
end


always @ (*) begin
    bin_num = 3'd0;
    band_en = 1'b1;
    casez(fft_index)
        10'b01zzzzzzzz : bin_num = 3'd7;
        10'b001zzzzzzz : bin_num = 3'd6;
        10'b0001zzzzzz : bin_num = 3'd5;
        10'b00001zzzzz : bin_num = 3'd4;
        10'b000001zzzz : bin_num = 3'd3;
        10'b0000001zzz : bin_num = 3'd2;
        10'b00000001zz : bin_num = 3'd1;
        10'b000000001z : bin_num = 3'd0;
        default : band_en = 0;
    endcase
end

always @ (posedge clk) begin
    //Delay variables to arrive on time with power output
    valid_d <= {valid_d[1:0], fft_valid};
    valid_last <= {valid_last[1:0], fft_last};
    band_en_d <= {band_en_d[1:0], band_en};
    bin_num_d <= {bin_num_d[5:0], bin_num };
   //Multiplication logic
    re_d <= re;
    im_d <= im;
    re_sq <= re_d * re_d;
    im_sq <= im_d * im_d;
    power <= re_sq + im_sq;
end
reg last_d = 1'b0;
integer j;

always @ (posedge clk) begin
    last_d     <= valid_last[2] && valid_d[2];
    band_valid <= 1'b0;                         // default: no pulse

    if (reset) begin
        last_d <= 1'b0;
        for (j = 0; j < 8; j = j + 1)
            total[j] <= 36'd0;
    end else if (last_d) begin
        // Frame done: publish the totals, pulse valid, start the next frame at 0
        band_totals <= {total[7], total[6], total[5], total[4],
                        total[3], total[2], total[1], total[0]};
        band_valid  <= 1'b1;
        for (j = 0; j < 8; j = j + 1)
            total[j] <= 36'd0;
    end else if (band_en_d[2] && valid_d[2]) begin
        total[bin_num_d[8:6]] <= total[bin_num_d[8:6]] + power;
    end
end
endmodule
