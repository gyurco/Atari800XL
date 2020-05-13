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

ENTITY SID_preFilterSum IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;
	ENABLE : IN STD_LOGIC;
	
	CHANNEL_A : IN STD_LOGIC_VECTOR(15 downto 0);
	CHANNEL_B : IN STD_LOGIC_VECTOR(15 downto 0);
	CHANNEL_C : IN STD_LOGIC_VECTOR(15 downto 0);
	CHANNEL_C_CUTDIRECT : IN STD_LOGIC;
	FILTER_EN : IN STD_LOGIC_VECTOR(2 downto 0);

	PREFILTER_OUT : OUT STD_LOGIC_VECTOR(15 downto 0); 
	DIRECT_OUT : OUT STD_LOGIC_VECTOR(15 downto 0)     -- Only chdis/4 amplitude
);
END SID_preFilterSum;

ARCHITECTURE vhdl OF SID_preFilterSum IS
	signal prefilter_reg: std_logic_vector(15 downto 0);
	signal prefilter_next: std_logic_vector(15 downto 0);
	signal direct_reg: std_logic_vector(15 downto 0);
	signal direct_next: std_logic_vector(15 downto 0);
BEGIN
	-- register
	process(clk, reset_n)
	begin
		if (reset_n = '0') then
			prefilter_reg <= (others=>'0');
			direct_reg <= (others=>'0');
		elsif (clk'event and clk='1') then
			prefilter_reg <= prefilter_next;
			direct_reg <= direct_next;
		end if;
	end process;
	
	-- next state
	process(prefilter_reg,direct_reg,enable,channel_a,channel_b,channel_c,channel_c_cutdirect)
		variable sum_tmp : unsigned(17 downto 0);
	begin
		prefilter_next <= prefilter_reg;
		direct_next <= direct_reg;
		
		if (enable = '1') then
			sum_tmp := 
				   resize((unsigned(channel_a) and (others=>(filter_en(0)))),18) + 
				   resize((unsigned(channel_b) and (others=>(filter_en(1)))),18) + 
				   resize((unsigned(channel_c) and (others=>(filter_en(2)))),18);
			prefilter_next <= std_logic_vector(sum_tmp(17 downto 2));

			sum_tmp := 
				   resize((unsigned(channel_a) and (others=>(not(filter_en(0))))),18) + 
				   resize((unsigned(channel_b) and (others=>(not(filter_en(1))))),18) + 
				   resize((unsigned(channel_c) and (others=>(not(channel_c_cutdirect) and not(filter_en(2))))),18);
			direct_next <= std_logic_vector(sum_tmp(17 downto 2));
		end if;
	end process;	
		
	-- output
	prefilter_out <= prefilter_reg;
	direct_out <= direct_reg;
		
END vhdl;
