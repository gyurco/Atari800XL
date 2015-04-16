---------------------------------------------------------------------------
-- (c) 2013-2015 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

LIBRARY work;

ENTITY atari800core_papilioduo IS 
	GENERIC
	(
		TV : integer;  -- 1 = PAL, 0=NTSC
		VIDEO : integer; -- 1 = RGB, 2 = VGA
		COMPOSITE_SYNC : integer; --0 = no, 1 = yes!
		SCANDOUBLE : integer; -- 1 = YES, 0=NO, (+ later scanlines etc)
		internal_rom : integer := 1 ;
		--internal_ram : integer := 16384;
		internal_ram : integer := 0;
		ext_clock : integer := 0
	);
	PORT
	(
		CLK_32 :  IN  STD_LOGIC; --32MHz - double check TODO

		-- For test bench
		EXT_CLK : in std_logic_vector(ext_clock downto 1);
                EXT_PLL_LOCKED : in std_logic_vector(ext_clock downto 1);

		--PS2_CLK2 :  IN  STD_LOGIC;
		--PS2_DAT2 :  IN  STD_LOGIC;
		PS2_CLK1 :  IN  STD_LOGIC;
		PS2_DAT1 :  IN  STD_LOGIC;
--NET PS2_DAT1      LOC="P120" | IOSTANDARD=LVTTL;                                # A4
--NET PS2_CLK1      LOC="P121" | IOSTANDARD=LVTTL;                                # A5

		VGA_VSYNC :  OUT  STD_LOGIC;
		VGA_HSYNC :  OUT  STD_LOGIC;
		VGA_BLUE :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_GREEN :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_RED :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0);
--NET VGA_HSYNC     LOC="P99"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # C0
--NET VGA_VSYNC     LOC="P97"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # C1
--NET VGA_BLUE(0)   LOC="P93"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # C2
--NET VGA_BLUE(1)   LOC="P83"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # C5
--NET VGA_BLUE(2)   LOC="P81"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # C6
--NET VGA_BLUE(3)   LOC="P79"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # C7
--NET VGA_GREEN(0)  LOC="P75"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # C8
--NET VGA_GREEN(1)  LOC="P67"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # C9
--NET VGA_GREEN(2)  LOC="P62"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # C10
--NET VGA_GREEN(3)  LOC="P59"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # C11
--NET VGA_RED(3)    LOC="P57"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # C12
--NET VGA_RED(2)    LOC="P55"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # C13
--NET VGA_RED(1)    LOC="P50"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # C14
--NET VGA_RED(0)    LOC="P47"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # C15
		
--		JOY1_n :  IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
		JOYSTICK1_1 : IN STD_LOGIC;
		JOYSTICK1_2 : IN STD_LOGIC;
		JOYSTICK1_3 : IN STD_LOGIC;
		JOYSTICK1_4 : IN STD_LOGIC;
		JOYSTICK1_5 : IN STD_LOGIC;
		JOYSTICK1_6 : IN STD_LOGIC;
		JOYSTICK1_7 : IN STD_LOGIC;
		JOYSTICK1_9 : IN STD_LOGIC;
--NET JOYSTICK1_5   LOC="P123" | IOSTANDARD=LVTTL;                                # A6
--NET JOYSTICK1_9   LOC="P124" | IOSTANDARD=LVTTL;                                # A7
--NET JOYSTICK1_4   LOC="P126" | IOSTANDARD=LVTTL;                                # A8
--NET JOYSTICK1_3   LOC="P127" | IOSTANDARD=LVTTL;                                # A9
--NET JOYSTICK1_7   LOC="P131" | IOSTANDARD=LVTTL;                                # A10
--NET JOYSTICK1_2   LOC="P132" | IOSTANDARD=LVTTL;                                # A11
--NET JOYSTICK1_6   LOC="P133" | IOSTANDARD=LVTTL;                                # A12
--NET JOYSTICK1_1   LOC="P134" | IOSTANDARD=LVTTL;                                # A13
--		JOY2_n :  IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
		JOYSTICK2_1 : IN STD_LOGIC;
		JOYSTICK2_2 : IN STD_LOGIC;
		JOYSTICK2_3 : IN STD_LOGIC;
		JOYSTICK2_4 : IN STD_LOGIC;
		JOYSTICK2_5 : IN STD_LOGIC;
		JOYSTICK2_6 : IN STD_LOGIC;
		JOYSTICK2_7 : IN STD_LOGIC;
		JOYSTICK2_9 : IN STD_LOGIC;
