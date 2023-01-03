`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/03/2023 06:10:43 PM
// Design Name: 
// Module Name: sd_simple
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


module sd_simple
(
    input clk_i,
    input rst_i,
    output SDCLK_o,
    inout CMD_io,
    inout DAT0_io,
    inout DAT1_io,
    inout DAT2_io,
    inout DAT3_io
);

parameter PRESCALER = 400;

reg [$clog2(PRESCALER/2)-1:0] fod_cnt_q;
reg fod_clk_q;

always @(posedge clk_i) begin
    if (rst_i) begin
        fod_cnt_q <= 0;
        fod_clk_q <= 1'b0;
    end else begin
        fod_cnt_q <= fod_cnt_q + 1'b1;
        if (fod_cnt_q == (PRESCALER/2)-1) begin
            fod_cnt_q <= 0;
            fod_clk_q <= ~fod_clk_q;
        end
    end
end



endmodule
