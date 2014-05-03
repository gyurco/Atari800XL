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

ENTITY atari800core_de1 IS 
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
END atari800core_de1;

ARCHITECTURE vhdl OF atari800core_de1 IS 
	-- SYSTEM
	SIGNAL CLK : STD_LOGIC;
	SIGNAL CLK_SDRAM : STD_LOGIC;
	SIGNAL RESET_N : STD_LOGIC;
	signal SDRAM_RESET_N : std_logic;
	SIGNAL PLL_LOCKED : STD_LOGIC;

	-- PIA
	SIGNAL	CA1_IN :  STD_LOGIC;
	SIGNAL	CB1_IN:  STD_LOGIC;
	SIGNAL	CA2_OUT :  STD_LOGIC;
	SIGNAL	CA2_DIR_OUT:  STD_LOGIC;
	SIGNAL	CB2_OUT :  STD_LOGIC;
	SIGNAL	CB2_DIR_OUT:  STD_LOGIC;
	SIGNAL	CA2_IN:  STD_LOGIC;
	SIGNAL	CB2_IN:  STD_LOGIC;
	SIGNAL	PORTA_IN :  STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL	PORTA_OUT :  STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL	PORTA_DIR_OUT :  STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL	PORTB_IN :  STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL	PORTB_OUT :  STD_LOGIC_VECTOR(7 DOWNTO 0);
	--SIGNAL	PORTB_DIR_OUT :  STD_LOGIC_VECTOR(7 DOWNTO 0);
	
	-- GTIA
	signal GTIA_TRIG : std_logic_vector(3 downto 0);
	
	-- ANTIC
	signal ANTIC_LIGHTPEN : std_logic;
	
	-- CARTRIDGE ACCESS
	SIGNAL	CART_RD4 :  STD_LOGIC;
	SIGNAL	CART_RD5 :  STD_LOGIC;
	
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
	
	signal SYSTEM_RESET_REQUEST: std_logic;

	-- pokey keyboard
	SIGNAL KEYBOARD_SCAN : std_logic_vector(5 downto 0);
	SIGNAL KEYBOARD_RESPONSE : std_logic_vector(1 downto 0);
	
	-- gtia consol keys
	SIGNAL CONSOL_START : std_logic;
	SIGNAL CONSOL_SELECT : std_logic;
	SIGNAL CONSOL_OPTION : std_logic;
	
	-- 6502 throttling
	SIGNAL THROTTLE_COUNT_6502 : std_logic_vector(5 downto 0);

	-- SIO
	SIGNAL SIO_RXD : std_logic;
	SIGNAL SIO_COMMAND : std_logic;
	SIGNAL SIO_TXD : std_logic;

	-- VIDEO
	signal VGA_VS_RAW : std_logic;
	signal VGA_HS_RAW : std_logic;

	-- AUDIO
	signal AUDIO_LEFT : std_logic_vector(15 downto 0);
	signal AUDIO_RIGHT : std_logic_vector(15 downto 0);

BEGIN 

-- ANYTHING NOT CONNECTED...
GPIO_0(0) <= 'Z';
GPIO_0(35 downto 2) <= (others=>'Z');
GPIO_1(35 downto 0) <= (others=>'Z');

FL_OE_N <= '1';
FL_WE_N <= '1';
FL_RST_N <= '1';
FL_ADDR <= (others=>'0');

SD_CLK <= '1';
SD_CMD <= '1';
SD_THREE <= '1';

LEDG <= (others=>'1');
LEDR <= (others=>'1');

SYSTEM_RESET_REQUEST <= '0';

-- TODO FUJI? Or Program counter or...
hexdecoder0 : entity work.hexdecoder
PORT MAP(CLK => CLK,
		 NUMBER => X"A",
		 DIGIT => HEX0);


hexdecoder1 : entity work.hexdecoder
PORT MAP(CLK => CLK,
		 NUMBER => X"7",
		 DIGIT => HEX1);


hexdecoder2 : entity work.hexdecoder
PORT MAP(CLK => CLK,
		 NUMBER => X"A",
		 DIGIT => HEX2);


