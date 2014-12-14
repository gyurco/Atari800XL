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

ENTITY atari800core_sockit IS
        PORT
        (
	--//////////// CLOCK //////////
	OSC_50_B3B : in std_logic;
	OSC_50_B4A : in std_logic;
	OSC_50_B5B : in std_logic;
	OSC_50_B8A : in std_logic;

	--//////////// LED //////////
	LED : out std_logic_vector(3 downto 0);

	--//////////// KEY //////////
	KEY : in std_logic_vector(3 downto 0);
	RESET_n : in std_logic;

	--//////////// SW //////////
	SW : in std_logic_vector(3 downto 0);

	--//////////// Si5338 //////////
	SI5338_SCL : out std_logic;
	SI5338_SDA : inout std_logic;

	--//////////// Temperature //////////
	TEMP_CS_n : out std_logic;
	TEMP_DIN : out std_logic;
	TEMP_DOUT : in std_logic;
	TEMP_SCLK : out std_logic;

	--//////////// VGA //////////
	VGA_B : out std_logic_vector(7 downto 0);
	VGA_BLANK_n : out std_logic;
	VGA_CLK : out std_logic;
	VGA_G : out std_logic_vector(7 downto 0);
	VGA_HS : out std_logic;
	VGA_R : out std_logic_vector(7 downto 0);
	VGA_SYNC_n : out std_logic;
	VGA_VS : out std_logic;

	--//////////// Audio //////////
	AUD_ADCDAT : inout std_logic;
	AUD_ADCLRCK : inout std_logic;
	AUD_BCLK : inout std_logic;
	AUD_DACDAT : out std_logic;
	AUD_DACLRCK : inout std_logic;
	AUD_MUTE : out std_logic;
	AUD_XCK : out std_logic;

	--//////////// I2C for Audio  //////////
	AUD_I2C_SCLK : out std_logic;
	AUD_I2C_SDAT : inout std_logic;

	--//////////// SDRAM //////////
	DDR3_A : out std_logic_vector(14 downto 0);
	DDR3_BA : out std_logic_vector(2 downto 0);
	DDR3_CAS_n : out std_logic;
	DDR3_CK_n : out std_logic;
	DDR3_CK_p : out std_logic;
	DDR3_CKE : out std_logic;
	DDR3_CS_n : out std_logic;
	DDR3_DM : out std_logic_vector(3 downto 0);
	DDR3_DQ : inout std_logic_vector(31 downto 0);
	DDR3_DQS_n : inout std_logic_vector(3 downto 0);
	DDR3_DQS_p : inout std_logic_vector(3 downto 0);
	DDR3_ODT : out std_logic;
	DDR3_RAS_n : out std_logic;
	DDR3_RESET_n : out std_logic;
	DDR3_RZQ : in std_logic;
	DDR3_WE_n : out std_logic;

	--//////////// HSMC : in std_logic; HSMC connect to HTG - HSMC to PIO Adaptor //////////
	GPIO0 : inout std_logic_vector(35 downto 0);
	GPIO1 : inout std_logic_vector(35 downto 0)
	);
END atari800core_sockit;

ARCHITECTURE vhdl OF atari800core_sockit IS 
	function vectorize(s: std_logic) return std_logic_vector is
	variable v: std_logic_vector(0 downto 0);
	begin
		v(0) := s;
		return v;
	end;

-- PLL
signal CLK : std_logic;
signal PLL_LOCKED : std_logic;

-- VGA
signal VGA_HS_RAW : std_logic;
signal VGA_VS_RAW : std_logic;
signal VGA_BLANK : std_logic;
BEGIN
	-- safe defaults
	LED <= "1010";

	SI5338_SCL <= 'Z';
	SI5338_SDA <= 'Z';

	TEMP_CS_n <= '1';
	TEMP_DIN <= 'Z';
	TEMP_SCLK <= 'Z';

	AUD_ADCDAT <= 'Z';
	AUD_ADCLRCK <= 'Z';
	AUD_BCLK <= 'Z';
	AUD_DACDAT <= '0';
	AUD_DACLRCK <= 'Z';
	AUD_MUTE <= '0';
	AUD_XCK <= '0';

	AUD_I2C_SCLK <= '0';
	AUD_I2C_SDAT <= 'Z';

	-- Hmmm, ddr3 controller? I thought it had a hard controller...
	DDR3_A <= (others=>'0');
	DDR3_BA <= (others=>'0');
	DDR3_CAS_n <= '1';
	--DDR3_CK_n <= '0';
	--DDR3_CK_p <= '1';
	DDR3_CKE <= '0';
	DDR3_CS_n <= '1';
	DDR3_DM <= (others=>'Z');
	DDR3_DQ <= (others=>'Z');
	--DDR3_DQS_n <= (others=>'0');
	--DDR3_DQS_p <= (others=>'1');
	DDR3_ODT <= 'Z';
	DDR3_RAS_n <= '1';
	DDR3_RESET_n <= '1';
	DDR3_WE_n <= '1';

