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

ENTITY SID_postFilterSum IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;
	
	DIRECT : IN STD_LOGIC_VECTOR(15 downto 0);
	FILTER_LP : IN STD_LOGIC_VECTOR(15 downto 0);
	FILTER_BP : IN STD_LOGIC_VECTOR(15 downto 0);
	FILTER_HP : IN STD_LOGIC_VECTOR(15 downto 0);
	FILTER_SEL : IN STD_LOGIC_VECTOR(2 downto 0);

	VOLUME : IN STD_LOGIC_VECTOR(15 downto 0);

	CHANNEL_OUT : OUT STD_LOGIC_VECTOR(15 downto 0)
);
END SID_postFilterSum;

ARCHITECTURE vhdl OF SID_postFilterSum IS
	signal mult_reg: std_logic_vector(35 downto 0);
	signal mult_next: std_logic_vector(35 downto 0);
BEGIN
	-- register
	process(clk, reset_n)
	begin
		if (reset_n = '0') then
			mult_reg <= (others=>'0');
		elsif (clk'event and clk='1') then
			mult_reg <= mult_next;
		end if;
	end process;
	
	-- next state
	process(channel_a,channel_b,channel_c,volume)
		variable sum_4 : unsigned(17 downto 0);
		variable sum_2 : unsigned(17 downto 0);
		variable sum_1 : unsigned(17 downto 0);
		variable sum_total : unsigned(17 downto 0);
		variable post_volume : unsigned(35 downto 0);
	begin
		sum_1 := 
			   resize((unsigned(filter_lp) and (others=>(filter_sel(0)))),18) + 
			   resize((unsigned(filter_bp) and (others=>(filter_sel(1)))),18) + 
			   resize((unsigned(filter_hp) and (others=>(filter_sel(2)))),18) +
			   resize(unsigned(direct),18);

		--filter_lp -> up to 75%
		--filter_lp -> up to 75%
		--filter_lp -> up to 75%
		--direct -> up to 75%
		-- therefore: total 3*, though if max filter level then diect=0, so total 2.25
		-- so *1.75 to get back up to full range...
		sum_4 := "00"&sum_1(17 downto 2);
		sum_2 := "0"&sum_1(17 downto 2)&"0";
		sum_total:= sum_1 + sum_2 + sum_4;

		-- Then apply volume
		mult_next := unsigned(sum_total) * resize(unsigned(volume),18);
	end process;	

	-- output
	channel_out <= mult_reg(21 downto 6);
		
END vhdl;
