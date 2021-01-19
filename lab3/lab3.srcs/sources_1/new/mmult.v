`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/04 16:41:38
// Design Name: 
// Module Name: mmult
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


module mmult(
input clk,                  // Clock signal.
input reset_n,              // Reset signal (negative logic).
input enable,               // Activation signal for matrix
                            //    multiplication (tells the circuit
                            //    that A and B are ready for use).
input [0:9*8-1] A_mat,      // A matrix.
input [0:9*8-1] B_mat,      // B matrix.
output reg valid,               // Signals that the output is valid
                            //       to read.
output reg [0:9*17-1] C_mat // The result of A x B.
);
integer i, j;
reg[0:1] index;

always@(posedge clk) begin
    if(reset_n == 0 | enable == 0) begin
        C_mat <= 0;
		index <= 0;
	end
    else if(enable == 1 & index < 3) begin
        for(i = 0; i < 3; i = i+1)
            for(j = 0; j < 3; j = j + 1)
                C_mat[(i*3+j)*17 +: 17] <= C_mat[(i*3+j)*17 +: 17] + A_mat[(i*3+index)*8 +: 8] * B_mat[(index*3+j)*8 +: 8];
        index <= index + 1;
        end
    if(index >= 3)
        valid <= 1;
    else 
        valid <= 0;
end
endmodule
