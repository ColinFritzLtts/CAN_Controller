`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/28/2020 01:02:01 PM
// Design Name: 
// Module Name: Acceptance_Filter_TB
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


module Acceptance_Filter_TB(

    );
 

reg i_sys_clk;
reg i_reset;
reg i_can_clk;
reg [127:0] i_rx_message;
wire o_rx_w_en;
wire [127:0] o_rx_fifo_w_data;
reg i_rx_full;
wire o_acfbsy;
reg [31:0] i_afmr1;
reg [31:0] i_afmr2;
reg [31:0] i_afmr3;
reg [31:0] i_afmr4;
reg [31:0] i_afir1;
reg [31:0] i_afir2;
reg [31:0] i_afir3;
reg [31:0] i_afir4;
reg i_uaf1;
reg i_uaf2;
reg i_uaf3;
reg i_uaf4;
reg i_can_ready;

Acceptance_Filter dut(.i_sys_clk(i_sys_clk), .i_reset(i_reset), .i_can_clk(i_can_clk), .i_can_ready(i_can_ready), 
.i_rx_message(i_rx_message[127:0]), 
.o_rx_w_en(o_rx_w_en), .o_rx_fifo_w_data(o_rx_fifo_w_data[127:0]), .i_rx_full(i_rx_full), .o_acfbsy(o_acfbsy), .i_afmr1(i_afmr1[31:0]),
 .i_afmr2(i_afmr2[31:0]), .i_afmr3(i_afmr3[31:0]), .i_afmr4(i_afmr4[31:0]), .i_afir1(i_afir1[31:0]), .i_afir2(i_afir2[31:0]), 
 .i_afir3(i_afir3[31:0]), .i_afir4(i_afir4[31:0]), .i_uaf1(i_uaf1), .i_uaf2(i_uaf2), .i_uaf3(i_uaf3), .i_uaf4(i_uaf4));

initial
begin 
i_sys_clk = 0;
forever #5 i_sys_clk <=~i_sys_clk;
end

initial
begin 
i_reset = 1;
#20;
i_reset = 0;
end

initial 
begin 
i_can_clk = 0;
forever #10 i_can_clk <= ~i_can_clk;
end 


initial 
begin 
//----------------------------filter_one_accept--------------------
i_rx_message[127:96] <= "11111111111111111111111111111111";
i_rx_message[95:0] <= "101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010";
i_afmr1 = "01111111111111111111111111111110";
i_afir1 = "11111111111111111111111111111111";
i_afmr2 = "00111111111111111111111111111100";
i_afir2 = "11111111111111111111111111111111";
i_afmr3 = "00011111111111111111111111111000";
i_afir3 = "11111111111111111111111111111111";
i_afmr4 = "00001111111111111111111111110000";
i_afir4 = "11111111111111111111111111111111";
i_uaf1 = 1;
i_uaf2 = 0;
i_uaf3 = 0;
i_uaf4 = 0;
#20;
@(posedge i_can_clk);
i_can_ready = 1;
@(posedge i_can_clk);
i_can_ready = 0;
#100;
//----------------------------filter_one_accept---------------------

//----------------------------filter_two_accept--------------------
i_uaf1 = 0;
i_uaf2 = 1;
i_uaf3 = 0;
i_uaf4 = 0;
@(posedge i_can_clk);
i_can_ready = 1;
@(posedge i_can_clk);
i_can_ready = 0;
#100;

//----------------------------filter_two_accept--------------------
//----------------------------filter_three_accept--------------------
i_uaf1 = 0;
i_uaf2 = 0;
i_uaf3 = 1;
i_uaf4 = 0;
@(posedge i_can_clk);
i_can_ready = 1;
@(posedge i_can_clk);
i_can_ready = 0;
#100;

//----------------------------filter_three_accept--------------------
//----------------------------filter_four_accept--------------------
i_uaf1 = 0;
i_uaf2 = 0;
i_uaf3 = 0;
i_uaf4 = 1;
@(posedge i_can_clk);
i_can_ready = 1;
@(posedge i_can_clk);
i_can_ready = 0;
#100;

//----------------------------filter_four_accept--------------------
//----------------------------filter_none_accept--------------------
i_uaf1 = 0;
i_uaf2 = 0;
i_uaf3 = 0;
i_uaf4 = 0;
@(posedge i_can_clk);
i_can_ready = 1;
@(posedge i_can_clk);
i_can_ready = 0;
#100;
//----------------------------filter_none_accept--------------------
//----------------------------discardmessage------------------------
i_uaf1 = 1;
i_uaf2 = 0;
i_uaf3 = 0;
i_uaf4 = 0;
i_rx_message[127:96] <= "11111110111101111111111101111111";
@(posedge i_can_clk);
i_can_ready = 1;
@(posedge i_can_clk);
i_can_ready = 0;
#100;
//----------------------------discardmessage------------------------
end

initial 
begin 
//one
wait (o_rx_w_en == 1);
#5;
if (i_rx_message == o_rx_fifo_w_data)
begin 
    $display("SUCCESS", o_rx_fifo_w_data);
end 
else if (i_rx_message !== o_rx_fifo_w_data)
begin 
    $display("FAILURE", o_rx_fifo_w_data);
end
wait (o_rx_w_en == 0);
//two
wait (o_rx_w_en == 1);
if (i_rx_message == o_rx_fifo_w_data)
begin 
    $display("SUCCESS", o_rx_fifo_w_data);
end 
else if (i_rx_message !== o_rx_fifo_w_data)
begin 
    $display("FAILURE", o_rx_fifo_w_data);
end
wait (o_rx_w_en == 0);
//three
wait (o_rx_w_en == 1);
if (i_rx_message == o_rx_fifo_w_data)
begin 
    $display("SUCCESS", o_rx_fifo_w_data);
end 
else if (i_rx_message !== o_rx_fifo_w_data)
begin 
    $display("FAILURE", o_rx_fifo_w_data);
end
wait (o_rx_w_en == 0);
//four
wait (o_rx_w_en == 1);
if (i_rx_message == o_rx_fifo_w_data)
begin 
    $display("SUCCESS", o_rx_fifo_w_data);
end 
else if (i_rx_message !== o_rx_fifo_w_data)
begin 
    $display("FAILURE", o_rx_fifo_w_data);
end
wait (o_rx_w_en == 0);
//none
wait (o_rx_w_en == 1);
if (i_rx_message == o_rx_fifo_w_data)
begin 
    $display("SUCCESS", o_rx_fifo_w_data);
end 
else if (i_rx_message !== o_rx_fifo_w_data)
begin 
    $display("FAILURE", o_rx_fifo_w_data);
end
wait (o_rx_w_en == 0);
//discard
wait (Acceptance_Filter.ACCEPTANCE_FILTER_FSM_STATE == Acceptance_Filter.DISCARDMESSAGE);
if (i_rx_message !== o_rx_fifo_w_data)
begin 
    $display("SUCCESS", o_rx_fifo_w_data);
end 
else if (i_rx_message == o_rx_fifo_w_data)
begin 
    $display("FAILURE", o_rx_fifo_w_data);
end
wait (o_rx_w_en == 0);
end
endmodule