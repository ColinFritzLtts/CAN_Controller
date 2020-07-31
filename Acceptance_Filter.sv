`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/28/2020 09:39:25 AM
// Design Name: 
// Module Name: Acceptance_Filter
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


module Acceptance_Filter(i_sys_clk, i_reset, i_can_clk, i_can_ready, i_rx_message[127:0], 
o_rx_w_en, o_rx_fifo_w_data[127:0], i_rx_full, o_acfbsy, i_afmr1[31:0], i_afmr2[31:0], 
i_afmr3[31:0], i_afmr4[31:0], i_afir1[31:0], i_afir2[31:0], i_afir3[31:0], i_afir4[31:0],
i_uaf1, i_uaf2, i_uaf3, i_uaf4);

input i_sys_clk;
input i_reset;
input i_can_clk;
input i_can_ready;
input [127:0] i_rx_message;
output o_rx_w_en;
output [127:0] o_rx_fifo_w_data;
input i_rx_full;
output o_acfbsy;
input [31:0] i_afmr1;
input [31:0] i_afmr2;
input [31:0] i_afmr3;
input [31:0] i_afmr4;
input [31:0] i_afir1;
input [31:0] i_afir2;
input [31:0] i_afir3;
input [31:0] i_afir4;
input i_uaf1;
input i_uaf2;
input i_uaf3;
input i_uaf4;

reg o_acfbsy;
reg o_rx_w_en;
reg [127:0] o_rx_fifo_w_data;
reg [31:0] mask_msg_one;
reg [31:0] mask_msg_two;
reg [31:0] mask_msg_three;
reg [31:0] mask_msg_four;
reg [31:0] mask_id_one;
reg [31:0] mask_id_two;
reg [31:0] mask_id_three;
reg [31:0] mask_id_four;
wire can_ready_synched;

localparam [2:0] IDLE = 0, PROCESSING = 1, ACCEPTMESSAGE =2, DISCARDMESSAGE =3;

reg [2:0] int_state;
reg [2:0] int_state_next;


double_synchronizer can_synchronizer(.i_sys_clk(i_sys_clk), .i_reset(i_reset), .synched(can_ready_synched), .un_synched(i_can_ready));

always @(int_state, i_reset, i_rx_message, can_ready_synched)
begin  : NXT_STATE
    if (i_reset == 1'b1) begin 
        int_state_next = IDLE;
        o_rx_w_en = 1'b0;
        o_acfbsy = 1'b0;
        o_rx_fifo_w_data[127:0] = 128'd0;
    end
    else begin 
        case(int_state)
				IDLE : begin 
				    o_rx_w_en = 1'b0;
				    if (can_ready_synched == 1'b1) begin 
				        int_state_next = PROCESSING;
				    end
				    else begin 
				         int_state_next=IDLE;
				    end
				end
				
				PROCESSING : begin 
				    if (mask_id_one !== 32'b0 && mask_msg_one !==32'b0 && i_uaf1 == 1'b1 && mask_id_one == mask_msg_one) begin 
				        int_state_next= ACCEPTMESSAGE;
				    end
				    
				    else if (mask_id_two !== 32'b0 && mask_msg_two !==32'b0 && i_uaf2 == 1'b1 && mask_id_two == mask_msg_two) begin 
				        int_state_next= ACCEPTMESSAGE;
				    end
				    
				    else if (mask_id_three !== 32'b0 && mask_msg_three !==32'b0 && i_uaf3 == 1'b1 && mask_id_three == mask_msg_three) begin 
				        int_state_next= ACCEPTMESSAGE;
				    end
				    
			        else if (mask_id_four !== 32'b0 && mask_msg_four !==32'b0 && i_uaf4 == 1'b1 && mask_id_four == mask_msg_four) begin 
				        int_state_next= ACCEPTMESSAGE;
				    end
				    else if (i_uaf1 == 1'b0 && i_uaf2 == 1'b0 && i_uaf3 == 1'b0 && i_uaf4 == 1'b0) begin 
				        int_state_next= ACCEPTMESSAGE;
				    end
				    else if (mask_msg_one == 32'b0 && mask_id_one == 32'b0 && mask_msg_two == 32'b0 && mask_id_two == 32'b0 && mask_msg_three == 32'b0 && mask_id_three == 32'b0 && mask_msg_four == 32'b0 && mask_id_four == 32'b0) begin 
				        int_state_next= ACCEPTMESSAGE;
				    end
				    else begin 
				        int_state_next= DISCARDMESSAGE;
				    end
				end
				
				ACCEPTMESSAGE : begin 
				    o_rx_w_en = 1'b1;
				    o_rx_fifo_w_data <= i_rx_message;
				    int_state_next= IDLE;
				end
				
				DISCARDMESSAGE : begin 
				    o_rx_w_en = 1'b0;
				    int_state_next= IDLE;
				end
				
				default : begin 
				    o_rx_w_en = 1'b0;
				    int_state_next= IDLE;
				end
        endcase
    end
end

always @(posedge i_sys_clk, posedge i_reset)
begin : CUR_STATE
	if (i_reset == 1'b1) begin 
        int_state = IDLE; 
    end
    else begin 
        int_state <= int_state_next;
	end
end

always @(i_afir1, i_afir2, i_afir3, i_afir4, i_afmr1, i_afmr2, i_afmr3, i_afmr4, i_uaf1, i_uaf2, i_uaf3, i_uaf4, i_rx_message)
begin 
    if (i_uaf1 == 1'b1) begin 
        mask_msg_one <= i_afmr1 & i_rx_message[127:96];
    end
    else begin 
        mask_msg_one <= 32'b0;
    end 
    
    if (i_uaf2 == 1'b1) begin 
        mask_msg_two <= i_afmr2 & i_rx_message[127:96];
    end
    else begin 
        mask_msg_two <= 32'b0;
    end
     
    if (i_uaf3 == 1'b1) begin 
        mask_msg_three <= i_afmr3 & i_rx_message[127:96];
    end
    else begin 
        mask_msg_three <= 32'b0;
    end 
    
    if (i_uaf4 == 1'b1) begin 
        mask_msg_four <= i_afmr4 & i_rx_message[127:96];
    end
    else begin 
        mask_msg_four <= 32'b0;
    end
     
    if (i_uaf1 == 1'b1) begin 
        mask_id_one <= i_afir1 & i_afmr1;
    end
    else begin 
        mask_id_one <= 32'b0;
    end
    
    if (i_uaf2 == 1'b1) begin 
        mask_id_two <= i_afir2 & i_afmr2;
    end
    else begin 
        mask_id_two <= 32'b0;
    end
    
    if (i_uaf3 == 1'b1) begin 
        mask_id_three <= i_afir3 & i_afmr3;
    end
    else begin 
        mask_id_three <= 32'b0;
    end
    
    if (i_uaf4 == 1'b1) begin 
        mask_id_four <= i_afir4 & i_afmr4;
    end
    else begin 
        mask_id_four <= 32'b0;
    end
end

endmodule
