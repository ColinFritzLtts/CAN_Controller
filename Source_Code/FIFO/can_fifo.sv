`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: L&T Technology Services Ltd.
// Engineer: Matt Stevenson
// 
// Create Date: 07/17/2020 04:48:21 PM
// Design Name: Tx/Rx FIFO
// Module Name: fifo
// Project Name: CAN Controller
// Target Devices: Nexys A7-100T
// Tool Versions: Vivado 2019.2
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fifo #(parameter FIFO_DEPTH = 2, DATA_WIDTH = 128)
// ----------- Port Declarations -------------------------------------------
    (
    input wire [DATA_WIDTH-1 : 0] i_fifo_w_data,
    input wire i_wr_en,
    input wire i_r_en,
    input wire i_reset,
    input wire i_sys_clk,
    output reg [DATA_WIDTH-1 : 0] o_fifo_r_data,
    output reg o_full,
    output reg o_empty, 
    output reg o_overflow,
    output reg o_underflow
    );

// ----------- Internal Variables -------------------------------------------

    reg [DATA_WIDTH-1 : 0] mem_array [0 : FIFO_DEPTH-1];
    reg [FIFO_DEPTH-1 : 0] r_ptr, w_ptr;
    reg [FIFO_DEPTH-1 : 0] r_ptr_next, w_ptr_next;
    reg full_ff, empty_ff;
    reg full_ff_next, empty_ff_next;
    reg [FIFO_DEPTH-1 : 0] ptr_reg, ptr_next;
    reg ptr_add, ptr_sub;
// --------------------------------------------------------------------------

// Always block updating internal variables to next values
    always @ (posedge i_sys_clk) begin : update
        if (i_reset == 1'b1) begin
                r_ptr       <= {(FIFO_DEPTH){1'b0}};
                w_ptr       <= {(FIFO_DEPTH){1'b0}};
                ptr_reg     <= {(FIFO_DEPTH){1'b0}};
                full_ff     <= 1'b0;
                empty_ff    <= 1'b1;
        end 
        else begin
                r_ptr       <= r_ptr_next;
                w_ptr       <= w_ptr_next;
                full_ff     <= full_ff_next;
                empty_ff    <= empty_ff_next;
                ptr_reg     <= ptr_next;
        end
    end
        
    // Update read and write pointers as well as empty/full flip-flops
    always @ (i_wr_en, i_r_en, w_ptr, r_ptr, empty_ff, full_ff, ptr_reg) begin
        w_ptr_next = w_ptr;
        r_ptr_next = r_ptr;
        full_ff_next = full_ff;
        empty_ff_next = empty_ff;
        ptr_add = 1'b0;
        ptr_sub = 1'b0;
        
        // Check if fifo full during write
        if (i_wr_en == 1'b1 & i_r_en == 1'b0) begin
            if (full_ff == 1'b0) begin
                if (w_ptr < FIFO_DEPTH-1) begin
                        ptr_add = 1'b1;
                        w_ptr_next = w_ptr + 1;
                        empty_ff_next = 1'b0;
                end
                else begin
                        w_ptr_next = {(FIFO_DEPTH){1'b0}};
                        empty_ff_next = 1'b0;
                end
                if ((w_ptr+1 == r_ptr) || ((w_ptr == FIFO_DEPTH-1) && (r_ptr == 1'b0))) begin
                    full_ff_next = 1'b1;
                end
            end
        end
        
        // Check if fifo empty during read
        if ((i_wr_en == 1'b0) && (i_r_en == 1'b1)) begin
            if (empty_ff == 1'b0) begin
                if (r_ptr < FIFO_DEPTH-1) begin
                    if (ptr_reg > 0) begin
                        ptr_sub = 1'b1;
                    end
                    else begin
                        ptr_sub = 1'b0;
                        r_ptr_next = r_ptr + 1;
                        full_ff_next = 1'b0;
                    end
                end
                else begin
                    r_ptr_next = {(FIFO_DEPTH){1'b0}};
                    full_ff_next = 1'b0;
                end
                    
                // check if fifo empty
                if ((r_ptr+1 == w_ptr) || ((r_ptr == FIFO_DEPTH-1) && (w_ptr == 1'b0))) begin
                    empty_ff_next = 1'b1;
                end
            end
        end
            
        // Update read and write pointers
        if ((i_wr_en == 1'b1) && (i_r_en == 1'b1)) begin
            if (w_ptr < FIFO_DEPTH-1) begin
                w_ptr_next = w_ptr + 1;
            end
            else begin
                w_ptr_next = {(FIFO_DEPTH){1'b0}};
            end
            if (r_ptr < FIFO_DEPTH-1) begin
                r_ptr_next = r_ptr + 1;
            end
            else begin
                r_ptr_next = {(FIFO_DEPTH){1'b0}};
            end         
        end
    end
            
    // memory buffer writing and reading
    always @ (posedge i_sys_clk) begin : mem_buffer
        if (i_reset == 1'b1) begin
            mem_array[r_ptr] <= {(DATA_WIDTH){1'b0}};
            o_fifo_r_data <= {(DATA_WIDTH){1'b0}};
            o_underflow <= 1'b0;
            o_overflow <= 1'b0;
        end
        else begin
            // successful write attempt
            if ((i_wr_en == 1'b1) && (full_ff == 1'b0)) begin
                mem_array[w_ptr] <= i_fifo_w_data;
                o_underflow <= 1'b0;
                o_overflow <= 1'b0;
            end
            // write enable while full results in overflow
            else if ((i_wr_en == 1'b1) && (empty_ff == 1'b0)) begin
                o_overflow <= 1'b1;
            end
            
            // successful read attempt
            if ((i_r_en == 1'b1) && (empty_ff == 1'b0)) begin
                o_fifo_r_data <= mem_array[r_ptr];
                o_underflow <= 1'b0;
            end
            // read enable while empty results in underflow
            else if ((i_r_en == 1'b1) && (empty_ff == 1'b1)) begin
                o_underflow <= 1'b1;
            end
        end
    end
        
    // FIFO depth counter
    always @ (ptr_sub, ptr_add, ptr_reg) begin : counter
        case ({ptr_sub, ptr_add})
            2'b01 :
                ptr_next = ptr_reg + 1;
            2'b10 :
                ptr_next = ptr_reg - 1;
            default : 
                ptr_next = ptr_reg;
        endcase
    end
        
    // Connecting internal regs to output ports
    always @ (full_ff, empty_ff) begin
        o_full = full_ff;
        o_empty = empty_ff;
    end
    
endmodule
