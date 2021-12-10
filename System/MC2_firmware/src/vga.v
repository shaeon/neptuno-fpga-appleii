/*
  
   Multicore 2 / Multicore 2+
  
   Copyright (c) 2017-2020 - Victor Trucco

  
   All rights reserved
  
   Redistribution and use in source and synthezised forms, with or without
   modification, are permitted provided that the following conditions are met:
  
   Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
  
   Redistributions in synthesized form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
  
   Neither the name of the author nor the names of other contributors may
   be used to endorse or promote products derived from this software without
   specific prior written permission.
  
   THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
   POSSIBILITY OF SUCH DAMAGE.
  
   You are responsible for any legal issues arising from your use of this code.
  
*/// (c) 2015 Till Harbaum 

module vga (
   // pixel clock
   input  pclk,

	// enable/disable scanlines
	input scanlines,
	
	// output to VGA screen
   output reg	hs,
   output reg 	vs,
   output [3:0] r,
   output [3:0] g,
   output [3:0] b,
	output reg blank
	
);
					
// http://tinyvga.com/vga-timing
//VGA Signal 640 x 480 @ 60 Hz Industry standard timing
parameter H   = 640;    // width of visible area
parameter HFP = 16;     // unused time before hsync
parameter HS  = 96;     // width of hsync
parameter HBP = 48;     // unused time after hsync

parameter V   = 480;    // height of visible area
parameter VFP = 10;     // unused time before vsync
parameter VS  = 2;      // width of vsync
parameter VBP = 33;     // unused time after vsync

reg[9:0]  h_cnt;        // horizontal pixel counter
reg[9:0]  v_cnt;        // vertical pixel counter

// both counters count from the begin of the visible area

// horizontal pixel counter
always@(posedge pclk) begin
	if(h_cnt==H+HFP+HS+HBP-1)   h_cnt <= 10'd0;
	else                        h_cnt <= h_cnt + 10'd1;

        // generate negative hsync signal
	if(h_cnt == H+HFP)    hs <= 1'b0;
	if(h_cnt == H+HFP+HS) hs <= 1'b1;
end

// veritical pixel counter
always@(posedge pclk) begin
        // the vertical counter is processed at the begin of each hsync
	if(h_cnt == H+HFP) begin
		if(v_cnt==VS+VBP+V+VFP-1)  v_cnt <= 10'd0; 
		else								v_cnt <= v_cnt + 10'd1;

               // generate positive vsync signal
 		if(v_cnt == V+VFP)    vs <= 1'b1;
		if(v_cnt == V+VFP+VS) vs <= 1'b0;
	end
end


reg [7:0] pixel;

always@(posedge pclk) begin
		  
	pixel <= 8'h00;
	
   // visible area?
	if((v_cnt < V) && (h_cnt < H))
		begin
			blank <= 1'b0;
		end 
	else 
		begin
			blank <= 1'b1;
		end
end

// split the 8 rgb bits into the three base colors. Every second line is
// darker when scanlines are enabled
wire scanline = scanlines && v_cnt[0];
assign r = (!scanline)?{ pixel[7:5],  1'b0 }:{ 1'b0, pixel[7:5] };
assign g = (!scanline)?{ pixel[4:2],  1'b0 }:{ 1'b0, pixel[4:2] };
assign b = (!scanline)?{ pixel[1:0],  2'b0 }:{ 1'b0, pixel[1:0] };

endmodule
