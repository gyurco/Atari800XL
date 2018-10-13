-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_MISC.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
USE ieee.math_real.realmax;

LIBRARY work;

ENTITY atari800core_eclaireXL IS 
	GENERIC
	(
		-- For initial port may help to have no
		internal_rom : integer := 1;  -- if 0 expects it in sdram,is 1:16k os+basic, is 2:... TODO
		internal_ram : integer := 16384  -- at start of memory map
	);
	PORT
	(
		CLOCK_50 :  IN  STD_LOGIC;

		GPIO :  INOUT  STD_LOGIC_VECTOR(16 DOWNTO 0);

		PBI_A :  OUT  STD_LOGIC_VECTOR(15 DOWNTO 0);
		PBI_D :  INOUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		PBI_CLK :  OUT  STD_LOGIC;
		PBI_RW_N :  OUT  STD_LOGIC;
		PBI_EXTSEL_N :  IN  STD_LOGIC;
		PBI_MPD_N :  IN  STD_LOGIC;
		PBI_REF_N :  INOUT  STD_LOGIC;
		PBI_IRQ_N :  IN  STD_LOGIC;
		PBI_RST_N :  OUT  STD_LOGIC;
		PBI_RAS_N :  OUT  STD_LOGIC;    
		PBI_CAS_N :  OUT  STD_LOGIC;    
		PBI_CASINH_N :  OUT  STD_LOGIC; 

		CART_S4_N :  OUT  STD_LOGIC;
		CART_S5_N :  OUT  STD_LOGIC;
		CART_RD4 :  IN  STD_LOGIC;
		CART_RD5 :  IN  STD_LOGIC;
		CART_CCTL_N :  OUT  STD_LOGIC;

		SIO_CLOCKIN :  INOUT  STD_LOGIC; -- bidirectional clock!
		SIO_CLOCKOUT :  OUT  STD_LOGIC;
		SIO_IN :  INOUT  STD_LOGIC;
		SIO_IRQ :  IN  STD_LOGIC;
		SIO_OUT :  OUT  STD_LOGIC;
		SIO_COMMAND :  INOUT  STD_LOGIC;
		SIO_PROCEED :  IN  STD_LOGIC;
		SIO_MOTOR_RAW :  INOUT  STD_LOGIC;

		SER_CMD :  OUT  STD_LOGIC;
		SER_TX :  OUT  STD_LOGIC;
		SER_RX :  IN  STD_LOGIC;

		PORTA :  INOUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		PORTB :  INOUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		TRIG :  IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
		POTIN :  IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
		POTRESET :  OUT  STD_LOGIC;

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
		DRAM_ADDR :  OUT  STD_LOGIC_VECTOR(12 DOWNTO 0);
		DRAM_DQ :  INOUT  STD_LOGIC_VECTOR(15 DOWNTO 0);

		SD_WRITEPROTECT : IN STD_LOGIC;
		SD_DETECT : IN STD_LOGIC;
		SD_DAT1 : OUT STD_LOGIC;
		SD_DAT0 :  IN  STD_LOGIC;
		SD_CLK :  OUT  STD_LOGIC;
		SD_CMD :  OUT  STD_LOGIC;
		SD_DAT3 :  OUT  STD_LOGIC;
		SD_DAT2 : OUT STD_LOGIC;

		VGA_VS :  OUT  STD_LOGIC;
		VGA_HS :  OUT  STD_LOGIC;
		VGA_B :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		VGA_G :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		VGA_R :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);

		HD_TX2P : OUT STD_LOGIC;
		HD_TX2N : OUT STD_LOGIC;
		HD_TX1P : OUT STD_LOGIC;
		HD_TX1N : OUT STD_LOGIC;
		HD_TX0P : OUT STD_LOGIC;
		HD_TX0N : OUT STD_LOGIC;
		HD_CLKP : OUT STD_LOGIC;
		HD_CLKN : OUT STD_LOGIC;

		VGA_BLANK_N : OUT STD_LOGIC;
		VGA_SYNC_N : OUT STD_LOGIC;
		VGA_CLK : OUT STD_LOGIC;
		
		AUDIO_LEFT : OUT STD_LOGIC;
		AUDIO_RIGHT : OUT STD_LOGIC;

		USB2DM: INOUT STD_LOGIC;
		USB2DP: INOUT STD_LOGIC;
		USB1DM: INOUT STD_LOGIC;
		USB1DP: INOUT STD_LOGIC;
		
		ADC_CS : OUT STD_LOGIC;
		ADC_SCLK : OUT STD_LOGIC;
		ADC_DOUT : IN STD_LOGIC;
		ADC_DIN : OUT STD_LOGIC;

		VID_SDA : INOUT STD_LOGIC; --PCA9540
		VID_SCL : INOUT STD_LOGIC;

		CLKGEN_SDA : INOUT STD_LOGIC; -- SI5351
		CLKGEN_SCL : INOUT STD_LOGIC;
		CLKGEN_CLK0 : IN STD_LOGIC;
		CLKGEN_CLK2 : IN STD_LOGIC
	);
END atari800core_eclaireXL;

ARCHITECTURE vhdl OF atari800core_eclaireXL IS 

component hq_dac
port (
  reset :in std_logic;
  clk :in std_logic;
  clk_ena : in std_logic;
  pcm_in : in std_logic_vector(19 downto 0);
  dac_out : out std_logic
);
end component;

component pll_gclk
	port (
		refclk   : in  std_logic := '0'; --  refclk.clk
		rst      : in  std_logic := '0'; --   reset.reset
		outclk_0 : out std_logic        -- outclk0.clk
	);
end component;

component pll_hdmi
	port (
		refclk   : in  std_logic := '0'; --  refclk.clk
		rst      : in  std_logic := '0'; --   reset.reset
		outclk_0 : out std_logic;        -- outclk0.clk
		outclk_1 : out std_logic;        -- outclk1.clk
		locked   : out std_logic         --  locked.export
	);
end component;

component pll_acore
	port (
		refclk   : in  std_logic := '0'; --  refclk.clk
		rst      : in  std_logic := '0'; --   reset.reset
		outclk_0 : out std_logic;        -- outclk0.clk
		outclk_1 : out std_logic;        -- outclk1.clk
		outclk_2 : out std_logic;        -- outclk2.clk
		outclk_3 : out std_logic;        -- outclk3.clk
		locked   : out std_logic;         --  locked.export
		reconfig_to_pll   : in  std_logic_vector(63 downto 0) := (others => '0'); --   reconfig_to_pll.reconfig_to_pll
		reconfig_from_pll : out std_logic_vector(63 downto 0)                     -- reconfig_from_pll.reconfig_from_pll
	);
end component;

component pll_acore_reconfig
	port (
		mgmt_clk          : in  std_logic                     := '0';             --          mgmt_clk.clk
		mgmt_reset        : in  std_logic                     := '0';             --        mgmt_reset.reset
		mgmt_waitrequest  : out std_logic;                                        -- mgmt_avalon_slave.waitrequest
		mgmt_read         : in  std_logic                     := '0';             --                  .read
		mgmt_write        : in  std_logic                     := '0';             --                  .write
		mgmt_readdata     : out std_logic_vector(31 downto 0);                    --                  .readdata
		mgmt_address      : in  std_logic_vector(5 downto 0)  := (others => '0'); --                  .address
		mgmt_writedata    : in  std_logic_vector(31 downto 0) := (others => '0'); --                  .writedata
		reconfig_to_pll   : out std_logic_vector(63 downto 0);                    --   reconfig_to_pll.reconfig_to_pll
		reconfig_from_pll : in  std_logic_vector(63 downto 0) := (others => '0')  -- reconfig_from_pll.reconfig_from_pll
	);
