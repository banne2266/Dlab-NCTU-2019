`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/08 14:43:21
// Design Name: 
// Module Name: BCD_counter
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


module BCD_counter(
  input clk,
  input rst,
  input increase,
  output [63:0]result
);

genvar i;
wire Ci[7:0];
wire Co[7:0];
wire [7:0]sum[7:0];
assign Ci[0] = increase;
assign Ci[1] = Co[0];
assign Ci[2] = Co[1];
assign Ci[3] = Co[2];
assign Ci[4] = Co[3];
assign Ci[5] = Co[4];
assign Ci[6] = Co[5];
assign Ci[7] = Co[6];

assign result = {sum[7],sum[6],sum[5],sum[4],sum[3],sum[2],sum[1],sum[0]};


generate
  for(i=0;i<8;i=i+1)begin
    BCD 
    B(
      .clk(clk),
      .rst(rst),
	  .Cin(Ci[i]),
	  .sum(sum[i]),
	  .Cout(Co[i])  
    );
  end
endgenerate  
endmodule


module BCD(
  input clk,
  input rst,
  input Cin,
  output reg[7:0]sum,
  output Cout
    );
	
always@(posedge clk)begin
  if(rst)
    sum <= "0";
  else if(Cin)
    sum <= (sum == "9") ? "0" : sum+1;   
end

assign Cout = (sum == "9" & Cin);

endmodule
