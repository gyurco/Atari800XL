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

	SUM : IN unsigned(11 downto 0);
	
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
		variable sum_saturated : unsigned(7 downto 0);
	begin
		sum_saturated := sum(7 downto 0);
		if (or_reduce(std_logic_vector(sum(11 downto 8)))='1') then
			sum_saturated := (others=>'1');
		end if;

		-- replace with piecewise interp. Takes a mul unit but saves lookup space.

-- saturation on
		if (saturate='1') then
			lookup := (x"86E8" ,x"9E40" ,x"B3E3" ,x"C7E3" ,x"DA52" ,x"EB42" ,x"FAC5" ,x"08ED" ,x"15CB" ,x"2172" ,x"2BF4" ,x"3562" ,x"3DCE" ,x"454B" ,x"4BEA" ,x"51BD" ,x"56D6" ,x"5B47" ,x"5F22" ,x"6278" ,x"655C" ,x"67E0" ,x"6A15" ,x"6C0D" ,x"6DDB" ,x"6F90" ,x"713E" ,x"72F7" ,x"74CD" ,x"76D2" ,x"7918" ,x"7BB0" ,x"7EAD");
		else
-- saturation off
			lookup := (x"8000", x"87FF", x"8FFF", x"97FF", x"9FFF", x"A7FF", x"AFFF", x"B7FF", x"BFFF", x"C7FF", x"CFFF", x"D7FF", x"DFFF", x"E7FF", x"EFFF", x"F7FF", x"FFFE", x"07FF", x"0FFF", x"17FF", x"1FFF", x"27FF", x"2FFF", x"37FF", x"3FFF", x"47FF", x"4FFF", x"57FF", x"5FFF", x"67FF", x"6FFF", x"77FF", x"7FFF");
		end if;

		y1 <= lookup(to_integer(sum_saturated(7 downto 3)));
		y2 <= lookup(to_integer(sum_saturated(7 downto 3))+1);

		ych <= y2-y1;

		volume_next <= std_logic_vector(yadj_reg(18 downto 3) + y1_reg);

		--case volume_sum(9 downto 0) is 
		--end case;
        end process;

	B_in <= resize(signed('0'&sum(2 downto 0)),16);
	linterp_mult : entity work.mult_infer
	PORT MAP( A => signed(ych),
		  B => b_in,
		  RESULT => yadj_next);
	
	-- output
	volume_out_next <= signed(volume_next);
		
END vhdl;
