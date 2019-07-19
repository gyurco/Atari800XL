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
use IEEE.STD_LOGIC_MISC.all;

LIBRARY work;

entity atari800core_chameleon is
	GENERIC
	(
	       TV : integer  -- 1 = PAL, 0=NTSC - PLL only, no auto-pll adjust!
	);
	port (
-- Clocks
		clk50m : in std_logic;
		phi2_n : in std_logic;
		dotclk_n : in std_logic;

-- Buttons
		usart_cts : in std_logic;  -- Left button
		freeze_btn : in std_logic; -- Middle button
		reset_btn : in std_logic;  -- Right

-- PS/2, IEC, LEDs
		iec_present : in std_logic;

		ps2iec_sel : out std_logic;
		ps2iec : in unsigned(3 downto 0);

		ser_out_clk : out std_logic;
		ser_out_dat : out std_logic;
		ser_out_rclk : out std_logic;

		iec_clk_out : out std_logic;
		iec_srq_out : out std_logic;
		iec_atn_out : out std_logic;
		iec_dat_out : out std_logic;

-- SPI, Flash and SD-Card
		flash_cs : out std_logic;
		rtc_cs : out std_logic;
		mmc_cs : out std_logic;
		mmc_cd : in std_logic;
		mmc_wp : in std_logic;
		spi_clk : out std_logic;
		spi_miso : in std_logic;
		spi_mosi : out std_logic;

-- Clock port
		clock_ior : out std_logic;
		clock_iow : out std_logic;

-- C64 bus
		reset_in : in std_logic;

		ioef : in std_logic;
		romlh : in std_logic;

		dma_out : out std_logic;
		game_out : out std_logic;
		exrom_out : out std_logic;

		irq_in : in std_logic;
		irq_out : out std_logic;
		nmi_in : in std_logic;
		nmi_out : out std_logic;
		ba_in : in std_logic;
		rw_in : in std_logic;
		rw_out : out std_logic;

		sa_dir : out std_logic;
		sa_oe : out std_logic;
		sa15_out : out std_logic;
		low_a : inout unsigned(15 downto 0);

		sd_dir : out std_logic;
		sd_oe : out std_logic;
		low_d : inout unsigned(7 downto 0);

-- SDRAM
		ram_clk : out std_logic;
		ram_ldqm : out std_logic;
		ram_udqm : out std_logic;
		ram_ras : out std_logic;
		ram_cas : out std_logic;
		ram_we : out std_logic;
		ram_ba : out std_logic_vector(1 downto 0);
		ram_a : out std_logic_vector(12 downto 0);
		ram_d : inout std_logic_vector(15 downto 0);

-- IR eye
		ir_data : in std_logic;

-- USB micro
		usart_clk : in std_logic;
		usart_rts : in std_logic;
		usart_rx : out std_logic;
		usart_tx : in std_logic;

-- Video output
		red : out std_logic_vector(4 downto 0);
		grn : out std_logic_vector(4 downto 0);
		blu : out std_logic_vector(4 downto 0);
		hsync_n : out std_logic;
		vsync_n : out std_logic;

-- Audio output
		sigma_l : out std_logic;
		sigma_r : out std_logic
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
  signal VGA_CS_RAW : std_logic;

  --signal RESET_n : std_logic;
  signal reset_counter : unsigned(15 downto 0):=X"0000";
  signal reset_n 	: std_logic := '1';  
  signal PLL_LOCKED : std_logic;
  signal CLK : std_logic;
  signal CLK_SDRAM : std_logic;

  signal CLK_PLL1 : std_logic; -- cascaded to get better clock

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
--	signal mux_clk_reg : std_logic := '0';
--	signal mux_reg : unsigned(3 downto 0) := (others => '1');
--	signal mux_d_reg : unsigned(3 downto 0) := (others => '1');

-- reset from chameleon
	signal chameleon_reset_n_next : std_logic_vector(6 downto 0);
	signal chameleon_reset_n_reg : std_logic_vector(6 downto 0);
	signal reset_short_next : std_logic;
	signal reset_short_reg : std_logic;
	signal reset_long_next : std_logic;
	signal reset_long_reg : std_logic;
	signal reconfig_next : std_logic;
	signal reconfig_reg : std_logic;

-- LEDs
--	signal led_green : std_logic;
--	signal led_red : std_logic;

-- clocks...
	signal ena_1mhz : std_logic; --fast clk
	signal ena_1khz : std_logic;

	--signal phi2 : std_logic;
	signal no_clock : std_logic;

	signal ena_10khz : std_logic; --slow clk
	signal ena_10hz : std_logic;	
	
-- Docking station
	signal docking_station : std_logic;
	--signal docking_ena : std_logic;
	--signal docking_irq : std_logic;
	--signal irq_n : std_logic;

	signal docking_joystick1_next : unsigned(5 downto 0);
	signal docking_joystick2_next : unsigned(5 downto 0);
	signal docking_joystick3_next : unsigned(5 downto 0);
	signal docking_joystick4_next : unsigned(5 downto 0);
	signal c64_keys_next : unsigned(63 downto 0);
	signal docking_joystick1_reg : unsigned(5 downto 0);
	signal docking_joystick2_reg : unsigned(5 downto 0);
	signal docking_joystick3_reg : unsigned(5 downto 0);
	signal docking_joystick4_reg : unsigned(5 downto 0);
	signal c64_keys_reg : unsigned(63 downto 0);
       	--  0 = col0, row0
       	--  1 = col1, row0
       	--  8 = col0, row1
	-- 63 = col7, row7
	-- low is pressed

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

-- IR remote
        signal ir_joya : unsigned(5 downto 0);
        signal ir_joyb : unsigned(5 downto 0);
	signal ir_escape : std_logic;
	signal ir_start : std_logic;
	signal ir_select : std_logic;
	signal ir_option : std_logic;
	signal ir_fkeys_next : std_logic_vector(11 downto 0);
	signal ir_fkeys_reg : std_logic_vector(11 downto 0);

	-- dma/virtual drive
	signal DMA_ADDR_FETCH : std_logic_vector(23 downto 0);
	signal DMA_WRITE_DATA : std_logic_vector(31 downto 0);
	signal DMA_FETCH : std_logic;
	signal DMA_32BIT_WRITE_ENABLE : std_logic;
	signal DMA_16BIT_WRITE_ENABLE : std_logic;
	signal DMA_8BIT_WRITE_ENABLE : std_logic;
	signal DMA_READ_ENABLE : std_logic;
	signal DMA_MEMORY_READY : std_logic;
	signal DMA_MEMORY_DATA : std_logic_vector(31 downto 0);

	signal ZPU_ADDR_ROM : std_logic_vector(15 downto 0);
	signal ZPU_ROM_DATA :  std_logic_vector(31 downto 0);

	signal ZPU_OUT1 : std_logic_vector(31 downto 0);
	signal ZPU_OUT2 : std_logic_vector(31 downto 0);
	signal ZPU_OUT3 : std_logic_vector(31 downto 0);
	signal ZPU_OUT4 : std_logic_vector(31 downto 0);
	signal ZPU_OUT6 : std_logic_vector(31 downto 0);

	signal zpu_pokey_enable : std_logic;
	signal zpu_sio_txd : std_logic;
	signal zpu_sio_rxd : std_logic;
	signal zpu_sio_command : std_logic;
	SIGNAL ASIO_CLOCKOUT : std_logic;

	-- system control from zpu
	signal ram_select : std_logic_vector(2 downto 0);
	signal reset_atari : std_logic;
	signal pause_atari : std_logic;
	SIGNAL speed_6502 : std_logic_vector(5 downto 0);
	signal turbo_vblank_only : std_logic;
	signal emulated_cartridge_select: std_logic_vector(5 downto 0);
	signal key_type : std_logic;
	signal atari800mode : std_logic;

	-- spi
	--signal spi_cs_n : std_logic;
	--signal spi_mosi : std_logic;
	--signal spi_clk : std_logic;

	-- scandoubler
	signal half_scandouble_enable_reg : std_logic;
	signal half_scandouble_enable_next : std_logic;
	signal VIDEO_B : std_logic_vector(7 downto 0);
	signal VGA_VS : std_logic;
	signal VGA_HS : std_logic;
	signal ir_data_sync : std_logic;


	-- turbo freezer!
	signal freezer_enable : std_logic;
	signal freezer_activate: std_logic;

	-- microcontroller (for slot flash)
	signal to_usb_rx : std_logic;

	-- atari keyboard
	signal shift_pressed : std_logic;
	signal control_pressed : std_logic;
	signal break_pressed : std_logic;
	signal consol_start_ps2 : std_logic;
	signal consol_start_int : std_logic;
	signal consol_select_ps2 : std_logic;
	signal consol_select_int : std_logic;
	signal consol_option_ps2 : std_logic;
	signal consol_option_int : std_logic;
	signal fkeys_ps2 : std_logic_vector(11 downto 0);
	signal fkeys_int : std_logic_vector(11 downto 0);
	signal keyboard_response_ps2 : std_logic_vector(1 downto 0);
	signal atari_keyboard : std_logic_vector(63 downto 0);
	signal atari_keyboard_ps2 : std_logic_vector(63 downto 0);

	signal PS2_KEYS : STD_LOGIC_VECTOR(511 downto 0);
	signal PS2_KEYS_NEXT : STD_LOGIC_VECTOR(511 downto 0);

	-- video settings
	signal pal : std_logic;
	signal scandouble : std_logic;
	signal scanlines : std_logic;
	signal csync : std_logic;
	signal video_mode : std_logic_vector(2 downto 0);

	-- flash memory slot
	signal flashslot : unsigned(4 downto 0);

	-- sync this, think its messing up state machine?
	signal ba_in_sync : std_logic;

begin
RESET_N <= PLL_LOCKED;
rtc_cs <= '0';   -- active high

-- Unused 
	iec_clk_out <= '0';
	iec_atn_out <= '0';
	iec_dat_out <= '0';
	iec_srq_out <= '0';
	irq_out <= '0';
	nmi_out <= '0';

--process(clk)
--begin
--	if rising_edge(clk) then
--		if reset_counter=X"FFFF" then
--			reset_n<='1';
--		else
--			reset_counter<=reset_counter+1;
--			reset_n<='0';
--		end if;
--	end if;
--end process;

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

-- pll

gen_ntsc_pll : if tv=0 generate
chameleon_pll2 : entity work.pll_ntsc
	PORT MAP
	(
		inclk0 => clk50m,
		c0 => clk_sdram,
		c1 => clk,
		c2 => ram_clk,
		locked => pll_locked
	);
end generate;

gen_pal_pll : if tv=1 generate
chameleon_pll2 : entity work.pll_pal
	PORT MAP
	(
		inclk0 => clk50m,
		c0 => clk_sdram,
		c1 => clk,
		c2 => ram_clk,
		locked => pll_locked
	);
end generate;
	
atarixl_simple_sdram1 : entity work.atari800core_simple_sdram
	GENERIC MAP
	(
		cycle_length => 32,
		internal_rom => 0,
		internal_ram => 0,
		video_bits => 8,
		palette => 0
	)
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N and SDRAM_RESET_N and not(reset_atari),

		-- VIDEO OUT - PAL/NTSC, original Atari timings approx (may be higher res)
		VIDEO_VS => VGA_VS_RAW,
		VIDEO_HS => VGA_HS_RAW,
		VIDEO_CS => VGA_CS_RAW,
		VIDEO_B => VIDEO_B,
		VIDEO_G => open,
		VIDEO_R => open,

		-- AUDIO OUT - Pokey/GTIA 1-bit and Covox all mixed
		AUDIO_L => audio_l_raw,
		AUDIO_R => audio_r_raw,

		-- JOYSTICK
		JOY1_n => std_logic_vector(docking_joystick1_reg and ir_joya)(4 downto 0),
		JOY2_n => std_logic_vector(docking_joystick2_reg and ir_joyb)(4 downto 0),
		JOY3_n => std_logic_vector(docking_joystick3_reg)(4 downto 0),
		JOY4_n => std_logic_vector(docking_joystick4_reg)(4 downto 0),

		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,
		KEYBOARD_SCAN => KEYBOARD_SCAN,

		SIO_COMMAND => zpu_sio_command,
		SIO_RXD => zpu_sio_txd,
		SIO_TXD => zpu_sio_rxd,
		SIO_CLOCKOUT => ASIO_CLOCKOUT,

		CONSOL_OPTION => CONSOL_OPTION or ir_option,
		CONSOL_SELECT => CONSOL_SELECT or ir_select,
		CONSOL_START => CONSOL_START or ir_start,

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

		DMA_FETCH => dma_fetch,
		DMA_READ_ENABLE => dma_read_enable,
		DMA_32BIT_WRITE_ENABLE => dma_32bit_write_enable,
		DMA_16BIT_WRITE_ENABLE => dma_16bit_write_enable,
		DMA_8BIT_WRITE_ENABLE => dma_8bit_write_enable,
		DMA_ADDR => dma_addr_fetch,
		DMA_WRITE_DATA => dma_write_data,
		MEMORY_READY_DMA => dma_memory_ready,
		DMA_MEMORY_DATA => dma_memory_data, 

   		RAM_SELECT => ram_select,
		PAL => PAL,
		HALT => pause_atari,
		THROTTLE_COUNT_6502 => speed_6502,
		TURBO_VBLANK_ONLY => turbo_vblank_only,
		emulated_cartridge_select => emulated_cartridge_select,
		freezer_enable => freezer_enable,
		freezer_activate => freezer_activate,
		atari800mode => atari800mode
	);

