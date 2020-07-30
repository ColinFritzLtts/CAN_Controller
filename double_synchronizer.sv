`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/28/2020 10:31:30 AM
// Design Name: 
// Module Name: double_synchronizer
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


module double_synchronizer(un_synched, i_sys_clk, i_reset, synched);

input un_synched;
input i_sys_clk;
input i_reset;
output synched;
reg synched;
reg intermediate;

always @(posedge i_sys_clk)
begin
if (i_reset ==1) begin 
intermediate<=0;
synched<=0;
end
else if (i_reset == 0) begin 
    intermediate<=un_synched;
    synched<=intermediate;
    end
end
endmodule