end component;

component clkctrl is
	port (
		inclk  : in  std_logic := '0'; --  altclkctrl_input.inclk
		ena    : in  std_logic := '0'; --                  .ena
		outclk : out std_logic         -- altclkctrl_output.outclk
	);
end component;

component ddioclkctrl is
	port (
		inclk3x   : in  std_logic                    := '0';             --  altclkctrl_input.inclk3x
		inclk2x   : in  std_logic                    := '0';             --                  .inclk2x
		inclk1x   : in  std_logic                    := '0';             --                  .inclk1x
		inclk0x   : in  std_logic                    := '0';             --                  .inclk0x
		clkselect : in  std_logic_vector(1 downto 0) := (others => '0'); --                  .clkselect
		ena       : in  std_logic                    := '0';             --                  .ena
		outclk    : out std_logic                                        -- altclkctrl_output.outclk
	);
end component;

component pll_usb is
	port (
		refclk   : in  std_logic := '0'; --  refclk.clk
		rst      : in  std_logic := '0'; --   reset.reset
		outclk_0 : out std_logic;        -- outclk0.clk
		outclk_1 : out std_logic;        -- outclk1.clk
		locked   : out std_logic         --  locked.export
	);
end component;

component pll_fifo IS
	PORT
	(
		data		: IN STD_LOGIC_VECTOR (37 DOWNTO 0);
		rdclk		: IN STD_LOGIC ;
		rdreq		: IN STD_LOGIC ;
		wrclk		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (37 DOWNTO 0);
		rdempty		: OUT STD_LOGIC 
	);
END component;

component sfl is
	port (
		asmi_access_granted : in  std_logic                    := '0';             -- asmi_access_granted.asmi_access_granted
		asmi_access_request : out std_logic;                                       -- asmi_access_request.asmi_access_request
		data_in             : in  std_logic_vector(3 downto 0) := (others => '0'); --             data_in.data_in
		data_oe             : in  std_logic_vector(3 downto 0) := (others => '0'); --             data_oe.data_oe
		data_out            : out std_logic_vector(3 downto 0);                    --            data_out.data_out
		dclk_in             : in  std_logic                    := '0';             --             dclk_in.dclkin
		ncso_in             : in  std_logic                    := '0';             --             ncso_in.scein
		noe_in              : in  std_logic                    := '0'              --              noe_in.noe
	);
