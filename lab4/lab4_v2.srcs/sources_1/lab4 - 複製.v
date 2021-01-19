`timescale 1ns / 1ps
module lab4(
  input  clk,            // System clock at 100 MHz
  input  reset_n,        // System reset signal, in negative logic
  input  [3:0] usr_btn,  // Four user pushbuttons
  output reg [3:0] usr_led   // Four yellow LEDs
);
reg[3:0] btn, reg_btn;
reg signed[3:0] counter = 0;
reg[19:0] pwm = 0;
reg[31:0] clk_cnt [3:0];
reg[3:0] light = 0;
integer i;

always@(posedge clk)begin
        for(i = 0; i < 4; i = i + 1)begin
            if(usr_btn[i] == 1)
                clk_cnt[i] <= clk_cnt[i] + 1;
            else begin
                clk_cnt[i] <= 0;
                btn[i] <= 0;
            end
            if(clk_cnt[i] == 10_000_000)
                btn[i] <= 1;
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

always@(posedge btn[0] or posedge btn[1] or negedge reset_n)begin
    if(reset_n == 0)
        counter <= 0;
    else begin
        if(btn[1] == 1 && counter < 7)
            counter <= counter + 1;
        else if(btn[0] == 1 && counter > -8 )
            counter <= counter - 1;
    end
end

always@(posedge btn[2] or posedge btn[3])begin
    if(btn[3] == 1 && light < 4)
        light <= light + 1;
    else if(btn[2] == 1 && light > 0)
        light <= light - 1;
end
endmodule