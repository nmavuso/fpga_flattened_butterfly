`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: fb_router
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

module fb_router #(
    parameter DATA_WIDTH = 32,
    parameter X_DIM      = 4,
    parameter Y_DIM      = 4,
    parameter X_COORD    = 0,
    parameter Y_COORD    = 0,
    parameter PKT_NO_FIELD_SIZE = 8, 
    parameter X_SIZE = $clog2(X_DIM),
    parameter Y_SIZE = $clog2(Y_DIM),
    parameter ROUTER_FLIT_WIDTH = (X_SIZE + Y_SIZE + DATA_WIDTH),
    parameter TOTAL_WIDTH = (X_SIZE + Y_SIZE + DATA_WIDTH + PKT_NO_FIELD_SIZE),
    parameter NUM_ROUTERS = X_DIM * Y_DIM,
    // Total number of I/O ports for this router
    parameter NUM_INPUT_PORTS  = 1 + (X_DIM - 1) + (Y_DIM - 1),
    parameter NUM_OUTPUT_PORTS = 1 + (X_DIM - 1) + (Y_DIM - 1)
)(
    input  wire clk,
    input  wire rstn,
    //FROM Packetizer
    input logic [TOTAL_WIDTH - 1:0] packet_in, //from packetizer
    input wire packet_in_valid, //packet from packetizer is valid
    output wire packet_in_ready,
    input  logic [ROUTER_FLIT_WIDTH-1:0]        i_data_pe,
    input  logic                         i_valid_pe,
    output logic                         o_ready_pe,
    output logic [ROUTER_FLIT_WIDTH-1:0]        o_data_pe,
    output logic                         o_valid_pe,
    input  logic                         i_ready_pe,
    input  logic [X_DIM-1:0][ROUTER_FLIT_WIDTH-1:0] i_data_dimX,
    input  logic [X_DIM-1:0]                 i_valid_dimX,
    output logic [X_DIM-1:0]                 o_ready_dimX,
    output logic [X_DIM-1:0][ROUTER_FLIT_WIDTH-1:0] o_data_dimX,
    output logic [X_DIM-1:0]                 o_valid_dimX,
    input  logic [X_DIM-1:0]                 i_ready_dimX,
    input  logic [Y_DIM-1:0][ROUTER_FLIT_WIDTH-1:0] i_data_dimY,
    input  logic [Y_DIM-1:0]                 i_valid_dimY,
    output logic [Y_DIM-1:0]                 o_ready_dimY,
    output logic [Y_DIM-1:0][ROUTER_FLIT_WIDTH-1:0] o_data_dimY,
    output logic [Y_DIM-1:0]                 o_valid_dimY,
    input  logic [Y_DIM-1:0]                 i_ready_dimY,
    //TO Packetizer
    output wire packet_out_valid,    //packet out ready to be sent out.
    output logic [TOTAL_WIDTH - 1:0] packet_out //to packetizer
);

    logic [X_SIZE-1:0] dest_x;
    logic [Y_SIZE-1:0] dest_y;
    int out_port_idx;
    int x_offset;
    int y_offset;
    //Header Format ---
    // A flit is [dest_x][dest_y][payload]
    localparam PAYLOAD_WIDTH = ROUTER_FLIT_WIDTH - X_SIZE - Y_SIZE;
    `define GET_DEST_X(flit) flit[ROUTER_FLIT_WIDTH-1 -: X_SIZE]
    `define GET_DEST_Y(flit) flit[PAYLOAD_WIDTH + Y_SIZE - 1 -: Y_SIZE]

    logic [NUM_INPUT_PORTS-1:0][ROUTER_FLIT_WIDTH-1:0] all_i_data;
    logic [NUM_INPUT_PORTS-1:0]                 all_i_valid;
    logic [NUM_INPUT_PORTS-1:0]                 all_o_ready;

    logic [NUM_INPUT_PORTS-1:0][ROUTER_FLIT_WIDTH-1:0] buf_reg_0, buf_reg_1;
    logic [NUM_INPUT_PORTS-1:0]                 buf_valid_0, buf_valid_1;
    logic [NUM_INPUT_PORTS-1:0]                 buf_pop; // Signal to pop from buffer

    logic [NUM_INPUT_PORTS-1:0][NUM_OUTPUT_PORTS-1:0] route_requests;

    logic [NUM_OUTPUT_PORTS-1:0][NUM_INPUT_PORTS-1:0] arbiter_requests;
    logic [NUM_OUTPUT_PORTS-1:0][NUM_INPUT_PORTS-1:0] arbiter_grants;
    logic [NUM_OUTPUT_PORTS-1:0]                     grant_valid;


    logic [NUM_OUTPUT_PORTS-1:0][ROUTER_FLIT_WIDTH-1:0] xbar_out_data;
    logic [NUM_OUTPUT_PORTS-1:0]                 xbar_out_valid;
    logic [NUM_OUTPUT_PORTS-1:0]                 all_i_ready;
    assign o_ready_pe = 1'b1;
    genvar k; 
    generate
    //X dimension links 
    for (k = 0; k < X_DIM; k++) begin: assign_x_links
        if (k < X_COORD) begin 
            assign all_i_data[1+k] = i_data_dimX[k]; 
            assign all_i_valid[1 + k] = i_valid_dimX[k]; 
            assign o_ready_dimX[k] = all_o_ready[1 + k]; 
            assign all_i_ready[1 + k] = i_ready_dimX[k]; 
        end else if (k > X_COORD) begin 
            assign all_i_data[1 + k - 1] = i_data_dimX[k]; 
            assign all_i_valid[1 + k - 1] = i_valid_dimX[k]; 
            assign o_ready_dimX[k] = all_o_ready[1 + k - 1]; 
            assign all_i_ready[1 + k - 1] = i_ready_dimX[k]; 
        end 
     end
    // Y dimension links 
    
    for (k = 0; k < Y_DIM; k++) begin: assign_y_links
        if (k < Y_COORD) begin 
            assign all_i_data[1 + (X_DIM -1) + k] = i_data_dimY[k]; 
            assign all_i_valid[1+ (X_DIM - 1) + k] = i_valid_dimY[k]; 
            assign o_ready_dimY[k] = all_o_ready[1 + (X_DIM -1) + k]; 
            assign all_i_ready[1+ (X_DIM -1) +k] = i_ready_dimY[k]; 
        end else if (k > Y_COORD) begin
            assign all_i_data[1 + (X_DIM -1) + k - 1] = i_data_dimY[k]; 
            assign all_i_valid[1+ (X_DIM - 1) + k - 1] = i_valid_dimY[k]; 
            assign o_ready_dimY[k] = all_o_ready[1 + (X_DIM -1) + k - 1]; 
            assign all_i_ready[1+ (X_DIM -1) +k -1] = i_ready_dimY[k]; 
        end
    end
    endgenerate
    
    
    // Packet Injection 
    assign packet_in_ready = all_o_ready[0]; 
    assign all_i_data[0] = packet_in[TOTAL_WIDTH-1 -:ROUTER_FLIT_WIDTH];
    assign all_i_valid[0] = packet_in_valid; 
    //Packet Ejection
    assign packet_out = xbar_out_data[0]; 
    assign packet_out_valid = xbar_out_valid[0];
    // Input Buffering 
    genvar in_port;
    for (in_port = 0; in_port < NUM_INPUT_PORTS; in_port = in_port + 1) begin : gen_input_buffers
        // Ready to accept a new flit if the first buffer stage is free.
        assign all_o_ready[in_port] = !buf_valid_0[in_port]; 

        always_ff @(posedge clk or negedge rstn) begin
            if (!rstn) begin
                buf_reg_0[in_port]   <= '0;
                buf_valid_0[in_port] <= 1'b0;
                buf_reg_1[in_port]   <= '0;
                buf_valid_1[in_port] <= 1'b0;
            end else begin
                // Logic for Stage 1 (head of buffer)
                if (buf_pop[in_port]) begin
                    buf_valid_1[in_port] <= 1'b0; // Flit is consumed
                end
                if (!buf_valid_1[in_port] && buf_valid_0[in_port]) begin
                    buf_valid_1[in_port] <= 1'b1; // Flit moves from stage 0 to 1
                    buf_reg_1[in_port]   <= buf_reg_0[in_port];
                    buf_valid_0[in_port] <= 1'b0; // Stage 0 is now free
                end
                
                // Logic for Stage 0 (accepting new flits)
                if (all_o_ready[in_port] && all_i_valid[in_port]) begin
                    buf_valid_0[in_port] <= 1'b1;
                    buf_reg_0[in_port]   <= all_i_data[in_port];
                end
            end
        end
    end

    // For each valid input flit, determine its target output port.
    always_comb begin
        route_requests = '0;
        for (int i = 0; i < NUM_INPUT_PORTS; i++) begin
            if (buf_valid_1[i]) begin
                dest_x = `GET_DEST_X(buf_reg_1[i]);
                dest_y = `GET_DEST_Y(buf_reg_1[i]);
                out_port_idx = -1;

                // Dimension-Order Routing: X then Y
                if (dest_x != X_COORD) begin // Route in X dimension
                    x_offset = (dest_x > X_COORD) ? dest_x - 1 : dest_x;
                    out_port_idx = 1 + x_offset; // PE is port 0
                end else if (dest_y != Y_COORD) begin // Route in Y dimension
                    y_offset = (dest_y > Y_COORD) ? dest_y - 1 : dest_y;
                    out_port_idx = 1 + (X_DIM - 1) + y_offset;
                end else begin // Destination is this local PE
                    out_port_idx = 0;
                end

                if (out_port_idx != -1) begin
                    route_requests[i][out_port_idx] = 1'b1;
                end
            end
        end
    end
    // Transpose route_requests for the arbiters
    always_comb begin
        for (int i = 0; i < NUM_INPUT_PORTS; i++) begin
            for (int j = 0; j < NUM_OUTPUT_PORTS; j++) begin
                arbiter_requests[j][i] = route_requests[i][j];
            end
        end
    end

    genvar out_port;
    for (out_port = 0; out_port < NUM_OUTPUT_PORTS; out_port = out_port + 1) begin : gen_arbiters
       (*DONT_TOUCH = "yes"*) rr_arbiter #(
            .NUM_REQUESTERS(NUM_INPUT_PORTS)
        ) arbiter_inst (
            .clk(clk),
            .rstn(rstn),
            .i_requests(arbiter_requests[out_port]),
            .o_grants(arbiter_grants[out_port]),
            .o_grant_valid(grant_valid[out_port])
        );
    end

    //Crossbar Traversal 
    always_comb begin
        // Default assignments
        xbar_out_data = '0;
        xbar_out_valid = '0;
        buf_pop = '0;

        for (int o = 0; o < NUM_OUTPUT_PORTS; o++) begin
            for (int i = 0; i < NUM_INPUT_PORTS; i++) begin
                if (arbiter_grants[o][i]) begin
                    xbar_out_data[o]  = buf_reg_1[i];
                    xbar_out_valid[o] = buf_valid_1[i];
                    // Pop the buffer only if the transfer will be successful this cycle
                    if (xbar_out_valid[o] && all_i_ready[o]) begin
                        buf_pop[i] = 1'b1;
                    end
                end
            end
        end
    end
    assign {o_data_dimY, o_data_dimX, o_data_pe} = xbar_out_data;
    // The valid signal is only asserted if the downstream consumer is ready
    assign {o_valid_dimY, o_valid_dimX, o_valid_pe} = xbar_out_valid & all_i_ready;

endmodule