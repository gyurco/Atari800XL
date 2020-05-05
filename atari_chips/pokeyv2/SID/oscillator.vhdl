---------------------------------------------------------------------------
-- (c) 2020 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY SID_oscillator IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;
	ENABLE : IN STD_LOGIC;
	
	BITS_OUT : OUT STD_LOGIC_VECTOR(11 downto 0);
	
	SYNC_IN : IN STD_LOGIC;
	SYNC_OUT : OUT STD_LOGIC;

	ADJ : IN STD_LOGIC_VECTOR(15 downto 0);
END SID_oscillator;

ARCHITECTURE vhdl OF SID_oscillator IS
	signal count_reg: unsigned(23 downto 0);
	signal count_next: unsigned(23 downto 0);
BEGIN
	-- register
	process(clk, reset_n)
	begin
		if (reset_n = '0') then
			count_reg <= (others=>'0');
		elsif (clk'event and clk='1') then
			count_reg <= count_next;
		end if;
	end process;
	
	-- next state
	process(count_reg,enable,adj,sync_in)
		variable count_inc : std_logic_vector(23 downto 0);
	begin
		count_next <= count_reg;
		sync_out <= '0';

		if (enable = '1') then
			count_inc := count_reg+unsigned(adj);

			sync_out <= count_inc(23) xor count_reg(23);

			if (sync_in='1') then
				count_next <= (others=>'0');
			else
				count_next <= count_inc;
			end if;
		end if;
	end process;	

	--output
	bits_out <= count_reg(23 downto 12);
		
END vhdl;
