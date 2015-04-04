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
	AUD_I2C_SCLK : inout std_logic;
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
	GPIO1 : inout std_logic_vector(35 downto 0);
	
	-- HPS PINs (these are not set when flashing fpga, but by preloader...
	HPS_DDR3_A:OUT STD_LOGIC_VECTOR(14 downto 0);
	HPS_DDR3_BA: OUT STD_LOGIC_VECTOR(2 downto 0);
	HPS_DDR3_CAS_N: OUT STD_LOGIC;
	HPS_DDR3_CKE:OUT STD_LOGIC;
	HPS_DDR3_CK_N: OUT STD_LOGIC;
	HPS_DDR3_CK_P: OUT STD_LOGIC;
	HPS_DDR3_CS_N: OUT STD_LOGIC;
	HPS_DDR3_DM: OUT STD_LOGIC_VECTOR(3 downto 0);
	HPS_DDR3_DQ: INOUT STD_LOGIC_VECTOR(31 downto 0);
	HPS_DDR3_DQS_N: INOUT STD_LOGIC_VECTOR(3 downto 0);
	HPS_DDR3_DQS_P: INOUT STD_LOGIC_VECTOR(3 downto 0);
	HPS_DDR3_ODT: OUT STD_LOGIC;
	HPS_DDR3_RAS_N: OUT STD_LOGIC;
	HPS_DDR3_RESET_N: OUT STD_LOGIC;
	HPS_DDR3_RZQ: IN STD_LOGIC;
	HPS_DDR3_WE_N: OUT STD_LOGIC;
	HPS_ENET_GTX_CLK: OUT STD_LOGIC;
	HPS_ENET_MDC:OUT STD_LOGIC;
	HPS_ENET_MDIO:INOUT STD_LOGIC;
	HPS_ENET_RX_CLK: IN STD_LOGIC;
	HPS_ENET_RX_DATA: IN STD_LOGIC_VECTOR(3 downto 0);
	HPS_ENET_RX_DV: IN STD_LOGIC;
	HPS_ENET_TX_DATA: OUT STD_LOGIC_VECTOR(3 downto 0);
	HPS_ENET_TX_EN: OUT STD_LOGIC;
	HPS_SD_CLK: OUT STD_LOGIC;
	HPS_SD_CMD: INOUT STD_LOGIC;
	HPS_SD_DATA: INOUT STD_LOGIC_VECTOR(3 downto 0);
	HPS_UART_RX: IN STD_LOGIC;
	HPS_UART_TX: OUT STD_LOGIC;
	HPS_USB_CLKOUT: IN STD_LOGIC;
	HPS_USB_DATA:INOUT STD_LOGIC_VECTOR(7 downto 0);
	HPS_USB_DIR: IN STD_LOGIC;
	HPS_USB_NXT: IN STD_LOGIC;
	HPS_USB_STP: OUT STD_LOGIC;
	HPS_FLASH_DATA : INOUT STD_LOGIC_VECTOR(3 downto 0);
	HPS_FLASH_DCLK : OUT STD_LOGIC;
	HPS_FLASH_NCSO : OUT STD_LOGIC;
	HPS_I2C_CLK : INOUT STD_LOGIC;
	HPS_I2C_SDA : INOUT STD_LOGIC;
	HPS_LCM_SPIM_CLK : OUT STD_LOGIC;
	HPS_LCM_SPIM_MISO : IN STD_LOGIC;
	HPS_LCM_SPIM_MOSI : OUT STD_LOGIC;
	HPS_LCM_SPIM_SS : OUT STD_LOGIC;	
	HPS_SPIM_CLK : OUT STD_LOGIC;
	HPS_SPIM_MISO : IN STD_LOGIC;
	HPS_SPIM_MOSI : OUT STD_LOGIC;
	HPS_SPIM_SS : OUT STD_LOGIC
	);
END atari800core_sockit;

