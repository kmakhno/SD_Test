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
    input en_i,
    output SDCLK_o,
    inout CMD_io,
    inout DAT0_io,
    inout DAT1_io,
    inout DAT2_io,
    inout DAT3_io
);

wire sdclk_rising_edge_d;
wire sdclk_falling_edge_d;

wire CMD_id;
wire CMD_od;
wire DAT0_id;
wire DAT0_od;
wire DAT1_id;
wire DAT1_od;
wire DAT2_id;
wire DAT2_od;
wire DAT3_id;
wire DAT3_od;
wire start_response_d;
wire OCR_busy_d;

reg [47:0] command_q;
reg [7:0] state_q;
reg [31:0] delay_q;
reg [7:0] bit_cnt_q;
reg [15:0] counter_q;
reg sdclk_q;
reg CMD_en_q;
reg DAT0_en_q;
reg DAT1_en_q;
reg DAT2_en_q;
reg DAT3_en_q;
reg [1:0] shr_q;
reg [31:0] attmept_counter_q;

reg response_hndl_state_q;
reg response_timeout_q;
reg [15:0] RCA_q;
reg [3:0] SD_state_q;
reg [7:0] sdclk_prescaler_q;

always @(posedge clk_i) begin
    if (rst_i) begin
        state_q <= 0;
        counter_q <= 0;
        delay_q <= 0;
        bit_cnt_q <= 0;
        sdclk_q <= 1'b0;
        CMD_en_q <= 1'b0;
        DAT0_en_q <= 1'b0;
        DAT1_en_q <= 1'b1;
        DAT2_en_q <= 1'b1;
        DAT3_en_q <= 1'b1;
        command_q <= 48'h800000000000;
        response_handeled_q <= 1'b0;
        attmept_counter_q <= 0;
        response_length_q <= 0;
        response_hndl_state_q <= 1'b0;
        response_timeout_q <= 1'b0;
        RCA_q <= 0;
        SD_state_q <= 4'b0;
        sdclk_prescaler_q <= 125;
    end else begin
        case (state_q)
            0: begin //IDLE
                if (en_i) begin
                    state_q <= 1;
                    response_timeout_q <= 1'b0;
                end
            end

            1: begin //generate gt 74 clocks delay
                counter_q <= counter_q + 1'b1;
                if (counter_q == 124) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    delay_q <= delay_q + 1'b1;
                    if (delay_q == 79) begin
                        delay_q <= 0;
                        state_q <= 2;
                        command_q <= {1'b0, 1'b1, 6'b0, 32'b0, 7'b1001010, 1'b1};
                    end
                end
            end

            2: begin //generate CMD0
                counter_q <= counter_q + 1'b1;
                if (counter_q == 124) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    command_q <= {command_q[46:0], 1'b1};
                    bit_cnt_q <= bit_cnt_q + 1'b1;
                    if (bit_cnt_q == 47) begin
                        bit_cnt_q <= 0;
                        state_q <= 3;
                    end
                end
            end

            3: begin //generate 8 clocks delay
                counter_q <= counter_q + 1'b1;
                if (counter_q == 124) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    delay_q <= delay_q + 1'b1;
                    if (delay_q == 7) begin
                        delay_q <= 0;
                        state_q <= 4;
                        command_q <= {1'b0, 1'b1, 6'b001000, 20'b0, 4'b0001, 8'b10101010, 7'b1000011, 1'b1};
                    end
                end
            end

            4: begin //generate CMD8
                counter_q <= counter_q + 1'b1;
                if (counter_q == 124) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    command_q <= {command_q[46:0], 1'b1};
                    bit_cnt_q <= bit_cnt_q + 1'b1;
                    if (bit_cnt_q == 47) begin
                        bit_cnt_q <= 0;
                        state_q <= 5;
                        CMD_en_q <= 1'b1;
                        response_length_q <= 48;
                    end
                end
            end

            5: begin //generate 64 clocks for getting response
                counter_q <= counter_q + 1'b1;
                if (counter_q == 124) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    delay_q <= delay_q + 1'b1;
                    if (response_complete_q || delay_q == 63) begin
                        delay_q <= 0;
                        state_q <= 6;
                        CMD_en_q <= 1'b0;
                        if (response_complete_q)
                            response_handeled_q <= 1'b1;
                    end
                end
            end

            6: begin //generate 8 clocks delay
                response_handeled_q <= 1'b0;
                counter_q <= counter_q + 1'b1;
                if (counter_q == 124) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    delay_q <= delay_q + 1'b1;
                    if (delay_q == 7) begin
                        delay_q <= 0;
                        state_q <= 7;
                        command_q <= {1'b0, 1'b1, 6'b110111, 32'b0, 7'b0110010, 1'b1};
                    end
                end
            end

            7: begin //CMD55
                counter_q <= counter_q + 1'b1;
                if (counter_q == 124) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    command_q <= {command_q[46:0], 1'b1};
                    bit_cnt_q <= bit_cnt_q + 1'b1;
                    if (bit_cnt_q == 47) begin
                        bit_cnt_q <= 0;
                        state_q <= 8;
                        CMD_en_q <= 1'b1;
                        response_length_q <= 48;
                    end
                end
            end

            8: begin //generate 64 clocks for getting response
                counter_q <= counter_q + 1'b1;
                if (counter_q == 124) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    delay_q <= delay_q + 1'b1;
                    if (response_complete_q || delay_q == 63) begin
                        delay_q <= 0;
                        state_q <= 9;
                        CMD_en_q <= 1'b0;
                        if (response_complete_q)
                            response_handeled_q <= 1'b1;
                    end
                end
            end


            9: begin //generate 8 clocks delay
                response_handeled_q <= 1'b0;
                counter_q <= counter_q + 1'b1;
                if (counter_q == 124) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    delay_q <= delay_q + 1'b1;
                    if (delay_q == 7) begin
                        delay_q <= 0;
                        state_q <= 10;
                        command_q <= {1'b0, 1'b1, 6'b101001, 32'h40300000, 7'b1010101, 1'b1};
                    end
                end
            end

            10: begin //ACMD41
                counter_q <= counter_q + 1'b1;
                if (counter_q == 124) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    command_q <= {command_q[46:0], 1'b1};
                    bit_cnt_q <= bit_cnt_q + 1'b1;
                    if (bit_cnt_q == 47) begin
                        bit_cnt_q <= 0;
                        state_q <= 11;
                        CMD_en_q <= 1'b1;
                        response_length_q <= 48;
                    end
                end
            end

            11: begin //generate 64 clocks for getting response
                counter_q <= counter_q + 1'b1;
                if (counter_q == 124) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    delay_q <= delay_q + 1'b1;
                    if (response_complete_q || delay_q == 63) begin
                        delay_q <= 0;
                        state_q <= 12;
                        CMD_en_q <= 1'b0;
                        if (response_complete_q) begin
                            response_handeled_q <= 1'b1;
                        end
                    end
                end
            end

            12: begin //generate 8 clocks delay
                response_handeled_q <= 1'b0;
                counter_q <= counter_q + 1'b1;
                if (counter_q == 124) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    delay_q <= delay_q + 1'b1;
                    if (delay_q == 7) begin
                        delay_q <= 0;
                        if (!OCR_busy_d)
                            state_q <= 13;
                        else
                            state_q <= 14;
                        // command_q <= {1'b0, 1'b1, 6'b101001, 32'b0, 7'b1110010, 1'b1};
                    end
                end
            end

            13: begin //50ms delay
                counter_q <= counter_q + 1'b1;
                if (counter_q == 124) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    delay_q <= delay_q + 1'b1;
                    if (delay_q == 19999) begin
                        delay_q <= 0;
                        state_q <= 6; //to CMD55
                        attmept_counter_q <= attmept_counter_q + 1'b1;
                    end
                end
            end

            14: begin //generate 8 clocks delay
                response_handeled_q <= 1'b0;
                counter_q <= counter_q + 1'b1;
                if (counter_q == 124) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    delay_q <= delay_q + 1'b1;
                    if (delay_q == 7) begin
                        delay_q <= 0;
                        state_q <= 15;
                        command_q <= {1'b0, 1'b1, 6'b000010, 32'b0, 7'b0100110, 1'b1};
                    end
                end
            end

            15: begin //CMD2
                counter_q <= counter_q + 1'b1;
                if (counter_q == 124) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    command_q <= {command_q[46:0], 1'b1};
                    bit_cnt_q <= bit_cnt_q + 1'b1;
                    if (bit_cnt_q == 47) begin
                        bit_cnt_q <= 0;
                        state_q <= 16;
                        CMD_en_q <= 1'b1;
                        response_length_q <= 136; //R2 response type has 136 bit response length
                    end
                end
            end

            16: begin //generate 64 clocks for getting response
                counter_q <= counter_q + 1'b1;
                if (counter_q == 124) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                case (response_hndl_state_q)
                    1'b0: begin
                        if (start_response_d) begin
                            response_hndl_state_q <= 1'b1;
                            delay_q <= 0;
                        end else if (sdclk_falling_edge_d) begin
                            delay_q <= delay_q + 1'b1;
                            if (delay_q == 63) begin
                                response_timeout_q <= 1'b1;
                                delay_q <= 0;
                                state_q <= 0;
                            end
                        end
                    end

                    1'b1: begin
                        if (response_complete_q) begin
                            state_q <= 17;
                            CMD_en_q <= 1'b0;
                            response_handeled_q <= 1'b1;
                            response_hndl_state_q <= 1'b0;
                        end
                    end
                endcase
            end


            17: begin //generate 8 clocks delay
                response_handeled_q <= 1'b0;
                counter_q <= counter_q + 1'b1;
                if (counter_q == 124) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    delay_q <= delay_q + 1'b1;
                    if (delay_q == 7) begin
                        delay_q <= 0;
                        state_q <= 18;
                        command_q <= {1'b0, 1'b1, 6'b000011, 32'b0, 7'b0010000, 1'b1};
                    end
                end
            end

            18: begin //CMD3
                counter_q <= counter_q + 1'b1;
                if (counter_q == 124) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    command_q <= {command_q[46:0], 1'b1};
                    bit_cnt_q <= bit_cnt_q + 1'b1;
                    if (bit_cnt_q == 47) begin
                        bit_cnt_q <= 0;
                        state_q <= 19;
                        CMD_en_q <= 1'b1;
                        response_length_q <= 48;
                    end
                end
            end

            19: begin //generate 64 clocks for getting response
                counter_q <= counter_q + 1'b1;
                if (counter_q == 124) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                case (response_hndl_state_q)
                    1'b0: begin
                        if (start_response_d) begin
                            response_hndl_state_q <= 1'b1;
                            delay_q <= 0;
                        end else if (sdclk_falling_edge_d) begin
                            delay_q <= delay_q + 1'b1;
                            if (delay_q == 63) begin
                                response_timeout_q <= 1'b1;
                                delay_q <= 0;
                                state_q <= 0;
                            end
                        end
                    end

                    1'b1: begin
                        if (response_complete_q) begin
                            state_q <= 20;
                            CMD_en_q <= 1'b0;
                            RCA_q <= response_reg_q[39:24];
                            SD_state_q <= response_reg_q[20:17];
                            response_handeled_q <= 1'b1;
                            response_hndl_state_q <= 1'b0;
                        end
                    end
                endcase
            end

            20: begin //generate 8 clocks delay
                response_handeled_q <= 1'b0;
                counter_q <= counter_q + 1'b1;
                if (counter_q == 124) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    delay_q <= delay_q + 1'b1;
                    if (delay_q == 7) begin
                        delay_q <= 0;
                        if (SD_state_q == 3) begin//if SD state in standby mode go next otherwise query a new RCA address
                            state_q <= 21;
                            command_q <= {1'b0, 1'b1, 6'b000111, RCA_q, 16'b0, 7'b0110000, 1'b1};
                            sdclk_prescaler_q <= 2; //change SD clock prescaler
                        end else begin
                            state_q <= 17;
                        end
                    end
                end
            end

            21: begin //CMD7
                counter_q <= counter_q + 1'b1;
                // if (counter_q == 124) begin
                if (counter_q == sdclk_prescaler_q-1) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    command_q <= {command_q[46:0], 1'b1};
                    bit_cnt_q <= bit_cnt_q + 1'b1;
                    if (bit_cnt_q == 47) begin
                        bit_cnt_q <= 0;
                        state_q <= 22;
                        CMD_en_q <= 1'b1;
                        DAT0_en_q <= 1'b1;
                        response_length_q <= 48;
                    end
                end
            end

            22: begin //generate 64 clocks for getting response
                counter_q <= counter_q + 1'b1;
                // if (counter_q == 124) begin
                if (counter_q == sdclk_prescaler_q-1) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                case (response_hndl_state_q)
                    1'b0: begin
                        if (start_response_d) begin
                            response_hndl_state_q <= 1'b1;
                            delay_q <= 0;
                        end else if (sdclk_falling_edge_d) begin
                            delay_q <= delay_q + 1'b1;
                            if (delay_q == 63) begin
                                response_timeout_q <= 1'b1;
                                delay_q <= 0;
                                state_q <= 0;
                            end
                        end
                    end

                    1'b1: begin
                        if (response_complete_q) begin
                            state_q <= 23;
                            CMD_en_q <= 1'b0;
                            DAT0_en_q <= 1'b0;
                            SD_state_q <= response_reg_q[20:17];
                            response_handeled_q <= 1'b1;
                            response_hndl_state_q <= 1'b0;
                        end
                    end
                endcase
            end

            23: begin
                response_handeled_q <= 1'b0;
                counter_q <= counter_q + 1'b1;
                // if (counter_q == 124) begin
                if (counter_q == sdclk_prescaler_q-1) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    delay_q <= delay_q + 1'b1;
                    if (delay_q == 7) begin
                        delay_q <= 0;
                        state_q <= 24;
                        command_q <= {1'b0, 1'b1, 6'b001101, RCA_q, 16'b0, 7'b1110111, 1'b1};
                        // if (SD_state_q == 3) begin//if SD state in standby mode go next otherwise query a new RCA address
                        //     state_q <= 21;
                        //     command_q <= {1'b0, 1'b1, 6'b000111, RCA_q, 16'b0, 7'b0110000, 1'b1};
                        // end else begin
                        //     state_q <= 17;
                        // end
                    end
                end
            end

            24: begin //CMD13 getting SD Status
                counter_q <= counter_q + 1'b1;
                // if (counter_q == 124) begin
                if (counter_q == sdclk_prescaler_q-1) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    command_q <= {command_q[46:0], 1'b1};
                    bit_cnt_q <= bit_cnt_q + 1'b1;
                    if (bit_cnt_q == 47) begin
                        bit_cnt_q <= 0;
                        state_q <= 25;
                        CMD_en_q <= 1'b1;
                        response_length_q <= 48;
                    end
                end
            end

            25: begin //generate 64 clocks for getting response
                counter_q <= counter_q + 1'b1;
                // if (counter_q == 124) begin
                if (counter_q == sdclk_prescaler_q-1) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                case (response_hndl_state_q)
                    1'b0: begin
                        if (start_response_d) begin
                            response_hndl_state_q <= 1'b1;
                            delay_q <= 0;
                        end else if (sdclk_falling_edge_d) begin
                            delay_q <= delay_q + 1'b1;
                            if (delay_q == 63) begin
                                response_timeout_q <= 1'b1;
                                delay_q <= 0;
                                state_q <= 0;
                            end
                        end
                    end

                    1'b1: begin
                        if (response_complete_q) begin
                            state_q <= 26;
                            CMD_en_q <= 1'b0;
                            SD_state_q <= response_reg_q[20:17];
                            response_handeled_q <= 1'b1;
                            response_hndl_state_q <= 1'b0;
                        end
                    end
                endcase
            end

            26: begin
                response_handeled_q <= 1'b0;
                counter_q <= counter_q + 1'b1;
                // if (counter_q == 124) begin
                if (counter_q == sdclk_prescaler_q-1) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    delay_q <= delay_q + 1'b1;
                    if (delay_q == 7) begin
                        delay_q <= 0;
                        // command_q <= {1'b0, 1'b1, 6'b001101, RCA_q, 16'b0, 7'b1110111, 1'b1};
                        if (SD_state_q == 4) begin//if SD state is transfer mode go next otherwise go to the beginning
                            state_q <= 27;
                            command_q <= {1'b0, 1'b1, 6'b110111, RCA_q, 16'b0, 7'b1000011, 1'b1};
                        end else begin
                            state_q <= 0;
                        end
                    end
                end
            end

            27: begin //CMD55
                counter_q <= counter_q + 1'b1;
                // if (counter_q == 124) begin
                if (counter_q == sdclk_prescaler_q-1) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    command_q <= {command_q[46:0], 1'b1};
                    bit_cnt_q <= bit_cnt_q + 1'b1;
                    if (bit_cnt_q == 47) begin
                        bit_cnt_q <= 0;
                        state_q <= 28;
                        CMD_en_q <= 1'b1;
                        response_length_q <= 48;
                    end
                end
            end

            28: begin //generate 64 clocks for getting response
                counter_q <= counter_q + 1'b1;
                // if (counter_q == 124) begin
                if (counter_q == sdclk_prescaler_q-1) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                case (response_hndl_state_q)
                    1'b0: begin
                        if (start_response_d) begin
                            response_hndl_state_q <= 1'b1;
                            delay_q <= 0;
                        end else if (sdclk_falling_edge_d) begin
                            delay_q <= delay_q + 1'b1;
                            if (delay_q == 63) begin
                                response_timeout_q <= 1'b1;
                                delay_q <= 0;
                                state_q <= 0;
                            end
                        end
                    end

                    1'b1: begin
                        if (response_complete_q) begin
                            state_q <= 29;
                            CMD_en_q <= 1'b0;
                            SD_state_q <= response_reg_q[20:17];
                            response_handeled_q <= 1'b1;
                            response_hndl_state_q <= 1'b0;
                        end
                    end
                endcase
            end

            29: begin
                response_handeled_q <= 1'b0;
                counter_q <= counter_q + 1'b1;
                // if (counter_q == 124) begin
                if (counter_q == sdclk_prescaler_q-1) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    delay_q <= delay_q + 1'b1;
                    if (delay_q == 7) begin
                        delay_q <= 0;
                        state_q <= 30;
                        command_q <= {1'b0, 1'b1, 6'b000110, 32'h2, 7'b1100101, 1'b1};
                    end
                end
            end

            30: begin //ACMD6 Change bus width to 4
                counter_q <= counter_q + 1'b1;
                // if (counter_q == 124) begin
                if (counter_q == 1) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    command_q <= {command_q[46:0], 1'b1};
                    bit_cnt_q <= bit_cnt_q + 1'b1;
                    if (bit_cnt_q == 47) begin
                        bit_cnt_q <= 0;
                        state_q <= 31;
                        CMD_en_q <= 1'b1;
                        response_length_q <= 48;
                    end
                end
            end

            31: begin //generate 64 clocks for getting response
                counter_q <= counter_q + 1'b1;
                // if (counter_q == 124) begin
                if (counter_q == sdclk_prescaler_q-1) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                case (response_hndl_state_q)
                    1'b0: begin
                        if (start_response_d) begin
                            response_hndl_state_q <= 1'b1;
                            delay_q <= 0;
                        end else if (sdclk_falling_edge_d) begin
                            delay_q <= delay_q + 1'b1;
                            if (delay_q == 63) begin
                                response_timeout_q <= 1'b1;
                                delay_q <= 0;
                                state_q <= 0;
                            end
                        end
                    end

                    1'b1: begin
                        if (response_complete_q) begin
                            state_q <= 32;
                            CMD_en_q <= 1'b0;
                            SD_state_q <= response_reg_q[20:17];
                            response_handeled_q <= 1'b1;
                            response_hndl_state_q <= 1'b0;
                        end
                    end
                endcase
            end

            32: begin
                response_handeled_q <= 1'b0;
                counter_q <= counter_q + 1'b1;
                // if (counter_q == 124) begin
                if (counter_q == sdclk_prescaler_q-1) begin
                    counter_q <= 0;
                    sdclk_q <= ~sdclk_q;
                end

                if (sdclk_falling_edge_d) begin
                    delay_q <= delay_q + 1'b1;
                    if (delay_q == 7) begin
                        delay_q <= 0;
                        state_q <= 33;
                        // command_q <= {1'b0, 1'b1, 6'b000110, 32'h2, 7'b1100101, 1'b1};
                    end
                end
            end

            33: begin
            end

        endcase
    end
end

always @(posedge clk_i) begin
    if (rst_i) begin
        shr_q <= 2'b00;
    end else if (CMD_en_q) begin
        shr_q <= {shr_q[0], CMD_id};
    end
end

reg response_state_q;
reg [135:0] response_reg_q;
reg [7:0] response_bit_cnt_q;
reg response_complete_q;
reg response_handeled_q;
reg [7:0] response_length_q;

always @(posedge clk_i) begin
    if (rst_i) begin
        response_state_q <= 1'b0;
        response_reg_q <= 0;
        response_bit_cnt_q <= 0;
        response_complete_q <= 1'b0;
    end else begin
        case (response_state_q)
            1'b0: begin //IDLE
                if (start_response_d) begin
                    response_state_q <= 1'b1;
                    response_reg_q <= 0;
                    response_complete_q <= 1'b0;
                end else if (response_handeled_q) begin
                    response_complete_q <= 1'b0;
                end
            end

            1'b1: begin //response handling
                if (sdclk_rising_edge_d) begin
                    response_bit_cnt_q <= response_bit_cnt_q + 1'b1;
                    response_reg_q <= {response_reg_q[134:0], CMD_id};
                    if (response_bit_cnt_q == response_length_q) begin
                        response_bit_cnt_q <= 0;
                        response_state_q <= 1'b0;
                        response_reg_q <= response_reg_q;
                        response_complete_q <= 1'b1;
                    end
                end
            end
        endcase
    end
end

assign start_response_d = shr_q[1] && !shr_q[0];
assign CMD_od = command_q[47];

IOBUF IOBUF_CMD (
  .O(CMD_id),     // Buffer output
  .IO(CMD_io),   // Buffer inout port (connect directly to top-level port)
  .I(CMD_od),     // Buffer input
  .T(CMD_en_q)      // 3-state enable input, high=input, low=output
);

IOBUF IOBUF_DAT0 (
  .O(DAT0_id),     // Buffer output
  .IO(DAT0_io),   // Buffer inout port (connect directly to top-level port)
  .I(DAT0_od),     // Buffer input
  .T(DAT0_en_q)      // 3-state enable input, high=input, low=output
);

IOBUF IOBUF_DAT1 (
  .O(DAT1_id),     // Buffer output
  .IO(DAT1_io),   // Buffer inout port (connect directly to top-level port)
  .I(DAT1_od),     // Buffer input
  .T(DAT1_en_q)      // 3-state enable input, high=input, low=output
);

IOBUF IOBUF_DAT2 (
  .O(DAT2_id),     // Buffer output
  .IO(DAT2_io),   // Buffer inout port (connect directly to top-level port)
  .I(DAT2_od),     // Buffer input
  .T(DAT2_en_q)      // 3-state enable input, high=input, low=output
);

IOBUF IOBUF_DAT3 (
  .O(DAT3_id),     // Buffer output
  .IO(DAT3_io),   // Buffer inout port (connect directly to top-level port)
  .I(DAT3_od),     // Buffer input
  .T(DAT3_en_q)      // 3-state enable input, high=input, low=output
);

// assign sdclk_rising_edge_d  = (counter_q == (sdclk_prescaler_q-1) && !sdclk_q);
reg [1:0] sdclk_shr_q = 2'b00;
always @(posedge clk_i) begin
    sdclk_shr_q <= {sdclk_shr_q[0], SDCLK_o};
end
assign sdclk_rising_edge_d = !sdclk_shr_q[1] && sdclk_shr_q[0]; 

assign sdclk_falling_edge_d = (counter_q == (sdclk_prescaler_q-1) && sdclk_q);
ila_0 ila_0_inst (
    .clk(clk_i),
    .probe0(en_i),
    .probe1(CMD_id),
    .probe2(CMD_od),
    .probe3(CMD_en_q),
    .probe4(sdclk_rising_edge_d),
    .probe5(sdclk_falling_edge_d),
    .probe6(state_q),
    .probe7(response_reg_q),
    .probe8(response_bit_cnt_q),
    .probe9(response_complete_q),
    .probe10(attmept_counter_q),
    .probe11(OCR_busy_d),
    .probe12(response_timeout_q),
    .probe13(RCA_q),
    .probe14(SD_state_q),
    .probe15(SDCLK_o),
    .probe16(start_response_d)
);

assign SDCLK_o = sdclk_q;
assign DAT0_od = 1'b1; //test
assign OCR_busy_d = response_reg_q[39];

endmodule
