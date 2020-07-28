`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: L&T Technology Services Ltd.
// Engineer: 
// 
// Create Date: 07/19/2020 02:42:22 PM
// Design Name: FIFO Testbench
// Module Name: fifo_tb
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


module fifo_tb;

    reg i_sys_clk;
    reg i_reset;
    reg i_wr_en;
    reg i_r_en;
    reg [127 : 0] i_fifo_w_data;
    wire o_empty;
    wire o_full;
    wire o_underflow;
    wire o_overflow;
    wire [127 : 0] o_fifo_r_data;
    
    fifo DUT(
        .i_sys_clk      (i_sys_clk),
        .i_reset        (i_reset),
        .i_wr_en        (i_wr_en),
        .i_r_en         (i_r_en),
        .i_fifo_w_data  (i_fifo_w_data),
        .o_empty        (o_empty),
        .o_full         (O_full),
        .o_underflow    (o_underflow),
        .o_overflow     (o_overflow),
        .o_fifo_r_data  (o_fifo_r_data)
    );
    
    initial begin
        i_sys_clk = 0;
        i_reset = 1;
        i_wr_en = 0;
        i_r_en = 0;
    end
    
    initial begin
        $dumpfile ("fifo_tb.vcd"); 
        $dumpvars;
    end
    
    initial  begin
        $display("\t\ttime,\ti_sys_clk,\ti_reset,\ti_wr_en,\ti_r_en,\to_empty,\to_full,\to_underflow,\to_overflow\t"); 
        $monitor("%d,\t%d,\t%d,\t%d,\t%d",$time, i_sys_clk, i_reset, i_wr_en, i_r_en, o_empty, o_full, o_underflow, o_overflow); 
    end 
    
    initial
        #100 $finish;
        
    initial begin
        #10 i_reset = 0;
        i_fifo_w_data = 128'h00000000000000000000000000000001;
        i_wr_en = 1;
        #10 i_wr_en = 0;
        i_fifo_w_data = 128'h10101010101010101010101010101010;
        i_wr_en = 1;
        #10 i_wr_en = 0;
        i_wr_en = 1;
        #10 i_wr_en = 0;
        i_fifo_w_data = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        i_wr_en = 1;
        #10 i_wr_en = 0;
        i_fifo_w_data = 128'h11111111111111111111111111111111;
        i_r_en = 1;
        #10 i_wr_en = 1;
        
    end
    
    always 
        #5 i_sys_clk = !i_sys_clk;
    
endmodule
