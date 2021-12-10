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
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   05:20:24 08/15/2016 
// Design Name: 
// Module Name:   switch_mode 
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
module switch_mode (
  input wire clk,
  input wire clkps2,
  input wire dataps2,
  output reg sdtest,
  output reg flashtest,
  output reg mousetest,
  output reg sdramtest,
  output reg sramtest,
  output reg serialtest,
  output reg snes1_mode,
  output reg snes2_mode,
  output reg hidetextwindow
  );

  wire key_event, released, extended;
  wire [7:0] scancode;

  ps2_port teclado (
    .clk(clk),  // se recomienda 1 MHz <= clk <= 600 MHz
    .enable_rcv(1'b1),  // habilitar la maquina de estados de recepcion
    .kb_or_mouse(1'b0),
    .ps2clk_ext(clkps2),
    .ps2data_ext(dataps2),
    .kb_interrupt(key_event),  // a 1 durante 1 clk para indicar nueva tecla recibida
    .scancode(scancode), // make o breakcode de la tecla
    .released(released),  // soltada=1, pulsada=0
    .extended(extended)  // extendida=1, no extendida=0
  );
   
  initial begin
    sdtest = 1'b0;
    serialtest = 1'b0;
    flashtest = 1'b0;
    mousetest = 1'b0;
    sdramtest = 1'b0;
    sramtest = 1'b0;
    snes1_mode = 1'b0;
    snes2_mode = 1'b0;
    hidetextwindow = 1'b0;
  end
  
  always @(posedge clk) begin
    sdtest <= 1'b0;
    flashtest <= 1'b0;
    mousetest <= 1'b0;
    sdramtest <= 1'b0;
    sramtest = 1'b0;
    serialtest <= 1'b0;
    if (key_event == 1'b1) begin
      if (scancode == 8'h29 && extended == 1'b0)  // tecla SPACE
        hidetextwindow <= ~released;
      else if (extended == 1'b0 && released == 1'b1) begin
        case (scancode)
		  /*
          8'h16,8'h69:  begin  // tecla 1
                          mode <= 1'b0;
                          vga <= 1'b0;
                        end
          8'h1E,8'h72:  begin  // tecla 2
                          mode <= 1'b1;
                          vga <= 1'b0;
                        end
          8'h26,8'h7A:  begin // tecla 3
                          mode <= 1'b1;
                          vga <= 1'b1;
                        end
								*/
			 8'h16,8'h69:  snes1_mode <= ~snes1_mode;   // tecla 1
			 8'h1e,8'h72:  snes2_mode <= ~snes2_mode;   // tecla 2
			 8'h26,8'h7A:  sramtest <= 1'b1;  // tecla 3
          8'h25,8'h6B:  sdramtest <= 1'b1; // tecla 4
          8'h2E,8'h73:  sdtest <= 1'b1;    // tecla 5
          8'h36,8'h74:  mousetest <= 1'b1; // tecla 6
          //8'h3D,8'h6C:  mousetest <= 1'b1;  // tecla 7
          //8'h3E,8'h75:  serialtest <= 1'b1; // tecla 8
        endcase
      end
    end
  end
endmodule

