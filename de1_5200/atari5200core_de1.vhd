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

LIBRARY work;

ENTITY atari5200core_de1 IS 
	GENERIC
	(
		TV : integer  -- 1 = PAL, 0=NTSC
	);
	PORT
	(
		CLOCK_50 :  IN  STD_LOGIC;

		AUD_BCLK :  IN  STD_LOGIC;
		AUD_DACLRCK :  IN  STD_LOGIC;
		I2C_SCLK :  INOUT  STD_LOGIC;
		I2C_SDAT :  INOUT  STD_LOGIC;

		PS2_CLK :  IN  STD_LOGIC;
		PS2_DAT :  IN  STD_LOGIC;

		UART_RXD :  IN  STD_LOGIC;
		UART_TXD :  OUT  STD_LOGIC;

		GPIO_0 :  INOUT  STD_LOGIC_VECTOR(35 DOWNTO 0);
		GPIO_1 :  INOUT  STD_LOGIC_VECTOR(35 DOWNTO 0);

		KEY :  IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
		SW :  IN  STD_LOGIC_VECTOR(9 DOWNTO 0);

		AUD_XCK :  OUT  STD_LOGIC;
		AUD_DACDAT :  OUT  STD_LOGIC;

		FL_OE_N :  OUT  STD_LOGIC;
		FL_WE_N :  OUT  STD_LOGIC;
		FL_RST_N :  OUT  STD_LOGIC;
		FL_ADDR :  OUT  STD_LOGIC_VECTOR(21 DOWNTO 0);
		FL_DQ :  IN  STD_LOGIC_VECTOR(7 DOWNTO 0);

		SRAM_CE_N :  OUT  STD_LOGIC;
		SRAM_OE_N :  OUT  STD_LOGIC;
		SRAM_WE_N :  OUT  STD_LOGIC;
		SRAM_LB_N :  OUT  STD_LOGIC;
		SRAM_UB_N :  OUT  STD_LOGIC;
		SRAM_ADDR :  OUT  STD_LOGIC_VECTOR(17 DOWNTO 0);
		SRAM_DQ :  INOUT  STD_LOGIC_VECTOR(15 DOWNTO 0);

		DRAM_BA_0 :  OUT  STD_LOGIC;
		DRAM_BA_1 :  OUT  STD_LOGIC;
		DRAM_CS_N :  OUT  STD_LOGIC;
		DRAM_RAS_N :  OUT  STD_LOGIC;
		DRAM_CAS_N :  OUT  STD_LOGIC;
		DRAM_WE_N :  OUT  STD_LOGIC;
		DRAM_LDQM :  OUT  STD_LOGIC;
		DRAM_UDQM :  OUT  STD_LOGIC;
		DRAM_CLK :  OUT  STD_LOGIC;
		DRAM_CKE :  OUT  STD_LOGIC;
		DRAM_ADDR :  OUT  STD_LOGIC_VECTOR(11 DOWNTO 0);
		DRAM_DQ :  INOUT  STD_LOGIC_VECTOR(15 DOWNTO 0);

		SD_CLK :  OUT  STD_LOGIC;
		SD_CMD :  OUT  STD_LOGIC;
		SD_THREE :  OUT  STD_LOGIC;
		SD_DATA :  IN  STD_LOGIC;

		HEX0 :  OUT  STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX1 :  OUT  STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX2 :  OUT  STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX3 :  OUT  STD_LOGIC_VECTOR(6 DOWNTO 0);

		LEDG :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		LEDR :  OUT  STD_LOGIC_VECTOR(9 DOWNTO 0);

		VGA_VS :  OUT  STD_LOGIC;
		VGA_HS :  OUT  STD_LOGIC;
		VGA_B :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_G :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_R :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0)
	);
END atari5200core_de1;