ARCHITECTURE vhdl OF atari800core_sockit IS 
	function vectorize(s: std_logic) return std_logic_vector is
	variable v: std_logic_vector(0 downto 0);
	begin
		v(0) := s;
		return v;
	end;

    component atari_hps is
        port (
            clk_clk                               : in    std_logic                     := 'X';             -- clk
            hps_0_h2f_reset_reset_n               : out   std_logic;                                        -- reset_n
            hps_0_hps_io_hps_io_emac1_inst_TX_CLK : out   std_logic;                                        -- hps_io_emac1_inst_TX_CLK
            hps_0_hps_io_hps_io_emac1_inst_TXD0   : out   std_logic;                                        -- hps_io_emac1_inst_TXD0
            hps_0_hps_io_hps_io_emac1_inst_TXD1   : out   std_logic;                                        -- hps_io_emac1_inst_TXD1
            hps_0_hps_io_hps_io_emac1_inst_TXD2   : out   std_logic;                                        -- hps_io_emac1_inst_TXD2
            hps_0_hps_io_hps_io_emac1_inst_TXD3   : out   std_logic;                                        -- hps_io_emac1_inst_TXD3
            hps_0_hps_io_hps_io_emac1_inst_RXD0   : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD0
            hps_0_hps_io_hps_io_emac1_inst_MDIO   : inout std_logic                     := 'X';             -- hps_io_emac1_inst_MDIO
            hps_0_hps_io_hps_io_emac1_inst_MDC    : out   std_logic;                                        -- hps_io_emac1_inst_MDC
            hps_0_hps_io_hps_io_emac1_inst_RX_CTL : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RX_CTL
            hps_0_hps_io_hps_io_emac1_inst_TX_CTL : out   std_logic;                                        -- hps_io_emac1_inst_TX_CTL
            hps_0_hps_io_hps_io_emac1_inst_RX_CLK : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RX_CLK
            hps_0_hps_io_hps_io_emac1_inst_RXD1   : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD1
            hps_0_hps_io_hps_io_emac1_inst_RXD2   : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD2
            hps_0_hps_io_hps_io_emac1_inst_RXD3   : in    std_logic                     := 'X';             -- hps_io_emac1_inst_RXD3
            hps_0_hps_io_hps_io_qspi_inst_IO0     : inout std_logic                     := 'X';             -- hps_io_qspi_inst_IO0
            hps_0_hps_io_hps_io_qspi_inst_IO1     : inout std_logic                     := 'X';             -- hps_io_qspi_inst_IO1
            hps_0_hps_io_hps_io_qspi_inst_IO2     : inout std_logic                     := 'X';             -- hps_io_qspi_inst_IO2
            hps_0_hps_io_hps_io_qspi_inst_IO3     : inout std_logic                     := 'X';             -- hps_io_qspi_inst_IO3
            hps_0_hps_io_hps_io_qspi_inst_SS0     : out   std_logic;                                        -- hps_io_qspi_inst_SS0
            hps_0_hps_io_hps_io_qspi_inst_CLK     : out   std_logic;                                        -- hps_io_qspi_inst_CLK
            hps_0_hps_io_hps_io_sdio_inst_CMD     : inout std_logic                     := 'X';             -- hps_io_sdio_inst_CMD
            hps_0_hps_io_hps_io_sdio_inst_D0      : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D0
            hps_0_hps_io_hps_io_sdio_inst_D1      : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D1
            hps_0_hps_io_hps_io_sdio_inst_CLK     : out   std_logic;                                        -- hps_io_sdio_inst_CLK
            hps_0_hps_io_hps_io_sdio_inst_D2      : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D2
            hps_0_hps_io_hps_io_sdio_inst_D3      : inout std_logic                     := 'X';             -- hps_io_sdio_inst_D3
            hps_0_hps_io_hps_io_usb1_inst_D0      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D0
            hps_0_hps_io_hps_io_usb1_inst_D1      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D1
            hps_0_hps_io_hps_io_usb1_inst_D2      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D2
            hps_0_hps_io_hps_io_usb1_inst_D3      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D3
            hps_0_hps_io_hps_io_usb1_inst_D4      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D4
            hps_0_hps_io_hps_io_usb1_inst_D5      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D5
            hps_0_hps_io_hps_io_usb1_inst_D6      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D6
            hps_0_hps_io_hps_io_usb1_inst_D7      : inout std_logic                     := 'X';             -- hps_io_usb1_inst_D7
            hps_0_hps_io_hps_io_usb1_inst_CLK     : in    std_logic                     := 'X';             -- hps_io_usb1_inst_CLK
            hps_0_hps_io_hps_io_usb1_inst_STP     : out   std_logic;                                        -- hps_io_usb1_inst_STP
            hps_0_hps_io_hps_io_usb1_inst_DIR     : in    std_logic                     := 'X';             -- hps_io_usb1_inst_DIR
            hps_0_hps_io_hps_io_usb1_inst_NXT     : in    std_logic                     := 'X';             -- hps_io_usb1_inst_NXT
            hps_0_hps_io_hps_io_spim0_inst_CLK    : out   std_logic;                                        -- hps_io_spim0_inst_CLK
            hps_0_hps_io_hps_io_spim0_inst_MOSI   : out   std_logic;                                        -- hps_io_spim0_inst_MOSI
            hps_0_hps_io_hps_io_spim0_inst_MISO   : in    std_logic                     := 'X';             -- hps_io_spim0_inst_MISO
            hps_0_hps_io_hps_io_spim0_inst_SS0    : out   std_logic;                                        -- hps_io_spim0_inst_SS0
            hps_0_hps_io_hps_io_spim1_inst_CLK    : out   std_logic;                                        -- hps_io_spim1_inst_CLK
            hps_0_hps_io_hps_io_spim1_inst_MOSI   : out   std_logic;                                        -- hps_io_spim1_inst_MOSI
            hps_0_hps_io_hps_io_spim1_inst_MISO   : in    std_logic                     := 'X';             -- hps_io_spim1_inst_MISO
            hps_0_hps_io_hps_io_spim1_inst_SS0    : out   std_logic;                                        -- hps_io_spim1_inst_SS0
            hps_0_hps_io_hps_io_uart0_inst_RX     : in    std_logic                     := 'X';             -- hps_io_uart0_inst_RX
            hps_0_hps_io_hps_io_uart0_inst_TX     : out   std_logic;                                        -- hps_io_uart0_inst_TX
            hps_0_hps_io_hps_io_i2c1_inst_SDA     : inout std_logic                     := 'X';             -- hps_io_i2c1_inst_SDA
            hps_0_hps_io_hps_io_i2c1_inst_SCL     : inout std_logic                     := 'X';             -- hps_io_i2c1_inst_SCL
            memory_mem_a                          : out   std_logic_vector(14 downto 0);                    -- mem_a
            memory_mem_ba                         : out   std_logic_vector(2 downto 0);                     -- mem_ba
            memory_mem_ck                         : out   std_logic;                                        -- mem_ck
            memory_mem_ck_n                       : out   std_logic;                                        -- mem_ck_n
            memory_mem_cke                        : out   std_logic;                                        -- mem_cke
            memory_mem_cs_n                       : out   std_logic;                                        -- mem_cs_n
            memory_mem_ras_n                      : out   std_logic;                                        -- mem_ras_n
            memory_mem_cas_n                      : out   std_logic;                                        -- mem_cas_n
            memory_mem_we_n                       : out   std_logic;                                        -- mem_we_n
            memory_mem_reset_n                    : out   std_logic;                                        -- mem_reset_n
            memory_mem_dq                         : inout std_logic_vector(31 downto 0) := (others => 'X'); -- mem_dq
            memory_mem_dqs                        : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs
            memory_mem_dqs_n                      : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs_n
            memory_mem_odt                        : out   std_logic;                                        -- mem_odt
            memory_mem_dm                         : out   std_logic_vector(3 downto 0);                     -- mem_dm
            memory_oct_rzqin                      : in    std_logic                     := 'X';             -- oct_rzqin
            reset_reset_n                         : in    std_logic                     := 'X';             -- reset_n
            atari_dma_dma_fetch                   : out   std_logic;                                        -- dma_fetch
            atari_dma_dma_read_enable             : out   std_logic;                                        -- dma_read_enable
            atari_dma_dma_32bit_write_enable      : out   std_logic;                                        -- dma_32bit_write_enable
            atari_dma_dma_8bit_write_enable       : out   std_logic;                                        -- dma_8bit_write_enable
            atari_dma_dma_addr                    : out   std_logic_vector(23 downto 0);                    -- dma_addr
            atari_dma_dma_write_data              : out   std_logic_vector(31 downto 0);                    -- dma_write_data
            atari_dma_memory_ready_dma            : in    std_logic                     := 'X';             -- memory_ready_dma
            atari_dma_dma_memory_data             : in    std_logic_vector(31 downto 0) := (others => 'X');  -- dma_memory_data
            arm_regs_pokey_enable                 : in    std_logic                     := 'X';             -- pokey_enable
            arm_regs_in1                          : in    std_logic_vector(31 downto 0) := (others => 'X'); -- in1
            arm_regs_in2                          : in    std_logic_vector(31 downto 0) := (others => 'X'); -- in2
            arm_regs_in3                          : in    std_logic_vector(31 downto 0) := (others => 'X'); -- in3
            arm_regs_in4                          : in    std_logic_vector(31 downto 0) := (others => 'X'); -- in4
            arm_regs_out1                         : out   std_logic_vector(31 downto 0);                    -- out1
            arm_regs_out2                         : out   std_logic_vector(31 downto 0);                    -- out2
            arm_regs_out3                         : out   std_logic_vector(31 downto 0);                    -- out3
            arm_regs_out4                         : out   std_logic_vector(31 downto 0);                    -- out4
            arm_regs_out5                         : out   std_logic_vector(31 downto 0);                    -- out5
            arm_regs_out6                         : out   std_logic_vector(31 downto 0);                    -- out6
            arm_regs_sio_data_in                  : out   std_logic;                                        -- sio_data_in
            arm_regs_sio_command                  : in    std_logic                     := 'X';             -- sio_command
            arm_regs_sio_data_out                 : in    std_logic    				
        );
    end component atari_hps;
	
	component pll_pal is
	port (
		refclk   : in  std_logic;
		rst      : in  std_logic;
		outclk_0 : out std_logic;
		outclk_1 : out std_logic;
		locked   : out std_logic
	);
	end component;

	
