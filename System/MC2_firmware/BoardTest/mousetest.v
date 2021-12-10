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
// Create Date:    06:06:35 08/19/2016 
// Design Name: 
// Module Name:    mousetest 
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

module mousetest (
   input wire clk,
   input wire rst,
   inout wire ps2clk,
   inout wire ps2data,
   output reg [2:0] botones,
	output reg [7:0] mX = 0,
	output reg [7:0] mY = 0
   );
   
   initial botones = 3'b000;
   reg enviando_comando = 1'b0;
   wire nuevo_evento;
   wire [7:0] mousedata;
   ps2_port lectura_de_raton (
       .clk(clk),
       .enable_rcv(~enviando_comando),
       .kb_or_mouse(1'b1),
       .ps2clk_ext(ps2clk),
       .ps2data_ext(ps2data),
       .kb_interrupt(nuevo_evento),
       .scancode(mousedata),
       .released(),
       .extended()
   );
   
   reg cargar_dato = 1'b0;
   wire ps2busy;
   ps2_host_to_kb escritura_a_raton (
       .clk(clk),
       .ps2clk_ext(ps2clk),
       .ps2data_ext(ps2data),
       .data(8'hF4),  // enable reporting
       .dataload(cargar_dato),
       .ps2busy(ps2busy),
       .ps2error()
   );
   
   reg [2:0] estado = INITMOUSE;
   parameter
      INITMOUSE = 3'd0,
      DEACTIVATELOAD = 3'd1,
      WAITINIT = 3'd2,
      FRAME1 = 3'd3,
      FRAME2 = 3'd4,
      FRAME3 = 3'd5
      ;
   always @(posedge clk) begin
      if (rst == 1'b1)
		begin
         estado <= INITMOUSE;
			mX <= 0;
			mY <= 0;
		end 
		
      case (estado)
         INITMOUSE:
            begin
               enviando_comando <= 1'b1;
               cargar_dato <= 1'b1;
               estado <= DEACTIVATELOAD;
            end
         DEACTIVATELOAD:
            begin
               cargar_dato <= 1'b0;
               estado <= WAITINIT;
            end
         WAITINIT:
            begin
               if (ps2busy == 1'b0) begin
                  enviando_comando <= 1'b0;
                  estado <= FRAME1;
               end
            end
         FRAME1:
            begin
               if (nuevo_evento == 1'b1) begin
                  if (mousedata[3] == 1'b1) begin
                     botones <= mousedata[2:0];
                     estado <= FRAME2;
                  end
               end
            end
         FRAME2:
            begin
               if (nuevo_evento == 1'b1) begin
						mX <= mX + mousedata;
                  estado <= FRAME3;
               end
            end
         FRAME3:
            begin
               if (nuevo_evento == 1'b1) begin
						mY <= mY + mousedata;
                  estado <= FRAME1;
               end
            end
      endcase
   end
endmodule
