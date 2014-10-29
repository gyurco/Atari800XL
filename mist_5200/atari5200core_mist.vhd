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

ENTITY atari5200core_mist IS 
	GENERIC
	(
		TV : integer;  -- 1 = PAL, 0=NTSC
		VIDEO : integer; -- 1 = RGB, 2 = VGA
		COMPOSITE_SYNC : integer; --0 = no, 1 = yes!
		SCANDOUBLE : integer -- 1 = YES, 0=NO, (+ later scanlines etc)
	);
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
END atari5200core_mist;

ARCHITECTURE vhdl OF atari5200core_mist IS 

component hq_dac
port (
  reset :in std_logic;
  clk :in std_logic;
  clk_ena : in std_logic;
  pcm_in : in std_logic_vector(19 downto 0);
  dac_out : out std_logic
);
end component;

component user_io
	GENERIC(
		STRLEN : in integer := 0
	);
	PORT(
		-- conf_str? how to do in vhdl...

		-- mist spi to firmware
		SPI_CLK : in std_logic;
		SPI_SS_IO : in std_logic;
		SPI_MISO : out std_logic;
		SPI_MOSI : in std_logic;

		-- joysticks
		JOYSTICK_0 : out std_logic_vector(5 downto 0);
		JOYSTICK_1 : out std_logic_vector(5 downto 0);
		JOYSTICK_ANALOG_0 : out std_logic_vector(15 downto 0);
		JOYSTICK_ANALOG_1 : out std_logic_vector(15 downto 0); -- x axis is top 8 bits, y axis is bottom 8 bits. signed.
		BUTTONS : out std_logic_vector(1 downto 0);
		SWITCHES : out std_logic_vector(1 downto 0);
		STATUS : out std_logic_vector(7 downto 0); -- what is this?

		-- ps2
		PS2_CLK : in std_logic; --12-16khz
		PS2_KBD_CLK : out std_logic;
		PS2_KBD_DATA : out std_logic;

		-- serial (one way?)
		SERIAL_DATA : in std_logic_vector(7 downto 0);
		SERIAL_STROBE : in std_logic;

		-- connection to sd card emulation
		sd_lba : in std_logic_vector(31 downto 0);
		sd_rd : in std_logic;
		sd_wr : in std_logic;
		sd_ack : out std_logic;
		sd_conf : in std_logic;
		sd_sdhc : in std_logic;
		sd_dout : out std_logic_vector(7 downto 0);
		sd_dout_strobe : out std_logic;
		sd_din : in std_logic_vector(7 downto 0);
		sd_din_strobe : out std_logic
	  );
	end component;

	component sd_card
	PORT (
		-- link to user_io for io controller
		io_lba : out std_logic_vector(31 downto 0);
		io_rd : out std_logic;
		io_wr : out std_logic;
		io_ack : in std_logic;
		io_conf : out std_logic;
		io_sdhc : out std_logic;
		
		-- data coming in from io controller
		io_din : in std_logic_vector(7 downto 0);
		io_din_strobe : in std_logic;
		
		-- data going out to io controller
		io_dout : out std_logic_vector(7 downto 0);
		io_dout_strobe : in std_logic;
		
		-- configuration input
		allow_sdhc : in std_logic;
	
		sd_cs : in std_logic;
		sd_sck : in std_logic;
		sd_sdi : in std_logic;
		sd_sdo : out std_logic
	); 
	end component;

  signal AUDIO_L_PCM : std_logic_vector(15 downto 0);
  signal AUDIO_R_PCM : std_logic_vector(15 downto 0);

  signal VGA_VS_RAW : std_logic;
  signal VGA_HS_RAW : std_logic;

  signal RESET_n : std_logic;
  signal PLL_LOCKED : std_logic;
  signal CLK : std_logic;
  signal CLK_SDRAM : std_logic;

  signal CLK_PLL1 : std_logic; -- cascaded to get better pal clock
  signal PLL1_LOCKED : std_logic;

  SIGNAL PS2_CLK : std_logic;
  SIGNAL PS2_DAT : std_logic;
  SIGNAL FKEYS : std_logic_vector(11 downto 0);

  signal capslock_pressed : std_logic;
  signal capsheld_next : std_logic;
  signal capsheld_reg : std_logic;
  
  signal spi_miso_io : std_logic;

  signal mist_buttons : std_logic_vector(1 downto 0);
  signal mist_switches : std_logic_vector(1 downto 0);

  signal		JOY1 :  STD_LOGIC_VECTOR(5 DOWNTO 0);
  signal		JOY2 :  STD_LOGIC_VECTOR(5 DOWNTO 0);
  signal		JOY1X : std_logic_vector(7 downto 0);
  signal		JOY1Y : std_logic_vector(7 downto 0);
  signal		JOY2X : std_logic_vector(7 downto 0);
  signal		JOY2Y : std_logic_vector(7 downto 0);
  signal		JOY1_n :  STD_LOGIC_VECTOR(4 DOWNTO 0);
  signal		JOY2_n :  STD_LOGIC_VECTOR(4 DOWNTO 0);
  signal joy_still : std_logic;

  SIGNAL	KEYBOARD_RESPONSE :  STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL	KEYBOARD_SCAN :  STD_LOGIC_VECTOR(5 DOWNTO 0);
  signal controller_select : std_logic_vector(1 downto 0);

  SIGNAL PAL : std_logic;
  SIGNAL COMPOSITE_ON_HSYNC : std_logic;
  SIGNAL VGA : std_logic;

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

	signal zpu_pokey_enable : std_logic;
	signal zpu_sio_txd : std_logic;
	signal zpu_sio_rxd : std_logic;
	signal zpu_sio_command : std_logic;

	-- system control from zpu
	signal ram_select : std_logic_vector(2 downto 0);
	signal rom_select : std_logic_vector(5 downto 0);
	signal reset_atari : std_logic;
	signal pause_atari : std_logic;
	SIGNAL speed_6502 : std_logic_vector(5 downto 0);

	-- connection to sd card emulation
	signal sd_lba : std_logic_vector(31 downto 0);
	signal sd_rd : std_logic;
	signal sd_wr : std_logic;
	signal sd_ack : std_logic;
	signal sd_conf : std_logic;
	signal sd_sdhc : std_logic;
	signal sd_dout : std_logic_vector(7 downto 0);
	signal sd_dout_strobe : std_logic;
	signal sd_din : std_logic_vector(7 downto 0);
	signal sd_din_strobe : std_logic;

	signal mist_sd_sdo : std_logic;
	signal mist_sd_sck : std_logic;
	signal mist_sd_sdi : std_logic;
	signal mist_sd_cs : std_logic;

	-- ps2
	signal SLOW_PS2_CLK : std_logic; -- around 16KHz

	-- scandoubler
	signal half_scandouble_enable_reg : std_logic;
	signal half_scandouble_enable_next : std_logic;
	signal VIDEO_B : std_logic_vector(7 downto 0);

