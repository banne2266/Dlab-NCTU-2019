`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/07 11:04:52
// Design Name: 
// Module Name: md5
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


module md5(

	input clk,
	input reset_n,
	input load_i,		///the signal to start the circuit
	output reg ready_o,	///the signal to indicate that the calculation is done.

	input [63:0] data_i,  ///input is an 8 bytes number
	output reg [127:0] data_o ///output the md5 hash(128bits)
);	
localparam [1:0] S_MAIN_IDLE = 0, S_MAIN_PREPROCESS = 1,
			   S_MAIN_CALCULATE = 2 ,S_MAIN_DONE = 3;
reg pre;
reg [31:0] w[15:0];
reg [1:0] state, next_state;
reg [6:0] round;
reg [31:0] t,r,h0,h1,h2,h3,a,b,c,d,f;
reg [3:0] g;
integer i,j;

// ------------------------------------------------------------------------
// FSM 
always @(posedge clk) begin
  if (~reset_n) begin
    state <= S_MAIN_IDLE;
  end
  else begin
    state <= next_state;
  end
end

always @(*) begin // FSM next-state logic
  case (state)
    S_MAIN_IDLE:
      	if (load_i) next_state = S_MAIN_PREPROCESS;
      	else next_state = S_MAIN_IDLE;
    S_MAIN_PREPROCESS:
		 next_state = S_MAIN_CALCULATE;
	S_MAIN_CALCULATE:
		if(round >= 64) next_state = S_MAIN_DONE;
		else next_state = S_MAIN_CALCULATE;
    S_MAIN_DONE:
    	next_state = S_MAIN_IDLE;
    default:
      	next_state = S_MAIN_IDLE;
  endcase
end
// End of FSM
// ------------------------------------------------------------------------

always @(posedge clk) begin
	if(state == S_MAIN_DONE)
		ready_o <= 1;
	else
		ready_o <= 0;
end

always @(posedge clk) begin
	if(!reset_n)
		pre <= 0;
	else if(state == S_MAIN_IDLE)
		pre <= 0;
	else if(state == S_MAIN_CALCULATE && pre == 0)
		pre <= 1;
	else if(state == S_MAIN_CALCULATE && pre == 1)
		pre <= 0;
	else
		pre <= pre;
end

always @(posedge clk) begin
	if(!reset_n)
		round <= 0;
	else if(state == S_MAIN_IDLE)
		round <= 0;
	else if(state == S_MAIN_CALCULATE && pre == 1)
		round <= round + 1;
	else
		round <= round;
end

// ------------------------------------------------------------------------
// MD5 algorithm

/// break chunk into sixteen 32-bit words w[j](little endian mode), 0 ? j ? 15
always @(posedge clk) begin
	if (~reset_n)begin
		for(i=0;i<16;i=i+1)
			w[i] <= 0;
	end
	else begin
		if(state == S_MAIN_IDLE)
			for(i=0;i<16;i=i+1)
					w[i] <= 0;
		else if(state == S_MAIN_PREPROCESS)begin
			w[0] <= {data_i[39-:8],data_i[47-:8],data_i[55-:8],data_i[63-:8]};
			w[1] <= {data_i[7-:8],data_i[15-:8],data_i[23-:8],data_i[31-:8]};
			w[2] <= 128;
			w[14] <= 64;
		end
	end
end

always @(posedge clk) begin
	if (~reset_n)begin
		a <= 0;
		b <= 0;
		c <= 0;
		d <= 0;
	end
	else begin
		if(state == S_MAIN_IDLE) begin
			a <= 0;
			b <= 0;
			c <= 0;
			d <= 0;
		end
		else if(state == S_MAIN_PREPROCESS)begin
			a <= h0;
			b <= h1;
			c <= h2;
			d <= h3;
		end
		else if(state == S_MAIN_CALCULATE && pre == 0 && round < 64)begin
			if(round < 16) begin
				f <= ((b & c) | ((~b) & d))+(a+t);
				g <= round;
			end
			else if(round < 32) begin
				f <= ((d & b) | ((~d) & c))+(a+t);
                g <= 5 * round + 1;
			end
			else if(round < 48) begin
				f <= (b ^ c ^ d)+(a+t);
                g <= 3 * round + 5;
			end
			else if(round < 64)begin
				f <= (c ^ (b | (~d)))+(a+t);
                g <= 7 * round;
			end
		end
		else if(state == S_MAIN_CALCULATE && pre == 1 && round < 64)begin
			d <= c;
			c <= b;
			b <= b + ((( f+w[g]) << r ) | (( f+w[g]) >> (32-r)));
			a <= d;
		end
	end
end


always @(posedge clk) begin
	if (~reset_n)begin
		h0 <= 32'h67452301;
		h1 <= 32'hefcdab89;
		h2 <= 32'h98badcfe;
		h3 <= 32'h10325476;
	end
	else begin
		if(state == S_MAIN_IDLE) begin
			h0 <= 32'h67452301;
			h1 <= 32'hefcdab89;
			h2 <= 32'h98badcfe;
			h3 <= 32'h10325476;
		end
		if(round == 64) begin
			h0 <= h0 + a;
			h1 <= h1 + b;
			h2 <= h2 + c;
			h3 <= h3 + d;
		end
	end
end

always @(posedge clk) begin
	if (~reset_n)begin
		data_o <= 0;
	end
	else begin
		if(state == S_MAIN_IDLE)
			data_o <= 0;
		else if(state == S_MAIN_DONE) begin
			data_o[127-:8] <= h0[7-:8];
			data_o[119-:8] <= h0[15-:8];
			data_o[111-:8] <= h0[23-:8];
			data_o[103-:8] <= h0[31-:8];
			data_o[ 95-:8] <= h1[7-:8];
			data_o[ 87-:8] <= h1[15-:8];
			data_o[ 79-:8] <= h1[23-:8];
			data_o[ 71-:8] <= h1[31-:8];
			data_o[ 63-:8] <= h2[7-:8];
			data_o[ 55-:8] <= h2[15-:8];
			data_o[ 47-:8] <= h2[23-:8];
			data_o[ 39-:8] <= h2[31-:8];
			data_o[ 31-:8] <= h3[7-:8];
			data_o[ 23-:8] <= h3[15-:8];
			data_o[ 15-:8] <= h3[23-:8];
			data_o[  7-:8] <= h3[31-:8];
		end
	end
end


//rom process
always @(round)
begin
   case(round)
         0: begin t = 32'hD76AA478; r = 7; end
         1: begin t = 32'hE8C7B756; r = 12; end
         2: begin t = 32'h242070DB; r = 17; end
         3: begin t = 32'hC1BDCEEE; r = 22; end
         4: begin t = 32'hF57C0FAF; r = 7; end
         5: begin t = 32'h4787C62A; r = 12; end
         6: begin t = 32'hA8304613; r = 17; end
         7: begin t = 32'hFD469501; r = 22; end
         8: begin t = 32'h698098D8; r = 7; end
         9: begin t = 32'h8B44F7AF; r = 12; end
         10: begin t = 32'hFFFF5BB1; r = 17; end
         11: begin t = 32'h895CD7BE; r = 22; end
         12: begin t = 32'h6B901122; r = 7; end
         13: begin t = 32'hFD987193; r = 12; end
         14: begin t = 32'hA679438E; r = 17; end
         15: begin t = 32'h49B40821; r = 22; end
	   
         16: begin t = 32'hf61e2562; r = 5; end
         17: begin t = 32'hc040b340; r = 9; end
         18: begin t = 32'h265e5a51; r = 14; end
         19: begin t = 32'he9b6c7aa; r = 20; end
         20: begin t = 32'hd62f105d; r = 5; end
         21: begin t = 32'h02441453; r = 9; end
         22: begin t = 32'hd8a1e681; r = 14; end
         23: begin t = 32'he7d3fbc8; r = 20; end
         24: begin t = 32'h21e1cde6; r = 5; end
         25: begin t = 32'hc33707d6; r = 9; end
         26: begin t = 32'hf4d50d87; r = 14; end
         27: begin t = 32'h455a14ed; r = 20; end
         28: begin t = 32'ha9e3e905; r = 5; end
         29: begin t = 32'hfcefa3f8; r = 9; end
         30: begin t = 32'h676f02d9; r = 14; end
         31: begin t = 32'h8d2a4c8a; r = 20; end
		   
         32: begin t = 32'hfffa3942; r = 4; end
         33: begin t = 32'h8771f681; r = 11; end
         34: begin t = 32'h6d9d6122; r = 16; end
         35: begin t = 32'hfde5380c; r = 23; end
         36: begin t = 32'ha4beea44; r = 4; end
         37: begin t = 32'h4bdecfa9; r = 11; end
         38: begin t = 32'hf6bb4b60; r = 16; end
         39: begin t = 32'hbebfbc70; r = 23; end
         40: begin t = 32'h289b7ec6; r = 4; end
         41: begin t = 32'heaa127fa; r = 11; end
         42: begin t = 32'hd4ef3085; r = 16; end
         43: begin t = 32'h04881d05; r = 23; end
         44: begin t = 32'hd9d4d039; r = 4; end
         45: begin t = 32'he6db99e5; r = 11; end
         46: begin t = 32'h1fa27cf8; r = 16; end
         47: begin t = 32'hc4ac5665; r = 23; end
		   
         48: begin t = 32'hf4292244; r = 6; end
         49: begin t = 32'h432aff97; r = 10; end
         50: begin t = 32'hab9423a7; r = 15; end
         51: begin t = 32'hfc93a039; r = 21; end
         52: begin t = 32'h655b59c3; r = 6; end
         53: begin t = 32'h8f0ccc92; r = 10; end
         54: begin t = 32'hffeff47d; r = 15; end
         55: begin t = 32'h85845dd1; r = 21; end
         56: begin t = 32'h6fa87e4f; r = 6; end
         57: begin t = 32'hfe2ce6e0; r = 10; end
         58: begin t = 32'ha3014314; r = 15; end
         59: begin t = 32'h4e0811a1; r = 21; end
         60: begin t = 32'hf7537e82; r = 6; end
         61: begin t = 32'hbd3af235; r = 10; end
         62: begin t = 32'h2ad7d2bb; r = 15; end
         63: begin t = 32'heb86d391; r = 21; end
         
         default: begin t = 0; r = 0; end
    endcase
end
//end process rom

// End of MD5 algorithm
// ------------------------------------------------------------------------
	

endmodule
