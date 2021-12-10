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
  
*/module sega_joystick  
(
    input  clk_i,     
    input  joy1_up_i,           
    input  joy1_down_i,         
    input  joy1_left_i,         
    input  joy1_right_i,            
    input  joy1_p6_i,           
    input  joy1_p9_i,           
    input  joy2_up_i,           
    input  joy2_down_i,         
    input  joy2_left_i,         
    input  joy2_right_i,            
    input  joy2_p6_i,           
    input  joy2_p9_i,           
    output joyX_p7_o,           
    output [11:0] joy1_o,       // MS ZYX CBA RLDU
    output [11:0] joy2_o        // MS ZYX CBA RLDU

);

reg clk_sega_s;

parameter CLOCK = 50;
localparam TIMECLK = (9 * (CLOCK / 1000));// (9 / (1 / CLOCK)) / 2; //calculate 9us state time based on input clock
reg [9:0] delay = TIMECLK;

always@(posedge clk_i)
begin
    delay <= delay - 10'd1;
    
    if (delay == 10'd0) 
        begin
            clk_sega_s <= ~clk_sega_s;
            delay <= TIMECLK; // 30
        end
end

reg [11:0]joy1_s;   
reg [11:0]joy2_s; 

initial begin
    joy1_s = 12'b111111111111;
    joy2_s = 12'b111111111111;
end

reg joyP7_s;

reg [7:0]state_v = 8'd0;
reg j1_sixbutton_v = 1'b0;
reg j2_sixbutton_v = 1'b0;

assign joy1_o = joy1_s;
assign joy2_o = joy2_s;
assign joyX_p7_o = joyP7_s;

reg old_clk;
always @(posedge clk_i) 
begin

    old_clk <= clk_sega_s;

    if (clk_sega_s & ~old_clk)
    begin

        state_v <= state_v + 1;

        case (state_v)          //-- joy_s format MXYZ SACB RLDU
            8'd0:  
                joyP7_s <=  1'b0;
                
            8'd1:
                joyP7_s <=  1'b1;

            8'd2:
                begin
                    joy1_s[3:0] <= {joy1_right_i, joy1_left_i, joy1_down_i, joy1_up_i}; //-- R, L, D, U
                    joy2_s[3:0] <= {joy2_right_i, joy2_left_i, joy2_down_i, joy2_up_i}; //-- R, L, D, U
                    joy1_s[5:4] <= {joy1_p9_i, joy1_p6_i}; //-- C, B
                    joy2_s[5:4] <= {joy2_p9_i, joy2_p6_i}; //-- C, B                    
                    joyP7_s <= 1'b0;
                    j1_sixbutton_v <= 1'b0; //-- Assume it's not a six-button controller
                    j2_sixbutton_v <= 1'b0; //-- Assume it's not a six-button controller
                end
                
            8'd3:
                begin
                    if (joy1_right_i == 1'b0 && joy1_left_i == 1'b0) // it's a megadrive controller
                            joy1_s[7:6] <= { joy1_p9_i , joy1_p6_i }; //-- Start, A
                    else
                            joy1_s[7:4] <= { 1'b1, 1'b1, joy1_p9_i, joy1_p6_i }; //-- read A/B as master System
                        
                    if (joy2_right_i == 1'b0 && joy2_left_i == 1'b0) // it's a megadrive controller
                            joy2_s[7:6] <= { joy2_p9_i , joy2_p6_i }; //-- Start, A
                    else
                            joy2_s[7:4] <= { 1'b1, 1'b1, joy2_p9_i, joy2_p6_i }; //-- read A/B as master System

                        
                    joyP7_s <= 1'b1;
                end
                
            8'd4:  
                joyP7_s <= 1'b0;

            8'd5:
                begin
                    if (joy1_down_i == 1'b0 && joy1_up_i == 1'b0 )
                        j1_sixbutton_v <= 1'b1; // --it's a six button
                    
                    
                    if (joy2_down_i == 1'b0 && joy2_up_i == 1'b0 )
                        j2_sixbutton_v <= 1'b1; // --it's a six button
                    
                    
                    joyP7_s <= 1'b1;
                end
                
            8'd6:
                begin
                    if (j1_sixbutton_v == 1'b1)
                        joy1_s[11:8] <= { joy1_right_i, joy1_left_i, joy1_down_i, joy1_up_i }; //-- Mode, X, Y e Z
                    
                    
                    if (j2_sixbutton_v == 1'b1)
                        joy2_s[11:8] <= { joy2_right_i, joy2_left_i, joy2_down_i, joy2_up_i }; //-- Mode, X, Y e Z
                    
                    
                    joyP7_s <= 1'b0;
                end 
                
            default:
                joyP7_s <= 1'b1;
                
        endcase
    end
end
    
endmodule