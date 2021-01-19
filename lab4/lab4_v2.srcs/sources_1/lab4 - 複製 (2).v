`timescale 1ns / 1ps
module lab4(
  input  clk,            // System clock at 100 MHz
  input  reset_n,        // System reset signal, in negative logic
  input  [3:0] usr_btn,  // Four user pushbuttons
  output reg [3:0] usr_led   // Four yellow LEDs
);
wire[3:0] btn, btn_pressed;
reg[3:0] reg_btn;
reg signed[3:0] counter = 0;
reg[19:0] pwm = 0;
reg[31:0] clk_cnt [3:0];
reg[3:0] light = 0;
integer i;
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

always@(posedge clk)begin
    if(!reset_n)
        counter = 0;
    else begin
        if(btn_pressed[1] == 1 && counter < 7)
            counter <= counter + 1;
        else if(btn_pressed[0] == 1 && counter > -8 )
            counter <= counter - 1;
        if(btn_pressed[3] == 1 && light < 4)
            light <= light + 1;
        else if(btn_pressed[2] == 1 && light > 0)
            light <= light - 1;
    end
        case(light)
        0:
        if(pwm <  50_000)
            usr_led <= counter;
        else
            usr_led <= 0;
        1:
        if(pwm < 250_000)
            usr_led <= counter;
        else
            usr_led <= 0;
        2:
        if(pwm < 500_000)
            usr_led <= counter;
        else
            usr_led <= 0;
        3:
        if(pwm < 750_000)
            usr_led <= counter;
        else
            usr_led <= 0;
        4:
            usr_led <= counter;
        endcase
        if(pwm < 1_000_000)
            pwm <= pwm + 1;
        else
            pwm <= 0;
end

endmodule

module debounce(
    input clk,
    input btn_input,
    output reg btn_output
    );
    reg [31:0] timer = 0;
    always@(posedge clk)begin
    if(btn_input == 1)
        timer <= timer + 1;
    else begin
        timer <= 0;
        btn_output = 0;
    end
    if(timer == 1_000_000)
        btn_output = 1;
    end
endmodule