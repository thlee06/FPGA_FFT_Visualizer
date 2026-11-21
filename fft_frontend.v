`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: pipeline_buffer
// Description: Frames 12-bit ADC samples into 1024-point AXI-Stream frames
//              and runs them through the xfft_0 core.
//////////////////////////////////////////////////////////////////////////////////


module fft_frontend(
    input wire clk,
    input wire reset,
    input wire [11:0] adc_in,
    input wire adc_valid,

    output wire [23:0] fft_re,
    output wire [23:0] fft_im,
    output wire [9:0]  fft_index,
    output wire        fft_valid,
    output wire        fft_last
);


wire [11:0] signed_sample = {~adc_in[11], adc_in[10:0]};
wire [15:0] extended_sample = {{4{signed_sample[11]}}, signed_sample};

//DATA ASSIGN
reg [31:0] s_axis_data_tdata = 32'd0;
reg        s_axis_data_tvalid = 1'b0;
reg        s_axis_data_tlast = 1'b0;
wire       s_axis_data_tready;


wire [47:0] m_axis_data_tdata;
wire [15:0] m_axis_data_tuser;


reg  [9:0]  sample_count = 10'd0;
wire        transfer_ready = s_axis_data_tvalid && s_axis_data_tready;

always @ (posedge clk) begin
    if (reset) begin
        s_axis_data_tvalid <= 1'b0;
        s_axis_data_tlast <= 1'b0;
        sample_count <= 1'b0;
    end else begin
        if (transfer_ready) begin
            s_axis_data_tvalid <= 1'b0;
            sample_count <= sample_count + 1;
        end
        if (adc_valid && (~s_axis_data_tvalid || transfer_ready)) begin
            s_axis_data_tdata <= {16'd0, extended_sample};
            s_axis_data_tvalid <= 1;
            s_axis_data_tlast  <= ((sample_count + transfer_ready) == 10'd1023);
        end
    end
end

// ---- FFT core ----
wire        s_axis_config_tready;
wire        m_axis_data_tvalid;
wire        m_axis_data_tlast;

xfft_0 u_fft (
    .aclk                        (clk),
    .aresetn                     (~reset),               // remove if aresetn not enabled in the IP

    // Config channel: unused. Core defaults to forward transform after reset.
    .s_axis_config_tdata         (8'd1),                 // bit 0 = FWD_INV (1 = forward)
    .s_axis_config_tvalid        (1'b0),
    .s_axis_config_tready        (s_axis_config_tready),

    // Input samples (from your framing logic)
    .s_axis_data_tdata           (s_axis_data_tdata),    // [31:0] = {im[15:0], re[15:0]}
    .s_axis_data_tvalid          (s_axis_data_tvalid),
    .s_axis_data_tready          (s_axis_data_tready),
    .s_axis_data_tlast           (s_axis_data_tlast),

    // Output bins
    .m_axis_data_tdata           (m_axis_data_tdata),    // [47:0] = {im[23:0], re[23:0]}
    .m_axis_data_tuser           (m_axis_data_tuser),    // [9:0] = XK_INDEX
    .m_axis_data_tvalid          (m_axis_data_tvalid),
    .m_axis_data_tlast           (m_axis_data_tlast),
    .m_axis_data_tready          (1'b1),

    // Status events: unconnected
    .event_frame_started         (),
    .event_tlast_unexpected      (),
    .event_tlast_missing         (),
    .event_status_channel_halt   (),
    .event_data_in_channel_halt  (),
    .event_data_out_channel_halt ()
);

assign fft_re    = m_axis_data_tdata[23:0];
assign fft_im    = m_axis_data_tdata[47:24];
assign fft_index = m_axis_data_tuser[9:0];
assign fft_valid = m_axis_data_tvalid;
assign fft_last  = m_axis_data_tlast;


endmodule