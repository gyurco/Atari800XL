---------------------------------------------------------------------------
-- (c) 2018 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_MISC.all;

ENTITY correct_duty IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;
	CLKIN : IN STD_LOGIC;
	CLKOUT : OUT STD_LOGIC;
	CLKOUT_EVENT : OUT STD_LOGIC
);
END correct_duty;

ARCHITECTURE vhdl OF correct_duty IS
	signal cnt_next : std_logic_vector(7 downto 0);
	signal cnt_reg : std_logic_vector(7 downto 0);
	signal half_next : std_logic_vector(6 downto 0);
	signal half_reg : std_logic_vector(6 downto 0);

	signal sync_next : std_logic;
	signal sync_reg : std_logic;

	signal clkout_next : std_logic;
	signal clkout_reg : std_logic;
	signal clkout_event_next : std_logic;
	signal clkout_event_reg : std_logic;
begin
	-- register
	process(clk,reset_n)
	begin
		if (reset_n='0') then
			cnt_reg <= (others=>'0');
			half_reg <= (others=>'0');
			sync_reg <= '0';
			clkout_reg <= '0';
			clkout_event_reg <= '0';
		elsif (clk'event and clk='1') then						
			cnt_reg <= cnt_next;	
			half_reg <= half_next;	
			sync_reg <= sync_next;	
			clkout_reg <= clkout_next;
			clkout_event_reg <= clkout_event_next;
		end if;
	end process;

	in_sync : entity work.synchronizer	
		port map (clk=>clk, raw=>CLKIN, sync=>SYNC_NEXT);	

	process(cnt_reg,half_reg,sync_next,sync_reg,CLKOUT_REG)
	begin
		cnt_next <= std_logic_vector(unsigned(cnt_reg)+1);
		half_next <= std_logic_vector(unsigned(half_reg)-1);

		CLKOUT_EVENT_NEXT<='0';
		CLKOUT_NEXT <= CLKOUT_REG;

		if (sync_reg ='0' and sync_next='1') then
			cnt_next <= (others=>'0');
			half_next <= cnt_reg(7 downto 1);
			CLKOUT_EVENT_NEXT <='1';
			CLKOUT_NEXT <= '1';
		end if;

		if (or_reduce(half_reg)='0') then
			CLKOUT_NEXT <= '0';
			CLKOUT_EVENT_NEXT<='1';
		end if;
	end process;

	CLKOUT <= CLKOUT_REG;
	CLKOUT_EVENT <= CLKOUT_EVENT_REG;
	
end vhdl;