hexdecoder3 : entity work.hexdecoder
PORT MAP(CLK => CLK,
		 NUMBER => X"1",
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
		 RESET_N =>  RESET_N and not(SYSTEM_RESET_REQUEST),
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
		 
SDRAM_REFRESH <= '0'; -- TODO

-- PIA mapping
CA1_IN <= '1';
CB1_IN <= '1';
CA2_IN <= CA2_OUT when CA2_DIR_OUT='1' else '1';
CB2_IN <= CB2_OUT when CB2_DIR_OUT='1' else '1';
SIO_COMMAND <= CB2_OUT;
--PORTA_IN <= ((JOY2_n(3)&JOY2_n(2)&JOY2_n(1)&JOY2_n(0)&JOY1_n(3)&JOY1_n(2)&JOY1_n(1)&JOY1_n(0)) and not (porta_dir_out)) or (porta_dir_out and porta_out);
PORTA_IN <= (not (porta_dir_out)) or (porta_dir_out and porta_out);
PORTB_IN <= PORTB_OUT;

-- ANTIC lightpen
ANTIC_LIGHTPEN <= '1'; --JOY2_n(4) and JOY1_n(4);

-- GTIA triggers
--GTIA_TRIG <= CART_RD5&"1"&JOY2_n(4)&JOY1_n(4);
GTIA_TRIG <= CART_RD5&"111";

-- Cartridge not inserted
CART_RD4 <= '0';
CART_RD5 <= '0';

-- Internal rom/ram
internalromram1 : entity work.internalromram
	GENERIC MAP
	(
		internal_rom => 1,
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

--gpio0_gen:
--   for I in 0 to 35 generate
--		gpio_0(I) <= gpio_0_out(I) when gpio_0_dir_out(I)='1' else 'Z';
--   end generate gpio0_gen;
--
--gpio1_gen:
--   for I in 0 to 35 generate
--		gpio_1(I) <= gpio_1_out(I) when gpio_1_dir_out(I)='1' else 'Z';
--   end generate gpio1_gen;
	
--b2v_inst19 : entity work.gpio
--PORT MAP(clk => CLK,
--		 gpio_enable => GPIO_ENABLE,
--		 pot_reset => POT_RESET,
--		 virtual_keyheld => KEY_HELD,
--		 virtual_shift_pressed => SHIFT_PRESSED,
--		 virtual_control_pressed => KBCODE(7),
--		 virtual_break_pressed => BREAK_PRESSED,
--		 pbi_write_enable => PBI_WRITE_ENABLE,
--		 cart_request => CART_REQUEST,
--		 s4_n => CART_S4_n,
--		 s5_n => CART_S5_N,
--		 cctl_n => CART_CCTL_N,
--		 cart_data_write => WRITE_DATA(7 DOWNTO 0),
--		 GPIO_0_IN => GPIO_0,
--		 GPIO_0_OUT => GPIO_0_OUT,
--		 GPIO_0_DIR_OUT => GPIO_0_DIR_OUT,
--		 GPIO_1_IN => GPIO_1,
--		 GPIO_1_OUT => GPIO_1_OUT,
--		 GPIO_1_DIR_OUT => GPIO_1_DIR_OUT,		 
--		 keyboard_scan => KEYBOARD_SCAN,
--		 pbi_addr_out => PBI_ADDR,
--		 porta_out => PORTA_OUT,
--		 porta_output => PORTA_DIR_OUT,
--		 virtual_keycode => KBCODE(5 DOWNTO 0),
--		 virtual_stick_in => VIRTUAL_STICKS,
--		 virtual_trig_in => VIRTUAL_TRIGGERS,
--		 lightpen => LIGHTPEN,
--		 cart_complete => CART_REQUEST_COMPLETE,
--		 rd4 => CART_RD4,
--		 rd5 => CART_RD5,
--		 cart_data_read => CART_ROM_DO,
--		 keyboard_response => KEYBOARD_RESPONSE,
--		 porta_in => GPIO_PORTA_IN,
--		 pot_in => POT_IN,
--		 trig_in => TRIGGERS,
--		 monitor => SIO_DATA_IN, -- i.e. zpu sio out
--		 CA2_DIR_OUT => CA2_DIR_OUT,
--		 CA2_OUT => CA2_OUT,
--		 CA2_IN => GPIO_CA2_IN,
--		 CB2_DIR_OUT => CB2_DIR_OUT,
--		 CB2_OUT => CB2_OUT,
--		 CB2_IN => GPIO_CB2_IN,
--		 SIO_IN => GPIO_SIO_IN,
--		 SIO_OUT => GPIO_SIO_OUT
--		 );

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

RESET_N <= PLL_LOCKED;

-- PS2 to pokey
keyboard_map1 : entity work.ps2_to_atari800
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,
		PS2_CLK => ps2_clk,
		PS2_DAT => ps2_dat,
		
		KEYBOARD_SCAN => KEYBOARD_SCAN,
		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,

		CONSOL_START => CONSOL_START,
		CONSOL_SELECT => CONSOL_SELECT,
		CONSOL_OPTION => CONSOL_OPTION
		
		-- TODO - reset!
	);

-- SIO
SIO_RXD <= UART_RXD;
UART_TXD <= SIO_TXD;
GPIO_0(1) <= SIO_COMMAND;

-- THROTTLE
THROTTLE_COUNT_6502 <= std_logic_vector(to_unsigned(1,6));

-- VIDEO
VGA_HS <= not(VGA_HS_RAW xor VGA_VS_RAW);
VGA_VS <= not(VGA_VS_RAW);

atari800 : entity work.atari800core
	GENERIC MAP
	(
		cycle_length => 32,
		video_bits => 4
	)
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N and SDRAM_RESET_N and not(SYSTEM_RESET_REQUEST),

		VIDEO_VS => VGA_VS_RAW,
		VIDEO_HS => VGA_HS_RAW,
		VIDEO_B => VGA_B,
		VIDEO_G => VGA_G,
		VIDEO_R => VGA_R,

		AUDIO_L => AUDIO_LEFT,
		AUDIO_R => AUDIO_RIGHT,

		CA1_IN => CA1_IN,
		CB1_IN => CB1_IN,
		CA2_IN => CA2_IN,
		CA2_OUT => CA2_OUT,
		CA2_DIR_OUT => CA2_DIR_OUT,
		CB2_IN => CB2_IN,
		CB2_OUT => CB2_OUT,
		CB2_DIR_OUT => CB2_DIR_OUT,
		PORTA_IN => PORTA_IN,
		PORTA_DIR_OUT => PORTA_DIR_OUT,
		PORTA_OUT => PORTA_OUT,
		PORTB_IN => PORTB_IN,
		PORTB_DIR_OUT => open,--PORTB_DIR_OUT,
		PORTB_OUT => PORTB_OUT,

		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,
		KEYBOARD_SCAN => KEYBOARD_SCAN,

		POT_IN => "00000000",
		POT_RESET => open,
		
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

		CART_RD4 => CART_RD4,
		CART_RD5 => CART_RD5,
		CART_S4_n => open,
		CART_S5_N => open,
		CART_CCTL_N => open,

		SIO_RXD => SIO_RXD,
		SIO_TXD => SIO_TXD,

		CONSOL_OPTION => CONSOL_OPTION,
		CONSOL_SELECT => CONSOL_SELECT,
		CONSOL_START=> CONSOL_START,
		GTIA_TRIG => GTIA_TRIG,
		
		ANTIC_LIGHTPEN => ANTIC_LIGHTPEN,

		SDRAM_REQUEST => SDRAM_REQUEST,
		SDRAM_REQUEST_COMPLETE => SDRAM_REQUEST_COMPLETE,
		SDRAM_READ_ENABLE => SDRAM_READ_ENABLE,
		SDRAM_WRITE_ENABLE => SDRAM_WRITE_ENABLE,
		SDRAM_ADDR => SDRAM_ADDR,
		SDRAM_DO => SDRAM_DO,

		ANTIC_REFRESH => open, -- TODO

		RAM_ADDR => RAM_ADDR,
		RAM_DO => RAM_DO,
		RAM_REQUEST => RAM_REQUEST,
		RAM_REQUEST_COMPLETE => RAM_REQUEST_COMPLETE,
		RAM_WRITE_ENABLE => RAM_WRITE_ENABLE,
		
		ROM_ADDR => ROM_ADDR,
		ROM_DO => ROM_DO,
		ROM_REQUEST => ROM_REQUEST,
		ROM_REQUEST_COMPLETE => ROM_REQUEST_COMPLETE,

		DMA_FETCH => '0',
		DMA_READ_ENABLE => '0',
		DMA_32BIT_WRITE_ENABLE => '0',
		DMA_16BIT_WRITE_ENABLE => '0',
		DMA_8BIT_WRITE_ENABLE => '0',
		DMA_ADDR => (others=>'0'),
		DMA_WRITE_DATA => (others=>'0'),
		MEMORY_READY_DMA => open,

		RAM_SELECT => "110",
		ROM_SELECT => (others=>'0'),
		CART_EMULATION_SELECT => "0000000",
		CART_EMULATION_ACTIVATE => '0',
		PAL => '1',
		USE_SDRAM => '1',
		ROM_IN_RAM => '0',
		THROTTLE_COUNT_6502 => THROTTLE_COUNT_6502,
		HALT => '0' 
	);

END vhdl;
