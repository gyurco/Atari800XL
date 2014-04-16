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



  signal AUDIO_L_PCM : std_logic_vector(15 downto 0);
  signal AUDIO_R_PCM : std_logic_vector(15 downto 0);

  signal VGA_R_WIDE : std_logic_vector(7 downto 0);
  signal VGA_G_WIDE : std_logic_vector(7 downto 0);
  signal VGA_B_WIDE : std_logic_vector(7 downto 0);
  signal VGA_VS_RAW : std_logic;
  signal VGA_HS_RAW : std_logic;

  signal RESET_n : std_logic;
  signal PLL_LOCKED : std_logic;
  signal CLK : std_logic;
  signal CLK_SDRAM : std_logic;

  signal keyboard : std_logic_vector(127 downto 0);
  signal atari_keyboard : std_logic_vector(63 downto 0);
  
  SIGNAL	SHIFT_PRESSED :  STD_LOGIC;
  SIGNAL	BREAK_PRESSED :  STD_LOGIC;
  SIGNAL	CONTROL_PRESSED :  STD_LOGIC;

  SIGNAL	CONSOL_OPTION :  STD_LOGIC;
  SIGNAL	CONSOL_SELECT :  STD_LOGIC;
  SIGNAL	CONSOL_START :  STD_LOGIC;

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

  signal mist_buttons : std_logic_vector(1 downto 0);
  signal mist_switches : std_logic_vector(1 downto 0);

  signal		JOY1 :  STD_LOGIC_VECTOR(5 DOWNTO 0);
  signal		JOY2 :  STD_LOGIC_VECTOR(5 DOWNTO 0);
  signal		JOY1_n :  STD_LOGIC_VECTOR(4 DOWNTO 0);
  signal		JOY2_n :  STD_LOGIC_VECTOR(4 DOWNTO 0);

  SIGNAL	KEYBOARD_RESPONSE :  STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL	KEYBOARD_SCAN :  STD_LOGIC_VECTOR(5 DOWNTO 0);

  SIGNAL	THROTTLE_COUNT_6502 :  STD_LOGIC_VECTOR(5 DOWNTO 0);

  SIGNAL PAL : std_logic;

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
  
  signal SYSTEM_RESET_REQUEST: std_logic;
  
  signal SDRAM_RESET_N : std_logic;

BEGIN 
pal <= '1'; -- TODO, two builds, with appropriate pll settings

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
		request => mist_sector_request_sync,
		sector => mist_sector_sync(23 downto 0),
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
	
	
	spi_do <= spi_miso_io when CONF_DATA0 ='0' else spi_miso_data when spi_SS2='0' else 'Z';

mist_sector_buffer1 : entity work.mist_sector_buffer
	PORT map
	(
		address_a		=> mist_addr,
		address_b		=> "0000000", -- TODO - need to expose a 2nd dma channel of some kind, so we don't have to halt 6502 to access sector buffer! ZPU_ADDR_ROM_RAM(8 DOWNTO 2),
		clock_a		=> spi_sck,
		clock_b		=> clk,
		data_a		=> mist_do,
		data_b		=> X"00000000", -- TODO zpu_do,
		wren_a		=> mist_wren,
		wren_b		=> '0',
		q_a		=> mist_di,
		q_b		=> open -- TODO zpu_sector_data
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
	  
	 joy1_n <= not(joy1(4 downto 0));
	 joy2_n <= not(joy2(4 downto 0));
	 
	process(clk,reset_n)
	begin
		if (reset_n='0') then
			capsheld_reg <= '0';
		elsif (clk'event and clk='1') then
			capsheld_reg <= capsheld_next;
		end if;
	end process;

-- TODO, this doesn't work yet
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
	
-- TODO, this is mapping from ST keycode, make mist firmware send PS2 keycodes or USB keycodes if possible
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

--HOT KEYS! Connect to ZPU when present...
--virtual_keys <= keyboard(65)&keyboard(66)&keyboard(67)&keyboard(68);
SYSTEM_RESET_REQUEST <= keyboard(63);

-- TODO this should be common, same for PS2 after mapping...
process(keyboard_scan, atari_keyboard, control_pressed, shift_pressed, break_pressed)
	begin	
		keyboard_response <= (others=>'1');		
		
		if (atari_keyboard(to_integer(unsigned(not(keyboard_scan)))) = '1') then
			keyboard_response(0) <= '0';
		end if;
		
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

-- TODO - mist joystick mapping!
--GPIO_PORTA_IN <= VIRTUAL_STICKS and (JOY1_n(0)&JOY1_n(1)&JOY1_n(2)&JOY1_n(3)&JOY2_n(0)&JOY2_n(1)&JOY2_n(2)&JOY2_n(3));
--fire is bit 4...

mist_pll : entity work.pll
PORT MAP(inclk0 => CLOCK_27(0),
		 c0 => CLK_SDRAM,
		 c1 => CLK,
		 c2 => SDRAM_CLK,
		 locked => PLL_LOCKED);

reset_n <= PLL_LOCKED;

-- THROTTLE
THROTTLE_COUNT_6502 <= std_logic_vector(to_unsigned(32-1,6));

atarixl_simple_sdram1 : entity work.atari800core_simple_sdram
	GENERIC MAP
	(
		cycle_length => 32,
		internal_rom => 1,
		internal_ram => 0
	)
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N and SDRAM_RESET_N and not(SYSTEM_RESET_REQUEST),

		VGA_VS => VGA_VS_RAW,
		VGA_HS => VGA_HS_RAW,
		VGA_B => VGA_B_WIDE,
		VGA_G => VGA_G_WIDE,
		VGA_R => VGA_R_WIDE,

		AUDIO_L => AUDIO_L_PCM,
		AUDIO_R => AUDIO_R_PCM,

		JOY1_n => JOY1_n,
		JOY2_n => JOY2_n,

		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,
		KEYBOARD_SCAN => KEYBOARD_SCAN,

		SIO_COMMAND => open,
		SIO_RXD => '1',
		SIO_TXD => open,

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

		DMA_FETCH => '0',
		DMA_READ_ENABLE => '0',
		DMA_32BIT_WRITE_ENABLE => '0',
		DMA_16BIT_WRITE_ENABLE => '0',
		DMA_8BIT_WRITE_ENABLE => '0',
		DMA_ADDR => (others=>'1'),
		DMA_WRITE_DATA => (others=>'1'),
		MEMORY_READY_DMA => open,

   		RAM_SELECT => (others=>'0'),
    		ROM_SELECT => "000001",
		PAL => PAL,
		HALT => '0',
		THROTTLE_COUNT_6502 => THROTTLE_COUNT_6502
	);

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
SDRAM_REFRESH <= '0'; -- TODO

-- Until SDRAM enabled... TODO
--SDRAM_nCS <= '1';
--SDRAM_DQ <= (others=>'Z');

--SDRAM_CKE <= '1';		 
LED <= '0';

VGA_HS <= not(VGA_HS_RAW xor VGA_VS_RAW);
VGA_VS <= not(VGA_VS_RAW);
VGA_R <= VGA_R_WIDE(7 downto 2);
VGA_G <= VGA_G_WIDE(7 downto 2);
VGA_B <= VGA_B_WIDE(7 downto 2);

END vhdl;
