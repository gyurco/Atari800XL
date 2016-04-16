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

ENTITY synchronizer_vector IS
GENERIC
(
	BITS : IN integer :=1
);
PORT 
( 
	CLK : IN STD_LOGIC;
	RAW : IN STD_LOGIC_VECTOR(BITS-1 downto 0);
	SYNC : OUT STD_LOGIC_VECTOR(BITS-1 downto 0)
);
END synchronizer_vector;

ARCHITECTURE vhdl OF synchronizer_vector IS
	signal a_next : std_logic_vector(BITS-1 downto 0);
	signal a_reg : std_logic_vector(BITS-1 downto 0);

	signal b_next : std_logic_vector(BITS-1 downto 0);
	signal b_reg : std_logic_vector(BITS-1 downto 0);

	signal c_next : std_logic_vector(BITS-1 downto 0);
	signal c_reg : std_logic_vector(BITS-1 downto 0);

begin
	-- register
	process(clk)
	begin
		if (clk'event and clk='1') then						
			a_reg <= a_next;	
			b_reg <= b_next;	
			c_reg <= c_next;	
		end if;
	end process;

	a_next <= raw;
	b_next <= a_reg;
	c_next <= b_reg;
	
	SYNC <= c_reg;

end vhdl;


