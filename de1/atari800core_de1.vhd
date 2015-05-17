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
	GENERIC
	(
		TV : integer; -- 1 = PAL, 0=NTSC
		GPIO : integer  -- 1 = OLD GPIO LAYOUT, 2=NEW GPIO LAYOUT (WIP)
	);
	PORT
	(
		CLOCK_50 :  IN  STD_LOGIC;
		CLOCK_27 :  IN  STD_LOGIC_VECTOR(1 downto 0);

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
	SIGNAL	CART_S4_n :  STD_LOGIC;
	SIGNAL	CART_S5_n :  STD_LOGIC;
	SIGNAL	CART_CCTL_n :  STD_LOGIC;
	
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
	
	-- gtia consol keys
	SIGNAL CONSOL_START : std_logic;
	SIGNAL CONSOL_SELECT : std_logic;
	SIGNAL CONSOL_OPTION : std_logic;
	
	-- SIO
	SIGNAL SIO_RXD : std_logic;
	SIGNAL SIO_COMMAND : std_logic;
	SIGNAL SIO_TXD : std_logic;

	SIGNAL GPIO_SIO_RXD : std_logic;

	SIGNAL SIO_CLOCKOUT : std_logic;
	SIGNAL SIO_CLOCKIN : std_logic;

	-- VIDEO
	signal VGA_VS_RAW : std_logic;
	signal VGA_HS_RAW : std_logic;
	signal VGA_CS_RAW : std_logic;

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
	signal ram_select : std_logic_vector(2 downto 0);
	signal reset_atari : std_logic;
	signal pause_atari : std_logic;
	SIGNAL speed_6502 : std_logic_vector(5 downto 0);
	signal emulated_cartridge_select: std_logic_vector(5 downto 0);

	-- GPIO
	signal GPIO_0_DIR_OUT : std_logic_vector(35 downto 0);
	signal GPIO_0_OUT : std_logic_vector(35 downto 0);
	signal GPIO_1_DIR_OUT : std_logic_vector(35 downto 0);
	signal GPIO_1_OUT : std_logic_vector(35 downto 0);
	signal TRIGGERS : std_logic_vector(3 downto 0);

	signal POT_RESET : std_logic;
	signal POT_IN : std_logic_vector(7 downto 0);

	signal GPIO_KEYBOARD_RESPONSE  : std_logic_vector(1 downto 0);
	signal PS2_KEYBOARD_RESPONSE  : std_logic_vector(1 downto 0);

	signal PBI_WRITE_ENABLE : std_logic;
	signal PBI_ADDRESS : std_logic_vector(15 downto 0);

	signal cart_request : std_logic;
	signal cart_request_complete : std_logic;
	signal cart_data : std_logic_vector(7 downto 0);

	signal pbi_addr : std_logic_vector(15 downto 0);

	signal enable_179_early : std_logic;

	-- scandoubler
	signal half_scandouble_enable_reg : std_logic;
	signal half_scandouble_enable_next : std_logic;
	signal VIDEO_B : std_logic_vector(7 downto 0);

	signal freezer_enable : std_logic;
	signal freezer_activate: std_logic;

	signal freezer_state: std_logic_vector(2 downto 0);

	signal pbi_enable: std_logic;

	signal pal : std_logic;

	signal PS2_KEYS : STD_LOGIC_VECTOR(511 downto 0);
	signal PS2_KEYS_NEXT : STD_LOGIC_VECTOR(511 downto 0);
BEGIN 

	pbi_enable <= SW(4);
	PAL <= SW(8);

-- ANYTHING NOT CONNECTED...
--GPIO_0(0) <= 'Z';
--GPIO_0(35 downto 2) <= (others=>'Z');
--GPIO_1(35 downto 0) <= (others=>'Z');

FL_OE_N <= '1';
FL_WE_N <= '1';
FL_RST_N <= '1';
FL_ADDR <= (others=>'0');

process(freezer_enable, freezer_activate, freezer_state)
begin
LEDG <= (others=>'1');
LEDR <= (others=>'1');
LEDG(0) <= freezer_enable;
LEDG(1) <= freezer_activate;
LEDG(4 downto 2) <= freezer_state;
end process;

-- TODO FUJI? Or Program counter or...
hexdecoder0 : entity work.hexdecoder
PORT MAP(CLK => CLK,
		 NUMBER => X"A",
		 DIGIT => HEX0);


hexdecoder1 : entity work.hexdecoder
PORT MAP(CLK => CLK,
		 NUMBER => X"8",
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

-- PIA mapping
-- emulate pull-up on command line
SIO_COMMAND <= CB2_OUT when CB2_DIR_OUT='1' else '1';
-- SIO_COMMAND <= CB2_OUT;
--PORTA_IN <= ((JOY2_n(3)&JOY2_n(2)&JOY2_n(1)&JOY2_n(0)&JOY1_n(3)&JOY1_n(2)&JOY1_n(1)&JOY1_n(0)) and not (porta_dir_out)) or (porta_dir_out and porta_out);
--PORTA_IN <= (not (porta_dir_out)) or (porta_dir_out and porta_out);
PORTB_IN <= PORTB_OUT;

-- GTIA triggers
--GTIA_TRIG <= CART_RD5&"1"&JOY2_n(4)&JOY1_n(4);
GTIA_TRIG <= "11"&TRIGGERS(1 downto 0);

-- Cartridge not inserted
--CART_RD4 <= '0';
--CART_RD5 <= '0';

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

gen_old_gpio : if gpio=1 generate
gpio1 : entity work.gpio
GENERIC MAP(
		cartridge_cycle_length => 26
)
PORT MAP(clk => CLK,
	reset_n => reset_n,
		 gpio_enable => pbi_enable,
		 pot_reset => pot_reset,
		 pbi_write_enable => pbi_write_enable,
		 enable_179_early => enable_179_early,
		 cart_request => cart_request,
		 cart_complete => cart_request_complete,
		 cart_data_read => cart_data,
		 s4_n => cart_s4_n,
		 s5_n => cart_s5_n,
		 cctl_n => cart_cctl_n,
		 cart_data_write => pbi_write_data(7 downto 0),
		 GPIO_0_IN => GPIO_0,
		 GPIO_0_OUT => GPIO_0_OUT,
		 GPIO_0_DIR_OUT => GPIO_0_DIR_OUT,
		 GPIO_1_IN => GPIO_1,
		 GPIO_1_OUT => GPIO_1_OUT,
		 GPIO_1_DIR_OUT => GPIO_1_DIR_OUT,		 
		 keyboard_scan => KEYBOARD_SCAN,
		 pbi_addr_out => pbi_addr,
		 porta_out => PORTA_OUT,
		 porta_output => PORTA_DIR_OUT,
		 lightpen => ANTIC_LIGHTPEN,
		 rd4 => CART_RD4,
		 rd5 => CART_RD5,
		 keyboard_response => GPIO_KEYBOARD_RESPONSE,
		 porta_in => PORTA_IN,
		 pot_in => pot_in,
		 trig_in => TRIGGERS,
		 CA2_DIR_OUT => CA2_DIR_OUT,
		 CA2_OUT => CA2_OUT,
		 CA2_IN => open,
		 CB2_DIR_OUT => CB2_DIR_OUT,
		 CB2_OUT => CB2_OUT,
		 CB2_IN => open,
		 SIO_IN => GPIO_SIO_RXD,
		 SIO_OUT => SIO_TXD
		 );

	CA1_IN <= '1';
	CB1_IN <= '1';
	CA2_IN <= CA2_OUT when CA2_DIR_OUT='1' else '1';
	CB2_IN <= CB2_OUT when CB2_DIR_OUT='1' else '1';
end generate gen_old_gpio;

gen_new_gpio : if gpio=2 generate
gpio2 : entity work.gpiov2
GENERIC MAP(
		cartridge_cycle_length => 26
)
PORT MAP(clk => CLK,
	reset_n => reset_n,
		 gpio_enable => pbi_enable,
		 pot_reset => pot_reset,
		 pbi_write_enable => pbi_write_enable,
		 enable_179_early => enable_179_early,
		 cart_request => cart_request,
		 cart_complete => cart_request_complete,
		 cart_data_read => cart_data,
		 s4_n => cart_s4_n,
		 s5_n => cart_s5_n,
		 cctl_n => cart_cctl_n,
		 cart_data_write => pbi_write_data(7 downto 0),
		 GPIO_0_IN => GPIO_0,
		 GPIO_0_OUT => GPIO_0_OUT,
		 GPIO_0_DIR_OUT => GPIO_0_DIR_OUT,
		 GPIO_1_IN => GPIO_1,
		 GPIO_1_OUT => GPIO_1_OUT,
		 GPIO_1_DIR_OUT => GPIO_1_DIR_OUT,		 
		 keyboard_scan => KEYBOARD_SCAN,
		 pbi_addr_out => pbi_addr,
		 porta_out => PORTA_OUT,
		 porta_output => PORTA_DIR_OUT,
		 lightpen => ANTIC_LIGHTPEN,
		 rd4 => CART_RD4,
		 rd5 => CART_RD5,
		 keyboard_response => GPIO_KEYBOARD_RESPONSE,
		 porta_in => PORTA_IN,
		 pot_in => pot_in,
		 trig_in => TRIGGERS,
		 CA2_DIR_OUT => CA2_DIR_OUT,
		 CA2_OUT => CA2_OUT,
		 CA2_IN => CA2_IN,
		 CB2_DIR_OUT => CB2_DIR_OUT,
		 CB2_OUT => CB2_OUT,
		 CB2_IN => CB2_IN,
		 SIO_IN => GPIO_SIO_RXD,
		 SIO_OUT => SIO_TXD,
		 SIO_CLOCKIN => SIO_CLOCKIN,
		 SIO_CLOCKOUT => SIO_CLOCKOUT
		 );
end generate gen_new_gpio;

	process(clk,RESET_N,SDRAM_RESET_N,reset_atari)
	begin
		if ((RESET_N and SDRAM_RESET_N and not(reset_atari))='0') then
			half_scandouble_enable_reg <= '0';
		elsif (clk'event and clk='1') then
			half_scandouble_enable_reg <= half_scandouble_enable_next;
		end if;
	end process;

	half_scandouble_enable_next <= not(half_scandouble_enable_reg);

scandoubler : entity work.scandoubler
GENERIC MAP
(
	video_bits=>4
)
PORT MAP(CLK => CLK,
		 RESET_N => RESET_N and SDRAM_RESET_N and not(reset_atari),
		 VGA => SW(7),
		 COMPOSITE_ON_HSYNC => SW(6),
		 colour_enable => half_scandouble_enable_reg,
		 doubled_enable => '1',
	 	 scanlines_on => SW(5),
		 vsync_in => VGA_VS_RAW,
		 hsync_in => VGA_HS_RAW,
		 csync_in => VGA_CS_RAW,
		 pal => PAL,
		 colour_in => VIDEO_B,
		 VSYNC => VGA_VS,
		 HSYNC => VGA_HS,
		 B => VGA_B,
		 G => VGA_G,
		 R => VGA_R);

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
--
--gen_old_pll : if tv=2 generate
pll : entity work.pll
PORT MAP(inclk0 => CLOCK_50,
		 c0 => CLK_SDRAM,
		 c1 => CLK,
		 c2 => DRAM_CLK,
		 locked => PLL_LOCKED);
--end generate;

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
		KEYBOARD_RESPONSE => PS2_KEYBOARD_RESPONSE,

		CONSOL_START => CONSOL_START,
		CONSOL_SELECT => CONSOL_SELECT,
		CONSOL_OPTION => CONSOL_OPTION,
		
		FKEYS => FKEYS,
		FREEZER_ACTIVATE => freezer_activate,

		PS2_KEYS_NEXT_OUT => ps2_keys_next,
		PS2_KEYS => ps2_keys
	);

KEYBOARD_RESPONSE <= PS2_KEYBOARD_RESPONSE and GPIO_KEYBOARD_RESPONSE;

-- SIO
-- TODO combine
--SIO_RXD <= UART_RXD;
UART_TXD <= SIO_TXD;
--GPIO_0(1) <= SIO_COMMAND;

zpu_sio_command <= SIO_COMMAND;
zpu_sio_rxd <= SIO_TXD;
SIO_RXD <= zpu_sio_txd and UART_RXD and GPIO_SIO_RXD;

-- VIDEO
--VGA_HS <= not(VGA_HS_RAW xor VGA_VS_RAW);
--VGA_VS <= not(VGA_VS_RAW);

atari800 : entity work.atari800core
	GENERIC MAP
	(
		cycle_length => 32,
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
		PORTA_IN => PORTA_IN and not("0000"&ps2_keys(16#174#)&ps2_keys(16#16B#)&ps2_keys(16#172#)&ps2_keys(16#175#)),
		PORTA_DIR_OUT => PORTA_DIR_OUT,
		PORTA_OUT => PORTA_OUT,
		PORTB_IN => PORTB_IN,
		PORTB_DIR_OUT => open,--PORTB_DIR_OUT,
		PORTB_OUT => PORTB_OUT,

		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,
		KEYBOARD_SCAN => KEYBOARD_SCAN,

		POT_IN => POT_IN,
		POT_RESET => POT_RESET,
		
		ENABLE_179_EARLY => ENABLE_179_EARLY,
		PBI_ADDR => PBI_ADDR,
		PBI_WRITE_ENABLE => PBI_WRITE_ENABLE,
		PBI_SNOOP_DATA => open,
		PBI_WRITE_DATA => PBI_WRITE_DATA,
		PBI_WIDTH_8bit_ACCESS => PBI_WIDTH_8bit_ACCESS,
		PBI_WIDTH_16bit_ACCESS => PBI_WIDTH_16bit_ACCESS,
		PBI_WIDTH_32bit_ACCESS => PBI_WIDTH_32bit_ACCESS,

		PBI_ROM_DO => CART_DATA,
		PBI_REQUEST => CART_REQUEST,
		PBI_REQUEST_COMPLETE => CART_REQUEST_COMPLETE,

		CART_RD4 => CART_RD4,
		CART_RD5 => CART_RD5,
		CART_S4_n => CART_S4_n,
		CART_S5_N => CART_S5_n,
		CART_CCTL_N => CART_CCTL_n,

		SIO_RXD => SIO_RXD,
		SIO_TXD => SIO_TXD,

		SIO_CLOCKIN => SIO_CLOCKIN,
		SIO_CLOCKOUT => SIO_CLOCKOUT,

		CONSOL_OPTION => CONSOL_OPTION,
		CONSOL_SELECT => CONSOL_SELECT,
		CONSOL_START=> CONSOL_START,
		GTIA_TRIG => GTIA_TRIG and not("000"&ps2_keys(16#127#)),
		
		ANTIC_LIGHTPEN => ANTIC_LIGHTPEN,

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

		RAM_SELECT => ram_select,
		CART_EMULATION_SELECT => emulated_cartridge_select,
		PAL => PAL,
		USE_SDRAM => SW(9),
		ROM_IN_RAM => '1',
		THROTTLE_COUNT_6502 => speed_6502,
		HALT => pause_atari,

		freezer_enable => freezer_enable,
		freezer_activate => freezer_activate,
		freezer_state_out => freezer_state,

		pbi_enable => pbi_enable
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
		ZPU_IN1 => X"000"&
			"00"&ps2_keys(16#76#)&ps2_keys(16#5A#)&ps2_keys(16#174#)&ps2_keys(16#16B#)&ps2_keys(16#172#)&ps2_keys(16#175#)& -- (esc)FLRDU
			FKEYS,
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
	emulated_cartridge_select <= zpu_out1(22 downto 17);

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