--NET JOYSTICK2_5   LOC="P98"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # D0
--NET JOYSTICK2_4   LOC="P95"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # D1
--NET JOYSTICK2_3   LOC="P92"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # D2
--NET JOYSTICK2_2   LOC="P87"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # D3
--NET JOYSTICK2_1   LOC="P84"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # D4
--NET JOYSTICK2_6   LOC="P82"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # D5
--NET JOYSTICK2_7   LOC="P80"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # D6
--NET JOYSTICK2_9   LOC="P78"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # D7
		
		AUDIO1_LEFT : OUT std_logic;
		AUDIO1_RIGHT : OUT std_logic;
--NET AUDIO1_LEFT   LOC="P88"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # C3
--NET AUDIO1_RIGHT  LOC="P85"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # C4

		SD_MISO :  IN  STD_LOGIC;
		SD_SCK :  OUT  STD_LOGIC;
		SD_MOSI :  OUT  STD_LOGIC;
		SD_nCS :  OUT  STD_LOGIC;
		SD_CD : IN STD_LOGIC; -- card detect

--NET SD_MISO       LOC="P118" | IOSTANDARD=LVTTL;                                # A2
--NET SD_CD         LOC="P119" | IOSTANDARD=LVTTL;                                # A3
--NET SD_MOSI       LOC="P115" | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # B0
--NET SD_SCK        LOC="P114" | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # B1
--NET SD_nCS        LOC="P112" | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # B2


		SRAM_DATA :  INOUT  STD_LOGIC_VECTOR(7 downto 0);
		SRAM_ADDR :  OUT  STD_LOGIC_VECTOR(20 downto 0);
		SRAM_CE :  OUT  STD_LOGIC;
		SRAM_WE :  OUT  STD_LOGIC;
		SRAM_OE :  OUT  STD_LOGIC;
--NET SRAM_DATA(0)  LOC="P14"  | IOSTANDARD=LVTTL;                                # SRAM_DATA0
--NET SRAM_DATA(1)  LOC="P15"  | IOSTANDARD=LVTTL;                                # SRAM_DATA1
--NET SRAM_DATA(2)  LOC="P16"  | IOSTANDARD=LVTTL;                                # SRAM_DATA2
--NET SRAM_DATA(3)  LOC="P17"  | IOSTANDARD=LVTTL;                                # SRAM_DATA3
--NET SRAM_DATA(4)  LOC="P21"  | IOSTANDARD=LVTTL;                                # SRAM_DATA4
--NET SRAM_DATA(5)  LOC="P22"  | IOSTANDARD=LVTTL;                                # SRAM_DATA5
--NET SRAM_DATA(6)  LOC="P23"  | IOSTANDARD=LVTTL;                                # SRAM_DATA6
--NET SRAM_DATA(7)  LOC="P24"  | IOSTANDARD=LVTTL;                                # SRAM_DATA7
--NET SRAM_ADDR(0)  LOC="P7"   | IOSTANDARD=LVTTL;                                # SRAM_ADDR0
--NET SRAM_ADDR(1)  LOC="P8"   | IOSTANDARD=LVTTL;                                # SRAM_ADDR1
--NET SRAM_ADDR(2)  LOC="P9"   | IOSTANDARD=LVTTL;                                # SRAM_ADDR2
--NET SRAM_ADDR(3)  LOC="P10"  | IOSTANDARD=LVTTL;                                # SRAM_ADDR3
--NET SRAM_ADDR(4)  LOC="P11"  | IOSTANDARD=LVTTL;                                # SRAM_ADDR4
--NET SRAM_ADDR(5)  LOC="P5"   | IOSTANDARD=LVTTL;                                # SRAM_ADDR5
--NET SRAM_ADDR(6)  LOC="P2"   | IOSTANDARD=LVTTL;                                # SRAM_ADDR6
--NET SRAM_ADDR(7)  LOC="P1"   | IOSTANDARD=LVTTL;                                # SRAM_ADDR7
--NET SRAM_ADDR(8)  LOC="P143" | IOSTANDARD=LVTTL;                                # SRAM_ADDR8
--NET SRAM_ADDR(9)  LOC="P142" | IOSTANDARD=LVTTL;                                # SRAM_ADDR9
--NET SRAM_ADDR(10) LOC="P43"  | IOSTANDARD=LVTTL;                                # SRAM_ADDR10
--NET SRAM_ADDR(11) LOC="P41"  | IOSTANDARD=LVTTL;                                # SRAM_ADDR11
--NET SRAM_ADDR(12) LOC="P40"  | IOSTANDARD=LVTTL;                                # SRAM_ADDR12
--NET SRAM_ADDR(13) LOC="P35"  | IOSTANDARD=LVTTL;                                # SRAM_ADDR13
--NET SRAM_ADDR(14) LOC="P34"  | IOSTANDARD=LVTTL;                                # SRAM_ADDR14
--NET SRAM_ADDR(15) LOC="P27"  | IOSTANDARD=LVTTL;                                # SRAM_ADDR15
--NET SRAM_ADDR(16) LOC="P29"  | IOSTANDARD=LVTTL;                                # SRAM_ADDR16
--NET SRAM_ADDR(17) LOC="P33"  | IOSTANDARD=LVTTL;                                # SRAM_ADDR17
--NET SRAM_ADDR(18) LOC="P32"  | IOSTANDARD=LVTTL;                                # SRAM_ADDR18
--NET SRAM_ADDR(19) LOC="P44"  | IOSTANDARD=LVTTL;                                # SRAM_ADDR19
--NET SRAM_ADDR(20) LOC="P30"  | IOSTANDARD=LVTTL;                                # SRAM_ADDR20
--NET SRAM_CE       LOC="P12"  | IOSTANDARD=LVTTL;                                # SRAM_CE
--NET SRAM_WE       LOC="P6"   | IOSTANDARD=LVTTL;                                # SRAM_WE
--NET SRAM_OE       LOC="P26"  | IOSTANDARD=LVTTL;                                # SRAM_OE


		ARDUINO_RESET :  OUT  STD_LOGIC;
		RESET :  IN  STD_LOGIC;
