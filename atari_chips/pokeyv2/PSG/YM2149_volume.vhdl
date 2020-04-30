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

ENTITY YM2149_volume IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;
	ENABLE : IN STD_LOGIC;
	
	CHANNEL : IN STD_LOGIC;
	FIXED : IN STD_LOGIC_VECTOR(4 downto 0);
	ENVELOPE : IN STD_LOGIC_VECTOR(3 downto 0);
	
	VOL_OUT : OUT STD_LOGIC_VECTOR(3 downto 0)
);
END YM2149_volume;

ARCHITECTURE vhdl OF YM2149_volume IS
	signal vol_reg: std_logic_vector(3 downto 0);
	signal vol_next: std_logic_vector(3 downto 0);
BEGIN
	-- register
	process(clk, reset_n)
	begin
		if (reset_n = '0') then
			vol_reg <= (others=>'0');
		elsif (clk'event and clk='1') then
			vol_reg <= vol_next;
		end if;
	end process;
	
	-- next state
	process(vol_reg,enable,channel,fixed)
	begin
		vol_next <= vol_reg;
		
		if (enable = '1') then
			if (fixed(4)='0') then --fixed
				vol_next <= fixed(3 downto 0);
			else
				vol_next <= envelope;
			end if;
		end if;
	end process;	
		
	-- output
	vol_out <= vol_reg;
		
END vhdl;
