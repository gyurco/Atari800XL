---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY i2sslave IS
PORT 
( 
	CLK : IN STD_LOGIC;
	
	BCLK : IN STD_LOGIC;
	DACLRC : IN STD_LOGIC;
	
	LEFT_IN : in std_logic_vector(15 downto 0);
	RIGHT_IN : in std_logic_vector(15 downto 0);
	
	MCLK_2 : OUT STD_LOGIC;
	DACDAT : OUT STD_LOGIC
);
END i2sslave;

ARCHITECTURE vhdl OF i2sslave IS
	signal bclk_reg : std_logic;
	signal bclk_last_reg : std_logic;
	signal daclrc_reg : std_logic;
	signal daclrc_last_reg : std_logic;
	
	signal shiftreg_reg : std_logic_vector(15 downto 0);
	signal shiftreg_next : std_logic_vector(15 downto 0);
	
	signal CLK_FAKE : std_logic;
BEGIN
	MCLK_2 <= CLK_FAKE; -- bad practice, but pll out of...
	
	-- Data read on bclk low->high transition
	-- daclrc is set on bclk high->low transition
	
	-- register inputs
	process(clk)
	begin
		if (clk'event and clk='1') then
			CLK_FAKE <= not(CLK_FAKE);
		end if;
	end process;
	
	process(CLK_FAKE)
	begin	
		if (CLK_FAKE'event and CLK_FAKE='1') then
			bclk_reg <= bclk;
			bclk_last_reg <= bclk_reg;
			daclrc_reg <= daclrc;
			daclrc_last_reg <= daclrc_reg;
			shiftreg_reg <= shiftreg_next;
		end if;
	end process;
	
	-- sample on change to daclrc, shift out bit if required
	process(daclrc_reg,daclrc_last_reg,bclk_reg,shiftreg_reg,left_in,right_in,bclk_last_reg)
		variable reload : std_logic;
	begin
		reload := '0';
		shiftreg_next <= shiftreg_reg;
		
		if (daclrc_reg = '1' and daclrc_last_reg = '0') then
			shiftreg_next <= right_in;
			reload := '1';
		end if;
		
		if (daclrc_reg = '0' and daclrc_last_reg = '1') then
			shiftreg_next <= left_in;
			reload := '1';
		end if;
		
		if (bclk_reg = '0' and bclk_last_reg = '1' and reload='0') then
				shiftreg_next <= shiftreg_reg(14 downto 0)&'0';
		end if;
			
	end process;
	
	DACDAT <= shiftreg_reg(15);
END vhdl;