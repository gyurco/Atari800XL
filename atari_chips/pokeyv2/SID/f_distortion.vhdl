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
		"000000000111111001","000000000111111100","000000001000000001","000000001000000110","000000001000001101","000000001000010110","000000001000100010","000000001000110001","000000001001000100","000000001001011101","000000001001111100","000000001010100100","000000001011011000","000000001100011010","000000001101101111","000000001111011011","000000010001100101","000000010100010100","000000010111110010","000000011100001100","000000100001101110","000000101000101011","000000110001010100","000000111100000001","000001001001000110","000001011000111011","000001101011110010","000010000001111000","000010011011001111","000010110111101100","000011010110110100","000011110111111000","000100011001111111","000100111100000110","000101011101001010","000101111100010001","000110011000101111","000110110010000110","000111001000001100","000111011011000011","000111101010110111","000111110111111101","001000000010101001","001000001011010011","001000010010001111","001000010111110010","001000011100001011","001000011111101010","001000100010011001","001000100100100011","001000100110001111","001000100111100011","001000101000100101","001000101001011001","001000101010000001","001000101010100001","001000101010111010","001000101011001101","001000101011011100","001000101011100111","001000101011110000","001000101011110111","001000101011111101","001000101100000001","001000101100000101");

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


