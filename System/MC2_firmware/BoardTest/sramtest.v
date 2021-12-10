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
// Create Date:    18:00:24 07/18/2018 
// Design Name: 
// Module Name:    sramtest 
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


module sramtest (
  input wire clk,
  input wire rst,
  output reg test_in_progress,
  output reg test_result,
  
  // SRAM pins
  output wire [20:0] sram_addr, 
  output wire sram_oe_n,
  output wire sram_we_n,
  inout tri [7:0] sram_data
  );
  
  
  
  //localparam FINAL_ADDRESS = 19'b1111111111111111111;
    localparam FINAL_ADDRESS = 21'b111111111111111111111;
    
  reg [20:0] addr_to_test =  21'b0000000000000000000;
  reg [15:0] data_to_sram = 8'h55;
  wire [7:0] data_from_sram;
  reg read_rq = 1'b0;
  reg write_rq = 1'b0;
  
  
  localparam
        RESET               = 4'd0,
        WRITE_DATA          = 4'd1,
        WRITE_DATA_01       = 4'd2,
        WRITE_DATA_02       = 4'd3,
        READ_DATA           = 4'd4,
        UPDATE_DATA         = 4'd5,
        CHK_DATA            = 4'd6,
        RETEST              = 4'd7,
        RETEST2             = 4'd8,
        RETEST3             = 4'd9,
        IDLE                = 4'd10
    ;
  
  
  reg [3:0] state = RESET;
  reg initial_rst = 1'b1;  // solo se usa para autoarrancar el test nada mÃƒÆ’Ã‚Â¡s cargar el core.
  
  reg [7:0] byte_to_test = 0;
  
  always @(posedge clk) 
  begin
  
   if (rst == 1'b1 || initial_rst == 1'b1)  
    begin
        byte_to_test = 0;
        state = RESET;
        test_result <= 1'b1;
      test_in_progress <= 1'b1;
    end
    
      case (state)
        RESET:
          begin
            read_rq <= 1'b0;
            write_rq <= 1'b0;
                
          
              addr_to_test <= 21'b000000000000000000000;
              data_to_sram <= byte_to_test;
              write_rq <= 1'b1;
              state <= WRITE_DATA;

              initial_rst <= 1'b0;
            
          end
             
        WRITE_DATA:
          begin
         
              if (addr_to_test == FINAL_ADDRESS) 
                begin
                    state <= CHK_DATA;
                    addr_to_test <= 21'b000000000000000000000;
                    read_rq <= 1'b1;
                    write_rq <= 1'b0;
                end
              else 
                begin
                    addr_to_test <= addr_to_test + 19'd1;
                //  data_to_sram <= addr_to_test[7:0];
                    write_rq <= 1'b1;
                end

          end
         
          

             
        READ_DATA:
          begin

              state <= UPDATE_DATA;
              data_to_sram <= data_from_sram + 8'h55;
                  read_rq <= 1'b0;
              write_rq <= 1'b0;
          end
             
        UPDATE_DATA:
          begin
          
              if (addr_to_test == FINAL_ADDRESS) 
                  begin
                state <= CHK_DATA;
                addr_to_test <= 21'b000000000000000000000;
                read_rq <= 1'b1;
                     write_rq <= 1'b0;
              end
              else 
                  begin
                addr_to_test <= addr_to_test + 19'd1;
                state <= READ_DATA;
                read_rq <= 1'b1;
                      write_rq <= 1'b0;
              end
            
            
          end
             
        CHK_DATA:
          begin
        
              if (addr_to_test == FINAL_ADDRESS) 
                      begin
                         state <= RETEST;
                         
                      end
              else 
                      begin
                         addr_to_test <= addr_to_test + 19'd1;
                         
                         if (data_from_sram != byte_to_test)
                             begin
                                test_in_progress <= 1'b0;
                                test_result <= 1'b0;
                                state <= IDLE;
                             end
                         else 
                            begin
                                read_rq <= 1'b1;
                            end
                      end

          end
             
             RETEST:
          begin
        
             case (byte_to_test)
                     
                     8'h00: 
                        begin
                            byte_to_test <= 8'h55;
                            state <= RESET;
                        end 
                    
                     8'h55: 
                        begin
                            byte_to_test <= 8'haa;
                            state <= RESET;
                        end 
    
                     8'haa: 
                        begin
                            byte_to_test <= 8'h0f;
                            state <= RESET;
                        end 
                    
                    8'h0f: 
                        begin
                            byte_to_test <= 8'hf0;
                            state <= RESET;
                        end 
                    
                    8'hf0: 
                        begin
                            byte_to_test <= 8'hff;
                            state <= RESET;
                        end 
    
                    default:
                        begin
                            test_in_progress <= 1'b0;
                            test_result <= 1'b1;
                            state <= IDLE;
                        end
                        
                endcase
          end
             
             IDLE:
             begin
                read_rq <= 1'b0;
                write_rq <= 1'b0;
             end
   
    
      endcase
    
  end
  
  assign sram_addr = addr_to_test;
  assign sram_oe_n = ~read_rq;
  assign sram_we_n = ~write_rq;
  assign sram_data = (write_rq == 1'b1) ? data_to_sram[7:0] : 8'bZZZZZZZZ;
  assign data_from_sram = sram_data;
  
endmodule

