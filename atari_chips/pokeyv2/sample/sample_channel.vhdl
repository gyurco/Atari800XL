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
use IEEE.STD_LOGIC_MISC.all;

ENTITY sample_channel IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;
	ENABLE : IN STD_LOGIC;

	start_addr : IN std_logic_vector(7 downto 0);
	len : IN std_logic_vector(11 downto 0);
	period : IN std_logic_vector(11 downto 0);
	
	addr : OUT STD_LOGIC_VECTOR(15 downto 0);
	irq : OUT STD_LOGIC
);
END sample_channel;

ARCHITECTURE vhdl OF sample_channel IS
	signal pointer_reg : unsigned(15 downto 0);
	signal pointer_next : unsigned(15 downto 0);
	signal remaining_reg : unsigned(11 downto 0);
	signal remaining_next : unsigned(11 downto 0);
	signal periodpos_reg : unsigned(11 downto 0);
	signal periodpos_next : unsigned(11 downto 0);

BEGIN
	-- register
	process(clk,reset_n)
	begin
		if (reset_n='0') then
			pointer_reg <= (others=>'0');
			remaining_reg <= (others=>'0');
			periodpos_reg <= (others=>'0');
		elsif (clk'event and clk='1') then
			pointer_reg <= pointer_next;
			remaining_reg <= remaining_next;
			periodpos_reg <= periodpos_next;
		end if;
	end process;

	process(start_addr, len, period,
		pointer_reg, remaining_reg, periodpos_reg,
		enable
		)
	begin
		pointer_next <= pointer_reg;
		remaining_next <= remaining_reg;
		periodpos_next <= periodpos_reg;
		irq <= '0';
	
		if (enable='1') then
			periodpos_next <= periodpos_reg-1;
			if (or_reduce(std_logic_vector(periodpos_reg))='0') then
				periodpos_next <= unsigned(period);
				pointer_next <= pointer_reg+1;
				remaining_next <= remaining_reg-1;
				if (or_reduce(std_logic_vector(remaining_reg))='0') then
					pointer_next(15 downto 8) <= unsigned(start_addr);
					pointer_next(7 downto 0) <= (others=>'0');
					remaining_next <= unsigned(len);
	
					irq <= '1';
				end if;
			end if;
		end if;
	end process;

	addr <= std_logic_vector(pointer_reg);
	
end vhdl;

