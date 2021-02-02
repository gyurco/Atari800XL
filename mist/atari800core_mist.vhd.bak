--------------------------------------------------------------------------- -- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

LIBRARY work;

ENTITY atari800core_mist IS 
	PORT
	(
		CLOCK_27 :  IN  STD_LOGIC_VECTOR(1 downto 0);

		VGA_VS :  OUT  STD_LOGIC;
		VGA_HS :  OUT  STD_LOGIC;
		VGA_B :  OUT  STD_LOGIC_VECTOR(5 DOWNTO 0);
		VGA_G :  OUT  STD_LOGIC_VECTOR(5 DOWNTO 0);
		VGA_R :  OUT  STD_LOGIC_VECTOR(5 DOWNTO 0);
		
		AUDIO_L : OUT std_logic;
		AUDIO_R : OUT std_logic;

		SDRAM_BA :  OUT  STD_LOGIC_VECTOR(1 downto 0);
		SDRAM_nCS :  OUT  STD_LOGIC;
		SDRAM_nRAS :  OUT  STD_LOGIC;
		SDRAM_nCAS :  OUT  STD_LOGIC;
		SDRAM_nWE :  OUT  STD_LOGIC;
		SDRAM_DQMH :  OUT  STD_LOGIC;
		SDRAM_DQML :  OUT  STD_LOGIC;
		SDRAM_CLK :  OUT  STD_LOGIC;
		SDRAM_CKE :  OUT  STD_LOGIC;
		SDRAM_A :  OUT  STD_LOGIC_VECTOR(12 DOWNTO 0);
		SDRAM_DQ :  INOUT  STD_LOGIC_VECTOR(15 DOWNTO 0);

		LED : OUT std_logic;
		
		UART_TX :  OUT  STD_LOGIC;
		UART_RX :  IN  STD_LOGIC;
		
		SPI_DO :  INOUT  STD_LOGIC;
		SPI_DI :  IN  STD_LOGIC;
		SPI_SCK :  IN  STD_LOGIC;
		SPI_SS2 :  IN  STD_LOGIC;		
		SPI_SS3 :  IN  STD_LOGIC;		
		SPI_SS4 :  IN  STD_LOGIC;
		CONF_DATA0 :  IN  STD_LOGIC -- AKA SPI_SS5
	);
END atari800core_mist;

ARCHITECTURE vhdl OF atari800core_mist IS 

component hq_dac
port (
  reset :in std_logic;
  clk :in std_logic;
  clk_ena : in std_logic;
  pcm_in : in std_logic_vector(19 downto 0);
  dac_out : out std_logic
);
end component;

component osd
generic ( OSD_COLOR : integer := 1 );  -- blue
port (
	clk_sys     : in std_logic;
	R_in        : in std_logic_vector(5 downto 0);
	G_in        : in std_logic_vector(5 downto 0);
	B_in        : in std_logic_vector(5 downto 0);
	HSync       : in std_logic;
	VSync       : in std_logic;

	R_out       : out std_logic_vector(5 downto 0);
	G_out       : out std_logic_vector(5 downto 0);
	B_out       : out std_logic_vector(5 downto 0);

	SPI_SCK     : in std_logic;
	SPI_SS3     : in std_logic;
	SPI_DI      : in std_logic
);
end component osd;

COMPONENT rgb2ypbpr
PORT (
        red     :        IN std_logic_vector(5 DOWNTO 0);
        green   :        IN std_logic_vector(5 DOWNTO 0);
        blue    :        IN std_logic_vector(5 DOWNTO 0);
        y       :        OUT std_logic_vector(5 DOWNTO 0);
        pb      :        OUT std_logic_vector(5 DOWNTO 0);
        pr      :        OUT std_logic_vector(5 DOWNTO 0)
        );
END COMPONENT;

