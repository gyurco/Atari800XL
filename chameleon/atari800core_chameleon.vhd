---------------------------------------------------------------------------
-- (c) 2014 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

LIBRARY work;

entity atari800core_chameleon is
port
(
   -- VGA
	red : OUT STD_LOGIC_VECTOR(4 downto 0);
	grn : OUT STD_LOGIC_VECTOR(4 downto 0);
	blu : OUT STD_LOGIC_VECTOR(4 downto 0);
	nHSync: OUT STD_LOGIC;
	nVSync: OUT STD_LOGIC;
	
	-- SDRAM
	sd_clk : OUT STD_LOGIC;
	sd_addr : OUT STD_LOGIC_VECTOR(12 downto 0);
	sd_ba_0 : OUT STD_LOGIC;
	sd_ba_1 : OUT STD_LOGIC;
	sd_we_n : OUT STD_LOGIC;
	sd_ras_n : OUT STD_LOGIC;
	sd_cas_n : OUT STD_LOGIC;
	sd_data :INOUT STD_LOGIC_VECTOR(15 downto 0);
	sd_ldqm : OUT STD_LOGIC;
	sd_udqm : OUT STD_LOGIC;

	-- Clocks
	clk8 : in std_logic;
	phi2_n : in std_logic;
	dotclock_n : in std_logic;

	-- Bus
	romlh_n : in std_logic;
	ioef_n : in std_logic;

	-- Buttons
	freeze_n : in std_logic;

	-- MMC/SPI
	spi_miso : in std_logic;
	mmc_cd_n : in std_logic;
	mmc_wp : in std_logic;
	-- mosi is on the MUX...

	-- MUX CPLD
	mux_clk : out std_logic;
	mux : out unsigned(3 downto 0);
	mux_d : out unsigned(3 downto 0);
	mux_q : in unsigned(3 downto 0);

	-- USART
	usart_tx : in std_logic;
	usart_clk : in std_logic;
	usart_rts : in std_logic;
	usart_cts : in std_logic;

	-- Audio
	sigmaL : out std_logic;
	sigmaR : out std_logic	
);
end atari800core_chameleon;

architecture vhdl of atari800core_chameleon is

component hq_dac
port (
  reset :in std_logic;
  clk :in std_logic;
  clk_ena : in std_logic;
  pcm_in : in std_logic_vector(19 downto 0);
  dac_out : out std_logic
);
end component;

  signal AUDIO_L_RAW : std_logic_vector(15 downto 0);
  signal AUDIO_R_RAW : std_logic_vector(15 downto 0);

  signal VGA_VS_RAW : std_logic;
  signal VGA_HS_RAW : std_logic;

  signal RESET_n : std_logic;
  signal PLL_LOCKED : std_logic;
  signal CLK : std_logic;
  signal CLK_SDRAM : std_logic;


-- SDRAM
  signal SDRAM_REQUEST : std_logic;
  signal SDRAM_REQUEST_COMPLETE : std_logic;
  signal SDRAM_READ_ENABLE :  STD_LOGIC;
  signal SDRAM_WRITE_ENABLE : std_logic;
  signal SDRAM_ADDR : STD_LOGIC_VECTOR(22 DOWNTO 0);
  signal SDRAM_DO : STD_LOGIC_VECTOR(31 DOWNTO 0);
  signal SDRAM_DI : STD_LOGIC_VECTOR(31 DOWNTO 0);
  signal SDRAM_WIDTH_8bit_ACCESS : std_logic;
  signal SDRAM_WIDTH_16bit_ACCESS : std_logic;
  signal SDRAM_WIDTH_32bit_ACCESS : std_logic;

  signal SDRAM_REFRESH : std_logic;
  
  signal SDRAM_RESET_N : std_logic;


-- MUX
	signal mux_clk_reg : std_logic := '0';
	signal mux_reg : unsigned(3 downto 0) := (others => '1');
	signal mux_d_reg : unsigned(3 downto 0) := (others => '1');

-- LEDs
	signal led_green : std_logic;
	signal led_red : std_logic;

-- clocks...
	signal sysclk : std_logic;
	signal ena_1mhz : std_logic;
	signal ena_1khz : std_logic;
	signal phi2 : std_logic;
	signal no_clock : std_logic;

-- Docking station
	signal docking_station : std_logic;
	signal docking_ena : std_logic;
	signal docking_irq : std_logic;
	signal irq_n : std_logic;

	signal docking_joystick1 : unsigned(5 downto 0);
	signal docking_joystick2 : unsigned(5 downto 0);
	signal docking_joystick3 : unsigned(5 downto 0);
	signal docking_joystick4 : unsigned(5 downto 0);

