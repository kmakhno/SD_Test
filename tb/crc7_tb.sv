`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/03/2023 09:50:42 PM
// Design Name: 
// Module Name: crc7_tb
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


module crc7_tb;

logic clk_i;
logic rst_i;
logic en_i;
logic [39:0] data_i;
logic [6:0] crc_o;
logic crc_valid_o;

crc7 crc7_inst( .* );

initial begin
    clk_i <= 1'b0;
    forever #(5) clk_i = ~clk_i;
end

initial begin
    rst_i <= 1'b1;
    #350;
    rst_i <= 1'b0;
end

initial begin
    en_i = 0;
    data_i = 0;
    #350;
    @(posedge clk_i);

    //Stimulus from Physical Layer Specification Version 3.01 (p.65)
    en_i <= 1'b1;
    data_i <= 40'h4000000000; //CMD0
    @(posedge clk_i);
    en_i <= 1'b0;
    repeat (42) @(posedge clk_i);

    en_i <= 1'b1;
    data_i <= 40'h5100000000; //CMD17
    @(posedge clk_i);
    en_i <= 1'b0;
    repeat (42) @(posedge clk_i);

    en_i <= 1'b1;
    data_i <= 40'b0001000100000000000000000000100100000000; //response CMD17
    @(posedge clk_i);
    en_i <= 1'b0;
    repeat (42) @(posedge clk_i);
    $finish;
end

endmodule
