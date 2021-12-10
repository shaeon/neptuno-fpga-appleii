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
  
*//*
  read sequence

clk   ``\____/````\____/` ..... _/````\____/````\____/` ..... _/````\____/````\____/`
             |         |         |         |         |         |         |
start XXXX```````````\__ ....... ____________________________________________________
             |         |         |         |         |         |         |
rnw   XXXXXX```XXXXXXXXX ....... XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
             |         | some    |         |         |         |         |
ready XXXXXXX\__________ clocks __/``````````````````  ....... ```````````\__________
                         before                                |         |
rdat  ------------------ ready  -< cell 0  | cell 1  | ....... |last cell>-----------
             |         |         |         |         |         |         |
done  XXXXXXX\__________ ....... _____________________ ....... ___________/``````````
                                                                            ^all operations stopped until next start strobe



  write sequence

clk   ``\____/````\____/` ..... _/````\____/````\____/````\____/````\____/````\____/````\____/````\____/
             |         | some    |         | some    |         |         |         |         |         |
start XXXX```````````\__ ....... _____________ .... ______________ .... ________________________________
             |         | clocks  |         | clocks  |         |         |         |         |         |
rnw   XXXXXX___XXXXXXXXX ....... XXXXXXXXXXXXX .... XXXXXXXXXXXXXX .... XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
             |         | before  |         | before  |         |         |         |         |         |
ready XXXXXXX\__________ ....... _/`````````\_ .... __/`````````\_ .... __/`````````\___________________
             |         | first   |         | next    |         |         |         |         |         |
wdat  XXXXXXXXXXXXXXXXXXXXXXXXXXXX< cell 0  >X .... XX< cell 1  >X .... XX<last cell>XXXXXXXXXXXXXXXXXXX
             |         | ready   |         | ready   |         |         |         |         |         |
done  XXXXXXXX\_________ ....... _____________ .... ______________ .... ____________/```````````````````
             |         | strobe  |         | strobe  |         |         |         |         |         |

*/


module sdram
(
	input             clk,
	input             rst_n, // total reset

	input             start, // start sequence
	output reg        done,  // =1 when operation is done,
						          // also done=0 while reset SDRAM initialisation is in progress

	input             rnw,   // 1 - read, 0 - write sequence (latched when start=1)
	output reg        ready, // strobe. when writing, one means that data from wdat written to the memory
						          // when reading, one means that data read from memory is on rdat output

	input      [15:0] wdat,  // input, data to be written to memory
	output reg [15:0] rdat,  // output, data last read from memory

	input       [1:0] sz,

	output            DRAM_CLK,
	output            DRAM_LDQM,DRAM_UDQM,
	output            DRAM_WE_N,
	output            DRAM_CAS_N,
	output            DRAM_RAS_N,
	output            DRAM_CS_N,
	output            DRAM_BA_0,
	output            DRAM_BA_1,
	inout  reg [15:0] DRAM_DQ,
	output     [12:0] DRAM_ADDR
);

assign {DRAM_BA_1,DRAM_BA_0} = ba;
assign DRAM_ADDR  = sdaddr;
assign DRAM_WE_N  = cmd[0];
assign DRAM_CAS_N = cmd[1];
assign DRAM_RAS_N = cmd[2];
assign DRAM_CS_N  = cs;
assign {DRAM_UDQM,DRAM_LDQM} = DRAM_ADDR[1:0];

reg [12:0] sdaddr, sdaddr2;
reg  [1:0] ba, ba2;
reg  [2:0] cmd, cmd2;
reg        cs, cs2;

wire [2:0] CMD_NOP             = 3'b111;
wire [2:0] CMD_ACTIVE          = 3'b011;
wire [2:0] CMD_READ            = 3'b101;
wire [2:0] CMD_WRITE           = 3'b100;
wire [2:0] CMD_PRECHARGE       = 3'b010;
wire [2:0] CMD_AUTO_REFRESH    = 3'b001;
wire [2:0] CMD_LOAD_MODE       = 3'b000;


reg [4:0] initstate;
reg       init_done;
always @ (posedge clk) begin
	if(!rst_n) begin
		initstate <= 0;
		init_done <= 0;
	end else begin
		if (state == 5) begin
			if(~&initstate) initstate <= initstate + 4'd1;
			else init_done <= 1;
		end
	end
end

reg ready2;

always @ (posedge clk) 
begin
	ready2 <= 0;
	if(wr) case(state) 3,4,5,6: ready2 <= 1; endcase
	if(rd) case(state) 2,3,4,5: ready2 <= 1; endcase
end

reg [2:0] state;
reg       wr,rd,wr2,done2;