end component;


	-- SYSTEM
	SIGNAL GCLOCK_50 : STD_LOGIC; -- Only 2 fplls can use the pin!
	SIGNAL CLK : STD_LOGIC;
	SIGNAL CLK_1x : STD_LOGIC;
	SIGNAL CLK_114 : STD_LOGIC;
	SIGNAL CLK_SDRAM : STD_LOGIC;
	SIGNAL RESET_N : STD_LOGIC;
	signal SDRAM_RESET_N : std_logic;
	SIGNAL PLL_LOCKED : STD_LOGIC;

 	SIGNAL CLK_PIXEL_IN : STD_LOGIC;
 	SIGNAL CLK_HDMI_IN : STD_LOGIC;

	SIGNAL CLK_raw : STD_LOGIC;
	SIGNAL CLK_1x_raw : STD_LOGIC;
	SIGNAL CLK_114_raw : STD_LOGIC;
	SIGNAL DRAM_CLK_raw : STD_LOGIC;

	SIGNAL PLL_ENABLE : STD_LOGIC;

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
	SIGNAL	PORTB_DIR_OUT :  STD_LOGIC_VECTOR(7 DOWNTO 0);
	
	-- GTIA
	signal GTIA_TRIG : std_logic_vector(3 downto 0);
	
	-- ANTIC
	signal ANTIC_LIGHTPEN : std_logic;
	signal ANTIC_TURBO : std_logic;
	
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
	SIGNAL	ROM_WRITE_ENABLE :  STD_LOGIC;

	-- SDRAM
	signal SDRAM_REQUEST : std_logic;
	signal SDRAM_REQUEST_COMPLETE : std_logic;
	signal SDRAM_READ_ENABLE :  STD_LOGIC;
	signal SDRAM_WRITE_ENABLE : std_logic;
	signal SDRAM_ADDR : STD_LOGIC_VECTOR(22 DOWNTO 0);
	signal SDRAM_DO : STD_LOGIC_VECTOR(31 DOWNTO 0);
	
	signal ANTIC_REFRESH : std_logic;
	
	-- pokey keyboard
	SIGNAL KEYBOARD_SCAN : std_logic_vector(5 downto 0);
	SIGNAL KEYBOARD_RESPONSE : std_logic_vector(1 downto 0);
	
	-- gtia consol keys
	SIGNAL CONSOL_START : std_logic;
	SIGNAL CONSOL_SELECT : std_logic;
	SIGNAL CONSOL_OPTION : std_logic;
	
	-- SIO
	SIGNAL ASIO_RXD : std_logic;
	SIGNAL ASIO_TXD : std_logic;
	SIGNAL ASIO_CLOCKOUT : std_logic;
	SIGNAL ASIO_CLOCKIN_IN : std_logic;
	SIGNAL ASIO_CLOCKIN_OUT : std_logic;
	SIGNAL ASIO_CLOCKIN_OE : std_logic;

	-- VIDEO
	signal VIDEO_VS : std_logic;
	signal VIDEO_HS : std_logic;
	signal VIDEO_CS : std_logic;
	signal VIDEO_BLANK : std_logic;
	signal VIDEO_BURST : std_logic;
	signal VIDEO_ODD_LINE : std_logic;
		-- post scandoubler...
	signal VIDEO_R : std_logic_vector(7 downto 0);
	signal VIDEO_G : std_logic_vector(7 downto 0);
	signal VIDEO_B : std_logic_vector(7 downto 0);
	signal VIDEO_VSYNC : std_logic;
	signal VIDEO_HSYNC : std_logic;

	-- AUDIO
	signal AUDIO_L_PCM : std_logic_vector(15 downto 0);
	signal AUDIO_R_PCM : std_logic_vector(15 downto 0);

	-- dma/virtual drive
	signal DMA_ADDR_FETCH : std_logic_vector(23 downto 0);
	signal DMA_WRITE_DATA : std_logic_vector(31 downto 0);
	signal DMA_FETCH : std_logic;
	signal DMA_32BIT_WRITE_ENABLE : std_logic;
	signal DMA_16BIT_WRITE_ENABLE : std_logic;
	signal DMA_8BIT_WRITE_ENABLE : std_logic;
	signal DMA_READ_ENABLE : std_logic;
	signal DMA_MEMORY_READY : std_logic;
	signal SNOOP_DATA : std_logic_vector(31 downto 0);
	signal SNOOP_DATA_READY : std_logic;

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

	SIGNAL FKEYS : std_logic_vector(11 downto 0);

	-- system control from zpu
	signal ram_select : std_logic_vector(2 downto 0);
	signal reset_atari_request : std_logic; --just a request since on atari 800 its an antic nmi, while on xl/xe its plumbed to reset
	signal reset_atari : std_logic;         
	signal antic_rnmi_n : std_logic;        
	signal pause_atari : std_logic;
	SIGNAL speed_6502 : std_logic_vector(5 downto 0);
	signal emulated_cartridge_select: std_logic_vector(5 downto 0);
	signal key_type : std_logic;
	signal atari800mode : std_logic;

	-- GPIO
	signal POT_RESET : std_logic;
	signal POT_IN : std_logic_vector(7 downto 0);

	signal PBI_WRITE_ENABLE : std_logic;
	signal PBI_ADDRESS : std_logic_vector(15 downto 0);

	signal pbi_disable : std_logic;
	signal pbi_external : std_logic;
	signal pbi_takeover : std_logic;
	signal pbi_release : std_logic;
	signal pbi_request : std_logic;
	signal pbi_request_complete : std_logic;
	signal pbi_data : std_logic_vector(7 downto 0);

	signal pbi_addr : std_logic_vector(15 downto 0);

	signal enable_179_early : std_logic;

	-- scandoubler
	signal half_scandouble_enable_reg : std_logic;
	signal half_scandouble_enable_next : std_logic;
	signal ATARI_COLOUR : std_logic_vector(7 downto 0);

	signal freezer_enable : std_logic;
	signal freezer_activate: std_logic;

	signal freezer_state: std_logic_vector(2 downto 0);

	signal PS2_KEYS : STD_LOGIC_VECTOR(511 downto 0);
	signal PS2_KEYS_NEXT : STD_LOGIC_VECTOR(511 downto 0);

	-- usb
	signal CLK_USB : std_logic;

	signal USBWireVPin : std_logic_vector(1 downto 0);
	signal USBWireVMin : std_logic_vector(1 downto 0);
	signal USBWireVPout : std_logic_vector(1 downto 0);
	signal USBWireVMout : std_logic_vector(1 downto 0);
	signal USBWireOE_n : std_logic_vector(1 downto 0);

	-- CONFIG
	SIGNAL ROM_IN_RAM : STD_LOGIC;

	-- svideo
	signal svideo_dac_clk : std_logic;
	signal svideo_ecs_clk : std_logic;

	signal svideo_c : std_logic_vector(7 downto 0);
	signal svideo_yout : std_logic_vector(7 downto 0);

	signal svideo_sync_n : std_logic;

	signal comp_n : std_logic;

	-- pbi bus
	signal bus_data_in : std_logic_vector(7 downto 0);
	signal bus_data_out : std_logic_vector(7 downto 0);
	signal bus_data_oe : std_logic;
	signal bus_addr_out : std_logic_vector(15 downto 0);
	signal bus_addr_oe : std_logic;
	signal bus_write_n : std_logic;
	signal bus_s4_n : std_logic;
	signal bus_s5_n : std_logic;
	signal bus_cctl_n : std_logic;
	signal bus_control_oe : std_logic;
	signal bus_refresh_oe : std_logic;
	signal bus_phi2 : std_logic;
	signal bus_cas_n : std_logic;
	signal bus_ras_n : std_logic;
	signal bus_casinh_n : std_logic;
	signal bus_casinh_oe : std_logic;
	signal mpd_n : std_logic;
	signal pbi_debug_data : std_logic_vector(31 downto 0);
	signal pbi_debug_ready : std_logic;
	signal nmi_n : std_logic;
	signal irq_n : std_logic;
	signal rdy : std_logic;
	signal an : std_logic_vector(2 downto 0);

	-- pll switching
	signal pll_state_reg : std_logic_vector(1 downto 0);
	signal pll_state_next : std_logic_vector(1 downto 0);
	constant PLL_STATE_WAIT : std_logic_vector(1 downto 0) := "00";
	constant PLL_STATE_WRITE : std_logic_vector(1 downto 0) := "01";
	constant PLL_STATE_PAUSE : std_logic_vector(1 downto 0) := "10";

	signal pll_write_acore : std_logic;
	signal pll_fifo_data : std_logic_vector(37 downto 0);
	signal pll_fifo_read : std_logic;
	signal pll_fifo_empty : std_logic;

	signal zpu_pll_addr : std_logic_vector(7 downto 2);
	signal zpu_pll_data : std_logic_vector(31 downto 0);
	signal zpu_pll_write : std_logic;

	signal pll_acore_reconfig_to_pll   : std_logic_vector(63 downto 0);
	signal pll_acore_reconfig_from_pll : std_logic_vector(63 downto 0);
	signal pll_acore_locked : std_logic;

	signal pll_hdmi_locked : std_logic;

	signal pll_pause_counter_reg : std_logic_vector(25 downto 0);
	signal pll_pause_counter_next : std_logic_vector(25 downto 0);

	signal pll_enable_reg : std_logic;
	signal pll_enable_next : std_logic;

	-- video settings
	signal pal : std_logic;
	signal scandouble : std_logic;
	signal scanlines : std_logic;
	signal csync : std_logic;
	signal video_mode : std_logic_vector(2 downto 0);
	signal scandoubler_format : std_logic_vector(1 downto 0);

	-- vga on 480p/576p/800x600 (exact!)
	signal adj_hsync : std_logic;
	signal adj_vsync : std_logic;
	signal adj_blank : std_logic;
	signal adj_red : std_logic_vector(7 downto 0);
	signal adj_green : std_logic_vector(7 downto 0);
	signal adj_blue : std_logic_vector(7 downto 0);

	-- hdtv
	signal tmds_h : std_logic_vector(7 downto 0);
	signal tmds_l : std_logic_vector(7 downto 0);

	signal reset_n_next : std_logic;
	signal reset_n_reg : std_logic;
	signal reset_n_reg_sync : std_logic;

	-- video via ddr out (to support HDMI)
	signal DDIO_OUT : std_logic_vector(7 downto 0);

	-- adc
	signal ADC_PBI : std_logic_vector(7 downto 0);
	signal ADC_SIO : std_logic_vector(7 downto 0);
	signal ADC_MICL : std_logic_vector(7 downto 0);
	signal ADC_MICR : std_logic_vector(7 downto 0);
	signal ADC_PBISIO : std_logic_vector(8 downto 0);


	signal state_reg_out : std_logic_vector(1 downto 0);
	signal memory_ready_antic_out :   STD_LOGIC;
	signal memory_ready_cpu_out :   STD_LOGIC;
	signal shared_enable_out :   STD_LOGIC;

	-- spi flash
	signal spi_flash_select : std_logic;
	signal spi_flash_di : std_logic;
	signal spi_do : std_logic;
	signal spi_clk : std_logic;

function to_std_logic(i : in integer) return std_logic is
begin
    if i = 0 then
        return '0';
    end if;
    return '1';
end function;

BEGIN 

	SD_DAT2<='Z';
	SD_DAT1<='Z';

