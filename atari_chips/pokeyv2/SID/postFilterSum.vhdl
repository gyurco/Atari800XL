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

	VOLUME : IN STD_LOGIC_VECTOR(3 downto 0);

	CHANNEL_OUT : OUT STD_LOGIC_VECTOR(15 downto 0)
);
END SID_postFilterSum;

ARCHITECTURE vhdl OF SID_postFilterSum IS
	signal mult_reg: unsigned(26 downto 0);
	signal mult_next: unsigned(26 downto 0);
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
	process(direct,filter_lp,filter_bp,filter_hp,filter_sel,volume)
		variable sum : unsigned(17 downto 0);
		variable post_volume : unsigned(35 downto 0);

		variable filter_sel0ext : unsigned(15 downto 0);
		variable filter_sel1ext : unsigned(15 downto 0);
		variable filter_sel2ext : unsigned(15 downto 0);

		variable volume_adj : unsigned(5 downto 0);
	begin
		filter_sel0ext := (others=>filter_sel(0));
		filter_sel1ext := (others=>filter_sel(1));
		filter_sel2ext := (others=>filter_sel(2));

		sum := 
			   resize((unsigned(filter_lp) and filter_sel0ext),18) +
			   resize((unsigned(filter_bp) and filter_sel1ext),18) +
			   resize((unsigned(filter_hp) and filter_sel2ext),18) +
			   resize(unsigned(direct),18);

		--filter_lp -> up to 75%
		--filter_lp -> up to 75%
		--filter_lp -> up to 75%
		--direct -> up to 75%
		-- therefore: total 3*, though if max filter level then diect=0, so total 2.25
		-- so *1.75 to get back up to full range...
		volume_adj:= unsigned("00"&volume) + unsigned("0"&volume&"0") + unsigned(volume&"00");

		-- Then apply volume
		mult_next <= sum * resize(unsigned(volume_adj),9);
	end process;	

	-- output
	channel_out <= std_logic_vector(mult_reg(23 downto 8));
		
END vhdl;
