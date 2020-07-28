`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: L&T Technology Services Ltd.
// Engineer: Matt Stevenson
// 
// Create Date: 07/17/2020 04:48:21 PM
// Design Name: 
// Module Name: fifo
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


module fifo #(parameter FIFO_DEPTH = 2, DATA_WIDTH = 128)
// ----------- Port Declarations -------------------------------------------
    (
    output reg [DATA_WIDTH-1 : 0] o_fifo_r_data,
    output reg o_full,
    output reg o_empty, 
    output reg o_overflow,
    output reg o_underflow,
    input wire [DATA_WIDTH-1 : 0] i_fifo_w_data,
    input wire i_wr_en,
    input wire i_r_en,
    input wire i_reset,
    input wire i_sys_clk 
    );

// ----------- Internal Variables -------------------------------------------

    reg [DATA_WIDTH-1 : 0] mem_array [0 : FIFO_DEPTH-1];
    reg [FIFO_DEPTH-1 : 0] rd_ptr, wr_ptr;
    reg [FIFO_DEPTH-1 : 0] rd_ptr_next, wr_ptr_next;
    reg full_ff, empty_ff;
    reg full_ff_next, empty_ff_next;
    reg [FIFO_DEPTH : 0] q_reg, q_next;
    reg q_add, q_sub;
// --------------------------------------------------------------------------

// Always block updating internal variables to next values
    always @ (posedge i_sys_clk)
        begin : update
            if (i_reset == 1'b1)
                begin
                    rd_ptr <= {(FIFO_DEPTH-1){1'b0}};
                    wr_ptr <= {(FIFO_DEPTH-1){1'b0}};
                    full_ff <= 1'b0;
                    empty_ff <= 1'b1;
                    q_reg <= {(FIFO_DEPTH){1'b0}};
                end 
            else
                begin
                    rd_ptr <= rd_ptr_next;
                    wr_ptr <= wr_ptr_next;
                    full_ff <= full_ff_next;
                    empty_ff <= empty_ff_next;
                    q_reg <= q_next;
                end
        end
        
// Update read and write pointers as well as empty/full flip-flops
    always @ (i_wr_en, i_r_en, wr_ptr, rd_ptr, empty_ff, full_ff, q_reg)
        begin
            wr_ptr_next = wr_ptr;
            rd_ptr_next = rd_ptr;
            full_ff_next = full_ff;
            empty_ff_next = empty_ff;
            q_add = 1'b0;
            q_sub = 1'b0;
            
        // Check if fifo full during write
        if (i_wr_en == 1'b1 & i_r_en == 1'b0)
            begin
                if (full_ff == 1'b0)
                    begin
                        if (wr_ptr < FIFO_DEPTH-1)
                            begin
                                q_add = 1'b1;
                                wr_ptr_next = wr_ptr + 1;
                                empty_ff_next = 1'b0;
                            end
                        else
                            begin
                                wr_ptr_next = {(FIFO_DEPTH-1){1'b0}};
                                empty_ff_next = 1'b0;
                            end
                        if ((wr_ptr+1 == rd_ptr) || ((wr_ptr == FIFO_DEPTH-1) && (rd_ptr == 1'b0)))
                            full_ff_next = 1'b1;
                    end
            end
        
        // Check if fifo empty during read
        if ((i_wr_en == 1'b0) && (i_r_en == 1'b1))
            begin
                if (empty_ff == 1'b0)
                    begin
                        if (rd_ptr < FIFO_DEPTH-1)
                            begin
                                if (q_reg > 0)
                                    q_sub = 1'b1;
                                else
                                    q_sub = 1'b0;
                                rd_ptr_next = rd_ptr + 1;
                                full_ff_next = 1'b0;
                            end
                        else
                            begin
                                rd_ptr_next = {(FIFO_DEPTH-1){1'b0}};
                                full_ff_next = 1'b0;
                            end
                        
                        // check if fifo empty
                        if ((rd_ptr+1 == wr_ptr) || ((rd_ptr == FIFO_DEPTH-1) && (wr_ptr == 1'b0)))
                            empty_ff_next = 1'b1;
                    end
            end
            
        // Update read and write pointers
        if ((i_wr_en == 1'b1) && (i_r_en == 1'b1))
            begin
                if (wr_ptr < FIFO_DEPTH-1)
                    wr_ptr_next = wr_ptr + 1;
                else
                    wr_ptr_next = {(FIFO_DEPTH-1){1'b0}};
                    
                if (rd_ptr < FIFO_DEPTH-1)
                    rd_ptr_next = rd_ptr + 1;
                else
                    rd_ptr_next = {(FIFO_DEPTH-1){1'b0}};
            end         
        end
        
// memory buffer writing and reading
    always @ (posedge i_sys_clk)
        begin : mem_buffer
            if (i_reset == 1'b1)
                begin
                    mem_array[rd_ptr] <= {(DATA_WIDTH-1){1'b0}};
                    o_fifo_r_data <= {(DATA_WIDTH-1){1'b0}};
                    o_underflow <= 1'b0;
                    o_overflow <= 1'b0;
                end
            else
                begin
                    // successful write attempt
                    if ((i_wr_en == 1'b1) && (full_ff == 1'b0))
                        begin
                            mem_array[wr_ptr] <= i_fifo_w_data;
                            o_underflow <= 1'b0;
                            o_overflow <= 1'b0;
                        end
                    // write enable while full results in overflow
                    else if ((i_wr_en == 1'b1) && (empty_ff == 1'b0))
                        o_overflow <= 1'b1;
                    
                    // successful read attempt
                    if ((i_r_en == 1'b1) && (empty_ff == 1'b0))
                        begin
                            o_fifo_r_data <= mem_array[rd_ptr];
                            o_underflow <= 1'b0;
                        end
                    // read enable while empty results in underflow
                    else if ((i_r_en == 1'b1) && (empty_ff == 1'b1))
                        o_underflow <= 1'b1;
                end
        end
        
// FIFO depth counter
    always @ (q_sub, q_add, q_reg)
        begin : counter
            case ({q_sub, q_add})
                2'b01 :
                    q_next = q_reg + 1;
                2'b10 :
                    q_next = q_reg - 1;
                default : 
                    q_next = q_reg;
            endcase
        end
        
// Connecting internal regs to output ports
    always @ (full_ff, empty_ff)
        begin
            o_full = full_ff;
            o_empty = empty_ff;
        end
    
endmodule