-- ANYTHING NOT CONNECTED...
GPIO(16 downto 12) <= (others=>'Z');
--GPIO(0) <= pbi_takeover;
--GPIO(1) <= pbi_release;
--GPIO(2) <= pbi_disable;
--GPIO(3) <= pbi_external;
--GPIO(4) <= bus_s4_n;
--GPIO(5) <= bus_s5_n;
--GPIO(6) <= bus_cctl_n;
--GPIO(7) <= pbi_request;
--GPIO(8) <= enable_179_early;
--GPIO(9) <= pbi_addr(0);
----GPIO(10) <= sdram_request;
----GPIO(11) <= sdram_request_complete;
----GPIO(12) <= ram_request;
----GPIO(13) <= ram_request_complete;
----GPIO(14) <= rom_request;
----GPIO(15) <= rom_request_complete;
--GPIO(10) <= memory_ready_antic_out;
--GPIO(11) <= dma_memory_ready;
--GPIO(12) <= memory_ready_cpu_out;
--GPIO(13) <= shared_enable_out;
--GPIO(14) <= state_reg_out(0);
--GPIO(15) <= state_reg_out(1);

gpio_debug : entity work.gpio_debug
	port map
	(
		clk=>clk,
		reset_n=>reset_n,
		pbi_debug=>pbi_debug_data,
		pbi_debug_ready=>pbi_debug_ready,
		data_out=>gpio(7 downto 0),
		clk_out=>gpio(8)
	);
gpio(11 downto 9) <= AN;
--GPIO(12) <= memory_ready_antic_out;
--GPIO(13) <= dma_memory_ready;
--GPIO(14) <= memory_ready_cpu_out;
--GPIO(15) <= shared_enable_out;
GPIO(12) <= state_reg_out(0);
GPIO(13) <= state_reg_out(1);

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
		 REFRESH => ANTIC_REFRESH,
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

DRAM_ADDR(12) <= '0';

-- PIA mapping
-- emulate pull-up on command line
--PORTB_IN <= PORTB_OUT;

-- Internal rom/ram
internalromram1 : entity work.internalromram
	GENERIC MAP
	(
		internal_rom => internal_rom,
		internal_ram => internal_ram 
	)
	PORT MAP (
 		clock   => CLK,
		reset_n => RESET_N,

		ROM_ADDR => ROM_ADDR,
		ROM_WR_ENABLE => ROM_WRITE_ENABLE, -- ZPU only, read only for Atari!!
		ROM_DATA_IN => PBI_WRITE_DATA(7 downto 0),
		ROM_REQUEST_COMPLETE => ROM_REQUEST_COMPLETE,
		ROM_REQUEST => ROM_REQUEST,
		ROM_DATA => ROM_DO,
		
		RAM_ADDR => RAM_ADDR,
		RAM_WR_ENABLE => RAM_WRITE_ENABLE,
		RAM_DATA_IN => PBI_WRITE_DATA(7 downto 0),
		RAM_REQUEST_COMPLETE => RAM_REQUEST_COMPLETE,
		RAM_REQUEST => RAM_REQUEST,
		RAM_DATA => RAM_DO(7 downto 0)
	);

	-- JOYSTICK/PADDLES
	-- TODO synchronizers!!!
PORTA_gen:
	for I in 0 to 7 generate
		-- Only drive low, there are pull-ups
		PORTA(I) <= PORTA_OUT(I) when PORTA_DIR_OUT(I)='1' and PORTA_OUT(I)='0' else 'Z';
	end generate PORTA_gen;
	PORTA_IN <= PORTA;

PORTB_gen:
	for I in 0 to 7 generate
		-- Only drive low, there are pull-ups
		PORTB(I) <= PORTB_OUT(I) when PORTB_DIR_OUT(I)='1' and PORTB_OUT(I)='0' else 'Z';
	end generate PORTB_gen;
	PORTB_IN <= PORTB;

	--POT_IN <= "0000"&NOT(POTIN);
	POT_IN <= "0000"&POTIN;
	POTRESET <= POT_RESET;

	GTIA_TRIG <= TRIG;
	ANTIC_LIGHTPEN <= and_reduce(TRIG); -- either joystick button				

	--SIO
	ASIO_CLOCKIN_IN <= SIO_CLOCKIN;
	SIO_CLOCKIN <= ASIO_CLOCKIN_OUT when ASIO_CLOCKIN_OE='1' else 'Z';
	SIO_CLOCKOUT <= ASIO_CLOCKOUT;

	----CB1=SIO_IRQ
	----CB2=SIO_COMMAND
	----CA1=SIO_PROCEED
	----CA2=SIO_MOTOR_RAW
	CB1_in <= SIO_IRQ;
	SIO_COMMAND <= '0' when (CB2_DIR_OUT and NOT(CB2_OUT))='1' else 'Z';
	CB2_in <= SIO_COMMAND;
	CA1_in <= SIO_PROCEED;
	SIO_MOTOR_RAW <= '0' when (CA2_DIR_OUT and NOT(CA2_OUT))='1' else 'Z';
	CA2_in <= SIO_MOTOR_RAW;

	SER_CMD <= CB2_OUT when CB2_DIR_OUT='1' else '1';
	SER_TX <= ASIO_TXD;
	
	--ASIO_RXD <= zpu_sio_txd and SIO_IN and SER_RX;
	ASIO_RXD <= SIO_IN;
	SIO_IN <= '0' when (zpu_sio_txd and SER_RX)='0' else 'Z';
	zpu_sio_rxd <= ASIO_TXD;
	zpu_sio_command <= CB2_OUT when CB2_DIR_OUT='1' else '1';
	SIO_OUT <= ASIO_TXD when ASIO_TXD='0' else 'Z';

	-- Cartridge/PBI
	pbi_disable <= antic_turbo when speed_6502="000001" else '1';
	--pbi_disable <= '1';
	--pbi_disable <= '0' when speed_6502="101001" else '1';
	--pbi_disable <= '0';

