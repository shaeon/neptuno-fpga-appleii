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
  
*/`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    03:30:06 02/14/2016 
// Design Name: 
// Module Name:    sync_generator_pal_ntsc 
// Project Name:  
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module sync_generator (
    input wire clk,   
    output reg csync_n,
    output reg hsync_n,
    output reg vsync_n,
    output wire [9:0] hc,
    output wire [9:0] vc,
    output reg blank
    );
    
    reg [9:0] h = 10'd0;
    reg [9:0] v = 10'd0;

    assign hc = h;
    assign vc = v;
    
    always @(posedge clk) begin

            if (h == 10'd799) begin
                h <= 10'd0;
                if (v == 10'd523) begin
                    v <= 10'd0;
                end
                else
                    v <= v + 10'd1;
            end
            else
                h <= h + 10'd1;
    end
    
    reg vblank, hblank;
    always @* begin
        vblank = 1'b0;
        hblank = 1'b0;
        vsync_n = 1'b1;
        hsync_n = 1'b1;

            if (v >= 10'd480 && v <= 10'd523) begin
                vblank = 1'b1;
                if (v >= 10'd491 && v <= 10'd493) begin
                    vsync_n = 1'b0;
                end
            end
            if (h >= 10'd640 && h <= 10'd799) begin
                hblank = 1'b1;
                if (h >= 10'd656 && h <= 10'd752) begin
                    hsync_n = 1'b0;
                end
            end

        blank = hblank | vblank;
        csync_n = hsync_n & vsync_n;
    end
endmodule
