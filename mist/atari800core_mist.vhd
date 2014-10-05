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

component user_io
	PORT(
	   SPI_CLK : in std_logic;
	   SPI_SS_IO : in std_logic;
	   SPI_MISO : out std_logic;
	   SPI_MOSI : in std_logic;
	   CORE_TYPE : in std_logic_vector(7 downto 0);
		JOY0 : out std_logic_vector(5 downto 0);
		JOY1 : out std_logic_vector(5 downto 0);
		BUTTONS : out std_logic_vector(1 downto 0);
		SWITCHES : out std_logic_vector(1 downto 0);
		CLK : in std_logic;
		PS2_CLK : out std_logic;
		PS2_DATA : out std_logic
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
  
  signal mist_sector_ready : std_logic;
  signal mist_sector_ready_sync : std_logic;
  signal mist_sector_request : std_logic;
  signal mist_sector_request_sync : std_logic;
  signal mist_sector_write : std_logic;
  signal mist_sector_write_sync : std_logic;
  signal mist_sector : std_logic_vector(25 downto 0);
  signal mist_sector_sync : std_logic_vector(25 downto 0);
  
  		
  signal mist_addr : std_logic_vector(8 downto 0);
  signal mist_do : std_logic_vector(7 downto 0);
  signal mist_di : std_logic_vector(7 downto 0);
  signal mist_wren : std_logic;
  
  signal spi_miso_data : std_logic;
  signal spi_miso_io : std_logic;

  signal mist_buttons : std_logic_vector(1 downto 0);
  signal mist_switches : std_logic_vector(1 downto 0);

  signal		JOY1 :  STD_LOGIC_VECTOR(5 DOWNTO 0);
  signal		JOY2 :  STD_LOGIC_VECTOR(5 DOWNTO 0);
  signal		JOY1_n :  STD_LOGIC_VECTOR(4 DOWNTO 0);
  signal		JOY2_n :  STD_LOGIC_VECTOR(4 DOWNTO 0);
  signal joy_still : std_logic;

  SIGNAL	KEYBOARD_RESPONSE :  STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL	KEYBOARD_SCAN :  STD_LOGIC_VECTOR(5 DOWNTO 0);

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
	signal emulated_cartridge_select: std_logic_vector(5 downto 0);

	-- mist sector
	signal ZPU_ROM_DATA_MUX :  std_logic_vector(31 downto 0);
	signal ZPU_SECTOR_DATA :  std_logic_vector(31 downto 0);
	signal ZPU_ROM_DO :  std_logic_vector(31 downto 0);
	signal ZPU_ROM_WREN :  std_logic;

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
mist_spi_interface : entity work.data_io 
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
		read_request => mist_sector_request_sync,
		write_request => mist_sector_write_sync,
		--request => mist_sector_request_sync,
		sector => mist_sector_sync(25 downto 0),
		ready => mist_sector_ready,
		
		-- DMA to RAM
		ADDR => mist_addr,
		DATA_OUT => mist_do,
		DATA_IN => mist_di,
		WR_EN => mist_wren
	 );
 
	-- TODO, review if these are all needed when ZPU connected again...
	select_sync : entity work.synchronizer
	PORT MAP ( CLK => clk, raw => mist_sector_ready, sync=>mist_sector_ready_sync);

	select_sync2 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector_request, sync=>mist_sector_request_sync);

	select_sync3 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector_write, sync=>mist_sector_write_sync);

	sector_sync0 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(0), sync=>mist_sector_sync(0));

	sector_sync1 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(1), sync=>mist_sector_sync(1));

	sector_sync2 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(2), sync=>mist_sector_sync(2));

	sector_sync3 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(3), sync=>mist_sector_sync(3));

	sector_sync4 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(4), sync=>mist_sector_sync(4));

	sector_sync5 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(5), sync=>mist_sector_sync(5));

	sector_sync6 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(6), sync=>mist_sector_sync(6));

	sector_sync7 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(7), sync=>mist_sector_sync(7));

	sector_sync8 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(8), sync=>mist_sector_sync(8));

	sector_sync9 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(9), sync=>mist_sector_sync(9));

	sector_sync10 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(10), sync=>mist_sector_sync(10));

	sector_sync11 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(11), sync=>mist_sector_sync(11));

	sector_sync12 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(12), sync=>mist_sector_sync(12));

	sector_sync13 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(13), sync=>mist_sector_sync(13));

	sector_sync14 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(14), sync=>mist_sector_sync(14));

	sector_sync15 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(15), sync=>mist_sector_sync(15));

	sector_sync16 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(16), sync=>mist_sector_sync(16));

	sector_sync17 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(17), sync=>mist_sector_sync(17));

	sector_sync18 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(18), sync=>mist_sector_sync(18));

	sector_sync19 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(19), sync=>mist_sector_sync(19));

	sector_sync20 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(20), sync=>mist_sector_sync(20));

	sector_sync21 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(21), sync=>mist_sector_sync(21));

	sector_sync22 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(22), sync=>mist_sector_sync(22));

	sector_sync23 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(23), sync=>mist_sector_sync(23));

	sector_sync24 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(24), sync=>mist_sector_sync(24));

	sector_sync25 : entity work.synchronizer
	PORT MAP ( CLK => spi_sck, raw => mist_sector(25), sync=>mist_sector_sync(25));
	
	
	spi_do <= spi_miso_io when CONF_DATA0 ='0' else spi_miso_data when spi_SS2='0' else 'Z';