-- PS/2 Keyboard
	signal ps2_keyboard_clk_in : std_logic;
	signal ps2_keyboard_dat_in : std_logic;
	--signal ps2_keyboard_clk_out : std_logic;
	--signal ps2_keyboard_dat_out : std_logic;

  SIGNAL	KEYBOARD_RESPONSE :  STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL	KEYBOARD_SCAN :  STD_LOGIC_VECTOR(5 DOWNTO 0);
  SIGNAL	CONSOL_OPTION :  STD_LOGIC;
  SIGNAL	CONSOL_SELECT :  STD_LOGIC;
  SIGNAL	CONSOL_START :  STD_LOGIC;
  SIGNAL FKEYS : std_logic_vector(11 downto 0);

begin
RESET_N <= PLL_LOCKED;

-- disable unused parts
--   sdram
--sd_clk <= 'Z';
--sd_addr <= (others=>'0');
--sd_ba_0 <= '0';
--sd_ba_1 <= '0';
--sd_we_n <= '1';
--sd_ras_n <= '1';
--sd_cas_n <= '1';
--sd_data <= (others=>'Z');
--sd_ldqm <= '0';
--sd_udqm <= '0';

-- simplest possible implementation
-- pll
pll : ENTITY work.pll
	PORT MAP
	(
		inclk0 => clk8,
		c0 => clk_sdram,
		c1 => clk,
		c2 => sd_clk,
		locked => pll_locked
	);
	
-- core
--atari800core : ENTITY work.atari800core_helloworld
--	GENERIC MAP
--	(
--		cycle_length => 32,
--
--		video_bits => 5,
--	
--		internal_rom => 1,
--		internal_ram => 16384
--	)
--	PORT MAP
--	(
--		CLK => clk,
--		RESET_N => RESET_N,
--
--		-- VIDEO OUT - PAL/NTSC, original Atari timings approx (may be higher res)
--		VIDEO_VS => vga_vs_raw,
--		VIDEO_HS => vga_hs_raw,
--		VIDEO_B => blu,
--		VIDEO_G => grn,
--		VIDEO_R => red,
--
--		-- AUDIO OUT - Pokey/GTIA 1-bit and Covox all mixed
--		AUDIO_L => audio_l_raw,
--		AUDIO_R => audio_r_raw,
--
--		-- JOYSTICK
--		JOY1_n => std_logic_vector(docking_joystick1)(4 downto 0),
--		JOY2_n => std_logic_vector(docking_joystick2)(4 downto 0),
--
--		-- KEYBOARD
--		PS2_CLK => ps2_keyboard_clk_in,
--		PS2_DAT => ps2_keyboard_dat_in,
--
--		-- video standard
--		PAL => '1'
--	);

atarixl_simple_sdram1 : entity work.atari800core_simple_sdram
	GENERIC MAP
	(
		cycle_length => 32,
		internal_rom => 1,
		internal_ram => 0,
		video_bits => 5
	)
	PORT MAP
	(
		CLK => CLK,
		--RESET_N => RESET_N and SDRAM_RESET_N and not(reset_atari),
		RESET_N => RESET_N and SDRAM_RESET_N,

		-- VIDEO OUT - PAL/NTSC, original Atari timings approx (may be higher res)
		VIDEO_VS => vga_vs_raw,
		VIDEO_HS => vga_hs_raw,
		VIDEO_B => blu,
		VIDEO_G => grn,
		VIDEO_R => red,

		-- AUDIO OUT - Pokey/GTIA 1-bit and Covox all mixed
		AUDIO_L => audio_l_raw,
		AUDIO_R => audio_r_raw,

		-- JOYSTICK
		JOY1_n => std_logic_vector(docking_joystick1)(4 downto 0),
		JOY2_n => std_logic_vector(docking_joystick2)(4 downto 0),

		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,
		KEYBOARD_SCAN => KEYBOARD_SCAN,

		SIO_COMMAND => open,
		SIO_RXD => '1',
		SIO_TXD => open,

		CONSOL_OPTION => CONSOL_OPTION,
		CONSOL_SELECT => CONSOL_SELECT,
		CONSOL_START => CONSOL_START,

		SDRAM_REQUEST => SDRAM_REQUEST,
		SDRAM_REQUEST_COMPLETE => SDRAM_REQUEST_COMPLETE,
		SDRAM_READ_ENABLE => SDRAM_READ_ENABLE,
		SDRAM_WRITE_ENABLE => SDRAM_WRITE_ENABLE,
		SDRAM_ADDR => SDRAM_ADDR,
		SDRAM_DO => SDRAM_DO,
		SDRAM_DI => SDRAM_DI,
		SDRAM_32BIT_WRITE_ENABLE => SDRAM_WIDTH_32bit_ACCESS,
		SDRAM_16BIT_WRITE_ENABLE => SDRAM_WIDTH_16bit_ACCESS,
		SDRAM_8BIT_WRITE_ENABLE => SDRAM_WIDTH_8bit_ACCESS,
		SDRAM_REFRESH => SDRAM_REFRESH,

		DMA_FETCH => '0',
		DMA_READ_ENABLE => '0',
		DMA_32BIT_WRITE_ENABLE => '0',
		DMA_16BIT_WRITE_ENABLE => '0',
		DMA_8BIT_WRITE_ENABLE => '0',
		DMA_ADDR => (others=>'0'),
		DMA_WRITE_DATA => (others=>'0'),
		MEMORY_READY_DMA => open,
		DMA_MEMORY_DATA => open, 

   		RAM_SELECT => (others=>'0'),
    		ROM_SELECT => (others=>'0'),
		PAL => '1',
		HALT => '0',
		THROTTLE_COUNT_6502 => "000001"
	);

