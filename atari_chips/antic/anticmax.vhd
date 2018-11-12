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
		RST_N : IN STD_LOGIC;

		FO0 : IN STD_LOGIC;
		PHI0 : OUT STD_LOGIC;
		
		CLK_OUT : OUT STD_LOGIC; -- Use PHI2 and internal oscillator to create a clock, feed out here
		CLK_SLOW : IN STD_LOGIC; -- ... and back in here, then to pll!		
		
		D :  INOUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		A :  INOUT  STD_LOGIC_VECTOR(15 DOWNTO 0);
		RW_N : IN STD_LOGIC;

		LP_N : IN STD_LOGIC; -- light pen

		NMI_N : OUT STD_LOGIC; 
		RNMI_N : IN STD_LOGIC;  -- Internal pull-up

		RDY : OUT STD_LOGIC;    -- Open drain
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

	signal BUS_ADDR : std_logic_vector(15 downto 0);
	signal BUS_ADDR_OE : std_logic;

	signal BUS_DATA : std_logic_vector(7 downto 0);
	signal BUS_DATA_OE : std_logic;

	signal REQUEST : std_logic;
	signal DMA_COMPLETE : std_logic;
	signal WRITE_N : std_logic;

	SIGNAL PAL_NTSC_N : STD_LOGIC;

	SIGNAL DMA_FETCH_ADDR : STD_LOGIC_VECTOR(15 downto 0);

	SIGNAL AN_OUT : STD_LOGIC_VECTOR(2 downto 0);
	SIGNAL AN_OUT_ENABLE : STD_LOGIC;

	SIGNAL ANTIC_NEXT_CYCLE : STD_LOGIC_VECTOR(2 downto 0); --000=cpu,001=dma,010=refresh,011=undef,100=undef,101=dma_wsync,110=refresh_wsync,101=undef

	SIGNAL RDY_DATA : STD_LOGIC;
	SIGNAL REF_N_DATA : STD_LOGIC;
	SIGNAL REF_N_OE : STD_LOGIC;
	SIGNAL HALT_N_DATA : STD_LOGIC;
	SIGNAL HALT_N_OE : STD_LOGIC;

	SIGNAL ANTIC_LP : STD_LOGIC;
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

bus_adapt : entity work.timing_antic
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N,
		
		-- input from the pins
		PHI2 => PHI2,
		bus_addr => A,
		bus_data => D,

		bus_lp_n => lp_n,
		bus_rnmi_n => rnmi_n,

		-- output to the cart port
		bus_addr_out => BUS_ADDR,
		bus_addr_oe => BUS_ADDR_OE,
		bus_data_out => BUS_DATA,
		bus_data_oe => BUS_DATA_OE,
		bus_rw_n => RW_N,
		bus_rdy => RDY_DATA,
		bus_ref_n => REF_N_DATA,
		bus_ref_n_oe => REF_N_OE,
		bus_halt_n => HALT_N_DATA,
		bus_halt_n_oe => HALT_N_OE,
		bus_an_out => AN,

		-- request for a memory bus cycle (read or write)
		-- into antic
		-- requests from the cpu
		BUS_REQUEST => REQUEST,
		ADDR_IN => ADDR_IN,
		DATA_IN => WRITE_DATA,
		RW_N => WRITE_N,
		LIGHTPEN => ANTIC_LP,

		-- response to the request, out of antic
		DATA_OUT => ANTIC_DO,

		-- antic dma master
		CYCLE_TYPE => antic_next_cycle,
		ADDR_OUT => dma_fetch_addr,
		DMA_COMPLETE => dma_complete,

		-- antic an0 output
		AN_OUT => AN_OUT,
		AN_OUT_ENABLE => AN_OUT_ENABLE,
		FO0 => FO0,

		-- end of cycle
		ENABLE_CYCLE => ENABLE_CYCLE
	);

PAL_NTSC_N <= '1'; -- TODO, GPIO!

antic1 : entity work.antic
GENERIC MAP(cycle_length=>32)
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
		MEMORY_READY_ANTIC => dma_complete,
		dma_fetch_out => open,
		dma_address_out => dma_fetch_addr,

		-- IRQs
		RNMI_N => RNMI_N,
		NMI_N_OUT => NMI_N,
		
		-- TV system (in fact just how many lines...)
		PAL => PAL_NTSC_N,
	
		lightpen => ANTIC_LP,
	
		-- WSYNC
		ANTIC_READY => open,
	
		-- GTIA interface
		AN => AN_OUT, -- needs to be 1 cycle earlier?
		COLOUR_CLOCK_ORIGINAL_OUT => AN_OUT_ENABLE, --  input from FO0, urg, back to front...
		COLOUR_CLOCK_OUT => open,
		HIGHRES_COLOUR_CLOCK_OUT => open, -- gtia makes this...

		-- next cycle
		next_cycle_type => antic_next_cycle,
	
		-- refresh
		refresh_out => open, 

		-- if we are in turbo mode -- would be cool to get 2x and 4x colour clock but needs much more work, possibly new hardware too
		turbo_out => open,
	
		-- for debugging
		shift_out => open,
		dma_clock_out => open,
		hcount_out => open,
		vcount_out => open
	);

	ANTIC_WRITE_ENABLE <= NOT(WRITE_N) and REQUEST;

	-- Wire up pins
	CLK_OUT <= PHI2_6X;
	
	D <= BUS_DATA when BUS_DATA_OE='1' else (others=>'Z');
	A <= BUS_ADDR when BUS_ADDR_OE='1' else (others=>'Z');
	HALT_N <= HALT_N_DATA when HALT_N_OE='1' else 'Z';
	REF_N <= REF_N_DATA when REF_N_OE='1' else 'Z';
	RDY <= '0' when RDY_DATA='0' else 'Z';

END vhdl;
