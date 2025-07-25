`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Nhlanhla Mavuso
// 
// Create Date: 
// Design Name:  
// Module Name: top
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


module top #(
    parameter X_DIM = 4,
    parameter Y_DIM = 4,
    parameter DATA_WIDTH = 32,
    parameter PKT_NO_FIELD_SIZE = 8, 
    parameter X_SIZE = $clog2(X_DIM),
    parameter Y_SIZE = $clog2(Y_DIM),
    parameter ROUTER_FLIT_WIDTH = (X_SIZE + Y_SIZE + DATA_WIDTH), 
    parameter TOTAL_WIDTH = (X_SIZE + Y_SIZE + DATA_WIDTH + PKT_NO_FIELD_SIZE)
)(
    input  wire clk_12MHz,
    input  wire rstn,
    input [TOTAL_WIDTH - 1:0] packet_in, // from Packetizer
    input wire packet_in_valid, 
    output wire packet_in_ready,
    output [TOTAL_WIDTH - 1:0] packet_out,  //to Packetizer 
    output wire packet_out_valid
);


   feedclock feedclock_i
       (.clk_in1(clk_12MHz),
        .clk_out1(clk),
        .locked(locked),
        .reset(reset));
    // Internal wires connecting PE to router
   (*dont_touch = "yes"*) wire [X_DIM*Y_DIM-1:0][ROUTER_FLIT_WIDTH-1:0] pe_to_noc_data;
   (*dont_touch = "yes"*) wire [X_DIM*Y_DIM-1:0]                pe_to_noc_valid;
   (*dont_touch = "yes"*) wire [X_DIM*Y_DIM-1:0]                noc_to_pe_ready;

   (*dont_touch = "yes"*) wire [X_DIM*Y_DIM-1:0][ROUTER_FLIT_WIDTH-1:0] noc_to_pe_data;
   (*dont_touch = "yes"*) wire [X_DIM*Y_DIM-1:0]                noc_to_pe_valid;
   (*dont_touch = "yes"*) wire [X_DIM*Y_DIM-1:0]                pe_to_noc_ready;

    // Instantiate homogeneous PEs
    genvar i;
    generate
        for (i = 0; i < X_DIM * Y_DIM; i = i + 1) begin : gen_pe
            hashing_pe #(
                .X_DIM(X_DIM),
                .Y_DIM(Y_DIM),
                .DATA_WIDTH(DATA_WIDTH),
                .PKT_NO_FIELD_SIZE (PKT_NO_FIELD_SIZE), 
                .X_SIZE (X_SIZE), 
                .Y_SIZE (Y_SIZE), 
                .ROUTER_FLIT_WIDTH (ROUTER_FLIT_WIDTH),
                .TOTAL_WIDTH (TOTAL_WIDTH)
            ) u_pe (
                .clk(clk),
                .rstn(rstn),
                .in_data(noc_to_pe_data[i]),
                .in_valid(noc_to_pe_valid[i]),
                .in_ready(noc_to_pe_ready[i]),
                .out_data(pe_to_noc_data[i]),
                .out_valid(pe_to_noc_valid[i]),
                .out_ready(pe_to_noc_ready[i])
            );
        end
    endgenerate

   (*DONT_TOUCH = "yes"*) flattened_butterfly_noc #(
        .X_DIM(X_DIM),
        .Y_DIM(Y_DIM),
        .DATA_WIDTH(DATA_WIDTH),
        .PKT_NO_FIELD_SIZE (PKT_NO_FIELD_SIZE), 
        .X_SIZE (X_SIZE), 
        .Y_SIZE (Y_SIZE), 
        .ROUTER_FLIT_WIDTH (ROUTER_FLIT_WIDTH),
        .TOTAL_WIDTH (TOTAL_WIDTH)
    ) u_noc (
        .clk(clk),
        .rstn(rstn),
        .packet_in (packet_in), //from packetizer
        .packet_in_valid(packet_in_valid), 
        .packet_in_ready(packet_in_ready),
        .pe_if_in_data(pe_to_noc_data),
        .pe_if_in_valid(pe_to_noc_valid),
        .pe_if_in_ready(pe_to_noc_ready),
        .pe_if_out_data(noc_to_pe_data),
        .pe_if_out_valid(noc_to_pe_valid),
        .pe_if_out_ready(noc_to_pe_ready),
        .packet_out(packet_out), //to packetizer
        .packet_out_valid(packet_out_valid)
    );

endmodule