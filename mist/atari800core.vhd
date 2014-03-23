-- Copyright (C) 1991-2012 Altera Corporation
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, Altera MegaCore Function License 
-- Agreement, or other applicable license agreement, including, 
-- without limitation, that your use is for the sole purpose of 
-- programming logic devices manufactured by Altera and sold by 
-- Altera or its authorized distributors.  Please refer to the 
-- applicable agreement for further details.

-- PROGRAM		"Quartus II 64-Bit"
-- VERSION		"Version 12.1 Build 243 01/31/2013 Service Pack 1.33 SJ Web Edition"
-- CREATED		"Tue Dec 31 22:21:48 2013"

LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

LIBRARY work;

ENTITY atari800core IS 
	PORT
	(
		CLOCK_27 :  IN  STD_LOGIC_VECTOR(1 downto 0);
--		PS2K_CLK :  IN  STD_LOGIC;
--		PS2K_DAT :  IN  STD_LOGIC;
--		PS2M_CLK :  IN  STD_LOGIC;
--		PS2M_DAT :  IN  STD_LOGIC;		

		VGA_VS :  OUT  STD_LOGIC;
		VGA_HS :  OUT  STD_LOGIC;
		VGA_B :  OUT  STD_LOGIC_VECTOR(5 DOWNTO 0);
		VGA_G :  OUT  STD_LOGIC_VECTOR(5 DOWNTO 0);
		VGA_R :  OUT  STD_LOGIC_VECTOR(5 DOWNTO 0);
		
--		JOY1_n :  IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
--		JOY2_n :  IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
		
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

--		SD_DAT0 :  IN  STD_LOGIC;
--		SD_CLK :  OUT  STD_LOGIC;
--		SD_CMD :  OUT  STD_LOGIC;
--		SD_DAT3 :  OUT  STD_LOGIC

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
END atari800core;

ARCHITECTURE bdf_type OF atari800core IS 
--
--component generic_ram_infer IS
--	generic
--	(
--		ADDRESS_WIDTH : natural := 9;
--		SPACE : natural := 512;
--		DATA_WIDTH : natural := 8
--	);
--   PORT
--   (
--      clock: IN   std_logic;
--      data:  IN   std_logic_vector (data_width-1 DOWNTO 0);
--      address:  IN   std_logic_vector(address_width-1 downto 0);
--      we:    IN   std_logic;
--      q:     OUT  std_logic_vector (data_width-1 DOWNTO 0)
--   );
--END component;

component mist_sector_buffer IS
	PORT
	(
		address_a		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		address_b		: IN STD_LOGIC_VECTOR (6 DOWNTO 0);
		clock_a		: IN STD_LOGIC  := '1';
		clock_b		: IN STD_LOGIC ;
		data_a		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		data_b		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		wren_a		: IN STD_LOGIC  := '0';
		wren_b		: IN STD_LOGIC  := '0';
		q_a		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		q_b		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END component;

component synchronizer IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RAW : IN STD_LOGIC;
	SYNC : OUT STD_LOGIC
);
END component;

component data_io IS 
	PORT
	(
		CLK : in std_logic;
		RESET_n : in std_logic;
		
		-- SPI connection - up to upstream to make miso 'Z' on ss_io going high
	   SPI_CLK : in std_logic;
	   SPI_SS_IO : in std_logic;
	   SPI_MISO: out std_logic;
	   SPI_MOSI : in std_logic;
		
		-- Sector access request
		request : in std_logic;
		sector : in std_logic_vector(23 downto 0);
		ready : out std_logic;
		
		-- DMA to RAM
		ADDR: out std_logic_vector(8 downto 0);
		DATA_OUT : out std_logic_vector(7 downto 0);
		DATA_IN : in std_logic_vector(7 downto 0);
		WR_EN : out std_logic
	 );
end component;

component user_io
	PORT(
	   SPI_CLK : in std_logic;
	   SPI_SS_IO : in std_logic;
	   SPI_MISO : out std_logic;
	   SPI_MOSI : in std_logic;
	   CORE_TYPE : in std_logic_vector(7 downto 0);
		JOY0 : out std_logic_vector(5 downto 0);
		JOY1 : out std_logic_vector(5 downto 0);
		KEYBOARD : out std_logic_vector(127 downto 0);
		BUTTONS : out std_logic_vector(1 downto 0);
		SWITCHES : out std_logic_vector(1 downto 0)
	  );
end component;

COMPONENT complete_address_decoder IS
generic (width : natural := 1);
PORT 
( 
	addr_in : in std_logic_vector(width-1 downto 0);			
	addr_decoded : out std_logic_vector((2**width)-1 downto 0)
);
END component;

COMPONENT cpu
	PORT(CLK : IN STD_LOGIC;
		 RESET : IN STD_LOGIC;
		 ENABLE : IN STD_LOGIC;
		 IRQ_n : IN STD_LOGIC;
		 NMI_n : IN STD_LOGIC;
		 MEMORY_READY : IN STD_LOGIC;
		 THROTTLE : IN STD_LOGIC;
		 RDY : IN STD_LOGIC;
		 DI : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 R_W_n : OUT STD_LOGIC;
		 CPU_FETCH : OUT STD_LOGIC;
		 A : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		 DO : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END COMPONENT;

component hq_dac
port (
  reset :in std_logic;
  clk :in std_logic;
  clk_ena : in std_logic;
  pcm_in : in std_logic_vector(19 downto 0);
  dac_out : out std_logic
);
end component;

component internalromram IS
  PORT(
    clock   : IN     STD_LOGIC;                             --system clock
    reset_n : IN     STD_LOGIC;                             --asynchronous reset

	ROM_ADDR : in STD_LOGIC_VECTOR(21 downto 0);
	ROM_REQUEST_COMPLETE : out STD_LOGIC;
	ROM_REQUEST : in std_logic;
	ROM_DATA : out std_logic_vector(7 downto 0);
	
	RAM_ADDR : in STD_LOGIC_VECTOR(18 downto 0);
	RAM_WR_ENABLE : in std_logic;
	RAM_DATA_IN : in STD_LOGIC_VECTOR(7 downto 0);
	RAM_REQUEST_COMPLETE : out STD_LOGIC;
	RAM_REQUEST : in std_logic;
	RAM_DATA : out std_logic_vector(7 downto 0)
	);
	
END component;

COMPONENT antic
	PORT(CLK : IN STD_LOGIC;
		 WR_EN : IN STD_LOGIC;
		 RESET_N : IN STD_LOGIC;
		 MEMORY_READY_ANTIC : IN STD_LOGIC;
		 MEMORY_READY_CPU : IN STD_LOGIC;
		 ANTIC_ENABLE_179 : IN STD_LOGIC;
		 PAL : IN STD_LOGIC;
		 lightpen : IN STD_LOGIC;
		 ADDR : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 CPU_DATA_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 MEMORY_DATA_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 NMI_N_OUT : OUT STD_LOGIC;
		 ANTIC_READY : OUT STD_LOGIC;
		 COLOUR_CLOCK_ORIGINAL_OUT : OUT STD_LOGIC;
		 COLOUR_CLOCK_OUT : OUT STD_LOGIC;
		 HIGHRES_COLOUR_CLOCK_OUT : OUT STD_LOGIC;
		 dma_fetch_out : OUT STD_LOGIC;
		 refresh_out : OUT STD_LOGIC;
		 dma_clock_out : OUT STD_LOGIC;
		 AN : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		 DATA_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 dma_address_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END COMPONENT;

COMPONENT ledsw
	PORT(CLK : IN STD_LOGIC;
		 KEY : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 SW : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
		 SYNC_KEYS : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		 SYNC_SWITCHES : OUT STD_LOGIC_VECTOR(9 DOWNTO 0)
	);
END COMPONENT;

COMPONENT pokey_mixer
	PORT(CLK : IN STD_LOGIC;
		 GTIA_SOUND : IN STD_LOGIC;
		 CHANNEL_0 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 CHANNEL_1 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 CHANNEL_2 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 CHANNEL_3 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 COVOX_CHANNEL_0 : IN STD_LOGIC_VECTOR(7 downto 0);
		 COVOX_CHANNEL_1 : IN STD_LOGIC_VECTOR(7 downto 0);
		 CHANNEL_ENABLE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 VOLUME_OUT : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END COMPONENT;

COMPONENT ps2_keyboard
	PORT(CLK : IN STD_LOGIC;
		 RESET_N : IN STD_LOGIC;
		 PS2_CLK : IN STD_LOGIC;
		 PS2_DAT : IN STD_LOGIC;
		 KEY_EVENT : OUT STD_LOGIC;
		 KEY_EXTENDED : OUT STD_LOGIC;
		 KEY_UP : OUT STD_LOGIC;
		 KEY_VALUE : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END COMPONENT;

COMPONENT zpu_glue
	PORT(CLK : IN STD_LOGIC;
		 RESET : IN STD_LOGIC;
		 PAUSE : IN STD_LOGIC;
		 MEMORY_READY : IN STD_LOGIC;
		 ZPU_CONFIG_DI : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 ZPU_DI : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 ZPU_RAM_DI : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 ZPU_ROM_DI : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 ZPU_SECTOR_DI : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 MEMORY_FETCH : OUT STD_LOGIC;
		 ZPU_READ_ENABLE : OUT STD_LOGIC;
		 ZPU_32BIT_WRITE_ENABLE : OUT STD_LOGIC;
		 ZPU_16BIT_WRITE_ENABLE : OUT STD_LOGIC;
		 ZPU_8BIT_WRITE_ENABLE : OUT STD_LOGIC;
		 ZPU_CONFIG_WRITE : OUT STD_LOGIC;
		 ZPU_ADDR_FETCH : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
		 ZPU_ADDR_ROM_RAM : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
		 ZPU_DO : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		 ZPU_STACK_WRITE : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
	);
END COMPONENT;

COMPONENT pokey
	PORT(CLK : IN STD_LOGIC;
		 CPU_MEMORY_READY : IN STD_LOGIC;
		 ANTIC_MEMORY_READY : IN STD_LOGIC;
		 WR_EN : IN STD_LOGIC;
		 RESET_N : IN STD_LOGIC;
		 SIO_IN1 : IN STD_LOGIC;
		 SIO_IN2 : IN STD_LOGIC;
		 SIO_IN3 : IN STD_LOGIC;
		 SIO_CLOCK : INOUT STD_LOGIC;
		 ADDR : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 DATA_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 keyboard_response : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		 POT_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 IRQ_N_OUT : OUT STD_LOGIC;
		 SIO_OUT1 : OUT STD_LOGIC;
		 SIO_OUT2 : OUT STD_LOGIC;
		 SIO_OUT3 : OUT STD_LOGIC;
		 POT_RESET : OUT STD_LOGIC;
		 CHANNEL_0_OUT : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		 CHANNEL_1_OUT : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		 CHANNEL_2_OUT : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		 CHANNEL_3_OUT : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		 DATA_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 keyboard_scan : OUT STD_LOGIC_VECTOR(5 DOWNTO 0)
	);
END COMPONENT;

COMPONENT pia
	PORT(	CLK : IN STD_LOGIC;
	ADDR : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
	CPU_DATA_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
	EN : IN STD_LOGIC;
	WR_EN : IN STD_LOGIC;
	
	RESET_N : IN STD_LOGIC;
	
	CA1 : IN STD_LOGIC;
	CB1 : IN STD_LOGIC;		
	
	CA2_DIR_OUT : OUT std_logic;
	CA2_OUT : OUT std_logic;
	CA2_IN : IN STD_LOGIC;

	CB2_DIR_OUT : OUT std_logic;
	CB2_OUT : OUT std_logic;
	CB2_IN : IN STD_LOGIC;
	
	-- remember these two are different if connecting to gpio (push pull vs pull up - check 6520 data sheet...)
	-- pull up - i.e. 0 driven only
	PORTA_DIR_OUT : OUT STD_LOGIC_VECTOR(7 downto 0); -- set bit to 1 to enable output mode
	PORTA_OUT : OUT STD_LOGIC_VECTOR(7 downto 0); 
	PORTA_IN : IN STD_LOGIC_VECTOR(7 downto 0);
	
	PORTB_DIR_OUT : OUT STD_LOGIC_VECTOR(7 downto 0);
	PORTB_OUT : OUT STD_LOGIC_VECTOR(7 downto 0); -- push pull
	PORTB_IN : IN STD_LOGIC_VECTOR(7 downto 0); -- push pull
	
	-- CPU interface
	DATA_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		
	IRQA_N : OUT STD_LOGIC;
	IRQB_N : OUT STD_LOGIC	);
END COMPONENT;

COMPONENT shared_enable
	PORT(CLK : IN STD_LOGIC;
		 RESET_N : IN STD_LOGIC;
		 MEMORY_READY_CPU : IN STD_LOGIC;
		 MEMORY_READY_ANTIC : IN STD_LOGIC;
		 PAUSE_6502 : IN STD_LOGIC;
		 THROTTLE_COUNT_6502 : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		 POKEY_ENABLE_179 : OUT STD_LOGIC;
		 ANTIC_ENABLE_179 : OUT STD_LOGIC;
		 oldcpu_enable : OUT STD_LOGIC;
		 CPU_ENABLE_OUT : OUT STD_LOGIC;
		 SCANDOUBLER_ENABLE_LOW : OUT STD_LOGIC;
		 SCANDOUBLER_ENABLE_HIGH : OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT pokey_ps2_decoder
	PORT(CLK : IN STD_LOGIC;
		 RESET_N : IN STD_LOGIC;
		 KEY_EVENT : IN STD_LOGIC;
		 KEY_EXTENDED : IN STD_LOGIC;
		 KEY_UP : IN STD_LOGIC;
		 KEY_CODE : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 KEY_HELD : OUT STD_LOGIC;
		 SHIFT_PRESSED : OUT STD_LOGIC;
		 BREAK_PRESSED : OUT STD_LOGIC;
		 KEY_INTERRUPT : OUT STD_LOGIC;
		 CONSOL_START : OUT STD_LOGIC;
		 CONSOL_SELECT : OUT STD_LOGIC;
		 CONSOL_OPTION : OUT STD_LOGIC;
		 SYSTEM_RESET : OUT STD_LOGIC;
		 KBCODE : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 VIRTUAL_STICKS : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 VIRTUAL_TRIGGER : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		 VIRTUAL_KEYS : out std_logic_vector(3 downto 0)
	);
END COMPONENT;


COMPONENT address_decoder
	PORT(CLK : IN STD_LOGIC;
		 CPU_FETCH : IN STD_LOGIC;
		 CPU_WRITE_N : IN STD_LOGIC;
		 ANTIC_FETCH : IN STD_LOGIC;
		 antic_refresh : IN STD_LOGIC;
		 ZPU_FETCH : IN STD_LOGIC;
		 ZPU_READ_ENABLE : IN STD_LOGIC;
		 ZPU_32BIT_WRITE_ENABLE : IN STD_LOGIC;
		 ZPU_16BIT_WRITE_ENABLE : IN STD_LOGIC;
		 ZPU_8BIT_WRITE_ENABLE : IN STD_LOGIC;
		 RAM_REQUEST_COMPLETE : IN STD_LOGIC;
		 ROM_REQUEST_COMPLETE : IN STD_LOGIC;
		 CART_REQUEST_COMPLETE : IN STD_LOGIC;
		 reset_n : IN STD_LOGIC;
		 CART_RD4 : IN STD_LOGIC;
		 CART_RD5 : IN STD_LOGIC;
		 use_sdram : IN STD_LOGIC;
		 SDRAM_REQUEST_COMPLETE : IN STD_LOGIC;
		 ANTIC_ADDR : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		 ANTIC_DATA : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 CACHE_ANTIC_DATA : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 CART_ROM_DATA : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 CPU_ADDR : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		 CPU_WRITE_DATA : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 GTIA_DATA : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 CACHE_GTIA_DATA : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 PIA_DATA : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 POKEY2_DATA : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 CACHE_POKEY2_DATA : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 POKEY_DATA : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 CACHE_POKEY_DATA : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 PORTB : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 RAM_DATA : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		 ram_select : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
		 ROM_DATA : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 rom_select : in std_logic_vector(5 downto 0);
		 cart_select : in std_logic_vector(6 downto 0);
		 cart_activate : in std_logic;
		 SDRAM_DATA : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 ZPU_ADDR : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
		 ZPU_WRITE_DATA : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 MEMORY_READY_ANTIC : OUT STD_LOGIC;
		 MEMORY_READY_ZPU : OUT STD_LOGIC;
		 MEMORY_READY_CPU : OUT STD_LOGIC;
		 GTIA_WR_ENABLE : OUT STD_LOGIC;
		 POKEY_WR_ENABLE : OUT STD_LOGIC;
		 POKEY2_WR_ENABLE : OUT STD_LOGIC;
		 ANTIC_WR_ENABLE : OUT STD_LOGIC;
		 PIA_WR_ENABLE : OUT STD_LOGIC;
		 PIA_RD_ENABLE : OUT STD_LOGIC;
		 RAM_WR_ENABLE : OUT STD_LOGIC;
		 PBI_WR_ENABLE : OUT STD_LOGIC;
		 RAM_REQUEST : OUT STD_LOGIC;
		 ROM_REQUEST : OUT STD_LOGIC;
		 CART_REQUEST : OUT STD_LOGIC;
		 CART_S4_n : OUT STD_LOGIC;
		 CART_S5_n : OUT STD_LOGIC;
		 CART_CCTL_n : OUT STD_LOGIC;
		 WIDTH_8bit_ACCESS : OUT STD_LOGIC;
		 WIDTH_16bit_ACCESS : OUT STD_LOGIC;
		 WIDTH_32bit_ACCESS : OUT STD_LOGIC;
		 SDRAM_READ_EN : OUT STD_LOGIC;
		 SDRAM_WRITE_EN : OUT STD_LOGIC;
		 SDRAM_REQUEST : OUT STD_LOGIC;
		 SDRAM_REFRESH : OUT STD_LOGIC;
		 MEMORY_DATA : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		 PBI_ADDR : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		 RAM_ADDR : OUT STD_LOGIC_VECTOR(18 DOWNTO 0);
		 ROM_ADDR : OUT STD_LOGIC_VECTOR(21 DOWNTO 0);
		 SDRAM_ADDR : OUT STD_LOGIC_VECTOR(22 DOWNTO 0);
		 WRITE_DATA : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		 D6_WR_ENABLE : out std_logic
	);
END COMPONENT;

COMPONENT sdram_statemachine
GENERIC (ADDRESS_WIDTH : INTEGER;
			AP_BIT : INTEGER;
			COLUMN_WIDTH : INTEGER;
			ROW_WIDTH : INTEGER
			);
	PORT(CLK_SYSTEM : IN STD_LOGIC;
		 CLK_SDRAM : IN STD_LOGIC;
		 RESET_N : IN STD_LOGIC;
		 READ_EN : IN STD_LOGIC;
		 WRITE_EN : IN STD_LOGIC;
		 REQUEST : IN STD_LOGIC;
		 BYTE_ACCESS : IN STD_LOGIC;
		 WORD_ACCESS : IN STD_LOGIC;
		 LONGWORD_ACCESS : IN STD_LOGIC;
		 REFRESH : IN STD_LOGIC;
		 ADDRESS_IN : IN STD_LOGIC_VECTOR(22 DOWNTO 0);
		 DATA_IN : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 SDRAM_DQ : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		 COMPLETE : OUT STD_LOGIC;
		 SDRAM_BA0 : OUT STD_LOGIC;
		 SDRAM_BA1 : OUT STD_LOGIC;
		 SDRAM_CKE : OUT STD_LOGIC;
		 SDRAM_CS_N : OUT STD_LOGIC;
		 SDRAM_RAS_N : OUT STD_LOGIC;
		 SDRAM_CAS_N : OUT STD_LOGIC;
		 SDRAM_WE_N : OUT STD_LOGIC;
		 SDRAM_ldqm : OUT STD_LOGIC;
		 SDRAM_udqm : OUT STD_LOGIC;
		 DATA_OUT : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		 SDRAM_ADDR : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
	);
END COMPONENT;

component sdram_statemachine_mcc IS
generic
(
	ADDRESS_WIDTH : natural := 22;
	ROW_WIDTH : natural := 12;
	AP_BIT : natural := 10;
	COLUMN_WIDTH : natural := 8
);
PORT 
( 
	CLK_SYSTEM : IN STD_LOGIC;
	CLK_SDRAM : IN STD_LOGIC; -- this is a exact multiple of system clock
	RESET_N : in STD_LOGIC;
	
	-- interface as though SRAM - this module can take care of caching/write combining etc etc. For first cut... nothing. TODO: What extra info would help me here?
	DATA_IN : in std_logic_vector(31 downto 0);
	ADDRESS_IN : in std_logic_vector(ADDRESS_WIDTH downto 0); -- 1 extra bit for byte alignment
	READ_EN : in std_logic; -- if no reads pending may be a good time to do a refresh
	WRITE_EN : in std_logic;
	REQUEST : in std_logic; -- Toggle this to issue a new request
	BYTE_ACCESS : in std_logic; -- ldqm/udqm set based on a(0) - if 0=0111, if 1=1011. Data fields valid:7 downto 0.
	WORD_ACCESS : in std_logic; -- ldqm/udqm set based on a(0) - if 0=0011, if 1=1001. Data fields valid:15 downto 0.
	LONGWORD_ACCESS : in std_logic; -- a(0) ignored. lqdm/udqm mask is 0000
	REFRESH : in std_logic;

	REPLY : out std_logic; -- This matches the request once complete
	DATA_OUT : out std_logic_vector(31 downto 0);

	-- sdram itself
	SDRAM_ADDR : out std_logic_vector(ROW_WIDTH downto 0);
	SDRAM_DQ : inout std_logic_vector(15 downto 0);
	SDRAM_BA0 : out std_logic;
	SDRAM_BA1 : out std_logic;
	
	SDRAM_CS_N : out std_logic;
	SDRAM_RAS_N : out std_logic;
	SDRAM_CAS_N : out std_logic;
	SDRAM_WE_N : out std_logic;
	
	SDRAM_ldqm : out std_logic; -- low enable, high disable - for byte addressing - NB, cas latency applies to reads
	SDRAM_udqm : out std_logic
);
END component;

COMPONENT zpu_rom
	PORT(clock : IN STD_LOGIC;
		 address : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		 q : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END COMPONENT;

COMPONENT scandoubler
	PORT(CLK : IN STD_LOGIC;
		 RESET_N : IN STD_LOGIC;
		 VGA : IN STD_LOGIC;
		 COMPOSITE_ON_HSYNC : IN STD_LOGIC;
		 colour_enable : IN STD_LOGIC;
		 doubled_enable : IN STD_LOGIC;
		 vsync_in : IN STD_LOGIC;
		 hsync_in : IN STD_LOGIC;
		 colour_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 VSYNC : OUT STD_LOGIC;
		 HSYNC : OUT STD_LOGIC;
		 B : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		 G : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		 R : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
	);
END COMPONENT;

COMPONENT zpu_ram
	PORT(wren : IN STD_LOGIC;
		 clock : IN STD_LOGIC;
		 address : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
		 data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 q : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END COMPONENT;

COMPONENT zpu_config_regs
	PORT(CLK : IN STD_LOGIC;
		 ENABLE_179 : IN STD_LOGIC;
		 WR_EN : IN STD_LOGIC;
		 SDCARD_DAT : IN STD_LOGIC;
		 SIO_COMMAND_OUT : IN STD_LOGIC;
		 SIO_DATA_OUT : IN STD_LOGIC;
		 PLL_LOCKED : IN STD_LOGIC;
		 REQUEST_RESET_ZPU : IN STD_LOGIC;
		 ADDR : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
		 CPU_DATA_IN : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 KEY : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 SWITCH : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
		 SDCARD_CLK : OUT STD_LOGIC;
		 SDCARD_CMD : OUT STD_LOGIC;
		 SDCARD_DAT3 : OUT STD_LOGIC;
		 SIO_DATA_IN : OUT STD_LOGIC;
		 PAUSE_ZPU : OUT STD_LOGIC;
		 PAL : OUT STD_LOGIC;
		 USE_SDRAM : OUT STD_LOGIC;
		 VGA : OUT STD_LOGIC;
		 COMPOSITE_ON_HSYNC : OUT STD_LOGIC;
		 GPIO_ENABLE : OUT STD_LOGIC;
		 RESET_6502 : OUT STD_LOGIC;
		 RESET_ZPU : OUT STD_LOGIC;
		 RESET_N : OUT STD_LOGIC;
		 PAUSE_6502 : OUT STD_LOGIC;
		 DATA_OUT : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		 LEDG : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 LEDR : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
		 RAM_SELECT : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		 ROM_SELECT : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		 THROTTLE_COUNT_6502 : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
		 ZPU_HEX : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		 sector : out std_logic_vector(31 downto 0);
		 sector_request : out std_logic;
		 sector_ready : in std_logic
	);
END COMPONENT;

COMPONENT pll
	PORT(inclk0 : IN STD_LOGIC;
		 c0 : OUT STD_LOGIC;
		 c1 : OUT STD_LOGIC;
		 c2 : OUT STD_LOGIC;
		 locked : OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT gtia
	PORT(CLK : IN STD_LOGIC;
		 WR_EN : IN STD_LOGIC;
		 CPU_MEMORY_READY : IN STD_LOGIC;
		 ANTIC_MEMORY_READY : IN STD_LOGIC;
		 ANTIC_FETCH : IN STD_LOGIC;
		 CPU_ENABLE_ORIGINAL : IN STD_LOGIC;
		 RESET_N : IN STD_LOGIC;
		 PAL : IN STD_LOGIC;
		 COLOUR_CLOCK_ORIGINAL : IN STD_LOGIC;
		 COLOUR_CLOCK : IN STD_LOGIC;
		 COLOUR_CLOCK_HIGHRES : IN STD_LOGIC;
		 CONSOL_START : IN STD_LOGIC;
		 CONSOL_SELECT : IN STD_LOGIC;
		 CONSOL_OPTION : IN STD_LOGIC;
		 TRIG0 : IN STD_LOGIC;
		 TRIG1 : IN STD_LOGIC;
		 TRIG2 : IN STD_LOGIC;
		 TRIG3 : IN STD_LOGIC;
		 ADDR : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
		 AN : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
		 CPU_DATA_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 MEMORY_DATA_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 VSYNC : OUT STD_LOGIC;
		 HSYNC : OUT STD_LOGIC;
		 sound : OUT STD_LOGIC;
		 COLOUR_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 DATA_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END COMPONENT;

COMPONENT irq_glue
	PORT(pokey_irq : IN STD_LOGIC;
		 pia_irqa : IN STD_LOGIC;
		 pia_irqb : IN STD_LOGIC;
		 combined_irq : OUT STD_LOGIC
	);
END COMPONENT;

component reg_file IS
generic
(
	BYTES : natural := 1;
	WIDTH : natural := 1
);
PORT 
( 
	CLK : IN STD_LOGIC;
	ADDR : IN STD_LOGIC_VECTOR(width-1 DOWNTO 0);
	DATA_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
	WR_EN : IN STD_LOGIC;
	
	DATA_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
);
END component;

component covox IS
PORT 
( 
	CLK : IN STD_LOGIC;
	ADDR : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
	DATA_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
	WR_EN : IN STD_LOGIC;
	
	covox_channel0 : out std_logic_vector(7 downto 0);
	covox_channel1 : out std_logic_vector(7 downto 0);
	covox_channel2 : out std_logic_vector(7 downto 0);
	covox_channel3 : out std_logic_vector(7 downto 0)
);
END component;

SIGNAL	ANTIC_ADDR :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	ANTIC_AN :  STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL	ANTIC_COLOUR_CLOCK_OUT :  STD_LOGIC;
SIGNAL	ANTIC_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	CACHE_ANTIC_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	ANTIC_ENABLE_179 :  STD_LOGIC;
SIGNAL	ANTIC_FETCH :  STD_LOGIC;
SIGNAL	ANTIC_HIGHRES_COLOUR_CLOCK_OUT :  STD_LOGIC;
SIGNAL	ANTIC_ORIGINAL_COLOUR_CLOCK_OUT :  STD_LOGIC;
SIGNAL	ANTIC_RDY :  STD_LOGIC;
SIGNAL	ANTIC_REFRESH :  STD_LOGIC;
SIGNAL	ANTIC_WRITE_ENABLE :  STD_LOGIC;
SIGNAL	AUDIO_LEFT :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	AUDIO_RIGHT :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	BREAK_PRESSED :  STD_LOGIC;

SIGNAL	CART_RD4 :  STD_LOGIC;
SIGNAL	CART_RD5 :  STD_LOGIC;
SIGNAL	CART_REQUEST :  STD_LOGIC;
SIGNAL	CART_REQUEST_COMPLETE :  STD_LOGIC;
SIGNAL	CART_ROM_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	CART_S4_n :  STD_LOGIC;
SIGNAL	CART_S5_N :  STD_LOGIC;
signal CART_CCTL_N : std_logic;
SIGNAL	CA2_OUT :  STD_LOGIC;
SIGNAL	CA2_DIR_OUT:  STD_LOGIC;
SIGNAL	CB2_OUT :  STD_LOGIC;
SIGNAL	CB2_DIR_OUT:  STD_LOGIC;
SIGNAL	CLK :  STD_LOGIC;
SIGNAL	CLK_SDRAM :  STD_LOGIC;
SIGNAL	COMPOSITE_ON_HSYNC :  STD_LOGIC;
SIGNAL	CONSOL_OPTION :  STD_LOGIC;
SIGNAL	CONSOL_SELECT :  STD_LOGIC;
SIGNAL	CONSOL_START :  STD_LOGIC;
SIGNAL	CPU_6502_RESET :  STD_LOGIC;
SIGNAL	CPU_ADDR :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	CPU_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	CPU_FETCH :  STD_LOGIC;
SIGNAL	CPU_SHARED_ENABLE :  STD_LOGIC;
SIGNAL	ENABLE_179_MEMWAIT :  STD_LOGIC;
SIGNAL   GPIO_0_IN : STD_LOGIC_VECTOR(35 downto 0);
SIGNAL   GPIO_0_OUT : STD_LOGIC_VECTOR(35 downto 0);
SIGNAL   GPIO_0_DIR_OUT : STD_LOGIC_VECTOR(35 downto 0);
SIGNAL   GPIO_1_IN : STD_LOGIC_VECTOR(35 downto 0);
SIGNAL   GPIO_1_OUT : STD_LOGIC_VECTOR(35 downto 0);
SIGNAL   GPIO_1_DIR_OUT : STD_LOGIC_VECTOR(35 downto 0);
SIGNAL	GPIO_CA2_IN:  STD_LOGIC;
SIGNAL	GPIO_CB2_IN:  STD_LOGIC;
SIGNAL	GPIO_ENABLE :  STD_LOGIC;
SIGNAL	GPIO_PORTA_IN :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	GPIO_PORTB_IN :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL   GPIO_SIO_IN : STD_LOGIC;
SIGNAL   GPIO_SIO_OUT : STD_LOGIC;
SIGNAL	GREEN_LEDS :  STD_LOGIC_VECTOR(1 TO 1);
SIGNAL	GREREN_LEDS :  STD_LOGIC_VECTOR(0 TO 0);
SIGNAL	GTIA_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	CACHE_GTIA_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	GTIA_SOUND :  STD_LOGIC;
SIGNAL	GTIA_WRITE_ENABLE :  STD_LOGIC;
SIGNAL	IRQ_n :  STD_LOGIC;
SIGNAL	KBCODE_DUMMY :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	KEY_HELD :  STD_LOGIC;
SIGNAL	KEY_INTERRUPT :  STD_LOGIC;
SIGNAL	KEYBOARD_RESPONSE :  STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL	KEYBOARD_SCAN :  STD_LOGIC_VECTOR(5 DOWNTO 0);
SIGNAL	LIGHTPEN :  STD_LOGIC;
SIGNAL	MEMORY_DATA :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	MEMORY_READY_ANTIC :  STD_LOGIC;
SIGNAL	MEMORY_READY_CPU :  STD_LOGIC;
SIGNAL	MEMORY_READY_ZPU :  STD_LOGIC;
SIGNAL	NMI_n :  STD_LOGIC;
SIGNAL	PAL :  STD_LOGIC;
SIGNAL	PAUSE_6502 :  STD_LOGIC;
SIGNAL	PBI_ADDR :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	PBI_WRITE_ENABLE :  STD_LOGIC;
SIGNAL	PIA_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	PIA_IRQA :  STD_LOGIC;
SIGNAL	PIA_IRQB :  STD_LOGIC;
SIGNAL	PIA_READ_ENABLE :  STD_LOGIC;
SIGNAL	PIA_WRITE_ENABLE :  STD_LOGIC;
SIGNAL	PLL_LOCKED :  STD_LOGIC;
SIGNAL	POKEY2_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	CACHE_POKEY2_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	POKEY2_WRITE_ENABLE :  STD_LOGIC;
SIGNAL	POKEY_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	CACHE_POKEY_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	POKEY_ENABLE_179 :  STD_LOGIC;
SIGNAL	POKEY_IRQ :  STD_LOGIC;
SIGNAL	POKEY_WRITE_ENABLE :  STD_LOGIC;
SIGNAL	PORTA_OUT :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	PORTA_DIR_OUT :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	PORTB_OUT :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	PORTB_DIR_OUT :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	POT_IN :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	POT_RESET :  STD_LOGIC;
SIGNAL	R_W_N :  STD_LOGIC;
SIGNAL	RAM_ADDR :  STD_LOGIC_VECTOR(18 DOWNTO 0);
SIGNAL	RAM_DO :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	RAM_REQUEST :  STD_LOGIC;
SIGNAL	RAM_REQUEST_COMPLETE :  STD_LOGIC;
SIGNAL	RAM_SELECT :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	RAM_WRITE_ENABLE :  STD_LOGIC;
SIGNAL	RESET_N :  STD_LOGIC;
SIGNAL	ROM_ADDR :  STD_LOGIC_VECTOR(21 DOWNTO 0);
SIGNAL	ROM_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	ROM_REQUEST :  STD_LOGIC;
SIGNAL	ROM_REQUEST_COMPLETE :  STD_LOGIC;
SIGNAL	ROM_SELECT :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	SCANDOUBLER_SHARED_ENABLE_HIGH :  STD_LOGIC;
SIGNAL	SCANDOUBLER_SHARED_ENABLE_LOW :  STD_LOGIC;
SIGNAL	SDRAM_ADDR :  STD_LOGIC_VECTOR(22 DOWNTO 0);
SIGNAL	SDRAM_DO :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	SDRAM_READ_ENABLE :  STD_LOGIC;
SIGNAL	SDRAM_REFRESH :  STD_LOGIC;
--SIGNAL	SDRAM_REPLY :  STD_LOGIC;
SIGNAL	SDRAM_REQUEST_COMPLETE :  STD_LOGIC;
SIGNAL	SDRAM_REQUEST :  STD_LOGIC;
SIGNAL	SDRAM_WRITE_ENABLE :  STD_LOGIC;
SIGNAL	SHIFT_PRESSED :  STD_LOGIC;
SIGNAL	SIO_COMMAND_OUT :  STD_LOGIC;
SIGNAL	SIO_DATA_IN :  STD_LOGIC;
SIGNAL	SIO_DATA_OUT :  STD_LOGIC;
SIGNAL	SYNC_KEYS :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	SYNC_SWITCHES :  STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL	SYSTEM_RESET_REQUEST :  STD_LOGIC;
SIGNAL	THROTTLE_COUNT_6502 :  STD_LOGIC_VECTOR(5 DOWNTO 0);
SIGNAL	TRIGGERS :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	USE_SDRAM :  STD_LOGIC;
SIGNAL	VGA :  STD_LOGIC;
SIGNAL	VIRTUAL_STICKS :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	VIRTUAL_TRIGGERS :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	VIRTUAL_KEYS :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	WIDTH_16BIT_ACCESS :  STD_LOGIC;
SIGNAL	WIDTH_32BIT_ACCESS :  STD_LOGIC;
SIGNAL	WIDTH_8BIT_ACCESS :  STD_LOGIC;
SIGNAL	WRITE_DATA :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	ZPU_16BIT_WRITE_ENABLE :  STD_LOGIC;
SIGNAL	ZPU_32BIT_WRITE_ENABLE :  STD_LOGIC;
SIGNAL	ZPU_8BIT_WRITE_ENABLE :  STD_LOGIC;
SIGNAL	ZPU_ADDR_FETCH :  STD_LOGIC_VECTOR(23 DOWNTO 0);
SIGNAL	ZPU_ADDR_ROM_RAM :  STD_LOGIC_VECTOR(23 DOWNTO 0);
SIGNAL	ZPU_CONFIG_DO :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	ZPU_CONFIG_WRITE_ENABLE :  STD_LOGIC;
SIGNAL	ZPU_DO :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	ZPU_FETCH :  STD_LOGIC;
SIGNAL	ZPU_HEX :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	ZPU_PAUSE :  STD_LOGIC;
SIGNAL	ZPU_RAM_DATA :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	ZPU_READ_ENABLE :  STD_LOGIC;
SIGNAL	ZPU_RESET :  STD_LOGIC;
SIGNAL	ZPU_ROM_DATA :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	ZPU_SECTOR_DATA :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	ZPU_STACK_WRITE :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_0 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_1 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_2 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_3 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_4 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_5 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_6 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_7 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_8 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_9 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_10 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_11 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_12 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_13 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_14 :  STD_LOGIC_VECTOR(7 DOWNTO 0);

SIGNAL	LEDR_dummy :  STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL	LEDG_dummy :  STD_LOGIC_VECTOR(7 DOWNTO 0);
signal UART_TXD_dummy : std_logic;

-- STUB OUT FOR NOW
SIGNAL		PS2K_CLK :  STD_LOGIC;
SIGNAL		PS2K_DAT :  STD_LOGIC;
signal		JOY1_n :  STD_LOGIC_VECTOR(5 DOWNTO 0);
signal		JOY2_n :  STD_LOGIC_VECTOR(5 DOWNTO 0);
signal		JOY1 :  STD_LOGIC_VECTOR(5 DOWNTO 0);
signal		JOY2 :  STD_LOGIC_VECTOR(5 DOWNTO 0);


SIGNAL		SD_DAT0 :  STD_LOGIC;
SIGNAL		SD_CLK :  STD_LOGIC;
SIGNAL		SD_CMD :  STD_LOGIC;
SIGNAL		SD_DAT3 :  STD_LOGIC;

signal mist_buttons : std_logic_vector(1 downto 0);
signal mist_switches : std_logic_vector(1 downto 0);

signal keyboard : std_logic_vector(127 downto 0);
signal atari_keyboard : std_logic_vector(63 downto 0);

SIGNAL	SHIFT_PRESSED_DUMMY :  STD_LOGIC;
SIGNAL	BREAK_PRESSED_DUMMY :  STD_LOGIC;
SIGNAL	CONTROL_PRESSED :  STD_LOGIC;

SIGNAL	CONSOL_OPTION_DUMMY :  STD_LOGIC;
SIGNAL	CONSOL_SELECT_DUMMY :  STD_LOGIC;
SIGNAL	CONSOL_START_DUMMY :  STD_LOGIC;

signal capslock_pressed : std_logic;
signal capsheld_next : std_logic;
signal capsheld_reg : std_logic;

signal mist_sector_ready : std_logic;
signal mist_sector_ready_sync : std_logic;
signal mist_sector_request : std_logic;
signal mist_sector_request_sync : std_logic;
signal mist_sector : std_logic_vector(31 downto 0);
signal mist_sector_sync : std_logic_vector(31 downto 0);

		
signal mist_addr : std_logic_vector(8 downto 0);
signal mist_do : std_logic_vector(7 downto 0);
signal mist_di : std_logic_vector(7 downto 0);
signal mist_wren : std_logic;

signal spi_miso_data : std_logic;
signal spi_miso_io : std_logic;

signal covox_write_enable : std_logic;
signal covox_channel0 : std_logic_vector(7 downto 0);
signal covox_channel1 : std_logic_vector(7 downto 0);
signal covox_channel2 : std_logic_vector(7 downto 0);
signal covox_channel3 : std_logic_vector(7 downto 0);

BEGIN 

	
-- mist spi io
mist_spi_interface : data_io 
	PORT map
	(
		CLK =>spi_sck,
		RESET_n =>reset_n,
		
		-- SPI connection - up to upstream to make miso 'Z' on ss_io going high
		SPI_CLK =>spi_sck,
		SPI_SS_IO => spi_ss2,
		SPI_MISO => spi_miso_data,
		SPI_MOSI => spi_di,
		
		-- Sector access request
		request => mist_sector_request_sync,
		sector => mist_sector_sync(23 downto 0),
		ready => mist_sector_ready,
		
		-- DMA to RAM
		ADDR => mist_addr,
		DATA_OUT => mist_do,
		DATA_IN => mist_di,
		WR_EN => mist_wren
	 );
 
	select_sync : synchronizer
	PORT MAP ( CLK => clk, raw => mist_sector_ready, sync=>mist_sector_ready_sync);

	select_sync2 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector_request, sync=>mist_sector_request_sync);

	sector_sync0 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(0), sync=>mist_sector_sync(0));

	sector_sync1 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(1), sync=>mist_sector_sync(1));

	sector_sync2 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(2), sync=>mist_sector_sync(2));

	sector_sync3 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(3), sync=>mist_sector_sync(3));

	sector_sync4 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(4), sync=>mist_sector_sync(4));

	sector_sync5 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(5), sync=>mist_sector_sync(5));

	sector_sync6 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(6), sync=>mist_sector_sync(6));

	sector_sync7 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(7), sync=>mist_sector_sync(7));

	sector_sync8 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(8), sync=>mist_sector_sync(8));

	sector_sync9 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(9), sync=>mist_sector_sync(9));

	sector_sync10 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(10), sync=>mist_sector_sync(10));

	sector_sync11 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(11), sync=>mist_sector_sync(11));

	sector_sync12 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(12), sync=>mist_sector_sync(12));

	sector_sync13 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(13), sync=>mist_sector_sync(13));

	sector_sync14 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(14), sync=>mist_sector_sync(14));

	sector_sync15 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(15), sync=>mist_sector_sync(15));

	sector_sync16 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(16), sync=>mist_sector_sync(16));

	sector_sync17 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(17), sync=>mist_sector_sync(17));

	sector_sync18 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(18), sync=>mist_sector_sync(18));

	sector_sync19 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(19), sync=>mist_sector_sync(19));

	sector_sync20 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(20), sync=>mist_sector_sync(20));

	sector_sync21 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(21), sync=>mist_sector_sync(21));

	sector_sync22 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(22), sync=>mist_sector_sync(22));

	sector_sync23 : synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(23), sync=>mist_sector_sync(23));
	
	
	spi_do <= spi_miso_io when CONF_DATA0 ='0' else spi_miso_data when spi_SS2='0' else 'Z';

	-- TODO, dual port, dual clock! 
