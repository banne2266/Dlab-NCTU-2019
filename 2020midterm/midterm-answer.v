`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NCTU-CS
// Engineer: Jeng-Huo, Tzeng
// 
// Create Date: 2020/11/05 19:21:33
// Design Name: 2020 Dlab-midterm-answer
// Module Name: midterm-answer
// Project Name:  2020 Dlab-midterm-answer
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


module midterm(
  input clk,
  input reset_n,
  input [3:0] usr_btn,
  output [3:0] usr_led,
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);
localparam [3:0]  S_MAIN_IDLE = 0, S_MAIN_ASKSTR1 = 1, S_MAIN_INPUT1 = 2, 
                S_MAIN_ASKSTR2 = 3, S_MAIN_INPUT2 = 4, S_MAIN_DISPLAY_LEN = 5, 
                S_MAIN_DISPLAY_LCS = 6;

localparam [2:0]    S_CAL_IDLE = 0, S_CAL_CALCULATE_1 = 1, S_CAL_CALCULATE_2 = 2, 
                    S_CAL_IDLE_2 = 3, S_CAL_DONE = 4;
reg [3:0] P, P_next;//state for the FSM
reg [2:0] Q, Q_next;//state for the FSM

reg [127:0] row_A = "welcomeTA's demo"; // Initialize the text of the first row.
reg [127:0] row_B = "Press btn3 start"; // Initialize the text of the second row.
reg [0:615] cir_string = "lmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
reg [0:127] input_A = "                ", input_B = "                ", lcs = "                ";
reg [15:0]  index_rowA;
reg [5:0]   index_input, len_A, len_B;
reg [5:0]  index_m, index_n;
wire [7:0] length;
reg [5:0]  index_m2, index_n2, length_temp;
reg [7:0] len [16:0][16:0];
reg [7:0] lcs_path [16:0][16:0];


integer i;
reg[3:0] reg_btn;
wire[3:0] btn, btn_pressed;

assign usr_led = Q;
assign length = (len[len_A][len_B] >= 8'd10) ? len[len_A][len_B] - 8'd10 + "a" : len[len_A][len_B] + "0";

always@(posedge clk) begin//state machine logic
    if(~reset_n)
        P <= S_MAIN_IDLE;
    else 
        P <= P_next;
end

always@(*) begin//next state logic
    case(P)
        S_MAIN_IDLE:
            if(btn_pressed[3])  P_next = S_MAIN_ASKSTR1;
            else     P_next = S_MAIN_IDLE;
        S_MAIN_ASKSTR1:
            if(btn_pressed[3])  P_next = S_MAIN_INPUT1;
            else     P_next = S_MAIN_ASKSTR1;
        S_MAIN_INPUT1:   
            if(btn_pressed[3])  P_next = S_MAIN_ASKSTR2;
            else     P_next = S_MAIN_INPUT1;
        S_MAIN_ASKSTR2:
            if(btn_pressed[3])  P_next = S_MAIN_INPUT2;
            else     P_next = S_MAIN_ASKSTR2;
        S_MAIN_INPUT2:
            if(btn_pressed[3])  P_next = S_MAIN_DISPLAY_LEN;
            else     P_next = S_MAIN_INPUT2;
        S_MAIN_DISPLAY_LEN:
            if(btn_pressed[3])  P_next = S_MAIN_DISPLAY_LCS;
            else     P_next = S_MAIN_DISPLAY_LEN;
        S_MAIN_DISPLAY_LCS:
            if(btn_pressed[3])  P_next = S_MAIN_ASKSTR1;
            else     P_next = S_MAIN_DISPLAY_LCS;
        default: P_next = S_MAIN_IDLE;
        endcase
end

always @(posedge clk) begin  //LCD screen logic
    case(P)
        S_MAIN_IDLE:begin
            row_A <= "welcomeTA's demo";
            row_B <= "Press btn3 start";
        end
        S_MAIN_ASKSTR1:begin
            row_A <= "Press btn3 to   ";
            row_B <= "enter string #1 ";
        end
        S_MAIN_INPUT1:begin
            row_A <= cir_string[index_rowA*8 +: 16*8];
            row_B[127:64] <= (index_input < 8) ? input_A[0:63] : input_A[index_input * 8 - 1 -: 64];
            row_B[63:0] <= "       ^";
        end
        S_MAIN_ASKSTR2:begin
            row_A <= "Press btn3 to   ";
            row_B <= "enter string #2 ";
        end
        S_MAIN_INPUT2:begin
            row_A <= cir_string[index_rowA*8 +: 16*8];
            row_B[127:64] <= (index_input < 8) ? input_B[0:63] : input_B[index_input * 8 - 1  -: 64];
            row_B[63:0] <= "       ^";
        end
        S_MAIN_DISPLAY_LEN:begin
            row_A <= "The length of   ";
            row_B <= {"LCS = 0x", length, "       "};
        end
        S_MAIN_DISPLAY_LCS:begin
            row_A <= "The LCS is:     ";
            row_B <= lcs;
        end
    endcase
end

always @(posedge clk) begin  //index logic
    if(P == S_MAIN_INPUT1 || P ==S_MAIN_INPUT2) begin
        if(btn_pressed[0])
            index_rowA <= (index_rowA > 0) ? index_rowA - 1 : 61;
        else if(btn_pressed[2])
            index_rowA <= (index_rowA < 61) ? index_rowA + 1 : 0;
        else
            index_rowA <= index_rowA;  
        if(btn_pressed[1])
            index_input <= (index_input < 16) ? index_input + 1 : 16;//index_input + 1;
        else
            index_input <= index_input;
    end
    else begin
        index_rowA <= 0;
        index_input <= 0;
    end
end

always @(posedge clk) begin  //length of A B
    if(P == S_MAIN_ASKSTR1)begin
        len_A <= 0;
        len_B <= 0;
    end
    else if(P == S_MAIN_INPUT1) begin
        len_A <= index_input;
    end
    else if(P ==S_MAIN_INPUT2) begin
        len_B <= index_input;
    end
    else begin
        len_A <= len_A;
        len_B <= len_B;
    end
end

always @(posedge clk) begin  //fetch input from user
    if(P == S_MAIN_ASKSTR1) begin
        input_A <= "                ";
        input_B <= "                ";
    end
    else if(P == S_MAIN_INPUT1) begin
        if(btn_pressed[1])
            input_A[index_input * 8 +: 8] <= row_A[7:0];
    end
    else if(P == S_MAIN_INPUT2) begin
        if(btn_pressed[1])
            input_B[index_input * 8 +: 8] <= row_A[7:0];
    end
end

always@(posedge clk) begin//state machine of LCS calculation
    if(~reset_n)
        Q <= S_CAL_IDLE;
    else 
        Q <= Q_next;
end

always@(*) begin
    case(Q)
        S_CAL_IDLE:
            if(P == S_MAIN_INPUT2 && P_next == S_MAIN_DISPLAY_LEN)  Q_next = S_CAL_CALCULATE_1;
            else     Q_next = S_CAL_IDLE;
        S_CAL_CALCULATE_1:
            if(index_m == len_A && index_n == len_B)  Q_next = S_CAL_IDLE_2;
            else     Q_next = S_CAL_CALCULATE_1;
        S_CAL_IDLE_2:
            if(P == S_MAIN_DISPLAY_LEN && P_next == S_MAIN_DISPLAY_LCS)  Q_next = S_CAL_CALCULATE_2;
            else    Q_next = S_CAL_IDLE_2;
        S_CAL_CALCULATE_2:
            if(length_temp == 0)  Q_next = S_CAL_DONE;
            else     Q_next = S_CAL_CALCULATE_2;
        S_CAL_DONE:   
             Q_next = S_CAL_IDLE;
        default: Q_next = S_CAL_IDLE;
    endcase
end

always@(posedge clk) begin // make DP matrix by using bottom up method
    if(Q == S_CAL_CALCULATE_1)begin
        if(index_m == 0 || index_n == 0)
            len[index_m][index_n] <= 0;
        else if(input_A[ (index_m - 1) * 8 +: 8 ] == input_B[ (index_n - 1) * 8 +: 8 ])begin
            len[index_m][index_n] <= len[index_m - 1][index_n - 1] + 1;
            lcs_path[index_m][index_n] <= 0;
        end
        else if(len[index_m - 1][index_n] < len[index_m][index_n - 1]) begin
            len[index_m][index_n] <= len[index_m][index_n - 1];
            lcs_path[index_m][index_n] <= 1;
        end
        else begin
            len[index_m][index_n] <= len[index_m - 1][index_n];
            lcs_path[index_m][index_n] <= 2;
        end
    end
end

always@(posedge clk) begin//the index logic
    if(Q == S_CAL_IDLE)begin
        index_m <= 0;
        index_n <= 0;
    end
    else if(Q == S_CAL_CALCULATE_1)begin
        if(index_n == len_B)
            index_n <= 0;
        else
            index_n <= index_n + 1;
        if(index_n == len_B)
            index_m <= index_m + 1;
        else
            index_m <= index_m;
    end
end

always@(posedge clk) begin//reconstruct the LCS
    if(Q == S_CAL_IDLE_2)begin
        index_m2 <= len_A;
        index_n2 <= len_B;
        length_temp <= len[len_A][len_B];
        lcs <= "                ";
    end
    else if(Q == S_CAL_CALCULATE_2)begin
        if(lcs_path[index_m2][index_n2] == 0) begin
            length_temp <= length_temp - 1;
            index_m2 <= index_m2 - 1;
            index_n2 <= index_n2 - 1;
            lcs[ (length_temp - 1) * 8 +: 8 ] <= input_A[(index_m2 - 1) * 8 +: 8];
        end
        else if(lcs_path[index_m2][index_n2] == 1)begin
            index_m2 <= index_m2;
            index_n2 <= index_n2 - 1;
            length_temp <= length_temp;
        end
        else begin
            index_m2 <= index_m2 - 1;
            index_n2 <= index_n2;
            length_temp <= length_temp;
        end
    end
end


debounce btn_db0(.clk(clk),.btn_input(usr_btn[0]),.btn_output(btn[0]));
debounce btn_db1(.clk(clk),.btn_input(usr_btn[1]),.btn_output(btn[1]));
debounce btn_db2(.clk(clk),.btn_input(usr_btn[2]),.btn_output(btn[2]));
debounce btn_db3(.clk(clk),.btn_input(usr_btn[3]),.btn_output(btn[3]));
always @(posedge clk) begin
    for(i = 0; i < 4; i = i + 1)begin
    if (~reset_n)
        reg_btn[i] <= 1;
    else
        reg_btn[i] <= btn[i];
    end
end
assign btn_pressed[0] = (btn[0] == 1 && reg_btn[0] == 0);
assign btn_pressed[1] = (btn[1] == 1 && reg_btn[1] == 0);
assign btn_pressed[2] = (btn[2] == 1 && reg_btn[2] == 0);
assign btn_pressed[3] = (btn[3] == 1 && reg_btn[3] == 0);

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

endmodule


module debounce(
input clk,
input btn_input,
output reg btn_output
);
reg [31:0] timer = 0;
reg pre;
always@(posedge clk)begin
    if(timer < 1000000)
        timer = timer + 1;
    else begin
        if(pre == btn_input)
            btn_output = btn_input;
        pre = btn_input;
        timer = 0;
    end
end
endmodule