-- video glue
nHSync <= (VGA_HS_RAW xor VGA_VS_RAW);
nVSync <= (VGA_VS_RAW);

-- audio glue
dac_left : hq_dac
port map
(
  reset => not(reset_n),
  clk => clk,
  clk_ena => '1',
  pcm_in => AUDIO_L_RAW&"0000",
  dac_out => sigmaL
);

dac_right : hq_dac
port map
(
  reset => not(reset_n),
  clk => clk,
  clk_ena => '1',
  pcm_in => AUDIO_R_RAW&"0000",
  dac_out => sigmaR
);

-- Some common chameleon parts - e.g. mux - taken from the hardware test
sysclk <= clk;

-- -----------------------------------------------------------------------
-- 1 Mhz and 1 Khz clocks
-- -----------------------------------------------------------------------
	my1Mhz : entity work.chameleon_1mhz
		generic map (
			--clk_ticks_per_usec => 100
			clk_ticks_per_usec => 57
		)
		port map (
			clk => sysclk,
			ena_1mhz => ena_1mhz,
			ena_1mhz_2 => open
		);

	my1Khz : entity work.chameleon_1khz
		port map (
			clk => sysclk,
			ena_1mhz => ena_1mhz,
			ena_1khz => ena_1khz
		);

-- -----------------------------------------------------------------------
-- Phi 2
-- -----------------------------------------------------------------------
	myPhi2: entity work.chameleon_phi_clock
		port map (
			clk => sysclk,
			phiIn => phi2,
		
			-- no_clock is high when there are no phiIn changes detected.
			-- This signal allows switching between real I/O and internal emulation.
			no_clock => no_clock,
		
			-- docking_station is high when there are no phiIn changes (no_clock) and
			-- the phi signal is low. Without docking station phi is pulled up.
			docking_station => docking_station
		);

	phi2 <= not phi2_n;

-- -----------------------------------------------------------------------
-- Docking station
-- -----------------------------------------------------------------------
	myDockingStation : entity work.chameleon_docking_station
		port map (
			clk => sysclk,
			ena_1mhz => ena_1mhz,
			enable => docking_ena,
			
			docking_station => docking_station,
			
			dotclock_n => dotclock_n,
			io_ef_n => ioef_n,
			rom_lh_n => romlh_n,
			irq_d => irq_n,
			irq_q => docking_irq,
			
			joystick1 => docking_joystick1,
			joystick2 => docking_joystick2,
			joystick3 => docking_joystick3,
			joystick4 => docking_joystick4,
			keys => open,
			restore_key_n => open,
			
			amiga_power_led => '0',
			amiga_drive_led => '0',
			amiga_reset_n => open,
			amiga_scancode => open
		);

