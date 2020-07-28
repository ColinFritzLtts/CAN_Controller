`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: L&T Technology Services Ltd.
// Engineer: Andrew Newman
// 
// Create Date: 07/17/2020 09:36:58 AM
// Design Name: CAN Bit Timing Module Testbench
// Module Name: can_btm_tb
// Project Name: CAN Controller
// Target Devices: Nexys A7-100
// Tool Versions: Vivado 2019.2
// Description: A testbench to validate CAN Bit Timing Module
// 
// Dependencies: can_bit_timing.sv
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module can_btm_tb();
    //tested module I/O
    reg  i_can_clk;
    reg  i_reset;
    reg  i_tx_bit;
    wire o_samp_tick;
    wire o_rx_bit;
    reg  [1:0] i_sjw;
    reg  [2:0] i_ts2;
    reg  [3:0] i_ts1;
    wire CAN_PHY_TX;
    reg  CAN_PHY_RX;
    
    //capture of the internal variables
    reg [1:0] int_state;
    reg [1:0] int_state_next;
    reg [5:0] int_rx_history;
    reg [7:0] int_state_counter;
    reg [2:0] int_ts2;
    reg [3:0] int_ts1;
    reg [2:0] int_ts2_next;
    reg [3:0] int_ts1_next;
    
    //testbench variables
    reg [63:0] tx_message;
    reg [63:0] rx_message;
    
    //component instantiation
    can_bit_timing DUT1(
        .i_can_clk   (i_can_clk), 
        .i_reset     (i_reset),   
        .i_tx_bit    (i_tx_bit),  
        .o_samp_tick (o_samp_tick),
        .o_rx_bit    (o_rx_bit),  
        .i_sjw       (i_sjw),
        .i_ts2       (i_ts2),
        .i_ts1       (i_ts1),
        .CAN_PHY_TX  (CAN_PHY_TX),
        .CAN_PHY_RX  (CAN_PHY_RX)
    );
    //initial setup
    initial begin
        i_can_clk = 1'b0;  
        i_reset = 1'b0;    
        i_tx_bit = 1'b1;
        i_sjw = 2'b01;
        i_ts2 = 3'b010;
        i_ts1 = 4'b0100;
        CAN_PHY_RX = 1'b1; 
    end 
  
  //clock generation
  always  
    #1 i_can_clk = !i_can_clk;  //clock generator 
  
  
  //data capture  
  always @(DUT1.int_state, DUT1.int_state_next, DUT1.int_rxbit_history, DUT1.int_state_counter) begin
      int_state = DUT1.int_state;
      int_state_next = DUT1.int_state_next;
      int_rx_history = DUT1.int_rxbit_history;
      int_state_counter = DUT1.int_state_counter;
  end
  
  always @(DUT1.int_ts2, DUT1.int_ts1, DUT1.int_ts2_next, DUT1.int_ts1_next) begin
      int_ts2      = DUT1.int_ts2;        
      int_ts1      = DUT1.int_ts1;        
      int_ts2_next = DUT1.int_ts2_next;
      int_ts1_next = DUT1.int_ts1_next;
  end 
  
  //variable dump
  initial  begin
    $dumpfile ("can_btm_tb.vcd"); 
    $dumpvars; 
  end 
  
  //simulation hard stop
  initial 
  #1600 $finish; 
    
    
  //Rest of testbench code after this line 
  initial begin
    tx_message[63:56] = (8'b00000011);
    tx_message[55:8] = (48'hAAAAAAAAAAAA);
    tx_message[7:0] = (8'b10111111);
    rx_message[63:55] = (9'b100000011);
    rx_message[54:7] = (48'hAAAAAAAAAAAA);
    rx_message[6:0] = (7'b1111111);
    
    #3 i_tx_bit = tx_message[0];
    CAN_PHY_RX = rx_message[0];
    for (int x = 1 ; x < 64; x++) begin
        @(posedge o_samp_tick) i_tx_bit = tx_message[x];
        CAN_PHY_RX = rx_message[x];
    end
    #1 i_reset = 1'b1;
  end
endmodule
