`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Flattened Butterfly NoC 
//////////////////////////////////////////////////////////////////////////////////

module flattened_butterfly_noc #(
    parameter X_DIM      = 4,
    parameter Y_DIM      = 4,
    parameter DATA_WIDTH = 32,
    parameter PKT_NO_FIELD_SIZE = 8, 
    parameter X_SIZE = $clog2(X_DIM),
    parameter Y_SIZE = $clog2(Y_DIM),
    parameter ROUTER_FLIT_WIDTH = (X_SIZE + Y_SIZE + DATA_WIDTH), 
    parameter TOTAL_WIDTH = (X_SIZE + Y_SIZE + DATA_WIDTH + PKT_NO_FIELD_SIZE),
    parameter NUM_ROUTERS = X_DIM * Y_DIM
)(
    input  wire clk,
    input  wire rstn,
    input logic [TOTAL_WIDTH - 1:0] packet_in, //from packetizer
    input wire packet_in_valid, //packet from packetizer is valid
    output wire packet_in_ready,
    input logic [NUM_ROUTERS-1:0][ROUTER_FLIT_WIDTH-1:0] pe_if_in_data,
    input logic [NUM_ROUTERS-1:0]                 pe_if_in_valid,
    output logic [NUM_ROUTERS-1:0]                 pe_if_in_ready,
    output logic [NUM_ROUTERS-1:0][ROUTER_FLIT_WIDTH-1:0] pe_if_out_data,
    output logic [NUM_ROUTERS-1:0]                 pe_if_out_valid,
    input logic [NUM_ROUTERS-1:0]                 pe_if_out_ready,
    output wire packet_out_valid,    //packet out ready to be sent out.
    output logic [TOTAL_WIDTH - 1:0] packet_out //to packetizer
);

    // --- Flattened Butterfly Links ---
    logic [NUM_ROUTERS-1:0][X_DIM-1:0][ROUTER_FLIT_WIDTH-1:0] flatfly_x_links;
    logic [NUM_ROUTERS-1:0][X_DIM-1:0]                 flatfly_x_valid;
    logic [NUM_ROUTERS-1:0][X_DIM-1:0]                 flatfly_x_ready;

    logic [NUM_ROUTERS-1:0][Y_DIM-1:0][ROUTER_FLIT_WIDTH-1:0] flatfly_y_links;
    logic [NUM_ROUTERS-1:0][Y_DIM-1:0]                 flatfly_y_valid;
    logic [NUM_ROUTERS-1:0][Y_DIM-1:0]                 flatfly_y_ready;

   //Signals to IO Router
   localparam PKT_IO_ROUTER_X = 0; //correct for flexibility
   localparam PKT_IO_ROUTER_Y = 0; //correct for flexibility 
   localparam PKT_IO_FLAT_IDX = PKT_IO_ROUTER_Y * X_DIM + PKT_IO_ROUTER_X;
    genvar x, y;
    for (y = 0; y < Y_DIM; y = y + 1) begin : gen_row
        for (x = 0; x < X_DIM; x = x + 1) begin : gen_col
            localparam FLAT_IDX = y * X_DIM + x;

            logic [X_DIM-1:0][ROUTER_FLIT_WIDTH-1:0] router_in_data_x;
            logic [X_DIM-1:0]                 router_in_valid_x;
            logic [X_DIM-1:0]                 router_in_ready_x;
            logic [Y_DIM-1:0][ROUTER_FLIT_WIDTH-1:0] router_in_data_y;
            logic [Y_DIM-1:0]                 router_in_valid_y;
            logic [Y_DIM-1:0]                 router_in_ready_y;
           
           if (x == PKT_IO_ROUTER_X && y == PKT_IO_ROUTER_Y) begin: io_router
                 (*DONT_TOUCH = "yes"*) fb_router #(
                .DATA_WIDTH(DATA_WIDTH),
                .X_DIM(X_DIM), 
                .Y_DIM(Y_DIM),
                .X_COORD(x),   
                .Y_COORD(y),
                .X_SIZE(X_SIZE), 
                .Y_SIZE(Y_SIZE)
            ) router_inst (
                .clk(clk), 
                .rstn(rstn),
                //Packetizer Interface In
                .packet_in (packet_in), //from packetizer
                .packet_in_valid(packet_in_valid), 
                .packet_in_ready(packet_in_ready),
                
                .i_data_pe(pe_if_in_data[FLAT_IDX]),
                .i_valid_pe(pe_if_in_valid[FLAT_IDX]),
                .o_ready_pe(pe_if_in_ready[FLAT_IDX]),
                .o_data_pe(pe_if_out_data[FLAT_IDX]),
                .o_valid_pe(pe_if_out_valid[FLAT_IDX]),
                .i_ready_pe(pe_if_out_ready[FLAT_IDX]),

                // X-Dimension Ports
                .i_data_dimX(router_in_data_x),
                .i_valid_dimX(router_in_valid_x),
                .o_ready_dimX(router_in_ready_x),
                .o_data_dimX(flatfly_x_links[FLAT_IDX]),
                .o_valid_dimX(flatfly_x_valid[FLAT_IDX]),
                .i_ready_dimX(flatfly_x_ready[FLAT_IDX]),

                // Y-Dimension Ports
                .i_data_dimY(router_in_data_y),
                .i_valid_dimY(router_in_valid_y),
                .o_ready_dimY(router_in_ready_y),
                .o_data_dimY(flatfly_y_links[FLAT_IDX]),
                .o_valid_dimY(flatfly_y_valid[FLAT_IDX]),
                .i_ready_dimY(flatfly_y_ready[FLAT_IDX]),
                
                // Packetizer Interface Out
                .packet_out(packet_out), // to packetizer
                .packet_out_valid(packet_out_valid) // packet out ready to be sent out.
            );
           end else begin 
            (*DONT_TOUCH = "yes"*) fb_router #(
                .DATA_WIDTH(DATA_WIDTH),
                .X_DIM(X_DIM), 
                .Y_DIM(Y_DIM),
                .X_COORD(x),   
                .Y_COORD(y),
                .X_SIZE(X_SIZE), 
                .Y_SIZE(Y_SIZE)
            ) router_inst (
                .clk(clk), 
                .rstn(rstn),
                //Packetizer Interface In
                .packet_in ('0), //from packetizer
                .packet_in_valid(1'b0), 
                .packet_in_ready(),
                
                .i_data_pe(pe_if_in_data[FLAT_IDX]),
                .i_valid_pe(pe_if_in_valid[FLAT_IDX]),
                .o_ready_pe(pe_if_in_ready[FLAT_IDX]),
                .o_data_pe(pe_if_out_data[FLAT_IDX]),
                .o_valid_pe(pe_if_out_valid[FLAT_IDX]),
                .i_ready_pe(pe_if_out_ready[FLAT_IDX]),
    
                // X-Dimension Ports
                .i_data_dimX(router_in_data_x),
                .i_valid_dimX(router_in_valid_x),
                .o_ready_dimX(router_in_ready_x),
                .o_data_dimX(flatfly_x_links[FLAT_IDX]),
                .o_valid_dimX(flatfly_x_valid[FLAT_IDX]),
                .i_ready_dimX(flatfly_x_ready[FLAT_IDX]),
    
                // Y-Dimension Ports
                .i_data_dimY(router_in_data_y),
                .i_valid_dimY(router_in_valid_y),
                .o_ready_dimY(router_in_ready_y),
                .o_data_dimY(flatfly_y_links[FLAT_IDX]),
                .o_valid_dimY(flatfly_y_valid[FLAT_IDX]),
                .i_ready_dimY(flatfly_y_ready[FLAT_IDX]),
                
                // Packetizer Interface Out
                .packet_out(), // to packetizer
                .packet_out_valid() // packet out ready to be sent out.
            );
       
           end
          
                
            genvar i;
            // X-Dimension links
            for (i = 0; i < X_DIM; i = i + 1) begin
                if (i != x) begin
                    localparam SRC_IDX = y * X_DIM + i;
                    assign router_in_data_x[i]  = flatfly_x_links[SRC_IDX][x];
                    assign router_in_valid_x[i] = flatfly_x_valid[SRC_IDX][x];
                    assign flatfly_x_ready[SRC_IDX][x] = router_in_ready_x[i];
                end else begin
                    assign router_in_data_x[i]  = '0;
                    assign router_in_valid_x[i] = 1'b0;
                    assign flatfly_x_ready[FLAT_IDX][i] = 1'b0;
                end
            end

            // Y-Dimension links
            for (i = 0; i < Y_DIM; i = i + 1) begin
                if (i != y) begin
                    localparam SRC_IDX = i * X_DIM + x;
                    assign router_in_data_y[i]  = flatfly_y_links[SRC_IDX][y];
                    assign router_in_valid_y[i] = flatfly_y_valid[SRC_IDX][y];
                    assign flatfly_y_ready[SRC_IDX][y] = router_in_ready_y[i];
                end else begin
                    assign router_in_data_y[i]  = '0;
                    assign router_in_valid_y[i] = 1'b0;
                    assign flatfly_y_ready[FLAT_IDX][i] = 1'b0;
                end
            end
        end
    end
endmodule
