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

	STATE : IN SIGNED(17 downto 1); -- Voltage of filter, which should not impact F
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
		type LOOKUP_TYPE is array (0 to 38) of unsigned(17 downto 0);
		variable lookup : LOOKUP_TYPE;

		variable pos: unsigned(17 downto 0);
	begin
		-- assumption: /home/markw/fpga/svn/jsidplay2-code/jsidplay2/src/main/java/builder/resid/residfp/Filter6581.java
		pos := unsigned('0'&not(state(17))&state(16 downto 1)) + f_raw;
		if (pos(17 downto 12) > to_unsigned(37,6)) then
			pos(17 downto 12) := to_unsigned(37,6);
			pos(11 downto 0) := (others=>'1');
		end if;

		-- replace with piecewise interp. Takes a mul unit but saves lookup space.
		lookup := (
		"000000000001000100","000000000001000101","000000000001000110","000000000001001000","000000000001001011","000000000001001111","000000000001010110","000000000001100000","000000000001110000","000000000010001000","000000000010101011","000000000011100000","000000000100101111","000000000110100001","000000001001000101","000000001100101001","000000010001011000","000000010111010111","000000011110011010","000000100110000111","000000101101110011","000000110100110111","000000111010110110","000000111111100110","000001000011001001","000001000101101110","000001000111100001","000001001000101111","000001001001100100","000001001010001000","000001001010100000","000001001010101111","000001001010111010","000001001011000001","000001001011000101","000001001011001000","000001001011001010","000001001011001011","000001001011001100");

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