-- -----------------------------------------------------------------------
-- MUX CPLD
-- -----------------------------------------------------------------------
	-- MUX clock
	process(sysclk)
	begin
		if rising_edge(sysclk) then
			mux_clk_reg <= not mux_clk_reg;
		end if;
	end process;

	-- MUX read
	process(sysclk)
	begin
		if rising_edge(sysclk) then
			if mux_clk_reg = '1' then
				case mux_reg is
				when X"6" =>
					irq_n <= mux_q(2);
				when X"B" =>
					--reset_button_n <= mux_q(1);
					--ir <= mux_q(3);
				when X"A" =>
					--vga_id <= mux_q;
				when X"E" =>
					ps2_keyboard_dat_in <= mux_q(0);
					ps2_keyboard_clk_in <= mux_q(1);
					--ps2_mouse_dat_in <= mux_q(2);
					--ps2_mouse_clk_in <= mux_q(3);
				when others =>
					null;
				end case;
			end if;
		end if;
	end process;

	-- MUX write
	process(sysclk)
	begin
		if rising_edge(sysclk) then
			docking_ena <= '0';
			if mux_clk_reg = '1' then
				case mux_reg is
				when X"7" =>
					mux_d_reg <= "1111";
					if docking_station = '1' then
						mux_d_reg <= "1" & docking_irq & "11";
					end if;
					mux_reg <= X"6";
				when X"6" =>
					mux_d_reg <= "1111";
					mux_reg <= X"8";
				when X"8" =>
					mux_d_reg <= "1111";
					mux_reg <= X"A";
				when X"A" =>
					mux_d_reg <= "10" & led_green & led_red;
					mux_reg <= X"B";
				when X"B" =>
					--mux_d_reg <= iec_reg;
					mux_d_reg <= "1111";
					mux_reg <= X"D";
					docking_ena <= '1';
				when X"D" =>
					--mux_d_reg(0) <= ps2_keyboard_dat_out;
					--mux_d_reg(1) <= ps2_keyboard_clk_out;
					--mux_d_reg(2) <= ps2_mouse_dat_out;
					--mux_d_reg(3) <= ps2_mouse_clk_out;
					mux_d_reg <= "1111";
					mux_reg <= X"E";
				when X"E" =>
					mux_d_reg <= "1111";
					mux_reg <= X"7";
				when others =>
					mux_reg <= X"B";
					mux_d_reg <= "10" & led_green & led_red;
				end case;
			end if;
		end if;
	end process;
	
	mux_clk <= mux_clk_reg;
	mux_d <= mux_d_reg;
	mux <= mux_reg;

-- -----------------------------------------------------------------------
-- LEDs
-- -----------------------------------------------------------------------
	myGreenLed : entity work.chameleon_led
		port map (
			clk => sysclk,
			clk_1khz => ena_1khz,
			led_on => '0',
			led_blink => '1',
			led => led_red,
			led_1hz => led_green
		);


-- -----------------------------------------------------------------------
-- SDRAM
-- -----------------------------------------------------------------------
sdram_adaptor : entity work.sdram_statemachine
GENERIC MAP(ADDRESS_WIDTH => 22,
			AP_BIT => 10,
			COLUMN_WIDTH => 8,
			ROW_WIDTH => 12
			)
PORT MAP(CLK_SYSTEM => CLK,
		 CLK_SDRAM => CLK_SDRAM,
		 RESET_N =>  RESET_N,
		 READ_EN => SDRAM_READ_ENABLE,
		 WRITE_EN => SDRAM_WRITE_ENABLE,
		 REQUEST => SDRAM_REQUEST,
		 BYTE_ACCESS => SDRAM_WIDTH_8BIT_ACCESS,
		 WORD_ACCESS => SDRAM_WIDTH_16BIT_ACCESS,
		 LONGWORD_ACCESS => SDRAM_WIDTH_32BIT_ACCESS,
		 REFRESH => SDRAM_REFRESH,
		 ADDRESS_IN => SDRAM_ADDR,
		 DATA_IN => SDRAM_DI,
		 SDRAM_DQ => sd_data,
		 COMPLETE => SDRAM_REQUEST_COMPLETE,
		 SDRAM_BA0 => sd_ba_0,
		 SDRAM_BA1 => sd_ba_1,
		 SDRAM_CKE => open,
		 SDRAM_CS_N => open,
		 SDRAM_RAS_N => sd_ras_n,
		 SDRAM_CAS_N => sd_cas_n,
		 SDRAM_WE_N => sd_we_n,
		 SDRAM_ldqm => sd_ldqm,
		 SDRAM_udqm => sd_udqm,
		 DATA_OUT => SDRAM_DO,
		 SDRAM_ADDR => sd_addr(11 downto 0),
		 reset_client_n => SDRAM_RESET_N
		 );
		 
sd_addr(12) <= '0';

-- PS2 to pokey
keyboard_map1 : entity work.ps2_to_atari800
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,
		PS2_CLK => ps2_keyboard_clk_in,
		PS2_DAT => ps2_keyboard_dat_in,
		
		KEYBOARD_SCAN => KEYBOARD_SCAN,
		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,

		CONSOL_START => CONSOL_START,
		CONSOL_SELECT => CONSOL_SELECT,
		CONSOL_OPTION => CONSOL_OPTION,
		
		FKEYS => FKEYS
	);

end vhdl;
