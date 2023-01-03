`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/03/2023 09:33:38 PM
// Design Name: 
// Module Name: crc7
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


module crc7
(
    input clk_i,
    input rst_i,
    input en_i,
    input [39:0] data_i,
    output [6:0] crc_o,
    output crc_valid_o
);

localparam IDLE = 1'b0,
            COMP = 1'b1;

reg state_q;
reg [6:0] crc_q;
reg crc_valid_q;
reg [39:0] shreg_q;
reg [5:0] bit_cnt_q;

always @(posedge clk_i) begin
    if (rst_i) begin
        state_q <= IDLE;
        crc_q <= 0;
        shreg_q <= 0;
        bit_cnt_q <= 0;
        crc_valid_q <= 1'b0;
    end else begin
        case (state_q)
            IDLE: begin
                crc_valid_q <= 1'b0;
                if (en_i) begin
                    crc_q <= 0;
                    shreg_q <= data_i;
                    state_q <= COMP;
                end
            end

            COMP: begin
                bit_cnt_q <= bit_cnt_q + 1'b1;
                shreg_q <= {shreg_q[38:0], 1'b0};
                crc_q[0] <= shreg_q[39] ^ crc_q[6];
                crc_q[1] <= crc_q[0];
                crc_q[2] <= crc_q[1];
                crc_q[3] <= crc_q[2] ^ shreg_q[39] ^ crc_q[6];
                crc_q[4] <= crc_q[3];
                crc_q[5] <= crc_q[4];
                crc_q[6] <= crc_q[5];
                if (bit_cnt_q == 39) begin
                    bit_cnt_q <= 0;
                    crc_valid_q <= 1'b1;
                    state_q <= IDLE;
                end
            end
        endcase
    end
end

assign crc_o = crc_q;
assign crc_valid_o = crc_valid_q;

endmodule
