`timescale 1ns / 1ps
module can_tx_priority_logic(i_sys_clk, i_reset, i_fifo_data[127:0], o_fifo_r_en, i_tx_empty, 
i_hpb_data[127:0], i_hpb_w_en, o_hpb_r_en, o_send_data[127:0], o_send_en, i_can_clk, 
i_busy_can);

input i_sys_clk;
input i_can_clk;
input i_busy_can;
input i_reset;
input i_tx_empty;
input i_hpb_w_en;
input [127:0] i_fifo_data;
input [127:0] i_hpb_data;

output [127:0] o_send_data;
output o_fifo_r_en;
output o_hpb_r_en;
output o_send_en;

reg [127:0] o_send_data;
reg o_fifo_r_en;
reg o_hpb_r_en;


localparam [3:0] IDLE = 0, HPB_PULL_DATA = 1, FIFO_PULL_DATA =2, WAIT_FOR_FIFO_DATA =3, 
WAIT_FOR_HPB_DATA =4 , HPB_SEND_DATA =5, FIFO_SEND_DATA=6, CAN_SEND_DATA =7;

reg [3:0] SYS_CLK_FSM_STATE, CAN_CLK_FSM_STATE;
reg handshake_can;
reg handshake_sys;
reg o_send_en;

always @(posedge i_sys_clk, posedge i_reset)
begin 
	if (i_reset==1) 
		begin 
		handshake_sys <= 1'b0;
		SYS_CLK_FSM_STATE <= IDLE;
		o_fifo_r_en <= 1'b0;
		o_hpb_r_en  <= 1'b0;
		end 
	else if (i_reset==0)
		begin 
			case(SYS_CLK_FSM_STATE)
				IDLE : 
				begin 
					if (i_hpb_w_en == 1'b0)
					begin 
						SYS_CLK_FSM_STATE<=HPB_PULL_DATA;
					end
					else if (i_tx_empty == 1'b0 && i_hpb_w_en == 1'b1)
					begin 
						SYS_CLK_FSM_STATE<=FIFO_PULL_DATA;
					end
				end
				
				HPB_PULL_DATA :
				begin
					o_hpb_r_en <= 1'b1; 
					SYS_CLK_FSM_STATE <= WAIT_FOR_HPB_DATA;
				end
				
				FIFO_PULL_DATA :
				begin 
					o_fifo_r_en<=1'b1;
					SYS_CLK_FSM_STATE <= WAIT_FOR_FIFO_DATA;
				end
				
				WAIT_FOR_HPB_DATA : 
				begin 
					o_hpb_r_en <= 1'b0;
					SYS_CLK_FSM_STATE <= HPB_SEND_DATA;
				end
				
				WAIT_FOR_FIFO_DATA : 
				begin 
					o_fifo_r_en <= 1'b0;
					SYS_CLK_FSM_STATE <= FIFO_SEND_DATA;
				end
				
				HPB_SEND_DATA : 
				begin 
				o_send_data<=i_hpb_data;
				if (handshake_can == 1'b0 && handshake_sys == 1'b0)
				begin 
				handshake_sys <=1'b1;
				end
				else if (handshake_sys == 1'b1 && handshake_can == 1'b1)
				begin 
				handshake_sys <= 1'b0;
				SYS_CLK_FSM_STATE<=IDLE;
				end
				end
				
				FIFO_SEND_DATA :
				begin 
				o_send_data<=i_fifo_data;
				if (handshake_can == 1'b0 && handshake_sys == 1'b0)
				begin 
				handshake_sys <=1'b1;
				end
				else if (handshake_sys == 1'b1 && handshake_can == 1'b1)
				begin 
				handshake_sys <= 1'b0;
				SYS_CLK_FSM_STATE<=IDLE;
				end
				end
			endcase
		end 
end

always @ (posedge i_can_clk, posedge i_reset)
begin 
	if (i_reset==1)
		begin 
		handshake_can <= 1'b0;
		CAN_CLK_FSM_STATE <= IDLE;
		end 
	else if (i_reset==0)
		begin 
			case(CAN_CLK_FSM_STATE)
				IDLE : 
				begin 
					if (handshake_sys == 1'b1 && handshake_can == 1'b0 && i_busy_can == 1'b0) 
					begin 
					o_send_en<=1'b1;
					CAN_CLK_FSM_STATE<=CAN_SEND_DATA;
					end
					
					else if (handshake_sys == 1'b0 && handshake_can == 1'b1)
					begin 
					handshake_can<=1'b0;
					end 
				end
				
				CAN_SEND_DATA :
				begin 
					o_send_en<=1'b0;
					if (handshake_sys == 1'b1 && handshake_can == 1'b0)
					begin 
						CAN_CLK_FSM_STATE<=IDLE;
						handshake_can<=1'b1;
					end 
				end
				
			endcase 
		end
		
end 

endmodule

