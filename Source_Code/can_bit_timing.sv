`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: L&T Technology Services Ltd.
// Engineer: Andrew Newman
// 
// Create Date: 07/15/2020 03:16:11 PM
// Design Name: CAN Bit Timing Module
// Module Name: can_bit_timing
// Project Name: CAN Controller
// Target Devices: Nexys A7-100
// Tool Versions: Vivado 2019.2
// Description: A Bit Timing Module, used in the synchronization stage of CAN controller
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module can_bit_timing(
    input wire i_can_clk = 1'b0,
    input wire i_reset = 1'b0,
    input wire i_tx_bit = 1'b1,
    output reg o_samp_tick,
    output reg o_rx_bit = 1'b1,
    input wire [1:0] i_sjw = 2'b00,
    input wire [2:0] i_ts2 = 3'b000,
    input wire [3:0] i_ts1 = 4'b0000,
    output reg CAN_PHY_TX,
    input wire CAN_PHY_RX = 1'b1
    );
    parameter SYNC = 0;         //
    parameter TS1 = 1;          //States as parameters
    parameter TS2 = 2;          //
     
//--------------------------------Internal Signals--------------------------------
    
    reg [1:0] int_state;                  // Current State(SYNC, TS1, or TS2)
    reg [1:0] int_state_next;             // Next State (SYNC, TS1, or TS2)
    reg int_samp_tick = 1'b0;             // Buffer variable for o_samp_tick 
    reg [5:0] int_rxbit_history = 5'h00;  // Stores six last received bits on the bus
    reg int_rx_compare = 1'b0;            // Current value of the CAN_PHY_RX
    reg int_rx_prev_compare = 1'b0;       // Past value of the CAN_PHY_RX
    
    integer int_state_counter = 0;        // Frame Counting
    integer int_ts1 = i_ts1 + 1;          // Converting the ts1 to proper length for reading convenience
    integer int_ts1_next = i_ts1 + 1;     // Dynamic frame adjustment variable
    integer int_ts2 = i_ts2 + 1;          // Converting the ts1 to proper length for reading convenience
    integer int_ts2_next = i_ts2 + 1;     // Dynamic frame adjustment variable
    
//--------------------------------Next State Logic--------------------------------
    
    always @ (i_reset, int_state, int_state_counter)
    begin : NEXT_STATE
        if (i_reset == 1'b1) begin
            int_state_next = SYNC; //BTM_RST_05
        end
        else begin
            //State calculations
            if (int_state == SYNC) begin
                int_state_next = TS1; //BTM_FSM_04
            end 
            else if (int_state == TS1) begin
                if(int_state_counter < int_ts1) begin
                    int_state_next = TS1; //BTM_FSM_04
                end
                else if(int_state_counter < int_ts1 + int_ts2) begin
                    int_state_next = TS2; //BTM_FSM_05
                end
                else begin
                    int_state_next = SYNC; //BTM_FSM_03
                end
            end 
            else if (int_state == TS2) begin
                if(int_state_counter < int_ts1 + int_ts2) begin
                    int_state_next = TS2;
                end
                else begin
                    int_state_next = SYNC;
                end
            end 
            else begin
                int_state_next = SYNC;
            end
        end
    end
    
    always_ff @(posedge i_can_clk)
    begin: COUNTER
        if (i_reset == 1'b1) begin
            int_state_counter = 0;
        end
        else begin
            //Advancing the state frame counter
            int_state_counter = int_state_counter + 1; //BTM_FSM_02
            //State calculations
            if(int_state_next == SYNC) begin
                int_state_counter = 0; //BTM_FSM_06
            end
        end
    end
//--------------------------------State Advancement Logic--------------------------------
    
    always_ff @ (posedge i_can_clk)
    begin : CUR_STATE
        if (i_reset == 1'b1) begin
            int_state = SYNC; //BTM_RST_05
        end
        else begin
            int_state <= int_state_next; //BTM_FSM_01
        end
    end
    
//--------------------------------Syncronization Logic--------------------------------
    
    always @ (posedge i_can_clk)
    begin : SYNC_STAGE
       if (i_reset == 1'b1) begin
            o_samp_tick = 1'b0; //BTM_RST_01
            CAN_PHY_TX = 1'b1;  //BTM_RST_02
            o_rx_bit = 1'b1;    //BTM_RST_03
            int_samp_tick = 1'b0;
            int_ts1_next = i_ts1 + 1;
            int_ts2_next = i_ts2 + 1;
            int_ts1 = i_ts1 + 1;
            int_ts2 = i_ts2 + 1;
        end
        else begin
            //o_samp_tick generation
            if ( (int_state == TS1) && (int_state_next == TS2)) begin
                int_samp_tick = 1'b1; //BTM_SYNC_01
            end
            else begin
                int_samp_tick = 1'b0;
            end
            o_samp_tick <= int_samp_tick; //BTM_SYNC_02
            
            //CAN_PHY_TX passthrough
            if (int_state == SYNC) begin
                CAN_PHY_TX = i_tx_bit; //BTM_SYNC_03
            end //lack of else condition implies a latch, which satisfies BTM_SYNC_04
            
            //o_rx_bit passthrough
            if ((int_state == TS1) && (int_state_next == TS2)) begin
                CAN_PHY_TX = i_tx_bit; //BTM_SYNC_05
            end //lack of else condition implies a latch, which satisfies BTM_SYNC_06
            
            //int_ts1 and int_ts2 permutations
            int_rx_prev_compare = int_rx_compare; //BTM_SYNC_08
            int_rx_compare = CAN_PHY_RX;          //BTM_SYNC_07
            
            if(int_rx_compare != int_rx_prev_compare) begin
                if(int_state_counter <= int_ts1 - (i_sjw + 1)) begin
                    int_ts2_next = int_ts2 - i_sjw;             //BTM_SYNC_09
                end
                else if(int_state_counter <= int_ts1) begin
                    int_ts2_next = int_ts2 - int_state_counter; //BTM_SYNC_10
                end
                else if(int_state_counter <= int_ts1 + i_sjw) begin
                    int_ts1_next = int_state_counter;           //BTM_SYNC_11
                end
                else if(int_state_counter <= i_sjw) begin
                    int_ts1_next = int_state_counter;           //BTM_SYNC_12
                end
            end
            
            if(int_state == SYNC) begin
                if(int_rxbit_history[5:0] == 6'b000000 || int_rxbit_history[5:0] == 6'b111111) begin
                    int_ts1 = i_ts1 + 1;        //BTM_SYNC_13 
                    int_ts2 = i_ts2 + 1;        //BTM_SYNC_14
                    int_ts1_next = int_ts1 + 1; // just a precaution; it should be overriden usually
                    int_ts2_next = int_ts2 + 1;
                end
                else begin
                    int_ts1 = int_ts1_next + 1; //BTM_SYNC_15
                    int_ts2 = int_ts2_next + 1; //BTM_SYNC_16
                end
            end
            
            //rx_bit_history generation
            if ( (int_state == TS1) && (int_state_next == TS2)) begin
                int_rxbit_history[5:0] = {int_rxbit_history[4:0], CAN_PHY_RX};
            end
            else begin
                int_rxbit_history = int_rxbit_history;
            end
        end 
    end
endmodule