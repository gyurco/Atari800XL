LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;


ENTITY pll_veronica IS
PORT 
( 
	inclk0 : IN STD_LOGIC;
	c0 : OUT STD_LOGIC;
	c1 : OUT STD_LOGIC;
	locked : OUT STD_LOGIC
);
END pll_veronica;

ARCHITECTURE vhdl OF pll_veronica IS
  constant CLK0_PERIOD : time := 1 us / (14);
  constant CLK1_PERIOD : time := 1 us / (14*7);
begin
	p_clk_gen_a : process
	begin
	c0 <= '1';
	wait for CLK0_PERIOD/2;
	c0 <= '0';
	wait for CLK0_PERIOD - (CLK0_PERIOD/2 );
	end process;

	p_clk_gen_b : process
	begin
	c1 <= '1';
	wait for CLK1_PERIOD/2;
	c1 <= '0';
	wait for CLK1_PERIOD - (CLK1_PERIOD/2 );
	end process;

	locked <= '0', '1' after 2000ns;
end vhdl;

