`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: L&T Technology Services Ltd.
// Engineer: Andrew Newman
// 
// Create Date: 07/17/2020 09:36:58 AM
// Design Name: CAN Bitstream Processor Module Testbench
// Module Name: can_bsp_tb
// Project Name: CAN Controller
// Target Devices: Nexys A7-100
// Tool Versions: Vivado 2019.2
// Description: A testbench to validate CAN Bitstream Processor Module
// 
// Dependencies: can_bsp.sv
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module can_bsp_tb();
    //tested module I/O
    reg  i_sleep;
    reg  i_lback;
    reg  i_reset;
    reg [0:127] i_send_data;
    reg  i_send_en;
    reg  i_can_clk;
    reg  i_cen;
    wire o_busy_can;
    wire o_acker;
    wire o_berr;
    wire o_ster;
    wire o_fmer;
    wire o_crcer;
    wire o_can_ready;
    wire [0:127] o_rx_message;
    wire [7:0] o_rec;
    wire [7:0] o_tec;
    wire o_errwrn;
    wire o_bbsy;
    wire o_bidle;
    wire o_normal;
    wire o_sleep;
    wire o_tx_bit;
    reg  i_samp_tick;
    reg  i_rx_bit;
    wire o_lback;
    wire o_config;
    wire o_wakeup;
    wire o_bsoff;
    wire o_error;
    wire o_txok;
    wire o_arblst;
    wire [1:0] o_estat;
    
    //capture of the internal variables
    
    
    //testbench variables
    reg[127:0] i_send_data_r;
    
    //component instantiation
    can_bsp DUT1(
    .i_sleep      (i_sleep     ),        
    .i_lback      (i_lback     ),       
    .i_reset      (i_reset     ),       
    .i_send_data  (i_send_data ),
    .i_send_en    (i_send_en   ),       
    .i_can_clk    (i_can_clk   ),       
    .i_cen        (i_cen       ),       
    .o_busy_can   (o_busy_can  ),       
    .o_acker      (o_acker     ),       
    .o_berr       (o_berr      ),       
    .o_ster       (o_ster      ),       
    .o_fmer       (o_fmer      ),       
    .o_crcer      (o_crcer     ),       
    .o_can_ready  (o_can_ready ),       
    .o_rx_message (o_rx_message),
    .o_rec        (o_rec       ), 
    .o_tec        (o_tec       ), 
    .o_errwrn     (o_errwrn    ),       
    .o_bbsy       (o_bbsy      ),       
    .o_bidle      (o_bidle     ),       
    .o_normal     (o_normal    ),       
    .o_sleep      (o_sleep     ),       
    .o_tx_bit     (o_tx_bit    ),       
    .i_samp_tick  (i_samp_tick ),       
    .i_rx_bit     (i_rx_bit    ),       
    .o_lback      (o_lback     ),       
    .o_config     (o_config    ),       
    .o_wakeup     (o_wakeup    ),       
    .o_bsoff      (o_bsoff     ),       
    .o_error      (o_error     ),       
    .o_txok       (o_txok      ),       
    .o_arblst     (o_arblst    ),       
    .o_estat      (o_estat     ) 
    );
    //initial setup
    initial begin
        i_sleep = 1'b0;
        i_lback = 1'b1;
        i_reset = 1'b0;
        i_send_en = 1'b0;
        i_can_clk = 1'b0;
        i_cen = 1'b1;
        i_samp_tick = 1'b0;
        i_rx_bit = 1'b1;
        
    end 
    
    
  
  //clock generation
  always  
    #1 i_can_clk = !i_can_clk;  //clock generator
  
  always begin
    #14 i_samp_tick = !i_samp_tick; //create one samp_tick pulse every 8 cycles
    #2  i_samp_tick = !i_samp_tick;
  end
  
  //data capture  
  
  
  //variable dump
  initial  begin
    $dumpfile ("can_btm_tb.vcd"); 
    $dumpvars; 
  end 
  
  //simulation hard stop
  initial 
  #1600 $finish; 
  
  always
    #1 i_send_data <= {<<{i_send_data_r}};

    
  //Rest of testbench code after this line 
  initial begin
    i_send_data_r <= {32'h000000AA, 32'h0000000F, 32'h01234567, 32'h89ABCDEF};
    #2 i_reset = 1'b1;
    #2 i_reset = 1'b0;
    i_send_en = 1'b1;
    #3000 $finish;
  end
endmodule