-- video glue
--nHSync <= (VGA_HS_RAW xor VGA_VS_RAW);
--nVSync <= (VGA_VS_RAW);

-- audio glue
dac_left : hq_dac
port map
(
  reset => not(reset_n),
  clk => clk,
  clk_ena => '1',
  pcm_in => AUDIO_L_RAW&"0000",
  dac_out => sigma_r
);

dac_right : hq_dac
port map
(
  reset => not(reset_n),
  clk => clk,
  clk_ena => '1',
  pcm_in => AUDIO_R_RAW&"0000",
  dac_out => sigma_l
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
		 SDRAM_DQ => ram_d,
		 COMPLETE => SDRAM_REQUEST_COMPLETE,
		 SDRAM_BA0 => ram_ba(0),
		 SDRAM_BA1 => ram_ba(1),
		 SDRAM_CKE => open,
		 SDRAM_CS_N => open,
		 SDRAM_RAS_N => ram_ras,
		 SDRAM_CAS_N => ram_cas,
		 SDRAM_WE_N => ram_we,
		 SDRAM_ldqm => ram_ldqm,
		 SDRAM_udqm => ram_udqm,
		 DATA_OUT => SDRAM_DO,
		 SDRAM_ADDR => ram_a(11 downto 0),
		 reset_client_n => SDRAM_RESET_N
		 );
		 