--NET RESET         LOC="P102" | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # B5
--NET ARDUINO_RESET LOC="P139" | IOSTANDARD=LVTTL;                                # ARDUINO_RESET


		--Some LEDS - use one for power(!), one for SIO, others for ???
		--Could use them to show sd card init, rom loaded or similar
		LED1 :  OUT  STD_LOGIC;
		LED2 :  OUT  STD_LOGIC;
		LED3 :  OUT  STD_LOGIC;
		LED4 :  OUT  STD_LOGIC
	
--NET LED1          LOC="P56"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # D12
--NET LED2          LOC="P51"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # D13
--NET LED3          LOC="P48"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # D14
--NET LED4          LOC="P39"  | IOSTANDARD=LVTTL | DRIVE=8 | SLEW=FAST;          # D15
	);
END atari800core_papilioduo;

ARCHITECTURE vhdl OF atari800core_papilioduo IS 

component hq_dac
port (
  reset :in std_logic;
  clk :in std_logic;
  clk_ena : in std_logic;
  pcm_in : in std_logic_vector(19 downto 0);
  dac_out : out std_logic
);
end component;

	signal AUDIO_L_PCM : std_logic_vector(15 downto 0);
	signal AUDIO_R_PCM : std_logic_vector(15 downto 0);

	signal AUDIO_OUT : std_logic;
	
	signal VIDEO_VS : std_logic;
	signal VIDEO_HS : std_logic;
	signal VIDEO_CS : std_logic;
	signal VIDEO_R : std_logic_vector(7 downto 0);
	signal VIDEO_G : std_logic_vector(7 downto 0);
	signal VIDEO_B : std_logic_vector(7 downto 0);

	signal VIDEO_BLANK : std_logic;
	signal VIDEO_BURST : std_logic;
	signal VIDEO_START_OF_FIELD : std_logic;
	signal VIDEO_ODD_LINE : std_logic;

	signal PAL : std_logic;
	
	signal JOY1_IN_n : std_logic_vector(4 downto 0);
	signal JOY2_IN_n : std_logic_vector(4 downto 0);

	signal PLL1_LOCKED : std_logic;
	signal CLK_PLL1 : std_logic;
	
	signal RESET_n : std_logic;
	signal PLL_LOCKED : std_logic;
	signal CLK : std_logic;
	signal CLK_SDRAM : std_logic;

	-- pokey keyboard
	SIGNAL KEYBOARD_SCAN : std_logic_vector(5 downto 0);
	SIGNAL KEYBOARD_RESPONSE : std_logic_vector(1 downto 0);
	
	-- gtia consol keys
	SIGNAL CONSOL_START : std_logic;
	SIGNAL CONSOL_SELECT : std_logic;
	SIGNAL CONSOL_OPTION : std_logic;
	SIGNAL FKEYS : std_logic_vector(11 downto 0);

	-- scandoubler
	signal half_scandouble_enable_reg : std_logic;
	signal half_scandouble_enable_next : std_logic;
	signal scanlines_reg : std_logic;
	signal scanlines_next : std_logic;
 	SIGNAL COMPOSITE_ON_HSYNC : std_logic;
 	SIGNAL VGA : std_logic;

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
	signal ZPU_OUT5 : std_logic_vector(31 downto 0);

	signal zpu_pokey_enable : std_logic;
	signal zpu_sio_txd : std_logic;
	signal zpu_sio_rxd : std_logic;
	signal zpu_sio_command : std_logic;

	-- system control from zpu
	signal ram_select : std_logic_vector(2 downto 0);
	signal reset_atari : std_logic;
	signal pause_atari : std_logic;
	SIGNAL speed_6502 : std_logic_vector(5 downto 0);
	signal emulated_cartridge_select: std_logic_vector(5 downto 0);

	-- turbo freezer!
	signal freezer_enable : std_logic;
	signal freezer_activate: std_logic;

	signal PS2_KEYS : STD_LOGIC_VECTOR(511 downto 0);
	signal PS2_KEYS_NEXT : STD_LOGIC_VECTOR(511 downto 0);

	-- sram
	signal ram_request : std_logic;
	signal ram_request_complete : std_logic;
	signal ram_read_enable : std_logic;
	signal ram_write_enable : std_logic;
	signal ram_addr : std_logic_vector(22 downto 0);
	signal ram_do : std_logic_vector(31 downto 0);
	signal ram_di : std_logic_vector(31 downto 0);
	signal ram_width32bit : std_logic;
