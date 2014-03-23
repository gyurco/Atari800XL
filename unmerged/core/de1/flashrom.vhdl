---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY flashrom IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;

	ADDRESS : IN STD_LOGIC_VECTOR(21 DOWNTO 0);
	
	REQUEST : IN STD_LOGIC;

	-- takes 90+ns, wait states handled here
	
	-- Flash interface
	FLASH_D : IN STD_LOGIC_VECTOR(7 downto 0);
	
	FLASH_CE_N : OUT STD_LOGIC;
	FLASH_OE_N : OUT STD_LOGIC;
	FLASH_WE_N : OUT STD_LOGIC;
	FLASH_RESET_N : OUT STD_LOGIC;
	FLASH_ADDRESS : OUT STD_LOGIC_VECTOR(21 downto 0);
	
	-- Provide data to system
	DOUT : OUT STD_LOGIC_VECTOR(7 downto 0);
	COMPLETE : OUT STD_LOGIC
);

END flashrom;

ARCHITECTURE vhdl OF flashrom IS
	signal complete_next : std_logic_vector(4 downto 0); --56MHZ, 17ns per cycle.
	signal complete_reg : std_logic_vector(4 downto 0);
BEGIN
	-- registers
	process(clk,reset_n)
	begin
		if (reset_n = '0') then
			complete_reg <= (others=>'0');
		elsif (clk'event and clk='1') then
			complete_reg <= complete_next;
		end if;
	end process;
	
	complete_next <= request&complete_reg(complete_reg'left downto 1);

	FLASH_CE_N <= '0';
	FLASH_OE_N <= '0';
	FLASH_WE_N <= '1';
	FLASH_RESET_N <= RESET_N;
	FLASH_ADDRESS <= ADDRESS;
	
	DOUT <= FLASH_D;
	COMPLETE <= complete_reg(0);
END vhdl;