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

ENTITY anticmax IS 
	PORT
	(
		-- Reminder
		-- OSC->GTIA->FO0->ANTIC->PHI0->CPU->PHI2->...

		PHI2 : IN STD_LOGIC;
		RST : IN STD_LOGIC;

		FO0 : IN STD_LOGIC;
		PHI0 : OUT STD_LOGIC;
		
		CLK_OUT : OUT STD_LOGIC; -- Use PHI2 and internal oscillator to create a clock, feed out here
		CLK_SLOW : IN STD_LOGIC; -- ... and back in here, then to pll!		
		
		D :  INOUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		A :  IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		W_N : IN STD_LOGIC;

		LP_N : IN STD_LOGIC; -- light pen

		NMI_N : OUT STD_LOGIC; 
		RNMI_N : IN STD_LOGIC;  -- Internal pull-up

		RDY : OUT_STD_LOGIC;    -- Open drain
		REF_N : OUT STD_LOGIC;  -- Driven, but... turbo freezer!! Try internal pull-ups?
		HALT_N : OUT STD_LOGIC; -- Driven, but... future devices like freezer? Try internal pull-ups?

		NC : IN STD_LOGIC_VECTOR(2 downto 1);

		AN : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);

		GPIO : INOUT STD_LOGIC_VECTOR(11 downto 0)
	);
END anticmax;		
		
ARCHITECTURE vhdl OF anticmax IS
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

	signal PHI0_REG : std_logic;

	signal ENABLE_CYCLE : std_logic;

	-- ANTIC
	SIGNAL	ANTIC_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL	ANTIC_WRITE_ENABLE :  STD_LOGIC;

	signal ADDR_IN : std_logic_vector(15 downto 0);
	signal WRITE_DATA : std_logic_vector(7 downto 0);

	signal BUS_DATA : std_logic_vector(7 downto 0);
	signal BUS_OE : std_logic;

	signal REQUEST : std_logic;
	signal WRITE_N : std_logic;

	SIGNAL SEL_ANTIC : STD_LOGIC;

	SIGNAL PAL_NTSC_N : STD_LOGIC;

	SIGNAL DMA_FETCH : STD_LOGIC;
	SIGNAL DMA_FETCH_ADDRESS : STD_LOGIC_VECTOR(15 downto 0);

	SIGNAL AN_OUT : STD_LOGIC_VECTOR(2 downto 0);
	SIGNAL AN_OUT_ENABLE : STD_LOGIC;

	signal ANTIC_READY : STD_LOGIC; 
	signal ANTIC_REFRESH : STD_LOGIC; 
BEGIN
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

	process(FO0)
	begin
		if (FO0'EVENT and FO0='1') then
			PHI0_REG <= not(PHI0_REG);
		end if;
	end process;
	PHI0 <= PHI0_REG;

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
		bus_cs => '1',
		bus_rw_n => W_N,

		-- request for a memory bus cycle (read or write)
		BUS_REQUEST => REQUEST,
		ADDR_IN => ADDR_IN,
		DATA_IN => WRITE_DATA,
		RW_N => WRITE_N,

		-- end of cycle
		ENABLE_CYCLE => ENABLE_CYCLE,

		DATA_OUT => ANTIC_DO
	);

PAL_NTSC_N <= '1'; -- TODO, GPIO!

antic1 : entity work.antic
PORT MAP(CLK => CLK,
		ANTIC_ENABLE_179 => ENABLE_CYCLE,
		WR_EN => ANTIC_WRITE_ENABLE,
		RESET_N => RESET_N,
		ADDR => ADDR_IN(3 DOWNTO 0),
		CPU_DATA_IN => WRITE_DATA(7 DOWNTO 0),
		MEMORY_READY_CPU => REQUEST,
		DATA_OUT => ANTIC_DO,

		-- ANTIC DMA!
		MEMORY_DATA_IN => WRITE_DATA(7 DOWNTO 0),
		MEMORY_READY_ANTIC => REQUEST,
		dma_fetch_out => dma_fetch, -- TODO -> to halt, but needs to be raised earlier?
		dma_address_out => dma_fetch_address,

		-- IRQs
		RNMI_N => RNMI_N,
		NMI_N_OUT => NMI_N,
		
		-- TV system (in fact just how many lines...)
		PAL => PAL_NTSC_N,
	
		lightpen => not(LP_N), -- synchronized? TODO
	
		-- WSYNC
		ANTIC_READY => ANTIC_READY,
	
		-- GTIA interface
		AN => AN_OUT, -- needs to be 1 cycle earlier?
		COLOUR_CLOCK_ORIGINAL_OUT => AN_OUT_ENABLE, --  input from FO0, urg, back to front...
		COLOUR_CLOCK_OUT => open,
		HIGHRES_COLOUR_CLOCK_OUT => open, -- gtia makes this...
	
		-- refresh
		refresh_out => ANTIC_REFRESH, -- TODO -> to halt, but needs to be raised earlier??

		-- if we are in turbo mode -- would be cool to get 2x and 4x colour clock but needs much more work, possibly new hardware too
		turbo_out => open,
	
		-- for debugging
		shift_out => open,
		dma_clock_out => open,
		hcount_out => open,
		vcount_out => open
	);

	process(ADDR_IN)
	begin
		SEL_ANTIC <= '0';
		if (ADDR_IN(15 downto 8)=x"D4") then
			SEL_ANTIC <= '1';
		end if;
	end process;

	ANTIC_WRITE_ENABLE <= NOT(WRITE_N) and REQUEST and SEL_ANTIC;

	-- Wire up pins
	CLK_OUT <= PHI2_6X;
	
	D <= BUS_DATA when BUS_OE='1' else (others=>'Z');

END vhdl;