ram_a(12) <= '0';

-- PS2 to pokey
ps2iec_sel <= '0';
ps2_keyboard_clk_in <= ps2iec(2);
ps2_keyboard_dat_in <= ps2iec(3);
keyboard_map1 : entity work.ps2_to_atari800
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,
		PS2_CLK => ps2_keyboard_clk_in, 
		PS2_DAT => ps2_keyboard_dat_in,

 		ATARI_KEYBOARD_OUT => atari_keyboard_ps2,

		KEY_TYPE => key_type,
		
		KEYBOARD_SCAN => KEYBOARD_SCAN,
		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE_ps2,

		CONSOL_START => CONSOL_START_ps2,
		CONSOL_SELECT => CONSOL_SELECT_ps2,
		CONSOL_OPTION => CONSOL_OPTION_ps2,
		
		FKEYS => FKEYS_ps2,
		FREEZER_ACTIVATE => freezer_activate,

		PS2_KEYS_NEXT_OUT => ps2_keys_next,
		PS2_KEYS => ps2_keys
	);

	-- map to atari key code
	process(c64_keys_reg, consol_start_ps2, consol_select_ps2, consol_option_ps2, fkeys_ps2)
	begin
		atari_keyboard <= (others=>'0');
		fkeys_int <= (others=>'0');

		shift_pressed <= '0';
		control_pressed <= '0';
		break_pressed <= '0';
		consol_start_int <= '0';
		consol_select_int <= '0';
		consol_option_int <= '0';
		
		atari_keyboard(63)<=not(c64_keys_reg(17));
		atari_keyboard(21)<=not(c64_keys_reg(35));
		atari_keyboard(18)<=not(c64_keys_reg(34));
		atari_keyboard(58)<=not(c64_keys_reg(18));
		atari_keyboard(42)<=not(c64_keys_reg(49));
		atari_keyboard(56)<=not(c64_keys_reg(42));
		atari_keyboard(61)<=not(c64_keys_reg(19));
		atari_keyboard(57)<=not(c64_keys_reg(43));
		atari_keyboard(13)<=not(c64_keys_reg(12));
		atari_keyboard(1)<=not(c64_keys_reg(20));
		atari_keyboard(5)<=not(c64_keys_reg(44));
		atari_keyboard(0)<=not(c64_keys_reg(21));
		atari_keyboard(37)<=not(c64_keys_reg(36));
		atari_keyboard(35)<=not(c64_keys_reg(60));
		atari_keyboard(8)<=not(c64_keys_reg(52));
		atari_keyboard(10)<=not(c64_keys_reg(13));
		atari_keyboard(47)<=not(c64_keys_reg(55));
		atari_keyboard(40)<=not(c64_keys_reg(10));
		atari_keyboard(62)<=not(c64_keys_reg(41));
		atari_keyboard(45)<=not(c64_keys_reg(50));
		atari_keyboard(11)<=not(c64_keys_reg(51));
		atari_keyboard(16)<=not(c64_keys_reg(59));
		atari_keyboard(46)<=not(c64_keys_reg(9));
		atari_keyboard(22)<=not(c64_keys_reg(58));
		atari_keyboard(43)<=not(c64_keys_reg(11));
		atari_keyboard(23)<=not(c64_keys_reg(33));
		atari_keyboard(50)<=not(c64_keys_reg(28));
		atari_keyboard(31)<=not(c64_keys_reg(7));
		atari_keyboard(30)<=not(c64_keys_reg(31));
		atari_keyboard(26)<=not(c64_keys_reg(1));
		atari_keyboard(24)<=not(c64_keys_reg(25));
		atari_keyboard(29)<=not(c64_keys_reg(2));
		atari_keyboard(27)<=not(c64_keys_reg(26));
		atari_keyboard(51)<=not(c64_keys_reg(3));
		atari_keyboard(53)<=not(c64_keys_reg(27));
		atari_keyboard(48)<=not(c64_keys_reg(4));
		atari_keyboard(17)<=not(c64_keys_reg(30));
		atari_keyboard(52)<=not(c64_keys_reg(0));
		atari_keyboard(28)<=not(c64_keys_reg(15));
		atari_keyboard(39)<=not(c64_keys_reg(47));
		atari_keyboard(60)<=not(c64_keys_reg(6));
		atari_keyboard(44)<=not(c64_keys_reg(54));
		atari_keyboard(12)<=not(c64_keys_reg(8));
		atari_keyboard(33)<=not(c64_keys_reg(39));
		atari_keyboard(54)<=not(c64_keys_reg(5));
		atari_keyboard(55)<=not(c64_keys_reg(29));
		atari_keyboard(15)<=not(c64_keys_reg(14));
		atari_keyboard(14)<=not(c64_keys_reg(53));
		atari_keyboard(6)<=not(c64_keys_reg(22));
		atari_keyboard(7)<=not(c64_keys_reg(46));
		atari_keyboard(38)<=not(c64_keys_reg(62));
		atari_keyboard(2)<=not(c64_keys_reg(45));
		atari_keyboard(32)<=not(c64_keys_reg(61));
		atari_keyboard(34)<=not(c64_keys_reg(37));
		shift_pressed<=not(c64_keys_reg(57)) or not(c64_keys_reg(38));
		break_pressed<=not(c64_keys_reg(63));
		control_pressed<=not(c64_keys_reg(23));
		consol_start_int<=not(c64_keys_reg(32));
		consol_select_int<=not(c64_keys_reg(40));
		consol_option_int<=not(c64_keys_reg(48));
		
		fkeys_int(8)<=not(c64_keys_reg(24)) and c64_keys_reg(23);
		fkeys_int(9)<=not(c64_keys_reg(24)) and not(c64_keys_reg(23));
		fkeys_int(10)<=not(c64_keys_reg(56));
		fkeys_int(11)<=not(c64_keys_reg(16));
				