BEGIN 
pal <= '1' when tv=1 else '0';
vga <= '1' when video=2 else '0';
composite_on_hsync <= '1' when composite_sync=1 else '0';

-- mist spi io
	spi_do <= spi_miso_io when CONF_DATA0 ='0' else 'Z';

my_user_io : user_io
	PORT map(
	   SPI_CLK => SPI_SCK,
	   SPI_SS_IO => CONF_DATA0,
	   SPI_MISO => SPI_miso_io,
	   SPI_MOSI => SPI_DI,
		JOYSTICK_0 => joy2,
		JOYSTICK_1 => joy1,
		JOYSTICK_ANALOG_0(15 downto 8) => joy2x,
		JOYSTICK_ANALOG_0(7 downto 0) => joy2y,
		JOYSTICK_ANALOG_1(15 downto 8) => joy1x,
		JOYSTICK_ANALOG_1(7 downto 0) => joy1y,
		BUTTONS => mist_buttons,
		SWITCHES => mist_switches,
		STATUS => open,

		PS2_CLK => SLOW_PS2_CLK,
		PS2_KBD_CLK => ps2_clk,
		PS2_KBD_DATA => ps2_dat,
	
		SERIAL_DATA => (others=>'0'),
		SERIAL_STROBE => '0',

		sd_lba => sd_lba,
		sd_rd => sd_rd,
		sd_wr => sd_wr,
		sd_ack => sd_ack,
		sd_conf => sd_conf,
		sd_sdhc => sd_sdhc,
		sd_dout => sd_dout,
		sd_dout_strobe => sd_dout_strobe,
		sd_din => sd_din,
		sd_din_strobe => sd_din_strobe
	  );

