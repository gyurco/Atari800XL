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

ENTITY shared_enable IS
GENERIC
(
	cycle_length : integer := 16; -- or 32...
)
PORT 
( 
	CLK : IN STD_LOGIC;	
	RESET_N : IN STD_LOGIC;
	MEMORY_READY_CPU : IN STD_LOGIC;          -- during memory wait states keep CPU awake
	MEMORY_READY_ANTIC : IN STD_LOGIC;          -- during memory wait states keep CPU awake
	PAUSE_6502 : in std_logic;
	THROTTLE_COUNT_6502 : in std_logic_vector(5 downto 0);

	POKEY_ENABLE_179 : OUT STD_LOGIC;  -- always about 1.79MHz to keep sound the same
	ANTIC_ENABLE_179 : OUT STD_LOGIC;  -- always about 1.79MHz to keep sound the same - 1 cycle early
	oldcpu_enable : OUT STD_LOGIC;     -- always about 1.79MHz to keep sound the same - expanded to next ready
	CPU_ENABLE_OUT : OUT STD_LOGIC;    -- for compatibility run at 1.79MHz, for speed run as fast as we can
	
	SCANDOUBLER_ENABLE_LOW : OUT STD_LOGIC; -- double antic's rate - due to high-res mode
	SCANDOUBLER_ENABLE_HIGH : OUT STD_LOGIC -- four times antic's rate - due to high-res mode
	
	-- antic DMA runs 1 cycle after 'enable', so ANTIC_ENABLE is delayed by 31 cycles vs CPU_ENABLE (when in 1.79MHz mode)
	-- XXX watch out on clock speed change from 56MHz!
);
END shared_enable;

ARCHITECTURE vhdl OF shared_enable IS
	component enable_divider IS
	generic(COUNT : natural := 1);
	PORT 
	( 
		CLK : IN STD_LOGIC;
		RESET_N : IN STD_LOGIC;
		ENABLE_IN : IN STD_LOGIC;
		
		ENABLE_OUT : OUT STD_LOGIC
	);
	END component;
	
	component delay_line IS
	generic(COUNT : natural := 1);
	PORT 
	( 
		CLK : IN STD_LOGIC;
		SYNC_RESET : IN STD_LOGIC;
		DATA_IN : IN STD_LOGIC;
		ENABLE : IN STD_LOGIC;
		RESET_N : IN STD_LOGIC;
		
		DATA_OUT : OUT STD_LOGIC
	);
	END component;		
	
	signal enable_179 : std_logic;
	signal enable_179_early : std_logic;
	signal enable_179_late : std_logic;
	signal cpu_enable : std_logic;
	
	signal cpu_extra_enable_next : std_logic;
	signal cpu_extra_enable_reg : std_logic;
	
	signal turbo_next : std_logic;
	signal turbo_reg : std_logic;	

	signal throttle_count_next : std_logic_vector(5 downto 0);
	signal throttle_count_reg : std_logic_vector(5 downto 0);	
	
	-- TODO - clean up
	signal oldcpu_extra_enable_next : std_logic;
	signal oldcpu_extra_enable_reg : std_logic;
	signal enable_179_expanded : std_logic;
	
	signal memory_ready : std_logic;
begin
	-- instantiate some clock calcs
	-- TODO - scandouble clocks assume 58MHz...
	SCANDOUBLER_ENABLE_HIGH <= '1';
		
	sl_enable_colour_clock_div : enable_divider
		generic map (COUNT=>2)
		port map(clk=>CLK,reset_n=>reset_n,enable_in=>'1',enable_out=>SCANDOUBLER_ENABLE_LOW);		

	enable_179_clock_div : enable_divider
		generic map (COUNT=>cycle_length)
		port map(clk=>clk,reset_n=>reset_n,enable_in=>'1',enable_out=>enable_179);
		
	process(THROTTLE_COUNT_6502, throttle_count_reg, enable_179)
	begin
		turbo_next <= '0';
		throttle_count_next <= std_logic_vector(unsigned(throttle_count_reg) + 1);

		--011111/31/1f = run every 32 cycles
		
		if (throttle_count_reg = THROTTLE_COUNT_6502) then
			throttle_count_next <= (others=>'0');
			turbo_next <= '1';
		end if;
		
		if (enable_179 = '1') then -- synchronize
			throttle_count_next <= "000001";
		end if;
		--0000000000111111111122222222223333
		--0123456789012345678901234567890123
		--X-------------------------------X
		--
		--000000000011111111112222222222333
		--R12345678901234567890123456789012
		---------------------------------NT
		
		--000000000011111100000000001111111
		--R12345678901234501234567890123456
		-----------------NT--------------NT
	end process;

	delay_line_phase : delay_line
		generic map (COUNT=>cycle_length-1)
		port map(clk=>clk,sync_reset=>'0',reset_n=>reset_n,data_in=>enable_179, enable=>'1', data_out=>enable_179_early);	

	delay_line_phase2 : delay_line
		generic map (COUNT=>cycle_length/2)
		port map(clk=>clk,sync_reset=>'0',reset_n=>reset_n,data_in=>enable_179, enable=>'1', data_out=>enable_179_late);		
	
	-- registers
	process(clk,reset_n)
	begin
		if (reset_n = '0') then
			cpu_extra_enable_reg <= '0';
			oldcpu_extra_enable_reg <= '0';
			turbo_reg <= '0';
			throttle_count_reg <= (others=>'0');
		elsif (clk'event and clk='1') then										
			cpu_extra_enable_reg <= cpu_extra_enable_next;
			oldcpu_extra_enable_reg <= oldcpu_extra_enable_next;
			turbo_reg <= turbo_next;
			throttle_count_reg <= throttle_count_next;
		end if;
	end process;
	
	-- next state
	memory_ready <= memORY_READY_CPU or memORY_READY_ANTIC;
	cpu_enable <= (turbo_reg or cpu_extra_enable_reg or enable_179) and not(pause_6502);
	cpu_extra_enable_next <= cpu_enable and not(memory_ready);
	
	oldcpu_extra_enable_next <= enable_179_expanded and not(memory_ready);
	enable_179_expanded <= oldcpu_extra_enable_reg or enable_179;
	
	-- output
	POKEY_ENABLE_179 <= enable_179_late; -- aka enable_179_late!  TODO!!!
	oldcpu_enable <= enable_179_expanded;
	ANTIC_ENABLE_179 <= enable_179_early;
	
	CPU_ENABLE_OUT <= cpu_enable; -- run at 25MHz

end vhdl;
