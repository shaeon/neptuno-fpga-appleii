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
		

--------------------------------------------------------------------------------
--
--   FileName:         joystick_Sega_6_buttons.vhd
--   Dependencies:     
--   Design Software:  Quartus II 32-bit Version 18.1
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 06/29/2019 Fernando Mosquera
--     Initial Public Release
--
--   Based in "Joystick read with sega 6 button support" by Victor trucco for Multicore 2
--   https://gitlab.com/victor.trucco/Multicore/blob/master/_MC2_firmware/synth/multicore2/top.vhd
--    
--------------------------------------------------------------------------------
 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity sega_joystick is
	port (
		joy1_up_i			: in    std_logic;
		joy1_down_i			: in    std_logic;
		joy1_left_i			: in    std_logic;
		joy1_right_i		: in    std_logic;
		joy1_p6_i			: in    std_logic;
		joy1_p9_i			: in    std_logic;
		joy2_up_i			: in    std_logic;
		joy2_down_i			: in    std_logic;
		joy2_left_i			: in    std_logic;
		joy2_right_i		: in    std_logic;
		joy2_p6_i			: in    std_logic;
		joy2_p9_i			: in    std_logic;
		joyX_p7_o			: out   std_logic;  -- send to Select pin 7 of the Megadrive Joystick
		vga_hsync_n_s		: in    std_logic;
      joy1_o				: out   std_logic_vector(11 downto 0) := (others => '1'); -- MS ZYX CBA RLDU
		joy2_o				: out   std_logic_vector(11 downto 0) := (others => '1')  -- MS ZYX CBA RLDU
	);
end entity;

architecture rtl of sega_joystick is

--- Joystick read with sega 6 button support---------------------- 



-- joystick
	signal joy1_s			: std_logic_vector(11 downto 0) := (others => '1'); -- MS ZYX CBA RLDU	
	signal joy2_s			: std_logic_vector(11 downto 0) := (others => '1'); -- MS ZYX CBA RLDU	
	signal joyP7_s			: std_logic;
	 
 begin

process(vga_hsync_n_s)
		variable state_v : unsigned(7 downto 0) := (others=>'0');
		variable j1_sixbutton_v : std_logic := '0';
		variable j2_sixbutton_v : std_logic := '0';
	begin
		if falling_edge(vga_hsync_n_s) then
		
			state_v := state_v + 1;
			
			case state_v is
				-- joy_s format MXYZ SACB RLDU
			
				when X"00" =>  
					joyP7_s <= '0';
					
				when X"01" =>
					joyP7_s <= '1';

				when X"02" => 
					joy1_s(3 downto 0) <= joy1_right_i & joy1_left_i & joy1_down_i & joy1_up_i; -- R, L, D, U
					joy2_s(3 downto 0) <= joy2_right_i & joy2_left_i & joy2_down_i & joy2_up_i; -- R, L, D, U
					joy1_s(5 downto 4) <= joy1_p9_i & joy1_p6_i; -- C, B
					joy2_s(5 downto 4) <= joy2_p9_i & joy2_p6_i; -- C, B					
					joyP7_s <= '0';
					j1_sixbutton_v := '0'; -- Assume it's not a six-button controller
					j2_sixbutton_v := '0'; -- Assume it's not a six-button controller

				when X"03" =>
					joy1_s(7 downto 6) <= joy1_p9_i & joy1_p6_i; -- Start, A
					joy2_s(7 downto 6) <= joy2_p9_i & joy2_p6_i; -- Start, A
					joyP7_s <= '1';
			
				when X"04" =>  
					joyP7_s <= '0';

				when X"05" =>
					if joy1_right_i = '0' and joy1_left_i = '0' and joy1_down_i = '0' and joy1_up_i = '0' then 
						j1_sixbutton_v := '1'; --it's a six button
					end if;
					
					if joy2_right_i = '0' and joy2_left_i = '0' and joy2_down_i = '0' and joy2_up_i = '0' then 
						j2_sixbutton_v := '1'; --it's a six button
					end if;
					
					joyP7_s <= '1';
					
				when X"06" =>
					if j1_sixbutton_v = '1' then
						joy1_s(11 downto 8) <= joy1_right_i & joy1_left_i & joy1_down_i & joy1_up_i; -- Mode, X, Y e Z
					end if;
					
					if j2_sixbutton_v = '1' then
						joy2_s(11 downto 8) <= joy2_right_i & joy2_left_i & joy2_down_i & joy2_up_i; -- Mode, X, Y e Z
					end if;
					
					joyP7_s <= '0';

				when others =>
					joyP7_s <= '1';
					
			end case;

		end if;
	end process;
	
	joyX_p7_o <= joyP7_s;
	joy1_o <= joy1_s;
	joy2_o <= joy2_s;
	
	--------------------------- 
	
end architecture;	
	