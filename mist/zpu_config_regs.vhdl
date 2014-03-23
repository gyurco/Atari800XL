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

ENTITY zpu_config_regs IS
PORT 
( 
	CLK : IN STD_LOGIC;
	
	ENABLE_179 : in std_logic;
	
	ADDR : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
	CPU_DATA_IN : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
	WR_EN : IN STD_LOGIC;
	
	-- SWITCHES
	SWITCH : in std_logic_vector(9 downto 0); -- already synchronized
	KEY : in std_logic_vector(3 downto 0); -- already synchronized
	
	-- LEDS
	LEDG : out std_logic_vector(7 downto 0);
	LEDR : out std_logic_vector(9 downto 0);
	
	-- SDCARD
	SDCARD_CLK : out std_logic;
	SDCARD_CMD : out std_logic;
	SDCARD_DAT : in std_logic;
	SDCARD_DAT3 : out std_logic;
	
	-- ATARI interface (in future we can also turbo load by directly hitting memory...)
	SIO_DATA_IN  : out std_logic;
	SIO_COMMAND_OUT : in std_logic;
	SIO_DATA_OUT : in std_logic;
	
	-- CPU interface
	DATA_OUT : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
	PAUSE_ZPU : out std_logic;
	
	-- SYSTEM CONFIG SETTINGS (legacy from switches - hardcoded to start with, then much fancier)
	PAL : OUT STD_LOGIC;
	USE_SDRAM : OUT STD_LOGIC;
	RAM_SELECT : OUT STD_LOGIC_VECTOR(3 downto 0);
	VGA : OUT STD_LOGIC;
	COMPOSITE_ON_HSYNC : OUT STD_LOGIC;
	GPIO_ENABLE : OUT STD_LOGIC;
	ROM_SELECT : out stD_logic_vector(3 downto 0);
	
	-- sector buffer
	sector : out std_logic_vector(31 downto 0);
	sector_request : out std_logic;
	sector_ready : in std_logic;

	-- system reset/halt
	PLL_LOCKED : IN STD_LOGIC; -- pll locked
	REQUEST_RESET_ZPU : in std_logic; -- from keyboard (f12 to start with)
	
	RESET_6502 : OUT STD_LOGIC; -- i.e. cpu reset - 6502
	RESET_ZPU : OUT STD_LOGIC; -- i.e. cpu reset - zpu
	RESET_N : OUT STD_LOGIC; -- i.e. reset line on flip flops
	
	PAUSE_6502 : out std_logic;
	
	THROTTLE_COUNT_6502 : out std_logic_vector(5 downto 0);
	
	ZPU_HEX : out std_logic_vector(15 downto 0)

--	-- synchronize async inputs
--	locked_synchronizer : synchronizer
--		port map (clk=>clk, raw=>LOCKED, sync=>LOCKED_REG);
	
);
END zpu_config_regs;

