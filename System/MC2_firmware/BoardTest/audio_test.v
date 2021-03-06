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
// Create Date:    02:37:59 08/15/2016 
// Design Name: 
// Module Name:    audio_test 
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
module audio_test (
   input wire clk,  // 14MHz
   output wire left,
   output wire right,
   output wire led1,
   output wire led2
   );
   
   reg [11:0] sample_addr = 12'd0;
   reg [7:0] sample;
   reg [12:0] cnt_2000 = 13'd0;
   reg leftright = 1'b0;

   reg [7:0] audiomem[0:3999];
   initial begin
      $readmemh ("left_audio.hex", audiomem, 0);
      $readmemh ("right_audio.hex", audiomem, 2000);
   end
   
   always @(posedge clk) begin
      if (cnt_2000 == 13'd3500) begin  // prescaler para pasar de 14MHz a 2kHz, que es nuestra frecuencia de muestreo
         cnt_2000 <= 13'd0;
         sample <= audiomem[sample_addr];
         if (sample_addr == 12'd1999)  // Si hemos llegado a la mitad de la memoria
            leftright <= 1'b1;         // La memoria contiene en una mitad, el sample izquierdo, y en la otra mitad, el derecho
         if (sample_addr == 12'd3999) begin // Si hemos llegado al final de la memoria
            sample_addr <= 12'd0;      // Volver al principio
            leftright <= 1'b0;         // Y seleccionar salida al izquierdo
         end
         else
            sample_addr <= sample_addr + 12'd1;
      end
      else
         cnt_2000 <= cnt_2000 + 13'd1;
   end
   
   wire aout;
   dac dac8bits (aout, sample, clk, 1'b0);
   assign left = (leftright == 1'b0)? aout : 1'b0;
   assign right = (leftright == 1'b1)? aout : 1'b0;
   assign led1 = ~leftright;
   assign led2 = leftright;
endmodule

`define MSBI 7 // Most significant Bit of DAC input

//This is a Delta-Sigma Digital to Analog Converter
module dac (DACout, DACin, Clk, Reset);
	output reg DACout; // This is the average output that feeds low pass filter
	input wire [`MSBI:0] DACin; // DAC input (excess 2**MSBI)
	input wire Clk;
	input wire Reset;

	initial DACout = 1'b0; // for optimum performance, ensure that this ff is in IOB
	reg [`MSBI+2:0] DeltaAdder; // Output of Delta adder
	reg [`MSBI+2:0] SigmaAdder; // Output of Sigma adder
	reg [`MSBI+2:0] SigmaLatch = 1'b1 << (`MSBI+1); // Latches output of Sigma adder
	reg [`MSBI+2:0] DeltaB; // B input of Delta adder

	always @(SigmaLatch) DeltaB = {SigmaLatch[`MSBI+2], SigmaLatch[`MSBI+2]} << (`MSBI+1);
	always @(DACin or DeltaB) DeltaAdder = DACin + DeltaB;
	always @(DeltaAdder or SigmaLatch) SigmaAdder = DeltaAdder + SigmaLatch;
	always @(posedge Clk)
	begin
		if(Reset)
		begin
			SigmaLatch <= #1 1'b1 << (`MSBI+1);
			DACout <= #1 1'b0;
		end
		else
		begin
			SigmaLatch <= #1 SigmaAdder;
			DACout <= #1 SigmaLatch[`MSBI+2];
		end
	end
endmodule

