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
    
end

endmodule
