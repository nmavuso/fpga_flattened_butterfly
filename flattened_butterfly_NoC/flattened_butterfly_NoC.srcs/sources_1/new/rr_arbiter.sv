`timescale 1ns/1ps

module rr_arbiter #(
    parameter NUM_REQUESTERS = 4
)(
    input  wire                          clk,
    input  wire                          rstn,
    input  wire [NUM_REQUESTERS-1:0]     i_requests, // Bitmask of requests
    output logic [NUM_REQUESTERS-1:0]    o_grants,   // One-hot grant signal
    output logic                         o_grant_valid // Asserted if any grant is given
);

    logic [NUM_REQUESTERS-1:0] priority_reg; // One-hot pointer to the highest priority requester

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            priority_reg <= 1'b1; // Initial priority to requester 0
        end else if (o_grant_valid) begin
            // Rotate priority to the requester immediately following the one just granted
            priority_reg <= {o_grants[NUM_REQUESTERS-2:0], o_grants[NUM_REQUESTERS-1]};
        end
    end

    // Combinational logic for arbitration - CORRECTED
    always_comb begin
        logic [NUM_REQUESTERS-1:0]  requests_after_priority;
        logic [NUM_REQUESTERS-1:0]  grant_after_priority;
        logic [NUM_REQUESTERS-1:0]  grant_before_priority;
        
        o_grant_valid = |i_requests;
        o_grants = '0;

        // Create a mask of all requesters at or after the current priority holder
        requests_after_priority = 0;
        for (int i = 0; i < NUM_REQUESTERS; i++) begin
            if (priority_reg[i]) begin
                requests_after_priority = i_requests >> i;
                break;
            end
        end

        // Pass 1: Grant to the first requesting bit at or after the priority pointer
        grant_after_priority = 0;
        for (int i = 0; i < NUM_REQUESTERS; i++) begin
            if (requests_after_priority[i]) begin
                grant_after_priority = (1'b1 << i);
                // Rotate back to original position
                for (int j = 0; j < NUM_REQUESTERS; j++) begin
                    if (priority_reg[j]) begin
                        grant_after_priority = grant_after_priority << j;
                        break;
                    end
                end
                break;
            end
        end

        // Pass 2: If no grant in pass 1, grant to the first requesting bit from the start (wrap-around)
        grant_before_priority = 0;
        for (int i = 0; i < NUM_REQUESTERS; i++) begin
            if (i_requests[i]) begin
                grant_before_priority = 1'b1 << i;
                break;
            end
        end

        if (|grant_after_priority) begin
            o_grants = grant_after_priority;
        end else begin
            o_grants = grant_before_priority;
        end

        // Ensure grant is cleared if there are no requests
        if (!o_grant_valid) begin
            o_grants = '0;
        end
    end

endmodule