-- PLL
signal CLK : std_logic;
signal CLK_HALF : std_logic;
signal PLL_LOCKED : std_logic;

-- VGA
signal VGA_CS_RAW : std_logic;
signal VGA_BLANK : std_logic;

-- AUDIO
signal AUDIO_LEFT : std_logic_vector(15 downto 0);
signal AUDIO_RIGHT : std_logic_vector(15 downto 0);

-- DMA
	signal atari_dma_fetch              : std_logic;
	signal atari_dma_read_enable        : std_logic;
	signal atari_dma_32bit_write_enable : std_logic;
	signal atari_dma_8bit_write_enable  : std_logic;
	signal atari_dma_addr               : std_logic_vector(23 downto 0);
	signal atari_dma_write_data         : std_logic_vector(31 downto 0);
	signal atari_memory_ready_dma       : std_logic;
	signal atari_dma_memory_data        : std_logic_vector(31 downto 0);

-- ARM REGS
	signal sio_data_in : std_logic;
	signal sio_data_out : std_logic;
	signal sio_command : std_logic;
	signal out1 : std_logic_vector(31 downto 0);
	signal out2 : std_logic_vector(31 downto 0);
	signal out3 : std_logic_vector(31 downto 0);
	signal out4 : std_logic_vector(31 downto 0);
	signal out5 : std_logic_vector(31 downto 0);
	signal out6 : std_logic_vector(31 downto 0);

