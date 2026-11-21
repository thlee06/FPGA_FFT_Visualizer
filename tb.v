`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/03/2026 01:02:59 PM
// Design Name: 
// Module Name: tb
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


module tb;
    parameter integer N             = 1024;  //bin size
    parameter integer TONE_BIN      = 100;   // tone lands exactly on this bin
    parameter integer AMPLITUDE     = 1800;  // codes, out of +/-2047
    parameter integer MIDSCALE      = 2048;  // 0.5 V bias
    parameter integer SAMPLE_CLOCKS = 100;   // clocks between samples
    
    localparam real PI = 3.14159265358979;
    
    reg         clk       = 1'b0;
    reg         reset     = 1'b1;
    reg  [11:0] adc_in    = 12'd2048;
    reg         adc_valid = 1'b0;

    wire [23:0] fft_re, fft_im;
    wire [9:0]  fft_index;
    wire        fft_valid, fft_last;

    integer n, fd;
    real    value;
    always  #5 clk = ~clk;
    
    top dut (
        .clk(clk), .reset(reset),
        .adc_in(adc_in), .adc_valid(adc_valid),
        .fft_re(fft_re), .fft_im(fft_im), .fft_index(fft_index),
        .fft_valid(fft_valid), .fft_last(fft_last)
    );
    
     initial begin
        fd = $fopen("fft_output.txt", "w");
        repeat (10) @(posedge clk);
        reset <= 1'b0;

        wait (dut.s_axis_data_tready === 1'b1);   // wait for the core
        @(posedge clk);

        for (n = 0; n < N; n = n + 1) begin
            value = MIDSCALE + AMPLITUDE * $sin(2.0 * PI * TONE_BIN * n / N);
            adc_in    <= $rtoi(value + 0.5);
            adc_valid <= 1'b1;
            @(posedge clk);
            adc_valid <= 1'b0;
            repeat (SAMPLE_CLOCKS - 1) @(posedge clk);
        end
    end

    // Checker: log each bin, then stop at the end of the frame
    always @(posedge clk) begin
        if (fft_valid) begin
            $fdisplay(fd, "%0d %0d %0d", fft_index,
                      $signed(fft_re), $signed(fft_im));
            if (fft_last) begin
                $fclose(fd);
                $display("DONE: wrote fft_output.txt at %0t", $time);
                $finish;
            end
        end
    end

    // Watchdog
    initial begin
        #20_000_000;
        $display("FAIL: timed out, no complete output frame");
        $finish;
    end
endmodule
    

    
   