bus_adaptor : ENTITY work.pbi6502
PORT MAP
( 
	CLK => clk,
	RESET_N => RESET_N and SDRAM_RESET_N and not(reset_atari),

	-- FPGA side
	ENABLE_179_EARLY =>enable_179_early,

	REQUEST => pbi_request, 
	ADDR_IN => pbi_addr,
	DATA_IN => pbi_write_data(7 downto 0), -- TODO, how about reads, need to expose them on the bus for anything?
	WRITE_IN => pbi_write_enable,
	PORTB => portb_out,
	ANTIC_REFRESH => antic_refresh,
	EXTERNAL_ACCESS => pbi_external,
	TAKEOVER => pbi_takeover,
	RELEASE => pbi_release,
	DISABLE => pbi_disable,
	COMPLETE => pbi_request_complete,
	MPD_N => MPD_N,

	SNOOP_DATA_IN => snoop_data(7 downto 0),
	SNOOP_DATA_READY => snoop_data_ready,

	DATA_OUT => pbi_data,

	DEBUG => pbi_debug_data(24 downto 0),
	DEBUG_READY => pbi_debug_ready,

	-- 6502 side
	BUS_DATA_IN => PBI_D,
	
	BUS_PHI1 => open,
	BUS_PHI2 => bus_phi2,
	--BUS_SUBCYCLE => open,
	BUS_ADDR_OUT => bus_addr_out,
	BUS_ADDR_OE => bus_addr_oe,
	BUS_DATA_OUT => bus_data_out,
	BUS_DATA_OE => bus_data_oe,
	BUS_WRITE_N => bus_write_n,
	BUS_S4_N => bus_s4_n,
	BUS_S5_N => bus_s5_n,
	BUS_CCTL_N => bus_cctl_n,
	BUS_D1XX_N => open, -- FOR ECI TODO
	BUS_CONTROL_OE => bus_control_oe,
	BUS_REFRESH_OE => bus_refresh_oe,

	BUS_CASINH_N => bus_casinh_n,
	BUS_CASINH_OE => bus_casinh_oe,
	BUS_CAS_N => bus_cas_n,
	BUS_RAS_N => bus_ras_n,

	BUS_RD4 => cart_rd4,
	BUS_RD5 => cart_rd5,
	PBI_MPD_N => pbi_mpd_n,
	PBI_REF_N => pbi_ref_n,
	PBI_EXTSEL_N => pbi_extsel_n
);

	--pbi_debug_data(15 downto 0)  <= addr
	--pbi_debug_data(23 downto 16) <= data
	--pbi_debug_data(24) <= r_w_n
	pbi_debug_data(25) <= NMI_N;
	pbi_debug_data(27) <= IRQ_N;
	pbi_debug_data(28) <= RDY;
	pbi_debug_data(29) <= VIDEO_HS;
	pbi_debug_data(30) <= VIDEO_VS;
	pbi_debug_data(31) <= ANTIC_REFRESH;

	CART_CCTL_N <= bus_cctl_n when bus_control_oe='1' else 'Z';
	CART_S4_N <= bus_s4_n when bus_control_oe='1' else 'Z';
	CART_S5_N <= bus_s5_n when bus_control_oe='1' else 'Z';

	PBI_CAS_N <= bus_cas_n when bus_control_oe='1' else 'Z';
	PBI_RAS_N <= bus_ras_n when bus_control_oe='1' else 'Z';
	PBI_CASINH_N <= bus_casinh_n when bus_casinh_oe='1' else 'Z';
	PBI_A <= bus_addr_out when bus_addr_oe='1' else (others=>'Z');
	PBI_D <= bus_data_out when bus_data_oe='1' else (others=>'Z');
	PBI_CLK <= bus_phi2;
	PBI_RW_N <= bus_write_n;
	PBI_REF_N <= '0' when bus_refresh_oe='1' else 'Z';

	PBI_RST_N <= '0' when (RESET_N and not(reset_atari))='0' else '1';

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
	video_bits=>8
)
PORT MAP(CLK => CLK,
		 RESET_N => RESET_N and SDRAM_RESET_N and not(reset_atari),
		 VGA => scandouble,
		 COMPOSITE_ON_HSYNC => csync,
		 colour_enable => half_scandouble_enable_reg,
		 doubled_enable => '1',
	 	 scanlines_on => scanlines,
		 vsync_in => VIDEO_VS,
		 hsync_in => VIDEO_HS,
		 csync_in => VIDEO_CS,
		 pal => PAL,
		 colour_in => ATARI_COLOUR,
		 VSYNC => VIDEO_VSYNC,
		 HSYNC => VIDEO_HSYNC,
		 B => VIDEO_B,
		 G => VIDEO_G,
		 R => VIDEO_R);

pll_acore_inst : pll_acore
PORT MAP(refclk => CLOCK_50,
		 outclk_0 => CLK_114_raw,   -- 4x
		 outclk_1 => DRAM_CLK_raw,  -- 4x 180 degrees
		 outclk_2 => CLK_raw,       -- 2x
		 outclk_3 => CLK_1x_raw,    -- 1x
                 reconfig_to_pll => pll_acore_reconfig_to_pll,
                 reconfig_from_pll => pll_acore_reconfig_from_pll,
		 locked => PLL_ACORE_LOCKED);

clkctrl1: clkctrl 
port map (
	inclk  => CLK_114_raw,
	ena    => pll_enable_reg,
	outclk => CLK_114
);

clkctrl2: clkctrl 
port map (
	inclk  => DRAM_CLK_raw,
	ena    => pll_enable_reg,
	outclk => DRAM_CLK
);

clkctrl3: clkctrl 
port map (
	inclk  => CLK_raw,
	ena    => pll_enable_reg,
	outclk => CLK
);

clkctrl4: clkctrl 
port map (
	inclk  => CLK_1x_raw,
	ena    => pll_enable_reg,
	outclk => CLK_1x
);

SVIDEO_ECS_CLK <= CLK_1x;

