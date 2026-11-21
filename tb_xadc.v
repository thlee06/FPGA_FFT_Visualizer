`timescale 1ns / 1ps

module tb_xadc;
    parameter integer NUM_SAMPLES = 120;      // ~3 cycles of 1 kHz at ~39 kS/s

    reg clk   = 1'b0;                          // must start at a known value
    reg reset = 1'b1;
    always #5 clk = ~clk;                      // 100 MHz

    wire [11:0] out;

    xadc xadc_dut (
        .vauxp6(1'b0), .vauxn6(1'b0),          // ignored in sim; model reads design.txt
        .vp_in(1'b0),  .vn_in(1'b0),
        .clk(clk),
        .btnC(reset),
        .led(out)
    );

    integer fd;
    integer count = 0;

    initial begin
        fd = $fopen("xadc_output.txt", "w");
        repeat (10) @(posedge clk);
        reset <= 1'b0;
    end

    // Log every sample the moment it's valid: time (ns), code, channel
    always @(posedge clk) begin
        if (xadc_dut.drdy_out) begin
            $fdisplay(fd, "%0t %0d %0d", $time,
                      xadc_dut.do_out[15:4], xadc_dut.channel_out);
            count = count + 1;
            if (count == NUM_SAMPLES) begin
                $fclose(fd);
                $display("DONE: %0d samples written at %0t ns", count, $time);
                $finish;
            end
        end
    end

    // Watchdog: if no samples arrive, check design.txt location and reset
    initial begin
        #6_000_000;
        $display("FAIL: timed out after %0d samples", count);
        $fclose(fd);
        $finish;
    end
endmodule