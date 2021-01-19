`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/08 13:04:23
// Design Name: 
// Module Name: sim
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


module sim(

    );
reg [3:0] usr_btn ;
wire [3:0] usr_led, LCD_D;
wire LCD_RS, LCD_RW, LCD_E;
reg clk = 1, reset_n = 1;

    
lab9 lab9(clk,reset_n, usr_btn, usr_led,LCD_RS, LCD_RW, LCD_E, LCD_D);

always 
  #5 clk <= ~clk;
  
  
initial begin
	#10
		usr_btn = 4'b1111;

end  
  
  
endmodule
