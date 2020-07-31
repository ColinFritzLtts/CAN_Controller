`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: L&T Technology Services Ltd.
// Engineer: Andrew Newman
// 
// Create Date: 07/28/2020 01:02:01 PM
// Design Name: Acceptance Filter Testcase Testbench
// Module Name: Acceptance_Filter_Testcases
// Project Name: CAN Controller
// Target Devices: 
// Tool Versions: 
// Description: Acceptance Filter Testcase Testbench for functional verification of Acceptance_Filter.sv
// 
// Dependencies: Acceptance_Filter.sv
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Acceptance_Filter_Testcases(

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

localparam [2:0] IDLE = 0, PROCESSING = 1, ACCEPTMESSAGE =2, DISCARDMESSAGE =3;

Acceptance_Filter DUT(
    .i_sys_clk(i_sys_clk), 
    .i_reset(i_reset), 
    .i_can_clk(i_can_clk), 
    .i_can_ready(i_can_ready), 
    .i_rx_message(i_rx_message[127:0]), 
    .o_rx_w_en(o_rx_w_en), 
    .o_rx_fifo_w_data(o_rx_fifo_w_data[127:0]), 
    .i_rx_full(i_rx_full), 
    .o_acfbsy(o_acfbsy), 
    .i_afmr1(i_afmr1[31:0]),
    .i_afmr2(i_afmr2[31:0]), 
    .i_afmr3(i_afmr3[31:0]), 
    .i_afmr4(i_afmr4[31:0]), 
    .i_afir1(i_afir1[31:0]), 
    .i_afir2(i_afir2[31:0]), 
    .i_afir3(i_afir3[31:0]), 
    .i_afir4(i_afir4[31:0]), 
    .i_uaf1(i_uaf1), 
    .i_uaf2(i_uaf2), 
    .i_uaf3(i_uaf3), 
    .i_uaf4(i_uaf4)
    );

initial begin 
    i_sys_clk = 0;
    forever #2 i_sys_clk <=~i_sys_clk;
end

initial begin 
    i_reset = 1;
    #20 i_reset = 0;
end

initial begin 
    i_can_clk = 0;
    forever #10 i_can_clk <= ~i_can_clk;
end 

//Testbench proper
initial begin 
    //Filter and message setup
    i_uaf1 = 1'b0;
    i_uaf2 = 1'b0;
    i_uaf3 = 1'b0;
    i_uaf4 = 1'b0;
    i_can_ready = 1'b0;
    i_rx_message[127:96] <= 32'hFFFFFFFF;
    i_rx_message[95:0] <= 96'hAAAAAAAAAAAAAAAAAAAAAAAA;
    i_afmr1 = 32'h7FFFFFFE;
    i_afir1 = 32'hFFFFFFFF;
    i_afmr2 = 32'h3FFFFFFC;
    i_afir2 = 32'hFFFFFFFF;
    i_afmr3 = 32'h1FFFFFF8;
    i_afir3 = 32'hFFFFFFFF;
    i_afmr4 = 32'h0FFFFFF0;
    #1 i_afir4 = 32'hFFFFFFFF;

    //ACCEPT_INIT_01_01
    i_reset = 1'b1;
    #1 $display("[ACCEPT_INIT_01_01] The module shall set o_rx_w_en logic low when i_reset is logic high.");
    assert (o_rx_w_en == 1'b0) 
        $display("PASS: o_rx_w_en = %b", o_rx_w_en);
    else
        $error("FAIL: o_rx_w_en = %b", o_rx_w_en);
    i_reset = 1'b0;
    #100;
    //
    //ACCEPT_INIT_02_01
    i_reset = 1'b1;
    #1 $display("[ACCEPT_INIT_02_01] The module shall set o_acfbsy to logic low when i_reset is logic high.");
    assert (o_acfbsy == 1'b0) 
        $display("PASS: o_acfbsy = %b", o_acfbsy);
    else
        $error("FAIL: o_acfbsy = %b", o_acfbsy);
    i_reset = 1'b0;
    #100;
    
    //ACCEPT_INIT_03_01
    i_reset = 1'b1;
    #1 $display("[ACCEPT_INIT_03_01] The module shall set o_rx_fifo_w_data[127:0] to all zeroes when i_reset is logic high.");
    assert (o_rx_fifo_w_data == 128'b0) 
        $display("PASS: o_rx_fifo_w_data = %b", o_rx_fifo_w_data);
    else
        $error("FAIL: o_rx_fifo_w_data = %b", o_rx_fifo_w_data);
    i_reset = 1'b0;
    #100;
     
    //ACCEPT_READY_01_01
    @(posedge i_sys_clk);
    i_can_ready = 1'b1;
    @(posedge i_sys_clk);
    $display("[ACCEPT_READY_01_01] The module shall set can_ready_synched logic high two i_sys_clk cycles after i_can_ready signal is set logic high.");
    @(posedge i_sys_clk) assert (DUT.can_ready_synched == 1'b1) 
        $display("PASS: can_ready_synched = %b", DUT.can_ready_synched);
    else
        $error("FAIL: can_ready_synched = %b", DUT.can_ready_synched);
    i_can_ready = 1'b0;
    #100;
    
    //ACCEPT_READY_01_02
    @(posedge i_sys_clk);
    i_can_ready = 1'b1;
    @(posedge i_sys_clk);
    @(posedge i_sys_clk);
    i_can_ready = 1'b0;
    @(posedge i_sys_clk);
    $display("[ACCEPT_READY_01_02] The module shall set can_ready_synched logic low two i_sys_clk cycles after i_can_ready signal is set logic low.  ");
    @(posedge i_sys_clk) assert (DUT.can_ready_synched == 1'b0) 
        $display("PASS: can_ready_synched = %b", DUT.can_ready_synched);
    else
        $error("FAIL: can_ready_synched = %b", DUT.can_ready_synched);
    #100;
    
    //ACCEPT_READY_02_01
    $display("[ACCEPT_READY_02_01] The module shall name the output of the double synchronizer in ACCEPT_READY_01 can_ready_synched.");
    assert (DUT.can_ready_synched == DUT.can_ready_synched) 
        $display("PASS: can_ready_synched = %b", DUT.can_ready_synched);
    else
        $error("FAIL: can_ready_synched = %b", DUT.can_ready_synched);
    #100;
    
    //ACCEPT_MASKMSG_01_01
    i_uaf1 = 1'b1;
    #1 $display("[ACCEPT_MASKMSG_01_01] The module shall perform bitwise logical AND operation on i_afmr1[31:0] with i_rx_message[127:96] and name the result mask_msg_one[31:0] if i_uaf1 is logic high.");
    assert (DUT.mask_msg_one == i_afmr1 & i_rx_message[127:96]) 
        $display("PASS: mask_msg_one = %b", DUT.mask_msg_one);
    else
        $error("FAIL: mask_msg_one = %b", DUT.mask_msg_one);
    i_uaf1 = 1'b0;
    #100;
    
    //ACCEPT_MASKMSG_02_01
    i_uaf2 = 1'b1;
    #1 $display("[ACCEPT_MASKMSG_02_01] The module shall perform bitwise logical AND operation on i_afmr2[31:0] with i_rx_message[127:96] and name the result  mask_msg_two[31:0] if i_uaf2 is logic high.  ");
    assert (DUT.mask_msg_two == i_afmr2 & i_rx_message[127:96]) 
        $display("PASS: mask_msg_two = %b", DUT.mask_msg_two);
    else
        $error("FAIL: mask_msg_two = %b", DUT.mask_msg_two);
    i_uaf2 = 1'b0;
    #100;
    
    //ACCEPT_MASKMSG_03_01
    i_uaf3 = 1'b1;
    #1 $display("[ACCEPT_MASKMSG_03_01] The module shall perform bitwise logical AND operation on i_afmr3[31:0] with i_rx_message[127:96] and name the result mask_msg_three[31:0] if i_uaf3 is logic high.  ");
    assert (DUT.mask_msg_three == i_afmr3 & i_rx_message[127:96]) 
        $display("PASS: mask_msg_three = %b", DUT.mask_msg_three);
    else
        $error("FAIL: mask_msg_three = %b", DUT.mask_msg_three);
    i_uaf3 = 1'b0;
    #100;
    
    //ACCEPT_MASKMSG_04_01
    i_uaf4 = 1'b1;
    #1 $display("[ACCEPT_MASKMSG_04_01] The module shall perform bitwise logical AND operation on i_afmr4[31:0] with i_rx_message[127:96] and name the result  mask_msg_four[31:0] if i_uaf4 is logic high.  ");
    assert (DUT.mask_msg_four == i_afmr4 & i_rx_message[127:96]) 
        $display("PASS: mask_msg_four = %b", DUT.mask_msg_four);
    else
        $error("FAIL: mask_msg_four = %b", DUT.mask_msg_four);
    i_uaf4 = 1'b0;
    #100;
    
    //ACCEPT_MASKMSG_05_01
    i_uaf1 = 1'b0;
    #1 $display("[ACCEPT_MASKMSG_05_01] The module shall set mask_msg_one[31:0] equal to 0x00000000 if i_uaf1 is logic low.");
    assert (DUT.mask_msg_one == 32'd0) 
        $display("PASS: mask_msg_one = %b", DUT.mask_msg_one);
    else
        $error("FAIL: mask_msg_one = %b", DUT.mask_msg_one);
    i_uaf1 = 1'b0;
    #100;
    
    //ACCEPT_MASKMSG_06_01
    i_uaf2 = 1'b0;
    #1 $display("[ACCEPT_MASKMSG_06_01] The module shall set mask_msg_two[31:0] equal to 0x00000000 if i_uaf2 is logic low.");
    assert (DUT.mask_msg_two == 32'd0) 
        $display("PASS: mask_msg_two = %b", DUT.mask_msg_two);
    else
        $error("FAIL: mask_msg_two = %b", DUT.mask_msg_two);
    i_uaf2 = 1'b0;
    #100;
    
    //ACCEPT_MASKMSG_07_01
    i_uaf3 = 1'b0;
    #1 $display("[ACCEPT_MASKMSG_07_01] The module shall set mask_msg_three[31:0] equal to 0x00000000 if i_uaf3 is logic low.");
    assert (DUT.mask_msg_three == 32'd0) 
        $display("PASS: mask_msg_three = %b", DUT.mask_msg_three);
    else
        $error("FAIL: mask_msg_three = %b", DUT.mask_msg_three);
    i_uaf3 = 1'b0;
    #100;
    
    //ACCEPT_MASKMSG_08_01
    i_uaf4 = 1'b0;
    #1 $display("[ACCEPT_MASKMSG_08_01] The module shall set mask_msg_four[31:0] equal to 0x00000000 if i_uaf4 is logic low.");
    assert (DUT.mask_msg_four == 32'd0) 
        $display("PASS: mask_msg_four = %b", DUT.mask_msg_four);
    else
        $error("FAIL: mask_msg_four = %b", DUT.mask_msg_four);
    i_uaf4 = 1'b0;
    #100;
    
    //ACCEPT_MASKID_01_01
    i_uaf1 = 1'b1;
    #1 $display("[ACCEPT_MASKID_01_01] The module shall perform bitwise logical AND operation on i_afmr1[31:0] with i_afir1[31:0] and name the result mask_id_one[31:0] if i_uaf1 is logic high.");
    assert (DUT.mask_id_one == i_afmr1 & i_afir1) 
        $display("PASS: mask_id_one = %b", DUT.mask_id_one);
    else
        $error("FAIL: mask_id_one = %b", DUT.mask_id_one);
    i_uaf1 = 1'b0;
    #100;
    
    //ACCEPT_MASKID_02_01
    i_uaf2 = 1'b1;
    #1 $display("[ACCEPT_MASKID_02_01] The module shall perform bitwise logical AND operation on i_afmr2[31:0] with i_afir2[31:0] and name the result  mask_id_two[31:0] if i_uaf2 is logic high.  ");
    assert (DUT.mask_id_two == i_afmr2 & i_afir2) 
        $display("PASS: mask_id_two = %b", DUT.mask_id_two);
    else
        $error("FAIL: mask_id_two = %b", DUT.mask_id_two);
    i_uaf2 = 1'b0;
    #100;
    
    //ACCEPT_MASKID_03_01
    i_uaf3 = 1'b1;
    #1 $display("[ACCEPT_MASKID_03_01] The module shall perform bitwise logical AND operation on i_afmr3[31:0] with i_afir3[31:0] and name the result mask_id_three[31:0] if i_uaf3 is logic high.  ");
    assert (DUT.mask_id_three == i_afmr3 & i_afir3) 
        $display("PASS: mask_id_three = %b", DUT.mask_id_three);
    else
        $error("FAIL: mask_id_three = %b", DUT.mask_id_three);
    i_uaf3 = 1'b0;
    #100;
    
    //ACCEPT_MASKID_04_01
    i_uaf4 = 1'b1;
    #1 $display("[ACCEPT_MASKID_04_01] The module shall perform bitwise logical AND operation on i_afmr4[31:0] with i_afir4[31:0] and name the result  mask_id_four[31:0] if i_uaf4 is logic high.");
    assert (DUT.mask_id_four == i_afmr4 & i_afir4) 
        $display("PASS: mask_id_four = %b", DUT.mask_id_four);
    else
        $error("FAIL: mask_id_four = %b", DUT.mask_id_four);
    i_uaf4 = 1'b0;
    #100;
    
    //ACCEPT_MASKID_05_01
    i_uaf1 = 1'b0;
    #1 $display("[ACCEPT_MASKID_05_01] The module shall set mask_id_one[31:0] equal to 0x00000000 if i_uaf1 is logic low.");
    assert (DUT.mask_id_one == 32'd0) 
        $display("PASS: mask_id_one = %b", DUT.mask_id_one);
    else
        $error("FAIL: mask_id_one = %b", DUT.mask_id_one);
    i_uaf1 = 1'b0;
    #100;
    
    //ACCEPT_MASKID_06_01
    i_uaf2 = 1'b0;
    #1 $display("[ACCEPT_MASKID_06_01] The module shall set mask_id_two[31:0] equal to 0x00000000 if i_uaf2 is logic low.");
    assert (DUT.mask_id_two == 32'd0) 
        $display("PASS: mask_id_two = %b", DUT.mask_id_two);
    else
        $error("FAIL: mask_id_two = %b", DUT.mask_id_two);
    i_uaf2 = 1'b0;
    #100;
    
    //ACCEPT_MASKID_07_01
    i_uaf3 = 1'b0;
    #1 $display("[ACCEPT_MASKID_07_01] The module shall set mask_id_three[31:0] equal to 0x00000000 if i_uaf3 is logic low.");
    assert (DUT.mask_id_three == 32'd0) 
        $display("PASS: mask_id_three = %b", DUT.mask_id_three);
    else
        $error("FAIL: mask_id_three = %b", DUT.mask_id_three);
    i_uaf3 = 1'b0;
    #100;
    
    //ACCEPT_MASKID_08_01
    i_uaf4 = 1'b0;
    #1 $display("[ACCEPT_MASKID_08_01] The module shall set mask_id_four[31:0] equal to 0x00000000 if i_uaf4 is logic low.");
    assert (DUT.mask_id_four == 32'd0) 
        $display("PASS: mask_id_four = %b", DUT.mask_id_four);
    else
        $error("FAIL: mask_id_four = %b", DUT.mask_id_four);
    i_uaf4 = 1'b0;
    #100;
    
    //ACCEPT_MASKID_09_01
    $display("[ACCEPT_MASKID_09_01] The module shall perform bitwise AND operation in ACCEPT_MASKID_01-04 with i_afmr1-4[31] of the first signal aligned with the i_afir1-4[31] bit of the second signal and so on down to position [0] of both.");
    $display("Please inspect the code to verify bitwise AND operation");
    #100;
    
    //ACCEPT_FSM_01_01
    #1 $display("[ACCEPT_FSM_01_01] The module shall implement an FSM with states IDLE, PROCESSING, ACCEPTMESSAGE, and DISCARDMESSAGE.");
    assert (DUT.int_state < 4) 
        $display("PASS1: DUT.int_state = %b", DUT.int_state);
    else
        $error("FAIL1: DUT.int_state = %b", DUT.int_state);
    assert (DUT.int_state_next < 4) 
        $display("PASS2: DUT.int_state_next = %b", DUT.int_state_next);
    else
        $error("FAIL2: DUT.int_state_next = %b", DUT.int_state_next);
    #100;
    
    //ACCEPT_FSM_02_01
    wait(DUT.int_state == IDLE);
    i_can_ready = 1'b1;
    wait (DUT.can_ready_synched == 1'b1);
    #1 $display("[ACCEPT_FSM_02_01] The module shall set int_state_next to PROCESSING if int_state is IDLE and can_ready_synched is logic high.");
    assert (DUT.int_state_next == PROCESSING) 
        $display("PASS: int_state_next = %b", DUT.int_state_next);
    else
        $error("FAIL: int_state_next = %b", DUT.int_state_next);
    i_can_ready = 1'b0;
    #100;
    
    //ACCEPT_FSM_03_01
    wait(DUT.int_state == IDLE);
    i_can_ready = 1'b1;
    i_uaf1 = 1'b1;
    wait (DUT.can_ready_synched == 1'b1);
    wait(DUT.int_state == PROCESSING);
    #1 $display("[ACCEPT_FSM_03_01] The module shall transition FSM from state PROCESSING to state ACCEPTMESSAGE if 1. mask_id_one[31:0] is not 0x00000000 and 2.  mask_msg_one[31:0] is not 0x00000000  and 3.i_uaf1 is logic high and 4. mask_id_one{31:0] is bitwise equivalent to mask_msg_one[31:0}");
    assert (DUT.int_state_next == ACCEPTMESSAGE) 
        $display("PASS: int_state_next = %b", DUT.int_state_next);
    else
        $error("FAIL: int_state_next = %b", DUT.int_state_next);
    i_can_ready = 1'b0;
    i_uaf1 = 1'b0;
    #100;
    
    //ACCEPT_FSM_04_01
    wait(DUT.int_state == IDLE);
    i_can_ready = 1'b1;
    i_uaf2 = 1'b1;
    wait (DUT.can_ready_synched == 1'b1);
    wait(DUT.int_state == PROCESSING);
    #1 $display("[ACCEPT_FSM_04_01] The module shall transition FSM from state PROCESSING to state ACCEPTMESSAGE if 1.  mask_id_two[31:0] is not 0x00000000 and 2.  mask_msg_two[31:0] is not 0x00000000 and 3.i_uaf2 is logic high and 4. mask_id_two{31:0] is bitwise equivalent to mask_msg_two[31:0]");
    assert (DUT.int_state_next == ACCEPTMESSAGE) 
        $display("PASS: int_state_next = %b", DUT.int_state_next);
    else
        $error("FAIL: int_state_next = %b", DUT.int_state_next);
    i_can_ready = 1'b0;
    i_uaf2 = 1'b0;
    #100;
    
    //ACCEPT_FSM_05_01
    wait(DUT.int_state == IDLE);
    i_can_ready = 1'b1;
    i_uaf3 = 1'b1;
    wait (DUT.can_ready_synched == 1'b1);
    wait(DUT.int_state == PROCESSING);
    #1 $display("[ACCEPT_FSM_05_01] The module shall transition FSM from state PROCESSING to state ACCEPTMESSAGE if 1. mask_id_three[31:0] is not 0x00000000 and 2. mask_msg_three[31:0] is not 0x00000000 and 3.i_uaf3 is logic high and 4. mask_id_three{31:0] is bitwise equivalent to mask_msg_three[31:0]");
    assert (DUT.int_state_next == ACCEPTMESSAGE) 
        $display("PASS: int_state_next = %b", DUT.int_state_next);
    else
        $error("FAIL: int_state_next = %b", DUT.int_state_next);
    i_can_ready = 1'b0;
    i_uaf3 = 1'b0;
    #100;
    
    //ACCEPT_FSM_06_01
    wait(DUT.int_state == IDLE);
    i_can_ready = 1'b1;
    i_uaf4 = 1'b1;
    wait (DUT.can_ready_synched == 1'b1);
    wait(DUT.int_state == PROCESSING);
    #1 $display("[ACCEPT_FSM_06_01] The module shall transition FSM from state PROCESSING to state ACCEPTMESSAGE if 1. mask_id_four[31:0] is not 0x00000000 and 2. mask_msg_four[31:0] is not 0x00000000 and 3. i_uaf4 is logic high and 4.mask_id_four[31:0] is bitwise equivalent to mask_msg_four[31:0]");
    assert (DUT.int_state_next == ACCEPTMESSAGE) 
        $display("PASS: int_state_next = %b", DUT.int_state_next);
    else
        $error("FAIL: int_state_next = %b", DUT.int_state_next);
    i_can_ready = 1'b0;
    i_uaf4 = 1'b0;
    #100;
    
    //ACCEPT_FSM_07_01
    wait(DUT.int_state == IDLE);
    i_can_ready = 1'b1;
    i_uaf1 = 1'b0;
    i_uaf2 = 1'b0;
    i_uaf3 = 1'b0;
    i_uaf4 = 1'b0;
    wait (DUT.can_ready_synched == 1'b1);
    wait(DUT.int_state == PROCESSING);
    #1 $display("[ACCEPT_FSM_07_01] The module shall transition FSM from state PROCESSING to state ACCEPTMESSAGE if i_uaf1 is logic low, i_uaf2 is logic low, i_uaf3 is logic low, and i_uaf4 is logic low.");
    assert (DUT.int_state_next == ACCEPTMESSAGE) 
        $display("PASS: int_state_next = %b", DUT.int_state_next);
    else
        $error("FAIL: int_state_next = %b", DUT.int_state_next);
    i_can_ready = 1'b0;
    #100;
    
    //ACCEPT_FSM_08_01
    wait(DUT.int_state == IDLE);
    i_can_ready = 1'b1;
    i_rx_message[127:96] = 32'd0;
    i_afmr1 = 32'd0;
    i_afir1 = 32'd0;
    i_afmr2 = 32'd0;
    i_afir2 = 32'd0;
    i_afmr3 = 32'd0;
    i_afir3 = 32'd0;
    i_afmr4 = 32'd0;
    i_afir4 = 32'd0;
    wait (DUT.can_ready_synched == 1'b1);
    wait(DUT.int_state == PROCESSING);
    #1 $display("[ACCEPT_FSM_08_01] The module shall transition FSM from state PROCESSING to state ACCEPTMESSAGE if 1. mask_id_one[31:0] is 0x00000000  and 2.mask_id_two[31:0] 0x00000000 and 3.mask_id_three[31:0] is 0x00000000 and 4.mask_id_four[31:0] is 0x00000000 and 5.mask_msg_one[31:0] is 0x00000000 6.mask_msg_two[31:0] is 0x00000000 7.mask_msg_three[31:0] is 0x00000000 and 8.mask_msg_four[31:0] is 0x00000000.");
    assert (DUT.int_state_next == ACCEPTMESSAGE) 
        $display("PASS: int_state_next = %b", DUT.int_state_next);
    else
        $error("FAIL: int_state_next = %b", DUT.int_state_next);
    i_can_ready = 1'b0;
    i_rx_message[127:96] = 32'hFFFFFFFF;
    i_afmr1 = 32'h7FFFFFFE;
    i_afir1 = 32'hFFFFFFFF;
    i_afmr2 = 32'h3FFFFFFC;
    i_afir2 = 32'hFFFFFFFF;
    i_afmr3 = 32'h1FFFFFF8;
    i_afir3 = 32'hFFFFFFFF;
    i_afmr4 = 32'h0FFFFFF0;
    i_afir4 = 32'hFFFFFFFF;
    #100;
    
    //ACCEPT_FSM_09_01
    wait(DUT.int_state == IDLE);
    i_can_ready = 1'b1;
    i_uaf1 = 1'b1;
    i_rx_message[127:96] = 32'hFFFFFFFF;
    i_afir1 = 32'hFFFFFF00;
    wait (DUT.can_ready_synched == 1'b1);
    wait(DUT.int_state == PROCESSING);
    #1 $display("[ACCEPT_FSM_09_01] The module shall transition FSM from state PROCESSING to state DISCARDMESSAGE if none of the conditional statements in ACCEPT_FSM_03-08 evaluate to True for the mask_id_one and mask_msg_one pair.");
    assert (DUT.int_state_next == DISCARDMESSAGE) 
        $display("PASS: int_state_next = %b", DUT.int_state_next);
    else
        $error("FAIL: int_state_next = %b", DUT.int_state_next);
    i_can_ready = 1'b0;
    i_uaf1 = 1'b0;
    i_rx_message[127:96] = 32'hFFFFFFFF;
    i_afir1 = 32'hFFFFFFFF;
    #100;
    
    //ACCEPT_FSM_09_02
    wait(DUT.int_state == IDLE);
    i_can_ready = 1'b1;
    i_uaf2 = 1'b1;
    i_rx_message[127:96] = 32'hFFFFFFFF;
    i_afir2 = 32'hFFFFFF00;
    wait (DUT.can_ready_synched == 1'b1);
    wait(DUT.int_state == PROCESSING);
    #1 $display("[ACCEPT_FSM_09_02] The module shall transition FSM from state PROCESSING to state DISCARDMESSAGE if none of the conditional statements in ACCEPT_FSM_03-08 evaluate to True for the mask_id_two and mask_msg_two pair.");
    assert (DUT.int_state_next == DISCARDMESSAGE) 
        $display("PASS: int_state_next = %b", DUT.int_state_next);
    else
        $error("FAIL: int_state_next = %b", DUT.int_state_next);
    i_can_ready = 1'b0;
    i_uaf2 = 1'b0;
    i_rx_message[127:96] = 32'hFFFFFFFF;
    i_afir2 = 32'hFFFFFFFF;
    #100;
    
    //ACCEPT_FSM_09_03
    wait(DUT.int_state == IDLE);
    i_can_ready = 1'b1;
    i_uaf3 = 1'b1;
    i_rx_message[127:96] = 32'hFFFFFFFF;
    i_afir3 = 32'hFFFFFF00;
    wait (DUT.can_ready_synched == 1'b1);
    wait(DUT.int_state == PROCESSING);
    #1 $display("[ACCEPT_FSM_09_03] The module shall transition FSM from state PROCESSING to state DISCARDMESSAGE if none of the conditional statements in ACCEPT_FSM_03-08 evaluate to True for the mask_id_three and mask_msg_three pair.");
    assert (DUT.int_state_next == DISCARDMESSAGE) 
        $display("PASS: int_state_next = %b", DUT.int_state_next);
    else
        $error("FAIL: int_state_next = %b", DUT.int_state_next);
    i_can_ready = 1'b0;
    i_uaf3 = 1'b0;
    i_rx_message[127:96] = 32'hFFFFFFFF;
    i_afir3 = 32'hFFFFFFFF;
    #100;
    
    //ACCEPT_FSM_09_04
    wait(DUT.int_state == IDLE);
    i_can_ready = 1'b1;
    i_uaf4 = 1'b1;
    i_rx_message[127:96] = 32'hFFFFFFFF;
    i_afir4 = 32'hFFFFFF00;
    wait (DUT.can_ready_synched == 1'b1);
    wait(DUT.int_state == PROCESSING);
    #1 $display("[ACCEPT_FSM_09_04] The module shall transition FSM from state PROCESSING to state DISCARDMESSAGE if none of the conditional statements in ACCEPT_FSM_03-08 evaluate to True for the mask_id_four and mask_msg_four pair.");
    assert (DUT.int_state_next == DISCARDMESSAGE) 
        $display("PASS: int_state_next = %b", DUT.int_state_next);
    else
        $error("FAIL: int_state_next = %b", DUT.int_state_next);
    i_can_ready = 1'b0;
    i_uaf4 = 1'b0;
    i_rx_message[127:96] = 32'hFFFFFFFF;
    i_afir4 = 32'hFFFFFFFF;
    #100;
    
    //ACCEPT_FSM_10_01
    wait(DUT.int_state == IDLE);
    #1 $display("[ACCEPT_FSM_10_01] The module shall set o_rx_w_en logic low when int_state is IDLE.");
    assert (o_rx_w_en == 1'b0) 
        $display("PASS: o_rx_w_en = %b", o_rx_w_en);
    else
        $error("FAIL: o_rx_w_en = %b", o_rx_w_en);
    #100;
    
    //ACCEPT_FSM_11_01
    wait(DUT.int_state == IDLE);
    i_can_ready = 1'b1;
    i_uaf1 = 1'b1;
    wait (DUT.can_ready_synched == 1'b1);
    wait(DUT.int_state == ACCEPTMESSAGE);
    #1 $display("[ACCEPT_FSM_11_01] The module shall set o_rx_w_en logic high in FSM state ACCEPTMESSAGE.");
    assert (o_rx_w_en == 1'b1) 
        $display("PASS: o_rx_w_en = %b", o_rx_w_en);
    else
        $error("FAIL: o_rx_w_en = %b", o_rx_w_en);
    i_can_ready = 1'b0;
    i_uaf1 = 1'b0;
    #100;
    
    //ACCEPT_FSM_12_01
    wait(DUT.int_state == IDLE);
    i_can_ready = 1'b1;
    i_uaf1 = 1'b1;
    wait (DUT.can_ready_synched == 1'b1);
    wait(DUT.int_state == ACCEPTMESSAGE);
    #1 $display("[ACCEPT_FSM_12_01] The module shall set o_rx_fifo_w_data[127:0] to i_rx_message[127:0] in FSM state ACCEPTMESSAGE.");
    assert (o_rx_fifo_w_data == i_rx_message) 
        $display("PASS: o_rx_fifo_w_data = %b", o_rx_fifo_w_data);
    else
        $error("FAIL: o_rx_fifo_w_data = %b", o_rx_fifo_w_data);
    i_can_ready = 1'b0;
    i_uaf1 = 1'b0;
    #100;
    
    //ACCEPT_FSM_13_01
    wait(DUT.int_state == IDLE);
    i_can_ready = 1'b1;
    i_uaf1 = 1'b1;
    wait (DUT.can_ready_synched == 1'b1);
    wait(DUT.int_state == ACCEPTMESSAGE);
    #1 $display("[ACCEPT_FSM_13_01] The module shall set FSM state to IDLE in FSM state ACCEPTMESSAGE.");
    assert (DUT.int_state_next == IDLE) 
        $display("PASS: int_state_next = %b", DUT.int_state_next);
    else
        $error("FAIL: int_state_next = %b", DUT.int_state_next);
    i_can_ready = 1'b0;
    i_uaf1 = 1'b0;
    #100;
    
    //ACCEPT_FSM_14_01
    wait(DUT.int_state == IDLE);
    i_can_ready = 1'b1;
    i_uaf1 = 1'b1;
    i_rx_message[127:96] = 32'hFFFFFFFF;
    i_afir1 = 32'hFFFFFF00;
    wait (DUT.can_ready_synched == 1'b1);
    wait(DUT.int_state == DISCARDMESSAGE);
    #1 $display("[ACCEPT_FSM_14_01] The module shall set FSM state to IDLE in FSM state DISCARDMESSAGE.");
    assert (DUT.int_state_next == IDLE) 
        $display("PASS: int_state_next = %b", DUT.int_state_next);
    else
        $error("FAIL: int_state_next = %b", DUT.int_state_next);
    i_can_ready = 1'b0;
    i_uaf1 = 1'b0;
    i_rx_message[127:96] = 32'hFFFFFFFF;
    i_afir1 = 32'hFFFFFFFF;
    #100;
    
    $finish;
end
endmodule