-- simple state machine for pll choice
process (CLOCK_50)
begin
	if (CLOCK_50'event and CLOCK_50='1') then
		pll_state_reg <= pll_state_next;
		pll_pause_counter_reg <= pll_pause_counter_next;
		pll_enable_reg <= pll_enable_next;
		reset_n_reg <= reset_n_next;
	end if;
end process;

reset_n <= reset_n_reg_sync;

reset_synchronizer : entity work.synchronizer
	port map (clk=>clk, raw=>reset_n_reg, sync=>reset_n_reg_sync);						

pll_fifo_int : pll_fifo
PORT MAP
(
	data => zpu_pll_addr(7 downto 2)&zpu_pll_data,
	wrclk => CLK,
	wrreq => zpu_pll_write,
	rdclk => CLOCK_50,
	rdreq => pll_fifo_read,
	q => pll_fifo_data,
	rdempty => pll_fifo_empty
);

-- pll_fifo_data, pll_fifo_empty - come from zpu...
process (pll_state_reg, pll_fifo_empty, pll_fifo_data, pll_pause_counter_reg, pll_enable_reg, pll_acore_locked)
begin
	pll_state_next <= pll_state_reg;
	reset_n_next <= pll_acore_locked;
	pll_pause_counter_next <= std_logic_vector(unsigned(pll_pause_counter_reg)+1);

	pll_write_acore <= '0';
	pll_fifo_read <= '0';

	pll_enable_next <= pll_enable_reg;
	
	case pll_state_reg is 
		when PLL_STATE_WAIT =>
			pll_enable_next <= '1';
			if (pll_fifo_empty = '0') then
				pll_state_next <= PLL_STATE_WRITE;
				pll_fifo_read <= '1';
			end if;

		when PLL_STATE_WRITE =>
			pll_write_acore <= '1';
			if (pll_fifo_data(37 downto 32) = "000010") then
				pll_state_next <= PLL_STATE_PAUSE;
				pll_pause_counter_next <= (others=>'0');
				pll_enable_next <= '0';
			else
				pll_state_next <= PLL_STATE_WAIT;
			end if;

		when PLL_STATE_PAUSE =>
			reset_n_next <= '1';
			if (pll_pause_counter_reg(25) = '1') then
				pll_state_next <= PLL_STATE_WAIT;
			end if;

		when others =>
			pll_state_next <= PLL_STATE_WAIT;
		
	end case;

			
end process;

pll_acore_reconfig_inst : pll_acore_reconfig
port map (
	mgmt_clk          => CLOCK_50,
	mgmt_reset        => '0',
	mgmt_waitrequest  => open,
	mgmt_read         => '0',
	mgmt_write        => pll_write_acore,
	mgmt_readdata     => open,
	mgmt_address      => pll_fifo_data(37 downto 32),
	mgmt_writedata    => pll_fifo_data(31 downto 0),
	reconfig_to_pll   => pll_acore_reconfig_to_pll,
	reconfig_from_pll => pll_acore_reconfig_from_pll
);

pll_hdmi_inst : pll_hdmi
PORT MAP(refclk => GCLOCK_50,
		 outclk_0 => CLK_PIXEL_IN, -- 27MHz 
		 outclk_1 => CLK_HDMI_IN,  -- 5*27MHz
		 locked => PLL_HDMI_LOCKED);

--end generate;


CLK_SDRAM <= CLK_114;
SVIDEO_DAC_CLK <= CLK_114; -- only if acore reconfigured to a suitable exact frequency (28.385 or 28.636363)


--		USB2DM: INOUT STD_LOGIC;
--		USB2DP: INOUT STD_LOGIC;
--		USB1DM: INOUT STD_LOGIC;
--		USB1DP: INOUT STD_LOGIC;
USB2DM <= USBWireVMout(0) when USBWireOE_n(0)='0' else 'Z';
USB2DP <= USBWireVPout(0) when USBWireOE_n(0)='0' else 'Z';
USBWireVMin(0) <= USB2DM;
USBWireVPin(0) <= USB2DP;

USB1DM <= USBWireVMout(1) when USBWireOE_n(1)='0' else 'Z';
USB1DP <= USBWireVPout(1) when USBWireOE_n(1)='0' else 'Z';
USBWireVMin(1) <= USB1DM;
USBWireVPin(1) <= USB1DP;

pllusbinstance : pll_usb
PORT MAP(refclk => CLOCK_50, 
		 outclk_0 => CLK_USB,
		 outclk_1 => GCLOCK_50,
		 locked => open);


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
		PS2_CLK => '1', -- No PS2...
		PS2_DAT => '1', -- No PS2...

		INPUT => zpu_out4,

		KEY_TYPE => key_type,
		
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

-- VIDEO
--VGA_HS <= not(VIDEO_HS xor VIDEO_VS);
--VGA_VS <= not(VIDEO_VS);


process(reset_atari_request,atari800mode,fkeys)
begin
	reset_atari <= '0';
	antic_rnmi_n <= '1';

	if (atari800mode='1' and fkeys(9)='0') then
		antic_rnmi_n <= not(reset_atari_request);
	else
		reset_atari <= reset_atari_request;
	end if;
end process;

atari800 : entity work.atari800core
	GENERIC MAP
	(
		cycle_length => 32,
		video_bits => 8,
		palette => 0,
		sdram_start_bank => integer(realmax(0.0,ceil(log2(real(internal_ram))-14.0)))
	)
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N and SDRAM_RESET_N and not(reset_atari),

		VIDEO_VS => VIDEO_VS,
		VIDEO_HS => VIDEO_HS,
		VIDEO_CS => VIDEO_CS,
		VIDEO_B => ATARI_COLOUR,
		VIDEO_G => open,
		VIDEO_R => open,
		VIDEO_BLANK => VIDEO_BLANK,
		VIDEO_BURST => VIDEO_BURST,
		VIDEO_START_OF_FIELD => open,
		VIDEO_ODD_LINE => VIDEO_ODD_LINE,

		AUDIO_L => AUDIO_L_PCM,
		AUDIO_R => AUDIO_R_PCM,
		SIO_AUDIO => ADC_PBISIO(8 downto 1),

		CA1_IN => CA1_IN,
		CB1_IN => CB1_IN,
		CA2_IN => CA2_IN,
		CA2_OUT => CA2_OUT,
		CA2_DIR_OUT => CA2_DIR_OUT,
		CB2_IN => CB2_IN,
		CB2_OUT => CB2_OUT,
		CB2_DIR_OUT => CB2_DIR_OUT,
		PORTA_IN => PORTA_IN and not("0000"&ps2_keys(16#174#)&ps2_keys(16#16B#)&ps2_keys(16#172#)&ps2_keys(16#175#)) and not(zpu_out3(0)&zpu_out3(1)&zpu_out3(2)&zpu_out3(3)&zpu_out2(0)&zpu_out2(1)&zpu_out2(2)&zpu_out2(3)),
		PORTA_DIR_OUT => PORTA_DIR_OUT,
		PORTA_OUT => PORTA_OUT,
		PORTB_IN => PORTB_IN,
		PORTB_DIR_OUT => PORTB_DIR_OUT,
		PORTB_OUT => PORTB_OUT,

		NMI_N_OUT => NMI_N,
		IRQ_N_OUT => IRQ_N,
		RDY_OUT => RDY,
		AN_OUT => AN,

		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,
		KEYBOARD_SCAN => KEYBOARD_SCAN,

		POT_IN => POT_IN,
		POT_RESET => POT_RESET,
		
		ENABLE_179_EARLY => ENABLE_179_EARLY,
		PBI_ADDR => PBI_ADDR,
		PBI_WRITE_ENABLE => PBI_WRITE_ENABLE,
		PBI_SNOOP_DATA => SNOOP_DATA,
		PBI_SNOOP_READY => SNOOP_DATA_READY,
		PBI_WRITE_DATA => PBI_WRITE_DATA,
		PBI_WIDTH_8bit_ACCESS => PBI_WIDTH_8bit_ACCESS,
		PBI_WIDTH_16bit_ACCESS => PBI_WIDTH_16bit_ACCESS,
		PBI_WIDTH_32bit_ACCESS => PBI_WIDTH_32bit_ACCESS,

		PBI_ROM_DO => pbi_data,
		PBI_REQUEST => pbi_request,
		PBI_REQUEST_COMPLETE => pbi_request_complete,
		PBI_TAKEOVER => pbi_takeover,
		PBI_RELEASE => pbi_release,
		PBI_DISABLE => pbi_disable,

		CART_RD5 => CART_RD5,
		PBI_MPD_N => MPD_N,

		PBI_IRQ_N => PBI_IRQ_N,

		SIO_RXD => ASIO_RXD,
		SIO_TXD => ASIO_TXD,

		SIO_CLOCKIN_IN => ASIO_CLOCKIN_IN,
		SIO_CLOCKIN_OUT => ASIO_CLOCKIN_OUT,
		SIO_CLOCKIN_OE => ASIO_CLOCKIN_OE,
		SIO_CLOCKOUT => ASIO_CLOCKOUT,

		CONSOL_OPTION => CONSOL_OPTION,
		CONSOL_SELECT => CONSOL_SELECT,
		CONSOL_START=> CONSOL_START,
		GTIA_TRIG => GTIA_TRIG and not("000"&ps2_keys(16#127#)) and not("00"&zpu_out3(4)&zpu_out2(4)),
		ANTIC_LIGHTPEN => ANTIC_LIGHTPEN,

		SDRAM_REQUEST => SDRAM_REQUEST,
		SDRAM_REQUEST_COMPLETE => SDRAM_REQUEST_COMPLETE,
		SDRAM_READ_ENABLE => SDRAM_READ_ENABLE,
		SDRAM_WRITE_ENABLE => SDRAM_WRITE_ENABLE,
		SDRAM_ADDR => SDRAM_ADDR,
		SDRAM_DO => SDRAM_DO,

		ANTIC_REFRESH => ANTIC_REFRESH,
		ANTIC_TURBO => ANTIC_TURBO,
		ANTIC_RNMI_N => ANTIC_RNMI_N,

		RAM_ADDR => RAM_ADDR,
		RAM_DO => RAM_DO,
		RAM_REQUEST => RAM_REQUEST,
		RAM_REQUEST_COMPLETE => RAM_REQUEST_COMPLETE,
		RAM_WRITE_ENABLE => RAM_WRITE_ENABLE,
		
		ROM_ADDR => ROM_ADDR,
		ROM_DO => ROM_DO,
		ROM_REQUEST => ROM_REQUEST,
		ROM_REQUEST_COMPLETE => ROM_REQUEST_COMPLETE,
		ROM_WRITE_ENABLE => ROM_WRITE_ENABLE,

		DMA_FETCH => dma_fetch,
		DMA_READ_ENABLE => dma_read_enable,
		DMA_32BIT_WRITE_ENABLE => dma_32bit_write_enable,
		DMA_16BIT_WRITE_ENABLE => dma_16bit_write_enable,
		DMA_8BIT_WRITE_ENABLE => dma_8bit_write_enable,
		DMA_ADDR => dma_addr_fetch,
		DMA_WRITE_DATA => dma_write_data,
		MEMORY_READY_DMA => dma_memory_ready,

		RAM_SELECT => ram_select,
		CART_EMULATION_SELECT => emulated_cartridge_select,
		PAL => PAL,
		ROM_IN_RAM => ROM_IN_RAM,
		THROTTLE_COUNT_6502 => speed_6502,
		HALT => pause_atari,
		ATARI800MODE => atari800mode,

		freezer_enable => freezer_enable,
		freezer_activate => freezer_activate,
		freezer_state_out => freezer_state,

		state_reg_out => state_reg_out,
		memory_ready_antic_out => memory_ready_antic_out,
		memory_ready_cpu_out => memory_ready_cpu_out,
		shared_enable_out => shared_enable_out

		--RAM_SELECT => "001",
		--CART_EMULATION_SELECT => (others=>'0'),
		--PAL => '0',
		--ROM_IN_RAM => '0',
		--THROTTLE_COUNT_6502 => "000001",
		--HALT => '0',

		--freezer_enable => '0',
		--freezer_activate => '0',
		--freezer_state_out => open
	);


ROM_IN_RAM <= '1' when internal_rom=0 else '0';

zpu: entity work.zpucore
	GENERIC MAP
	(
		platform => 2,
		spi_clock_div => 2, -- 28MHz/2. Max for SD cards is 25MHz...
		memory => 8192,
		usb => 2
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
		ZPU_MEMORY_DATA => snoop_data, 

		-- rom bus master
		-- data on next cycle after addr
		ZPU_ADDR_ROM => zpu_addr_rom,
		ZPU_ROM_DATA => zpu_rom_data,

		-- settings bus master
		ZPU_PLL_WRITE => zpu_pll_write,
		ZPU_PLL_DATA => zpu_pll_data,
		ZPU_PLL_ADDR => zpu_pll_addr,

		-- spi master
		-- Too painful to bit bang spi from zpu, so we have a hardware master in here
		ZPU_SPI_DI => sd_dat0 and spi_flash_di,
		ZPU_SPI_CLK => spi_clk,
		ZPU_SPI_DO => spi_do,
		ZPU_SPI_SELECT0 => sd_dat3,
		ZPU_SPI_SELECT1 => spi_flash_select,

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
			sd_writeprotect&sd_detect&
			ps2_keys(16#76#)&ps2_keys(16#5A#)&ps2_keys(16#174#)&ps2_keys(16#16B#)&ps2_keys(16#172#)&ps2_keys(16#175#)& -- (esc)FLRDU
			FKEYS,
		ZPU_IN2 => X"00000000",
		ZPU_IN3 => X"00000000",
		ZPU_IN4 => X"00000000",

		-- ouputs - e.g. Atari system control, halt, throttle, rom select
		ZPU_OUT1 => zpu_out1,
		ZPU_OUT2 => zpu_out2,
		ZPU_OUT3 => zpu_out3,
		ZPU_OUT4 => zpu_out4,
		ZPU_OUT5 => open, -- usb analog stick
		ZPU_OUT6 => zpu_out6,

		-- USB host
		CLK_USB => CLK_USB,
	
		USBWireVPin => USBWireVPin,
		USBWireVMin => USBWireVMin,
		USBWireVPout => USBWireVPout,
		USBWireVMout => USBWireVMout,
		USBWireOE_n => USBWireOE_n,

		i2c0_sda => clkgen_sda,
		i2c0_scl => clkgen_scl,

		i2c1_sda => vid_sda,
		i2c1_scl => vid_scl
	);

	pause_atari <= zpu_out1(0);
	reset_atari_request <= zpu_out1(1);
	speed_6502 <= zpu_out1(7 downto 2);
	ram_select <= zpu_out1(10 downto 8);
	atari800mode <= zpu_out1(11);
	emulated_cartridge_select <= zpu_out1(22 downto 17);

	freezer_enable <= zpu_out1(25);
	key_type <= zpu_out1(26);

	video_mode <= zpu_out6(2 downto 0);
	PAL <= zpu_out6(4);
	scanlines <= zpu_out6(5);
	csync <= zpu_out6(6);

--BIT_REG(,0x02,26,video,zpu_out1)
--BIT_REG(,0x01,28,tv,zpu_out1)
--BIT_REG(,0x01,29,scanlines,zpu_out1)
--BIT_REG(,0x01,30,csync,zpu_out1)
--#define VIDEO_RGB 0    00
--#define VIDEO_VGA 1    01
--#define VIDEO_SVIDEO 2 10
--#define VIDEO_HDMI 3   11

sfl_spi : sfl
	port map(
		asmi_access_granted => '0',
		asmi_access_request => open,
		data_in(0)          => spi_do,
		data_in(1)          => 'Z',
		data_in(2)          => 'Z',
		data_in(3)          => 'Z',
		data_oe(0)          => '1',
		data_oe(1)          => '0',
		data_oe(2)          => '0',
		data_oe(3)          => '0',
		data_out(0)         => open,
		data_out(1)         => spi_flash_di,
		data_out(2)         => open,
		data_out(3)         => open,
		dclk_in             => spi_clk,
		ncso_in             => spi_flash_select,
		noe_in              => '0' -- ?
	);
	sd_cmd <= spi_do;
	sd_clk <= spi_clk;

zpu_rom1: entity work.zpu_rom
	port map(
	        clock => clk,
	        address => zpu_addr_rom(15 downto 2),
	        q => zpu_rom_data
	);

enable_179_clock_div_zpu_pokey : entity work.enable_divider
	generic map (COUNT=>32) -- cycle_length
	port map(clk=>clk,reset_n=>reset_n,enable_in=>'1',enable_out=>zpu_pokey_enable);

dac_left : hq_dac
port map
(
  reset => not(reset_n),
  clk => clk,
  clk_ena => '1',
  pcm_in => AUDIO_L_PCM&"0000",
  dac_out => AUDIO_LEFT
);

dac_right : hq_dac
port map
(
  reset => not(reset_n),
  clk => clk,
  clk_ena => '1',
  pcm_in => AUDIO_R_PCM&"0000",
  dac_out => AUDIO_RIGHT
);

adc084_inst : entity work.adc084
  PORT MAP(
    clk       => CLK,
    reset_n   => RESET_N,

    CS        => ADC_CS,
    SCLK      => ADC_SCLK,
    DOUT      => ADC_DOUT,
    DIN       => ADC_DIN,

    CH1OUT    => ADC_PBI,  --     -> mix 
    CH2OUT    => ADC_SIO,  --     -> mix
    CH3OUT    => ADC_MICL, -- JACK/LEFT  -> sampler! (TODO)
    CH4OUT    => ADC_MICR  -- JACK/RIGHT -> sampler!
  );
  process(ADC_PBI,ADC_SIO)
  begin
    --ADC_PBISIO <= std_logic_vector((unsigned("0"&ADC_MICL)+unsigned("0"&ADC_MICR)));
    ADC_PBISIO <= std_logic_vector((unsigned("0"&ADC_PBI)+unsigned("0"&ADC_SIO)));
    --ADC_PBISIO <= std_logic_vector((unsigned("0"&ADC_SIO)+unsigned("0"&ADC_SIO)));
  end process;

--adc_i2c : entity work.i2c_master
--  GENERIC MAP(
--    input_clk => 58_000_000, --input clock speed from user logic in Hz - approx
--    bus_clk   => 400_000)   --speed the i2c bus (scl) will run at in Hz
--  PORT MAP(
--    clk       => CLK,
--    reset_n   => RESET_N,
--    ena       => '1',
--    addr      => "1001101",
--    rw        => '1',
--    data_wr   => "00000000",
--    busy      => adc_busy_next,
--    data_rd   => adc_in,
--    ack_error => open,
--    sda       => ADC_SDA,
--    scl       => ADC_SCL);

process(clk_raw,clk_114_raw,video_mode,adj_red,adj_green,adj_blue,adj_vsync,adj_hsync,adj_blank,VIDEO_R,VIDEO_G,VIDEO_B,VIDEO_BLANK,VIDEO_VSYNC,VIDEO_HSYNC,svideo_yout,svideo_c,svideo_sync_n,CLK,CLK_PIXEL_IN)
begin
	VGA_R <= VIDEO_R;
	VGA_G <= VIDEO_G;
	VGA_B <= VIDEO_B;
	VGA_BLANK_N <= '0';
	VGA_CLK <= '0';
	SCANDOUBLE <= '0';
	VGA_VS <= VIDEO_VSYNC;
	VGA_HS <= VIDEO_HSYNC;
	SCANDOUBLER_FORMAT <= "00";
	VGA_SYNC_N <= '1';
	COMP_N <= '1';

	-- original RGB
	-- scandoubled RGB (works on some vga devices...)
	-- svideo
	-- hdmi with audio  (and vga exact mode...)
	-- dvi (i.e. no preamble or audio) (and vga exact mode...)
	-- vga exact mode (hdmi off)
	-- composite (todo firmware...)

	case video_mode is
		when "000" =>
			VGA_BLANK_N <= not(VIDEO_BLANK);
			VGA_CLK <= CLK_RAW;
		when "001" =>
			VGA_BLANK_N <= '1'; -- TODO
			VGA_CLK <= CLK_RAW;
			SCANDOUBLE <= '1';
		when "010" => -- svideo
			VGA_G <= svideo_yout;
			VGA_B <= svideo_c;
			VGA_R <= svideo_c;

			VGA_BLANK_N <= '1'; -- TODO
			VGA_SYNC_N <= svideo_sync_n;
			VGA_CLK <= CLK_RAW; --CLK_114_RAW;
		when "011" =>
			--480p/576p over HDMI (and VGA!)
			VGA_R <= adj_red;
			VGA_G <= adj_green;
			VGA_B <= adj_blue;
			VGA_BLANK_N <= not(adj_blank);
			VGA_VS <= adj_vsync;
			VGA_HS <= adj_hsync;
			VGA_CLK <= CLK_PIXEL_IN;
			SCANDOUBLER_FORMAT <= "10";
		when "100" =>
			--480p/576p over DVI (and VGA!)
			VGA_R <= adj_red;
			VGA_G <= adj_green;
			VGA_B <= adj_blue;
			VGA_BLANK_N <= not(adj_blank);
			VGA_VS <= adj_vsync;
			VGA_HS <= adj_hsync;
			VGA_CLK <= CLK_PIXEL_IN;
			SCANDOUBLER_FORMAT <= "01";
		when "101" =>
			--480p/576p over VGA! (and VGA! - dupe...)
			VGA_R <= adj_red;
			VGA_G <= adj_green;
			VGA_B <= adj_blue;
			VGA_BLANK_N <= not(adj_blank);
			VGA_VS <= adj_vsync;
			VGA_HS <= adj_hsync;
			VGA_CLK <= CLK_PIXEL_IN;
			SCANDOUBLER_FORMAT <= "00";
		when "110" => -- composite
			VGA_R <= (others=>'0');
			VGA_G <= (others=>'0');
			VGA_G <= svideo_yout;
			VGA_BLANK_N <= '1'; -- TODO
			VGA_SYNC_N <= svideo_sync_n;
			VGA_CLK <= CLK_RAW; --CLK_114_RAW;
			COMP_N <= '0';

		when others =>
	end case;
end process;

	ddio_inst : entity work.altddio_out8
	port map (
		datain_h => TMDS_H,
		datain_l => TMDS_L,
		outclock => CLK_HDMI_IN,
		dataout  => DDIO_OUT);

	HD_TX2P <= DDIO_OUT(7); -- D2P
	HD_TX2N <= DDIO_OUT(6); -- D2N
	HD_TX1P <= DDIO_OUT(5); -- D1P
	HD_TX1N <= DDIO_OUT(4); -- D1N
	HD_TX0P <= DDIO_OUT(3); -- D0P
	HD_TX0N <= DDIO_OUT(2); -- D0N
	HD_CLKP <= DDIO_OUT(1); -- C P
	HD_CLKN <= DDIO_OUT(0); -- C N

	-- SVIDEO COMPONENT
	svideo_imple : entity work.svideo_gtia
	PORT MAP
	(
		CLK => clk,
		RESET_N => reset_n,

		brightness => ATARI_COLOUR(3 downto 0),
		hue => ATARI_COLOUR(7 downto 4),
		burst => VIDEO_BURST,
		blank => VIDEO_BLANK,
		sof => VIDEO_VS,
		csync_n => not(VIDEO_CS),
		vpos_lsb => VIDEO_ODD_LINE,
		pal => pal,

		composite => not(COMP_N),
		
		chroma => svideo_c,
		luma => svideo_yout,
		luma_sync_n => svideo_sync_n
	);


-- HDMI
scandoubler_hdmi_int : work.scandoubler_hdmi
PORT MAP
( 
	CLK_ATARI_IN => CLK,

	RESET_N => RESET_N and SDRAM_RESET_N and not(reset_atari),

	audio_left => audio_l_pcm,
	audio_right => audio_r_pcm,
	
	-- GTIA interface
	pal => pal,
	scanlines_on => scanlines,
	csync_on => csync,
	format => scandoubler_format,
	colour_enable => half_scandouble_enable_reg,
	colour_in => atari_colour,
	vsync_in => VIDEO_VS,
	hsync_in => VIDEO_HS,
	
	--HDMI clock domain
	CLK_HDMI_IN => clk_hdmi_in,
	CLK_PIXEL_IN => clk_pixel_in,

	O_hsync => adj_hsync,
	O_vsync => adj_vsync,
	O_blank => adj_blank,
	O_red => adj_red,
	O_green => adj_green,
	O_blue => adj_blue,

	-- TO TV...
	O_TMDS_H => tmds_h,
	O_TMDS_L => tmds_l
);

END vhdl;