-- keyboard/paddles/joysticks
	-- pokey keyboard
	SIGNAL KEYBOARD_SCAN : std_logic_vector(5 downto 0);
	SIGNAL KEYBOARD_RESPONSE : std_logic_vector(1 downto 0);
	
	-- gtia consol keys
	SIGNAL CONSOL_START : std_logic;
	SIGNAL CONSOL_SELECT : std_logic;
	SIGNAL CONSOL_OPTION : std_logic;
	SIGNAL FKEYS : std_logic_vector(11 downto 0);

	signal PS2_KEYS : STD_LOGIC_VECTOR(511 downto 0);
	signal PS2_KEYS_NEXT : STD_LOGIC_VECTOR(511 downto 0);

	-- paddles
	signal paddle_mode_next : std_logic;
	signal paddle_mode_reg : std_logic;
	signal		JOY1X : std_logic_vector(7 downto 0);
	signal		JOY1Y : std_logic_vector(7 downto 0);
	signal		JOY2X : std_logic_vector(7 downto 0);
	signal		JOY2Y : std_logic_vector(7 downto 0);
	
	signal JOY1 : std_logic_vector(5 downto 0);
	signal JOY2 : std_logic_vector(5 downto 0);
	signal JOY1_n : std_logic_vector(4 downto 0);
	signal JOY2_n : std_logic_vector(4 downto 0);	
	
	signal pokey_enable : std_logic;

	-- system control from zpu
	signal ram_select : std_logic_vector(2 downto 0);
	signal reset_atari : std_logic;
	signal pause_atari : std_logic;
	SIGNAL speed_6502 : std_logic_vector(5 downto 0);
	signal emulated_cartridge_select: std_logic_vector(5 downto 0);

	-- turbo freezer!
	signal freezer_enable : std_logic;
	signal freezer_activate: std_logic;
	
