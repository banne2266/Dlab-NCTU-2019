`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai 
// 
// Create Date: 2018/12/11 16:04:41
// Design Name: 
// Module Name: lab9
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: A circuit that show the animation of a fish swimming in a seabed
//              scene on a screen through the VGA interface of the Arty I/O card.
// 
// Dependencies: vga_sync, clk_divider, sram 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab10(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    input  [3:0] usr_sw,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );

// Declare system variables
reg  [31:0] fish_clock,fish_clock2,geni_clock,genix_clock,geniy_clock ;
reg eatA, eatB;
wire [9:0]  pos,pos2,genix,geniy;
wire        fish_region;
wire        geni_region;

// declare SRAM control signals
wire [16:0] sram_addr;
wire [11:0] data_in;
wire [11:0] data_out;
wire        sram_we, sram_en;

// declare SRAM control signals
wire [16:0] sramfish_addr;
wire [11:0] datafish_in;
wire [11:0] datafish_out;
wire        sramfish_we, sramfish_en;

// declare SRAM control signals
wire [16:0] sramgeni_addr;
wire [11:0] datageni_in;
wire [11:0] datageni_out;
wire        sramgeni_we, sramgeni_en;

// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
  
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)
  
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
  
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel
  
// Application-specific VGA signals
reg  [17:0] pixel_addr;
reg  [17:0] fishs_addr;
reg  [17:0] genis_addr;


// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height

// Set parameters for the fish images
localparam FISH_VPOS   = 64; // Vertical location of the fish in the sea image.
localparam FISH_VPOS2  = 128;
localparam FISH_W      = 64; // Width of the fish.
localparam FISH_H      = 32; // Height of the fish.
reg [17:0] fish_addr[0:7];   // Address array for up to 8 fish images.

// Set parameters for the geni images
localparam GENI_W      = 40; // Width of the fish.
localparam GENI_H      = 40; // Height of the fish.
reg [17:0] geni_addr[0:15];   // Address array for up to 8 fish images.
assign usr_led = genix_clock;
// Initializes the fish images starting addresses.
// Note: System Verilog has an easier way to initialize an array,
//       but we are using Verilog 2001 :(
initial begin
  fish_addr[0] = 18'd0;         /* Addr for fish image #1 */
  fish_addr[1] = FISH_W*FISH_H*1; /* Addr for fish image #2 */
  fish_addr[2] = FISH_W*FISH_H*2; /* Addr for fish image #3 */
  fish_addr[3] = FISH_W*FISH_H*3; /* Addr for fish image #4 */
  fish_addr[4] = FISH_W*FISH_H*4; /* Addr for fish image #5 */
  fish_addr[5] = FISH_W*FISH_H*5; /* Addr for fish image #6 */
  fish_addr[6] = FISH_W*FISH_H*6; /* Addr for fish image #7 */
  fish_addr[7] = FISH_W*FISH_H*7; /* Addr for fish image #8 */
end

initial begin
  geni_addr[ 0] = 18'd0;         /* Addr for fish image #1 */
  geni_addr[ 1] = GENI_W*GENI_H* 1; /* Addr for fish image #2 */
  geni_addr[ 2] = GENI_W*GENI_H* 2; /* Addr for fish image #2 */
  geni_addr[ 3] = GENI_W*GENI_H* 3; /* Addr for fish image #2 */
  geni_addr[ 4] = GENI_W*GENI_H* 4; /* Addr for fish image #2 */
  geni_addr[ 5] = GENI_W*GENI_H* 5; /* Addr for fish image #2 */
  geni_addr[ 6] = GENI_W*GENI_H* 6; /* Addr for fish image #2 */
  geni_addr[ 7] = GENI_W*GENI_H* 7; /* Addr for fish image #2 */
  geni_addr[ 8] = GENI_W*GENI_H* 8; /* Addr for fish image #2 */
  geni_addr[ 9] = GENI_W*GENI_H* 9; /* Addr for fish image #2 */
  geni_addr[10] = GENI_W*GENI_H*10; /* Addr for fish image #2 */
  geni_addr[11] = GENI_W*GENI_H*11; /* Addr for fish image #2 */
  geni_addr[12] = GENI_W*GENI_H*12; /* Addr for fish image #2 */
  geni_addr[13] = GENI_W*GENI_H*13; /* Addr for fish image #2 */
  geni_addr[14] = GENI_W*GENI_H*14; /* Addr for fish image #2 */
  geni_addr[15] = GENI_W*GENI_H*15; /* Addr for fish image #2 */
  genix_clock[31:20] = 320;
  geniy_clock[31:20] = 180;
end

// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);

// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W*VBUF_H))
  ram0 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));

assign sram_we = &usr_btn; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr = pixel_addr;
assign data_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------
// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
sramfish #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH_W*FISH_H*8))
  ram1 (.clk(clk), .we(sramfish_we), .en(sramfish_en),
          .addr(sramfish_addr), .data_i(datafish_in), .data_o(datafish_out));

assign sramfish_we = &usr_btn; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sramfish_en = 1;          // Here, we always enable the SRAM block.
assign sramfish_addr = fishs_addr;
assign datafish_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
sramgeni #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(GENI_W*GENI_H*16))
  ram2 (.clk(clk), .we(sramgeni_we), .en(sramgeni_en),
          .addr(sramgeni_addr), .data_i(datageni_in), .data_o(datageni_out));

assign sramgeni_we = &usr_btn; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sramgeni_en = 1;          // Here, we always enable the SRAM block.
assign sramgeni_addr = genis_addr;
assign datageni_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;


// ------------------------------------------------------------------------
// An animation clock for the motion of the fish, upper bits of the
// fish clock is the x position of the fish on the VGA screen.
// Note that the fish will move one screen pixel every 2^20 clock cycles,
// or 10.49 msec
assign pos = fish_clock[31:20]; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen
always @(posedge clk) begin
  if (~reset_n || fish_clock[31:21] > VBUF_W + FISH_W)
    fish_clock <= 0;
  else if(usr_sw[0]==0)
    fish_clock <= fish_clock + 1;
  else if(usr_sw[0]==1)
    fish_clock <= fish_clock + 2;
end

assign pos2 = 2*(VBUF_W + FISH_W) - fish_clock2[31:20]; 
always @(posedge clk) begin
  if (~reset_n || fish_clock2[31:21] > VBUF_W + FISH_W)
    fish_clock2 <= 0;
  else if(usr_sw[3]==0)
    fish_clock2 <= fish_clock2 + 1;
  else if(usr_sw[3]==1)
    fish_clock2 <= fish_clock2 + 3;
end
// End of the animation clock code.
// ------------------------------------------------------------------------
// ------------------------------------------------------------------------
// An animation clock for the motion of the fish, upper bits of the
// fish clock is the x position of the fish on the VGA screen.
// Note that the fish will move one screen pixel every 2^20 clock cycles,
// or 10.49 msec
assign genix = genix_clock[31:20]; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen
assign geniy = geniy_clock[31:20]; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen                 

always @(posedge clk) begin
  if (~reset_n)
    geni_clock <= 0;
  else if(usr_sw[2]==0)
    geni_clock <= geni_clock +1;
  else if(usr_sw[2]==1)
    geni_clock <= geni_clock +2;
end   


always @(posedge clk) begin
  if (~reset_n) begin
    genix_clock[31:20] <= 320;
    geniy_clock[31:20] <= 180;
  end
  else begin
    if     (usr_btn[0] && genix < 640)
    	genix_clock <= genix_clock + 2;
    else if(usr_btn[1] && genix >  80)
    	genix_clock <= genix_clock - 2;
    else if(usr_btn[2] && geniy < 200)
    	geniy_clock <= geniy_clock + 1;
    else if(usr_btn[3] && geniy >   0)
    	geniy_clock <= geniy_clock - 1;
  	else begin
  		geniy_clock <= geniy_clock;
  		genix_clock <= genix_clock;
  	end
  end
end
// End of the animation clock code.
// ------------------------------------------------------------------------
 always @(posedge clk) begin
  if (~reset_n)begin
    eatA <= 0;
    eatB <= 0;
  end  
  if(genix + 40 > pos && genix < pos + 96 && geniy > 48 && geniy < 80 && usr_sw[2]==1 && usr_sw[1]==1)
  	eatA <= 1;
  if(genix + 40 > pos2 && genix < pos2 + 96 && geniy > 116 && geniy < 144 && usr_sw[2]==1 && usr_sw[1]==1)
  	eatB <= 1;
end   
// ------------------------------------------------------------------------
// Video frame buffer address generation unit (AGU) with scaling control
// Note that the width x height of the fish image is 64x32, when scaled-up
// on the screen, it becomes 128x64. 'pos' specifies the right edge of the
// fish image.
assign fish_region =
           (pixel_y >= (FISH_VPOS<<1) && pixel_y < (FISH_VPOS+FISH_H)<<1 &&
           (pixel_x + 127) >= pos && pixel_x < pos + 1 && eatA == 0) || 
           (pixel_y >= (FISH_VPOS2<<1) && pixel_y < (FISH_VPOS2+FISH_H)<<1 &&
           (pixel_x + 127) >= pos2 && pixel_x < pos2 + 1 && eatB == 0);
assign geni_region =
           pixel_y >= (geniy<<1) && pixel_y < (geniy+GENI_H)<<1 &&
           (pixel_x + 79) >= genix && pixel_x < genix + 1;

always @ (posedge clk) begin
  if (~reset_n)
    pixel_addr <= 0;
  else
    // Scale up a 320x240 image for the 640x480 display.
    // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
    pixel_addr <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
end


always @ (posedge clk) begin
  if (~reset_n)
    fishs_addr <= 0;
  else if (fish_region && pixel_y < 255)
    fishs_addr <= fish_addr[fish_clock[25:23]] +
                  ((pixel_y>>1)-FISH_VPOS)*FISH_W +
                  ((pixel_x +(FISH_W*2-1)-pos)>>1);
  else if (fish_region && pixel_y >= 256)
    fishs_addr <= fish_addr[fish_clock2[25:23]] +
                  ((pixel_y>>1)-FISH_VPOS2)*FISH_W +
                  FISH_W*2 - ((pixel_x +(FISH_W*2-1)-pos2)>>1);
  else
    // Scale up a 320x240 image for the 640x480 display.
    // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
    fishs_addr <= 0;
end

always @ (posedge clk) begin
  if (~reset_n)
    genis_addr <= 0;
  else if (geni_region)
    genis_addr <= geni_addr[geni_clock[26:23]] +
                  ((pixel_y>>1)-geniy)*GENI_W +
                  ((pixel_x +(GENI_W*2-1)-genix)>>1);
  else
    // Scale up a 320x240 image for the 640x480 display.
    // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
    genis_addr <= 0;
end
// End of the AGU code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  else
    rgb_next = (usr_sw[1] == 1 && geni_region == 1 && datageni_out != 12'h0f0) ? datageni_out :
    		   (fish_region == 1 && datafish_out != 12'h0f0) ? datafish_out : data_out; 
    // RGB value at (pixel_x, pixel_y)
end
// End of the video data display code.
// ------------------------------------------------------------------------

endmodule