BEGIN 

ARDUINO_RESET <= '1'; -- force arduino out of reset, when its reset some of our input pins are screwed up

LED1 <= '1';
LED2 <= not(zpu_sio_command);
LED3 <= not(zpu_sio_txd);
LED4 <= not(zpu_sio_rxd);

dac : hq_dac
port map
(
  reset => not(reset_n),
  clk => clk,
  clk_ena => '1',
  pcm_in => AUDIO_L_PCM&"0000",
  dac_out => audio_out
);

audio1_left <= audio_out;
audio1_right <= audio_out;

--u_DAC_L : entity work.dac
--port map (
--   CLK_I                      => CLK,
--   RES_N_I                    => RESET_N,
--   DAC_I                      => AUDIO_L_PCM,
--   DAC_O                      => AUDIO1_LEFT );
--
--u_DAC_R : entity work.dac
--port map (
--   CLK_I                      => CLK,
--   RES_N_I                    => RESET_N,
--   DAC_I                      => AUDIO_R_PCM,
--   DAC_O                      => AUDIO1_RIGHT );


gen_fake_pll : if ext_clock=1 generate
	CLK <= EXT_CLK(1);
	PLL_LOCKED <= EXT_PLL_LOCKED(1);
end generate;

--TODO xilinx version
gen_real_pll : if ext_clock=0 generate
--	gen_tv_pal : if tv=1 generate
--		papilioduo_pll : entity work.pal_pll
--		PORT MAP(inclk0 => FPGA_CLK,
--				 c0 => CLK_PLL1,
--				 locked => PLL1_LOCKED);
--		papilioduo_pll2 : entity work.pll_downstream_pal
--		PORT MAP(inclk0 => CLK_PLL1,
--				 c0 => CLK_SDRAM,
--				 c1 => CLK,
--				 c2 => SDRAM_CLK,
--				 c3 => SVIDEO_DAC_CLK,
--				 c4 => SCANDOUBLE_CLK,      
--				 areset => not(PLL1_LOCKED),
--				 locked => PLL_LOCKED);
--	end generate;
--
--	gen_tv_ntsc : if tv=0 generate
--		papilioduo_pll : entity work.ntsc_pll
--		PORT MAP(inclk0 => FPGA_CLK,
--				 c0 => CLK_PLL1,
--				 locked => PLL1_LOCKED);
--		papilioduo_pll2 : entity work.pll_downstream_ntsc
--		PORT MAP(inclk0 => CLK_PLL1,
--				 c0 => CLK_SDRAM,
--				 c1 => CLK,
--				 c2 => SDRAM_CLK,
--				 c3 => SVIDEO_DAC_CLK,
--				 c4 => SCANDOUBLE_CLK,      
--				 areset => not(PLL1_LOCKED),
--				 locked => PLL_LOCKED);
--	end generate;

	gen_tv_pal : if tv=1 generate
		pll : entity work.pll_pal
		port map (
		   CLK_IN1                      => CLK_32,
		   CLK_OUT1                     => CLK,
		   RESET                      => '0',
		   LOCKED                     => PLL_LOCKED );

	end generate;

	gen_tv_ntsc : if tv=0 generate
		pll : entity work.pll_ntsc
		port map (
		   CLK_IN1                      => CLK_32,
		   CLK_OUT1                     => CLK,
		   RESET                      => '0',
		   LOCKED                     => PLL_LOCKED );

	end generate;