ARCHITECTURE vhdl OF atari5200core_de1 IS 
	-- SYSTEM
	SIGNAL CLK : STD_LOGIC;
	SIGNAL CLK_SDRAM : STD_LOGIC;
	SIGNAL RESET_N : STD_LOGIC;
	signal SDRAM_RESET_N : std_logic;
	SIGNAL PLL_LOCKED : STD_LOGIC;

	-- GTIA
	signal CONSOL_OUT : std_logic_vector(3 downto 0);
	signal CONSOL_IN : std_logic_vector(3 downto 0);
	signal GTIA_TRIG : std_logic_vector(3 downto 0);
	
	-- CARTRIDGE ACCESS
	--SIGNAL	CART_RD4 :  STD_LOGIC;
	--SIGNAL	CART_RD5 :  STD_LOGIC;
	--SIGNAL	CART_S4_n :  STD_LOGIC;
	--SIGNAL	CART_S5_n :  STD_LOGIC;
	--SIGNAL	CART_CCTL_n :  STD_LOGIC;
	
	-- PBI
	SIGNAL PBI_WRITE_DATA : std_logic_vector(31 downto 0);
	SIGNAL PBI_WIDTH_32BIT_ACCESS : std_logic;
	SIGNAL PBI_WIDTH_16BIT_ACCESS : std_logic;
	SIGNAL PBI_WIDTH_8BIT_ACCESS : std_logic;
	
	-- INTERNAL ROM/RAM
	SIGNAL	RAM_ADDR :  STD_LOGIC_VECTOR(18 DOWNTO 0);
	SIGNAL	RAM_DO :  STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL	RAM_REQUEST :  STD_LOGIC;
	SIGNAL	RAM_REQUEST_COMPLETE :  STD_LOGIC;
	SIGNAL	RAM_WRITE_ENABLE :  STD_LOGIC;
	
	SIGNAL	ROM_ADDR :  STD_LOGIC_VECTOR(21 DOWNTO 0);
	SIGNAL	ROM_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL	ROM_REQUEST :  STD_LOGIC;
	SIGNAL	ROM_REQUEST_COMPLETE :  STD_LOGIC;

	-- SDRAM
	signal SDRAM_REQUEST : std_logic;
	signal SDRAM_REQUEST_COMPLETE : std_logic;
	signal SDRAM_READ_ENABLE :  STD_LOGIC;
	signal SDRAM_WRITE_ENABLE : std_logic;
	signal SDRAM_ADDR : STD_LOGIC_VECTOR(22 DOWNTO 0);
	signal SDRAM_DO : STD_LOGIC_VECTOR(31 DOWNTO 0);
	
	signal SDRAM_REFRESH : std_logic;
	
	-- pokey keyboard
	SIGNAL KEYBOARD_SCAN : std_logic_vector(5 downto 0);
	SIGNAL KEYBOARD_RESPONSE : std_logic_vector(1 downto 0);
	
	-- SIO
	SIGNAL SIO_RXD : std_logic;
	SIGNAL SIO_COMMAND : std_logic;
	SIGNAL SIO_TXD : std_logic;

	SIGNAL GPIO_SIO_RXD : std_logic;

	-- VIDEO
	signal VGA_VS_RAW : std_logic;
	signal VGA_HS_RAW : std_logic;

	-- AUDIO
	signal AUDIO_LEFT : std_logic_vector(15 downto 0);
	signal AUDIO_RIGHT : std_logic_vector(15 downto 0);

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

	SIGNAL FKEYS : std_logic_vector(11 downto 0);

	-- system control from zpu
	signal reset_atari : std_logic;
	signal pause_atari : std_logic;
	SIGNAL speed_6502 : std_logic_vector(5 downto 0);

	-- GPIO
	signal GPIO_0_DIR_OUT : std_logic_vector(35 downto 0);
	signal GPIO_0_OUT : std_logic_vector(35 downto 0);
	signal GPIO_1_DIR_OUT : std_logic_vector(35 downto 0);
	signal GPIO_1_OUT : std_logic_vector(35 downto 0);
	signal TRIGGERS : std_logic_vector(3 downto 0);

	-- POT
	signal POT_RESET : std_logic;
	signal POT_IN : std_logic_vector(7 downto 0);

BEGIN 

-- ANYTHING NOT CONNECTED...
--GPIO_0(0) <= 'Z';
--GPIO_0(35 downto 2) <= (others=>'Z');
--GPIO_1(35 downto 0) <= (others=>'Z');

FL_OE_N <= '1';
FL_WE_N <= '1';
FL_RST_N <= '1';
FL_ADDR <= (others=>'0');

LEDG <= (others=>'1');
LEDR <= (others=>'1');

-- TODO FUJI? Or Program counter or...
hexdecoder0 : entity work.hexdecoder
PORT MAP(CLK => CLK,
		 NUMBER => X"5",
		 DIGIT => HEX0);


hexdecoder1 : entity work.hexdecoder
PORT MAP(CLK => CLK,
		 NUMBER => X"2",
		 DIGIT => HEX1);


hexdecoder2 : entity work.hexdecoder
PORT MAP(CLK => CLK,
		 NUMBER => X"0",
		 DIGIT => HEX2);


