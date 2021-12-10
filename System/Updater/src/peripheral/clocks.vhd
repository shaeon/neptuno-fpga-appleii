--
-- Multicore 2 / Multicore 2+
--
-- Copyright (c) 2017-2020 - Victor Trucco
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- You are responsible for any legal issues arising from your use of this code.
--
		

--
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clocks is
port (
	clk_28		: in    std_logic;		-- 28 MHz clock input
	nReset		: in    std_logic;

	clk_video	: out   std_logic;		--   14 MHz clock out for ULA
	clk_psg		: out   std_logic			-- 1.75 MHz clock out for AY (asynchronous)
);
end clocks;

architecture clocks_arch of clocks is
	signal counter	 : unsigned(3 downto 0);
begin

	process(nReset, clk_28)
	begin
		if nReset = '0' then
			counter <= (others => '0');
		elsif falling_edge(clk_28) then
			counter <= counter + 1;
		end if;
	end process;

	-- counter(0) = /2	= 14
	-- counter(1) = /4	= 7
	-- counter(2) = /8	= 3.5
	-- counter(3) = /16	= 1.75
	-- counter(4) = /32
	-- counter(5) = /64
	clk_video <= counter(0);
	clk_psg   <= '1' when counter(3 downto 0) = "1110" else '0';

end clocks_arch;