end generate;

reset_n <= PLL_LOCKED;
JOY1_IN_N <= JOYSTICK1_6&JOYSTICK1_4&JOYSTICK1_3&JOYSTICK1_2&JOYSTICK1_1;
JOY2_IN_N <= JOYSTICK2_6&JOYSTICK2_4&JOYSTICK2_3&JOYSTICK2_2&JOYSTICK2_1;

--	JOY1_n : IN std_logic_vector(4 downto 0); -- FRLDU, 0=pressed


-- PS2 to pokey
keyboard_map1 : entity work.ps2_to_atari800
	GENERIC MAP
	(
		ps2_enable => 1,
		direct_enable => 1
	)
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,
		PS2_CLK => PS2_CLK1,
		PS2_DAT => PS2_DAT1,

		INPUT => zpu_out4,
		
		KEYBOARD_SCAN => KEYBOARD_SCAN,
		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,

		CONSOL_START => CONSOL_START,
		CONSOL_SELECT => CONSOL_SELECT,
		CONSOL_OPTION => CONSOL_OPTION,
		
		FKEYS => FKEYS,
		FREEZER_ACTIVATE => freezer_activate,

		PS2_KEYS_NEXT_OUT => ps2_keys_next,
		PS2_KEYS => ps2_keys
	);

PAL <= '1' when TV=1 else '0';

atarixl_simple_sdram1 : entity work.atari800core_simple_sdram
	GENERIC MAP
	(
		cycle_length => 32,
		internal_rom => internal_rom,
		internal_ram => internal_ram,
		video_bits => 8,
		palette => 0,
		low_memory => 2,
                STEREO                     => 0,
                COVOX                      => 0
	)
	PORT MAP
	(
		CLK => CLK,
		--RESET_N => RESET_N and SDRAM_RESET_N and not(SYSTEM_RESET_REQUEST),
		RESET_N => RESET_N and not(RESET_ATARI),

		VIDEO_VS => VIDEO_VS,
		VIDEO_HS => VIDEO_HS,
		VIDEO_CS => VIDEO_CS,
		VIDEO_B => VIDEO_B,
		VIDEO_G => VIDEO_G,
		VIDEO_R => VIDEO_R,
		VIDEO_BLANK =>VIDEO_BLANK,
		VIDEO_BURST =>VIDEO_BURST,
		VIDEO_START_OF_FIELD =>VIDEO_START_OF_FIELD,
		VIDEO_ODD_LINE =>VIDEO_ODD_LINE,

		AUDIO_L => AUDIO_L_PCM,
		AUDIO_R => AUDIO_R_PCM,

		JOY1_n => JOY1_IN_n,
		JOY2_n => JOY2_IN_n,

		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,
		KEYBOARD_SCAN => KEYBOARD_SCAN,

		SIO_COMMAND => zpu_sio_command,
		SIO_RXD => zpu_sio_txd,
		SIO_TXD => zpu_sio_rxd,

		CONSOL_OPTION => CONSOL_OPTION,
		CONSOL_SELECT => CONSOL_SELECT,
		CONSOL_START => CONSOL_START,

-- TODO, connect to SRAM! Handle 32-bit in multiple cycles. How fast is the sram.
		SDRAM_REQUEST => ram_request,
		SDRAM_REQUEST_COMPLETE => ram_request_complete,
		SDRAM_READ_ENABLE => ram_read_enable,
		SDRAM_WRITE_ENABLE => ram_write_enable,
		SDRAM_ADDR => ram_addr,
		SDRAM_DO => ram_do,
		SDRAM_DI => ram_di,
		SDRAM_32BIT_WRITE_ENABLE => ram_width32bit,
		SDRAM_16BIT_WRITE_ENABLE => open,
		SDRAM_8BIT_WRITE_ENABLE => open,
		SDRAM_REFRESH => open,

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
		emulated_cartridge_select => emulated_cartridge_select,
--		freezer_enable => freezer_enable,
--		freezer_activate => freezer_activate

--   		RAM_SELECT => (others=>'0'),
--		PAL => PAL,
--		HALT => '0',
--		THROTTLE_COUNT_6502 => "000001",
--		emulated_cartridge_select => (others=>'0'),
		freezer_enable => '0',
		freezer_activate => '0'
	);