my_sd_card : sd_card
	PORT map (
		io_lba => sd_lba,
		io_rd => sd_rd,
		io_wr => sd_wr,
		io_ack => sd_ack,
		io_conf => sd_conf,
		io_sdhc => sd_sdhc,
		
		io_din => sd_dout,
		io_din_strobe => sd_dout_strobe,
		
		io_dout => sd_din,
		io_dout_strobe => sd_din_strobe,
		
		allow_sdhc => '1',
	
		sd_cs => mist_sd_cs,
		sd_sck => mist_sd_sck,
		sd_sdi => mist_sd_sdi,
		sd_sdo => mist_sd_sdo
	); 
	  
	 joy1_n <= not(joy1(5)&joy1(3 downto 0));
	 joy2_n <= not(joy2(5)&joy2(3 downto 0));

-- PS2 to pokey
keyboard_map1 : entity work.ps2_to_atari5200
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,
		PS2_CLK => ps2_clk,
		PS2_DAT => ps2_dat,

		FIRE2 => '0'&'0'&joy2(4)&joy1(4),
		CONTROLLER_SELECT => CONTROLLER_SELECT, -- selected stick keyboard/shift button
		
		KEYBOARD_SCAN => KEYBOARD_SCAN,
		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,

		FKEYS => FKEYS
	);
-- stick 0: consol(1 downto 0)="00"

joy_still <= joy1_n(3) and joy1_n(2) and joy1_n(1) and joy1_n(0); -- TODO, need something better here I think! e.g. keypad? 5200 not centreing
	 
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

gen_ntsc_pll : if tv=0 generate
mist_pll : entity work.pll_ntsc
PORT MAP(inclk0 => CLOCK_27(0),
		 c0 => CLK_SDRAM,
		 c1 => CLK,
		 c2 => SDRAM_CLK,
		 c3 => SLOW_PS2_CLK,
		 locked => PLL_LOCKED);
end generate;

gen_pal_pll : if tv=1 generate
mist_pll : entity work.pll_pal_pre
PORT MAP(inclk0 => CLOCK_27(0),
		 c0 => CLK_PLL1,
		 locked => PLL1_LOCKED);
mist_pll2 : entity work.pll_pal_post
PORT MAP(inclk0 => CLK_PLL1,
		 c0 => CLK_SDRAM,
		 c1 => CLK,
		 c2 => SDRAM_CLK,
		 c3 => SLOW_PS2_CLK,
		 areset => not(PLL1_LOCKED),
		 locked => PLL_LOCKED);
end generate;

reset_n <= PLL_LOCKED;

