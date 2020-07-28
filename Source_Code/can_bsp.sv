`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: L&T Technology Services Ltd.
// Engineer: Andrew Newman
// 
// Create Date: 07/20/2020 10:38:28 AM
// Design Name: CAN Bitstream Processor
// Module Name: can_bsp
// Project Name: CAN Controller 
// Target Devices: Nexys A7-100
// Tool Versions: Vivado 2019.2
// Description: CAN Bitstream Processor module for CAN Controller
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module can_bsp(
    input wire i_sleep,
    input wire i_lback,
    input wire i_reset,
    input wire [0:127] i_send_data,
    input wire i_send_en,
    input wire i_can_clk,
    input wire i_cen,
    output reg o_busy_can,
    output reg o_acker,
    output reg o_berr,
    output reg o_ster,
    output reg o_fmer,
    output reg o_crcer,
    output reg o_can_ready,
    output reg [0:127] o_rx_message,
    output reg [7:0] o_rec,
    output reg [7:0] o_tec,
    output reg o_errwrn,
    output reg o_bbsy,
    output reg o_bidle,
    output reg o_normal,
    output reg o_sleep,
    output reg o_tx_bit,
    input wire i_samp_tick,
    input wire i_rx_bit,
    output reg o_lback,
    output reg o_config,
    output reg o_wakeup,
    output reg o_bsoff,
    output reg o_error,
    output reg o_txok,
    output reg o_arblst,
    output reg [1:0] o_estat
    );
//--------------------------------Internal Parameters--------------------------------
    parameter MCONFIG = 0;            //
    parameter MLOOPBACK = 1;          //States as parameters
    parameter MSLEEP = 2;             //
    parameter MNORMAL = 3;            //
    parameter IDLE = 0;               //
    parameter BUSY = 1;               //States as parameters
    parameter IFS = 2;                //
    
     
//--------------------------------Internal Signals--------------------------------
    //States
    reg [1:0]   int_mstate;                  // Current Module State(MCONFIG, MLOOPBACK, MSLEEP, or MNORMAL)
    reg [1:0]   int_mstate_next;             // Next Module State (MCONFIG, MLOOPBACK, MSLEEP, or MNORMAL)
    reg [1:0]   int_tstate;                  // Current Transmit State(IDLE, BUSY, or IFS)
    reg [1:0]   int_tstate_next;             // Next Receive State (IDLE, BUSY, or IFS)
    reg [1:0]   int_rstate;                  // Current Transmit State(IDLE, BUSY, or IFS)
    reg [1:0]   int_rstate_next;             // Next Receive State (IDLE, BUSY, or IFS)
    
    //Data storage
    reg [7:0]   int_txbit_history;           // History of recentrly transmitted bits
    reg [7:0]   int_rxbit_history;           // History of recentrly received bits
    reg [0:127] int_txframe_reg;             // Storage for assembled frame to be transmitted
    reg [0:127] int_rxframe_reg;             // Storage for assembly of currently received frame
    reg [14:0] int_crc_checksum;             // Storage for Tx message CRC checksum
    reg [14:0] int_rx_crc_checksum;          // Storage for Rx message CRC checksum to be compared to the sent one
    reg         int_tx_send_bit;             // Storage for bit to be transferred
    reg         int_can_ready;               // Buffer for the can_ready signal
    reg         int_error;                   // Error generation pair
    reg         int_arblst;                  // Arbitration Lost signal generation pair
    
    //Counters
    integer     int_txbit_counter;           // Counter for number of bits transmitted in current frame
    integer     int_rxbit_counter;           // Counter for number of bits received in current frame
    integer     int_tx_frame_end;            // End pointer for the transmit frame
    integer     int_rx_frame_end;            // End pointer for the receive frame
    
    //CRC Generation Function Invocation
    assign int_crc_checksum = nextCRC15_D64(i_send_data_r[63:0],
                                            15'h4599);
    assign int_rx_crc_checksum = nextCRC15_D64(int_rxframe_reg_r[63:0],
                                               15'h4599);    
    //Shortcuts, reverse vector declarations
    wire [127:0] i_send_data_r;
    assign i_send_data_r = {<<{i_send_data}};
    wire [127:0] int_rxframe_reg_r;
    assign int_rxframe_reg_r = {<<{int_rxframe_reg_r}};

//--------------------------------Next Module State Logic--------------------------------
    always @ (i_reset, int_mstate)
    begin : NEXT_MSTATE
        if (i_reset == 1'b1) begin
            int_mstate_next = MSLEEP; //BSP_RST_24
        end
        else begin
            //State calculations
            if (i_cen == 1'b0) begin
                int_mstate_next = MCONFIG; // BSP_MFSM_02
            end
            else begin
                if(i_lback == 1'b1) begin
                    int_mstate_next = MLOOPBACK; // BSP_MFSM_03
                end
                else begin
                    if(i_sleep == 1'b1) begin
                        int_mstate_next = MSLEEP; // BSP_MFSM_04
                    end
                    else begin
                        int_mstate_next = MNORMAL; // BSP_MFSM_05
                    end
                end
            end
        end
    end
    
//--------------------------------Next Transmit State Logic--------------------------------
    always @ (i_reset, int_tstate, i_samp_tick)
    begin : NEXT_TSTATE
        if (i_reset == 1'b1) begin
            int_tstate_next = IDLE; 
        end
        else begin
            //State calculations
            if (int_mstate == MSLEEP || int_mstate == MCONFIG) begin
                int_tstate_next = IFS; //BSP_SOVR_01
            end
            else if (int_tstate == BUSY) begin
                if(int_txbit_history[7:0] == 8'hFF) begin
                    int_tstate_next = IFS; //BSP_TFSM_02
                end
                else begin
                    int_tstate_next = BUSY;
                end
            end
            else if(int_tstate == IFS) begin
                if((int_txbit_history[2:0] == 3'b111) && (i_send_en == 1'b1)) begin
                    int_tstate_next = BUSY; //BSP_TFSM_03
                end
                else if ((int_txbit_history[3:0] == 4'b1110)) begin
                    int_tstate_next = IDLE; //BSP_TFSM_04
                end
                else begin
                    int_tstate_next = IFS;
                end
            end
            else begin
                if(int_txbit_history[7:0] == 8'hFF) begin
                    int_tstate_next = IFS; //BSP_TFSM_05
                end
                else begin
                    int_tstate_next = IDLE;
                end
            end
        end
    end
    always_ff @ (posedge i_can_clk)
    begin : TXBIT_HISTORY_GEN
        if (i_reset == 1'b1) begin
            int_txbit_history = 8'hAA; 
        end
        else begin
            if(i_samp_tick == 1'b1) begin
                int_txbit_history[7:0] = {int_txbit_history[6:0], int_tx_send_bit}; //BSP_FRTX_01
            end
        end
    end
    
//--------------------------------Next Receive State Logic--------------------------------
    always @ (i_reset, int_rstate, i_samp_tick)
    begin : NEXT_RSTATE
        if (i_reset == 1'b1) begin
            int_rstate_next = IDLE; 
        end
        else begin
            //State calculations
            if (int_mstate == MSLEEP || int_mstate == MCONFIG) begin
                int_rstate_next = IFS; //BSP_SOVR_02
            end
            else if (int_rstate == BUSY) begin
                if(int_rxbit_history[7:0] == 8'hFF) begin
                    int_rstate_next = IFS; //BSP_RFSM_02
                end
                else begin
                    int_rstate_next = BUSY;
                end
            end
            else if(int_rstate == IFS) begin
                if((int_rxbit_history[2:0] == 3'b111) && (i_send_en == 1'b1)) begin
                    int_rstate_next = BUSY; //BSP_RFSM_03
                end
                else begin
                    int_rstate_next = IFS;
                end
            end
            else begin
                if(int_rxbit_history[7:0] == 8'hFF) begin
                    int_rstate_next = IFS; //BSP_RFSM_04
                end
                else begin
                    int_rstate_next = IDLE;
                end
            end
        end
    end
    always_ff @ (posedge i_can_clk)
    begin : RXBIT_HISTORY_GEN
        if (i_reset == 1'b1) begin
            int_rxbit_history = 8'hAA; 
        end
        else begin
            if(i_samp_tick == 1'b1) begin
                int_rxbit_history[7:0] = {int_rxbit_history[6:0], i_rx_bit}; //BSP_FRRX_01
            end
        end
    end 
       
//--------------------------------State Advancement Logic--------------------------------
    always_ff @ (posedge i_can_clk)
    begin : CUR_MSTATE
        if (i_reset == 1'b1) begin
            int_mstate = MSLEEP; //BSP_RST_23
        end
        else begin
            int_mstate <= int_mstate_next; //BSP_MFSM_01
        end
    end
    
    always_ff @ (posedge i_can_clk)
    begin : CUR_TSTATE
        if (i_reset == 1'b1) begin
            int_tstate = IDLE;  
        end
        else begin
            int_tstate <= int_tstate_next; //BSP_TFSM_01
        end
    end
    
    always_ff @ (posedge i_can_clk)
    begin : CUR_RSTATE
        if (i_reset == 1'b1) begin
            int_rstate = IDLE; 
        end
        else begin
            int_rstate <= int_rstate_next; //BSP_RFSM_01
        end
    end
    
//--------------------------------Transmission Frame Assembly--------------------------------
    always @(posedge i_can_clk)
    begin: TX_COUNTER
        if (i_reset == 1'b1) begin
            int_txbit_counter = 0;
        end
        else begin
            //Counter advancement logic
            if(i_samp_tick == 1'b1) begin
                if (int_tstate == IFS) begin
                    int_txbit_counter = 0;  //BSP_TXASS_02
                end
                else begin
                    int_txbit_counter = int_txbit_counter + 1;  //BSP_TXASS_01
                end
            end
        end
    end
    
    always @(i_reset, int_tstate, i_samp_tick, i_send_data)
    begin: TX_ASSEMBLY
        if (i_reset == 1'b1) begin
            int_txframe_reg = 128'd0;
        end
        else begin
            //Frame assembly proper
            if(int_tstate == BUSY) begin
                int_txframe_reg[0:10] = i_send_data[96:106];        //BSP_TXASS_03
                int_txframe_reg[11] = i_send_data[107];             //BSP_TXASS_04
                int_txframe_reg[12] = i_send_data[108];             //BSP_TXASS_05
                if(i_send_data[108] == 1'b0) begin
                    //standard frame
                    int_txframe_reg[13] = 1'b0;                     //BSP_TXASS_06
                    int_txframe_reg[14:17] = i_send_data[64:67];    //BSP_TXASS_07
                    case(i_send_data[64:67])
                        4'd0 : begin
                            //Number of data bytes = 0+1 = 1
                            int_txframe_reg[18:(1)*4+17] = i_send_data_r[63:(16-1)*4];    //BSP_TXASS_08
                            int_txframe_reg[(1)*4+18:(1)*4+18+14] = int_crc_checksum;   //BSP_TXASS_09
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(1)*4+33:(1)*4+43] = 11'b10111111111;   //BSP_SOVR_03
                            end
                            else begin
                                int_txframe_reg[(1)*4+33:(1)*4+43] = 11'b11111111111;       //BSP_TXASS_10
                            end
                            int_tx_frame_end = (1)*4+33;                                //BSP_TXASS_17
                        end
                        4'd1 : begin
                            //Number of data bytes = 1+1 = 2
                            int_txframe_reg[18:(2)*4+17] = i_send_data_r[63:(16-2)*4];    //BSP_TXASS_08
                            int_txframe_reg[(2)*4+18:(2)*4+18+14] = int_crc_checksum;   //BSP_TXASS_09
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(2)*4+33:(2)*4+43] = 11'b10111111111;   //BSP_SOVR_03
                            end
                            else begin
                                int_txframe_reg[(2)*4+33:(2)*4+43] = 11'b11111111111;   //BSP_TXASS_10
                            end
                            int_tx_frame_end = (2)*4+33;                                //BSP_TXASS_17
                        end
                        4'd2 : begin
						    //Number of data bytes = 2+1 = 3
                            int_txframe_reg[18:(3)*4+17] = i_send_data_r[63:(16-3)*4];    //BSP_TXASS_08
                            int_txframe_reg[(3)*4+18:(3)*4+18+14] = int_crc_checksum;   //BSP_TXASS_09
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(3)*4+33:(3)*4+43] = 11'b10111111111;   //BSP_SOVR_03
                            end
                            else begin
                                int_txframe_reg[(3)*4+33:(3)*4+43] = 11'b11111111111;   //BSP_TXASS_10
                            end
                            int_tx_frame_end = (3)*4+33;                                //BSP_TXASS_17
                        end
                        4'd3 : begin
                            //Number of data bytes = 3+1 = 4
                            int_txframe_reg[18:(4)*4+17] = i_send_data_r[63:(16-4)*4];    //BSP_TXASS_08
                            int_txframe_reg[(4)*4+18:(4)*4+18+14] = int_crc_checksum;   //BSP_TXASS_09
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(4)*4+33:(4)*4+43] = 11'b10111111111;   //BSP_SOVR_03
                            end
                            else begin
                                int_txframe_reg[(4)*4+33:(4)*4+43] = 11'b11111111111;   //BSP_TXASS_10
                            end
                            int_tx_frame_end = (4)*4+33;                                //BSP_TXASS_17
                        end
                        4'd4 : begin
                            //Number of data bytes = 4+1 = 5
                            int_txframe_reg[18:(5)*4+17] = i_send_data_r[63:(16-5)*4];    //BSP_TXASS_08
                            int_txframe_reg[(5)*4+18:(5)*4+18+14] = int_crc_checksum;   //BSP_TXASS_09
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(5)*4+33:(5)*4+43] = 11'b10111111111;   //BSP_SOVR_03
                            end
                            else begin
                                int_txframe_reg[(5)*4+33:(5)*4+43] = 11'b11111111111;   //BSP_TXASS_10
                            end
                            int_tx_frame_end = (5)*4+33;                                //BSP_TXASS_17
                        end
                        4'd5 : begin
                            //Number of data bytes = 5+1 = 6
                            int_txframe_reg[18:(6)*4+17] = i_send_data_r[63:(16-6)*4];    //BSP_TXASS_08
                            int_txframe_reg[(6)*4+18:(6)*4+18+14] = int_crc_checksum;   //BSP_TXASS_09
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(6)*4+33:(6)*4+43] = 11'b10111111111;   //BSP_SOVR_03
                            end
                            else begin
                                int_txframe_reg[(6)*4+33:(6)*4+43] = 11'b11111111111;   //BSP_TXASS_10
                            end
                            int_tx_frame_end = (6)*4+33;                                //BSP_TXASS_17
                        end
                        4'd6 : begin
                            //Number of data bytes = 6+1 = 7
                            int_txframe_reg[18:(7)*4+17] = i_send_data_r[63:(16-7)*4];    //BSP_TXASS_08
                            int_txframe_reg[(7)*4+18:(7)*4+18+14] = int_crc_checksum;   //BSP_TXASS_09
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(7)*4+33:(7)*4+43] = 11'b10111111111;   //BSP_SOVR_03
                            end
                            else begin
                                int_txframe_reg[(7)*4+33:(7)*4+43] = 11'b11111111111;   //BSP_TXASS_10
                            end
                            int_tx_frame_end = (7)*4+33;                                //BSP_TXASS_17
                        end
                        4'd7 : begin
                            //Number of data bytes = 7+1 = 8
                            int_txframe_reg[18:(8)*4+17] = i_send_data_r[63:(16-8)*4];    //BSP_TXASS_08
                            int_txframe_reg[(8)*4+18:(8)*4+18+14] = int_crc_checksum;   //BSP_TXASS_09
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(8)*4+33:(8)*4+43] = 11'b10111111111;   //BSP_SOVR_03
                            end
                            else begin
                                int_txframe_reg[(8)*4+33:(8)*4+43] = 11'b11111111111;   //BSP_TXASS_10
                            end
                            int_tx_frame_end = (8)*4+33;                                //BSP_TXASS_17
                        end
                        4'd8 : begin
                            //Number of data bytes = 8+1 = 9
                            int_txframe_reg[18:(9)*4+17] = i_send_data_r[63:(16-9)*4];    //BSP_TXASS_08
                            int_txframe_reg[(9)*4+18:(9)*4+18+14] = int_crc_checksum;   //BSP_TXASS_09
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(9)*4+33:(9)*4+43] = 11'b10111111111;   //BSP_SOVR_03
                            end
                            else begin
                                int_txframe_reg[(9)*4+33:(9)*4+43] = 11'b11111111111;   //BSP_TXASS_10
                            end
                            int_tx_frame_end = (9)*4+33;                                //BSP_TXASS_17
                        end
                        4'd9 : begin
                            //Number of data bytes = 9+1 = 10
                            int_txframe_reg[18:(10)*4+17] = i_send_data_r[63:(16-10)*4];   //BSP_TXASS_08
                            int_txframe_reg[(10)*4+18:(10)*4+18+14] = int_crc_checksum;  //BSP_TXASS_09
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(10)*4+33:(10)*4+43] = 11'b10111111111;  //BSP_SOVR_03
                            end
                            else begin
                                int_txframe_reg[(10)*4+33:(10)*4+43] = 11'b11111111111;  //BSP_TXASS_10
                            end
                            int_tx_frame_end = (10)*4+33;                                //BSP_TXASS_17
                        end
                        4'd10 : begin
                            //Number of data bytes = 10+1 = 11
                            int_txframe_reg[18:(11)*4+17] = i_send_data_r[63:(16-11)*4];   //BSP_TXASS_08
                            int_txframe_reg[(11)*4+18:(11)*4+18+14] = int_crc_checksum;  //BSP_TXASS_09
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(11)*4+33:(11)*4+43] = 11'b10111111111;  //BSP_SOVR_03
                            end
                            else begin
                                int_txframe_reg[(11)*4+33:(11)*4+43] = 11'b11111111111;  //BSP_TXASS_10
                            end
                            int_tx_frame_end = (11)*4+33;                                //BSP_TXASS_17
                        end
                        4'd11 : begin
                            //Number of data bytes = 11+1 = 12
                            int_txframe_reg[18:(12)*4+17] = i_send_data_r[63:(16-12)*4];   //BSP_TXASS_08
                            int_txframe_reg[(12)*4+18:(12)*4+18+14] = int_crc_checksum;  //BSP_TXASS_09
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(12)*4+33:(12)*4+43] = 11'b10111111111;  //BSP_SOVR_03
                            end
                            else begin
                                int_txframe_reg[(12)*4+33:(12)*4+43] = 11'b11111111111;  //BSP_TXASS_10
                            end
                            int_tx_frame_end = (12)*4+33;                                //BSP_TXASS_17
                        end
                        4'd12 : begin
						    //Number of data bytes = 12+1 = 13
                            int_txframe_reg[18:(13)*4+17] = i_send_data_r[63:(16-13)*4];   //BSP_TXASS_08
                            int_txframe_reg[(13)*4+18:(13)*4+18+14] = int_crc_checksum;  //BSP_TXASS_09
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(13)*4+33:(13)*4+43] = 11'b10111111111;  //BSP_SOVR_03
                            end
                            else begin
                                int_txframe_reg[(13)*4+33:(13)*4+43] = 11'b11111111111;  //BSP_TXASS_10
                            end
                            int_tx_frame_end = (13)*4+33;                                //BSP_TXASS_17
                        end
                        4'd13 : begin
                            //Number of data bytes = 13+1 = 14
                            int_txframe_reg[18:(14)*4+17] = i_send_data_r[63:(16-14)*4];   //BSP_TXASS_08
                            int_txframe_reg[(14)*4+18:(14)*4+18+14] = int_crc_checksum;  //BSP_TXASS_09
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(14)*4+33:(14)*4+43] = 11'b10111111111;   //BSP_SOVR_03
                            end
                            else begin
                                int_txframe_reg[(14)*4+33:(14)*4+43] = 11'b11111111111;   //BSP_TXASS_10
                            end
                            int_tx_frame_end = (14)*4+33;                                //BSP_TXASS_17
                        end
                        4'd14 : begin
                            //Number of data bytes = 14+1 = 15
                            int_txframe_reg[18:(15)*4+17] = i_send_data_r[63:(16-15)*4];   //BSP_TXASS_08
                            int_txframe_reg[(15)*4+18:(15)*4+18+14] = int_crc_checksum;  //BSP_TXASS_09
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(15)*4+33:(15)*4+43] = 11'b10111111111;  //BSP_SOVR_03
                            end
                            else begin
                                int_txframe_reg[(15)*4+33:(15)*4+43] = 11'b11111111111;  //BSP_TXASS_10
                            end
                            int_tx_frame_end = (15)*4+33;                                //BSP_TXASS_17
                        end
                        4'd15 : begin
                            //Number of data bytes = 15+1 = 16
                            int_txframe_reg[18:(16)*4+17] = i_send_data_r[63:(16-16)*4];   //BSP_TXASS_08
                            int_txframe_reg[(16)*4+18:(16)*4+18+14] = int_crc_checksum;  //BSP_TXASS_09
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(16)*4+33:(16)*4+43] = 11'b10111111111;  //BSP_SOVR_03
                            end
                            else begin
                                int_txframe_reg[(16)*4+33:(16)*4+43] = 11'b11111111111;  //BSP_TXASS_10
                            end
                            int_tx_frame_end = (16)*4+33;                                //BSP_TXASS_17
                        end
                        default : begin
                            //Number of data bytes = 0+1 = 1
                            int_txframe_reg[18:(1)*4+17] = i_send_data_r[63:(16-1)*4];    //BSP_TXASS_08
                            int_txframe_reg[(1)*4+18:(1)*4+18+14] = int_crc_checksum;   //BSP_TXASS_09
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(1)*4+33:(1)*4+43] = 11'b10111111111;   //BSP_SOVR_03
                            end
                            else begin
                                int_txframe_reg[(1)*4+33:(1)*4+43] = 11'b11111111111;   //BSP_TXASS_10
                            end
                            int_tx_frame_end = (1)*4+33;                                //BSP_TXASS_17
                        end
                    endcase
                end
                else begin
                    //extended frame
                    int_txframe_reg[13:30] = i_send_data[109:126];  //BSP_TXASS_11
                    int_txframe_reg[31] = i_send_data[127];         //BSP_TXASS_12
                    int_txframe_reg[32:35] = i_send_data[64:67];    //BSP_TXASS_13
                    case(i_send_data[64:67])
                        4'd0 : begin
                            //Number of data bytes = 0+1 = 1
                            int_txframe_reg[36:(1)*4+35] = i_send_data_r[63:(16-1)*4];    //BSP_TXASS_14
                            int_txframe_reg[(1)*4+36:(1)*4+36+14] = int_crc_checksum;   //BSP_TXASS_15
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(1)*4+51:(1)*4+61] = 11'b10111111111;   //BSP_SOVR_04
                            end
                            else begin
                                int_txframe_reg[(1)*4+51:(1)*4+61] = 11'b11111111111;   //BSP_TXASS_16
                            end
                            int_tx_frame_end = (1)*4+51;                                //BSP_TXASS_18
                        end
                        4'd1 : begin
                            //Number of data bytes = 1+1 = 2
                            int_txframe_reg[36:(2)*4+35] = i_send_data_r[63:(16-2)*4];    //BSP_TXASS_14
                            int_txframe_reg[(2)*4+36:(2)*4+36+14] = int_crc_checksum;   //BSP_TXASS_15
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(2)*4+51:(2)*4+61] = 11'b10111111111;   //BSP_SOVR_04
                            end
                            else begin
                                int_txframe_reg[(2)*4+51:(2)*4+61] = 11'b11111111111;   //BSP_TXASS_16
                            end
                            int_tx_frame_end = (2)*4+51;                                //BSP_TXASS_18
                        end
                        4'd2 : begin
						    //Number of data bytes = 2+1 = 3
                            int_txframe_reg[36:(3)*4+35] = i_send_data_r[63:(16-3)*4];    //BSP_TXASS_14
                            int_txframe_reg[(3)*4+36:(3)*4+36+14] = int_crc_checksum;   //BSP_TXASS_15
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(3)*4+51:(3)*4+61] = 11'b10111111111;   //BSP_SOVR_04
                            end
                            else begin
                                int_txframe_reg[(3)*4+51:(3)*4+61] = 11'b11111111111;   //BSP_TXASS_16
                            end
                            int_tx_frame_end = (3)*4+51;                                //BSP_TXASS_18
                        end
                        4'd3 : begin
                            //Number of data bytes = 3+1 = 4
                            int_txframe_reg[36:(4)*4+35] = i_send_data_r[63:(16-4)*4];    //BSP_TXASS_14
                            int_txframe_reg[(4)*4+36:(4)*4+36+14] = int_crc_checksum;   //BSP_TXASS_15
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(4)*4+51:(4)*4+61] = 11'b10111111111;   //BSP_SOVR_04
                            end
                            else begin
                                int_txframe_reg[(4)*4+51:(4)*4+61] = 11'b11111111111;   //BSP_TXASS_16
                            end
                            int_tx_frame_end = (4)*4+51;                                //BSP_TXASS_18
                        end
                        4'd4 : begin
                            //Number of data bytes = 4+1 = 5
                            int_txframe_reg[36:(5)*4+35] = i_send_data_r[63:(16-5)*4];    //BSP_TXASS_14
                            int_txframe_reg[(5)*4+36:(5)*4+36+14] = int_crc_checksum;   //BSP_TXASS_15
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(5)*4+51:(5)*4+61] = 11'b10111111111;   //BSP_SOVR_04
                            end
                            else begin
                                int_txframe_reg[(5)*4+51:(5)*4+61] = 11'b11111111111;   //BSP_TXASS_16
                            end
                            int_tx_frame_end = (5)*4+51;                                //BSP_TXASS_18
                        end
                        4'd5 : begin
                            //Number of data bytes = 5+1 = 6
                            int_txframe_reg[36:(6)*4+35] = i_send_data_r[63:(16-6)*4];    //BSP_TXASS_14
                            int_txframe_reg[(6)*4+36:(6)*4+36+14] = int_crc_checksum;   //BSP_TXASS_15
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(6)*4+51:(6)*4+61] = 11'b10111111111;   //BSP_SOVR_04
                            end
                            else begin
                                int_txframe_reg[(6)*4+51:(6)*4+61] = 11'b11111111111;   //BSP_TXASS_16
                            end
                            int_tx_frame_end = (6)*4+51;                                //BSP_TXASS_18
                        end
                        4'd6 : begin
                            //Number of data bytes = 6+1 = 7
                            int_txframe_reg[36:(7)*4+35] = i_send_data_r[63:(16-7)*4];    //BSP_TXASS_14
                            int_txframe_reg[(7)*4+36:(7)*4+36+14] = int_crc_checksum;   //BSP_TXASS_15
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(7)*4+51:(7)*4+61] = 11'b10111111111;   //BSP_SOVR_04
                            end
                            else begin
                                int_txframe_reg[(7)*4+51:(7)*4+61] = 11'b11111111111;   //BSP_TXASS_16
                            end
                            int_tx_frame_end = (7)*4+51;                                //BSP_TXASS_18
                        end
                        4'd7 : begin
                            //Number of data bytes = 7+1 = 8
                            int_txframe_reg[36:(8)*4+35] = i_send_data_r[63:(16-8)*4];    //BSP_TXASS_14
                            int_txframe_reg[(8)*4+36:(8)*4+36+14] = int_crc_checksum;   //BSP_TXASS_15
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(8)*4+51:(8)*4+61] = 11'b10111111111;   //BSP_SOVR_04
                            end
                            else begin
                                int_txframe_reg[(8)*4+51:(8)*4+61] = 11'b11111111111;   //BSP_TXASS_16
                            end
                            int_tx_frame_end = (8)*4+51;                                //BSP_TXASS_18
                        end
                        4'd8 : begin
                            //Number of data bytes = 8+1 = 9
                            int_txframe_reg[36:(9)*4+35] = i_send_data_r[63:(16-9)*4];    //BSP_TXASS_14
                            int_txframe_reg[(9)*4+36:(9)*4+36+14] = int_crc_checksum;   //BSP_TXASS_15
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(9)*4+51:(9)*4+61] = 11'b10111111111;   //BSP_SOVR_04
                            end
                            else begin
                                int_txframe_reg[(9)*4+51:(9)*4+61] = 11'b11111111111;   //BSP_TXASS_16
                            end
                            int_tx_frame_end = (9)*4+51;                                //BSP_TXASS_18
                        end
                        4'd9 : begin
                            //Number of data bytes = 9+1 = 10
                            int_txframe_reg[36:(10)*4+35] = i_send_data_r[63:(16-10)*4];  //BSP_TXASS_14
                            int_txframe_reg[(10)*4+36:(10)*4+36+14] = int_crc_checksum; //BSP_TXASS_15
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(10)*4+51:(10)*4+61] = 11'b10111111111; //BSP_SOVR_04
                            end
                            else begin
                                int_txframe_reg[(10)*4+51:(10)*4+61] = 11'b11111111111; //BSP_TXASS_16
                            end
                            int_tx_frame_end = (10)*4+51;                               //BSP_TXASS_18
                        end
                        4'd10 : begin
                            //Number of data bytes = 10+1 = 11
                            int_txframe_reg[36:(11)*4+35] = i_send_data_r[63:(16-11)*4];  //BSP_TXASS_14
                            int_txframe_reg[(11)*4+36:(11)*4+36+14] = int_crc_checksum; //BSP_TXASS_15
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(11)*4+51:(11)*4+61] = 11'b10111111111; //BSP_SOVR_04
                            end
                            else begin
                                int_txframe_reg[(11)*4+51:(11)*4+61] = 11'b11111111111; //BSP_TXASS_16
                            end
                            int_tx_frame_end = (11)*4+51;                               //BSP_TXASS_18
                        end
                        4'd11 : begin
                            //Number of data bytes = 11+1 = 12
                            int_txframe_reg[36:(12)*4+35] = i_send_data_r[63:(16-12)*4];  //BSP_TXASS_14
                            int_txframe_reg[(12)*4+36:(12)*4+36+14] = int_crc_checksum; //BSP_TXASS_15
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(12)*4+51:(12)*4+61] = 11'b10111111111; //BSP_SOVR_04
                            end
                            else begin
                                int_txframe_reg[(12)*4+51:(12)*4+61] = 11'b11111111111; //BSP_TXASS_16
                            end
                            int_tx_frame_end = (12)*4+51;                               //BSP_TXASS_18
                        end
                        4'd12 : begin
						    //Number of data bytes = 12+1 = 13
                            int_txframe_reg[36:(13)*4+35] = i_send_data_r[63:(16-13)*4];  //BSP_TXASS_14
                            int_txframe_reg[(13)*4+36:(13)*4+36+14] = int_crc_checksum; //BSP_TXASS_15
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(13)*4+51:(13)*4+61] = 11'b10111111111; //BSP_SOVR_04
                            end
                            else begin
                                int_txframe_reg[(13)*4+51:(13)*4+61] = 11'b11111111111; //BSP_TXASS_16
                            end
                            int_tx_frame_end = (13)*4+51;                               //BSP_TXASS_18
                        end
                        4'd13 : begin
                            //Number of data bytes = 13+1 = 14
                            int_txframe_reg[36:(14)*4+35] = i_send_data_r[63:(16-14)*4];  //BSP_TXASS_14
                            int_txframe_reg[(14)*4+36:(14)*4+36+14] = int_crc_checksum; //BSP_TXASS_15
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(14)*4+51:(14)*4+61] = 11'b10111111111; //BSP_SOVR_04
                            end
                            else begin
                                int_txframe_reg[(14)*4+51:(14)*4+61] = 11'b11111111111; //BSP_TXASS_16
                            end
                            int_tx_frame_end = (14)*4+51;                               //BSP_TXASS_18
                        end
                        4'd14 : begin
                            //Number of data bytes = 14+1 = 15
                            int_txframe_reg[36:(15)*4+35] = i_send_data_r[63:(16-15)*4];  //BSP_TXASS_14
                            int_txframe_reg[(15)*4+36:(15)*4+36+14] = int_crc_checksum; //BSP_TXASS_15
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(15)*4+51:(15)*4+61] = 11'b10111111111; //BSP_SOVR_04
                            end
                            else begin
                                int_txframe_reg[(15)*4+51:(15)*4+61] = 11'b11111111111; //BSP_TXASS_16
                            end
                            int_tx_frame_end = (15)*4+51;                               //BSP_TXASS_18
                        end
                        4'd15 : begin
                            //Number of data bytes = 15+1 = 16
                            int_txframe_reg[36:(16)*4+35] = i_send_data_r[63:(16-16)*4];  //BSP_TXASS_14
                            int_txframe_reg[(16)*4+36:(16)*4+36+14] = int_crc_checksum; //BSP_TXASS_15
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(16)*4+51:(16)*4+61] = 11'b10111111111; //BSP_SOVR_04
                            end
                            else begin
                                int_txframe_reg[(16)*4+51:(16)*4+61] = 11'b11111111111; //BSP_TXASS_16
                            end
                            int_tx_frame_end = (16)*4+51;                               //BSP_TXASS_18
                        end
                        default : begin
                            //Number of data bytes = 0+1 = 1
                            int_txframe_reg[36:(1)*4+35] = i_send_data_r[63:(16-1)*4];    //BSP_TXASS_14
                            int_txframe_reg[(1)*4+36:(1)*4+36+14] = int_crc_checksum;   //BSP_TXASS_15
                            if(int_mstate == MLOOPBACK) begin
                                int_txframe_reg[(1)*4+51:(1)*4+61] = 11'b10111111111;   //BSP_SOVR_04
                            end
                            else begin
                                int_txframe_reg[(1)*4+51:(1)*4+61] = 11'b11111111111;   //BSP_TXASS_16
                            end
                            int_tx_frame_end = (1)*4+51;                                //BSP_TXASS_18
                        end
                    endcase
                end
            end
        end     
    end
   
//--------------------------------Transmission Frame Assembly--------------------------------
    always_ff @ (posedge i_can_clk)
    begin : TX_SEND
        if (i_reset == 1'b1) begin
            int_tx_send_bit = 1'b1;
            o_tx_bit = 1'b1;        //BSP_RST_02
        end
        else begin
            if(i_samp_tick == 1'b1) begin
                if(int_tstate == BUSY) begin
                    if(int_txbit_counter < int_tx_frame_end) begin
                        if(int_txbit_history[5:0] == 6'b111111) begin
                            int_tx_send_bit = 1'b0; //BSP_FRTX_02
                            o_tx_bit = 1'b0;        //BSP_FRTX_06
                        end
                        else if(int_txbit_history[5:0] == 6'b000000) begin
                            int_tx_send_bit = 1'b1; //BSP_FRTX_03
                            o_tx_bit = 1'b1;        //BSP_FRTX_07
                        end
                        else begin 
                            int_tx_send_bit = int_txframe_reg[int_txbit_counter]; //BSP_FRTX_04
                            o_tx_bit = int_txframe_reg[int_txbit_counter];        //BSP_FRTX_08
                        end
                    end
                    else begin
                        int_tx_send_bit = int_txframe_reg[int_txbit_counter]; //BSP_FRTX_05
                        o_tx_bit = int_txframe_reg[int_txbit_counter];        //BSP_FRTX_09
                    end
                end
                else begin
                    //int_tstate is either IDLE or IFS
                    int_tx_send_bit = 1'b1; //BSP_SOVR_05
                    o_tx_bit = 1'b1;        //BSP_SOVR_06
                end
            end
        end
    end
//--------------------------------Receiver Frame Assembly--------------------------------
    always @(posedge i_can_clk)
    begin: RX_COUNTER
        if (i_reset == 1'b1) begin
            int_rxbit_counter = 0;
        end
        else begin
            //Counter advancement logic
            if(i_samp_tick == 1'b1) begin
                if (int_rstate == IFS) begin
                    int_rxbit_counter = 0;  //BSP_RXASS_02
                end
                else begin
                    int_rxbit_counter = int_rxbit_counter + 1;  //BSP_RXASS_01
                end
            end
        end
    end
    
    always @(i_reset, int_rstate, i_samp_tick, i_rx_bit)
    begin: RX_ASSEMBLY
        if (i_reset == 1'b1) begin
            int_rxframe_reg = 128'd0;
        end
        else begin
            //Frame assembly proper
            if(int_tstate == BUSY) begin
                o_rx_message = 128'd0;                              //Redundant, just cleaning the register
                o_rx_message[96:106] = int_rxframe_reg[0:10];       //BSP_RXASS_03
                o_rx_message[107] = int_txframe_reg[11];            //BSP_RXASS_04
                o_rx_message[108] = int_txframe_reg[12];            //BSP_RXASS_05
                if(int_rxframe_reg[12] == 1'b0) begin
                    //standard frame
                    o_rx_message[64:67] = int_rxframe_reg[14:17];    //BSP_RXASS_06
                    case(int_rxframe_reg[14:17])
                        4'd0 : begin
                            o_rx_message[((16 - (1))*4):63] = int_rxframe_reg_r[((1)*4 + 17):18];    //BSP_RXASS_07
                        end
                        4'd1 : begin
                            o_rx_message[((16 - (2))*4):63] = int_rxframe_reg_r[((2)*4 + 17):18];    //BSP_RXASS_07
                        end
                        4'd2 : begin
                            o_rx_message[((16 - (3))*4):63] = int_rxframe_reg_r[((3)*4 + 17):18];    //BSP_RXASS_07
                        end
                        4'd3 : begin
                            o_rx_message[((16 - (4))*4):63] = int_rxframe_reg_r[((4)*4 + 17):18];    //BSP_RXASS_07
                        end
                        4'd4 : begin
                            o_rx_message[((16 - (5))*4):63] = int_rxframe_reg_r[((5)*4 + 17):18];    //BSP_RXASS_07
                        end
                        4'd5 : begin
                            o_rx_message[((16 - (6))*4):63] = int_rxframe_reg_r[((6)*4 + 17):18];    //BSP_RXASS_07
                        end
                        4'd6 : begin
                            o_rx_message[((16 - (7))*4):63] = int_rxframe_reg_r[((7)*4 + 17):18];    //BSP_RXASS_07
                        end
                        4'd7 : begin
                            o_rx_message[((16 - (8))*4):63] = int_rxframe_reg_r[((8)*4 + 17):18];    //BSP_RXASS_07
                        end
                        4'd8 : begin
                            o_rx_message[((16 - (9))*4):63] = int_rxframe_reg_r[((9)*4 + 17):18];    //BSP_RXASS_07
                        end
                        4'd9 : begin
                            o_rx_message[((16 - (10))*4):63] = int_rxframe_reg_r[((10)*4 + 17):18];  //BSP_RXASS_07
                        end
                        4'd10 : begin
                            o_rx_message[((16 - (11))*4):63] = int_rxframe_reg_r[((11)*4 + 17):18];  //BSP_RXASS_07
                        end
                        4'd11 : begin
                            o_rx_message[((16 - (12))*4):63] = int_rxframe_reg_r[((12)*4 + 17):18];  //BSP_RXASS_07
                        end
                        4'd12 : begin
                            o_rx_message[((16 - (13))*4):63] = int_rxframe_reg_r[((13)*4 + 17):18];  //BSP_RXASS_07
                        end
                        4'd13 : begin
                            o_rx_message[((16 - (14))*4):63] = int_rxframe_reg_r[((14)*4 + 17):18];  //BSP_RXASS_07
                        end
                        4'd14 : begin
                            o_rx_message[((16 - (15))*4):63] = int_rxframe_reg_r[((15)*4 + 17):18];  //BSP_RXASS_07
                        end
                        4'd15 : begin
                            o_rx_message[((16 - (16))*4):63] = int_rxframe_reg_r[((16)*4 + 17):18];  //BSP_RXASS_07
                        end
                        default : begin
                            o_rx_message[((16 - (1))*4):63] = int_rxframe_reg_r[((1)*4 + 17):18];    //BSP_RXASS_07
                        end
                    endcase
                end
                else begin
                    //extended frame
                    o_rx_message[109:126] = int_rxframe_reg[13:30];         //BSP_RXASS_08
                    o_rx_message[127] = int_rxframe_reg[31];                //BSP_RXASS_09
                    o_rx_message[64:67] = int_rxframe_reg[32:35];           //BSP_RXASS_10
                    case(int_rxframe_reg[32:35])
                        4'd0 : begin
                            o_rx_message[((16 - (1))*4):63] = int_rxframe_reg_r[((1)*4 + 35):36];    //BSP_RXASS_11
                        end
                        4'd1 : begin
                            o_rx_message[((16 - (2))*4):63] = int_rxframe_reg_r[((2)*4 + 35):36];    //BSP_RXASS_11
                        end
                        4'd2 : begin
                            o_rx_message[((16 - (3))*4):63] = int_rxframe_reg_r[((3)*4 + 35):36];    //BSP_RXASS_11
                        end
                        4'd3 : begin
                            o_rx_message[((16 - (4))*4):63] = int_rxframe_reg_r[((4)*4 + 35):36];    //BSP_RXASS_11
                        end
                        4'd4 : begin
                            o_rx_message[((16 - (5))*4):63] = int_rxframe_reg_r[((5)*4 + 35):36];    //BSP_RXASS_11
                        end
                        4'd5 : begin
                            o_rx_message[((16 - (6))*4):63] = int_rxframe_reg_r[((6)*4 + 35):36];    //BSP_RXASS_11
                        end
                        4'd6 : begin
                            o_rx_message[((16 - (7))*4):63] = int_rxframe_reg_r[((7)*4 + 35):36];    //BSP_RXASS_11
                        end
                        4'd7 : begin
                            o_rx_message[((16 - (8))*4):63] = int_rxframe_reg_r[((8)*4 + 35):36];    //BSP_RXASS_11
                        end
                        4'd8 : begin
                            o_rx_message[((16 - (9))*4):63] = int_rxframe_reg_r[((9)*4 + 35):36];    //BSP_RXASS_11
                        end
                        4'd9 : begin
                            o_rx_message[((16 - (10))*4):63] = int_rxframe_reg_r[((10)*4 + 35):36];  //BSP_RXASS_11
                        end
                        4'd10 : begin
                            o_rx_message[((16 - (11))*4):63] = int_rxframe_reg_r[((11)*4 + 35):36];  //BSP_RXASS_11
                        end
                        4'd11 : begin
                            o_rx_message[((16 - (12))*4):63] = int_rxframe_reg_r[((12)*4 + 35):36];  //BSP_RXASS_11
                        end
                        4'd12 : begin
                            o_rx_message[((16 - (13))*4):63] = int_rxframe_reg_r[((13)*4 + 35):36];  //BSP_RXASS_11
                        end
                        4'd13 : begin
                            o_rx_message[((16 - (14))*4):63] = int_rxframe_reg_r[((14)*4 + 35):36];  //BSP_RXASS_11
                        end
                        4'd14 : begin
                            o_rx_message[((16 - (15))*4):63] = int_rxframe_reg_r[((15)*4 + 35):36];  //BSP_RXASS_11
                        end
                        4'd15 : begin
                            o_rx_message[((16 - (16))*4):63] = int_rxframe_reg_r[((16)*4 + 35):36];  //BSP_RXASS_11
                        end
                        default : begin
                            o_rx_message[((16 - (1))*4):63] = int_rxframe_reg_r[((1)*4 + 35):36];    //BSP_RXASS_11
                        end
                    endcase
                end
            end
        end
    end
    
//--------------------------------Receiver Frame Assembly--------------------------------
    always_ff @ (posedge i_can_clk)
    begin : RX_SEND
        if (i_reset == 1'b1) begin
            int_rxframe_reg = 128'd0;
        end
        else begin
            if(i_samp_tick == 1'b1) begin
                if(int_rstate == BUSY) begin
                    if(int_rxbit_counter < int_rx_frame_end) begin
                        if(int_rxbit_history[5:0] != 6'b111111 && int_rxbit_history[5:0] != 6'b000000) begin 
                            int_rxframe_reg[int_rxbit_counter] = i_rx_bit;  //BSP_FRRX_02
                        end
                    end
                end
            end
        end
    end
//--------------------------------Receiver Frame Signaling--------------------------------
    always_ff @ (posedge i_can_clk)
    begin : RX_SIGNAL
        if (i_reset == 1'b1) begin
            o_can_ready = 1'b0;         //BSP_RST_22
            int_can_ready = 1'b0;
        end
        else begin
            o_can_ready = int_can_ready;    //BSP_RXSIG_01 + BSP_RXSIG_02
            if(int_rstate == IFS) begin
                int_can_ready = 1'b1;       //BSP_RXSIG_01
            end
            else begin
                int_can_ready = 1'b1;       //BSP_RXSIG_02
            end
        end
    end
    
//--------------------------------Error generation and signaling--------------------------------
    assign o_error = int_error;     //BSP_ERROR_15
    assign o_arblst = int_arblst;   //BSP_ERROR_17
    always @(i_reset, int_mstate, int_tstate, int_rstate, i_samp_tick, i_rx_bit, int_rxbit_counter, int_txbit_counter)
    begin: ERROR_GEN
        if (i_reset == 1'b1) begin
            o_busy_can = 1'b0;       //BSP_RST_01
            o_rec = 8'h00;           //BSP_RST_03
            o_tec = 8'h00;           //BSP_RST_04
            o_acker = 1'b0;          //BSP_RST_05
            o_berr = 1'b0;           //BSP_RST_06
            o_ster = 1'b0;           //BSP_RST_07
            o_fmer = 1'b0;           //BSP_RST_08
            o_crcer = 1'b0;          //BSP_RST_09
            o_estat = 2'b10;         //BSP_RST_10
            o_bbsy = 1'b0;           //BSP_RST_11
            o_bidle = 1'b0;          //BSP_RST_12
            o_normal = 1'b0;         //BSP_RST_13
            o_config = 1'b0;         //BSP_RST_14
            o_txok = 1'b0;           //BSP_RST_15
            int_arblst = 1'b0;       //BSP_RST_16 through assign clause int BSP_ERROR_17
            o_bsoff = 1'b0;          //BSP_RST_18
            o_sleep = 1'b0;          //BSP_RST_19
            o_lback = 1'b0;          //BSP_RST_20
            o_wakeup = 1'b0;         //BSP_RST_21
            int_error = 1'b0;        //BSP_RST_17 through assign clause int BSP_ERROR_15
        end
        else begin
            o_rec = int_rxbit_counter;              //BSP_ERROR_01
            o_tec = int_txbit_counter;              //BSP_ERROR_02
            //Busy and idle signals generation
            o_busy_can = 1'b0;
            o_txok = 1'b0;
            o_berr = 1'b0;
            o_ster = 1'b0; 
            o_bbsy = 1'b0; 
            o_bidle = 1'b0; 
            int_error = 1'b0;
            if(int_tstate == BUSY) begin
                if(int_mstate != MCONFIG) begin
                    if(int_mstate != MSLEEP) begin
                        o_busy_can = 1'b1;          //BSP_ERROR_03
                    end
                    o_bbsy = 1'b1;                  //BSP_ERROR_06
                end
                if(int_tstate_next == IFS) begin
                    //end of transmission here
                    if(int_error == 1'b0) begin
                        //report txok
                        o_txok = 1'b1;              //BSP_ERROR_16
                    end
                end
                if(int_rstate == BUSY) begin
                    if(int_rxframe_reg[int_rxbit_counter] != int_txframe_reg[int_rxbit_counter]) begin
                        o_berr = 1'b1;              //BSP_ERROR_20
                        int_error = 1'b1;           //BSP_ERROR_30
                    end
                    if(int_rxbit_counter < int_rx_frame_end) begin
                        if(int_rxbit_history[5:0] == 6'b000000 || int_rxbit_history[5:0] == 6'b111111) begin
                            o_ster = 1'b1;          //BSP_ERROR_21
                            int_error = 1'b1;       //BSP_ERROR_31
                        end
                    end
                end
            end
            else if(int_tstate == IFS) begin
                //placeholder for now
            end
            else begin
                //int_tstate is IDLE
                if(int_rstate == IDLE) begin
                    if(int_mstate != MCONFIG) begin
                        o_bidle = 1'b1;             //BSP_ERROR_08
                    end
                end
            end
            
            //State signaling generation
            if(int_mstate == MNORMAL) begin
                o_normal = 1'b1;                    //BSP_ERROR_09
                o_sleep  = 1'b0;
                o_lback  = 1'b0;
                o_config = 1'b0;
                o_wakeup = 1'b0;
                o_bsoff  = 1'b0;
            end
            else if(int_mstate == MSLEEP) begin
                o_normal = 1'b0;
                o_sleep  = 1'b1;                    //BSP_ERROR_10
                o_lback  = 1'b0;
                o_config = 1'b0;
                if(int_mstate_next == MNORMAL) begin
                    o_wakeup = 1'b1;                //BSP_ERROR_13
                end
                else begin 
                    o_wakeup = 1'b0;
                end
                o_bsoff  = 1'b1;                    //BSP_ERROR_14
            end
            else if(int_mstate == MLOOPBACK) begin
                o_normal = 1'b0;
                o_sleep  = 1'b0;
                o_lback  = 1'b1;                    //BSP_ERROR_11
                o_config = 1'b0;
                o_wakeup = 1'b0;
                o_bsoff  = 1'b0;                    
            end
            else if(int_mstate == MCONFIG) begin
                o_normal = 1'b0;
                o_sleep  = 1'b0;
                o_lback  = 1'b0;
                o_config = 1'b1;                    //BSP_ERROR_12
                o_wakeup = 1'b0;
                o_bsoff  = 1'b1;                    //BSP_ERROR_14
            end
            
            //Errwrn generation
            if(int_rxbit_counter >= 8'd96) begin
                o_errwrn = 1'b1;                    //BSP_ERROR_04
            end
            else if(int_txbit_counter >= 8'd96) begin
                o_errwrn = 1'b1;                    //BSP_ERROR_05
            end
            else begin
                o_errwrn = 1'b0;                    //contingency to reset the variable
            end
            o_acker = 1'b0;
            o_fmer = 1'b0;
            o_crcer = 1'b0;
            if(int_rstate == IFS) begin
                if(int_rxframe_reg[12] == 1'b0) begin
                    if(int_rxframe_reg[13] == 1'b0) begin
                        o_fmer = 1'b1;              //BSP_ERROR_23
                        int_error = 1'b1;           //BSP_ERROR_33
                    end
                    //standard frame
                    case(int_rxframe_reg[14:17])
                        4'd0 : begin
                            o_acker = int_rxframe_reg[((1)*4 + 35)];    //BSP_ERROR_18
                            int_error = int_rxframe_reg[((1)*4 + 35)] || int_error;  //BSP_ERROR_28
                            if(int_rxframe_reg[((1)*4 + 18):((1)*4 + 18 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_26
                                int_error = 1'b1;                       //BSP_ERROR_36
                            end
                        end
                        4'd1 : begin
                            o_acker = int_rxframe_reg[((2)*4 + 35)];    //BSP_ERROR_18
                            int_error = int_rxframe_reg[((2)*4 + 35)] || int_error;  //BSP_ERROR_28
                            if(int_rxframe_reg[((2)*4 + 18):((2)*4 + 18 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_26
                                int_error = 1'b1;                       //BSP_ERROR_36
                            end
                        end
                        4'd2 : begin
                            o_acker = int_rxframe_reg[((3)*4 + 35)];    //BSP_ERROR_18
                            int_error = int_rxframe_reg[((3)*4 + 35)] || int_error;  //BSP_ERROR_28
                            if(int_rxframe_reg[((3)*4 + 18):((3)*4 + 18 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_26
                                int_error = 1'b1;                       //BSP_ERROR_36
                            end
                        end
                        4'd3 : begin
                            o_acker = int_rxframe_reg[((4)*4 + 35)];    //BSP_ERROR_18
                            int_error = int_rxframe_reg[((4)*4 + 35)] || int_error;  //BSP_ERROR_28
                            if(int_rxframe_reg[((4)*4 + 18):((4)*4 + 18 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_26
                                int_error = 1'b1;                       //BSP_ERROR_36
                            end
                        end
                        4'd4 : begin
                            o_acker = int_rxframe_reg[((5)*4 + 35)];    //BSP_ERROR_18
                            int_error = int_rxframe_reg[((5)*4 + 35)] || int_error;  //BSP_ERROR_28
                            if(int_rxframe_reg[((5)*4 + 18):((5)*4 + 18 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_26
                                int_error = 1'b1;                       //BSP_ERROR_36
                            end
                        end
                        4'd5 : begin
                            o_acker = int_rxframe_reg[((6)*4 + 35)];    //BSP_ERROR_18
                            int_error = int_rxframe_reg[((6)*4 + 35)] || int_error;  //BSP_ERROR_28
                            if(int_rxframe_reg[((6)*4 + 18):((6)*4 + 18 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_26
                                int_error = 1'b1;                       //BSP_ERROR_36
                            end
                        end
                        4'd6 : begin
                            o_acker = int_rxframe_reg[((7)*4 + 35)];    //BSP_ERROR_18
                            int_error = int_rxframe_reg[((7)*4 + 35)] || int_error;  //BSP_ERROR_28
                            if(int_rxframe_reg[((7)*4 + 18):((7)*4 + 18 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_26
                                int_error = 1'b1;                       //BSP_ERROR_36
                            end
                        end
                        4'd7 : begin
                            o_acker = int_rxframe_reg[((8)*4 + 35)];    //BSP_ERROR_18
                            int_error = int_rxframe_reg[((8)*4 + 35)] || int_error;  //BSP_ERROR_28
                            if(int_rxframe_reg[((8)*4 + 18):((8)*4 + 18 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_26
                                int_error = 1'b1;                       //BSP_ERROR_36
                            end
                        end
                        4'd8 : begin
                            o_acker = int_rxframe_reg[((9)*4 + 35)];    //BSP_ERROR_18
                            int_error = int_rxframe_reg[((9)*4 + 35)] || int_error;  //BSP_ERROR_28
                            if(int_rxframe_reg[((9)*4 + 18):((9)*4 + 18 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_26
                                int_error = 1'b1;                       //BSP_ERROR_36
                            end
                        end
                        4'd9 : begin
                            o_acker = int_rxframe_reg[((10)*4 + 35)];   //BSP_ERROR_18
                            int_error = int_rxframe_reg[((10)*4 + 35)] || int_error;  //BSP_ERROR_28
                            if(int_rxframe_reg[((10)*4 + 18):((10)*4 + 18 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_26
                                int_error = 1'b1;                       //BSP_ERROR_36
                            end
                        end
                        4'd10 : begin
                            o_acker = int_rxframe_reg[((11)*4 + 35)];   //BSP_ERROR_18
                            int_error = int_rxframe_reg[((11)*4 + 35)] || int_error;  //BSP_ERROR_28
                            if(int_rxframe_reg[((11)*4 + 18):((11)*4 + 18 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_26
                                int_error = 1'b1;                       //BSP_ERROR_36
                            end
                        end
                        4'd11 : begin
                            o_acker = int_rxframe_reg[((12)*4 + 35)];   //BSP_ERROR_18
                            int_error = int_rxframe_reg[((12)*4 + 35)] || int_error;  //BSP_ERROR_28
                            if(int_rxframe_reg[((12)*4 + 18):((12)*4 + 18 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_26
                                int_error = 1'b1;                       //BSP_ERROR_36
                            end
                        end
                        4'd12 : begin
                            o_acker = int_rxframe_reg[((13)*4 + 35)];   //BSP_ERROR_18
                            int_error = int_rxframe_reg[((13)*4 + 35)] || int_error;  //BSP_ERROR_28
                            if(int_rxframe_reg[((13)*4 + 18):((13)*4 + 18 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_26
                                int_error = 1'b1;                       //BSP_ERROR_36
                            end
                        end
                        4'd13 : begin
                            o_acker = int_rxframe_reg[((14)*4 + 35)];   //BSP_ERROR_18
                            int_error = int_rxframe_reg[((14)*4 + 35)] || int_error;  //BSP_ERROR_28
                            if(int_rxframe_reg[((14)*4 + 18):((14)*4 + 18 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_26
                                int_error = 1'b1;                       //BSP_ERROR_36
                            end
                        end
                        4'd14 : begin
                            o_acker = int_rxframe_reg[((15)*4 + 35)];   //BSP_ERROR_18
                            int_error = int_rxframe_reg[((15)*4 + 35)] || int_error;  //BSP_ERROR_28
                            if(int_rxframe_reg[((15)*4 + 18):((15)*4 + 18 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_26
                                int_error = 1'b1;                       //BSP_ERROR_36
                            end
                        end
                        4'd15 : begin
                            o_acker = int_rxframe_reg[((16)*4 + 35)];   //BSP_ERROR_18
                            int_error = int_rxframe_reg[((16)*4 + 35)] || int_error;  //BSP_ERROR_28
                            if(int_rxframe_reg[((16)*4 + 18):((16)*4 + 18 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_26
                                int_error = 1'b1;                       //BSP_ERROR_36
                            end
                        end
                        default : begin
                            o_acker = int_rxframe_reg[((1)*4 + 35)];    //BSP_ERROR_18
                            int_error = int_rxframe_reg[((1)*4 + 35)] || int_error;  //BSP_ERROR_28
                            if(int_rxframe_reg[((1)*4 + 18):((1)*4 + 18 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_26
                                int_error = 1'b1;                       //BSP_ERROR_36
                            end
                        end
                    endcase
                end
                else begin
                    //extended frame
                    case(int_rxframe_reg[32:35])
                        4'd0 : begin
                            o_acker = int_rxframe_reg[((1)*4 + 53)];    //BSP_ERROR_19
                            int_error = int_rxframe_reg[((1)*4 + 53)] || int_error;  //BSP_ERROR_29
                            if(int_rxframe_reg[((1)*4 + 36):((1)*4 + 36 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_27
                                int_error = 1'b1;                       //BSP_ERROR_37
                            end
                        end
                        4'd1 : begin
                            o_acker = int_rxframe_reg[((2)*4 + 53)];    //BSP_ERROR_19
                            int_error = int_rxframe_reg[((2)*4 + 53)] || int_error;  //BSP_ERROR_29
                            if(int_rxframe_reg[((2)*4 + 36):((2)*4 + 36 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_27
                                int_error = 1'b1;                       //BSP_ERROR_37
                            end
                        end
                        4'd2 : begin
                            o_acker = int_rxframe_reg[((3)*4 + 53)];    //BSP_ERROR_19
                            int_error = int_rxframe_reg[((3)*4 + 53)] || int_error;  //BSP_ERROR_29
                            if(int_rxframe_reg[((3)*4 + 36):((3)*4 + 36 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_27
                                int_error = 1'b1;                       //BSP_ERROR_37
                            end
                        end
                        4'd3 : begin
                            o_acker = int_rxframe_reg[((4)*4 + 53)];    //BSP_ERROR_19
                            int_error = int_rxframe_reg[((4)*4 + 53)] || int_error;  //BSP_ERROR_29
                            if(int_rxframe_reg[((4)*4 + 36):((4)*4 + 36 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_27
                                int_error = 1'b1;                       //BSP_ERROR_37
                            end
                        end
                        4'd4 : begin
                            o_acker = int_rxframe_reg[((5)*4 + 53)];    //BSP_ERROR_19
                            int_error = int_rxframe_reg[((5)*4 + 53)] || int_error;  //BSP_ERROR_29
                            if(int_rxframe_reg[((5)*4 + 36):((5)*4 + 36 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_27
                                int_error = 1'b1;                       //BSP_ERROR_37
                            end
                        end
                        4'd5 : begin
                            o_acker = int_rxframe_reg[((6)*4 + 53)];    //BSP_ERROR_19
                            int_error = int_rxframe_reg[((6)*4 + 53)] || int_error;  //BSP_ERROR_29
                            if(int_rxframe_reg[((6)*4 + 36):((6)*4 + 36 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_27
                                int_error = 1'b1;                       //BSP_ERROR_37
                            end
                        end
                        4'd6 : begin
                            o_acker = int_rxframe_reg[((7)*4 + 53)];    //BSP_ERROR_19
                            int_error = int_rxframe_reg[((7)*4 + 53)] || int_error;  //BSP_ERROR_29
                            if(int_rxframe_reg[((7)*4 + 36):((7)*4 + 36 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_27
                                int_error = 1'b1;                       //BSP_ERROR_37
                            end
                        end
                        4'd7 : begin
                            o_acker = int_rxframe_reg[((8)*4 + 53)];    //BSP_ERROR_19
                            int_error = int_rxframe_reg[((8)*4 + 53)] || int_error;  //BSP_ERROR_29
                            if(int_rxframe_reg[((8)*4 + 36):((8)*4 + 36 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_27
                                int_error = 1'b1;                       //BSP_ERROR_37
                            end
                        end
                        4'd8 : begin
                            o_acker = int_rxframe_reg[((9)*4 + 53)];    //BSP_ERROR_19
                            int_error = int_rxframe_reg[((9)*4 + 53)] || int_error;  //BSP_ERROR_29
                            if(int_rxframe_reg[((9)*4 + 36):((9)*4 + 36 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_27
                                int_error = 1'b1;                       //BSP_ERROR_37
                            end
                        end
                        4'd9 : begin
                            o_acker = int_rxframe_reg[((10)*4 + 53)];   //BSP_ERROR_19
                            int_error = int_rxframe_reg[((10)*4 + 53)] || int_error;  //BSP_ERROR_29
                            if(int_rxframe_reg[((10)*4 + 36):((10)*4 + 36 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_27
                                int_error = 1'b1;                       //BSP_ERROR_37
                            end
                        end
                        4'd10 : begin
                            o_acker = int_rxframe_reg[((11)*4 + 53)];   //BSP_ERROR_19
                            int_error = int_rxframe_reg[((11)*4 + 53)] || int_error;  //BSP_ERROR_29
                            if(int_rxframe_reg[((11)*4 + 36):((11)*4 + 36 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_27
                                int_error = 1'b1;                       //BSP_ERROR_37
                            end
                        end
                        4'd11 : begin
                            o_acker = int_rxframe_reg[((12)*4 + 53)];   //BSP_ERROR_19
                            int_error = int_rxframe_reg[((12)*4 + 53)] || int_error;  //BSP_ERROR_29
                            if(int_rxframe_reg[((12)*4 + 36):((12)*4 + 36 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_27
                                int_error = 1'b1;                       //BSP_ERROR_37
                            end
                        end
                        4'd12 : begin
                            o_acker = int_rxframe_reg[((13)*4 + 53)];   //BSP_ERROR_19
                            int_error = int_rxframe_reg[((13)*4 + 53)] || int_error;  //BSP_ERROR_29
                            if(int_rxframe_reg[((13)*4 + 36):((13)*4 + 36 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_27
                                int_error = 1'b1;                       //BSP_ERROR_37
                            end
                        end
                        4'd13 : begin
                            o_acker = int_rxframe_reg[((14)*4 + 53)];   //BSP_ERROR_19
                            int_error = int_rxframe_reg[((14)*4 + 53)] || int_error;  //BSP_ERROR_29
                            if(int_rxframe_reg[((14)*4 + 36):((14)*4 + 36 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_27
                                int_error = 1'b1;                       //BSP_ERROR_37
                            end
                        end
                        4'd14 : begin
                            o_acker = int_rxframe_reg[((15)*4 + 53)];   //BSP_ERROR_19
                            int_error = int_rxframe_reg[((15)*4 + 53)] || int_error;  //BSP_ERROR_29
                            if(int_rxframe_reg[((15)*4 + 36):((15)*4 + 36 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_27
                                int_error = 1'b1;                       //BSP_ERROR_37
                            end
                        end
                        4'd15 : begin
                            o_acker = int_rxframe_reg[((16)*4 + 53)];   //BSP_ERROR_19
                            int_error = int_rxframe_reg[((16)*4 + 53)] || int_error;  //BSP_ERROR_29
                            if(int_rxframe_reg[((16)*4 + 36):((16)*4 + 36 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_27
                                int_error = 1'b1;                       //BSP_ERROR_37
                            end
                        end
                        default : begin
                            o_acker = int_rxframe_reg[((1)*4 + 53)];    //BSP_ERROR_19
                            int_error = int_rxframe_reg[((1)*4 + 53)] || int_error;  //BSP_ERROR_29
                            if(int_rxframe_reg[((1)*4 + 36):((1)*4 + 36 + 14)] != int_rx_crc_checksum) begin
                                o_crcer = 1'b1;                         //BSP_ERROR_27
                                int_error = 1'b1;                       //BSP_ERROR_37
                            end
                        end
                    endcase
                end
            end
            else if(int_rstate == BUSY) begin
                if(int_rxframe_reg[12] == 1'b0) begin
                    
                    //standard frame
                    case(int_rxframe_reg[14:17])
                        4'd0 : begin
                            if(int_rxframe_reg[((1)*4 + 33):((1)*4 + 35)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_24
                                int_error = 1'b1;                       //BSP_ERROR_34
                            end
                        end
                        4'd1 : begin
                            if(int_rxframe_reg[((2)*4 + 33):((2)*4 + 35)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_24
                                int_error = 1'b1;                       //BSP_ERROR_34
                            end 
                        end
                        4'd2 : begin
                            if(int_rxframe_reg[((3)*4 + 33):((3)*4 + 35)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_24
                                int_error = 1'b1;                       //BSP_ERROR_34
                            end 
                        end
                        4'd3 : begin
                            if(int_rxframe_reg[((4)*4 + 33):((4)*4 + 35)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_24
                                int_error = 1'b1;                       //BSP_ERROR_34
                            end 
                        end
                        4'd4 : begin
                            if(int_rxframe_reg[((5)*4 + 33):((5)*4 + 35)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_24
                                int_error = 1'b1;                       //BSP_ERROR_34
                            end 
                        end
                        4'd5 : begin
                            if(int_rxframe_reg[((6)*4 + 33):((6)*4 + 35)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_24
                                int_error = 1'b1;                       //BSP_ERROR_34
                            end 
                        end
                        4'd6 : begin
                            if(int_rxframe_reg[((7)*4 + 33):((7)*4 + 35)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_24
                                int_error = 1'b1;                       //BSP_ERROR_34
                            end 
                        end
                        4'd7 : begin
                            if(int_rxframe_reg[((8)*4 + 33):((8)*4 + 35)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_24
                                int_error = 1'b1;                       //BSP_ERROR_34
                            end 
                        end
                        4'd8 : begin
                            if(int_rxframe_reg[((9)*4 + 33):((9)*4 + 35)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_24
                                int_error = 1'b1;                       //BSP_ERROR_34
                            end 
                        end
                        4'd9 : begin
                            if(int_rxframe_reg[((10)*4 + 33):((10)*4 + 35)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_24
                                int_error = 1'b1;                       //BSP_ERROR_34
                            end 
                        end
                        4'd10 : begin
                            if(int_rxframe_reg[((11)*4 + 33):((11)*4 + 35)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_24
                                int_error = 1'b1;                       //BSP_ERROR_34
                            end 
                        end
                        4'd11 : begin
                            if(int_rxframe_reg[((12)*4 + 33):((12)*4 + 35)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_24
                                int_error = 1'b1;                       //BSP_ERROR_34
                            end 
                        end
                        4'd12 : begin
                            if(int_rxframe_reg[((13)*4 + 33):((13)*4 + 35)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_24
                                int_error = 1'b1;                       //BSP_ERROR_34
                            end 
                        end
                        4'd13 : begin
                            if(int_rxframe_reg[((14)*4 + 33):((14)*4 + 35)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_24
                                int_error = 1'b1;                       //BSP_ERROR_34
                            end 
                        end
                        4'd14 : begin
                            if(int_rxframe_reg[((15)*4 + 33):((15)*4 + 35)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_24
                                int_error = 1'b1;                       //BSP_ERROR_34
                            end 
                        end
                        4'd15 : begin
                            if(int_rxframe_reg[((16)*4 + 33):((16)*4 + 35)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_24
                                int_error = 1'b1;                       //BSP_ERROR_34
                            end 
                        end
                        default : begin
                            if(int_rxframe_reg[((1)*4 + 33):((1)*4 + 35)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_24
                                int_error = 1'b1;                       //BSP_ERROR_34
                            end 
                        end
                    endcase
                end
                else begin
                    //extended frame
                    case(int_rxframe_reg[32:35])
                        4'd0 : begin
                            if(int_rxframe_reg[((1)*4 + 51):((1)*4 + 53)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_25
                                int_error = 1'b1;                       //BSP_ERROR_35
                            end 
                        end
                        4'd1 : begin
                            if(int_rxframe_reg[((2)*4 + 51):((2)*4 + 53)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_25
                                int_error = 1'b1;                       //BSP_ERROR_35
                            end 
                        end
                        4'd2 : begin
                            if(int_rxframe_reg[((3)*4 + 51):((3)*4 + 53)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_25
                                int_error = 1'b1;                       //BSP_ERROR_35
                            end 
                        end
                        4'd3 : begin
                            if(int_rxframe_reg[((4)*4 + 51):((4)*4 + 53)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_25
                                int_error = 1'b1;                       //BSP_ERROR_35
                            end 
                        end
                        4'd4 : begin
                            if(int_rxframe_reg[((5)*4 + 51):((5)*4 + 53)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_25
                                int_error = 1'b1;                       //BSP_ERROR_35
                            end 
                        end
                        4'd5 : begin
                            if(int_rxframe_reg[((6)*4 + 51):((6)*4 + 53)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_25
                                int_error = 1'b1;                       //BSP_ERROR_35
                            end 
                        end
                        4'd6 : begin
                            if(int_rxframe_reg[((7)*4 + 51):((7)*4 + 53)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_25
                                int_error = 1'b1;                       //BSP_ERROR_35
                            end 
                        end
                        4'd7 : begin
                            if(int_rxframe_reg[((8)*4 + 51):((8)*4 + 53)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_25
                                int_error = 1'b1;                       //BSP_ERROR_35
                            end 
                        end
                        4'd8 : begin
                            if(int_rxframe_reg[((9)*4 + 51):((9)*4 + 53)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_25
                                int_error = 1'b1;                       //BSP_ERROR_35
                            end 
                        end
                        4'd9 : begin
                            if(int_rxframe_reg[((10)*4 + 51):((10)*4 + 53)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_25
                                int_error = 1'b1;                       //BSP_ERROR_35
                            end 
                        end
                        4'd10 : begin
                            if(int_rxframe_reg[((11)*4 + 51):((11)*4 + 53)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_25
                                int_error = 1'b1;                       //BSP_ERROR_35
                            end 
                        end
                        4'd11 : begin
                            if(int_rxframe_reg[((12)*4 + 51):((12)*4 + 53)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_25
                                int_error = 1'b1;                       //BSP_ERROR_35
                            end 
                        end
                        4'd12 : begin
                            if(int_rxframe_reg[((13)*4 + 51):((13)*4 + 53)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_25
                                int_error = 1'b1;                       //BSP_ERROR_35
                            end 
                        end
                        4'd13 : begin
                            if(int_rxframe_reg[((14)*4 + 51):((14)*4 + 53)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_25
                                int_error = 1'b1;                       //BSP_ERROR_35
                            end 
                        end
                        4'd14 : begin
                            if(int_rxframe_reg[((15)*4 + 51):((15)*4 + 53)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_25
                                int_error = 1'b1;                       //BSP_ERROR_35
                            end 
                        end
                        4'd15 : begin
                            if(int_rxframe_reg[((6)*4 + 51):((16)*4 + 53)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_25
                                int_error = 1'b1;                       //BSP_ERROR_35
                            end 
                        end
                        default : begin
                            if(int_rxframe_reg[((1)*4 + 51):((1)*4 + 53)] == 3'b101) begin
                                o_fmer = 1'b1;                          //BSP_ERROR_25
                                int_error = 1'b1;                       //BSP_ERROR_35
                            end 
                        end
                    endcase
                end
            end
            
            //int_error based conditionals
            if(int_error == 1'b0) begin
                
            end
        end
    end
//endmodule

//CRC FUNCTION MODULE
////////////////////////////////////////////////////////////////////////////////
// Copyright (C) 1999-2008 Easics NV.
// This source file may be used and distributed without restriction
// provided that this copyright statement is not removed from the file
// and that any derivative work contains the original copyright notice
// and the associated disclaimer.
//
// THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
// OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
// WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
//
// Purpose : synthesizable CRC function
//   * polynomial: x^15 + x^14 + x^10 + x^8 + x^7 + x^4 + x^3 + 1
//   * data width: 64
//
// Info : tools@easics.be
//        http://www.easics.com
////////////////////////////////////////////////////////////////////////////////
//module CRC15_D64;

  // polynomial: x^15 + x^14 + x^10 + x^8 + x^7 + x^4 + x^3 + 1
  // data width: 64
  // convention: the first serial bit is D[63]
  function [14:0] nextCRC15_D64(input [63:0] Data,
                                input [14:0] crc);

    //input [63:0] Data;
    //input [14:0] crc;
    reg [63:0] d;
    reg [14:0] c;
    reg [14:0] newcrc;
  begin
    d = Data;
    c = crc;

    newcrc[0] = d[63] ^ d[62] ^ d[61] ^ d[58] ^ d[57] ^ d[52] ^ d[51] ^ d[49] ^ d[48] ^ d[45] ^ d[43] ^ d[38] ^ d[37] ^ d[33] ^ d[29] ^ d[27] ^ d[21] ^ d[20] ^ d[19] ^ d[17] ^ d[14] ^ d[12] ^ d[11] ^ d[10] ^ d[9] ^ d[7] ^ d[6] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^ d[0] ^ c[0] ^ c[2] ^ c[3] ^ c[8] ^ c[9] ^ c[12] ^ c[13] ^ c[14];
    newcrc[1] = d[63] ^ d[62] ^ d[59] ^ d[58] ^ d[53] ^ d[52] ^ d[50] ^ d[49] ^ d[46] ^ d[44] ^ d[39] ^ d[38] ^ d[34] ^ d[30] ^ d[28] ^ d[22] ^ d[21] ^ d[20] ^ d[18] ^ d[15] ^ d[13] ^ d[12] ^ d[11] ^ d[10] ^ d[8] ^ d[7] ^ d[5] ^ d[4] ^ d[3] ^ d[2] ^ d[1] ^ c[0] ^ c[1] ^ c[3] ^ c[4] ^ c[9] ^ c[10] ^ c[13] ^ c[14];
    newcrc[2] = d[63] ^ d[60] ^ d[59] ^ d[54] ^ d[53] ^ d[51] ^ d[50] ^ d[47] ^ d[45] ^ d[40] ^ d[39] ^ d[35] ^ d[31] ^ d[29] ^ d[23] ^ d[22] ^ d[21] ^ d[19] ^ d[16] ^ d[14] ^ d[13] ^ d[12] ^ d[11] ^ d[9] ^ d[8] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[2] ^ c[1] ^ c[2] ^ c[4] ^ c[5] ^ c[10] ^ c[11] ^ c[14];
    newcrc[3] = d[63] ^ d[62] ^ d[60] ^ d[58] ^ d[57] ^ d[55] ^ d[54] ^ d[49] ^ d[46] ^ d[45] ^ d[43] ^ d[41] ^ d[40] ^ d[38] ^ d[37] ^ d[36] ^ d[33] ^ d[32] ^ d[30] ^ d[29] ^ d[27] ^ d[24] ^ d[23] ^ d[22] ^ d[21] ^ d[19] ^ d[15] ^ d[13] ^ d[11] ^ d[5] ^ d[2] ^ d[1] ^ d[0] ^ c[0] ^ c[5] ^ c[6] ^ c[8] ^ c[9] ^ c[11] ^ c[13] ^ c[14];
    newcrc[4] = d[62] ^ d[59] ^ d[57] ^ d[56] ^ d[55] ^ d[52] ^ d[51] ^ d[50] ^ d[49] ^ d[48] ^ d[47] ^ d[46] ^ d[45] ^ d[44] ^ d[43] ^ d[42] ^ d[41] ^ d[39] ^ d[34] ^ d[31] ^ d[30] ^ d[29] ^ d[28] ^ d[27] ^ d[25] ^ d[24] ^ d[23] ^ d[22] ^ d[21] ^ d[19] ^ d[17] ^ d[16] ^ d[11] ^ d[10] ^ d[9] ^ d[7] ^ d[4] ^ d[0] ^ c[0] ^ c[1] ^ c[2] ^ c[3] ^ c[6] ^ c[7] ^ c[8] ^ c[10] ^ c[13];
    newcrc[5] = d[63] ^ d[60] ^ d[58] ^ d[57] ^ d[56] ^ d[53] ^ d[52] ^ d[51] ^ d[50] ^ d[49] ^ d[48] ^ d[47] ^ d[46] ^ d[45] ^ d[44] ^ d[43] ^ d[42] ^ d[40] ^ d[35] ^ d[32] ^ d[31] ^ d[30] ^ d[29] ^ d[28] ^ d[26] ^ d[25] ^ d[24] ^ d[23] ^ d[22] ^ d[20] ^ d[18] ^ d[17] ^ d[12] ^ d[11] ^ d[10] ^ d[8] ^ d[5] ^ d[1] ^ c[0] ^ c[1] ^ c[2] ^ c[3] ^ c[4] ^ c[7] ^ c[8] ^ c[9] ^ c[11] ^ c[14];
    newcrc[6] = d[61] ^ d[59] ^ d[58] ^ d[57] ^ d[54] ^ d[53] ^ d[52] ^ d[51] ^ d[50] ^ d[49] ^ d[48] ^ d[47] ^ d[46] ^ d[45] ^ d[44] ^ d[43] ^ d[41] ^ d[36] ^ d[33] ^ d[32] ^ d[31] ^ d[30] ^ d[29] ^ d[27] ^ d[26] ^ d[25] ^ d[24] ^ d[23] ^ d[21] ^ d[19] ^ d[18] ^ d[13] ^ d[12] ^ d[11] ^ d[9] ^ d[6] ^ d[2] ^ c[0] ^ c[1] ^ c[2] ^ c[3] ^ c[4] ^ c[5] ^ c[8] ^ c[9] ^ c[10] ^ c[12];
    newcrc[7] = d[63] ^ d[61] ^ d[60] ^ d[59] ^ d[57] ^ d[55] ^ d[54] ^ d[53] ^ d[50] ^ d[47] ^ d[46] ^ d[44] ^ d[43] ^ d[42] ^ d[38] ^ d[34] ^ d[32] ^ d[31] ^ d[30] ^ d[29] ^ d[28] ^ d[26] ^ d[25] ^ d[24] ^ d[22] ^ d[21] ^ d[17] ^ d[13] ^ d[11] ^ d[9] ^ d[6] ^ d[4] ^ d[2] ^ d[1] ^ d[0] ^ c[1] ^ c[4] ^ c[5] ^ c[6] ^ c[8] ^ c[10] ^ c[11] ^ c[12] ^ c[14];
    newcrc[8] = d[63] ^ d[60] ^ d[57] ^ d[56] ^ d[55] ^ d[54] ^ d[52] ^ d[49] ^ d[47] ^ d[44] ^ d[39] ^ d[38] ^ d[37] ^ d[35] ^ d[32] ^ d[31] ^ d[30] ^ d[26] ^ d[25] ^ d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[19] ^ d[18] ^ d[17] ^ d[11] ^ d[9] ^ d[6] ^ d[5] ^ d[4] ^ d[0] ^ c[0] ^ c[3] ^ c[5] ^ c[6] ^ c[7] ^ c[8] ^ c[11] ^ c[14];
    newcrc[9] = d[61] ^ d[58] ^ d[57] ^ d[56] ^ d[55] ^ d[53] ^ d[50] ^ d[48] ^ d[45] ^ d[40] ^ d[39] ^ d[38] ^ d[36] ^ d[33] ^ d[32] ^ d[31] ^ d[27] ^ d[26] ^ d[24] ^ d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[19] ^ d[18] ^ d[12] ^ d[10] ^ d[7] ^ d[6] ^ d[5] ^ d[1] ^ c[1] ^ c[4] ^ c[6] ^ c[7] ^ c[8] ^ c[9] ^ c[12];
    newcrc[10] = d[63] ^ d[61] ^ d[59] ^ d[56] ^ d[54] ^ d[52] ^ d[48] ^ d[46] ^ d[45] ^ d[43] ^ d[41] ^ d[40] ^ d[39] ^ d[38] ^ d[34] ^ d[32] ^ d[29] ^ d[28] ^ d[25] ^ d[24] ^ d[23] ^ d[22] ^ d[17] ^ d[14] ^ d[13] ^ d[12] ^ d[10] ^ d[9] ^ d[8] ^ d[4] ^ d[3] ^ d[1] ^ d[0] ^ c[3] ^ c[5] ^ c[7] ^ c[10] ^ c[12] ^ c[14];
    newcrc[11] = d[62] ^ d[60] ^ d[57] ^ d[55] ^ d[53] ^ d[49] ^ d[47] ^ d[46] ^ d[44] ^ d[42] ^ d[41] ^ d[40] ^ d[39] ^ d[35] ^ d[33] ^ d[30] ^ d[29] ^ d[26] ^ d[25] ^ d[24] ^ d[23] ^ d[18] ^ d[15] ^ d[14] ^ d[13] ^ d[11] ^ d[10] ^ d[9] ^ d[5] ^ d[4] ^ d[2] ^ d[1] ^ c[0] ^ c[4] ^ c[6] ^ c[8] ^ c[11] ^ c[13];
    newcrc[12] = d[63] ^ d[61] ^ d[58] ^ d[56] ^ d[54] ^ d[50] ^ d[48] ^ d[47] ^ d[45] ^ d[43] ^ d[42] ^ d[41] ^ d[40] ^ d[36] ^ d[34] ^ d[31] ^ d[30] ^ d[27] ^ d[26] ^ d[25] ^ d[24] ^ d[19] ^ d[16] ^ d[15] ^ d[14] ^ d[12] ^ d[11] ^ d[10] ^ d[6] ^ d[5] ^ d[3] ^ d[2] ^ c[1] ^ c[5] ^ c[7] ^ c[9] ^ c[12] ^ c[14];
    newcrc[13] = d[62] ^ d[59] ^ d[57] ^ d[55] ^ d[51] ^ d[49] ^ d[48] ^ d[46] ^ d[44] ^ d[43] ^ d[42] ^ d[41] ^ d[37] ^ d[35] ^ d[32] ^ d[31] ^ d[28] ^ d[27] ^ d[26] ^ d[25] ^ d[20] ^ d[17] ^ d[16] ^ d[15] ^ d[13] ^ d[12] ^ d[11] ^ d[7] ^ d[6] ^ d[4] ^ d[3] ^ c[0] ^ c[2] ^ c[6] ^ c[8] ^ c[10] ^ c[13];
    newcrc[14] = d[62] ^ d[61] ^ d[60] ^ d[57] ^ d[56] ^ d[51] ^ d[50] ^ d[48] ^ d[47] ^ d[44] ^ d[42] ^ d[37] ^ d[36] ^ d[32] ^ d[28] ^ d[26] ^ d[20] ^ d[19] ^ d[18] ^ d[16] ^ d[13] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^ d[6] ^ d[5] ^ d[3] ^ d[2] ^ d[1] ^ d[0] ^ c[1] ^ c[2] ^ c[7] ^ c[8] ^ c[11] ^ c[12] ^ c[13];
    nextCRC15_D64 = newcrc;
  end
  endfunction
endmodule