component user_io
	GENERIC (
		STRLEN : integer := 0;
		PS2DIV : integer := 1500 );
	PORT(
		clk_sys : in std_logic;
		clk_sd : in std_logic;
		conf_str : in std_logic_vector(8*STRLEN-1 downto 0);

		-- mist spi to firmware
		SPI_CLK : in std_logic;
		SPI_SS_IO : in std_logic;
		SPI_MISO : out std_logic;
		SPI_MOSI : in std_logic;

		-- joysticks
		JOYSTICK_0 : out std_logic_vector(5 downto 0);
		JOYSTICK_1 : out std_logic_vector(5 downto 0);
		JOYSTICK_ANALOG_0 : out std_logic_vector(15 downto 0);
		JOYSTICK_ANALOG_1 : out std_logic_vector(15 downto 0);
		BUTTONS : out std_logic_vector(1 downto 0);
		SWITCHES : out std_logic_vector(1 downto 0);
		STATUS : out std_logic_vector(63 downto 0);

		-- video switches
		scandoubler_disable: out std_logic;
		ypbpr: out std_logic;
		no_csync: out std_logic;

		-- ps2
		PS2_KBD_CLK : out std_logic;
		PS2_KBD_DATA : out std_logic;

		-- serial (one way?)
		SERIAL_DATA : in std_logic_vector(7 downto 0);
		SERIAL_STROBE : in std_logic;

		-- connection to sd card emulation
		sd_lba : in std_logic_vector(31 downto 0);
		sd_rd : in std_logic_vector(1 downto 0);
		sd_wr : in std_logic_vector(1 downto 0);
		sd_ack : out std_logic;
		sd_ack_conf : out std_logic;
		sd_conf : in std_logic;
		sd_sdhc : in std_logic;
		sd_dout : out std_logic_vector(7 downto 0);
		sd_dout_strobe : out std_logic;
		sd_din : in std_logic_vector(7 downto 0);
		sd_din_strobe : out std_logic;
		sd_buff_addr : out std_logic_vector(8 downto 0);
		img_size    : out std_logic_vector(31 downto 0);
		img_mounted : out std_logic_vector(1 downto 0)
	  );
	end component;

	component data_io
	port (
		clk_sys : in std_logic;

		SPI_SCK : in std_logic;
		SPI_SS2 : in std_logic;
		SPI_DI  : in std_logic;

		ioctl_wait     : in std_logic;
		ioctl_download : out std_logic;
		ioctl_index    : out std_logic_vector(7 downto 0);
		ioctl_wr       : out std_logic;
		ioctl_addr     : out std_logic_vector(24 downto 0);
		ioctl_dout     : out std_logic_vector(15 downto 0)
	);
	end component data_io;


  signal AUDIO_L_PCM : std_logic_vector(15 downto 0);
  signal AUDIO_R_PCM : std_logic_vector(15 downto 0);

  signal VGA_VS_RAW : std_logic;
  signal VGA_HS_RAW : std_logic;
  signal VGA_CS_RAW : std_logic;

  signal RESET_n : std_logic;
  signal CLK : std_logic;
  signal CLK_SDRAM : std_logic;

  signal CLK_PLL1 : std_logic; -- cascaded to get better pal clock
  signal PLL1_LOCKED : std_logic;

  SIGNAL PS2_CLK : std_logic;
  SIGNAL PS2_DAT : std_logic;
  SIGNAL	CONSOL_OPTION_RAW :  STD_LOGIC;
  SIGNAL	CONSOL_OPTION :  STD_LOGIC;
  SIGNAL	CONSOL_SELECT_RAW :  STD_LOGIC;
  SIGNAL	CONSOL_SELECT :  STD_LOGIC;
  SIGNAL	CONSOL_START_RAW :  STD_LOGIC;
  SIGNAL	CONSOL_START :  STD_LOGIC;
  SIGNAL FKEYS : std_logic_vector(11 downto 0);

  signal capslock_pressed : std_logic;
  signal capsheld_next : std_logic;
  signal capsheld_reg : std_logic;
  
  signal spi_miso_io : std_logic;

  signal mist_buttons : std_logic_vector(1 downto 0);
  signal mist_switches : std_logic_vector(1 downto 0);
  signal mist_status   : std_logic_vector(63 downto 0);

  signal		JOY1 :  STD_LOGIC_VECTOR(5 DOWNTO 0);
  signal		JOY2 :  STD_LOGIC_VECTOR(5 DOWNTO 0);
  signal		JOY1_n :  STD_LOGIC_VECTOR(4 DOWNTO 0);
  signal		JOY2_n :  STD_LOGIC_VECTOR(4 DOWNTO 0);
  signal joy_still : std_logic;

  signal		JOY1X : std_logic_vector(7 downto 0);
  signal		JOY1Y : std_logic_vector(7 downto 0);
  signal		JOY2X : std_logic_vector(7 downto 0);
  signal		JOY2Y : std_logic_vector(7 downto 0);

  SIGNAL	KEYBOARD_RESPONSE :  STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL	KEYBOARD_SCAN :  STD_LOGIC_VECTOR(5 DOWNTO 0);
  signal atari_keyboard : std_logic_vector(63 downto 0);

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

	-- dma/virtual drive
	signal DMA_ADDR_FETCH : std_logic_vector(23 downto 0);
	signal DMA_ADDR_FETCH_IOCTL : std_logic_vector(23 downto 0);
	signal DMA_ADDR_FETCH_ZPU : std_logic_vector(23 downto 0);
	signal DMA_WRITE_DATA : std_logic_vector(31 downto 0);
	signal DMA_WRITE_DATA_IOCTL : std_logic_vector(31 downto 0);
	signal DMA_WRITE_DATA_ZPU : std_logic_vector(31 downto 0);
	signal DMA_FETCH : std_logic;
	signal DMA_FETCH_ZPU : std_logic;
	signal DMA_FETCH_IOCTL : std_logic;
	signal DMA_32BIT_WRITE_ENABLE : std_logic;
	signal DMA_32BIT_WRITE_ENABLE_ZPU : std_logic;
	signal DMA_16BIT_WRITE_ENABLE : std_logic;
	signal DMA_16BIT_WRITE_ENABLE_ZPU : std_logic;
	signal DMA_16BIT_WRITE_ENABLE_IOCTL : std_logic;
	signal DMA_8BIT_WRITE_ENABLE : std_logic;
	signal DMA_8BIT_WRITE_ENABLE_ZPU : std_logic;
	signal DMA_READ_ENABLE : std_logic;
	signal DMA_READ_ENABLE_ZPU : std_logic;
	signal DMA_MEMORY_READY : std_logic;
	signal DMA_MEMORY_READY_ZPU : std_logic;
	signal DMA_MEMORY_DATA : std_logic_vector(31 downto 0);

	signal ZPU_ADDR_ROM : std_logic_vector(15 downto 0);
	signal ZPU_ROM_DATA :  std_logic_vector(31 downto 0);

	signal ZPU_IN1  : std_logic_vector(31 downto 0);
	signal ZPU_IN2  : std_logic_vector(31 downto 0);
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
	signal cart_type_byte : std_logic_vector(7 downto 0);
	signal key_type : std_logic;
	signal atari800mode : std_logic;
	signal turbo_drive : std_logic_vector(2 downto 0);

	-- connection to sd card emulation
	signal sd_lba : std_logic_vector(31 downto 0);
	signal sd_rd : std_logic_vector(1 downto 0);
	signal sd_wr : std_logic_vector(1 downto 0);
	signal sd_ack : std_logic;
	signal sd_ack_conf : std_logic;
	signal sd_conf : std_logic;
	signal sd_sdhc : std_logic;
	signal sd_dout : std_logic_vector(7 downto 0);
	signal sd_dout_strobe : std_logic;
	signal sd_din : std_logic_vector(7 downto 0);
	signal sd_din_strobe : std_logic;
	signal sd_buff_addr: std_logic_vector(8 downto 0);
	signal img_size    : std_logic_vector(31 downto 0);
	signal img_mounted : std_logic_vector(1 downto 0);

	signal zpu_secbuf_addr : std_logic_vector(8 downto 0);
	signal zpu_secbuf_d : std_logic_vector(7 downto 0);
	signal zpu_secbuf_we : std_logic;
	signal zpu_secbuf_q	: std_logic_vector(7 downto 0);

	signal mist_sd_sdo : std_logic;
	signal mist_sd_sck : std_logic;
	signal mist_sd_sdi : std_logic;
	signal mist_sd_cs : std_logic;

	-- data io
	signal rom_loaded      : std_logic;
	type ioctl_t is (
		IOCTL_IDLE,
		IOCTL_UNLOAD,
		IOCTL_WRITE,
		IOCTL_ACK);
	signal ioctl_state     : ioctl_t;
	signal ioctl_download  : std_logic;
	signal ioctl_download_D: std_logic;
	signal ioctl_index     : std_logic_vector(7 downto 0);
	signal ioctl_wr        : std_logic;
	signal ioctl_addr      : std_logic_vector(24 downto 0);
	signal ioctl_dout      : std_logic_vector(15 downto 0);
	signal reset_load      : std_logic;
	signal cold_reset      : std_logic;
	signal zpu_cold_reset  : std_logic;
	signal zpu_unl_reset   : std_logic;

	-- ps2
	signal PS2_KEYS : STD_LOGIC_VECTOR(511 downto 0);
	signal PS2_KEYS_NEXT : STD_LOGIC_VECTOR(511 downto 0);

	-- scandoubler
	signal half_scandouble_enable_reg : std_logic;
	signal half_scandouble_enable_next : std_logic;
	signal VIDEO_B : std_logic_vector(7 downto 0);

	-- turbo freezer!
	signal freezer_enable : std_logic;
	signal freezer_activate: std_logic;

	-- paddles
	signal paddle_mode_next : std_logic;
	signal paddle_mode_reg : std_logic;

	-- video settings
	signal pal : std_logic;
	signal scandouble : std_logic;
	signal scanlines : std_logic;
	signal video_mode : std_logic_vector(2 downto 0);
	signal scandoubler_disable : std_logic;
	signal ypbpr : std_logic;
	signal no_csync : std_logic;
	signal sd_hs         : std_logic;
  signal sd_vs         : std_logic;
  signal sd_red_o      : std_logic_vector(5 downto 0);
  signal sd_green_o    : std_logic_vector(5 downto 0);
  signal sd_blue_o     : std_logic_vector(5 downto 0);
  signal osd_red_o     : std_logic_vector(5 downto 0);
  signal osd_green_o   : std_logic_vector(5 downto 0);
  signal osd_blue_o    : std_logic_vector(5 downto 0);  
  signal vga_y_o       : std_logic_vector(5 downto 0);
  signal vga_pb_o      : std_logic_vector(5 downto 0);
  signal vga_pr_o      : std_logic_vector(5 downto 0);

	-- pll reconfig
	signal CLK_RECONFIG_PLL : std_logic;
	signal CLK_RECONFIG_PLL_LOCKED : std_logic;

	constant SDRAM_BASE    : unsigned(23 downto 0) := x"800000";
	constant CARTRIDGE_MEM : unsigned(23 downto 0) := x"D00000";
	constant SDRAM_ROM_ADDR : unsigned(23 downto 0):= x"F00000";

	constant CONF_STR : string :=
		"A800XL;;"&
		"F,ROM,Load ROM;"&
		"F,ROMCAR,Load Cart;"&
		"S0,ATRXEX,Load Disk 1;"&
		"S1,ATRXEX,Load Disk 2;"&
		"P1,Video;"&
		"P2,System;"&
		"P1O5,Video,NTSC,PAL;"&
		"P1O6,Scanlines,Off,On;"&
		"P2O8A,CPU Speed,1x,2x,4x,8x,16x;"&
		"P2OB,Turbo at VBL only,Off,On;"&
		"P2OC,Machine,XL/XE,400/800;"&
		"P2ODF,XL/XE Memory,64K,128K,320KB Compy,320KB Rambo,576K Compy,576K Rambo,1088K,4MB;"&
		"P2OGI,400/800 Memory,8K,16K,32K,48K,52K;"&
		"P2OJ,Keyboard,ISO,ANSI;"&
		"P2OKM,Drive speed,Standard,Fast-6,Fast-5,Fast-4,Fast-3,Fast-2,Fast-1,Fast-0;"&
		"T1,Reset;"&
		"T2,Cold reset;"&
		"T3,Cold reset with unload;";

	-- convert string to std_logic_vector to be given to user_io
	function to_slv(s: string) return std_logic_vector is
		constant ss: string(1 to s'length) := s;
		variable rval: std_logic_vector(1 to 8 * s'length);
		variable p: integer;
		variable c: integer;
	begin
		for i in ss'range loop
			p := 8 * i;
			c := character'pos(ss(i));
			rval(p - 7 to p) := std_logic_vector(to_unsigned(c,8));
		end loop;
		return rval;
	end function;

BEGIN 
-- hack for paddles
	process(clk,RESET_N)
	begin
		if (RESET_N = '0') then
			paddle_mode_reg <= '0';
		elsif (clk'event and clk='1') then
			paddle_mode_reg <= paddle_mode_next;
		end if;
	end process;

	process(paddle_mode_reg, joy1, joy2)
	begin
		joy1_n <= (others=>'1');
		joy2_n <= (others=>'1');

		if (paddle_mode_reg = '1') then
			joy1_n <= "111"&not(joy1(4)&joy1(5)); --FLRDU
			joy2_n <= "111"&not(joy2(4)&joy2(5));
		else
			joy1_n <= not(joy1(4 downto 0));
			joy2_n <= not(joy2(4 downto 0));
		end if;
	end process;

	paddle_mode_next <= paddle_mode_reg xor (not(ps2_keys(16#11F#)) and ps2_keys_next(16#11F#)); -- left windows key

-- mist spi io
	spi_do <= spi_miso_io when CONF_DATA0 ='0' else 'Z';

	sd_conf <= '0';
	sd_sdhc <= '1';

	my_user_io : user_io
	GENERIC map (STRLEN => CONF_STR'length)
	PORT map(
		clk_sys => CLK,
		clk_sd => CLK,
		SPI_CLK => SPI_SCK,
		SPI_SS_IO => CONF_DATA0,
		SPI_MISO => SPI_miso_io,
		SPI_MOSI => SPI_DI,
		conf_str => to_slv(CONF_STR),
		JOYSTICK_0 => joy2,
		JOYSTICK_1 => joy1,
		JOYSTICK_ANALOG_0(15 downto 8) => joy2x,
		JOYSTICK_ANALOG_0(7 downto 0) => joy2y,
		JOYSTICK_ANALOG_1(15 downto 8) => joy1x,
		JOYSTICK_ANALOG_1(7 downto 0) => joy1y,
		BUTTONS => mist_buttons,
		SWITCHES => mist_switches,
		STATUS => mist_status,
		scandoubler_disable => scandoubler_disable,
		ypbpr => ypbpr,
		no_csync => no_csync,

		PS2_KBD_CLK => ps2_clk,
		PS2_KBD_DATA => ps2_dat,

		SERIAL_DATA => (others=>'0'),
		SERIAL_STROBE => '0',

		sd_lba => sd_lba,
		sd_rd => sd_rd,
		sd_wr => sd_wr,
		sd_ack => sd_ack,
		sd_ack_conf => sd_ack_conf,
		sd_conf => sd_conf,
		sd_sdhc => sd_sdhc,
		sd_dout => sd_dout,
		sd_dout_strobe => sd_dout_strobe,
		sd_din => sd_din,
		sd_din_strobe => sd_din_strobe,
		sd_buff_addr => sd_buff_addr,
		img_mounted => img_mounted,
		img_size => img_size
	);

	-- PS2 to pokey
	keyboard_map1 : entity work.ps2_to_atari800
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,
		PS2_CLK => ps2_clk,
		PS2_DAT => ps2_dat,

 		INPUT => zpu_out4,

 		ATARI_KEYBOARD_OUT => atari_keyboard,

		KEY_TYPE => key_type,

		KEYBOARD_SCAN => KEYBOARD_SCAN,
		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,

		CONSOL_START => CONSOL_START_RAW,
		CONSOL_SELECT => CONSOL_SELECT_RAW,
		CONSOL_OPTION => CONSOL_OPTION_RAW,

		FKEYS => FKEYS,
		FREEZER_ACTIVATE => freezer_activate,

		PS2_KEYS_NEXT_OUT => ps2_keys_next,
		PS2_KEYS => ps2_keys
	);

	CONSOL_START <= CONSOL_START_RAW or (mist_buttons(1) and not(joy1_n(4)));
	joy_still <= joy1_n(3) and joy1_n(2) and joy1_n(1) and joy1_n(0);
	CONSOL_SELECT <= CONSOL_SELECT_RAW or (mist_buttons(1) and joy1_n(4) and not(joy_still));
	CONSOL_OPTION <= CONSOL_OPTION_RAW or (mist_buttons(1) and joy1_n(4) and joy_still);

	dac_left : hq_dac
	port map
	(
		reset => not(reset_n),
		clk => clk,
		clk_ena => '1',
		pcm_in => AUDIO_L_PCM&"0000",
		dac_out => audio_l
	);

	dac_right : hq_dac
	port map
	(
		reset => not(reset_n),
		clk => clk,
		clk_ena => '1',
		pcm_in => AUDIO_R_PCM&"0000",
		dac_out => audio_r
	);

	reconfig_pll : entity work.pll_reconfig -- This only exists to generate reset!!
	PORT MAP(inclk0 => CLOCK_27(0),
		c0 => CLK_RECONFIG_PLL,
		locked => CLK_RECONFIG_PLL_LOCKED);

	process (CLK_RECONFIG_PLL, CLK_RECONFIG_PLL_LOCKED)
	begin
		if CLK_RECONFIG_PLL_LOCKED = '0' then
			rom_loaded <= '0';
		elsif rising_edge(CLK_RECONFIG_PLL) then
			if ioctl_download = '1' then -- FIXME: synchronize
				rom_loaded <= '1';
			end if;
		end if;
	end process;

	pll_switcher : work.switch_pal_ntsc
	GENERIC MAP
	(
		CLOCKS => 4,
		SYNC_ON => 1
	)
	PORT MAP
	(
		RECONFIG_CLK => CLK_RECONFIG_PLL,
		RESET_N => CLK_RECONFIG_PLL_LOCKED,

		PAL => PAL,
		SWITCH_ENA => not ioctl_download and rom_loaded,
		INPUT_CLK => CLOCK_27(0),
		PLL_CLKS(0) => CLK_SDRAM,
		PLL_CLKS(1) => CLK,
		PLL_CLKS(2) => SDRAM_CLK,

		RESET_N_OUT => RESET_N
	);

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

		VIDEO_VS => VGA_VS_RAW,
		VIDEO_HS => VGA_HS_RAW,
		VIDEO_CS => VGA_CS_RAW,
		VIDEO_B => VIDEO_B,
		VIDEO_G => open,
		VIDEO_R => open,

		AUDIO_L => AUDIO_L_PCM,
		AUDIO_R => AUDIO_R_PCM,

		JOY1_n => JOY1_n(4)&JOY1_n(0)&JOY1_n(1)&JOY1_n(2)&JOY1_n(3),
		JOY2_n => JOY2_n(4)&JOY2_n(0)&JOY2_n(1)&JOY2_n(2)&JOY2_n(3),

		PADDLE0 => signed(joy1x),
		PADDLE1 => signed(joy1y),
		PADDLE2 => signed(joy2x),
		PADDLE3 => signed(joy2y),

		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,
		KEYBOARD_SCAN => KEYBOARD_SCAN,

		SIO_COMMAND => zpu_sio_command,
		SIO_RXD => zpu_sio_txd,
		SIO_TXD => zpu_sio_rxd,
		SIO_CLOCKOUT => ASIO_CLOCKOUT,

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
		freezer_activate => freezer_activate
	);

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
		SDRAM_DQ => SDRAM_DQ,
		COMPLETE => SDRAM_REQUEST_COMPLETE,
		SDRAM_BA0 => SDRAM_BA(0),
		SDRAM_BA1 => SDRAM_BA(1),
		SDRAM_CKE => SDRAM_CKE,
		SDRAM_CS_N => SDRAM_nCS,
		SDRAM_RAS_N => SDRAM_nRAS,
		SDRAM_CAS_N => SDRAM_nCAS,
		SDRAM_WE_N => SDRAM_nWE,
		SDRAM_ldqm => SDRAM_DQML,
		SDRAM_udqm => SDRAM_DQMH,
		DATA_OUT => SDRAM_DO,
		SDRAM_ADDR => SDRAM_A(11 downto 0),
		reset_client_n => SDRAM_RESET_N
	);
		 
	SDRAM_A(12) <= '0';

	mist_data_io: data_io
	port map (
		clk_sys => CLK,

		SPI_SCK => SPI_SCK,
		SPI_SS2 => SPI_SS2,
		SPI_DI  => SPI_DI,

		ioctl_wait     => '0',
		ioctl_download => ioctl_download,
		ioctl_index    => ioctl_index,
		ioctl_wr       => ioctl_wr,
		ioctl_addr     => ioctl_addr,
		ioctl_dout     => ioctl_dout
	);

	dma_read_enable <= '0' when ioctl_state /= IOCTL_IDLE else dma_read_enable_zpu;
	dma_addr_fetch <= dma_addr_fetch_ioctl when ioctl_state /= IOCTL_IDLE else dma_addr_fetch_zpu;
	dma_write_data <= dma_write_data_ioctl when ioctl_state /= IOCTL_IDLE else dma_write_data_zpu;
	dma_fetch <= dma_fetch_ioctl when ioctl_state /= IOCTL_IDLE else dma_fetch_zpu;
	dma_8bit_write_enable <= '0' when ioctl_state /= IOCTL_IDLE else dma_8bit_write_enable_zpu;
	dma_16bit_write_enable <= dma_16bit_write_enable_ioctl when ioctl_state /= IOCTL_IDLE else dma_16bit_write_enable_zpu;
	dma_32bit_write_enable <= '0' when ioctl_state /= IOCTL_IDLE else dma_32bit_write_enable_zpu;
	dma_memory_ready_zpu <= '0' when ioctl_state /= IOCTL_IDLE else dma_memory_ready;

	emulated_cartridge_select <=
		     "000001" when cart_type_byte = x"01" -- standard 8k
		else "100001" when cart_type_byte = x"02" -- standard 16k
		else "001101" when cart_type_byte = x"08" -- Williams 64k
		else "001010" when cart_type_byte = x"09" -- Express 64
		else "001001" when cart_type_byte = x"0a" -- Diamond 64
		else "001000" when cart_type_byte = x"0b" -- SDX64
		else "110000" when cart_type_byte = x"0c" -- XEGS 32k
		else "110001" when cart_type_byte = x"0d" -- XEGS 64k
		else "110010" when cart_type_byte = x"0e" -- XEGS 128k
		else "000100" when cart_type_byte = x"0f" -- OSS 16
		else "001100" when cart_type_byte = x"11" -- ATRAX 128
		else "001101" when cart_type_byte = x"16" -- Williams 32k (=Williams 64k)
		else "110011" when cart_type_byte = x"17" -- XEGS 256
		else "110100" when cart_type_byte = x"18" -- XEGS 512
		else "110101" when cart_type_byte = x"19" -- XEGS 1024
		else "101000" when cart_type_byte = x"1a" -- MEGA 16
		else "101001" when cart_type_byte = x"1b" -- MEGA 32
		else "101010" when cart_type_byte = x"1c" -- MEGA 64
		else "101011" when cart_type_byte = x"1d" -- MEGA 128
		else "101100" when cart_type_byte = x"1e" -- MEGA 256
		else "101101" when cart_type_byte = x"1f" -- MEGA 512
		else "101110" when cart_type_byte = x"20" -- MEGA 1024
		else "111000" when cart_type_byte = x"21" -- SXEGS 32
		else "111001" when cart_type_byte = x"22" -- SXEGS 64
		else "111010" when cart_type_byte = x"23" -- SXEGS 128
		else "111011" when cart_type_byte = x"24" -- SXEGS 256
		else "111100" when cart_type_byte = x"25" -- SXEGS 512
		else "111101" when cart_type_byte = x"26" -- SXEGS 1024
		else "100011" when cart_type_byte = x"28" -- BLIZZARD 16
		else "000010" when cart_type_byte = x"29" -- ATARIMAX 128
		else "000011" when cart_type_byte = x"2a" -- ATARIMAX 1024
		else "100100" when cart_type_byte = x"38" -- SIC 512
		else "000000";

	process (CLK, RESET_N)
		variable sdram_a: unsigned(23 downto 0);
	begin
		if RESET_N = '0' then
			ioctl_state <= IOCTL_IDLE;
			reset_load <= '0';
		elsif rising_edge(CLK) then
			ioctl_download_D <= ioctl_download;
			case ioctl_state is

			when IOCTL_IDLE =>
				reset_load <= '0';
				dma_fetch_ioctl <= '0';
				dma_16bit_write_enable_ioctl <= '0';
				if cold_reset = '1' then
					-- reset with unload
					cart_type_byte <= (others => '0');
					dma_addr_fetch_ioctl <= std_logic_vector(SDRAM_BASE);
					ioctl_state <= IOCTL_UNLOAD;
				elsif ioctl_download_D = '0' and ioctl_download = '1' then
					-- cart loading starts
					ioctl_state <= IOCTL_WRITE;
					cart_type_byte <= (others => '0');
				end if;

			when IOCTL_UNLOAD =>
				if dma_fetch_ioctl = '1' then
					if dma_memory_ready = '1' then
						dma_fetch_ioctl <= '0';
						dma_16bit_write_enable_ioctl <= '0';
						dma_addr_fetch_ioctl <= std_logic_vector(unsigned(dma_addr_fetch_ioctl) + 2);
					end if;
				elsif dma_addr_fetch_ioctl = std_logic_vector(SDRAM_BASE + x"10000") then
					ioctl_state <= IOCTL_IDLE;
					reset_load <= '1';
				else
					dma_fetch_ioctl <= '1';
					dma_16bit_write_enable_ioctl <= '1';
					dma_write_data_ioctl <= (others => '0');
				end if;

			when IOCTL_WRITE =>
				if ioctl_download = '0' then
					-- end of download
					ioctl_state <= IOCTL_IDLE;
					reset_load <= '1';
					if ioctl_index = x"02" then
						-- ROM file type detection from size
						if    ioctl_addr = '0'&x"002000" then cart_type_byte <= x"01"; -- standard 8k
						elsif ioctl_addr = '0'&x"004000" then cart_type_byte <= x"02"; -- standard 16k
						elsif ioctl_addr = '0'&x"008000" then cart_type_byte <= x"0c"; -- Atari XEGS 32k
						elsif ioctl_addr = '0'&x"010000" then cart_type_byte <= x"0d"; -- Atari XEGS 64k
						elsif ioctl_addr = '0'&x"020000" then cart_type_byte <= x"0e"; -- Atari XEGS 128k
						elsif ioctl_addr = '0'&x"100000" then cart_type_byte <= x"2a"; -- Atarimax 1024k
						end if;
					end if;
				elsif ioctl_wr = '1' then
					-- new word arrived from IO controller
					if (ioctl_index = x"42" and unsigned(ioctl_addr) = 6) then
						-- CAR header type field
						cart_type_byte <= ioctl_dout(15 downto 8);
					elsif (ioctl_index = x"42" and unsigned(ioctl_addr) < 16) then
						-- skip CAR header
						null;
					else
						dma_fetch_ioctl <= '1';
						dma_16bit_write_enable_ioctl <= '1';
						dma_write_data_ioctl <= ioctl_dout & ioctl_dout;
						if ioctl_index(7 downto 1) = "0000000" then -- 0 or 1
							-- BASIC + OS ROM
							sdram_a := unsigned(ioctl_addr(23 downto 0)) + SDRAM_ROM_ADDR;
						else
							sdram_a := unsigned(ioctl_addr(23 downto 0)) + CARTRIDGE_MEM;
						end if;
						if ioctl_index = x"42" then
							sdram_a := sdram_a - 16;
						end if;
						dma_addr_fetch_ioctl <= std_logic_vector(sdram_a);
						ioctl_state <= IOCTL_ACK;
					end if;
				end if;

			when IOCTL_ACK =>
				if dma_memory_ready = '1' then
					dma_fetch_ioctl <= '0';
					dma_16bit_write_enable_ioctl <= '0';
					ioctl_state <= IOCTL_WRITE;
				end if;

			when others => null;

			end case;
		end if;
	end process;

	LED <= zpu_sio_rxd;

	scandouble <= not scandoubler_disable;

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
		video_bits=>6
	)
	PORT MAP
	( 
		CLK => CLK,
		RESET_N => RESET_N and SDRAM_RESET_N and not(reset_atari),
		
		VGA => scandouble,
		COMPOSITE_ON_HSYNC => '0', -- OSD needs separate sync, handle csync in the final mix

		colour_enable => half_scandouble_enable_reg,
		doubled_enable => '1',
		scanlines_on => scanlines,
		
		-- GTIA interface
		pal => PAL,
		colour_in => VIDEO_B,
		vsync_in => VGA_VS_RAW,
		hsync_in => VGA_HS_RAW,
		csync_in => VGA_CS_RAW,
		
		-- TO TV...
		R => sd_red_o,
		G => sd_green_o,
		B => sd_blue_o,
		
		VSYNC => sd_vs,
		HSYNC => sd_hs
	);

	osd_inst: osd
	port map (
		clk_sys     => CLK,
		SPI_SCK     => SPI_SCK,
		SPI_SS3     => SPI_SS3,
		SPI_DI      => SPI_DI,

		R_in        => sd_red_o,
		G_in        => sd_green_o,
		B_in        => sd_blue_o,
		HSync       => sd_hs,
		VSync       => sd_vs,

		R_out       => osd_red_o,
		G_out       => osd_green_o,
		B_out       => osd_blue_o
	);

	rgb2ypbpr_inst: rgb2ypbpr
	port map (
		red => osd_red_o,
		green => osd_green_o,
		blue => osd_blue_o,
		y => vga_y_o,
		pb => vga_pb_o,
		pr => vga_pr_o
	);

	VGA_R <= vga_pr_o when ypbpr='1' else osd_red_o;
	VGA_G <= vga_y_o  when ypbpr='1' else osd_green_o;
	VGA_B <= vga_pb_o when ypbpr='1' else osd_blue_o;
	-- If 15kHz Video - composite sync to VGA_HS and VGA_VS high for MiST RGB cable
	VGA_HS <= not (sd_hs xor sd_vs) when (scandoubler_disable='1' and no_csync='0') or ypbpr='1' else sd_hs;
	VGA_VS <= '1' when (scandoubler_disable='1' and no_csync='0') or ypbpr='1' else sd_vs;

	sector_buffer: entity work.DualPortRAM
	generic map (
		addrbits => 9,
		databits => 8
	)
	port map (
		clock => CLK,
		-- Port A - IO Controller side
		address_a => sd_buff_addr,
		data_a => sd_dout,
		wren_a => sd_dout_strobe,
		q_a => sd_din,
		-- Port B - ZPU side
		address_b => zpu_secbuf_addr,
		data_b => zpu_secbuf_d,
		wren_b => zpu_secbuf_we,
		q_b => zpu_secbuf_q
	);

	process (CLK, RESET_N)
	begin
		if RESET_N = '0' then
			zpu_in1(31 downto 29) <= "000";
			zpu_secbuf_we <= '0';
		elsif rising_edge(CLK) then
			sd_lba <= zpu_out2;
			sd_rd <= zpu_out3(31 downto 30);
			sd_wr <= zpu_out3(29 downto 28);

			zpu_secbuf_addr <= zpu_out3(16 downto 8);
			zpu_secbuf_d <= zpu_out3(7 downto 0);
			zpu_secbuf_we <= zpu_out3(17);

			if img_mounted(0) = '1' then
				zpu_in2 <= img_size;
				zpu_in1(30) <= not zpu_in1(30);
			elsif img_mounted(1) = '1' then
				zpu_in2 <= img_size;
				zpu_in1(31) <= not zpu_in1(31);
			elsif zpu_out3(18) = '1' then
				zpu_in2 <= X"000000"&zpu_secbuf_q;
			end if;
			zpu_in1(29) <= sd_ack;

		end if;
	end process;

	zpu_in1(28 downto 0) <= 
			turbo_drive&X"00"&
			(atari_keyboard(28))&ps2_keys(16#5A#)&ps2_keys(16#174#)&ps2_keys(16#16B#)&ps2_keys(16#172#)&ps2_keys(16#175#)& -- (esc)FLRDU
				'0'&zpu_unl_reset&zpu_cold_reset&FKEYS(8 downto 0);

	zpu: entity work.zpucore
	GENERIC MAP
	(
		platform => 1,
		spi_clock_div => 4,	-- 28MHz/2. Max for SD cards is 25MHz...
		nMHz_clock_div => 27,
		memory => 8192
	)
	PORT MAP
	(
		-- standard...
		CLK => CLK,
		RESET_N => RESET_N and sdram_reset_n,

		-- dma bus master (with many waitstates...)
		ZPU_ADDR_FETCH => dma_addr_fetch_zpu,
		ZPU_DATA_OUT => dma_write_data_zpu,
		ZPU_FETCH => dma_fetch_zpu,
		ZPU_32BIT_WRITE_ENABLE => dma_32bit_write_enable_zpu,
		ZPU_16BIT_WRITE_ENABLE => dma_16bit_write_enable_zpu,
		ZPU_8BIT_WRITE_ENABLE => dma_8bit_write_enable_zpu,
		ZPU_READ_ENABLE => dma_read_enable_zpu,
		ZPU_MEMORY_READY => dma_memory_ready_zpu,
		ZPU_MEMORY_DATA => dma_memory_data, 

		-- rom bus master
		-- data on next cycle after addr
		ZPU_ADDR_ROM => zpu_addr_rom,
		ZPU_ROM_DATA => zpu_rom_data,
	
		ZPU_ROM_WREN => open,

		-- nmhz clock
		CLK_nMHz => CLOCK_27(0),

		-- spi master
		ZPU_SPI_DI => mist_sd_sdo,
		ZPU_SPI_CLK => mist_sd_sck,
		ZPU_SPI_DO => mist_sd_sdi,
		ZPU_SPI_SELECT0 => mist_sd_cs,
		ZPU_SPI_SELECT1 => open,

		-- SIO
		-- Ditto for speaking to Atari, we have a built in Pokey
		ZPU_POKEY_ENABLE => zpu_pokey_enable,
		ZPU_SIO_TXD => zpu_sio_txd,
		ZPU_SIO_RXD => zpu_sio_rxd,
		ZPU_SIO_COMMAND => zpu_sio_command,
		ZPU_SIO_CLK => ASIO_CLOCKOUT,

		-- external control
		-- switches etc. sector DMA blah blah.
		ZPU_IN1 => zpu_in1,

--		ZPU_IN1 => X"000"&
--			"00"&
--			(atari_keyboard(28))&ps2_keys(16#5A#)&ps2_keys(16#174#)&ps2_keys(16#16B#)&ps2_keys(16#172#)&ps2_keys(16#175#)& -- (esc)FLRDU
--				(FKEYS(11) or (mist_buttons(0) and not(joy1_n(4))))&(FKEYS(10) or (mist_buttons(0) and joy1_n(4) and joy_still))&(FKEYS(9) or (mist_buttons(0) and joy1_n(4) and not(joy_still)))&FKEYS(8 downto 0),
		ZPU_IN2 => zpu_in2,
		ZPU_IN3 => atari_keyboard(31 downto 0),
		ZPU_IN4 => atari_keyboard(63 downto 32),

		-- ouputs - e.g. Atari system control, halt, throttle, rom select
		ZPU_OUT1 => zpu_out1,
		ZPU_OUT2 => zpu_out2,
		ZPU_OUT3 => zpu_out3,
		ZPU_OUT4 => zpu_out4,
		ZPU_OUT6 => zpu_out6 --video mode
	);

	zpu_cold_reset <= mist_status(2) or FKEYS(9);
	zpu_unl_reset <= mist_status(3) or FKEYS(10);

	cold_reset  <= zpu_cold_reset or zpu_unl_reset;
	reset_atari <= mist_status(1) or mist_buttons(1) or zpu_out1(1) or reset_load;
	speed_6502 <= "000001" when mist_status(10 downto 8) = "000" else
	              "000010" when mist_status(10 downto 8) = "001" else
	              "000100" when mist_status(10 downto 8) = "010" else
	              "001000" when mist_status(10 downto 8) = "011" else
	              "010000";

	turbo_vblank_only <= mist_status(11);

	atari800mode <= mist_status(12);
	ram_select <= mist_status(15 downto 13) when atari800mode = '0' else mist_status(18 downto 16);
	PAL <= mist_status(5);
	scanlines <= mist_status(6);
	key_type <= mist_status(19);
	turbo_drive <= mist_status(22 downto 20);

	pause_atari <= '1' when zpu_out1(0) = '1' or ioctl_state /= IOCTL_IDLE else '0';
	freezer_enable <= zpu_out1(25);

	zpu_rom1: entity work.zpu_rom
	port map(
	        clock => clk,
	        address => zpu_addr_rom(13 downto 2),
	        q => zpu_rom_data
	);

	enable_179_clock_div_zpu_pokey : entity work.enable_divider
	generic map (COUNT=>32) -- cycle_length
	port map(clk=>clk,reset_n=>reset_n,enable_in=>'1',enable_out=>zpu_pokey_enable);

END vhdl;
