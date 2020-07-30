`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: L&T Technology Services Ltd.
// Engineer: Andrew Newman
// 
// Create Date: 07/19/2020 02:42:22 PM
// Design Name: FIFO Testcases
// Module Name: can_fifo_testcases
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


module can_fifo_testcases;

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
        .o_full         (o_full),
        .o_underflow    (o_underflow),
        .o_overflow     (o_overflow),
        .o_fifo_r_data  (o_fifo_r_data)
    );
    
    initial begin
        i_sys_clk = 1'b0;
        i_reset = 1'b0;
        i_wr_en = 1'b0;
        i_r_en = 1'b0;
        i_fifo_w_data = 128'b0;
    end
    
    initial begin
        $dumpfile ("fifo_testcases.vcd"); 
        $dumpvars;
    end
    
    //initial  begin
    //    $display("\t\ttime,\ti_sys_clk,\ti_reset,\ti_wr_en,\ti_r_en,\to_empty,\to_full,\to_underflow,\to_overflow\t"); 
    //    $monitor("%d,\t%d,\t%d,\t%d,\t%d",$time, i_sys_clk, i_reset, i_wr_en, i_r_en, o_empty, o_full, o_underflow, o_overflow); 
    //end 
    
        
    
    //Clock Generation
    always 
        #1 i_sys_clk = !i_sys_clk;
    
    //Testbench proper
    always begin
        #1;
        //FIFO_INIT_01_1
        $display("[FIFO_INIT_01_1] Module shall set 'FIFO_DEPTH' to default 2 (optionally 2,4,8,16,32,64) upon initialization.");
        assert (DUT.FIFO_DEPTH == 2) 
            $display("PASS: FIFO_DEPTH = %b", DUT.FIFO_DEPTH);
        else
            $error("FAIL: FIFO_DEPTH = %b", DUT.FIFO_DEPTH);
        
        //FIFO_INIT_02_1
        $display("[FIFO_INIT_02_1] Module shall include internal memory buffer 'mem_array' to hold [FIFO_DEPTH-1:0] 128 bit words of FIFO data.");
        assert (DUT.DATA_WIDTH == 128) 
            $display("PASS: FIFO_WIDTH = %b", DUT.DATA_WIDTH);
        else
            $error("FAIL: FIFO_WIDTH = %b", DUT.DATA_WIDTH);
        
        //FIFO_INIT_03_1
        $display("[FIFO_INIT_03_1] Module shall set 'o_underflow' logic low upon system startup.");
        assert (o_underflow == 1'b0) 
            $display("PASS: o_underflow = %b", o_underflow);
        else
            $error("FAIL: o_underflow = %b", o_underflow);
        
        //FIFO_INIT_04_1
        $display("[FIFO_INIT_04_1] Module shall set 'o_fifo_r_data[127:0]' to all zeroes upon system startup.");
        assert (o_fifo_r_data == 128'b0) 
            $display("PASS: o_fifo_r_data = %b", o_fifo_r_data);
        else
            $error("FAIL: o_fifo_r_data = %b", o_fifo_r_data);
        
        //FIFO_INIT_05_1
        $display("[FIFO_INIT_05_1] Module shall set 'o_full' logic low upon system startup.");
        assert (o_full == 1'b0) 
            $display("PASS: o_full = %b", o_full);
        else
            $error("FAIL: o_full = %b", o_full);
        
        //FIFO_INIT_06_1 
        $display("[FIFO_INIT_06_1] Module shall set 'o_empty' logic low upon system startup.");
        assert (o_empty == 1'b0) 
            $display("PASS: o_empty = %b", o_empty);
        else
            $error("FAIL: o_empty = %b", o_empty);
        
        //FIFO_INIT_07_1 
        $display("[FIFO_INIT_07_1] Module shall set 'o_overflow' logic low upon system startup.");
        assert (o_overflow == 1'b0) 
            $display("PASS: o_overflow = %b", o_overflow);
        else
            $error("FAIL: o_overflow = %b", o_overflow);
        
        //FIFO_W_01_1 
        i_fifo_w_data = 128'b1;
        i_wr_en = 1'b1;
        i_r_en = 1'b0;
        i_reset = 1'b0;
        wait(o_full == 1'b1);
        @(posedge i_sys_clk);
        $display("[FIFO_W_01_1] Module shall set 'o_overflow' logic high if 'i_w_en' is logic high while 'o_full' is logic high.");
         @(negedge i_sys_clk) assert (o_overflow == 1'b1) 
            $display("PASS: o_overflow = %b", o_overflow);
        else
            $error("FAIL: o_overflow = %b", o_overflow);
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b0;
        i_r_en = 1'b0;
        i_reset = 1'b1;
        #2 i_reset = 1'b0;
        
        //FIFO_W_02_1
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b1;
        i_r_en = 1'b1;
        i_reset = 1'b0;
        wait(DUT.w_ptr < DUT.FIFO_DEPTH - 1);
        i_fifo_w_data = 128'hFFFFFFFF;
        i_wr_en = 1'b1;
        i_r_en = 1'b0;
        i_reset = 1'b0;
        @(posedge i_sys_clk);
        $display("[FIFO_W_02_1] Module shall write 128 bits of 'i_fifo_w_data' to 'mem_array[w_ptr]' when 'i_w_en' is logic high and 'w_ptr' < FIFO_DEPTH-1.");
        @(negedge i_sys_clk) assert (DUT.mem_array[DUT.w_ptr - 1] == i_fifo_w_data) 
            $display("PASS: mem_array[w_ptr] = %b", DUT.mem_array[DUT.w_ptr - 1]);
        else
            $error("FAIL: mem_array[w_ptr] = %b", DUT.mem_array[DUT.w_ptr - 1]);
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b0;
        i_r_en = 1'b0;
        i_reset = 1'b1;
        #2 i_reset = 1'b0;
        
        
        //FIFO_W_03_1
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b1;
        i_r_en = 1'b1;
        i_reset = 1'b0;
        wait(DUT.r_ptr == 0);
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b1;
        i_r_en = 1'b0;
        i_reset = 1'b0;
        wait(DUT.w_ptr == DUT.FIFO_DEPTH - 1);
        $display("[FIFO_W_03_1] Module shall set 'o_full' logic high when 'w_ptr' is equal to FIFO_DEPTH-1 and 'r_ptr' is 0.");
        @(posedge i_sys_clk) assert (o_full == 1'b1) 
            $display("PASS: o_full = %b", o_full);
        else
            $error("FAIL: o_full = %b", o_full);
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b0;
        i_r_en = 1'b0;
        i_reset = 1'b1;
        #2 i_reset = 1'b0;
        
        
        //FIFO_W_04_1
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b1;
        i_r_en = 1'b1;
        i_reset = 1'b0;
        wait(DUT.r_ptr == 1);
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b1;
        i_r_en = 1'b0;
        i_reset = 1'b0;
        wait(DUT.w_ptr == 0);
        $display("[FIFO_W_04_1] Module shall set 'o_full' logic high when 'w_ptr' + 1 is equal to 'r_ptr'.");
        @(posedge i_sys_clk) assert (o_full == 1'b1) 
            $display("PASS: o_full = %b", o_full);
        else
            $error("FAIL: o_full = %b", o_full);
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b0;
        i_r_en = 1'b0;
        i_reset = 1'b1;
        #2 i_reset = 1'b0;
        
        
        //FIFO_W_05_1
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b1;
        i_r_en = 1'b1;
        i_reset = 1'b0;
        wait(DUT.r_ptr != 1'b0);
        i_fifo_w_data = 128'hFFFFFFFF;
        i_wr_en = 1'b1;
        i_r_en = 1'b0;
        i_reset = 1'b0;
        wait(DUT.w_ptr < DUT.FIFO_DEPTH - 1);
        $display("[FIFO_W_05_1] Module shall set internal variable 'ptr_add' logic high when 'i_w_en' is logic high and 'i_r_en' is logic low only while 'w_ptr' < FIFO_DEPTH-1.");
        @(posedge i_sys_clk) assert (DUT.ptr_add == 1'b1) 
            $display("PASS: ptr_add = %b", DUT.ptr_add);
        else
            $error("FAIL: ptr_add = %b", DUT.ptr_add);
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b0;
        i_r_en = 1'b0;
        i_reset = 1'b1;
        #2 i_reset = 1'b0;
        
        
        //FIFO_R_01_1
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b0;
        i_r_en = 1'b1;
        i_reset = 1'b0;
        wait(o_empty == 1'b1);
        $display("[FIFO_R_01_1] Module shall set 'o_underflow' logic high if 'i_r_en' is logic high while 'o_empty' is logic high.");
        #2 assert (o_underflow == 1'b1) 
            $display("PASS: o_underflow = %b", o_underflow);
        else
            $error("FAIL: o_underflow = %b", o_underflow);
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b0;
        i_r_en = 1'b0;
        i_reset = 1'b1;
        #2 i_reset = 1'b0;
        
        
        //FIFO_R_02_1
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b0;
        i_r_en = 1'b1;
        i_reset = 1'b0;
        wait(DUT.r_ptr < DUT.FIFO_DEPTH - 1);
        i_fifo_w_data = 128'hFFFFFFFF;
        i_wr_en = 1'b1;
        i_r_en = 1'b0;
        i_reset = 1'b0;
        @(posedge i_sys_clk);
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b0;
        i_r_en = 1'b1;
        i_reset = 1'b0;
        wait(DUT.r_ptr < DUT.FIFO_DEPTH - 1);
        $display("[FIFO_R_02_1] Module shall set 128 bits of 'o_fifo_r_data' to value of 'mem_array[r_ptr]' when 'i_r_en' is logic high and' r_ptr' < FIFO_DEPTH-1.");
        @(posedge i_sys_clk) assert (o_fifo_r_data == DUT.mem_array[DUT.r_ptr]) 
            $display("PASS: o_fifo_r_data = %b", o_fifo_r_data);
        else
            $error("FAIL: o_fifo_r_data = %b", o_fifo_r_data);
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b0;
        i_r_en = 1'b0;
        i_reset = 1'b1;
        #2 i_reset = 1'b0;
        
        
        //FIFO_R_03_1
        i_fifo_w_data = 128'hFFFFFFFF;
        i_wr_en = 1'b0;
        i_r_en = 1'b0;
        i_reset = 1'b0;
        DUT.w_ptr = 0;
        DUT.r_ptr = DUT.FIFO_DEPTH - 1;
        #2 $display("[FIFO_R_03_1] Module shall set 'o_empty' logic high when 'r_ptr' is equal to FIFO_DEPTH-1 and 'w_ptr' is 0.");
        @(posedge i_sys_clk) assert (o_empty == 1'b1) 
            $display("PASS: o_empty = %b", o_empty);
        else
            $error("FAIL: o_empty = %b", o_empty);
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b0;
        i_r_en = 1'b0;
        i_reset = 1'b1;
        #2 i_reset = 1'b0;
        
        
        //FIFO_R_04_1
        i_fifo_w_data = 128'hFFFFFFFF;
        i_wr_en = 1'b0;
        i_r_en = 1'b0;
        i_reset = 1'b0;
        DUT.w_ptr = 1;
        DUT.r_ptr = 0;
        #2 $display("[FIFO_R_04_1] Module shall set 'o_empty' logic high when 'r_ptr' +1 is equal to 'w_ptr'.");
        @(posedge i_sys_clk) assert (o_empty == 1'b1) 
            $display("PASS: o_empty = %b", o_empty);
        else
            $error("FAIL: o_empty = %b", o_empty);
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b0;
        i_r_en = 1'b0;
        i_reset = 1'b1;
        #2 i_reset = 1'b0;
        
        
        //FIFO_R_05_1
        i_fifo_w_data = 128'hFFFFFFFF;
        i_wr_en = 1'b1;
        i_r_en = 1'b1;
        i_reset = 1'b0;
        wait(DUT.w_ptr == 0);
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b0;
        i_r_en = 1'b1;
        i_reset = 1'b0;
        wait(DUT.r_ptr < DUT.FIFO_DEPTH - 1);
        #2 $display("[FIFO_R_05_1] Module shall set internal variable 'ptr_sub' logic high when 'i_r_en' is logic high and 'i_w_en' is logic low only while 'r_ptr' < FIFO_DEPTH-1.");
        @(posedge i_sys_clk) assert (DUT.ptr_sub == 1'b1) 
            $display("PASS: ptr_sub = %b", DUT.ptr_sub);
        else
            $error("FAIL: ptr_sub = %b", DUT.ptr_sub);
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b0;
        i_r_en = 1'b0;
        i_reset = 1'b1;
        #2 i_reset = 1'b0;
        @(posedge i_sys_clk);
        
        
        //FIFO_CNT_01_1
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b0;
        i_r_en = 1'b0;
        i_reset = 1'b0;
        DUT.ptr_add = 1'b1;
        $display("[FIFO_CNT_01_1] Module shall increment internal variable 'ptr_reg' when 'ptr_add' is logic high.");
        #1 assert (DUT.ptr_next == 3'b001) 
            $display("PASS: ptr_reg = %b", DUT.ptr_next);
        else
            $error("FAIL: ptr_reg = %b", DUT.ptr_next);
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b0;
        i_r_en = 1'b0;
        DUT.ptr_add = 1'b0;
        i_reset = 1'b1;
        #2 i_reset = 1'b0;
        @(posedge i_sys_clk);
        
        
        //FIFO_CNT_02_1
        i_fifo_w_data = 128'hFFFFFFFF;
        i_wr_en = 1'b0;
        i_r_en = 1'b0;
        i_reset = 1'b0;
        DUT.ptr_sub = 1'b1;
        $display("[FIFO_CNT_02_1] Module shall decrement internal variable 'ptr_reg' when 'ptr_sub' is logic high.");
        #1 assert (DUT.ptr_next == 3'b111) 
            $display("PASS: ptr_reg = %b", DUT.ptr_next);
        else
            $error("FAIL: ptr_reg = %b", DUT.ptr_next);
        i_fifo_w_data = 128'b0;
        i_wr_en = 1'b0;
        i_r_en = 1'b0;
        DUT.ptr_sub = 1'b0;
        i_reset = 1'b1;
        #2 i_reset = 1'b0;
        
        
        //FIFO_RST_01_1
        i_reset = 1'b1;
        @(posedge i_sys_clk);
        $display("[FIFO_RST_01_1] Module shall set 'o_underflow' logic low upon system reset.");
        assert (o_underflow == 1'b0) 
            $display("PASS: o_underflow = %b", o_underflow);
        else
            $error("FAIL: o_underflow = %b", o_underflow);
        i_reset = 1'b0;
        
        //FIFO_RST_02_1
        i_reset = 1'b1;
        @(posedge i_sys_clk);
        $display("[FIFO_RST_02_1] Module shall set 'o_fifo_r_data[127:0]' to all zeroes upon system reset.");
        assert (o_fifo_r_data == 128'b0) 
            $display("PASS: o_fifo_r_data = %b", o_fifo_r_data);
        else
            $error("FAIL: o_fifo_r_data = %b", o_fifo_r_data);
        i_reset = 1'b0;
        
        //FIFO_RST_03_1
        i_reset = 1'b1;
        @(posedge i_sys_clk);
        $display("[FIFO_RST_03_1] Module shall set 'o_full' logic low upon system reset.");
        assert (o_full == 1'b0) 
            $display("PASS: o_full = %b", o_full);
        else
            $error("FAIL: o_full = %b", o_full);
        i_reset = 1'b0;
        
        //FIFO_RST_04_1
        i_reset = 1'b1;
        @(posedge i_sys_clk);
        $display("[FIFO_RST_04_1] Module shall set 'o_empty' logic low upon system reset.");
        assert (o_empty == 1'b0) 
            $display("PASS: o_empty = %b", o_empty);
        else
            $error("FAIL: o_empty = %b", o_empty);
        i_reset = 1'b0;
        
        //FIFO_RST_05_1
        i_reset = 1'b1;
        @(posedge i_sys_clk);
        $display("[FIFO_RST_05_1] Module shall set 'o_overflow' logic low upon system reset.");
        assert (o_overflow == 1'b0) 
            $display("PASS: o_overflow = %b", o_overflow);
        else
            $error("FAIL: o_overflow = %b", o_overflow);
        i_reset = 1'b0;
        
        //FIFO_RST_06_1
        i_reset = 1'b1;
        @(posedge i_sys_clk);
        $display("[FIFO_RST_06_1] Module shall set 'w_ptr[FIFO_DEPTH-1:0]' to all zeroes upon system reset.");
        assert (DUT.w_ptr == 0) 
            $display("PASS: w_ptr = %b", DUT.w_ptr);
        else
            $error("FAIL: w_ptr = %b", DUT.w_ptr);
        i_reset = 1'b0;
        
        //FIFO_RST_06_2
        i_reset = 1'b1;
        @(posedge i_sys_clk);
        $display("[FIFO_RST_06_2] Module shall set 'r_ptr[FIFO_DEPTH-1:0]' to all zeroes upon system reset.");
        assert (DUT.r_ptr == 0) 
            $display("PASS: r_ptr = %b", DUT.r_ptr);
        else
            $error("FAIL: r_ptr = %b", DUT.r_ptr);
        i_reset = 1'b0;
        
        $finish;
    end
endmodule