hexdecoder3 : entity work.hexdecoder
PORT MAP(CLK => CLK,
		 NUMBER => X"0",
		 DIGIT => HEX3);

sram1 : entity work.sram
PORT MAP(WREN => RAM_WRITE_ENABLE,
		 clk => CLK,
		 reset_n => RESET_N,
		 request => RAM_REQUEST,
		 width_16bit => PBI_WIDTH_16BIT_ACCESS,
		 ADDRESS => RAM_ADDR,
		 DIN => PBI_WRITE_DATA(15 DOWNTO 0),
		 SRAM_DQ => SRAM_DQ,
		 SRAM_CE_N => SRAM_CE_N,
		 SRAM_OE_N => SRAM_OE_N,
		 SRAM_WE_N => SRAM_WE_N,
		 SRAM_LB_N => SRAM_LB_N,
		 SRAM_UB_N => SRAM_UB_N,
		 complete => RAM_REQUEST_COMPLETE,
		 DOUT => RAM_DO,
		 SRAM_ADDR => SRAM_ADDR);

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
		 BYTE_ACCESS => PBI_WIDTH_8BIT_ACCESS,
		 WORD_ACCESS => PBI_WIDTH_16BIT_ACCESS,
		 LONGWORD_ACCESS => PBI_WIDTH_32BIT_ACCESS,
		 REFRESH => SDRAM_REFRESH,
		 ADDRESS_IN => SDRAM_ADDR,
		 DATA_IN => PBI_WRITE_DATA(31 downto 0),
		 SDRAM_DQ => DRAM_DQ,
		 COMPLETE => SDRAM_REQUEST_COMPLETE,
		 SDRAM_BA0 => DRAM_BA_0,
		 SDRAM_BA1 => DRAM_BA_1,
		 SDRAM_CKE => DRAM_CKE,
		 SDRAM_CS_N => DRAM_CS_N,
		 SDRAM_RAS_N => DRAM_RAS_N,
		 SDRAM_CAS_N => DRAM_CAS_N,
		 SDRAM_WE_N => DRAM_WE_N,
		 SDRAM_ldqm => DRAM_LDQM,
		 SDRAM_udqm => DRAM_UDQM,
		 DATA_OUT => SDRAM_DO,
		 SDRAM_ADDR => DRAM_ADDR(11 downto 0),
		 reset_client_n => SDRAM_RESET_N
		 );

-- GTIA triggers
--GTIA_TRIG <= CART_RD5&"1"&JOY2_n(4)&JOY1_n(4);
GTIA_TRIG <= TRIGGERS(3 downto 0);

-- Internal rom/ram
internalromram1 : entity work.internalromram
	GENERIC MAP
	(
		internal_rom => 0,
		internal_ram => 0
	)
	PORT MAP (
 		clock   => CLK,
		reset_n => RESET_N,

		ROM_ADDR => ROM_ADDR,
		ROM_REQUEST_COMPLETE => ROM_REQUEST_COMPLETE,
		ROM_REQUEST => ROM_REQUEST,
		ROM_DATA => ROM_DO,
		
		RAM_ADDR => RAM_ADDR,
		RAM_WR_ENABLE => RAM_WRITE_ENABLE,
		RAM_DATA_IN => PBI_WRITE_DATA(7 downto 0),
		RAM_REQUEST_COMPLETE => open,
		RAM_REQUEST => RAM_REQUEST,
		RAM_DATA => open
	);

--sync_switches1 : entity work.sync_switches
--PORT MAP(CLK => CLK,
--		 KEY => KEY,
--		 SW => SW,
--		 SYNC_KEYS => SYNC_KEYS,
--		 SYNC_SWITCHES => SYNC_SWITCHES);

gpio0_gen:
   for I in 0 to 35 generate
		gpio_0(I) <= gpio_0_out(I) when gpio_0_dir_out(I)='1' else 'Z';
   end generate gpio0_gen;

gpio1_gen:
   for I in 0 to 35 generate
		gpio_1(I) <= gpio_1_out(I) when gpio_1_dir_out(I)='1' else 'Z';
   end generate gpio1_gen;

