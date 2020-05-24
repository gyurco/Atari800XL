---------------------------------------------------------------------------
-- (c) 2020 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
--
-- Simple sigma delta based on https://aip.scitation.org/doi/pdf/10.1063/1.3530300
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_MISC.all;

ENTITY sigmadelta_2ndorder IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;

	AUDIN : IN UNSIGNED(15 downto 0);
	AUDOUT : OUT std_logic
);
END sigmadelta_2ndorder;

ARCHITECTURE vhdl OF sigmadelta_2ndorder IS	
	signal ttl1_next : signed(30 downto 0);
	signal ttl1_reg : signed(30 downto 0);
	signal ttl2_next : signed(30 downto 0);		
	signal ttl2_reg : signed(30 downto 0);		
	
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


--a1=	-2.00000;
--a2=	-10.00000;
--b1=	2.00000;
--c1=	2.00000;
--c2=	1.00000;
	process(audin,ttl1_reg,ttl2_reg)
		variable fb : signed(30 downto 0);
		variable ttl1_tmp : signed(30 downto 0);		
	begin
		fb:=(others=>'0');
		if ((not(ttl2_reg(30)) and or_reduce(std_logic_vector(ttl2_reg(30-1 downto 16))))='1') then
			fb(16) := '1';
		else			
			fb(16) := '0';
		end if;
	
		ttl1_tmp := ttl1_reg + signed("000"&audin&"0") - (fb(30-1 downto 0)&"0");
		ttl1_next <= ttl1_tmp;

		ttl2_next <= ttl2_reg + (ttl1_tmp(30-1 downto 0)&"0") - ((fb(30-1 downto 0)&"0")+(fb(30-3 downto 0)&"000"));	
		
		out_next <= fb(16);	
	end process;

	audout <= out_reg;
	
end vhdl;

