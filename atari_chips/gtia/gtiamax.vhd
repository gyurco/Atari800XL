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
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

LIBRARY work;

ENTITY gtiamax IS 
	PORT
	(
		PHI2 : IN STD_LOGIC;
		
		CLK_OUT : OUT STD_LOGIC; -- Use PHI2 and internal oscillator to create a clock, feed out here
		CLK_SLOW : IN STD_LOGIC; -- ... and back in here, then to pll!		
		
		D :  INOUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		A :  IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
		W_N : IN STD_LOGIC;
		CS_N : IN STD_LOGIC;

		S :  INOUT  STD_LOGIC_VECTOR(3 DOWNTO 0);
		T :  IN  STD_LOGIC_VECTOR(3 DOWNTO 0);

		AN :  IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
		HALT_N :  IN STD_LOGIC;

		OSC :  IN STD_LOGIC; -- 2x PHI0 ish, iffy duty cycle at TTL levels (at 4V its ok!)
		FO0 :  OUT STD_LOGIC; -- as OSC, but corrected duty cycle
		PAL :  IN STD_LOGIC; -- PAL clock (5/4...)

		GPIO :  INOUT  STD_LOGIC_VECTOR(11 DOWNTO 0);
		NC :  INOUT  STD_LOGIC_VECTOR(6 DOWNTO 1);
		CAD3 : IN STD_LOGIC;

		CSYNC : OUT STD_LOGIC;
		COLOR : OUT STD_LOGIC;
		LUM : OUT STD_LOGIC_VECTOR(3 downto 0)
	);
END gtiamax;		
		
ARCHITECTURE vhdl OF gtiamax IS
	component int_osc is
	port (
		clkout : out std_logic;        -- clkout.clk
		oscena : in  std_logic := '0'  -- oscena.oscena
	);
	end component;

	component pll
		port (
			inclk0   : in  std_logic := '0';
			c0 : out std_logic;
			locked   : out std_logic
		);
	end component;

	signal OSC_CLK : std_logic;
	signal PHI2_6X : std_logic;

	signal CLK : std_logic;
	signal RESET_N : std_logic;

	signal ENABLE_CYCLE : std_logic;

	signal ADDR_IN : std_logic_vector(4 downto 0);
	signal WRITE_DATA : std_logic_vector(7 downto 0);

	signal BUS_DATA : std_logic_vector(7 downto 0);
	signal BUS_OE : std_logic;

	signal REQUEST : std_logic;
	signal WRITE_N : std_logic;

	signal GTIA_DO : std_logic_vector(7 downto 0);

	signal GTIA_WRITE_ENABLE : std_logic;

	signal OSC_CLEAN : std_logic;
	signal OSC_CLEAN_EVENT : std_logic;
	signal CC_FALLING : std_logic;

	signal S_OUT : std_logic_vector(3 downto 0);

	signal VIDEO_COLOUR : std_logic_vector(7 downto 0);
	signal VIDEO_HSYNC : std_logic;
	signal VIDEO_VSYNC : std_logic;
	signal VIDEO_CSYNC : std_logic;
	signal VIDEO_BLANK : std_logic;
	signal VIDEO_BURST : std_logic;
	signal VIDEO_START_OF_FIELD : std_logic;
	signal VIDEO_ODD_LINE : std_logic;
BEGIN
	NC <= (others=>'Z');
	GPIO <= (others=>'Z');

	oscillator : int_osc
	port map 
	(
		clkout => OSC_CLK, 
		oscena => '1'
	);


	--phi_multiplier : entity work.phi_mult
	--port map 
	--(
	--	clkin => OSC_CLK,
	--	phi2 => PHI2,
	--	clkout => PHI2_6X -- 6x phi2, aligned!
	--);
	
	PHI2_6X <= OSC_CLK;

	pll_inst : pll
	PORT MAP(inclk0 => CLK_SLOW,
			 c0 => CLK, -- 27MHz 
			 locked => RESET_N);

bus_adapt : entity work.slave_timing_6502
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N,
		
		-- input from the cart port
		PHI2 => PHI2,
		bus_addr => A,
		bus_data => D,
	
		-- output to the cart port
		bus_data_out => BUS_DATA,
		bus_drive => BUS_OE,
		bus_cs => NOT(CS_N),
		bus_rw_n => W_N,

		-- request for a memory bus cycle (read or write)
		BUS_REQUEST => REQUEST,
		ADDR_IN => ADDR_IN,
		DATA_IN => WRITE_DATA,
		RW_N => WRITE_N,

		-- end of cycle
		ENABLE_CYCLE => ENABLE_CYCLE,

		DATA_OUT => GTIA_DO
	);

osc_cleaner : entity work.correct_duty
PORT MAP(
	CLK => CLK,
	RESET_N => RESET_N,
	CLKIN => OSC,
	CLKOUT => OSC_CLEAN,
	CLKOUT_EVENT => OSC_CLEAN_EVENT
	);

	CC_FALLING <= OSC_CLEAN_EVENT and not(OSC_CLEAN);

gtia1 : entity work.gtia
PORT MAP(CLK => CLK,
	ENABLE_179 => ENABLE_CYCLE,
	WR_EN => GTIA_WRITE_ENABLE,
	RESET_N => RESET_N,
	ADDR => ADDR_IN(4 DOWNTO 0),
	CPU_DATA_IN => WRITE_DATA(7 DOWNTO 0),
	DATA_OUT => GTIA_DO,

	-- pmg dma
	--MEMORY_DATA_IN => BUS_SNOOP,
	--ANTIC_FETCH => BUS_HALT,
	--CPU_ENABLE_ORIGINAL => ENABLE_CYCLE,
	MEMORY_DATA_IN => (others=>'1'),
	ANTIC_FETCH => '0',
	CPU_ENABLE_ORIGINAL => '0',

	PAL => '1', -- TODO: GPIO
	
	-- ANTIC interface
	COLOUR_CLOCK_ORIGINAL => CC_FALLING,
	COLOUR_CLOCK => CC_FALLING,
	COLOUR_CLOCK_HIGHRES => OSC_CLEAN_EVENT,
	AN => AN,
	
	-- keyboard interface
	CONSOL_IN => NOT(S),
	CONSOL_OUT => S_OUT,
	
	-- keyboard interface
	TRIG => T,
	
	-- TO scandoubler...
	COLOUR_out => VIDEO_COLOUR,
	
	VSYNC => VIDEO_VSYNC,
	HSYNC => VIDEO_HSYNC,
	CSYNC => VIDEO_CSYNC,
	BLANK => VIDEO_BLANK,
	BURST => VIDEO_BURST,
	START_OF_FIELD => VIDEO_START_OF_FIELD,
	ODD_LINE => VIDEO_ODD_LINE
	);

GTIA_WRITE_ENABLE <= NOT(WRITE_N) and REQUEST;

-- Wire up pins
CLK_OUT <= PHI2_6X;

D <= BUS_DATA when BUS_OE='1' else (others=>'Z');

S(0) <= '0' when S_OUT(0)='1' else 'Z';
S(1) <= '0' when S_OUT(1)='1' else 'Z';
S(2) <= '0' when S_OUT(2)='1' else 'Z';
S(3) <= '0' when S_OUT(3)='1' else 'Z';

CSYNC <= NOT(VIDEO_CSYNC);
COLOR <= '0'; -- TODO
LUM(3 downto 0) <= VIDEO_COLOUR(3 downto 0);

FO0 <= OSC_CLEAN;

END vhdl;
