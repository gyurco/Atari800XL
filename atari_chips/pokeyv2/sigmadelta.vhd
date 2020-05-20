---------------------------------------------------------------------------
-- (c) 2020 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
--
-- Simple sigma delta based on https://aip.scitation.org/doi/pdf/10.1063/1.3526240
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_MISC.all;

ENTITY sigmadelta IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;

	AUDIN : IN UNSIGNED(15 downto 0);
	AUDOUT : OUT std_logic
);
END sigmadelta;

ARCHITECTURE vhdl OF sigmadelta IS	
	signal ttl1_next : signed(21 downto 0);
	signal ttl1_reg : signed(21 downto 0);
	signal ttl2_next : signed(21 downto 0);		
	signal ttl2_reg : signed(21 downto 0);		
	
	signal out_next : std_logic;
	signal out_reg : std_logic;
BEGIN

	process(clk,reset_n)
	begin
		if (reset_n='0') then
			ttl1_reg <= (others=>'0');
			ttl2_reg <= (others=>'0');
			out_reg <= '0';
		elsif (clk'event and clk='1')  then
			ttl1_reg <= ttl1_next;
			ttl2_reg <= ttl2_next;
			out_reg <= out_next;
		end if;
	end process;


	process(audin,ttl1_reg,ttl2_reg)
		variable fb : signed(21 downto 0);
		variable ttl1_tmp : signed(21 downto 0);
	begin
		if (ttl2_reg(21) = '1') then
			fb := to_signed(0,22);
		else			
			fb := to_signed(65536,22);
		end if;
	
		ttl1_tmp := ttl1_reg + signed("0000"&audin) - fb;
		ttl1_next <= ttl1_tmp;

		ttl2_next <= ttl2_reg + ttl1_next - fb;	
		
		out_next <= not(ttl2_reg(21));
	end process;

	audout <= out_reg;
	
end vhdl;

