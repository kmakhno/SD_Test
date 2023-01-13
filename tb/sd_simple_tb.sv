`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.01.2023 12:07:38
// Design Name: 
// Module Name: sd_simple_tb
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


module sd_simple_tb;

logic clk_i;
logic rst_i;
logic en_i;
logic SDCLK_o;
wire  CMD_io;
wire  DAT0_io;
wire  DAT1_io;
wire  DAT2_io;
wire  DAT3_io;

sd_simple sd_simple_inst (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .en_i(en_i),
    .SDCLK_o(SDCLK_o),
    .CMD_io(CMD_io),
    .DAT0_io(DAT0_io),
    .DAT1_io(DAT1_io),
    .DAT2_io(DAT2_io),
    .DAT3_io(DAT3_io)
);

logic CMD_q;
wire CMD;

assign CMD_io = (sd_simple_inst.CMD_en_q) ? CMD_q : 1'bZ;
assign CMD = CMD_io;

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
    #350;
    @(posedge clk_i);
    en_i <= 1;
    @(posedge clk_i);
    en_i <= 0;
    repeat (70000) @(posedge clk_i);
    $finish;
end

logic [47:0] response;
logic resp_en;

initial begin
    response = '1;
    resp_en = 0;
    forever begin
        if (sd_simple_inst.sdclk_falling_edge_d) begin
            response <= {response[46:0], 1'b1};
        end
        if (sd_simple_inst.state_q == 5 && !resp_en) begin
            if (sd_simple_inst.sdclk_falling_edge_d && sd_simple_inst.delay_q == 10) begin
                response <= {1'b0, 1'b0, 13'b0, $urandom(), 1'b1};
                $strobe("response=%012h", response);
                resp_en <= 1'b1;
            end
        end
        @(posedge clk_i);
    end
end

assign CMD_q = response[47];

endmodule
