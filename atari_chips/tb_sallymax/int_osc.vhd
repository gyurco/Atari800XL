LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;


ENTITY int_osc IS
PORT 
( 
	clkout : out std_logic;        -- clkout.clk
	oscena : in  std_logic := '0'  -- oscena.oscena
);
END int_osc;

ARCHITECTURE vhdl OF int_osc IS
  constant CLK0_PERIOD : time := 1 us / (55);
begin
	p_clk_gen_a : process
	begin
	clkout <= '1';
	wait for CLK0_PERIOD/2;
	clkout <= '0';
	wait for CLK0_PERIOD - (CLK0_PERIOD/2 );
	end process;
end vhdl;

