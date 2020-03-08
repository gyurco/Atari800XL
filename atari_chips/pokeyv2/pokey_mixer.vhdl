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

	SUM : IN STD_LOGIC_VECTOR(7 downto 0); -- unsigned
	
	VOLUME_OUT_NEXT : OUT STD_LOGIC_vector(15 downto 0) --signed
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
 	process (sum, y1, y2, y1_reg, yadj_reg)
		type LOOKUP_TYPE is array (0 to 32) of signed(15 downto 0);
		variable lookup : LOOKUP_TYPE;
		variable sum_saturated : std_logic_vector(5 downto 0);
	begin
		sum_saturated := sum(5 downto 0);
		if (sum(6)='1' or sum(7)='1') then
			sum_saturated := (others=>'1');
		end if;

		-- replace with piecewise interp. Takes a mul unit but saves lookup space.

		lookup := (x"86E8" ,x"9E40" ,x"B3E3" ,x"C7E3" ,x"DA52" ,x"EB42" ,x"FAC5" ,x"08ED" ,x"15CB" ,x"2172" ,x"2BF4" ,x"3562" ,x"3DCE" ,x"454B" ,x"4BEA" ,x"51BD" ,x"56D6" ,x"5B47" ,x"5F22" ,x"6278" ,x"655C" ,x"67E0" ,x"6A15" ,x"6C0D" ,x"6DDB" ,x"6F90" ,x"713E" ,x"72F7" ,x"74CD" ,x"76D2" ,x"7918" ,x"7BB0" ,x"7EAD");

		y1 <= lookup(to_integer(unsigned(sum_saturated(5 downto 1))));
		y2 <= lookup(to_integer(unsigned(sum_saturated(5 downto 1)))+1);

		ych <= y2-y1;

		volume_next <= std_logic_vector(yadj_reg(20 downto 5) + y1_reg);

		--case volume_sum(9 downto 0) is 
		--end case;
        end process;

	B_in <= signed("00000000000"&sum(0 downto 0)&"0000");
	linterp_mult : entity work.mult_infer
	PORT MAP( A => signed(ych),
		  B => b_in,
		  RESULT => yadj_next);
	
	-- output
	volume_out_next <= volume_next;
		
END vhdl;
