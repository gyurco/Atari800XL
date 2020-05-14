---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_MISC.all;

ENTITY pokey_mixer IS
PORT 
( 
	CLK : IN STD_LOGIC;

	SUM : IN unsigned(5 downto 0);
	
	SATURATE : IN std_logic; -- pokey style curve or linear
	
	VOLUME_OUT_NEXT : OUT signed(15 downto 0)
);
END pokey_mixer;

ARCHITECTURE vhdl OF pokey_mixer IS
	signal volume_next : std_logic_vector(15 downto 0);

	signal y1 : signed(15 downto 0);
	signal y1_reg : signed(15 downto 0);
	signal y2 : signed(15 downto 0);
	signal ych : signed(15 downto 0);
	signal yadj_next : signed(31 downto 0);
	signal yadj_reg : signed(31 downto 0);

	signal b_in : signed(15 downto 0);
BEGIN
process(clk)
begin
	if (clk'event and clk='1') then
		YADJ_REG <= YADJ_NEXT;
		Y1_REG <= Y1;
	END IF;
END PROCESS;

	-- next state
 	process (sum, y1, y2, y1_reg, yadj_reg, saturate)
		type LOOKUP_TYPE is array (0 to 32) of signed(15 downto 0);
		variable lookup : LOOKUP_TYPE;
	begin
		-- replace with piecewise interp. Takes a mul unit but saves lookup space.

-- saturation on
		if (saturate='1') then
			lookup := (x"8000",x"921F",x"A58F",x"BA47",x"CF8E",x"E494",x"F8AE",x"0B67",x"1C84",x"2BF2",x"39B9",x"45ED",x"50A5",x"59F4",x"61E7",x"688B",x"6DEF",x"7227",x"7551",x"7793",x"791D",x"7A20",x"7ACF",x"7B54",x"7BCE",x"7C4E",x"7CD7",x"7D67",x"7DFE",x"7EA6",x"7F7E",x"7FFF",x"7FFF");
		else
-- saturation off
			lookup := (x"8000",x"8865",x"90CC",x"9932",x"A199",x"A9FF",x"B265",x"BACC",x"C332",x"CB99",x"D3FF",x"DC65",x"E4CC",x"ED32",x"F598",x"FDFF",x"0665",x"0ECC",x"1732",x"1F99",x"27FF",x"3065",x"38CC",x"4132",x"4999",x"51FF",x"5A65",x"62CC",x"6B32",x"7399",x"7BFF",x"7FFF",x"7FFF");
>>
		end if;

		y1 <= lookup(to_integer(sum(5 downto 1)));
		y2 <= lookup(to_integer(sum(5 downto 1))+1);

		ych <= y2-y1;

		volume_next <= std_logic_vector(yadj_reg(16 downto 1) + y1_reg);

        end process;

	B_in <= resize(signed('0'&sum(0 downto 0)),16);
	linterp_mult : entity work.mult_infer
	PORT MAP( A => signed(ych),
		  B => b_in,
		  RESULT => yadj_next);
	
	-- output
	volume_out_next <= signed(volume_next);
		
END vhdl;
