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

ENTITY PSG_envelope IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;
	ENABLE : IN STD_LOGIC;
	
	COUNT_RESET : IN STD_LOGIC;
	SHAPE : IN STD_LOGIC_VECTOR(3 downto 0);
	PERIOD : IN STD_LOGIC_VECTOR(15 downto 0);
	
	ENVELOPE : OUT STD_LOGIC_VECTOR(3 downto 0)
);
END PSG_envelope;

ARCHITECTURE vhdl OF PSG_envelope IS
	signal envelope_reg: unsigned(3 downto 0);
	signal envelope_next: unsigned(3 downto 0);

	signal envelope_shape_reg: unsigned(3 downto 0);

	signal envelope_count_reg: unsigned(5 downto 0);
	signal envelope_count_next: unsigned(5 downto 0);

	signal envelope_tick: std_logic;
BEGIN
--	-- register
--	process(clk, reset_n)
--	begin
--		if (reset_n = '0') then
--			envelope_count_reg <= (others=>'0');
--			envelope_reg <= (others=>'0');
--		elsif (clk'event and clk='1') then
--			envelope_count_reg <= envelope_count_next;
--			envelope_reg <= envelope_next;
--		end if;
--	end process;
--
--	envelope_ticker : entity work.PSG_freqdiv
--	GENERIC MAP
--	(
--		bits => 19
--	)
--	PORT MAP
--	(
--		CLK => clk,
--		RESET_N => reset_n,
--		ENABLE => enable,
--		
--		BIT_OUT => envelope_tick,
--		
--		THRESHOLD => unsigned(PERIOD&"000")
--	);	
--	
--	-- next state
--	process(envelope_count_reg,enable,envelope_tick,count_reset)
--		variable continue : std_logic;
--		variable attack : std_logic;
--		variable alternate : std_logic;
--		variable hold : std_logic;
--
--		variable alternate_adj : std_logic;
--	begin
--		envelope_count_next <= envelope_count_reg;
--
--		continue := envelope_shape_reg(3);
--		attack := envelope_shape_reg(2);
--		alternate := envelope_shape_reg(1);
--		hold := envelope_shape_reg(0);
--
--		-- hold, alternate and continue do NOTHING until the top bit is set
--		-- then...
--		-- alternate xors output
--		alternate_adj := alternate and envelope_count_reg(5);
--
--		if (enable = '1' and envelope_tick='1') then
--			envelope_count_next <= envelope_count_reg + 1;
--		end if;
--
--		envelope_next <= envelope_count_reg(3 downto 0) xor attack&attack&attack&attack xor alternate_adj&alternate_adj&alternate_adj&alternate_adj;
--
--		if (envelope_count_reg(5)='1') then
--			if (continue='0') then
--				envelope_next <= (others=>'0');
--			end if;
--		end if;
--
--		if (count_reset ='1') then
--			envelope_count_next <= (others=>'0');
--		end if;
--	end process;
--		
--	-- output
--	envelope <= envelope_count_reg xor attack;
		
END vhdl;