atari5200_test : entity work.atari5200core_simplesdram
	GENERIC MAP
	(
		cycle_length => 32,
		--internal_rom => 4, --5200 rom...
		internal_rom => 0, --5200 rom...
		internal_ram => 0, -- only 1 option for 5200...
		video_bits => 8,
		palette => 0
	)
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N and SDRAM_RESET_N and not(reset_atari),

		VIDEO_VS => VGA_VS_RAW,
		VIDEO_HS => VGA_HS_RAW,
		VIDEO_B => VIDEO_B,
		VIDEO_G => open,
		VIDEO_R => open,

		AUDIO_L => AUDIO_L_PCM,
		AUDIO_R => AUDIO_R_PCM,

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

		THROTTLE_COUNT_6502 => speed_6502,
		HALT => pause_atari,

		-- JOYSTICK
		JOY1_X => signed(joy1x),
		JOY1_Y => signed(joy1y),
		JOY1_BUTTON => joy1_n(4),
		JOY2_X => signed(joy2x),
		JOY2_Y => signed(joy2y),
		JOY2_BUTTON => joy2_n(4),

		-- Pokey keyboard matrix
		-- Standard component available to connect this to PS2
		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,
		KEYBOARD_SCAN => KEYBOARD_SCAN,
		CONTROLLER_SELECT => CONTROLLER_SELECT
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
--SDRAM_REFRESH <= '0'; -- TODO

-- Until SDRAM enabled... TODO
--SDRAM_nCS <= '1';
--SDRAM_DQ <= (others=>'Z');

--SDRAM_CKE <= '1';		 
LED <= zpu_sio_rxd;

--VGA_HS <= not(VGA_HS_RAW xor VGA_VS_RAW);
--VGA_VS <= not(VGA_VS_RAW);

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
		
		VGA => vga,
		COMPOSITE_ON_HSYNC => composite_on_hsync,

		colour_enable => half_scandouble_enable_reg,
		doubled_enable => '1',
		scanlines_on => mist_switches(1),
		
		-- GTIA interface
		colour_in => VIDEO_B,
		vsync_in => VGA_VS_RAW,
		hsync_in => VGA_HS_RAW,
		
		-- TO TV...
		R => VGA_R,
		G => VGA_G,
		B => VGA_B,
		
		VSYNC => VGA_VS,
		HSYNC => VGA_HS
	);

zpu: entity work.zpucore
	GENERIC MAP
	(
		platform => 1,
		spi_clock_div => 16 -- 28MHz/2. Max for SD cards is 25MHz...
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
	
		ZPU_ROM_WREN => open,

		-- spi master
		ZPU_SD_DAT0 => mist_sd_sdo,
		ZPU_SD_CLK => mist_sd_sck,
		ZPU_SD_CMD => mist_sd_sdi,
		ZPU_SD_DAT3 => mist_sd_cs,

		-- SIO
		-- Ditto for speaking to Atari, we have a built in Pokey
		ZPU_POKEY_ENABLE => zpu_pokey_enable,
		ZPU_SIO_TXD => zpu_sio_txd,
		ZPU_SIO_RXD => zpu_sio_rxd,
		ZPU_SIO_COMMAND => zpu_sio_command,

		-- external control
		-- switches etc. sector DMA blah blah.
		ZPU_IN1 => X"00000"&(FKEYS(11) or (mist_buttons(0) and not(joy1_n(4))))&(FKEYS(10) or (mist_buttons(0) and joy1_n(4) and joy_still))&(FKEYS(9) or (mist_buttons(0) and joy1_n(4) and not(joy_still)))&FKEYS(8 downto 0),
		ZPU_IN2 => X"00000000",
		ZPU_IN3 => X"00000000",
		ZPU_IN4 => X"00000000",

		-- ouputs - e.g. Atari system control, halt, throttle, rom select
		ZPU_OUT1 => zpu_out1,
		ZPU_OUT2 => zpu_out2,
		ZPU_OUT3 => zpu_out3,
		ZPU_OUT4 => zpu_out4
	);

	pause_atari <= zpu_out1(0);
	reset_atari <= zpu_out1(1);
	speed_6502 <= zpu_out1(7 downto 2);
	ram_select <= zpu_out1(10 downto 8);
	rom_select <= zpu_out1(16 downto 11);

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