ARCHITECTURE vhdl OF zpu_config_regs IS
	COMPONENT complete_address_decoder IS
	generic (width : natural := 4);
	PORT 
	( 
		addr_in : in std_logic_vector(width-1 downto 0);			
		addr_decoded : out std_logic_vector((2**width)-1 downto 0)
	);
	END component;
	
	COMPONENT spi_master IS
	  GENERIC(
		 slaves  : INTEGER := 4;  --number of spi slaves
		 d_width : INTEGER := 2); --data bus width
	  PORT(
		 clock   : IN     STD_LOGIC;                             --system clock
		 reset_n : IN     STD_LOGIC;                             --asynchronous reset
		 enable  : IN     STD_LOGIC;                             --initiate transaction
		 cpol    : IN     STD_LOGIC;                             --spi clock polarity
		 cpha    : IN     STD_LOGIC;                             --spi clock phase
		 cont    : IN     STD_LOGIC;                             --continuous mode command
		 clk_div : IN     INTEGER;                               --system clock cycles per 1/2 period of sclk
		 addr    : IN     INTEGER;                               --address of slave
		 tx_data : IN     STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  --data to transmit
		 miso    : IN     STD_LOGIC;                             --master in, slave out
		 sclk    : BUFFER STD_LOGIC;                             --spi clock
		 ss_n    : BUFFER STD_LOGIC_VECTOR(slaves-1 DOWNTO 0);   --slave select
		 mosi    : OUT    STD_LOGIC;                             --master out, slave in
		 busy    : OUT    STD_LOGIC;                             --busy / data ready signal
		 rx_data : OUT    STD_LOGIC_VECTOR(d_width-1 DOWNTO 0)); --data received
	END component;	
	

	component pokey IS
	PORT 
	( 
		CLK : IN STD_LOGIC;
		--ENABLE_179 :in std_logic;
		CPU_MEMORY_READY :in std_logic;
		ANTIC_MEMORY_READY :in std_logic;
		ADDR : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		DATA_IN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		WR_EN : IN STD_LOGIC;
		
		RESET_N : IN STD_LOGIC;
		
		-- keyboard interface
		keyboard_scan : out std_logic_vector(5 downto 0);
		keyboard_response : in std_logic_vector(1 downto 0);
		
		-- pots - go high as capacitor charges
		POT_IN : in std_logic_vector(7 downto 0);
		
		-- sio interface
		SIO_IN1 : IN std_logic;
		SIO_IN2 : IN std_logic;
		SIO_IN3 : IN std_logic;
		
		DATA_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		
		CHANNEL_0_OUT : OUT STD_LOGIC_VECTOR(3 downto 0);
		CHANNEL_1_OUT : OUT STD_LOGIC_VECTOR(3 downto 0);
		CHANNEL_2_OUT : OUT STD_LOGIC_VECTOR(3 downto 0);
		CHANNEL_3_OUT : OUT STD_LOGIC_VECTOR(3 downto 0);
		
		IRQ_N_OUT : OUT std_logic;
		
		SIO_OUT1 : OUT std_logic;
		SIO_OUT2 : OUT std_logic;
		SIO_OUT3 : OUT std_logic;
		
		SIO_CLOCK : INOUT std_logic; -- TODO, should not use internally
		
		POT_RESET : out std_logic
	);
	END component;	
	
	function vectorize(s: std_logic) return std_logic_vector is
	variable v: std_logic_vector(0 downto 0);
	begin
		v(0) := s;
		return v;
	end;
	
	signal addr_decoded : std_logic_vector(15 downto 0);	
	
	signal config_6502_next : std_logic_vector(7 downto 0);
	signal config_6502_reg : std_logic_vector(7 downto 0);
	signal ram_select_next : std_logic_vector(3 downto 0);
	signal ram_select_reg : std_logic_vector(3 downto 0);
	signal rom_select_next : std_logic_vector(3 downto 0);
	signal rom_select_reg : std_logic_vector(3 downto 0);
	signal gpio_enable_next : std_logic;
	signal gpio_enable_reg : std_logic;
	
	signal pause_next : std_logic_vector(31 downto 0);
	signal pause_reg : std_logic_vector(31 downto 0);
	signal paused_next : std_logic;
	signal paused_reg : std_logic;
	
	signal ledg_next : std_logic_vector(7 downto 0);
	signal ledg_reg : std_logic_vector(7 downto 0);

	signal ledr_next : std_logic_vector(9 downto 0);
	signal ledr_reg : std_logic_vector(9 downto 0);
	
	signal reset_n_next : std_logic;
	signal reset_n_reg : std_logic;
	
	signal reset_6502_cpu_next : std_logic;
	signal reset_6502_cpu_reg : std_logic;
	
	signal reset_zpu_next : std_logic;
	signal reset_zpu_reg : std_logic;	
	
	signal spi_miso : std_logic;
	signal spi_mosi : std_logic;
	signal spi_busy : std_logic;	
	signal spi_enable : std_logic;
	signal spi_chip_select : std_logic_vector(0 downto 0);
	signal spi_clk_out : std_logic;
	
	signal spi_tx_data : std_logic_vector(7 downto 0);
	signal spi_rx_data : std_logic_vector(7 downto 0);
	
	signal spi_addr_next : std_logic;
	signal spi_addr_reg : std_logic;
	signal spi_speed_next : std_logic_vector(7 downto 0);
	signal spi_speed_reg : std_logic_vector(7 downto 0);

	signal zpu_hex_next : std_logic_vector(15 downto 0);
	signal zpu_hex_reg : std_logic_vector(15 downto 0);
	
	signal pokey_data_out : std_logic_vector(7 downto 0);
	
	signal sector_next : std_logic_vector(31 downto 0);
	signal sector_reg : std_logic_vector(31 downto 0);
	signal sector_request_next : std_logic;
	signal sector_request_reg : std_logic; -- cleared when ready asserted
	
