`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2026 02:27:17 PM
// Design Name: 
// Module Name: visualizer_top
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


module visualizer_top(
    input wire vauxp6,
    input wire vauxn6,
    input wire vp_in,
    input wire vn_in,
    input wire clk,
    input wire btnC,
     
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue,
    output wire       Hsync,
    output wire       Vsync
    );


//RESET
wire rst = 0;
reset_sync u_reset_sync(
    .reset(btnC),
    .clk(clk),
    .out(reset)
    );


//ADC
//module xadc_capture(
//input wire vauxp6,
//input wire vauxn6,
//input wire vp_in,
//input wire vn_in,
//input wire clk,
//input wire btnC,
//output reg [11:0] led
//);
wire [11:0] adc_out;
wire adc_drdy;
xadc_capture u_xadc (
    .vauxp6(vauxp6),
    .vauxn6(vauxn6),
    .vp_in(vp_in),
    .vn_in(vn_in),
    .clk(clk),
    .btnC(reset),
    .led(adc_out),
    .drdy_out(adc_drdy)
    );

//BUFFER/FFT FRONTEND

//module fft_frontend(
//    input wire clk,
//    input wire reset,
//    input wire [11:0] adc_in,
//    input wire adc_valid,

//    output wire [23:0] fft_re,
//    output wire [23:0] fft_im,
//    output wire [9:0]  fft_index,
//    output wire        fft_valid,
//    output wire        fft_last
//);
wire [23:0] fft_re;
wire [23:0] fft_im;
wire [9:0]  fft_index;
wire        fft_valid;
wire        fft_last;


fft_frontend u_fft_frontend(
    .clk(clk),
    .reset(reset),
    .adc_in(adc_out),
    .adc_valid(adc_drdy),
    .fft_re(fft_re),
    .fft_im(fft_im),
    .fft_index(fft_index),
    .fft_valid(fft_valid),
    .fft_last(fft_last)
    );
//BAND POWER
//module band_power( 
//input wire clk,
//input wire [23:0] fft_re_in,
//input wire [23:0] fft_im_in,
//input wire [9:0]  fft_index,
//input wire        fft_valid,
//input wire        fft_last,
//output reg [287:0] band_totals,
//output reg         band_valid

wire [287:0] band_totals;
wire         band_valid;
band_power u_band_power(
    .clk(clk),
    .fft_re_in(fft_re),
    .fft_im_in(fft_im),
    .fft_index(fft_index),
    .fft_valid(fft_valid),
    .fft_last(fft_last),
    .reset(reset),
    .band_totals(band_totals),
    .band_valid(band_valid)
    );

//VISUALIZER

vga_spectrum  u_vga (
    .clk(clk), .reset(reset),
    .band_totals(band_totals), .band_valid(band_valid),
    .vgaRed(vgaRed), .vgaGreen(vgaGreen), .vgaBlue(vgaBlue),
    .Hsync(Hsync), .Vsync(Vsync)
);


    

    
endmodule
