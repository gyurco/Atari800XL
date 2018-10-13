-- (c) 2017 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

LIBRARY work;

ENTITY gpio_debug IS 
	PORT
	(
		CLK :  IN  STD_LOGIC;
		RESET_N :  IN  STD_LOGIC;

		PBI_DEBUG : IN STD_LOGIC_VECTOR(31 downto 0);
		PBI_DEBUG_READY : IN STD_LOGIC;

		DATA_OUT :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		CLK_OUT :  OUT  STD_LOGIC
	);
END gpio_debug;

ARCHITECTURE vhdl OF gpio_debug IS 
	signal cycle_reg : std_logic_vector(4 downto 0);
	signal cycle_next : std_logic_vector(4 downto 0);

	signal pbi_debug_reg : std_logic_vector(31 downto 0);
	signal pbi_debug_next : std_logic_vector(31 downto 0);

	signal data_out_reg : std_logic_vector(7 downto 0);
	signal data_out_next : std_logic_vector(7 downto 0);

	signal clk_out_reg : std_logic;
	signal clk_out_next : std_logic;
	
BEGIN

	process(clk,reset_n)
	begin
		if (reset_n='0') then
			pbi_debug_reg <= (others=>'0');
			cycle_reg <= (others=>'0');
			data_out_reg <= (others=>'0');
			clk_out_reg <= '0';
		elsif (clk'event and clk='1') then
			pbi_debug_reg <= pbi_debug_next;
			cycle_reg <= cycle_next;
			data_out_reg <= data_out_next;
			clk_out_reg <= clk_out_next;
		end if;
	end process;

	process(cycle_reg,pbi_debug_ready,pbi_debug,pbi_debug_reg,data_out_reg,clk_out_reg)
	begin	
		pbi_debug_next <= pbi_debug_reg;
		cycle_next <= std_logic_vector(unsigned(cycle_reg)+1);
		data_out_next <= data_out_reg;
		clk_out_next <= clk_out_reg;

		if (pbi_debug_ready='1') then
			cycle_next <= (others=>'0');
			pbi_debug_next <= pbi_debug;
		end if;

		case cycle_reg is
		when "0"&x"0" => 
			data_out_next <= pbi_debug_reg(7 downto 0);
		when "0"&x"4" => 
			clk_out_next <= not(clk_out_reg);
		when "0"&x"8" => 
			data_out_next <= pbi_debug_reg(15 downto 8);
		when "0"&x"c" => 
			clk_out_next <= not(clk_out_reg);
		when "1"&x"0" => 
			data_out_next <= pbi_debug_reg(23 downto 16);
		when "1"&x"4" => 
			clk_out_next <= not(clk_out_reg);
		when "1"&x"8" => 
			data_out_next <= pbi_debug_reg(31 downto 24);
		when "1"&x"c" => 
			clk_out_next <= not(clk_out_reg);
		when others =>
		end case;

	end process;

	data_out <= data_out_reg;
	clk_out <= clk_out_reg;

END vhdl;

