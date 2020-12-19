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

ENTITY SID_f_distortion IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;

	STATE : IN SIGNED(17 downto 0); -- Voltage of filter, which should not impact F
	F_RAW : IN UNSIGNED(17 downto 0); -- Wanted F, scaled to same units as voltage of filter
	F_DISTORTED : OUT UNSIGNED(17 downto 0) --Result F
);
END SID_f_distortion;

ARCHITECTURE vhdl OF SID_f_distortion IS
	signal y1 : unsigned(17 downto 0);
	signal y1_reg : unsigned(17 downto 0);
	signal y2 : unsigned(17 downto 0);
	signal ych : unsigned(17 downto 0);
	signal yadj_next : unsigned(35 downto 0);
	signal yadj_reg : unsigned(35 downto 0);
	signal ychpos : unsigned(17 downto 0);
	signal f_distorted_next : unsigned(17 downto 0);
begin
	-- register
	process(clk,reset_n)
	begin
		if (reset_n='0') then
			y1_reg <= (others=>'0');
			yadj_reg <= (others=>'0');
		elsif (clk'event and clk='1') then						
			y1_reg <= y1;
			yadj_reg <= yadj_next;
		end if;
	end process;

 	process (state,f_raw, y1, y2, ych, ychpos, y1_reg, yadj_reg)
		type LOOKUP_TYPE is array (0 to 64) of unsigned(17 downto 0);
		variable lookup : LOOKUP_TYPE;

		variable pos: unsigned(18 downto 0);
	begin
		-- assumption: /home/markw/fpga/svn/jsidplay2-code/jsidplay2/src/main/java/builder/resid/residfp/Filter6581.java
		pos := unsigned(not(state(17))&state(16 downto 0)) + resize(f_raw,19);
		if (pos(18)='1') then
			pos(17 downto 0) := (others=>'1');
		end if;

		-- replace with piecewise interp. Takes a mul unit but saves lookup space.
		lookup := (
		"000000000111111001","000000000111111101","000000001000000000","000000001000000110","000000001000001110","000000001000010101","000000001000100010","000000001000110010","000000001001000010","000000001001011100","000000001001111110","000000001010100000","000000001011010110","000000001100011101","000000001101100100","000000001111010110","000000010001101000","000000010011111100","000000010111100101","000000011100010000","000000100000111011","000000101000001100","000000110001011000","000000111010011001","000001001000000101","000001011000110111","000001101000110010","000001111111111111","000010011010111011","000010110011000010","000011010011111101","000011110111001011","000100011011100111","000100111000110010","000101011100001101","000101111101011011","000110010101110101","000110110001001011","000111001000110011","000111011001000001","000111101010001011","000111111000001101","001000000001011011","001000001010110111","001000010010010100","001000010111000111","001000011011111011","001000011111101010","001000100010000010","001000100100011001","001000100110001110","001000100111011000","001000101000100000","001000101001011000","001000101001111100","001000101010011110","001000101010111001","001000101011001010","001000101011011010","001000101011100111","001000101011101111","001000101011110111","001000101011111101","001000101100000001","001000101100000100");

		ychpos <= resize(pos(11 downto 0),18);
		y1 <= lookup(to_integer(pos(17 downto 12)));
		y2 <= lookup(to_integer(pos(17 downto 12))+1);

		ych <= y2-y1;

		yadj_next <= ych * ychpos;

		f_distorted_next <= y1_reg + resize(yadj_reg(30 downto 12),18);
        end process;

	-- output
	f_distorted <= f_distorted_next;
end vhdl;