mist_sector_buffer1 : entity work.mist_sector_buffer
	PORT map
	(
		address_a		=> mist_addr,
		address_b		=> zpu_addr_rom(8 downto 2),
		clock_a		=> spi_sck,
		clock_b		=> clk,
		data_a		=> mist_do,
		data_b		=> dma_write_data(7 downto 0)&dma_write_data(15 downto 8)&dma_write_data(23 downto 16)&dma_write_data(31 downto 24),
		wren_a		=> mist_wren,
		wren_b		=> zpu_rom_wren, 
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
		JOY0 => joy2,
		JOY1 => joy1,
		BUTTONS => mist_buttons,
		SWITCHES => mist_switches,
		CLK => SLOW_PS2_CLK,
		PS2_CLK => ps2_clk,
		PS2_DATA => ps2_dat
	  );
	  
	 joy1_n <= not(joy1(4 downto 0));
	 joy2_n <= not(joy2(4 downto 0));

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

		CONSOL_START => CONSOL_START_RAW,
		CONSOL_SELECT => CONSOL_SELECT_RAW,
		CONSOL_OPTION => CONSOL_OPTION_RAW,
		
		FKEYS => FKEYS
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
		VIDEO_B => VIDEO_B,
		VIDEO_G => open,
		VIDEO_R => open,

		AUDIO_L => AUDIO_L_PCM,
		AUDIO_R => AUDIO_R_PCM,

		JOY1_n => JOY1_n(4)&JOY1_n(0)&JOY1_n(1)&JOY1_n(2)&JOY1_n(3),
		JOY2_n => JOY2_n(4)&JOY2_n(0)&JOY2_n(1)&JOY2_n(2)&JOY2_n(3),

		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,
		KEYBOARD_SCAN => KEYBOARD_SCAN,

		SIO_COMMAND => zpu_sio_command,
		SIO_RXD => zpu_sio_txd,
		SIO_TXD => zpu_sio_rxd,

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
    		ROM_SELECT => rom_select,
		PAL => PAL,
		HALT => pause_atari,
		THROTTLE_COUNT_6502 => speed_6502,
		emulated_cartridge_select => emulated_cartridge_select
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
		ZPU_ROM_DATA => zpu_rom_data_mux,
	
		ZPU_ROM_WREN => zpu_rom_wren, -- special for mist...

		-- spi master
		-- not used for mist...
		ZPU_SD_DAT0 => '0',
		ZPU_SD_CLK => open,
		ZPU_SD_CMD => open,
		ZPU_SD_DAT3 => open,

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
		ZPU_IN4 => X"000000"&"0000000"&mist_sector_ready_sync,

		-- ouputs - e.g. Atari system control, halt, throttle, rom select
		ZPU_OUT1 => zpu_out1,
		ZPU_OUT2 => zpu_out2,
		ZPU_OUT3 => zpu_out3,
		ZPU_OUT4 => zpu_out4
	);

	mist_sector <= zpu_out4(25 downto 0);
	mist_sector_request <= zpu_out4(26);
	mist_sector_write <= zpu_out4(27);

	pause_atari <= zpu_out1(0);
	reset_atari <= zpu_out1(1);
	speed_6502 <= zpu_out1(7 downto 2);
	ram_select <= zpu_out1(10 downto 8);
	rom_select <= zpu_out1(16 downto 11);
	emulated_cartridge_select <= zpu_out1(22 downto 17);

zpu_rom1: entity work.zpu_rom
	port map(
	        clock => clk,
	        address => zpu_addr_rom(13 downto 2),
	        q => zpu_rom_data
	);

process(zpu_addr_rom, zpu_rom_data, zpu_sector_data)
begin
	zpu_rom_data_mux <= zpu_rom_data;
	if (zpu_addr_rom(15 downto 14) = "01") then
		zpu_rom_data_mux <= zpu_sector_data(7 downto 0)&zpu_sector_data(15 downto 8)&zpu_sector_data(23 downto 16)&zpu_sector_data(31 downto 24);
	end if;
end process;

enable_179_clock_div_zpu_pokey : entity work.enable_divider
	generic map (COUNT=>32) -- cycle_length
	port map(clk=>clk,reset_n=>reset_n,enable_in=>'1',enable_out=>zpu_pokey_enable);

END vhdl;