begin
	-- register
	process(clk,pll_locked)
	begin
		if (clk'event and clk='1') then	
			if (pll_locked = '0') then
				config_6502_reg <= "1"&"0"&"011111"; -- reset_6502, halt_6502, run_every 32 cycles
				rom_select_reg <= "0010";
				ram_select_reg <= "0010";
				gpio_enable_reg <= '0';
				pause_reg <= (others=>'0');
				paused_reg <= '0';
				ledg_reg <= (others=>'0');
				ledr_reg <= (others=>'0');
				
				spi_addr_reg <= '1';
				spi_speed_reg <= X"80";
				
				zpu_hex_reg <= X"b007";
				
				reset_n_reg <= '0';			
				reset_zpu_reg <= '1';
				reset_6502_cpu_reg <= '1';											
				
				sector_reg <= (others=>'0');
				sector_request_reg <= '0';
			else
				config_6502_reg <= config_6502_next;
				rom_select_reg <= rom_select_next;
				ram_select_reg <= ram_select_next;
				gpio_enable_reg <= gpio_enable_next;			
				pause_reg <= pause_next;
				paused_reg <= paused_next;
				ledg_reg <= ledg_next;
				ledr_reg <= ledr_next;
				
				spi_addr_reg <= spi_addr_next;
				spi_speed_reg <= spi_speed_next;
	
				zpu_hex_reg <= zpu_hex_next;
	
				reset_n_reg <= reset_n_next;			
				reset_zpu_reg <= reset_zpu_next;
				reset_6502_cpu_reg <= reset_6502_cpu_next;							
				
				sector_reg <= sector_next;
				sector_request_reg <= sector_request_next;				
			end if;
		end if;
	end process;

	-- decode address
	decode_addr1 : complete_address_decoder
		generic map(width=>4)
		port map (addr_in=>addr(3 downto 0), addr_decoded=>addr_decoded);

	-- spi - for sd card access without bit banging...
	-- 200KHz to start with - probably fine for 8-bit, can up it later after init
	spi_master1 : spi_master
		generic map(slaves=>1,d_width=>8)
		port map (clock=>clk,reset_n=>pll_locked,enable=>spi_enable,cpol=>'0',cpha=>'0',cont=>'0',clk_div=>to_integer(unsigned(spi_speed_reg)),addr=>to_integer(unsigned(vectorize(spi_addr_reg))),
		          tx_data=>spi_tx_data, miso=>spi_miso,sclk=>spi_clk_out,ss_n=>spi_chip_select,mosi=>spi_mosi,
					 rx_data=>spi_rx_data,busy=>spi_busy);
					 
	-- spi-programming model:
	-- reg for write/read
	-- data (send/receive)
	-- busy
	-- speed - 0=400KHz, 1=10MHz? Start with 400KHz then atari800core...
	-- chip select
	
	-- uart - another Pokey! Running at atari frequency.
	uart1 : pokey
		port map (clk=>clk,CPU_MEMORY_READY=>enable_179,ANTIC_MEMORY_READY=>enable_179,addr=>addr(3 downto 0),data_in=>cpu_data_in(7 downto 0),wr_en=>addr(4) and wr_en, 
		reset_n=>pll_locked,keyboard_response=>"11",pot_in=>X"00",
		sio_in1=>sio_data_out,sio_in2=>'1',sio_in3=>'1', -- TODO, pokey dir...
		data_out=>pokey_data_out, 
		sio_out1=>sio_data_in);

	-- hardware regs for ZPU
	--
	-- KEYS -> all for ZPU. SWITCHES -> all for ZPU
	-- i.e. zpu must control: rom/ram select, turbo, 6502 reset, scandoubler, rom wait states, pal/ntsc, gpio enable, sdram vs sram
	-- these need storing somewhere...
	-- TODO - volume output from here
	-- TODO - hex digits register
	-- TODO - if we take over antic we need to point antic to alternative RAM!
	-- TODO - if we take over antic we need to point it back at the original display list... e.g. freeze, store state, restore state...
	-- TODO - reset pokey and pia interrupts too?
	--
	-- virtual joystick button -> keyboard (windows key?)
	-- reset -> keyboard -> f12 -> zpu reset. Then zpu controls 6502 reset.
	--
	-- important todo -> speed up clearing ram. e.g. 32-bit sram write. Only clear bit we need to.
	--
	-- STEP 1 -> joystick -> keyboard (DONE)
	-- STEP 2 -> hardcode switch inputs to 65XE, PAL, non scandoubled  (DONE)
	-- STEP 3 -> 6502 reset (DONE))/turbo under zpu control (DONE)
	-- STEP 4 -> zpu starts 6502 on key1 (DONE)
	-- STEP 5 -> simple OSD! ok, just make antic display mode 2 on reset with hello world, joystick to select... (CLOSE)
	--
	-- CONFIG_ATARI: 
	-- 	R/W: 0-5: run every n cycles (0-63), 6: pause, 7: reset 
	--    R/W(8-11 bits) - XX 00=64k,01=128K,10=320K Compy,11=320K Rambo
	--    R/W(12-15 bits) - XX 00=XL, 01=XL turbo, 10=OS B/debugger, 11=OS B turbo
	--	   R/W(16-20 bits) - XXXG= G:0=GPIO_OFF,1=GPIO_ON(ISH!)
	-- PAUSE (DONE) -- W: 0-31:wait for n cycles
	-- SWITCH (DONE)
	--		R: 0-9 - switches
	-- KEY (DONE)
	--    R: 0-3 - keys
	-- LEDG (DONE) 
	--    R/W: 0-9
	-- LEDR (DONE) 
	--    R/W: 0-9
	-- SPI_DATA (DONE) 
	--		W - write data (starts transmission)
	--		R - read data (wait for complete first)
	-- SPI_STATE/SPI_CTRL (DONE) 
	--    R: 0=busy
	--    W: 0=select_n, speed
	-- SIO
	--    R: 0=CMD
	-- FPGA board (DONE) 
	--    R(32 bits) 0=DE1
	-- HEX digits
	--    W(16 bits)
	-- SECTOR
	--   W(32 bits) - write here initiates a request_reset_zpu
	--   R: 0=request_active
	
	-- TODO, ROM select, RAM select etc etc
	-- TODO firmware with OSD!
				
	-- Writes to registers
	process(cpu_data_in,wr_en,addr,addr_decoded, ledg_reg, ledr_reg, pause_reg, config_6502_reg, rom_select_reg, ram_select_reg, gpio_enable_reg, spi_speed_reg, spi_addr_reg, zpu_hex_reg, sector_request_reg, sector_ready, sector_reg)
	begin
		config_6502_next <= config_6502_reg;
		rom_select_next <= rom_select_reg;
		ram_select_next <= ram_select_reg;
		gpio_enable_next <= gpio_enable_reg;
		pause_next <= pause_reg;
		ledg_next <= ledg_reg;
		ledr_next <= ledr_reg;
		
		spi_speed_next <= spi_speed_reg;
		spi_addr_next <= spi_addr_reg;
		spi_tx_data <= (others=>'0');
		spi_enable <= '0';
		
		zpu_hex_next <= zpu_hex_reg;
		
		sector_next <= sector_reg;
		sector_request_next <= sector_request_reg and not(sector_ready);
		
		paused_next <= '0';
		if (not(pause_reg = X"00000000")) then
			pause_next <= std_LOGIC_VECTOR(unsigned(pause_reg)-to_unsigned(1,32));
			paused_next <= '1';
		end if;
	
		if (wr_en = '1' and addr(4) = '0') then
			if(addr_decoded(0) = '1') then
				config_6502_next <= cpu_data_in(7 downto 0);
				ram_select_next <= cpu_DATA_IN(11 downto 8);
				rom_select_next <= cpu_DATA_IN(15 downto 12);
				gpio_enable_next <= cpu_DATA_IN(16);
			end if;	
			
			if(addr_decoded(1) = '1') then
				pause_next <= cpu_data_in;
				paused_next <= '1';
			end if;				

			if(addr_decoded(4) = '1') then
				ledg_next <= cpu_data_in(7 downto 0);
			end if;	
			
			if(addr_decoded(5) = '1') then
				ledr_next <= cpu_data_in(9 downto 0);
			end if;	

			if(addr_decoded(6) = '1') then
				-- TODO, check overrun?
				spi_tx_data <= cpu_data_in(7 downto 0);
				spi_enable <= '1';
			end if;	

			if(addr_decoded(7) = '1') then
				spi_addr_next <= cpu_data_in(0);
				if (cpu_data_in(1) = '1') then
					spi_speed_next <= X"80"; -- slow, for init
				else
					spi_speed_next <= X"04"; -- turbo!
				end if;
			end if;	

			if(addr_decoded(10) = '1') then
				zpu_hex_next <= cpu_data_in(15 downto 0);
			end if;	
			
			if(addr_decoded(11) = '1') then
				sector_next <= cpu_data_in;
				sector_request_next <= '1';
			end if;
			
		end if;
	end process;
	
	-- Read from registers
	process(addr,addr_decoded, ledg_reg, ledr_reg, SWITCH, KEY, SIO_COMMAND_OUT, spi_rx_data, spi_busy, pokey_data_out, zpu_hex_reg, config_6502_reg, ram_select_reg, rom_select_reg, gpio_enable_reg, sector_request_reg)
	begin
		data_out <= (others=>'0');

		if (addr(4) = '0') then
			if (addr_decoded(0) = '1') then
				data_out(7 downto 0) <= config_6502_reg;
				data_out(11 downto 8) <= ram_select_reg;
				data_out(15 downto 12) <= rom_select_reg;
				data_out(16) <= gpio_enable_reg;
			end if;
			
			if (addr_decoded(2) = '1') then
				data_out(9 downto 0) <= (others=>'0'); -- TODO - enable SD.
			end if;		
			
			if (addr_decoded(3) = '1') then
				data_out(3 downto 0) <= key;
			end if;		
			
			if (addr_decoded(4) = '1') then
				data_out(7 downto 0) <= ledg_reg;
			end if;

			if (addr_decoded(5) = '1') then
				data_out(9 downto 0) <= ledr_reg;
			end if;

			if (addr_decoded(6) = '1') then
				data_out(7 downto 0) <= spi_rx_data;
			end if;

			if (addr_decoded(7) = '1') then
				data_out(0) <= spi_busy;
			end if;		

			if(addr_decoded(8) = '1') then
				data_out(0) <= sio_command_OUT;
			end if;	
			
			if (addr_decoded(9) = '1') then
				--data_out <= X"00000000"; -- DE1!
				--data_out <= X"00000001"; -- DE2!
				--data_out <= X"00000002"; -- SOCKIT!
				--data_out <= X"00000003"; -- REPLAY!
				data_out <= X"00000004"; -- MMC!		
			end if;
			
			if (addr_decoded(10) = '1') then
				data_out(15 downto 0) <= zpu_hex_reg;
			end if;			
			
			if (addr_decoded(11) = '1') then
				data_out(0) <= sector_request_reg;
			end if;			
			
		else
			data_out(7 downto 0) <= pokey_data_out;
		end if;
	end process;	
	
	process(request_reset_zpu, config_6502_next, config_6502_reg)
	begin
		reset_n_next <= '1';
		reset_zpu_next <= '0';
		reset_6502_cpu_next <= config_6502_reg(7);
		
		if (request_reset_zpu = '1') then
			reset_n_next <= '0';
			reset_zpu_next <= '1';
			reset_6502_cpu_next <= '1';
		end if;
	end process;
	
	-- outputs
	PAUSE_ZPU <= paused_reg;
	LEDG <= ledg_reg;
	LEDR <= ledr_reg;
	
	SDCARD_CLK <= spi_clk_out;
	SDCARD_CMD <= spi_mosi;
	spi_miso <= SDCARD_DAT; -- INPUT!! XXX
	SDCARD_DAT3 <= spi_chip_select(0);
	
	PAL <= '1'; -- TODO
	--USE_SDRAM <= '1'; -- should not be all or nothing. can mix for higher ram settings...
	USE_SDRAM <= '1'; -- should not be all or nothing. can mix for higher ram settings...
	RAM_SELECT <= ram_select_reg;
	VGA <= '1';
	COMPOSITE_ON_HSYNC <= '0';
	GPIO_ENABLE <= '0'; -- enable gpio - FIXME - esp carts!
	ROM_SELECT <= rom_select_reg;
	
	reset_n <= reset_n_reg; -- system reset or pll not locked
	reset_zpu <= reset_zpu_reg; -- system_reset or pll not locked
	reset_6502 <= reset_6502_cpu_reg; -- zpu software controlled
	
	pause_6502 <= config_6502_reg(6); -- zpu software controlled
	
	throttle_count_6502 <= config_6502_reg(5 downto 0); -- zpu software controlled	
	
	zpu_hex <= zpu_hex_reg;
	
	sector <= sector_reg;
	sector_request <= sector_request_reg;
end vhdl;