iobuf1: ENTITY  work.altiobuf_iobuf_bidir_lup
	 PORT  MAP
	 ( 
		 datain	=> "0000",
		 dataio	=> DDR3_DQS_p,
		 dataio_b => DDR3_DQS_n,
		 dataout => open,
		 oe=> "1111",
		 oe_b=> "1111"
	 ); 

iobuf2: ENTITY  work.altiobufo_iobuf_out_h5u
	 PORT MAP
	 ( 
		 datain	=> "0",
		 dataout(0) => DDR3_CK_p,
		 dataout_b(0) => DDR3_CK_n,
		 oe	=> "0",
		 oe_b	=> "0"
	 ); 

	GPIO0 <= (others=>'Z');
	GPIO1 <= (others=>'Z');

	-- pll
pll : entity work.pll_pal
	PORT MAP(refclk => OSC_50_B3B,
	rst => not(reset_n),
	outclk_0 => CLK,
	locked => PLL_LOCKED);

	-- vga
	VGA_HS <= not(VGA_HS_RAW xor VGA_VS_RAW);
	VGA_VS <= not(VGA_VS_RAW);
	VGA_SYNC_N <= not(VGA_HS_RAW xor VGA_VS_RAW);
	VGA_BLANK_N <= NOT(VGA_BLANK);
	VGA_CLK <= CLK;

	-- Atari 800 core... With internal ROM/RAM.
atari800core1 : ENTITY work.atari800core_simple_sdram
	GENERIC MAP
	(
		cycle_length => 32,

		video_bits => 8,
		palette => 1,
	
		internal_rom => 1,
		internal_ram => 65536
	)
	PORT MAP
	(
		CLK => CLK,
		RESET_N => PLL_LOCKED,

		-- VIDEO OUT - PAL/NTSC, original Atari timings approx (may be higher res)
		VIDEO_VS => VGA_VS_RAW,
		VIDEO_HS => VGA_HS_RAW,
		VIDEO_B => VGA_B,
		VIDEO_G => VGA_G,
		VIDEO_R => VGA_R,
			-- These ones are probably only needed for e.g. svideo
		VIDEO_BLANK => VGA_BLANK,
		VIDEO_BURST => open,
		VIDEO_START_OF_FIELD => open,
		VIDEO_ODD_LINE => open,

		-- AUDIO OUT - Pokey/GTIA 1-bit and Covox all mixed
		-- TODO - choose stereo/mono pokey
		AUDIO_L => open,
		AUDIO_R => open,

		-- JOYSTICK
		JOY1_n => (others=>'0'),
		JOY2_n => (others=>'0'),

		-- Pokey keyboard matrix
		-- Standard component available to connect this to PS2
		KEYBOARD_RESPONSE => "11",
		KEYBOARD_SCAN => open,

		-- SIO
		SIO_COMMAND => open,
		SIO_RXD => '1',
		SIO_TXD => open,

		-- GTIA consol
		CONSOL_OPTION => '0',
		CONSOL_SELECT => '0',
		CONSOL_START => '0',

		SDRAM_REQUEST => open,
		SDRAM_REQUEST_COMPLETE => '1',
		SDRAM_READ_ENABLE => open,
		SDRAM_WRITE_ENABLE => open,
		SDRAM_ADDR => open,
		SDRAM_DO => (others=>'0'),
		SDRAM_DI => open,
		SDRAM_32BIT_WRITE_ENABLE => open,
		SDRAM_16BIT_WRITE_ENABLE => open,
		SDRAM_8BIT_WRITE_ENABLE => open,
		SDRAM_REFRESH => open,

		DMA_FETCH => '0',
		DMA_READ_ENABLE => '0',
		DMA_32BIT_WRITE_ENABLE => '0',
		DMA_16BIT_WRITE_ENABLE => '0',
		DMA_8BIT_WRITE_ENABLE => '0',
		DMA_ADDR => (others=>'0'),
		DMA_WRITE_DATA => (others=>'0'),
		MEMORY_READY_DMA => open,
		DMA_MEMORY_DATA => open,

		-- Special config params
   		RAM_SELECT => (others=>'0'), -- 64K,128K,320KB Compy, 320KB Rambo, 576K Compy, 576K Rambo, 1088K, 4MB
    		ROM_SELECT => "000001",
		PAL => '1',
		HALT => '0',
		THROTTLE_COUNT_6502 => "000001",
		emulated_cartridge_select => (others=>'0'),
		freezer_enable => '0',
		freezer_activate => '0'
	);

END vhdl;