always @ (posedge clk) 
begin

	reg  [9:0] cas_addr, cas_addr2;
	reg [23:0] addr, addr2, addr3; // x4
	reg  [5:0] rcnt = 0;
	reg        rnw_reg;
	reg  [1:0] rfsh;
	reg [15:0] rdat2,rdat3;
	reg        done3;
	reg [4:0]  is, is2, is3;
	reg [2:0]  st;
	reg        id;
	reg [2:0]  cas_cmd, cas_cmd2;
	reg        wdat_req;

	st    <= st + 1'd1;
	state <= st;

	DRAM_DQ <= 16'bZ;

	wr <= wr2;
	wdat_req <= wr2 & ready2;
	if(wdat_req) DRAM_DQ <= wdat;

	rdat3   <= DRAM_DQ;
	rdat2   <= rdat3;
	rdat    <= rdat2;
	cmd2    <= CMD_NOP;

	is3 <= initstate;
	is2 <= is3;
	is  <= is2;
	id  <= init_done;

	if(!id) 
		begin
			cs2 <= is[4];

			if(state == 1) 
			begin
				case(is[3:0])
				
					2 : 		begin
									sdaddr2[10]<= 1; // all banks
									cmd2       <= CMD_PRECHARGE;
								end
								
					4,7 : 	begin
									cmd2       <= CMD_AUTO_REFRESH;
								end
								
					10, 13 : begin
									cmd2       <= CMD_LOAD_MODE;
									sdaddr2    <= 13'b000_0_00_011_0_010; // WRITE BURST, (burst read, burst write)   LATENCY=3, BURST LENGHT=4 //usando um write burst diferente, o CAS precisa ser alterado[1:0]??
								//	sdaddr2    <= 13'b000_0_00_010_0_010; // WRITE BURST, (burst read, burst write)   LATENCY=2, BURST LENGHT=4 
									//sdaddr2  <= 13'b000_1_00_010_0_000; // SM-X         (burst read, single write)  LATENCY=2  BURST LENGHT=1 
									//sdaddr2  <= 13'b000_0_00_010_0_010; // FGPAPCE
								end
								
				endcase
			end
			
			wr2  <= 0;
			wr   <= 0;
			rd   <= 0;
			rcnt <= 0;
			done2<= 0;
			
		end
	else if(done2) 
				begin
				
					rd    <= 0;
					wr2   <= 0;
					wr    <= 0;
					addr  <= 0;
					addr2 <= 0;
					st    <= 0;
					done3 <= 0;
					
					if(start) 
						begin
							done2   <= 0;
							rnw_reg <= rnw;
						end
					
				end
	else 
		begin
			case(state)
				0: begin
						rcnt       <= rcnt + 1'd1;
						if(rcnt == 50) rcnt <= 0;

						rfsh <= 0;
						if(rcnt >= 49) rfsh <= {1'b1, rcnt[0]};
						addr3 <= addr;
					end

				// RAS
				1 : begin
						cas_cmd2   <= CMD_NOP;
						wr2        <= 0;
						if(rfsh[1]) begin
							cmd2    <= CMD_AUTO_REFRESH;
							cs2     <= rfsh[0];
						end
						else if(~done3) begin
//							{cs2, cas_addr2[9], cas_addr2[8:2], sdaddr2, ba2, cas_addr2[1:0]} <= {addr3, 2'b00};
							
				//			cs2				<= addr3[23];
				//			cas_addr2[9]	<= addr3[22];
				//			cas_addr2[8:2]	<= addr3[21:15];
				//			sdaddr2[12]		<= addr3[14]; //SDRAM line A12
				//			sdaddr2[11:0]	<= addr3[13:2];
				//			ba2				<= addr3[1:0];
				//			cas_addr2[1:0] <= 2'b00;
							
							cs2				<= 1'b0;//addr3[23];

							
							sdaddr2[12]		<= addr3[21]; 
							sdaddr2[11:0]	<= addr3[20:9];
							
							cas_addr2[8:2]	<= addr3[8:2];
							cas_addr2[1:0] <= 2'b00; //por causa do write burst???
							ba2				<= addr3[1:0];
	
							wr2     <= ~rnw_reg;
							cas_cmd2<= rnw_reg ? CMD_READ : CMD_WRITE;
							cmd2    <= CMD_ACTIVE;
							addr2   <= addr + 1'd1;
						end
					end
				
				2 : begin
						addr       <= addr2;
						cas_addr   <= cas_addr2;
						cas_cmd    <= cas_cmd2;
					end

				// CAS
				4 : begin
						sdaddr2[12:9] <= 3'b0010;// AUTO PRECHARGE
						sdaddr2[8:0]   <= cas_addr; //cas is A0 to A8
						cmd2           <= cas_cmd;
					end
				
				7: begin
						if(sz == 3 && &addr[23:0]) done3 <= 1;
						if(sz == 2 && &addr[22:0]) done3 <= 1;
						if(sz == 1 && &addr[21:0]) done3 <= 1;
						if(sz == 0 && &addr[20:0]) done3 <= 1;
						rd <= (cas_cmd == CMD_READ);
						if(done3) done2 <= 1;
					end
			endcase
		end
end

always @ (posedge clk) begin
	sdaddr <= sdaddr2;
	ba <= ba2;
	cmd <= cmd2;
	cs <= cs2;
	ready <= ready2;
	done <= done2;
end

altddio_out
#(
	.extend_oe_disable("OFF"),
	.intended_device_family("Cyclone V"),
	.invert_output("OFF"),
	.lpm_hint("UNUSED"),
	.lpm_type("altddio_out"),
	.oe_reg("UNREGISTERED"),
	.power_up_high("OFF"),
	.width(1)
)
sdramclk_ddr
(
	.datain_h(1'b0),
	.datain_l(1'b1),
	.outclock(clk),
	.dataout(DRAM_CLK),
	.aclr(1'b0),
	.aset(1'b0),
	.oe(1'b1),
	.outclocken(1'b1),
	.sclr(1'b0),
	.sset(1'b0)
);

endmodule