gpio1 : entity work.gpio
PORT MAP(clk => CLK,
		 gpio_enable => '1',
		 pot_reset => pot_reset,
		 pbi_write_enable => '0',
		 cart_request => '0',
		 cart_complete => open,
		 cart_data_read => open,
		 s4_n => '0',
		 s5_n => '0',
		 cctl_n => '0',
		 cart_data_write => x"00",
		 GPIO_0_IN => GPIO_0,
		 GPIO_0_OUT => GPIO_0_OUT,
		 GPIO_0_DIR_OUT => GPIO_0_DIR_OUT,
		 GPIO_1_IN => GPIO_1,
		 GPIO_1_OUT => GPIO_1_OUT,
		 GPIO_1_DIR_OUT => GPIO_1_DIR_OUT,		 
		 keyboard_scan => KEYBOARD_SCAN, --5200
		 pbi_addr_out => X"0000",
		 porta_out => (others=>'0'),
		 porta_output => (others=>'0'),
		 lightpen => open,
		 rd4 => open,
		 rd5 => open,
		 keyboard_response => KEYBOARD_RESPONSE, -- 5200
		 porta_in => open,
		 pot_in => pot_in,
		 trig_in => TRIGGERS, -- 5200
		 CA2_DIR_OUT => '0',
		 CA2_OUT => '0',
		 CA2_IN => open,
		 CB2_DIR_OUT => '0',
		 CB2_OUT => '0',
		 CB2_IN => open,
		 SIO_IN => GPIO_SIO_RXD,
		 SIO_OUT => SIO_TXD,
		CONSOL => CONSOL_OUT
		 );

--b2v_inst22 : entity work.scandoubler
--PORT MAP(CLK => CLK,
--		 RESET_N => RESET_N,
--		 VGA => VGA,
--		 COMPOSITE_ON_HSYNC => COMPOSITE_ON_HSYNC,
--		 colour_enable => SCANDOUBLER_SHARED_ENABLE_LOW,
--		 doubled_enable => SCANDOUBLER_SHARED_ENABLE_HIGH,
--		 vsync_in => SYNTHESIZED_WIRE_12,
--		 hsync_in => SYNTHESIZED_WIRE_13,
--		 colour_in => SYNTHESIZED_WIRE_14,
--		 VSYNC => VGA_VS,
--		 HSYNC => VGA_HS,
--		 B => VGA_B,
--		 G => VGA_G,
--		 R => VGA_R);


audio_codec_config_over_i2c : entity work.i2c_loader
GENERIC MAP(device_address => 26,
			log2_divider => 6,
			num_retries => 0
			)
PORT MAP(CLK => CLK,
		 nRESET => RESET_N,
		 I2C_SCL => I2C_SCLK,
		 I2C_SDA => I2C_SDAT);

audio_codec_data : entity work.i2sslave
PORT MAP(CLK => CLK,
		 BCLK => AUD_BCLK,
		 DACLRC => AUD_DACLRCK,
		 LEFT_IN => AUDIO_LEFT,
		 RIGHT_IN => AUDIO_RIGHT,
		 MCLK_2 => AUD_XCK,
		 DACDAT => AUD_DACDAT);


pll : entity work.pll
PORT MAP(inclk0 => CLOCK_50,
		 c0 => CLK_SDRAM,
		 c1 => CLK,
		 c2 => DRAM_CLK,
		 locked => PLL_LOCKED);

--gen_ntsc_pll : if tv=0 generate
--pll : entity work.pll_ntsc
--PORT MAP(inclk0 => CLOCK_27(0),
--		 c0 => CLK_SDRAM,
--		 c1 => CLK,
--		 c2 => DRAM_CLK,
--		 locked => PLL_LOCKED);
--end generate;
--
--gen_pal_pll : if tv=1 generate
--pll : entity work.pll_pal
--PORT MAP(inclk0 => CLOCK_27(0),
--		 c0 => CLK_SDRAM,
--		 c1 => CLK,
--		 c2 => DRAM_CLK,
--		 locked => PLL_LOCKED);
--end generate;

RESET_N <= PLL_LOCKED;

-- PS2 to pokey
keyboard_map1 : entity work.ps2_to_atari5200
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,
		PS2_CLK => ps2_clk,
		PS2_DAT => ps2_dat,
		
		KEYBOARD_SCAN => KEYBOARD_SCAN,
		KEYBOARD_RESPONSE => open,

		FIRE2 => (others=>'0'),
		CONTROLLER_SELECT => (others=>'0'),

		FKEYS => FKEYS
	);

-- SIO
-- TODO combine
--SIO_RXD <= UART_RXD;
UART_TXD <= SIO_TXD;
--GPIO_0(1) <= SIO_COMMAND;

SIO_COMMAND <= 'Z'; -- no PIA...
zpu_sio_command <= SIO_COMMAND;
zpu_sio_rxd <= SIO_TXD;
SIO_RXD <= zpu_sio_txd and UART_RXD;

