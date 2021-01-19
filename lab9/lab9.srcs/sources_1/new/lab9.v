`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/06 13:38:05
// Design Name: 
// Module Name: lab9
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


module lab9(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
  );

localparam [2:0] S_MAIN_IDLE = 3'b001, S_MAIN_CRACK = 3'b010,
			   S_MAIN_REST = 3'b011 ,S_MAIN_DISP = 3'b100,
			   S_MAIN_PREPARE = 3'b101;
localparam PARALLEL_NUM = 10;
// Declare system variables
wire btn_level, btn_pressed;
reg  prev_btn_level;
reg [2:0] P, P_next;
wire [63:0] number;
reg [0:127] passwd_hash = 128'hef775988943825d2871e1cfa75473ec0;
reg [127:0] row_A = "Press button3 to";
reg [127:0] row_B = "start the crack!";
reg [63:0] ans;
wire [63:0] timer;
wire num_increase, timer_increase;
reg [31:0] timer_bcd;
reg [19:0] sub_timer;

reg [PARALLEL_NUM-1:0] load_i;
wire [PARALLEL_NUM-1:0] out_en;
wire [127:0] out_hash[PARALLEL_NUM-1:0];
wire [63:0] in_data[PARALLEL_NUM-1:0];


integer i, j;
LCD_module lcd0( 
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);
BCD_counter timeBCD_counter(
	.clk(clk),
	.rst(~reset_n),
	.increase(timer_increase),
	.result(timer)
);
BCD_counter numberBCD_counter(
	.clk(clk),
	.rst(~reset_n),
	.increase(num_increase),
	.result(number[63:8])
);
debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level)
);

md5 crack_core00(.clk(clk),.reset_n(reset_n),.load_i(load_i[0]),.ready_o(out_en[0]),.data_i(in_data[0]),.data_o(out_hash[0]));
md5 crack_core01(.clk(clk),.reset_n(reset_n),.load_i(load_i[1]),.ready_o(out_en[1]),.data_i(in_data[1]),.data_o(out_hash[1]));
md5 crack_core02(.clk(clk),.reset_n(reset_n),.load_i(load_i[2]),.ready_o(out_en[2]),.data_i(in_data[2]),.data_o(out_hash[2]));
md5 crack_core03(.clk(clk),.reset_n(reset_n),.load_i(load_i[3]),.ready_o(out_en[3]),.data_i(in_data[3]),.data_o(out_hash[3]));
md5 crack_core04(.clk(clk),.reset_n(reset_n),.load_i(load_i[4]),.ready_o(out_en[4]),.data_i(in_data[4]),.data_o(out_hash[4]));
md5 crack_core05(.clk(clk),.reset_n(reset_n),.load_i(load_i[5]),.ready_o(out_en[5]),.data_i(in_data[5]),.data_o(out_hash[5]));
md5 crack_core06(.clk(clk),.reset_n(reset_n),.load_i(load_i[6]),.ready_o(out_en[6]),.data_i(in_data[6]),.data_o(out_hash[6]));
md5 crack_core07(.clk(clk),.reset_n(reset_n),.load_i(load_i[7]),.ready_o(out_en[7]),.data_i(in_data[7]),.data_o(out_hash[7]));
md5 crack_core08(.clk(clk),.reset_n(reset_n),.load_i(load_i[8]),.ready_o(out_en[8]),.data_i(in_data[8]),.data_o(out_hash[8]));
md5 crack_core09(.clk(clk),.reset_n(reset_n),.load_i(load_i[9]),.ready_o(out_en[9]),.data_i(in_data[9]),.data_o(out_hash[9]));

assign in_data[0] =  {number[63: 8], "0"};
assign in_data[1] =  {number[63: 8], "1"};
assign in_data[2] =  {number[63: 8], "2"};
assign in_data[3] =  {number[63: 8], "3"};
assign in_data[4] =  {number[63: 8], "4"};
assign in_data[5] =  {number[63: 8], "5"};
assign in_data[6] =  {number[63: 8], "6"};
assign in_data[7] =  {number[63: 8], "7"};
assign in_data[8] =  {number[63: 8], "8"};
assign in_data[9] =  {number[63: 8], "9"};


assign num_increase = (P == S_MAIN_PREPARE);
assign timer_increase = (sub_timer == 100 && P ==S_MAIN_CRACK);
//
// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;
assign usr_led = {out_en,P};

// ------------------------------------------------------------------------
// FSM 
always @(posedge clk) begin
  if (~reset_n)
    P <= S_MAIN_IDLE;
  else
    P <= P_next;
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_IDLE:
      if (btn_pressed == 1) P_next = S_MAIN_PREPARE;
      else P_next = S_MAIN_IDLE;
    S_MAIN_CRACK:
		 if(out_en)
		 	P_next = S_MAIN_PREPARE;
		 else
		 	P_next = S_MAIN_CRACK;
	S_MAIN_PREPARE:
		if(ans != 0)
			P_next = S_MAIN_REST;
		else
			P_next = S_MAIN_CRACK;
	S_MAIN_REST:
		 P_next = S_MAIN_DISP;
    S_MAIN_DISP:
    	 P_next = S_MAIN_DISP;
    default:
      P_next = S_MAIN_IDLE;
  endcase
end
// End of FSM
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Timer logic
always @(posedge clk) begin
	sub_timer <= (sub_timer >= 100000) ? 0 : sub_timer + 1;
end

// End of Timer logic
// ------------------------------------------------------------------------


always @(posedge clk) begin
	if (~reset_n)
		ans <= 0;
	else begin
		if(P == S_MAIN_IDLE)
			ans <= 0;
		else if(P == S_MAIN_CRACK && out_en)begin
			for(i=0;i<PARALLEL_NUM;i=i+1)
				if(out_hash[i] == passwd_hash)
					ans = in_data[i];
		end
	end
end


always @(posedge clk) begin
  if (~reset_n)
    load_i <= 0;
  else begin
  	if(P == S_MAIN_PREPARE)
  		load_i <= 10'b11111_11111;
  	else
  		load_i <= 0;
  end  
end

// ------------------------------------------------------------------------
// LCD Display function.
always @(posedge clk) begin
  	if (~reset_n)begin
  		row_A <= "Press button3 to";
		row_B <= "start the crack!";
	end
  	else begin
  		if(P == S_MAIN_CRACK) begin
  			row_A <= "Pwd cracking... ";
			row_B <= "Fuck you Dlab...";
  		end
  		else if(P == S_MAIN_DISP) begin
  			row_A <= {"Passwd: ", ans};
			row_B <= {"Time: ", timer, "ms"};
		end
  	end
end
// End of the LCD display function
// ------------------------------------------------------------------------

endmodule
// ------------------------------------------------------------------------
/*
	To do list:
		1:binary to bcd converter. 	V
		2:the md5 algorithm.		V
		3:parallel cracking.		V
*/
// ------------------------------------------------------------------------