-- Video options
	pal <= '1' when tv=1 else '0';
	vga <= '1' when video=2 else '0';
	composite_on_hsync <= '1' when composite_sync=1 else '0';

	process(clk,RESET_N,reset_atari)
	begin
		if ((RESET_N and not(reset_atari))='0') then
			half_scandouble_enable_reg <= '0';
			scanlines_reg <= '0';
		elsif (clk'event and clk='1') then
			half_scandouble_enable_reg <= half_scandouble_enable_next;
			scanlines_reg <= scanlines_next;
		end if;
	end process;

	half_scandouble_enable_next <= not(half_scandouble_enable_reg);
	scanlines_next <= scanlines_reg xor (not(ps2_keys(16#11#)) and ps2_keys_next(16#11#)); -- left alt

	scandoubler1: entity work.scandoubler
	PORT MAP
	( 
		CLK => CLK,
	        RESET_N => reset_n,
		
		VGA => vga,
		COMPOSITE_ON_HSYNC => composite_on_hsync,

		colour_enable => half_scandouble_enable_reg,
		doubled_enable => '1',
		scanlines_on => scanlines_reg,
		
		-- GTIA interface
		pal => PAL,
		colour_in => VIDEO_B,
		vsync_in => VIDEO_VS,
		hsync_in => VIDEO_HS,
		csync_in => VIDEO_CS,
		
		-- TO TV...
		R => VGA_RED,
		G => VGA_GREEN,
		B => VGA_BLUE,
		
		VSYNC => VGA_VSYNC,
		HSYNC => VGA_HSYNC
	);

zpu: entity work.zpucore
	GENERIC MAP
	(
		platform => 1,
		spi_clock_div => 2, -- 28MHz/2. Max for SD cards is 25MHz...
		usb => 0
	)
	PORT MAP
	(
		-- standard...
		CLK => CLK,
		RESET_N => RESET_N,

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
		ZPU_SD_DAT0 => SD_MISO,
		ZPU_SD_CLK => SD_SCK,
		ZPU_SD_CMD => SD_MOSI,
		ZPU_SD_DAT3 => SD_nCS,

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
		ZPU_OUT2 => zpu_out2, --joy0
		ZPU_OUT3 => zpu_out3, --joy1
		ZPU_OUT4 => zpu_out4, --keyboard
		ZPU_OUT5 => zpu_out5  --analog stick (not supported without USB)
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


ram : entity work.sram
	PORT MAP
	( 
		ADDRESS => ram_addr(20 downto 0),
		DIN => ram_di,
		WREN => ram_write_enable,
		
		clk => clk,
		reset_n => reset_n,
		
		request => ram_request,

		width32bit => ram_width32bit,
		
		-- SRAM interface
		SRAM_ADDR => sram_addr,
		SRAM_CE_N => sram_ce,
		SRAM_OE_N => sram_oe,
		SRAM_WE_N => sram_we,
	
		SRAM_DQ => sram_data,
		
		-- Provide data to system
		DOUT => ram_do,
		complete => ram_request_complete
	);

END vhdl;
