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
		"000000000001000100","000000000001000100","000000000001000101","000000000001000110","000000000001000111","000000000001001000","000000000001001001","000000000001001011","000000000001001110","000000000001010001","000000000001010110","000000000001011011","000000000001100010","000000000001101011","000000000001110110","000000000010000101","000000000010011000","000000000010101111","000000000011001101","000000000011110011","000000000100100011","000000000101011111","000000000110101010","000000001000000111","000000001001111000","000000001100000001","000000001110100100","000000010001100011","000000010100111110","000000011000110100","000000011101000001","000000100001011111","000000100110000111","000000101010101110","000000101111001100","000000110011011001","000000110111010000","000000111010101011","000000111101101011","000001000000001110","000001000010010111","000001000100001000","000001000101100101","000001000110110000","000001000111101100","000001001000011100","000001001001000010","000001001001100000","000001001001111000","000001001010001011","000001001010011001","000001001010100101","000001001010101110","000001001010110101","000001001010111010","000001001010111111","000001001011000010","000001001011000100","000001001011000110","000001001011001000","000001001011001001","000001001011001010","000001001011001011","000001001011001100","000001001011001100");

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


