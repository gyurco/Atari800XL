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
		"000001001001101011","000001010011001000","000001011101110000","000001101001101110","000001110111001011","000010000110010001","000010010111001101","000010101010001011","000010111111011011","000011010111001100","000011110001101101","000100001111010001","000100110000001010","000101010100101011","000101111101001001","000110101001111000","000111011011001100","001000010001011000","001001001100101111","001010001101100011","001011010100000001","001100100000010100","001101110010100011","001111001010101111","010000101000110101","010010001100101001","010011110101111000","010101100100001010","010111010110111100","011001001101100111","011011000111011010","011101000011100000","011111000001000001","100000111111000001","100010111100100010","100100111000101000","100110110010011011","101000101001000101","101010011011111000","101100001010001001","101101110011011001","101111010111001100","110000110101010010","110010001101011110","110011011111101101","110100101100000000","110101110010011101","110110110011010001","110111101110101000","111000100100110100","111001010110001000","111010000010110110","111010101011010100","111011001111110101","111011110000101110","111100001110010010","111100101000110011","111101000000100011","111101010101110011","111101101000110010","111101111001101110","111110001000110100","111110010110010000","111110100010001110","111110101100110111");

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


