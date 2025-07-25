`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/23/2025 06:28:49 PM
// Design Name: 
// Module Name: processing_element
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


module hashing_pe #(
    parameter X_DIM      = 4,
    parameter Y_DIM      = 4,
    parameter DATA_WIDTH = 32,
    parameter PKT_NO_FIELD_SIZE = 8, 
    parameter X_SIZE = $clog2(X_DIM),
    parameter Y_SIZE = $clog2(Y_DIM),
    parameter ROUTER_FLIT_WIDTH = (X_SIZE + Y_SIZE + DATA_WIDTH), 
    parameter TOTAL_WIDTH = (X_SIZE + Y_SIZE + DATA_WIDTH + PKT_NO_FIELD_SIZE)
)(
    input  wire                     clk,
    input  wire                     rstn,

    // Input from NoC router
    input  wire [ROUTER_FLIT_WIDTH-1:0]    in_data,
    input  wire                     in_valid,
    output wire                     in_ready,

    // Output to NoC router
    output reg  [ROUTER_FLIT_WIDTH-1:0]    out_data,
    output reg                      out_valid,
    input  wire                     out_ready
);

    // Simple hash function (XOR reduction across 4 segments)
    function [ROUTER_FLIT_WIDTH-1:0] simple_hash;
        input [ROUTER_FLIT_WIDTH-1:0] data;
        reg [7:0] hash_part;
        begin
            hash_part = data[8:1] ^ data[16:9] ^ data[24:17] ^ data[31:24];
            simple_hash = {data[ROUTER_FLIT_WIDTH-9:0], hash_part[7:0]}; // Rotate and append hash byte
        end
    endfunction

    // Internal state machine
    typedef enum logic [1:0] {
        IDLE,
        HASHING,
        SEND
    } state_t;

    state_t state, next_state;

    reg [ROUTER_FLIT_WIDTH-1:0] data_buffer;

    // Ready signal logic
    assign in_ready = (state == IDLE);

    // State transition
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE:    if (in_valid) next_state = HASHING;
            HASHING:                next_state = SEND;
            SEND:    if (out_ready) next_state = IDLE;
        endcase
    end

    // Output logic
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            out_data  <= '0;
            out_valid <= 0;
            data_buffer <= '0;
        end else begin
            case (state)
                IDLE: begin
                    out_valid <= 0;
                    if (in_valid) begin
                        data_buffer <= in_data;
                    end
                end
                HASHING: begin
                    out_data  <= simple_hash(data_buffer);
                    out_valid <= 1;
                end
                SEND: begin
                    if (out_ready) begin
                        out_valid <= 0;
                    end
                end
            endcase
        end
    end

endmodule
