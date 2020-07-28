`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/23/2020 02:40:12 PM
// Design Name: 
// Module Name: Tx_Priority_Demo_TB
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


module Tx_Priority_Demo_TB(

    );

reg i_sys_clk;
reg i_reset;
wire o_fifo_r_en;
reg i_tx_empty;
reg i_hpb_w_en;
wire [127:0] o_send_data;
wire o_send_en;
reg i_can_clk;
reg i_busy_can;
reg [127:0] i_hpb_data;
reg [127:0] i_fifo_data;

can_tx_priority_logic dut(.i_sys_clk(i_sys_clk), .i_reset(i_reset), .i_fifo_data(i_fifo_data[127:0]), .o_fifo_r_en(o_fifo_r_en),
 .i_tx_empty(i_tx_empty), 
.i_hpb_data(i_hpb_data[127:0]), .i_hpb_w_en(i_hpb_w_en), .o_hpb_r_en(o_hpb_r_en), .o_send_data(o_send_data[127:0]), 
.o_send_en(o_send_en), .i_can_clk(i_can_clk), 
.i_busy_can(i_busy_can));

initial begin 
i_sys_clk = 0;

forever #5 i_sys_clk =~i_sys_clk;

end 
initial begin 
i_can_clk= 0;
forever #10 i_can_clk = ~i_can_clk;
end
initial begin 
i_reset = 1;
#20;
i_reset = 0;
end 

initial begin 
//------------------------HPB_AND_FIFO_CONTAINING_DATA_TEST---------------------------------------
#20; 
i_hpb_w_en = 1'b0;
i_tx_empty = 1'b0;
i_busy_can = 1'b0;
i_fifo_data[127:0] = "1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111";
i_hpb_data[127:0] =  "0111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110"; 
wait(o_send_en == 1);
if (i_hpb_data == o_send_data)
begin 
    $display("SUCCESS", o_send_data);
end 
else if (i_hpb_data !== o_send_data)
begin 
    $display("FAILURE", o_send_data);
end

//------------------------HPB_AND_FIFO_CONTAINING_DATA_TEST---------------------------------------
//----------------HPB_ONLY_CONTAINING_DATA_TEST---------------------------------------------------
@(posedge i_can_clk); // o_send_en goes low
#1;
i_tx_empty = 1;
i_hpb_data[127:0] = "0111111111111111111111011111111111111011111111111111111111101111111111111111111111111111111111111111111111111111111111111111111111101111111111111100";
@(posedge i_sys_clk); // moves sys to idle

@(posedge i_can_clk); // reset
wait(o_send_en == 1);
if (i_hpb_data == o_send_data)
begin 
    $display("SUCCESS", o_send_data);
end
else if (i_hpb_data !== o_send_data)
begin 
    $display("FAILURE", o_send_data);
end

//------------------------HPB_ONLY_CONTAINING_DATA_TEST------------------------------------------


//------------------------FIFO_ONLY_CONTAINING_DATA_TEST------------------------------------------
@(posedge i_can_clk); // o_send_en goes low
#1 
i_hpb_w_en = 1;
i_tx_empty = 0;
@(posedge i_sys_clk); // sys side is sent to idle
@(posedge i_can_clk); // reset 
wait (o_send_en == 1);
if (i_fifo_data == o_send_data)
begin 
    $display("SUCCESS", o_send_data);
end
else if (i_fifo_data !== o_send_data)
begin 
    $display("FAILURE", o_send_data);
end
//------------------------FIFO_ONLY_CONTAINING_DATA_TEST------------------------------------------


//------------------------NO_DATA_AVAILABLE_TEST--------------------------------------------------
@(posedge i_can_clk); // o_send_en low
i_hpb_w_en = 1;
i_tx_empty = 1;
@(posedge i_sys_clk); // sys side set to idle
@(posedge i_can_clk); // reset 
if (dut.SYS_CLK_FSM_STATE == dut.IDLE)
begin 
    $display("SUCCESS", dut.SYS_CLK_FSM_STATE);
end
else if ( dut.SYS_CLK_FSM_STATE !== dut.IDLE )
begin 
    $display("FAILURE", dut.SYS_CLK_FSM_STATE);
end

//------------------------NO_DATA_AVAILABLE_TEST--------------------------------------------------
end
endmodule