--		atari_keyboard(63)<=ps2_keys_reg(16#1C#);
--		atari_keyboard(21)<=ps2_keys_reg(16#32#);
--		atari_keyboard(18)<=ps2_keys_reg(16#21#);
--		atari_keyboard(58)<=ps2_keys_reg(16#23#);
--		atari_keyboard(42)<=ps2_keys_reg(16#24#);
--		atari_keyboard(56)<=ps2_keys_reg(16#2B#);
--		atari_keyboard(61)<=ps2_keys_reg(16#34#);
--		atari_keyboard(57)<=ps2_keys_reg(16#33#);
--		atari_keyboard(13)<=ps2_keys_reg(16#43#);
--		atari_keyboard(1)<=ps2_keys_reg(16#3B#);
--		atari_keyboard(5)<=ps2_keys_reg(16#42#);
--		atari_keyboard(0)<=ps2_keys_reg(16#4B#);
--		atari_keyboard(37)<=ps2_keys_reg(16#3A#);
--		atari_keyboard(35)<=ps2_keys_reg(16#31#);
--		atari_keyboard(8)<=ps2_keys_reg(16#44#);
--		atari_keyboard(10)<=ps2_keys_reg(16#4D#);
--		atari_keyboard(47)<=ps2_keys_reg(16#15#);
--		atari_keyboard(40)<=ps2_keys_reg(16#2D#);
--		atari_keyboard(62)<=ps2_keys_reg(16#1B#);
--		atari_keyboard(45)<=ps2_keys_reg(16#2C#);
--		atari_keyboard(11)<=ps2_keys_reg(16#3C#);
--		atari_keyboard(16)<=ps2_keys_reg(16#2A#);
--		atari_keyboard(46)<=ps2_keys_reg(16#1D#);
--		atari_keyboard(22)<=ps2_keys_reg(16#22#);
--		atari_keyboard(43)<=ps2_keys_reg(16#35#);
--		atari_keyboard(23)<=ps2_keys_reg(16#1A#);
--		atari_keyboard(50)<=ps2_keys_reg(16#45#);
--		atari_keyboard(31)<=ps2_keys_reg(16#16#);
--		atari_keyboard(30)<=ps2_keys_reg(16#1E#);
--		atari_keyboard(26)<=ps2_keys_reg(16#26#);
--		atari_keyboard(24)<=ps2_keys_reg(16#25#);
--		atari_keyboard(29)<=ps2_keys_reg(16#2E#);
--		atari_keyboard(27)<=ps2_keys_reg(16#36#);
--		atari_keyboard(51)<=ps2_keys_reg(16#3D#);
--		atari_keyboard(53)<=ps2_keys_reg(16#3E#);
--		atari_keyboard(48)<=ps2_keys_reg(16#46#);
--		--atari_keyboard(17)<=ps2_keys_reg(16#ec#);
--		--atari_keyboard(17)<=ps2_keys_reg(16#16c#);
--		atari_keyboard(17)<=ps2_keys_reg(16#16c#) or ps2_keys_reg(16#03#);
--		atari_keyboard(52)<=ps2_keys_reg(16#66#);
--		atari_keyboard(28)<=ps2_keys_reg(16#76#);
--		--atari_keyboard(39)<=ps2_keys_reg(16#91#);
--		atari_keyboard(39)<=ps2_keys_reg(16#111#);
--		atari_keyboard(60)<=ps2_keys_reg(16#58#);
--		atari_keyboard(44)<=ps2_keys_reg(16#0D#);
--		atari_keyboard(12)<=ps2_keys_reg(16#5A#);
--		atari_keyboard(33)<=ps2_keys_reg(16#29#);
--		atari_keyboard(54)<=ps2_keys_reg(16#4E#);
--		atari_keyboard(55)<=ps2_keys_reg(16#55#);
--		atari_keyboard(15)<=ps2_keys_reg(16#5B#);
--		atari_keyboard(14)<=ps2_keys_reg(16#54#);
--		atari_keyboard(6)<=ps2_keys_reg(16#52#);
--		atari_keyboard(7)<=ps2_keys_reg(16#5D#);
--		atari_keyboard(38)<=ps2_keys_reg(16#4A#);
--		atari_keyboard(2)<=ps2_keys_reg(16#4C#);
--		atari_keyboard(32)<=ps2_keys_reg(16#41#);
--		atari_keyboard(34)<=ps2_keys_reg(16#49#);
--
--		atari_keyboard(3)<=ps2_keys_reg(16#05#);
--		atari_keyboard(4)<=ps2_keys_reg(16#06#);
--		atari_keyboard(19)<=ps2_keys_reg(16#04#);
--		atari_keyboard(20)<=ps2_keys_reg(16#0c#);
--
--		consol_start_int<=ps2_keys_reg(16#0B#);
--		consol_select_int<=ps2_keys_reg(16#83#);
--		consol_option_int<=ps2_keys_reg(16#0a#);
--		shift_pressed<=ps2_keys_reg(16#12#) or ps2_keys_reg(16#59#);
--		--control_pressed<=ps2_keys_reg(16#14#) or ps2_keys_reg(16#94#);
--		control_pressed<=ps2_keys_reg(16#14#) or ps2_keys_reg(16#114#);
--		break_pressed<=ps2_keys_reg(16#77#);
--
--		fkeys_int(0)<=ps2_keys_reg(16#05#);
--		fkeys_int(1)<=ps2_keys_reg(16#06#);
--		fkeys_int(2)<=ps2_keys_reg(16#04#);
--		fkeys_int(3)<=ps2_keys_reg(16#0C#);
--		fkeys_int(4)<=ps2_keys_reg(16#03#);
--		fkeys_int(5)<=ps2_keys_reg(16#0B#);
--		fkeys_int(6)<=ps2_keys_reg(16#83#);
--		fkeys_int(7)<=ps2_keys_reg(16#0a#);
--		fkeys_int(8)<=ps2_keys_reg(16#01#);
--		fkeys_int(9)<=ps2_keys_reg(16#09#);
--		fkeys_int(10)<=ps2_keys_reg(16#78#);
--		fkeys_int(11)<=ps2_keys_reg(16#07#);

		--merge special keys
		consol_start<=consol_start_ps2 or consol_start_int;
		consol_select<=consol_select_ps2 or consol_select_int;
		consol_option<=consol_option_ps2 or consol_option_int;
		fkeys<=fkeys_ps2 or fkeys_int;

	end process;

	process(keyboard_scan, atari_keyboard, control_pressed, shift_pressed, break_pressed, keyboard_response_ps2)
		begin	
			keyboard_response <= keyboard_response_ps2;
			
			if (atari_keyboard(to_integer(unsigned(not(keyboard_scan)))) = '1') then
				keyboard_response(0) <= '0';
			end if;
			
			if (keyboard_scan(5 downto 4)="00" and break_pressed = '1') then
				keyboard_response(1) <= '0';
			end if;
			
			if (keyboard_scan(5 downto 4)="10" and shift_pressed = '1') then
				keyboard_response(1) <= '0';
			end if;

			if (keyboard_scan(5 downto 4)="11" and control_pressed = '1') then
				keyboard_response(1) <= '0';
			end if;
	end process;		 

zpu: entity work.zpucore
	GENERIC MAP
	(
		platform => 1, -- TODO
		spi_clock_div => 16, -- 57MHz/32. Max for SD cards is 25MHz... TODO Same for DE1, too high??
		nMHz_clock_div => 50
	)
	PORT MAP
	(
		-- standard...
		CLK => CLK,
		RESET_N => RESET_N and sdram_reset_n,

		-- dma bus master (with many waitstates...)
		ZPU_ADDR_FETCH => dma_addr_fetch,
		ZPU_DATA_OUT => dma_write_data,
		ZPU_FETCH => dma_fetch,
		ZPU_32BIT_WRITE_ENABLE => dma_32bit_write_enable,
		ZPU_16BIT_WRITE_ENABLE => dma_16bit_write_enable,
		ZPU_8BIT_WRITE_ENABLE => dma_8bit_write_enable,
		ZPU_READ_ENABLE => dma_read_enable,
		ZPU_MEMORY_READY => dma_memory_ready,
		ZPU_MEMORY_DATA => dma_memory_data, 

		-- rom bus master
		-- data on next cycle after addr
		ZPU_ADDR_ROM => zpu_addr_rom,
		ZPU_ROM_DATA => zpu_rom_data,

		-- spi master
		-- Too painful to bit bang spi from zpu, so we have a hardware master in here
		ZPU_SPI_DI => spi_miso,
		ZPU_SPI_CLK => spi_clk,
		ZPU_SPI_DO => spi_mosi,
		ZPU_SPI_SELECT0 => mmc_cs, 
		ZPU_SPI_SELECT1 => flash_cs, 

		-- SIO
		-- Ditto for speaking to Atari, we have a built in Pokey
		ZPU_POKEY_ENABLE => zpu_pokey_enable,
		ZPU_SIO_TXD => zpu_sio_txd,
		ZPU_SIO_RXD => zpu_sio_rxd,
		ZPU_SIO_COMMAND => zpu_sio_command,
		ZPU_SIO_CLK => ASIO_CLOCKOUT,

		-- external control
		-- switches etc. sector DMA blah blah.
		ZPU_IN1 => X"000"&
			mmc_wp&mmc_cd&
			(atari_keyboard(28) or atari_keyboard_ps2(28) or ir_escape)&ps2_keys(16#5A#)&ps2_keys(16#174#)&ps2_keys(16#16B#)&ps2_keys(16#172#)&ps2_keys(16#175#)& -- (esc)FLRDU
			(FKEYS or ir_fkeys_reg),
		ZPU_IN2(31 downto 5) => (others=>'0'),
		ZPU_IN2(4 downto 0) => std_logic_vector(flashslot),
		ZPU_IN3 => atari_keyboard(31 downto 0) or atari_keyboard_ps2(31 downto 0),
		ZPU_IN4 => atari_keyboard(63 downto 32) or atari_keyboard_ps2(63 downto 32),

		-- nMHz clock
		CLK_nMHz => clk50m,

		-- ouputs - e.g. Atari system control, halt, throttle, rom select
		ZPU_OUT1 => zpu_out1,
		ZPU_OUT2 => zpu_out2,
		ZPU_OUT3 => zpu_out3,
		ZPU_OUT4 => zpu_out4,
		ZPU_OUT5 => open, -- usb analog stick
		ZPU_OUT6 => zpu_out6
	);

	pause_atari <= zpu_out1(0);
	reset_atari <= zpu_out1(1) or reset_short_reg;
	speed_6502 <= zpu_out1(7 downto 2);
	ram_select <= zpu_out1(10 downto 8);
	atari800mode <= zpu_out1(11);
	emulated_cartridge_select <= zpu_out1(22 downto 17);
	freezer_enable <= zpu_out1(25);
	key_type <= zpu_out1(26);

	turbo_vblank_only <= zpu_out1(31);

	video_mode <= zpu_out6(2 downto 0);
	PAL <= zpu_out6(4);
	scanlines <= zpu_out6(5);
	csync <= zpu_out6(6);

process(video_mode)
begin
	SCANDOUBLE <= '0';

	-- original RGB
	-- scandoubled RGB (works on some vga devices...)
	-- svideo
	-- hdmi with audio  (and vga exact mode...)
	-- dvi (i.e. no preamble or audio) (and vga exact mode...)
	-- vga exact mode (hdmi off)
	-- composite (todo firmware...)

	case video_mode is
		when "000" =>
		when "001" =>
			SCANDOUBLE <= '1';
		when "010" => -- svideo
			-- not supported
		when "011" =>
			-- not supported
		when "100" =>
			-- not supported
		when "101" =>
			-- not supported
		when "110" => -- composite
			-- not supported

		when others =>
	end case;
end process;

zpu_rom1: entity work.zpu_rom
	port map(
	        clock => clk,
	        address => zpu_addr_rom(14 downto 2),
	        q => zpu_rom_data
	);

enable_179_clock_div_zpu_pokey : entity work.enable_divider
	generic map (COUNT=>32) -- cycle_length
	port map(clk=>clk,reset_n=>reset_n,enable_in=>'1',enable_out=>zpu_pokey_enable);

-----
-- scandoubler
-----
	process(clk,RESET_N,SDRAM_RESET_N,reset_atari)
	begin
		if ((RESET_N and SDRAM_RESET_N and not(reset_atari))='0') then
			half_scandouble_enable_reg <= '0';
		elsif (clk'event and clk='1') then
			half_scandouble_enable_reg <= half_scandouble_enable_next;
		end if;
	end process;

	half_scandouble_enable_next <= not(half_scandouble_enable_reg);

	scandoubler1: entity work.scandoubler
	GENERIC MAP
	(
		video_bits=>5
	)
	PORT MAP
	( 
		CLK => CLK,
		RESET_N => RESET_N and SDRAM_RESET_N and not(reset_atari),
		
		VGA => scandouble,
		COMPOSITE_ON_HSYNC => csync,

		colour_enable => half_scandouble_enable_reg,
		doubled_enable => '1',
		scanlines_on => scanlines,
		
		-- GTIA interface
		pal => pal,
		colour_in => VIDEO_B,
		vsync_in => VGA_VS_RAW,
		hsync_in => VGA_HS_RAW,
		csync_in => VGA_CS_RAW,
		
		-- TO TV...
		R => red,
		G => grn,
		B => blu,
		
		VSYNC => VGA_VS,
		HSYNC => VGA_HS
	);
hsync_n <= VGA_HS;
vsync_n <= VGA_VS;

process(clk,reset_n)
begin
	if (reset_n='0') then
		chameleon_reset_n_reg <= (others=>'1');
		reconfig_reg <= '0';
		reset_long_reg <= '0';
		reset_short_reg <= '0';
		c64_keys_reg <= (others=>'1');
		docking_joystick1_reg <= (others=>'1');
		docking_joystick2_reg <= (others=>'1');
		docking_joystick3_reg <= (others=>'1');
		docking_joystick4_reg <= (others=>'1');
		ir_fkeys_reg <= (others=>'0');
	elsif (clk'event and clk = '1') then
		chameleon_reset_n_reg <= chameleon_reset_n_next;
		reconfig_reg <= reconfig_next;
		reset_long_reg <= reset_long_next;
		reset_short_reg <= reset_short_next;
		c64_keys_reg <= c64_keys_next;
		docking_joystick1_reg <= docking_joystick1_next;
		docking_joystick2_reg <= docking_joystick2_next;
		docking_joystick3_reg <= docking_joystick3_next;
		docking_joystick4_reg <= docking_joystick4_next;
		ir_fkeys_reg <= ir_fkeys_next;
	end if;
end process;

-- 10hz for crappy debounce!
	my10khz : entity work.enable_divider
		generic map (
			count => 5700
		)
		port map (
			clk => clk,
			reset_n => reset_n,
			enable_in => '1',
			enable_out => ena_10khz
		);

		my10hz : entity work.enable_divider
		generic map (
			count => 1000
		)
		port map (
			clk => clk,
			reset_n => reset_n,
			enable_in => ena_10khz,
			enable_out => ena_10hz
		);

chameleon_reset_n_next(0) <= reset_btn;

process(ena_10hz, chameleon_reset_n_reg, reconfig_reg, reset_long_reg, reset_short_reg)
begin
	reconfig_next <= reconfig_reg;
	chameleon_reset_n_next(6 downto 1) <= chameleon_reset_n_reg(6 downto 1);
	reset_short_next <= reset_short_reg;
	reset_long_next <= reset_long_reg;
	reconfig_next <= reconfig_reg or reset_long_reg;
	
	if (ena_10hz = '1') then
		reset_short_next <= '0';
		reset_long_next <= '0';
	
		chameleon_reset_n_next(6 downto 1) <= chameleon_reset_n_reg(5 downto 0);

		if (chameleon_reset_n_reg(0) = '0') then
			reset_short_next <= '1';
		end if;
		if (or_reduce(chameleon_reset_n_reg(6 downto 0)) = '0') then
			reset_long_next <= '1';
		end if;
	end if;
end process;

-- -----------------------------------------------------------------------
-- 1 Mhz and 1 Khz clocks
-- -----------------------------------------------------------------------
	my1Mhz : entity work.chameleon_1mhz
		generic map (
			clk_ticks_per_usec => 113
		)
		port map (
			clk => clk_sdram,
			ena_1mhz => ena_1mhz,
			ena_1mhz_2 => open
		);

	my1Khz : entity work.chameleon_1khz
		port map (
			clk => clk_sdram,
			ena_1mhz => ena_1mhz,
			ena_1khz => ena_1khz
		);

ir_data_synchron : entity work.synchronizer
PORT MAP ( CLK => clk, raw => ir_data, sync=>ir_data_sync);

myIr : entity work.chameleon_cdtv_remote
	port map (
		clk => clk_sdram,
		ena_1mhz => ena_1mhz,
		ir => ir_data_sync,

--		trigger : out std_logic;
--
		key_1 => ir_fkeys_next(0),
		key_2 => ir_fkeys_next(1),
		key_3 => ir_fkeys_next(2),
		key_4 => ir_fkeys_next(3),
--		key_5 => ir_fkeys_next(4),
--		key_6 => ir_fkeys_next(5),
--		key_7 => ir_fkeys_next(6),
--		key_8 => ir_fkeys_next(7),
--		key_9 => ir_fkeys_next(8),
--		key_0 => ir_fkeys_next(9),
--		key_escape : out std_logic;
--		key_enter : out std_logic;
		key_escape => ir_escape,
		key_genlock => ir_fkeys_next(10),
		key_cdtv => ir_fkeys_next(11),
		key_power => ir_fkeys_next(9),
		key_rew => ir_start,
		key_play => ir_select,
		key_ff => ir_option,
		key_stop => ir_fkeys_next(8),
--		key_vol_up : out std_logic;
--		key_vol_dn : out std_logic;
		joystick_a => ir_joya,
		joystick_b => ir_joyb
--		debug_code : out unsigned(11 downto 0)
	);


ba_synchron : entity work.synchronizer
PORT MAP ( CLK => clk, raw => ba_in, sync=>ba_in_sync);

chameleon_io_inst : entity work.chameleon2_io 
	generic map (
		enable_docking_station => true,
		enable_cdtv_remote => false,
		enable_c64_joykeyb => true,
		enable_c64_4player  => true
	)
	port map(
-- Clocks
		clk => clk_sdram,
		ena_1mhz => ena_1mhz,
		phi2_n => phi2_n,
		dotclock_n => dotclk_n,

-- Control
		reset => not(reset_n), -- active high!!
		
-- Toplevel signals
		ir_data => ir_data_sync,

		clock_ior => clock_ior,
		clock_iow => clock_iow,

		ioef => ioef,
		romlh => romlh,
		
		dma_out => dma_out,
		game_out => game_out,
		exrom_out => exrom_out,

		ba_in => ba_in_sync,
--		rw_in : in std_logic;
		rw_out => rw_out,

		sa_dir => sa_dir,
		sa_oe => sa_oe,
		sa15_out => sa15_out,
		low_a => low_a,

		sd_dir => sd_dir,
		sd_oe => sd_oe,
		low_d => low_d,

-- Config
		no_clock => no_clock,
		docking_station => docking_station,

-- C64 timing (only for C64 related cores)
		phi_mode => not(PAL),
		phi_out => open,
		phi_cnt => open,
		phi_end_0 => open,
		phi_end_1 => open,
		phi_post_1 => open,
		phi_post_2 => open,
		phi_post_3 => open,
		phi_post_4 => open,
		
-- C64 bus (only for C64 related cores)
--		c64_vicii_data : in unsigned(7 downto 0) := (others => '1');
--		c64_cs : in std_logic := '0';
--		c64_cs_roms : in std_logic := '0';
--		c64_cs_vicii : in std_logic := '0';
--		c64_cs_clockport : in std_logic := '0';
--		c64_we : in std_logic := '0';
--		c64_a : in unsigned(15 downto 0) := (others => '0');
--		c64_d : in unsigned(7 downto 0) := (others => '1');
--		c64_q : out unsigned(7 downto 0);

-- Joysticks
		joystick1 => docking_joystick1_next,
		joystick2 => docking_joystick2_next,
		joystick3 => docking_joystick3_next,
		joystick4 => docking_joystick4_next,

-- Keyboards
		--  0 = col0, row0
		--  1 = col1, row0
		--  8 = col0, row1
		-- 63 = col7, row7
		--keys => c64_keys_next
		keys => c64_keys_next
--		restore_key_n : out std_logic;
--		amiga_reset_n : out std_logic;
--		amiga_trigger : out std_logic;
--		amiga_scancode : out unsigned(7 downto 0)
	);

	io_shiftreg_inst : entity work.chameleon2_io_shiftreg
	port map (
		clk => clk_sdram,

		ser_out_clk => ser_out_clk,
		ser_out_dat => ser_out_dat,
		ser_out_rclk => ser_out_rclk,

		reset_c64 => '0', -- system_reset,
		reset_iec => '0',
		ps2_mouse_clk => '1',
		ps2_mouse_dat => '1',
		ps2_keyboard_clk => '1',
		ps2_keyboard_dat => '1',
		led_green => '1',
		led_red => not(zpu_sio_txd)
	);

usb : entity work.chameleon_usb
	port map (
		clk => clk_sdram,
		
		req => open,
		we => open,
		a => open,
		q => open,
		
		reconfig => reconfig_reg,
		reconfig_slot => "0000",
		
		flashslot => flashslot, 
		
		-- talk to microcontroller
		serial_clk => usart_clk,
		serial_rxd => usart_tx,
		serial_txd => usart_rx,
		serial_cts_n => usart_rts,
		
		serial_debug_trigger => open,
		serial_debug_data => open
	);

end vhdl;