BEGIN
	-- safe defaults
	LED <= "1010";

	SI5338_SCL <= 'Z';
	SI5338_SDA <= 'Z';

	TEMP_CS_n <= '1';
	TEMP_DIN <= 'Z';
	TEMP_SCLK <= 'Z';

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
pll : pll_pal
	PORT MAP(refclk => OSC_50_B3B,
	rst => not(reset_n),
	outclk_0 => CLK,
	outclk_1 => CLK_HALF,
	locked => PLL_LOCKED);

	-- vga
	VGA_HS <= not(VGA_CS_RAW);
	VGA_VS <= '1';
	VGA_SYNC_N <= not(VGA_CS_RAW);
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
		internal_ram => 256*4*320
	)
	PORT MAP
	(
		CLK => CLK,
		RESET_N => PLL_LOCKED and not(reset_atari),

		-- VIDEO OUT - PAL/NTSC, original Atari timings approx (may be higher res)
		VIDEO_VS => open,
		VIDEO_HS => open,
		VIDEO_CS => VGA_CS_RAW,
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
		AUDIO_L => AUDIO_LEFT,
		AUDIO_R => AUDIO_RIGHT,

		-- JOYSTICK
		JOY1_n => JOY1_n,
		JOY2_n => JOY2_n,
		
		PADDLE0 => signed(joy1x),
		PADDLE1 => signed(joy1y),
		PADDLE2 => signed(joy2x),
		PADDLE3 => signed(joy2y),

		-- Pokey keyboard matrix
		-- Standard component available to connect this to PS2
		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,
		KEYBOARD_SCAN => KEYBOARD_SCAN,

		-- SIO
		SIO_COMMAND => sio_command,
		SIO_RXD => sio_data_in,
		SIO_TXD => sio_data_out,

		-- GTIA consol
		CONSOL_OPTION => CONSOL_OPTION,
		CONSOL_SELECT => CONSOL_SELECT,
		CONSOL_START => CONSOL_START,

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

		DMA_FETCH => atari_dma_fetch,
		DMA_READ_ENABLE => atari_dma_read_enable,
		DMA_32BIT_WRITE_ENABLE => atari_dma_32bit_write_enable,
		DMA_16BIT_WRITE_ENABLE => '0',
		DMA_8BIT_WRITE_ENABLE => atari_dma_8bit_write_enable,
		DMA_ADDR => atari_dma_addr,
		DMA_WRITE_DATA => atari_dma_write_data,
		MEMORY_READY_DMA => atari_memory_ready_dma,
		DMA_MEMORY_DATA => atari_dma_memory_data,

		-- Special config params
   	RAM_SELECT => ram_select,
		PAL => '1',
		HALT => pause_atari,
		THROTTLE_COUNT_6502 => speed_6502,
		emulated_cartridge_select => emulated_cartridge_select,
		freezer_enable => freezer_enable,
		freezer_activate => freezer_activate
	);

    hps_bridge : component atari_hps
        port map (
            clk_clk                               => CLK,                               --             clk.clk
            hps_0_h2f_reset_reset_n               => open,               -- hps_0_h2f_reset.reset_n
            hps_0_hps_io_hps_io_emac1_inst_TX_CLK => HPS_ENET_GTX_CLK, --    hps_0_hps_io.hps_io_emac1_inst_TX_CLK
            hps_0_hps_io_hps_io_emac1_inst_TXD0   => HPS_ENET_TX_DATA(0),   --                .hps_io_emac1_inst_TXD0
            hps_0_hps_io_hps_io_emac1_inst_TXD1   => HPS_ENET_TX_DATA(1),   --                .hps_io_emac1_inst_TXD1
            hps_0_hps_io_hps_io_emac1_inst_TXD2   => HPS_ENET_TX_DATA(2),   --                .hps_io_emac1_inst_TXD2
            hps_0_hps_io_hps_io_emac1_inst_TXD3   => HPS_ENET_TX_DATA(3),   --                .hps_io_emac1_inst_TXD3
            hps_0_hps_io_hps_io_emac1_inst_RXD0   => HPS_ENET_RX_DATA(0),   --                .hps_io_emac1_inst_RXD0
            hps_0_hps_io_hps_io_emac1_inst_MDIO   => HPS_ENET_MDIO,   --                .hps_io_emac1_inst_MDIO
            hps_0_hps_io_hps_io_emac1_inst_MDC    => HPS_ENET_MDC,    --                .hps_io_emac1_inst_MDC
            hps_0_hps_io_hps_io_emac1_inst_RX_CTL => HPS_ENET_RX_DV, --                .hps_io_emac1_inst_RX_CTL
            hps_0_hps_io_hps_io_emac1_inst_TX_CTL => HPS_ENET_TX_EN, --                .hps_io_emac1_inst_TX_CTL
            hps_0_hps_io_hps_io_emac1_inst_RX_CLK => HPS_ENET_RX_CLK, --                .hps_io_emac1_inst_RX_CLK
            hps_0_hps_io_hps_io_emac1_inst_RXD1   => HPS_ENET_RX_DATA(1),   --                .hps_io_emac1_inst_RXD1
            hps_0_hps_io_hps_io_emac1_inst_RXD2   => HPS_ENET_RX_DATA(2),   --                .hps_io_emac1_inst_RXD2
            hps_0_hps_io_hps_io_emac1_inst_RXD3   => HPS_ENET_RX_DATA(3),   --                .hps_io_emac1_inst_RXD3
            hps_0_hps_io_hps_io_qspi_inst_IO0     => HPS_FLASH_DATA(0),     --                .hps_io_qspi_inst_IO0
            hps_0_hps_io_hps_io_qspi_inst_IO1     => HPS_FLASH_DATA(1),     --                .hps_io_qspi_inst_IO1
            hps_0_hps_io_hps_io_qspi_inst_IO2     => HPS_FLASH_DATA(2),     --                .hps_io_qspi_inst_IO2
            hps_0_hps_io_hps_io_qspi_inst_IO3     => HPS_FLASH_DATA(3),     --                .hps_io_qspi_inst_IO3
            hps_0_hps_io_hps_io_qspi_inst_SS0     => HPS_FLASH_NCSO,     --                .hps_io_qspi_inst_SS0
            hps_0_hps_io_hps_io_qspi_inst_CLK     => HPS_FLASH_DCLK,     --                .hps_io_qspi_inst_CLK
            hps_0_hps_io_hps_io_sdio_inst_CMD     => HPS_SD_CMD,     --                .hps_io_sdio_inst_CMD
            hps_0_hps_io_hps_io_sdio_inst_D0      => HPS_SD_DATA(0),      --                .hps_io_sdio_inst_D0
            hps_0_hps_io_hps_io_sdio_inst_D1      => HPS_SD_DATA(1),      --                .hps_io_sdio_inst_D1
            hps_0_hps_io_hps_io_sdio_inst_CLK     => HPS_SD_CLK,     --                .hps_io_sdio_inst_CLK
            hps_0_hps_io_hps_io_sdio_inst_D2      => HPS_SD_DATA(2),      --                .hps_io_sdio_inst_D2
            hps_0_hps_io_hps_io_sdio_inst_D3      => HPS_SD_DATA(3),      --                .hps_io_sdio_inst_D3
            hps_0_hps_io_hps_io_usb1_inst_D0      => HPS_USB_DATA(0),      --                .hps_io_usb1_inst_D0
            hps_0_hps_io_hps_io_usb1_inst_D1      => HPS_USB_DATA(1),      --                .hps_io_usb1_inst_D1
            hps_0_hps_io_hps_io_usb1_inst_D2      => HPS_USB_DATA(2),      --                .hps_io_usb1_inst_D2
            hps_0_hps_io_hps_io_usb1_inst_D3      => HPS_USB_DATA(3),      --                .hps_io_usb1_inst_D3
            hps_0_hps_io_hps_io_usb1_inst_D4      => HPS_USB_DATA(4),      --                .hps_io_usb1_inst_D4
            hps_0_hps_io_hps_io_usb1_inst_D5      => HPS_USB_DATA(5),      --                .hps_io_usb1_inst_D5
            hps_0_hps_io_hps_io_usb1_inst_D6      => HPS_USB_DATA(6),      --                .hps_io_usb1_inst_D6
            hps_0_hps_io_hps_io_usb1_inst_D7      => HPS_USB_DATA(7),      --                .hps_io_usb1_inst_D7
            hps_0_hps_io_hps_io_usb1_inst_CLK     => HPS_USB_CLKOUT,     --                .hps_io_usb1_inst_CLK
            hps_0_hps_io_hps_io_usb1_inst_STP     => HPS_USB_STP,     --                .hps_io_usb1_inst_STP
            hps_0_hps_io_hps_io_usb1_inst_DIR     => HPS_USB_DIR,     --                .hps_io_usb1_inst_DIR
            hps_0_hps_io_hps_io_usb1_inst_NXT     => HPS_USB_NXT,     --                .hps_io_usb1_inst_NXT
            hps_0_hps_io_hps_io_spim0_inst_CLK    => HPS_LCM_SPIM_CLK,    --                .hps_io_spim0_inst_CLK
            hps_0_hps_io_hps_io_spim0_inst_MOSI   => HPS_LCM_SPIM_MOSI,   --                .hps_io_spim0_inst_MOSI
            hps_0_hps_io_hps_io_spim0_inst_MISO   => HPS_LCM_SPIM_MISO,   --                .hps_io_spim0_inst_MISO
            hps_0_hps_io_hps_io_spim0_inst_SS0    => HPS_LCM_SPIM_SS,    --                .hps_io_spim0_inst_SS0
            hps_0_hps_io_hps_io_spim1_inst_CLK    => HPS_SPIM_CLK,    --                .hps_io_spim1_inst_CLK
            hps_0_hps_io_hps_io_spim1_inst_MOSI   => HPS_SPIM_MOSI,   --                .hps_io_spim1_inst_MOSI
            hps_0_hps_io_hps_io_spim1_inst_MISO   => HPS_SPIM_MISO,   --                .hps_io_spim1_inst_MISO
            hps_0_hps_io_hps_io_spim1_inst_SS0    => HPS_SPIM_SS,    --                .hps_io_spim1_inst_SS0
            hps_0_hps_io_hps_io_uart0_inst_RX     => HPS_UART_RX,     --                .hps_io_uart0_inst_RX
            hps_0_hps_io_hps_io_uart0_inst_TX     => HPS_UART_TX,     --                .hps_io_uart0_inst_TX
            hps_0_hps_io_hps_io_i2c1_inst_SDA     => HPS_I2C_SDA,     --                .hps_io_i2c1_inst_SDA
            hps_0_hps_io_hps_io_i2c1_inst_SCL     => HPS_I2C_CLK,     --                .hps_io_i2c1_inst_SCL
				memory_mem_a => HPS_DDR3_A, -- memory.mem_a
				memory_mem_ba => HPS_DDR3_BA, -- .mem_ba
				memory_mem_ck => HPS_DDR3_CK_P, -- .mem_ck
				memory_mem_ck_n => HPS_DDR3_CK_N, -- .mem_ck_n
				memory_mem_cke => HPS_DDR3_CKE, -- .mem_cke
				memory_mem_cs_n => HPS_DDR3_CS_N, -- .mem_cs_n
				memory_mem_ras_n => HPS_DDR3_RAS_N, -- .mem_ras_n
				memory_mem_cas_n => HPS_DDR3_CAS_N, -- .mem_cas_n
				memory_mem_we_n => HPS_DDR3_WE_N, -- .mem_we_n
				memory_mem_reset_n => HPS_DDR3_RESET_N, -- .mem_reset_n
				memory_mem_dq => HPS_DDR3_DQ, -- .mem_dq
				memory_mem_dqs => HPS_DDR3_DQS_P, -- .mem_dqs
				memory_mem_dqs_n => HPS_DDR3_DQS_N, -- .mem_dqs_n
				memory_mem_odt => HPS_DDR3_ODT, -- .mem_odt
				memory_mem_dm => HPS_DDR3_DM, -- .mem_dm
				memory_oct_rzqin => HPS_DDR3_RZQ, -- .oct_rzqin
            reset_reset_n                         => PLL_LOCKED,                         --           reset.reset_n
				atari_dma_dma_fetch => atari_dma_fetch,
				atari_dma_dma_read_enable => atari_dma_read_enable,
				atari_dma_dma_32bit_write_enable => atari_dma_32bit_write_enable,
				atari_dma_dma_8bit_write_enable => atari_dma_8bit_write_enable,
				atari_dma_dma_addr => atari_dma_addr,
				atari_dma_dma_write_data => atari_dma_write_data,
				atari_dma_memory_ready_dma => atari_memory_ready_dma,
				atari_dma_dma_memory_data => atari_dma_memory_data,
            arm_regs_pokey_enable                 => pokey_enable,                 --        arm_regs.pokey_enable
            arm_regs_in1                          => X"000"&
			"00"&ps2_keys(16#76#)&ps2_keys(16#5A#)&ps2_keys(16#174#)&ps2_keys(16#16B#)&ps2_keys(16#172#)&ps2_keys(16#175#)& -- (esc)FLRDU
			FKEYS,                          --                .in1
            arm_regs_in2                          => (others=>'0'),                          --                .in2
            arm_regs_in3                          => (others=>'0'),                          --                .in3
            arm_regs_in4                          => (others=>'0'),                          --                .in4
            arm_regs_out1                         => out1,                         --                .out1
            arm_regs_out2                         => out2,                         --                .out2
            arm_regs_out3                         => out3,                         --                .out3
            arm_regs_out4                         => out4,                         --                .out4
            arm_regs_out5                         => out5,                         --                .out5
            arm_regs_out6                         => out6,                         --                .out6
            arm_regs_sio_data_in                  => sio_data_in,                  --                .sio_data_in
            arm_regs_sio_command                  => sio_command,                  --                .sio_command
            arm_regs_sio_data_out                 => sio_data_out                  --                .sio_data_out				
		);	

	pause_atari <= out1(0);
	reset_atari <= out1(1);
	speed_6502 <= out1(7 downto 2);
	ram_select <= out1(10 downto 8);
	emulated_cartridge_select <= out1(22 downto 17);
	freezer_enable <= out1(25);

	JOY1 <= out2(5 downto 4)&out2(0)&out2(1)&out2(2)&out2(3);
	JOY2 <= out3(5 downto 4)&out3(0)&out3(1)&out3(2)&out3(3);
	
	JOY1X <= out5(7 downto 0);
	JOY1Y <= out5(15 downto 8);
	JOY2X <= out5(23 downto 16);
	JOY2Y <= out5(31 downto 24);
	
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

keyboard_map1 : entity work.ps2_to_atari800
	GENERIC MAP
	(
		ps2_enable => 0,
		direct_enable => 1
	)
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,
		
		INPUT => out4,
		
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

-- hack for paddles
	process(clk,PLL_LOCKED)
	begin
		if (PLL_LOCKED = '0') then
			paddle_mode_reg <= '0';
		elsif (clk'event and clk='1') then
			paddle_mode_reg <= paddle_mode_next;
		end if;
	end process;
	
	enable_179_clock_div_zpu_pokey : entity work.enable_divider
	generic map (COUNT=>32) -- cycle_length
	port map(clk=>clk,reset_n=>reset_n,enable_in=>'1',enable_out=>pokey_enable);

-- sound
audio_codec_config_over_i2c : entity work.i2c_loader
GENERIC MAP(device_address => 26,
			log2_divider => 6,
			num_retries => 0
			)
PORT MAP(CLK => CLK,
		 nRESET => PLL_LOCKED,
		 I2C_SCL => AUD_I2C_SCLK,
		 I2C_SDA => AUD_I2C_SDAT);

audio_codec_data : entity work.i2sslave
PORT MAP(CLK_HALF => CLK_HALF,
		 BCLK => AUD_BCLK,
		 DACLRC => AUD_DACLRCK,
		 LEFT_IN => '0'&AUDIO_LEFT(15 downto 1), -- TODO...
		 RIGHT_IN => '0'&AUDIO_RIGHT(15 downto 1),
		 MCLK_2 => AUD_XCK,
		 DACDAT => AUD_DACDAT);

	AUD_ADCDAT <= 'Z';
	AUD_ADCLRCK <= 'Z';
	--AUD_BCLK <= 'Z';
	--AUD_DACDAT <= '0';
	--AUD_DACLRCK <= 'Z';
	AUD_MUTE <= '1';
	--AUD_XCK <= '0';

--	AUD_I2C_SCLK <= '0';
--	AUD_I2C_SDAT <= 'Z';

END vhdl;