-- VIDEO
VGA_HS <= not(VGA_HS_RAW xor VGA_VS_RAW);
VGA_VS <= not(VGA_VS_RAW);

CONSOL_IN <= "1000";

atari5200 : entity work.atari5200core
	GENERIC MAP
	(
		cycle_length => 32,
		video_bits => 4
	)
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N and SDRAM_RESET_N and not(reset_atari),

		VIDEO_VS => VGA_VS_RAW,
		VIDEO_HS => VGA_HS_RAW,
		VIDEO_B => VGA_B,
		VIDEO_G => VGA_G,
		VIDEO_R => VGA_R,

		AUDIO_L => AUDIO_LEFT,
		AUDIO_R => AUDIO_RIGHT,

		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,
		KEYBOARD_SCAN => KEYBOARD_SCAN,

		POT_IN => POT_IN,
		POT_RESET => POT_RESET,
		
		PBI_ADDR => open,
		PBI_WRITE_ENABLE => open,
		PBI_SNOOP_DATA => open,
		PBI_WRITE_DATA => PBI_WRITE_DATA,
		PBI_WIDTH_8bit_ACCESS => PBI_WIDTH_8bit_ACCESS,
		PBI_WIDTH_16bit_ACCESS => PBI_WIDTH_16bit_ACCESS,
		PBI_WIDTH_32bit_ACCESS => PBI_WIDTH_32bit_ACCESS,

		PBI_ROM_DO => "11111111",
		PBI_REQUEST => open,
		PBI_REQUEST_COMPLETE => '1',

		SIO_RXD => SIO_RXD,
		SIO_TXD => SIO_TXD,

		CONSOL_OUT => CONSOL_OUT,
		CONSOL_IN => CONSOL_IN,
		GTIA_TRIG => GTIA_TRIG,
		
		SDRAM_REQUEST => SDRAM_REQUEST,
		SDRAM_REQUEST_COMPLETE => SDRAM_REQUEST_COMPLETE,
		SDRAM_READ_ENABLE => SDRAM_READ_ENABLE,
		SDRAM_WRITE_ENABLE => SDRAM_WRITE_ENABLE,
		SDRAM_ADDR => SDRAM_ADDR,
		SDRAM_DO => SDRAM_DO,

		ANTIC_REFRESH => SDRAM_REFRESH,

		RAM_ADDR => RAM_ADDR,
		RAM_DO => RAM_DO,
		RAM_REQUEST => RAM_REQUEST,
		RAM_REQUEST_COMPLETE => RAM_REQUEST_COMPLETE,
		RAM_WRITE_ENABLE => RAM_WRITE_ENABLE,
		
		ROM_ADDR => ROM_ADDR,
		ROM_DO => ROM_DO,
		ROM_REQUEST => ROM_REQUEST,
		ROM_REQUEST_COMPLETE => ROM_REQUEST_COMPLETE,

		DMA_FETCH => dma_fetch,
		DMA_READ_ENABLE => dma_read_enable,
		DMA_32BIT_WRITE_ENABLE => dma_32bit_write_enable,
		DMA_16BIT_WRITE_ENABLE => dma_16bit_write_enable,
		DMA_8BIT_WRITE_ENABLE => dma_8bit_write_enable,
		DMA_ADDR => dma_addr_fetch,
		DMA_WRITE_DATA => dma_write_data,
		MEMORY_READY_DMA => dma_memory_ready,
		--DMA_MEMORY_DATA => dma_memory_data,  
		PBI_SNOOP_DATA => DMA_MEMORY_DATA,

		USE_SDRAM => '1', --SW(9), -- TODO
		ROM_IN_RAM => '1',
		HALT => pause_atari,
		THROTTLE_COUNT_6502 => speed_6502
	);

zpu: entity work.zpucore
	GENERIC MAP
	(
		platform => 1,
		spi_clock_div => 1 -- 28MHz/2. Max for SD cards is 25MHz...
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
		ZPU_SD_DAT0 => sd_data,
		ZPU_SD_CLK => sd_clk,
		ZPU_SD_CMD => sd_cmd,
		ZPU_SD_DAT3 => sd_three,

		-- SIO
		-- Ditto for speaking to Atari, we have a built in Pokey
		ZPU_POKEY_ENABLE => zpu_pokey_enable,
		ZPU_SIO_TXD => zpu_sio_txd,
		ZPU_SIO_RXD => zpu_sio_rxd,
		ZPU_SIO_COMMAND => zpu_sio_command,

		-- external control
		-- switches etc. sector DMA blah blah.
		ZPU_IN1 => X"00000"&FKEYS,
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