--	mist_sector_buffer : generic_ram_infer
--	generic map
--	(
--		ADDRESS_WIDTH => 9,
--		SPACE => 512,
--		DATA_WIDTH => 8
--	)
--   PORT map
--   (
--      clock => spi_sck,
--      data => mist_do,
--      address => mist_addr,
--      we => mist_wren,
--      q => mist_di
--   );

mist_sector_buffer1 : mist_sector_buffer
	PORT map
	(
		address_a		=> mist_addr,
		address_b		=> ZPU_ADDR_ROM_RAM(8 DOWNTO 2),
		clock_a		=> spi_sck,
		clock_b		=> clk,
		data_a		=> mist_do,
		data_b		=> zpu_do,
		wren_a		=> mist_wren,
		wren_b		=> '0',
		q_a		=> mist_di,
		q_b		=> zpu_sector_data
	);
	
my_user_io : user_io
	PORT map(
	   SPI_CLK => SPI_SCK,
	   SPI_SS_IO => CONF_DATA0,
	   SPI_MISO => SPI_miso_io,
	   SPI_MOSI => SPI_DI,
	   CORE_TYPE => x"A4",
		JOY0 => joy1,
		JOY1 => joy2,
		KEYBOARD => keyboard,
		BUTTONS => mist_buttons,
		SWITCHES => mist_switches
	  );
	  
	 joy1_n <= not(joy1);
	 joy2_n <= not(joy2);
	 
	process(clk,reset_n)
	begin
		if (reset_n='0') then
			capsheld_reg <= '0';
		elsif (clk'event and clk='1') then
			capsheld_reg <= capsheld_next;
		end if;
	end process;

	process(keyboard,capsheld_reg)
	begin
		capsheld_next <= capsheld_reg;
		capslock_pressed <= '0';
		
		if ((keyboard(58) xor capsheld_reg)='1') then
			capsheld_next <= keyboard(58);
			
			-- assert something for 10 frames
			capslock_pressed <= '1';
		end if;
	end process;
	
atari_keyboard(63) <= keyboard(30);
atari_keyboard(62) <= keyboard(31);
atari_keyboard(61) <= keyboard(34);
atari_keyboard(60) <= '0';
atari_keyboard(58) <= keyboard(32);
atari_keyboard(57) <= keyboard(35);
atari_keyboard(56) <= keyboard(33);
atari_keyboard(55) <= keyboard(13);
atari_keyboard(54) <= keyboard(12);
atari_keyboard(53) <= keyboard(9);
atari_keyboard(52) <= keyboard(14);
atari_keyboard(51) <= keyboard(8);
atari_keyboard(50) <= keyboard(11);
atari_keyboard(48) <= keyboard(10);
atari_keyboard(47) <= keyboard(16);
atari_keyboard(46) <= keyboard(17);
atari_keyboard(45) <= keyboard(20);
atari_keyboard(44) <= keyboard(15);
atari_keyboard(43) <= keyboard(21);
atari_keyboard(42) <= keyboard(18);
atari_keyboard(40) <= keyboard(19);
atari_keyboard(39) <= keyboard(56);
atari_keyboard(38) <= keyboard(53);
atari_keyboard(37) <= keyboard(50);
atari_keyboard(35) <= keyboard(49);
atari_keyboard(34) <= keyboard(52);
atari_keyboard(33) <= keyboard(57);
atari_keyboard(32) <= keyboard(51);
atari_keyboard(31) <= keyboard(2);
atari_keyboard(30) <= keyboard(3);
atari_keyboard(29) <= keyboard(6);
atari_keyboard(28) <= keyboard(1);
atari_keyboard(27) <= keyboard(7);
atari_keyboard(26) <= keyboard(4);
atari_keyboard(24) <= keyboard(5);
atari_keyboard(23) <= keyboard(44);
atari_keyboard(22) <= keyboard(45);
atari_keyboard(21) <= keyboard(48);
atari_keyboard(18) <= keyboard(46);
atari_keyboard(17) <= keyboard(59);
atari_keyboard(16) <= keyboard(47);
atari_keyboard(15) <= keyboard(27);
atari_keyboard(14) <= keyboard(26);
atari_keyboard(13) <= keyboard(23);
atari_keyboard(12) <= keyboard(28);
atari_keyboard(11) <= keyboard(22);
atari_keyboard(10) <= keyboard(25);
atari_keyboard(8) <= keyboard(24);
atari_keyboard(7) <= keyboard(41);
atari_keyboard(6) <= keyboard(40);
atari_keyboard(5) <= keyboard(37);
atari_keyboard(2) <= keyboard(39);
atari_keyboard(1) <= keyboard(36);
atari_keyboard(0) <= keyboard(38);

	  
shift_pressed <= keyboard(54) or keyboard(42);
control_pressed <= keyboard(29);
break_pressed <= keyboard(96); -- TODO - not on st keyboard

consol_start <= keyboard(60); --F2
consol_select <= keyboard(61); --F3
consol_option <= keyboard(62); -- F4
		
--f5 <= keyboard(63);
--f6 <= keyboard(64);
--f7 <= keyboard(65);
--f8 <= keyboard(66);
--f9 <= keyboard(67);
--f10 <= keyboard(68);

virtual_keys <= keyboard(65)&keyboard(66)&keyboard(67)&keyboard(68);
SYSTEM_RESET_REQUEST <= keyboard(63);

process(keyboard_scan, atari_keyboard, control_pressed, shift_pressed, break_pressed)
	begin	
		keyboard_response <= (others=>'1');		
		
		if (atari_keyboard(to_integer(unsigned(not(keyboard_scan)))) = '1') then
			keyboard_response(0) <= '0';
		end if;
		
--		if (key_held='1' and kbcode(5 downto 0) = not(keyboard_scan)) then
--			keyboard_response(0) <= '0';
--		end if;
		
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
		  
	-- decode address
--decode_addr1 : complete_address_decoder
--	generic map(width=>6)
--	port map (addr_in=>keyboard_scan, addr_decoded=>keyboard_scan_decoded);
	  
b2v_a_6502 : cpu
PORT MAP(CLK => CLK,
		 RESET => CPU_6502_RESET,
		 ENABLE => RESET_N,
		 IRQ_n => IRQ_n,
		 NMI_n => NMI_n,
		 MEMORY_READY => MEMORY_READY_CPU,
		 THROTTLE => CPU_SHARED_ENABLE,
		 RDY => ANTIC_RDY,
		 DI => MEMORY_DATA(7 DOWNTO 0),
		 R_W_n => R_W_N,
		 CPU_FETCH => CPU_FETCH,
		 A => CPU_ADDR,
		 DO => CPU_DO);

LIGHTPEN <= '1';
b2v_inst1 : antic
PORT MAP(CLK => CLK,
		 WR_EN => ANTIC_WRITE_ENABLE,
		 RESET_N => RESET_N,
		 MEMORY_READY_ANTIC => MEMORY_READY_ANTIC,
		 MEMORY_READY_CPU => MEMORY_READY_CPU,
		 ANTIC_ENABLE_179 => ANTIC_ENABLE_179,
		 PAL => PAL,
		 lightpen => LIGHTPEN,
		 ADDR => PBI_ADDR(3 DOWNTO 0),
		 CPU_DATA_IN => WRITE_DATA(7 DOWNTO 0),
		 MEMORY_DATA_IN => MEMORY_DATA(7 DOWNTO 0),
		 NMI_N_OUT => NMI_n,
		 ANTIC_READY => ANTIC_RDY,
		 COLOUR_CLOCK_ORIGINAL_OUT => ANTIC_ORIGINAL_COLOUR_CLOCK_OUT,
		 COLOUR_CLOCK_OUT => ANTIC_COLOUR_CLOCK_OUT,
		 HIGHRES_COLOUR_CLOCK_OUT => ANTIC_HIGHRES_COLOUR_CLOCK_OUT,
		 dma_fetch_out => ANTIC_FETCH,
		 refresh_out => ANTIC_REFRESH,
		 AN => ANTIC_AN,
		 DATA_OUT => ANTIC_DO,
		 dma_address_out => ANTIC_ADDR);

b2v_inst11 : pokey_mixer
PORT MAP(CLK => CLK,
		 GTIA_SOUND => GTIA_SOUND,
		 CHANNEL_0 => SYNTHESIZED_WIRE_0,
		 CHANNEL_1 => SYNTHESIZED_WIRE_1,
		 CHANNEL_2 => SYNTHESIZED_WIRE_2,
		 CHANNEL_3 => SYNTHESIZED_WIRE_3,
		 COVOX_CHANNEL_0 => covox_channel0,
		 COVOX_CHANNEL_1 => covox_channel1,
		 CHANNEL_ENABLE => "1111",
		 VOLUME_OUT => AUDIO_LEFT);
		 
dac_left : hq_dac
port map
(
  reset => not(reset_n),
  clk => clk,
  clk_ena => '1',
  pcm_in => audio_left&"0000",
  dac_out => audio_l
);

dac_right : hq_dac
port map
(
  reset => not(reset_n),
  clk => clk,
  clk_ena => '1',
  pcm_in => audio_right&"0000",
  dac_out => audio_r
);


b2v_inst12 : ps2_keyboard
PORT MAP(CLK => CLK,
		 RESET_N => RESET_N,
		 PS2_CLK => PS2K_CLK,
		 PS2_DAT => PS2K_DAT,
		 KEY_EVENT => SYNTHESIZED_WIRE_8,
		 KEY_EXTENDED => SYNTHESIZED_WIRE_9,
		 KEY_UP => SYNTHESIZED_WIRE_10,
		 KEY_VALUE => SYNTHESIZED_WIRE_11);


b2v_inst13 : zpu_glue
PORT MAP(CLK => CLK,
		 RESET => ZPU_RESET,
		 PAUSE => ZPU_PAUSE,
		 MEMORY_READY => MEMORY_READY_ZPU,
		 ZPU_CONFIG_DI => ZPU_CONFIG_DO,
		 ZPU_DI => MEMORY_DATA,
		 ZPU_RAM_DI => ZPU_RAM_DATA,
		 ZPU_ROM_DI => ZPU_ROM_DATA,
		 ZPU_SECTOR_DI => zpu_sector_data,
		 MEMORY_FETCH => ZPU_FETCH,
		 ZPU_READ_ENABLE => ZPU_READ_ENABLE,
		 ZPU_32BIT_WRITE_ENABLE => ZPU_32BIT_WRITE_ENABLE,
		 ZPU_16BIT_WRITE_ENABLE => ZPU_16BIT_WRITE_ENABLE,
		 ZPU_8BIT_WRITE_ENABLE => ZPU_8BIT_WRITE_ENABLE,
		 ZPU_CONFIG_WRITE => ZPU_CONFIG_WRITE_ENABLE,
		 ZPU_ADDR_FETCH => ZPU_ADDR_FETCH,
		 ZPU_ADDR_ROM_RAM => ZPU_ADDR_ROM_RAM,
		 ZPU_DO => ZPU_DO,
		 ZPU_STACK_WRITE => ZPU_STACK_WRITE);


b2v_inst14 : pokey_mixer
PORT MAP(CLK => CLK,
		 GTIA_SOUND => GTIA_SOUND,
		 CHANNEL_0 => SYNTHESIZED_WIRE_4,
		 CHANNEL_1 => SYNTHESIZED_WIRE_5,
		 CHANNEL_2 => SYNTHESIZED_WIRE_6,
		 CHANNEL_3 => SYNTHESIZED_WIRE_7,
		 COVOX_CHANNEL_0 => covox_channel2,
		 COVOX_CHANNEL_1 => covox_channel3, 
		 CHANNEL_ENABLE => "1111",
		 VOLUME_OUT => AUDIO_RIGHT);


b2v_inst15 : pokey
PORT MAP(CLK => CLK,
		 CPU_MEMORY_READY => MEMORY_READY_CPU,
		 ANTIC_MEMORY_READY => MEMORY_READY_ANTIC,
		 WR_EN => POKEY2_WRITE_ENABLE,
		 RESET_N => RESET_N,
		 ADDR => PBI_ADDR(3 DOWNTO 0),
		 DATA_IN => WRITE_DATA(7 DOWNTO 0),
		 CHANNEL_0_OUT => SYNTHESIZED_WIRE_4,
		 CHANNEL_1_OUT => SYNTHESIZED_WIRE_5,
		 CHANNEL_2_OUT => SYNTHESIZED_WIRE_6,
		 CHANNEL_3_OUT => SYNTHESIZED_WIRE_7,
		 DATA_OUT => POKEY2_DO,
		 SIO_IN1 => '1',
		 SIO_IN2 => '1',
		 SIO_IN3 => '1',
		 keyboard_response => "00",
		 pot_in=>"00000000");


-- PIA
--GPIO_0[0] <= CA2_OUT when CA2_DIR_OUT='1' else 'Z';
--CA2_IN <= GPIO_0[0];

--GPIO_O[1] <= CB2_OUT when CB2_DIR_OUT='1' else 'Z';
--CB2_IN <= GPIO_O[1];
SIO_COMMAND_OUT <= CB2_OUT; -- we generate command frame, use internal rather than from pin
-- TODO - sioto gpio!
GPIO_PORTB_IN <= PORTB_OUT;
GPIO_CA2_IN <= CA2_OUT;
GPIO_CB2_IN <= CB2_OUT;
GPIO_PORTA_IN <= VIRTUAL_STICKS and (JOY1_n(0)&JOY1_n(1)&JOY1_n(2)&JOY1_n(3)&JOY2_n(0)&JOY2_n(1)&JOY2_n(2)&JOY2_n(3));

b2v_inst16 : pia
PORT MAP(CLK => CLK,
		 EN => PIA_READ_ENABLE,
		 WR_EN => PIA_WRITE_ENABLE,
		 RESET_N => RESET_N,
		 CA1 => '1', --todo - high/low?
		 CB1 => '1',
		 CA2_DIR_OUT => CA2_DIR_OUT,
		 CA2_IN => GPIO_CA2_IN,
		 CA2_OUT => CA2_OUT,
		 CB2_DIR_OUT => CB2_DIR_OUT,
		 CB2_IN => GPIO_CB2_IN,
		 CB2_OUT => CB2_OUT,
		 ADDR => PBI_ADDR(1 DOWNTO 0),
		 CPU_DATA_IN => WRITE_DATA(7 DOWNTO 0),
		 IRQA_N => PIA_IRQA,
		 IRQB_N => PIA_IRQB,
		 DATA_OUT => PIA_DO,
		 PORTA_IN => GPIO_PORTA_IN,
		 PORTA_DIR_OUT => PORTA_DIR_OUT,
		 PORTA_OUT => PORTA_OUT,
		 PORTB_IN => GPIO_PORTB_IN,
		 PORTB_DIR_OUT => PORTB_DIR_OUT,
		 PORTB_OUT => PORTB_OUT);

b2v_inst17 : shared_enable
PORT MAP(CLK => CLK,
		 RESET_N => RESET_N,
		 MEMORY_READY_CPU => MEMORY_READY_CPU,
		 MEMORY_READY_ANTIC => MEMORY_READY_ANTIC,
		 PAUSE_6502 => PAUSE_6502,
		 THROTTLE_COUNT_6502 => THROTTLE_COUNT_6502,
		 POKEY_ENABLE_179 => POKEY_ENABLE_179,
		 ANTIC_ENABLE_179 => ANTIC_ENABLE_179,
		 oldcpu_enable => ENABLE_179_MEMWAIT,
		 CPU_ENABLE_OUT => CPU_SHARED_ENABLE,
		 SCANDOUBLER_ENABLE_LOW => SCANDOUBLER_SHARED_ENABLE_LOW,
		 SCANDOUBLER_ENABLE_HIGH => SCANDOUBLER_SHARED_ENABLE_HIGH);


virtual_sticks <= (others=>'1');
virtual_triggers <= "0011";
--b2v_inst18 : pokey_ps2_decoder
--PORT MAP(CLK => CLK,
--		 RESET_N => RESET_N,
--		 KEY_EVENT => SYNTHESIZED_WIRE_8,
--		 KEY_EXTENDED => SYNTHESIZED_WIRE_9,
--		 KEY_UP => SYNTHESIZED_WIRE_10,
--		 KEY_CODE => SYNTHESIZED_WIRE_11,
--		 KEY_HELD => KEY_HELD,
--		 SHIFT_PRESSED => SHIFT_PRESSED_DUMMY,
--		 BREAK_PRESSED => BREAK_PRESSED_DUMMY,
--		 CONSOL_START => CONSOL_START_DUMMY,
--		 CONSOL_SELECT => CONSOL_SELECT_DUMMY,
--		 CONSOL_OPTION => CONSOL_OPTION_DUMMY,
--		 SYSTEM_RESET => SYSTEM_RESET_REQUEST,
--		 KBCODE => KBCODE_dummy,
--		 VIRTUAL_STICKS => VIRTUAL_STICKS,
--		 VIRTUAL_TRIGGER => VIRTUAL_TRIGGERS,
--		 VIRTUAL_KEYS => VIRTUAL_KEYS);

-- no cart!
CART_RD4 <= '0';
CART_RD5 <= '0';
CART_REQUEST_COMPLETE <= '0';
CART_ROM_DO <= (others=>'0');

b2v_inst2 : address_decoder
PORT MAP(CLK => CLK,
		 CPU_FETCH => CPU_FETCH,
		 CPU_WRITE_N => R_W_N,
		 ANTIC_FETCH => ANTIC_FETCH,
		 antic_refresh => ANTIC_REFRESH,
		 ZPU_FETCH => ZPU_FETCH,
		 ZPU_READ_ENABLE => ZPU_READ_ENABLE,
		 ZPU_32BIT_WRITE_ENABLE => ZPU_32BIT_WRITE_ENABLE,
		 ZPU_16BIT_WRITE_ENABLE => ZPU_16BIT_WRITE_ENABLE,
		 ZPU_8BIT_WRITE_ENABLE => ZPU_8BIT_WRITE_ENABLE,
		 RAM_REQUEST_COMPLETE => RAM_REQUEST_COMPLETE,
		 ROM_REQUEST_COMPLETE => ROM_REQUEST_COMPLETE,
		 CART_REQUEST_COMPLETE => CART_REQUEST_COMPLETE,
		 reset_n => RESET_N,
		 CART_RD4 => CART_RD4,
		 CART_RD5 => CART_RD5,
		 use_sdram => USE_SDRAM,
		 SDRAM_REQUEST_COMPLETE => SDRAM_REQUEST_COMPLETE,
		 ANTIC_ADDR => ANTIC_ADDR,
		 ANTIC_DATA => ANTIC_DO,
		 CACHE_ANTIC_DATA => CACHE_ANTIC_DO,
		 CART_ROM_DATA => CART_ROM_DO,
		 CPU_ADDR => CPU_ADDR,
		 CPU_WRITE_DATA => CPU_DO,
		 GTIA_DATA => GTIA_DO,
		 CACHE_GTIA_DATA => CACHE_GTIA_DO,
		 PIA_DATA => PIA_DO,
		 POKEY2_DATA => POKEY2_DO,
		 CACHE_POKEY2_DATA => CACHE_POKEY2_DO,
		 POKEY_DATA => POKEY_DO,
		 CACHE_POKEY_DATA => CACHE_POKEY_DO,
		 PORTB => PORTB_OUT,
		 RAM_DATA => RAM_DO,
		 ram_select => RAM_SELECT(2 downto 0),
		 ROM_DATA => ROM_DO,
		 rom_select => "00"&ROM_SELECT, -- TODO
		 SDRAM_DATA => SDRAM_DO,
		 ZPU_ADDR => ZPU_ADDR_FETCH,
		 ZPU_WRITE_DATA => ZPU_DO,
		 MEMORY_READY_ANTIC => MEMORY_READY_ANTIC,
		 MEMORY_READY_ZPU => MEMORY_READY_ZPU,
		 MEMORY_READY_CPU => MEMORY_READY_CPU,
		 GTIA_WR_ENABLE => GTIA_WRITE_ENABLE,
		 POKEY_WR_ENABLE => POKEY_WRITE_ENABLE,
		 POKEY2_WR_ENABLE => POKEY2_WRITE_ENABLE,
		 ANTIC_WR_ENABLE => ANTIC_WRITE_ENABLE,
		 PIA_WR_ENABLE => PIA_WRITE_ENABLE,
		 PIA_RD_ENABLE => PIA_READ_ENABLE,
		 RAM_WR_ENABLE => RAM_WRITE_ENABLE,
		 PBI_WR_ENABLE => PBI_WRITE_ENABLE,
		 RAM_REQUEST => RAM_REQUEST,
		 ROM_REQUEST => ROM_REQUEST,
		 CART_REQUEST => CART_REQUEST,
		 CART_S4_n => CART_S4_n,
		 CART_S5_n => CART_S5_N,
		 CART_CCTL_n => CART_CCTL_N,
		 WIDTH_8bit_ACCESS => WIDTH_8BIT_ACCESS,
		 WIDTH_16bit_ACCESS => WIDTH_16BIT_ACCESS,
		 WIDTH_32bit_ACCESS => WIDTH_32BIT_ACCESS,
		 SDRAM_READ_EN => SDRAM_READ_ENABLE,
		 SDRAM_WRITE_EN => SDRAM_WRITE_ENABLE,
		 SDRAM_REQUEST => SDRAM_REQUEST,
		 SDRAM_REFRESH => SDRAM_REFRESH,
		 MEMORY_DATA => MEMORY_DATA,
		 PBI_ADDR => PBI_ADDR,
		 RAM_ADDR => RAM_ADDR,
		 ROM_ADDR => ROM_ADDR,
		 SDRAM_ADDR => SDRAM_ADDR,
		 WRITE_DATA => WRITE_DATA,
		 d6_wr_enable => covox_write_enable,
		 cart_select => "0000000",
		 cart_activate => '0');

b2v_inst21 : zpu_rom
PORT MAP(clock => CLK,
		 address => ZPU_ADDR_ROM_RAM(13 DOWNTO 2),
		 q => ZPU_ROM_DATA);


b2v_inst22 : scandoubler
PORT MAP(CLK => CLK,
		 RESET_N => RESET_N,
		 VGA => VGA,
		 COMPOSITE_ON_HSYNC => COMPOSITE_ON_HSYNC,
		 colour_enable => SCANDOUBLER_SHARED_ENABLE_LOW,
		 doubled_enable => SCANDOUBLER_SHARED_ENABLE_HIGH,
		 vsync_in => SYNTHESIZED_WIRE_12,
		 hsync_in => SYNTHESIZED_WIRE_13,
		 colour_in => SYNTHESIZED_WIRE_14,
		 VSYNC => VGA_VS,
		 HSYNC => VGA_HS,
		 B => VGA_B(5 downto 2),
		 G => VGA_G(5 downto 2),
		 R => VGA_R(5 downto 2));

b2v_inst23 : zpu_ram
PORT MAP(wren => ZPU_STACK_WRITE(2),
		 clock => CLK,
		 address => ZPU_ADDR_ROM_RAM(11 DOWNTO 2),
		 data => ZPU_DO(23 DOWNTO 16),
		 q => ZPU_RAM_DATA(23 DOWNTO 16));

SYNC_KEYS <= (others=> '0');
SYNC_SWITCHES <= (others=> '1');
b2v_inst24 : zpu_config_regs
PORT MAP(CLK => CLK,
		 ENABLE_179 => POKEY_ENABLE_179,
		 WR_EN => ZPU_CONFIG_WRITE_ENABLE,
		 SDCARD_DAT => SD_DAT0,
		 SIO_COMMAND_OUT => SIO_COMMAND_OUT,
		 SIO_DATA_OUT => SIO_DATA_OUT,
		 PLL_LOCKED => PLL_LOCKED,
		 REQUEST_RESET_ZPU => SYSTEM_RESET_REQUEST,
		 ADDR => ZPU_ADDR_ROM_RAM(6 DOWNTO 2),
		 CPU_DATA_IN => ZPU_DO,
		 KEY => VIRTUAL_KEYS, --SYNC_KEYS,
		 SWITCH => SYNC_SWITCHES,
		 SDCARD_CLK => SD_CLK,
		 SDCARD_CMD => SD_CMD,
		 SDCARD_DAT3 => SD_DAT3,
		 SIO_DATA_IN => SIO_DATA_IN,
		 PAUSE_ZPU => ZPU_PAUSE,
		 PAL => PAL,
		 USE_SDRAM => USE_SDRAM,
		 VGA => VGA,
		 COMPOSITE_ON_HSYNC => COMPOSITE_ON_HSYNC,
		 GPIO_ENABLE => GPIO_ENABLE,
		 RESET_6502 => CPU_6502_RESET,
		 RESET_ZPU => ZPU_RESET,
		 RESET_N => RESET_N,
		 PAUSE_6502 => PAUSE_6502,
		 DATA_OUT => ZPU_CONFIG_DO,
		 LEDG => LEDG_dummy,
		 LEDR => LEDR_dummy,
		 RAM_SELECT => RAM_SELECT,
		 ROM_SELECT => ROM_SELECT,
		 THROTTLE_COUNT_6502 => THROTTLE_COUNT_6502,
		 ZPU_HEX => ZPU_HEX,
		 sector_request => mist_sector_request,
		 sector => mist_sector,
		 sector_ready => mist_sector_ready_sync
		 );


b2v_inst25 : zpu_ram
PORT MAP(wren => ZPU_STACK_WRITE(3),
		 clock => CLK,
		 address => ZPU_ADDR_ROM_RAM(11 DOWNTO 2),
		 data => ZPU_DO(31 DOWNTO 24),
		 q => ZPU_RAM_DATA(31 DOWNTO 24));


b2v_inst26 : zpu_ram
PORT MAP(wren => ZPU_STACK_WRITE(0),
		 clock => CLK,
		 address => ZPU_ADDR_ROM_RAM(11 DOWNTO 2),
		 data => ZPU_DO(7 DOWNTO 0),
		 q => ZPU_RAM_DATA(7 DOWNTO 0));


b2v_inst27 : zpu_ram
PORT MAP(wren => ZPU_STACK_WRITE(1),
		 clock => CLK,
		 address => ZPU_ADDR_ROM_RAM(11 DOWNTO 2),
		 data => ZPU_DO(15 DOWNTO 8),
		 q => ZPU_RAM_DATA(15 DOWNTO 8));


b2v_inst5 : pll
PORT MAP(inclk0 => CLOCK_27(0),
		 c0 => CLK_SDRAM,
		 c1 => CLK,
		 c2 => SDRAM_CLK,
		 locked => PLL_LOCKED);

b2v_inst7 : pokey
PORT MAP(CLK => CLK,
		 CPU_MEMORY_READY => MEMORY_READY_CPU,
		 ANTIC_MEMORY_READY => MEMORY_READY_ANTIC,
		 WR_EN => POKEY_WRITE_ENABLE,
		 RESET_N => RESET_N,
		 SIO_IN1 => '1',
		 SIO_IN2 => '1',
		 SIO_IN3 => SIO_DATA_IN,
		 ADDR => PBI_ADDR(3 DOWNTO 0),
		 DATA_IN => WRITE_DATA(7 DOWNTO 0),
		 keyboard_response => KEYBOARD_RESPONSE,
		 POT_IN => POT_IN,
		 IRQ_N_OUT => POKEY_IRQ,
		 SIO_OUT1 => UART_TXD_dummy,
		 SIO_OUT2 => GPIO_SIO_OUT,
		 SIO_OUT3 => SIO_DATA_OUT,
		 POT_RESET => POT_RESET,
		 CHANNEL_0_OUT => SYNTHESIZED_WIRE_0,
		 CHANNEL_1_OUT => SYNTHESIZED_WIRE_1,
		 CHANNEL_2_OUT => SYNTHESIZED_WIRE_2,
		 CHANNEL_3_OUT => SYNTHESIZED_WIRE_3,
		 DATA_OUT => POKEY_DO,
		 keyboard_scan => KEYBOARD_SCAN);

--	process(keyboard_scan, kbcode, key_held, shift_pressed, break_pressed)
--	begin	
--		keyboard_response <= (others=>'1');
--		
--		if (key_held='1' and kbcode(5 downto 0) = not(keyboard_scan)) then
--			keyboard_response(0) <= '0';
--		end if;
--		
--		if (keyboard_scan(5 downto 4)="00" and break_pressed = '1') then
--			keyboard_response(1) <= '0';
--		end if;
--		
--		if (keyboard_scan(5 downto 4)="10" and shift_pressed = '1') then
--			keyboard_response(1) <= '0';
--		end if;
--
--		if (keyboard_scan(5 downto 4)="11" and kbcode(7) = '1') then
--			keyboard_response(1) <= '0';
--		end if;
--	end process;		 
--		 	 
b2v_inst8 : gtia
PORT MAP(CLK => CLK,
		 WR_EN => GTIA_WRITE_ENABLE,
		 CPU_MEMORY_READY => MEMORY_READY_CPU,
		 ANTIC_MEMORY_READY => MEMORY_READY_ANTIC,
		 ANTIC_FETCH => ANTIC_FETCH,
		 CPU_ENABLE_ORIGINAL => ENABLE_179_MEMWAIT,
		 RESET_N => RESET_N,
		 PAL => PAL,
		 COLOUR_CLOCK_ORIGINAL => ANTIC_ORIGINAL_COLOUR_CLOCK_OUT,
		 COLOUR_CLOCK => ANTIC_COLOUR_CLOCK_OUT,
		 COLOUR_CLOCK_HIGHRES => ANTIC_HIGHRES_COLOUR_CLOCK_OUT,
		 CONSOL_START => CONSOL_START,
		 CONSOL_SELECT => CONSOL_SELECT,
		 CONSOL_OPTION => CONSOL_OPTION,
		 TRIG0 => VIRTUAL_TRIGGERS(0) and joy2_n(4), -- TODO - joystick trigger too
		 TRIG1 => VIRTUAL_TRIGGERS(1) and joy1_n(4),
		 --TRIG0 => VIRTUAL_TRIGGERS(0),
		 --TRIG1 => VIRTUAL_TRIGGERS(1),
		 TRIG2 => VIRTUAL_TRIGGERS(2),
		 TRIG3 => VIRTUAL_TRIGGERS(3),
		 ADDR => PBI_ADDR(4 DOWNTO 0),
		 AN => ANTIC_AN,
		 CPU_DATA_IN => WRITE_DATA(7 DOWNTO 0),
		 MEMORY_DATA_IN => MEMORY_DATA(7 DOWNTO 0),
		 VSYNC => SYNTHESIZED_WIRE_12,
		 HSYNC => SYNTHESIZED_WIRE_13,
		 sound => GTIA_SOUND,
		 COLOUR_out => SYNTHESIZED_WIRE_14,
		 DATA_OUT => GTIA_DO);


b2v_inst9 : irq_glue
PORT MAP(pokey_irq => POKEY_IRQ,
		 pia_irqa => PIA_IRQA,
		 pia_irqb => PIA_IRQB,
		 combined_irq => IRQ_n);
		 
pokey1_mirror : reg_file
generic map(BYTES=>16,WIDTH=>4)
port map(
	CLK => CLK,
	ADDR => PBI_ADDR(3 downto 0),
	DATA_IN => WRITE_DATA(7 downto 0),
	WR_EN => POKEY_WRITE_ENABLE,
	DATA_OUT => CACHE_POKEY_DO
);	 

pokey2_mirror : reg_file
generic map(BYTES=>16,WIDTH=>4)
port map(
	CLK => CLK,
	ADDR => PBI_ADDR(3 downto 0),
	DATA_IN => WRITE_DATA(7 downto 0),
	WR_EN => POKEY2_WRITE_ENABLE,
	DATA_OUT => CACHE_POKEY2_DO
);	 		 

gtia_mirror : reg_file
generic map(BYTES=>32,WIDTH=>5)
port map(
	CLK => CLK,
	ADDR => PBI_ADDR(4 downto 0),
	DATA_IN => WRITE_DATA(7 downto 0),
	WR_EN => GTIA_WRITE_ENABLE,
	DATA_OUT => CACHE_GTIA_DO
);	

antic_mirror : reg_file
generic map(BYTES=>16,WIDTH=>4)
port map(
	CLK => CLK,
	ADDR => PBI_ADDR(3 downto 0),
	DATA_IN => WRITE_DATA(7 downto 0),
	WR_EN => ANTIC_WRITE_ENABLE,
	DATA_OUT => CACHE_ANTIC_DO
);	

irr : internalromram
  PORT map(
    clock => clk,
    reset_n => reset_n,

	ROM_ADDR =>rom_addr,
	ROM_REQUEST_COMPLETE => rom_REQUEST_COMPLETE,
	ROM_REQUEST => rom_REQUEST,
	ROM_DATA => rom_DO,
	
	RAM_ADDR => ram_addr,
	RAM_WR_ENABLE => ram_WRITE_ENABLE,
	RAM_DATA_IN => wriTE_DATA(7 downto 0),
	RAM_REQUEST_COMPLETE => ram_REQUEST_COMPLETE,
	RAM_REQUEST => ram_REQUEST,
	RAM_DATA => ram_do(7 downto 0)
	);

b2v_inst20 : sdram_statemachine
GENERIC MAP(ADDRESS_WIDTH => 22,
			AP_BIT => 10,
			COLUMN_WIDTH => 8,
			ROW_WIDTH => 12
			)
PORT MAP(CLK_SYSTEM => CLK,
		 CLK_SDRAM => CLK_SDRAM,
		 RESET_N => RESET_N,
		 READ_EN => SDRAM_READ_ENABLE,
		 WRITE_EN => SDRAM_WRITE_ENABLE,
		 REQUEST => SDRAM_REQUEST,
		 BYTE_ACCESS => WIDTH_8BIT_ACCESS,
		 WORD_ACCESS => WIDTH_16BIT_ACCESS,
		 LONGWORD_ACCESS => WIDTH_32BIT_ACCESS,
		 REFRESH => SDRAM_REFRESH,
		 ADDRESS_IN => SDRAM_ADDR,
		 DATA_IN => WRITE_DATA,
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
		 SDRAM_ADDR => SDRAM_A(11 downto 0));
		 
SDRAM_A(12) <= '0';

--b2v_inst20 : sdram_statemachine_mcc
--GENERIC MAP(ADDRESS_WIDTH => 22,
--			AP_BIT => 10,
--			COLUMN_WIDTH => 8,
--			ROW_WIDTH => 12
--			)
--PORT MAP(CLK_SYSTEM => CLK,
--		 CLK_SDRAM => CLK_SDRAM,
--		 RESET_N => RESET_N,
--		 READ_EN => SDRAM_READ_ENABLE,
--		 WRITE_EN => SDRAM_WRITE_ENABLE,
--		 REQUEST => SDRAM_REQUEST,
--		 BYTE_ACCESS => WIDTH_8BIT_ACCESS,
--		 WORD_ACCESS => WIDTH_16BIT_ACCESS,
--		 LONGWORD_ACCESS => WIDTH_32BIT_ACCESS,
--		 REFRESH => SDRAM_REFRESH,
--		 ADDRESS_IN => SDRAM_ADDR,
--		 DATA_IN => WRITE_DATA,
--		 SDRAM_DQ => SDRAM_DQ,
--		 REPLY => SDRAM_REQUEST_COMPLETE,
--		 SDRAM_BA0 => SDRAM_BA(0),
--		 SDRAM_BA1 => SDRAM_BA(1),
--		 --SDRAM_CKE => SDRAM_A(12), -- TODO?
--		 SDRAM_CS_N => SDRAM_nCS,
--		 SDRAM_RAS_N => SDRAM_nRAS,
--		 SDRAM_CAS_N => SDRAM_nCAS,
--		 SDRAM_WE_N => SDRAM_nWE,
--		 SDRAM_ldqm => SDRAM_DQML,
--		 SDRAM_udqm => SDRAM_DQMH,
--		 DATA_OUT => SDRAM_DO,
--		 SDRAM_ADDR => SDRAM_A(12 downto 0)); -- TODO?

--SDRAM_CKE <= '1';		 
LED <= '0';
VGA_R(1 downto 0) <= "00";
VGA_G(1 downto 0) <= "00";
VGA_B(1 downto 0) <= "00";

covox1 : covox
	PORT map
	( 
		clk => clk,
		addr => pbi_addr(1 downto 0),
		data_in => WRITE_DATA(7 DOWNTO 0),
		wr_en => covox_write_enable,
		covox_channel0 => covox_channel0,
		covox_channel1 => covox_channel1,
		covox_channel2 => covox_channel2,
		covox_channel3 => covox_channel3
	);
		
END bdf_type;