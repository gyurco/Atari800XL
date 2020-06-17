---------------------------------------------------------------------------
-- (c) 2020 mark watson
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

LIBRARY work;

ENTITY pokeymax IS 
	GENERIC
	(
		pokeys : integer := 1; -- 1-4
		lowpass : integer := 1; -- 0=lowpass off, 1=lowpass on (leave on except if there is no space! Low impact...)
		enable_auto_stereo : integer := 0;   -- 1=auto detect a4 => not toggling => mono

		fancy_switch_bit : integer := 20; -- 0=ext is low => mono
		gtia_audio_bit : integer := 0;    -- 0=no gtia on l/r,1=gtia mixed on l/r
		xel_mode : integer := 0;    -- 1=ignore CS1
		a4_bit : integer := 0;
		a5_bit : integer := 0;
		a6_bit : integer := 0;
		a7_bit : integer := 0;

		ext_bits : integer := 3; 

		enable_config : integer := 1;
		enable_sid : integer := 0;
		enable_psg : integer := 0;
		enable_covox : integer := 0;
		enable_sample : integer := 0;
		enable_flash : integer := 0;

   		version : STRING  := "DEVELOPR" -- 8 char string atascii
	);
	PORT
	(
		PHI2 : IN STD_LOGIC;
		
		CLK_OUT : OUT STD_LOGIC; -- Use PHI2 and internal oscillator to create a clock, feed out here
		CLK_SLOW : IN STD_LOGIC; -- ... and back in here, then to pll!		
		
		D :  INOUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		A :  IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
		W_N : IN STD_LOGIC;
		IRQ : INOUT STD_LOGIC;
		SOD : OUT STD_LOGIC;
		ACLK : OUT STD_LOGIC;
		BCLK : INOUT STD_LOGIC;
		SID : IN STD_LOGIC;
		CS0_N : IN STD_LOGIC;
		CS1 : IN STD_LOGIC;

		AUD : OUT STD_LOGIC_VECTOR(4 DOWNTO 1);

		EXT : INOUT STD_LOGIC_VECTOR(EXT_BITS DOWNTO 1);

		PADDLE : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		POTRESET_N : OUT STD_LOGIC;

		IOX_RST : OUT STD_LOGIC;
		IOX_INT : IN STD_LOGIC;
		IOX_SDA : INOUT STD_LOGIC;
		IOX_SCL : INOUT STD_LOGIC
	);
END pokeymax;		
		
ARCHITECTURE vhdl OF pokeymax IS
	component int_osc is
	port (
		clkout : out std_logic;        -- clkout.clk
		oscena : in  std_logic := '0'  -- oscena.oscena
	);
	end component;

	component pll
		port (
			inclk0   : in  std_logic := '0';
			c0 : out std_logic;
			c1 : out std_logic;
			locked   : out std_logic
		);
	end component;

	signal OSC_CLK : std_logic; -- about 82MHz! Always?? Massive range on data sheet

	signal CLK : std_logic;
	signal CLK116 : std_logic;
	signal RESET_N : std_logic;

	signal ENABLE_CYCLE : std_logic;

	-- WRITE ENABLES
	SIGNAL POKEY_WRITE_ENABLE : STD_LOGIC_VECTOR(3 downto 0);		
	
	SIGNAL SID_WRITE_ENABLE : STD_LOGIC_VECTOR(1 downto 0);	

	SIGNAL PSG_READ_ENABLE : STD_LOGIC_VECTOR(1 downto 0);	
	SIGNAL PSG_WRITE_ENABLE : STD_LOGIC_VECTOR(1 downto 0);	

	SIGNAL SAMPLE_WRITE_ENABLE : STD_LOGIC;	
	SIGNAL CONFIG_WRITE_ENABLE : STD_LOGIC;	
	
	-- DATA OUTS
	type DO_TYPE is array (NATURAL range <>) of std_logic_vector(7 downto 0);
	
	SIGNAL POKEY_DO : DO_TYPE(3 downto 0);	
	
	SIGNAL SID_DO : DO_TYPE(1 downto 0);
	
	SIGNAL PSG_DO : DO_TYPE(1 DOWNTO 0);	
	
	SIGNAL SAMPLE_DO : STD_LOGIC_VECTOR(7 DOWNTO 0);	
	SIGNAL CONFIG_DO : STD_LOGIC_VECTOR(7 DOWNTO 0);	
	
	-- POKEY	
	type POKEY_AUDIO is array(NATURAL range<>) of std_logic_vector(3 downto 0);
	signal POKEY_CHANNEL0 : POKEY_AUDIO(3 downto 0);
	signal POKEY_CHANNEL1 : POKEY_AUDIO(3 downto 0);
	signal POKEY_CHANNEL2 : POKEY_AUDIO(3 downto 0);
	signal POKEY_CHANNEL3 : POKEY_AUDIO(3 downto 0);

	signal CHANNEL0SUM_NEXT : unsigned(5 downto 0);	
	signal CHANNEL1SUM_NEXT : unsigned(5 downto 0);
	signal CHANNEL2SUM_NEXT : unsigned(5 downto 0);
	signal CHANNEL3SUM_NEXT : unsigned(5 downto 0);
	signal CHANNEL0SUM_REG : unsigned(5 downto 0);	
	signal CHANNEL1SUM_REG : unsigned(5 downto 0);
	signal CHANNEL2SUM_REG : unsigned(5 downto 0);
	signal CHANNEL3SUM_REG : unsigned(5 downto 0);	
	
	signal SIO_CLOCKIN_IN : std_logic;
	signal SIO_CLOCKIN_OUT : std_logic;
	signal SIO_CLOCKIN_OE : std_logic;
	signal SIO_CLOCKOUT : std_logic;

	signal SIO_TXD : std_logic;
	signal SIO_RXD : std_logic;

	signal POKEY_IRQ : std_logic_vector(3 downto 0);

	signal ADDR_IN : std_logic_vector(7 downto 0);
	signal WRITE_DATA : std_logic_vector(7 downto 0);
	signal DEVICE_ADDR : std_logic_vector(3 downto 0);

	signal POKEY_AUDIO_0 : signed(15 downto 0);
	signal POKEY_AUDIO_1 : signed(15 downto 0);
	signal POKEY_AUDIO_2 : signed(15 downto 0);
	signal POKEY_AUDIO_3 : signed(15 downto 0);
	
	signal AUDIO_0_UNSIGNED : unsigned(15 downto 0);
	signal AUDIO_1_UNSIGNED : unsigned(15 downto 0);
	signal AUDIO_2_UNSIGNED : unsigned(15 downto 0);
	signal AUDIO_3_UNSIGNED : unsigned(15 downto 0);	
	
	signal AUDIO_0_SIGMADELTA : std_logic;
	signal AUDIO_1_SIGMADELTA : std_logic;
	signal AUDIO_2_SIGMADELTA : std_logic;
	signal AUDIO_3_SIGMADELTA : std_logic;

	signal KEYBOARD_SCAN : std_logic_vector(5 downto 0);
	signal KEYBOARD_RESPONSE : std_logic_vector(1 downto 0);
	signal KEYBOARD_SCAN_ENABLE : std_logic;

	-- SID
	signal SID_CLK_ENABLE : std_logic;
	type SID_AUDIO_TYPE is array(NATURAL range<>) of std_logic_vector(15 downto 0);
	signal SID_AUDIO : SID_AUDIO_TYPE(1 downto 0);
	
	-- PSG
	signal PSG_ENABLE_2Mhz : std_logic;
	signal PSG_ENABLE_1Mhz : std_logic;
	signal PSG_ENABLE_1_7Mhz : std_logic;
	signal PSG_ENABLE : std_logic;
	type PSG_AUDIO_TYPE is array(NATURAL range<>) of std_logic_vector(15 downto 0);
	signal PSG_AUDIO : PSG_AUDIO_TYPE(3 downto 0);	

	signal PSG_FREQ_REG : std_logic_vector(1 downto 0);
	signal PSG_FREQ_NEXT : std_logic_vector(1 downto 0);

	signal PSG_STEREOMODE_REG : std_logic_vector(1 downto 0);
	signal PSG_STEREOMODE_NEXT : std_logic_vector(1 downto 0);

	signal PSG_ENVELOPE16_REG : std_logic;
	signal PSG_ENVELOPE16_NEXT : std_logic;

	signal PSG_MIX11 : std_logic_vector(2 downto 0);
	signal PSG_MIX12 : std_logic_vector(2 downto 0);
	signal PSG_MIX21 : std_logic_vector(2 downto 0);
	signal PSG_MIX22 : std_logic_vector(2 downto 0);
	
	-- SUPPORT	
	signal BUS_DATA : std_logic_vector(7 downto 0);
	signal BUS_OE : std_logic;

	signal REQUEST : std_logic;
	signal WRITE_N : std_logic;

	signal DO_MUX : std_logic_vector(7 downto 0);

	signal i2c0_ena : std_logic;
	signal i2c0_addr : std_logic_vector(7 downto 1);
	signal i2c0_rw : std_logic;
	signal i2c0_write_data : std_logic_vector(7 downto 0);
	signal i2c0_busy : std_logic;
	signal i2c0_read_data : std_logic_vector(7 downto 0);
	signal i2c0_error : std_logic;

	signal CS_COMB : std_logic;

	signal AIN : std_logic_vector(7 downto 0);

	signal POTRESET : std_logic;

	signal FANCY_ENABLE : std_logic;
	signal FANCY_SWITCH : std_logic;
	signal A4_DETECTED : std_logic;
	signal GTIA_AUDIO : std_logic;

	signal EXT_INT : std_logic_vector(20 downto 0);

	-- DETECT RIGHT PLAYING
	signal RIGHT_PLAYING_RECENTLY : std_logic;
	signal RIGHT_NEXT : unsigned(5 downto 0);
	signal RIGHT_REG : unsigned(5 downto 0);
	signal RIGHT_PLAYING_COUNT_NEXT : unsigned(23 downto 0);
	signal RIGHT_PLAYING_COUNT_REG : unsigned(23 downto 0);
	
	-- config
		--config regs
	signal DETECT_RIGHT_REG : std_logic;
	signal IRQ_EN_REG : std_logic;
	signal CHANNEL_MODE_REG : std_logic;
	signal SATURATE_REG : std_logic;
	signal POST_DIVIDE_REG : std_logic_vector(7 downto 0);	
	signal GTIA_ENABLE_REG : std_logic_vector(3 downto 0);
	signal VERSION_LOC_REG : std_logic_vector(2 downto 0);
	
	signal DETECT_RIGHT_NEXT : std_logic;
	signal IRQ_EN_NEXT : std_logic;
	signal CHANNEL_MODE_NEXT : std_logic;
	signal SATURATE_NEXT : std_logic;
	signal POST_DIVIDE_NEXT : std_logic_vector(7 downto 0);
	signal GTIA_ENABLE_NEXT : std_logic_vector(3 downto 0);
	signal VERSION_LOC_NEXT : std_logic_vector(2 downto 0);
	
		--config infra
	signal addr_decoded4 : std_logic_vector(15 downto 0);	
	signal addr_decoded5 : std_logic_vector(31 downto 0);	
	signal CONFIG_ENABLE_REG : std_logic;
	signal CONFIG_ENABLE_NEXT: std_logic;
	
	-- SAMPLE/COVOX
	signal SAMPLE_CH2_REG : std_logic_vector(7 downto 0);
	signal SAMPLE_CH1_REG : std_logic_vector(7 downto 0);
	signal SAMPLE_CH2_NEXT : std_logic_vector(7 downto 0);
	signal SAMPLE_CH1_NEXT : std_logic_vector(7 downto 0);
	signal SAMPLE_CH4_REG : std_logic_vector(7 downto 0);
	signal SAMPLE_CH3_REG : std_logic_vector(7 downto 0);
	signal SAMPLE_CH4_NEXT : std_logic_vector(7 downto 0);
	signal SAMPLE_CH3_NEXT : std_logic_vector(7 downto 0);

	type SAMPLE_AUDIO_TYPE is array(NATURAL range<>) of std_logic_vector(15 downto 0);
	signal SAMPLE_AUDIO : SAMPLE_AUDIO_TYPE(1 downto 0);

	-- FLASH
	signal flash_do : std_logic_vector(31 downto 0);

	signal CPU_FLASH_REQUEST_NEXT : std_logic;
	signal CPU_FLASH_REQUEST_REG : std_logic;
	signal CPU_FLASH_WRITE_N_NEXT : std_logic;
	signal CPU_FLASH_WRITE_N_REG : std_logic;
	signal CPU_FLASH_CFG_NEXT : std_logic;
	signal CPU_FLASH_CFG_REG : std_logic;
	signal CPU_FLASH_ADDR_NEXT : std_logic_vector(17 downto 0);
	signal CPU_FLASH_ADDR_REG : std_logic_vector(17 downto 0);
	signal CPU_FLASH_DATA_NEXT : std_logic_vector(31 downto 0);
	signal CPU_FLASH_DATA_REG : std_logic_vector(31 downto 0);
	signal CPU_FLASH_COMPLETE : std_logic;

	signal CONFIG_FLASH_STATE_REG : std_logic_vector(1 downto 0);
	signal CONFIG_FLASH_STATE_NEXT : std_logic_vector(1 downto 0);
	constant CONFIG_FLASH_STATE_ADDR1 : std_logic_vector(1 downto 0) := "00";
	constant CONFIG_FLASH_STATE_ADDR2 : std_logic_vector(1 downto 0) := "01";
	constant CONFIG_FLASH_STATE_DONE : std_logic_vector(1 downto 0) := "10";
	signal CONFIG_FLASH_REQUEST : std_logic;
	signal CONFIG_FLASH_COMPLETE : std_logic;
	signal CONFIG_FLASH_ADDR : std_logic_vector(0 downto 0);

	function getByte(a : string; x : integer) return std_logic_vector is
   		 variable ret : std_logic_vector(7 downto 0);
	begin
	        ret := std_logic_vector(to_unsigned(character'pos(a(x)), 8));
	    return ret;
	end function getByte;
	
BEGIN
	IOX_RST <= 'Z'; -- TODO weak pull up in pins (see TODO file)
	EXT <= (others=>'Z');

xel_mode_on : if xel_mode=1 generate 
	CS_COMB <= not(CS0_N);
end generate;

xel_mode_off : if xel_mode=0 generate 
	CS_COMB <= CS1 and not(CS0_N);
end generate;

	oscillator : int_osc
	port map 
	(
		clkout => OSC_CLK, 
		oscena => '1'
	);

flash_on : if enable_flash=1 generate 

	process(CLK116,RESET_N)
	begin
		if (RESET_N='0') then
			CPU_FLASH_REQUEST_REG <= '0';
			CPU_FLASH_WRITE_N_REG <= '1';
			CPU_FLASH_CFG_REG <= '0';
			CPU_FLASH_ADDR_REG <= (others=>'0');
			CPU_FLASH_DATA_REG <= (others=>'0');
			CONFIG_FLASH_STATE_REG <= CONFIG_FLASH_STATE_ADDR1;
		elsif (CLK116'event and CLK116='1') then
			CPU_FLASH_REQUEST_REG <= CPU_FLASH_REQUEST_NEXT;
			CPU_FLASH_WRITE_N_REG <= CPU_FLASH_WRITE_N_NEXT;
			CPU_FLASH_CFG_REG <= CPU_FLASH_CFG_NEXT;
			CPU_FLASH_ADDR_REG <= CPU_FLASH_ADDR_NEXT;
			CPU_FLASH_DATA_REG <= CPU_FLASH_DATA_NEXT;
			CONFIG_FLASH_STATE_REG <= CONFIG_FLASH_STATE_NEXT;
		end if;
	end process;

	-- TODO:req2 initially reads some data for the config regs
	-- then the state machine fills the entirely of block ram
	-- say it takes 10 cycles for 32-bits, this will take... 0.7ms, should be ok... 44MB/s!
	flash_controller_inst : entity work.flash_controller
	port map
	(
		CLK => CLK116,
		RESET_N => RESET_N,

		-- Request from device 1 (cpu)
		flash_req1_addr_config => CPU_FLASH_CFG_REG,
		flash_req1_addr => CPU_FLASH_ADDR_REG(17 downto 2),
		flash_req1_data_in => CPU_FLASH_DATA_REG,
		flash_req1_write_n => CPU_FLASH_WRITE_N_REG,

		flash_req2_addr(12 downto 1) => (others=>'0'),   -- first 2 32-bit words are config!
		flash_req2_addr(0 downto 0) => CONFIG_FLASH_ADDR(0 downto 0),

		flash_req_request(0) => CPU_FLASH_REQUEST_REG,
		flash_req_request(1) => CONFIG_FLASH_REQUEST,
		flash_req_request(7 downto 2) => (others=>'0'),
		flash_req_complete(0) => CPU_FLASH_COMPLETE,
		flash_req_complete(1) => CONFIG_FLASH_COMPLETE,
		flash_req_complete(7 downto 2) => open,

		flash_data_out => flash_do
	);

	-- initialize the registers from flash

	-- flash memory map
	-- 32KB
	-- 0x0000-0x07ff - 2k configuration (regs, psg vol curve, pokey mixing curve, sid filter piecewise linear?)
	-- 	first 64 bits - config regs 
	-- 0x0800-0x3fff - 14k sid tables
	-- 0x4000-0x7fff - 16k fixed samples?

	-- reg init
	process(CONFIG_FLASH_STATE_REG, CONFIG_FLASH_COMPLETE)
	begin
		CONFIG_FLASH_REQUEST <= '0';
		CONFIG_FLASH_STATE_NEXT <= CONFIG_FLASH_STATE_REG;
		CONFIG_FLASH_ADDR <= "0";

		case CONFIG_FLASH_STATE_REG is
			when CONFIG_FLASH_STATE_ADDR1 =>
				CONFIG_FLASH_REQUEST <= '1';
				CONFIG_FLASH_ADDR <= "0";
				if (CONFIG_FLASH_COMPLETE='1') then
					CONFIG_FLASH_STATE_NEXT <= CONFIG_FLASH_STATE_ADDR2;
				end if;
			when CONFIG_FLASH_STATE_ADDR2 =>
				CONFIG_FLASH_REQUEST <= '1';
				CONFIG_FLASH_ADDR <= "1";
				if (CONFIG_FLASH_COMPLETE='1') then
					CONFIG_FLASH_STATE_NEXT <= CONFIG_FLASH_STATE_DONE;
				end if;
			when others=>
		end case;
	end process;
end generate;

	EXT_INT(0) <= '0';  --force to 0
	EXT_INT(20 downto ext_bits+1) <= (others=>'1');
	EXT_INT(ext_bits downto 1) <= EXT;

        synchronizer_gtia_audio : entity work.synchronizer
                port map (clk=>clk, raw=>EXT_INT(gtia_audio_bit), sync=>GTIA_AUDIO);
        synchronizer_fancy_enable : entity work.synchronizer
		port map (clk=>clk, raw=>EXT_INT(fancy_switch_bit), sync=>FANCY_SWITCH);

	--assert address_bits<7 report "EXT3 already used for A6";

	CLK_OUT <= OSC_CLK;

	pll_inst : pll
	PORT MAP(inclk0 => CLK_SLOW,
			 c0 => CLK, --56 ish
			 c1 => CLK116,  --113ish
			 locked => RESET_N);


	AIN(3 downto 0) <= A;
	AIN(7) <= EXT_INT(a7_bit);
	AIN(6) <= EXT_INT(a6_bit);
	AIN(5) <= EXT_INT(a5_bit);
	AIN(4) <= EXT_INT(a4_bit);

bus_adapt : entity work.slave_timing_6502
	GENERIC MAP
	(
		address_bits => 8
	)
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N,
		
		-- input from the cart port
		PHI2 => PHI2,
		bus_addr => AIN, 
		bus_data => D,
	
		-- output to the cart port
		bus_data_out => BUS_DATA,
		bus_drive => BUS_OE,
		bus_cs => CS_COMB,
		bus_rw_n => W_N,

		-- request for a memory bus cycle (read or write)
		BUS_REQUEST => REQUEST,
		ADDR_IN => ADDR_IN,
		DATA_IN => WRITE_DATA,
		RW_N => WRITE_N,

		-- end of cycle
		ENABLE_CYCLE => ENABLE_CYCLE,

		DATA_OUT => DO_MUX
	);
	
auto_stereo : if enable_auto_stereo=1 generate -- auto detect
	a4 : ENTITY work.stereo_detect
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,
	
		A => AIN(4), -- raw...
		DETECT => A4_DETECTED
	);
end generate;

auto_stereo_off : if enable_auto_stereo=0 generate -- manual switch
	A4_DETECTED <= '1';
end generate;

FANCY_ENABLE <= FANCY_SWITCH and A4_DETECTED;
	
-- TODO: into another entity
process(clk)
begin
	if (clk'event and clk='1') then
		CHANNEL0SUM_REG <= CHANNEL0SUM_NEXT;
		CHANNEL1SUM_REG <= CHANNEL1SUM_NEXT;
		CHANNEL2SUM_REG <= CHANNEL2SUM_NEXT;
		CHANNEL3SUM_REG <= CHANNEL3SUM_NEXT;
	end if;
end process;

	
process(
	POKEY_CHANNEL0,POKEY_CHANNEL1,POKEY_CHANNEL2,POKEY_CHANNEL3,
	CHANNEL_MODE_REG -- 0=pokeys have a channel each,1=ch 0 summed, ch 1 summed, ch 2 summed etc
	)
variable p0 : unsigned(5 downto 0);	
variable p1 : unsigned(5 downto 0);
variable p2 : unsigned(5 downto 0);
variable p3 : unsigned(5 downto 0);

variable c0 : unsigned(5 downto 0);	
variable c1 : unsigned(5 downto 0);
variable c2 : unsigned(5 downto 0);
variable c3 : unsigned(5 downto 0);	
	
variable sum0 : unsigned(5 downto 0);	
variable sum1 : unsigned(5 downto 0);
variable sum2 : unsigned(5 downto 0);
variable sum3 : unsigned(5 downto 0);

variable GTIA_VOLUME_SUM : unsigned(9 downto 0);
begin
	p0 := resize(unsigned(POKEY_CHANNEL0(0)),6) + resize(unsigned(POKEY_CHANNEL1(0)),6) + resize(unsigned(POKEY_CHANNEL2(0)),6) + resize(unsigned(POKEY_CHANNEL3(0)),6);
	p1 := resize(unsigned(POKEY_CHANNEL0(1)),6) + resize(unsigned(POKEY_CHANNEL1(1)),6) + resize(unsigned(POKEY_CHANNEL2(1)),6) + resize(unsigned(POKEY_CHANNEL3(1)),6);
	p2 := resize(unsigned(POKEY_CHANNEL0(2)),6) + resize(unsigned(POKEY_CHANNEL1(2)),6) + resize(unsigned(POKEY_CHANNEL2(2)),6) + resize(unsigned(POKEY_CHANNEL3(2)),6);
	p3 := resize(unsigned(POKEY_CHANNEL0(3)),6) + resize(unsigned(POKEY_CHANNEL1(3)),6) + resize(unsigned(POKEY_CHANNEL2(3)),6) + resize(unsigned(POKEY_CHANNEL3(3)),6);
	
	c0 := resize(unsigned(POKEY_CHANNEL0(0)),6) + resize(unsigned(POKEY_CHANNEL0(1)),6) + resize(unsigned(POKEY_CHANNEL0(2)),6) + resize(unsigned(POKEY_CHANNEL0(3)),6);
	c1 := resize(unsigned(POKEY_CHANNEL1(0)),6) + resize(unsigned(POKEY_CHANNEL1(1)),6) + resize(unsigned(POKEY_CHANNEL1(2)),6) + resize(unsigned(POKEY_CHANNEL1(3)),6);
	c2 := resize(unsigned(POKEY_CHANNEL2(0)),6) + resize(unsigned(POKEY_CHANNEL2(1)),6) + resize(unsigned(POKEY_CHANNEL2(2)),6) + resize(unsigned(POKEY_CHANNEL2(3)),6);
	c3 := resize(unsigned(POKEY_CHANNEL3(0)),6) + resize(unsigned(POKEY_CHANNEL3(1)),6) + resize(unsigned(POKEY_CHANNEL3(2)),6) + resize(unsigned(POKEY_CHANNEL3(3)),6);	
	
	if CHANNEL_MODE_REG ='1' then
		sum0 := c0;
		sum1 := c1;
		sum2 := c2;
		sum3 := c3;	
	else
		sum0 := p0;
		sum1 := p1;
		sum2 := p2;
		sum3 := p3;	
	end if;
	
	CHANNEL0SUM_NEXT <= sum0;
	CHANNEL1SUM_NEXT <= sum1;
	CHANNEL2SUM_NEXT <= sum2;
	CHANNEL3SUM_NEXT <= sum3;
end process;
	
pokey_mixer_both : entity work.pokey_mixer_mux
PORT MAP(CLK => CLK,
		 CHANNEL_0 => CHANNEL0SUM_REG,
		 CHANNEL_1 => CHANNEL1SUM_REG,
		 CHANNEL_2 => CHANNEL2SUM_REG,
		 CHANNEL_3 => CHANNEL3SUM_REG,
		 VOLUME_OUT_0 => POKEY_AUDIO_0,
		 VOLUME_OUT_1 => POKEY_AUDIO_1,
		 VOLUME_OUT_2 => POKEY_AUDIO_2,
		 VOLUME_OUT_3 => POKEY_AUDIO_3,
		 SATURATE => SATURATE_REG
		 );

--------------------------------------------------------
-- PRIMARY POKEY		 GTIA_VOLUME_
--------------------------------------------------------
pokey1 : entity work.pokey
GENERIC MAP
(
	custom_keyboard_scan => 1
)
PORT MAP(CLK => CLK,
		 ENABLE_179 => ENABLE_CYCLE,
		 WR_EN => POKEY_WRITE_ENABLE(0),
		 RESET_N => RESET_N,
		 SIO_IN1 => SIO_RXD,
		 SIO_IN2 => '1',
		 SIO_IN3 => '1',
		 SIO_CLOCKIN_IN => SIO_CLOCKIN_IN,
		 SIO_CLOCKIN_OUT => SIO_CLOCKIN_OUT,
		 SIO_CLOCKIN_OE => SIO_CLOCKIN_OE,
		 ADDR => ADDR_IN(3 DOWNTO 0),
		 DATA_IN => WRITE_DATA(7 DOWNTO 0),
		 keyboard_response => KEYBOARD_RESPONSE,
		 POT_IN => PADDLE,
		 IRQ_N_OUT => POKEY_IRQ(0),
		 SIO_OUT1 => SIO_TXD,
		 SIO_OUT2 => open,
		 SIO_OUT3 => open,
		 SIO_CLOCKOUT => SIO_CLOCKOUT,
		 POT_RESET => POTRESET,
		 CHANNEL_0_OUT => POKEY_CHANNEL0(0),
		 CHANNEL_1_OUT => POKEY_CHANNEL1(0),
		 CHANNEL_2_OUT => POKEY_CHANNEL2(0),
		 CHANNEL_3_OUT => POKEY_CHANNEL3(0),
		 DATA_OUT => POKEY_DO(0),
		 keyboard_scan => KEYBOARD_SCAN,
		 keyboard_scan_enable => KEYBOARD_SCAN_ENABLE
		);

--------------------------------------------------------		
-- POKEY 2-4	 
--------------------------------------------------------		
   POKEY_OFF: 
   for I in pokeys to 3 generate
      POKEY_CHANNEL0(I) <= (others=>'0');
		POKEY_CHANNEL1(I) <= (others=>'0');
		POKEY_CHANNEL2(I) <= (others=>'0');
		POKEY_CHANNEL3(I) <= (others=>'0');
		POKEY_IRQ(I) <= '1';
		POKEY_DO(I) <= (others=>'0');
   end generate POKEY_OFF;		

   POKEY_ON: 
   for I in 1 to pokeys-1 generate
		pokeyx : entity work.pokey
		GENERIC MAP
		(
			custom_keyboard_scan => 2
		)
		PORT MAP(CLK => CLK,
				 ENABLE_179 => ENABLE_CYCLE,
				 WR_EN => POKEY_WRITE_ENABLE(I),
				 RESET_N => RESET_N,
				 ADDR => ADDR_IN(3 DOWNTO 0),
				 DATA_IN => WRITE_DATA(7 DOWNTO 0),
				 CHANNEL_0_OUT => POKEY_CHANNEL0(I),
				 CHANNEL_1_OUT => POKEY_CHANNEL1(I),
				 CHANNEL_2_OUT => POKEY_CHANNEL2(I),
				 CHANNEL_3_OUT => POKEY_CHANNEL3(I),
				 DATA_OUT => POKEY_DO(I),
				 SIO_IN1 => '1',
				 SIO_IN2 => '1',
				 SIO_IN3 => '1',
				 IRQ_N_OUT => POKEY_IRQ(I),
				 keyboard_response => "00",
				 pot_in=>"00000000");
   end generate POKEY_ON;

--------------------------------------------------------
-- SID
--------------------------------------------------------
sid_off : if enable_sid=0 generate 
	SID_AUDIO(0) <= (others=>'0');
	SID_AUDIO(1) <= (others=>'0');
	SID_DO(0) <= (others=>'0');
	SID_DO(1) <= (others=>'0');
end generate sid_off;

sid_on : if enable_sid=1 generate 
	enable_sid_div : entity work.syncreset_enable_divider
          generic map (COUNT=>58,RESETCOUNT=>6) -- 28-22
          port map(clk=>clk,syncreset=>'0',reset_n=>reset_n,enable_in=>'1',enable_out=>SID_CLK_ENABLE);

sid1 : entity work.SID_top
GENERIC MAP
(
	CLKSPEED => 58333333 --TODO
)
PORT MAP(
	CLK => CLK,
	RESET_N => RESET_N,
	ENABLE => SID_CLK_ENABLE, --1MHz

	WRITE_ENABLE => SID_WRITE_ENABLE(0),
	ADDR => ADDR_IN(4 downto 0),
	DI => WRITE_DATA(7 downto 0),
	DO => SID_DO(0),
	--POT_X => (others=>'0'),
	--POT_Y => (others=>'0'),
	--EXTFILTER_EN => '0',
	AUDIO => SID_AUDIO(0) --TODO: review volume, can't really be 17 bits!!
);

sid2 : entity work.SID_top
GENERIC MAP
(
	CLKSPEED => 58333333 --TODO
)
PORT MAP(
	CLK => CLK,
	RESET_N => RESET_N,
	ENABLE => SID_CLK_ENABLE, --1MHz

	WRITE_ENABLE => SID_WRITE_ENABLE(1),
	ADDR => ADDR_IN(4 downto 0),
	DI => WRITE_DATA(7 downto 0),
	DO => SID_DO(1),
	--POT_X => (others=>'0'),
	--POT_Y => (others=>'0'),
	--EXTFILTER_EN => '0',
	AUDIO => SID_AUDIO(1)
);
end generate sid_on;		
--------------------------------------------------------
-- PSG
--------------------------------------------------------
psg_off : if enable_psg=0 generate 
	PSG_AUDIO(0) <= (others=>'0');
	PSG_AUDIO(1) <= (others=>'0');
	PSG_DO(0) <= (others=>'0');
	PSG_DO(1) <= (others=>'0');
end generate psg_off;

-- VERY approx (for now) PSG master clock!
psg_on : if enable_psg=1 generate 
enable_psg_div2 : entity work.syncreset_enable_divider
  generic map (COUNT=>29,RESETCOUNT=>6) -- 28-22
  port map(clk=>clk,syncreset=>'0',reset_n=>reset_n,enable_in=>'1',enable_out=>PSG_ENABLE_2MHz);

enable_psg_div1 : entity work.syncreset_enable_divider
  generic map (COUNT=>58,RESETCOUNT=>6) -- 28-22
  port map(clk=>clk,syncreset=>'0',reset_n=>reset_n,enable_in=>'1',enable_out=>PSG_ENABLE_1MHz);

enable_psg_div_1_7 : entity work.syncreset_enable_divider
  generic map (COUNT=>33,RESETCOUNT=>6) -- 28-22
  port map(clk=>clk,syncreset=>'0',reset_n=>reset_n,enable_in=>'1',enable_out=>PSG_ENABLE_1_7MHz);

process(PSG_FREQ_REG,PSG_ENABLE_2MHz,PSG_ENABLE_1MHz,PSG_ENABLE_1_7MHz,ENABLE_CYCLE)
begin
	PSG_ENABLE <= '0';

	case PSG_FREQ_REG is
		when "00"=>
			PSG_ENABLE <= PSG_ENABLE_2MHz;
		when "01"=>
			PSG_ENABLE <= PSG_ENABLE_1MHz;
		when "10"=>
			PSG_ENABLE <= PSG_ENABLE_1_7Mhz;
		when others=>
			PSG_ENABLE <= PSG_ENABLE_2MHz;
	end case;
end process;

process(PSG_STEREOMODE_REG)
begin
	PSG_MIX11 <= (others=>'0');
	PSG_MIX12 <= (others=>'0');
	PSG_MIX21 <= (others=>'0');
	PSG_MIX22 <= (others=>'0');

	case PSG_STEREOMODE_REG is
		when "00"=>
			PSG_MIX11 <= "111";
			PSG_MIX12 <= "111";
			PSG_MIX21 <= "111";
			PSG_MIX22 <= "111";
		when "01"=>
			PSG_MIX11 <= "110";
			PSG_MIX12 <= "011";
			PSG_MIX21 <= "110";
			PSG_MIX22 <= "011";
		when "10"=>
			PSG_MIX11 <= "101";
			PSG_MIX12 <= "011";
			PSG_MIX21 <= "101";
			PSG_MIX22 <= "011";
		when others=>
			PSG_MIX11 <= "111";
			PSG_MIX22 <= "111";
	end case;
end process;

PSG_1 : entity work.PSG_top
  port map(
	clk=>clk,
	reset_n=>reset_n,
	enable=>psg_enable,
	addr=>addr_in(3 downto 0),
	write_enable=>PSG_WRITE_ENABLE(0),
	ENVELOPE32=>not(PSG_ENVELOPE16_REG),
	MASK1=>PSG_MIX11,
	MASK2=>PSG_MIX12,
	di=>write_data,
	do=>PSG_DO(0),
	audio1=>PSG_AUDIO(0),
	audio2=>PSG_AUDIO(1)
	);
	
PSG_2 : entity work.PSG_top
  port map(
	clk=>clk,
	reset_n=>reset_n,
	enable=>psg_enable, 
	addr=>addr_in(3 downto 0),
	write_enable=>PSG_WRITE_ENABLE(1),
	ENVELOPE32=>not(PSG_ENVELOPE16_REG),
	MASK1=>PSG_MIX21,
	MASK2=>PSG_MIX22,
	di=>write_data,
	do=>PSG_DO(1),
	audio1=>PSG_AUDIO(2),
	audio2=>PSG_AUDIO(3)
	);
end generate psg_on;		
	
--------------------------------------------------------
-- COVOX
--------------------------------------------------------
covox_off : if enable_covox=0 generate 
	SAMPLE_CH1_REG <= (others=>'0');
	SAMPLE_CH2_REG <= (others=>'0');
	SAMPLE_CH3_REG <= (others=>'0');
	SAMPLE_CH4_REG <= (others=>'0');
	SAMPLE_DO <= (others=>'0');
	SAMPLE_AUDIO(0) <= (others=>'0');
	SAMPLE_AUDIO(1) <= (others=>'0');
end generate covox_off;

covox_on : if enable_covox=1 generate 
process(addr_decoded5,SAMPLE_CH1_REG,SAMPLE_CH2_REG,SAMPLE_CH3_REG,SAMPLE_CH4_REG)
begin
	SAMPLE_DO <= (others=>'0');

	if (addr_decoded5(0)='1') then
		SAMPLE_DO <= SAMPLE_CH1_REG;
	end if;

	if (addr_decoded5(1)='1') then
		SAMPLE_DO <= SAMPLE_CH2_REG;
	end if;

	if (addr_decoded5(2)='1') then
		SAMPLE_DO <= SAMPLE_CH3_REG;
	end if;

	if (addr_decoded5(3)='1') then
		SAMPLE_DO <= SAMPLE_CH4_REG;
	end if;
end process;

process(addr_decoded5, SAMPLE_WRITE_ENABLE,
SAMPLE_CH1_REG,SAMPLE_CH2_REG,SAMPLE_CH3_REG,SAMPLE_CH4_REG,WRITE_DATA)
	variable l : unsigned(8 downto 0);
	variable r : unsigned(8 downto 0);
begin
	SAMPLE_CH1_NEXT <= SAMPLE_CH1_REG;
	SAMPLE_CH2_NEXT <= SAMPLE_CH2_REG;
	SAMPLE_CH3_NEXT <= SAMPLE_CH3_REG;
	SAMPLE_CH4_NEXT <= SAMPLE_CH4_REG;

	l := resize(unsigned(SAMPLE_CH1_REG),9) + resize(unsigned(SAMPLE_CH4_REG),9);
	r := resize(unsigned(SAMPLE_CH2_REG),9) + resize(unsigned(SAMPLE_CH3_REG),9);
	SAMPLE_AUDIO(0) <= std_logic_vector(l)&"0000000";
	SAMPLE_AUDIO(1) <= std_logic_vector(r)&"0000000";

	if (SAMPLE_WRITE_ENABLE='1') then
		if (addr_decoded5(0)='1') then
			SAMPLE_CH1_NEXT <= WRITE_DATA;
		end if;
		if (addr_decoded5(1)='1') then
			SAMPLE_CH2_NEXT <= WRITE_DATA;
		end if;
		if (addr_decoded5(2)='1') then
			SAMPLE_CH3_NEXT <= WRITE_DATA;
		end if;
		if (addr_decoded5(3)='1') then
			SAMPLE_CH4_NEXT <= WRITE_DATA;
		end if;
	end if;
end process;

process(clk,reset_n)
begin
	if (reset_n='0') then
		SAMPLE_CH1_REG <= (others=>'0');
		SAMPLE_CH2_REG <= (others=>'0');
		SAMPLE_CH3_REG <= (others=>'0');
		SAMPLE_CH4_REG <= (others=>'0');
	elsif (clk'event and clk='1') then
		SAMPLE_CH1_REG <= SAMPLE_CH1_NEXT;
		SAMPLE_CH2_REG <= SAMPLE_CH2_NEXT;
		SAMPLE_CH3_REG <= SAMPLE_CH3_NEXT;
		SAMPLE_CH4_REG <= SAMPLE_CH4_NEXT;
	end if;
end process;

end generate covox_on;
		
-------------------------------------------------------
-- COMMON, data bus
--
--
-- memory map
-- d200 - pokey0
-- d210 - pokey1
-- d220 - pokey2
-- d230 - pokey3
-- d240 - sid1
-- d260 - sid2
-- d280 - covox/sample
-- d2a0 - ym1 (mapped as 0-f, rather than convoluted 0/1)
-- d2b0 - ym2
-- d2f0 - config (write 0x3f to d21c to map it in d210, for low bit devices)

process(CONFIG_ENABLE_REG,ADDR_IN,addr_decoded4,FANCY_ENABLE)
	variable addr_bits : std_logic_vector(3 downto 0);
begin
	-- choose which bank
	addr_bits := (others=>'0');
	addr_bits(3 downto 0) := ADDR_IN(7 downto 4);
	
	if (fancy_enable='0') then
		addr_bits := (others=>'0');
	end if;

	if (addr_in(7 downto 40)=x"f") then -- TODO: tweak...
		addr_bits := x"0"; --disable config access here
	end if;
		
	if ((config_enable_reg='1' and addr_bits="0001") or (addr_bits(3 downto 2) = "00" and addr_decoded4(12)='1')) then
		addr_bits := x"f";
	end if;
	
	DEVICE_ADDR <= addr_bits;
end process;			

process(
	DEVICE_ADDR,
	POKEY_DO,
	SID_DO,
	PSG_DO,
	SAMPLE_DO,
	CONFIG_DO,
	write_n,
	request
	)
	variable writereq : std_logic;
	variable readreq : std_logic;
begin
	writereq := not(write_n) and request;
	readreq := write_n and request;
	
	POKEY_WRITE_ENABLE <= (others=>'0');
	SID_WRITE_ENABLE <= (others=>'0');
	PSG_WRITE_ENABLE <= (others=>'0');
	PSG_READ_ENABLE <= (others=>'0');
	SAMPLE_WRITE_ENABLE <= '0';
	CONFIG_WRITE_ENABLE <= '0';
	
	DO_MUX <= (others =>'0');
	
	case DEVICE_ADDR is
		when x"0" =>
			DO_MUX <= POKEY_DO(0);
			POKEY_WRITE_ENABLE(0) <= writereq;
		when x"1" =>
			DO_MUX <= POKEY_DO(1);
			POKEY_WRITE_ENABLE(1) <= writereq;
		when x"2" =>
			DO_MUX <= POKEY_DO(2);
			POKEY_WRITE_ENABLE(2) <= writereq;
		when x"3" =>
			DO_MUX <= POKEY_DO(3);
			POKEY_WRITE_ENABLE(3) <= writereq;
		when x"4"|x"5" =>
			DO_MUX <= SID_DO(0);
			SID_WRITE_ENABLE(0) <= writereq;
		when x"6"|x"7" =>
			DO_MUX <= SID_DO(1);
			SID_WRITE_ENABLE(1) <= writereq;
		when x"8"|x"9" =>
			DO_MUX <= SAMPLE_DO;								
			SAMPLE_WRITE_ENABLE <= writereq;			
		when x"a" =>
			DO_MUX <= PSG_DO(0);
			PSG_WRITE_ENABLE(0) <= writereq;
			PSG_READ_ENABLE(0) <= readreq;
		when x"b" =>
			DO_MUX <= PSG_DO(1);			
			PSG_WRITE_ENABLE(1) <= writereq;
			PSG_READ_ENABLE(1) <= readreq;
		when x"f" =>
			DO_MUX <= CONFIG_DO;
			CONFIG_WRITE_ENABLE <= writereq;
		when others =>
	end case;
end process;

-------------------------------------------------------
-- Configuration

process(clk,reset_n)
begin
	if (reset_n='0') then
		DETECT_RIGHT_REG <= '1';
		IRQ_EN_REG <= '0';
		CHANNEL_MODE_REG <= '0';
		SATURATE_REG <= '1';
		POST_DIVIDE_REG <= "10100000"; -- 1/2 5v, 3/4 1v
		GTIA_ENABLE_REG <= "1100"; -- external only
		CONFIG_ENABLE_REG <= '0';
		VERSION_LOC_REG <= (others=>'0');
		PSG_FREQ_REG <= "00"; --2MHz
		PSG_STEREOMODE_REG <= "01"; --Polish
		PSG_ENVELOPE16_REG <= '0'; --32 step
	elsif (clk'event and clk='1') then
		DETECT_RIGHT_REG <= DETECT_RIGHT_NEXT;
		IRQ_EN_REG <= IRQ_EN_NEXT;
		CHANNEL_MODE_REG <= CHANNEL_MODE_NEXT;
		SATURATE_REG <= SATURATE_NEXT;
		POST_DIVIDE_REG <= POST_DIVIDE_NEXT;
		GTIA_ENABLE_REG <= GTIA_ENABLE_NEXT;
		CONFIG_ENABLE_REG <= CONFIG_ENABLE_NEXT;
		VERSION_LOC_REG <= VERSION_LOC_NEXT;
		PSG_FREQ_REG <= PSG_FREQ_NEXT;
		PSG_STEREOMODE_REG <= PSG_STEREOMODE_NEXT;
		PSG_ENVELOPE16_REG <= PSG_ENVELOPE16_NEXT;
	end if;
end process;

-- default config

gen_config : if enable_config=1 generate

decode_addr1 : entity work.complete_address_decoder
	generic map(width=>4)
	port map (addr_in=>ADDR_IN(3 downto 0), addr_decoded=>addr_decoded4);

decode_addr2 : entity work.complete_address_decoder
	generic map(width=>5)
	port map (addr_in=>ADDR_IN(4 downto 0), addr_decoded=>addr_decoded5);
	
process(CONFIG_WRITE_ENABLE, WRITE_DATA, addr_decoded4,
	SATURATE_REG,CHANNEL_MODE_REG,IRQ_EN_REG,DETECT_RIGHT_REG,
	CONFIG_ENABLE_REG,
	POST_DIVIDE_REG,
	GTIA_ENABLE_REG,
	VERSION_LOC_REG,
	PSG_FREQ_REG,
	PSG_STEREOMODE_REG,
	PSG_ENVELOPE16_REG,
	CPU_FLASH_REQUEST_REG,CPU_FLASH_WRITE_N_REG,CPU_FLASH_CFG_REG,CPU_FLASH_ADDR_REG,CPU_FLASH_DATA_REG,
	CPU_FLASH_COMPLETE,CONFIG_FLASH_COMPLETE,CONFIG_FLASH_ADDR,flash_do
)
begin
	SATURATE_NEXT <= SATURATE_REG;
	CHANNEL_MODE_NEXT <= CHANNEL_MODE_REG;
	IRQ_EN_NEXT <= IRQ_EN_REG;
	DETECT_RIGHT_NEXT <= DETECT_RIGHT_REG;

	POST_DIVIDE_NEXT <= POST_DIVIDE_REG;
	
	GTIA_ENABLE_NEXT <= GTIA_ENABLE_REG;
	
	CONFIG_ENABLE_NEXT <= CONFIG_ENABLE_REG;
	
	VERSION_LOC_NEXT <= VERSION_LOC_REG;

	PSG_FREQ_NEXT <= PSG_FREQ_REG;
	PSG_STEREOMODE_NEXT <= PSG_STEREOMODE_REG;
	PSG_ENVELOPE16_NEXT <= PSG_ENVELOPE16_REG;

	CPU_FLASH_REQUEST_NEXT <= CPU_FLASH_REQUEST_REG;
	CPU_FLASH_WRITE_N_NEXT <= CPU_FLASH_WRITE_N_REG;
	CPU_FLASH_CFG_NEXT <= CPU_FLASH_CFG_REG;
	CPU_FLASH_ADDR_NEXT <= CPU_FLASH_ADDR_REG;
	CPU_FLASH_DATA_NEXT <= CPU_FLASH_DATA_REG;


	if (CPU_FLASH_COMPLETE='1') then
		CPU_FLASH_DATA_NEXT <= flash_do;
		CPU_FLASH_REQUEST_NEXT <= '0';
	end if;

	if (enable_flash=1 and CONFIG_FLASH_COMPLETE='1') then
		case CONFIG_FLASH_ADDR is
			when "0"=>
				SATURATE_NEXT <= flash_do(0);
					-- 1 reserved...
				CHANNEL_MODE_NEXT <= flash_do(2);
				IRQ_EN_NEXT <= flash_do(3);
				DETECT_RIGHT_NEXT <= flash_do(4);
					-- 5-7 reserved
				POST_DIVIDE_NEXT <= flash_do(15 downto 8);
				GTIA_ENABLE_NEXT <= flash_do(19 downto 16);
					-- 23 downto 20 reserved
				PSG_FREQ_NEXT <= flash_do(25 downto 24);
				PSG_STEREOMODE_NEXT <= flash_do(27 downto 26);
				PSG_ENVELOPE16_NEXT <= flash_do(28);
					-- 31 downto 29 reserved
			when "1" =>
			when others =>
		end case;
	elsif (CONFIG_WRITE_ENABLE='1') then
		if (addr_decoded4(0)='1') then
			SATURATE_NEXT <= WRITE_DATA(0);
			CHANNEL_MODE_NEXT <= WRITE_DATA(2);
			IRQ_EN_NEXT <= WRITE_DATA(3);
			DETECT_RIGHT_NEXT <= WRITE_DATA(4);
		end if;
		
		if (addr_decoded4(2)='1') then
			POST_DIVIDE_NEXT <= WRITE_DATA;
		end if;
				
		if (addr_decoded4(3)='1') then			
			GTIA_ENABLE_NEXT <= WRITE_DATA(3 downto 0);
		end if;		

		if (addr_decoded4(4)='1') then
			VERSION_LOC_NEXT <= WRITE_DATA(2 downto 0);
		end if;
		
		if (addr_decoded4(5)='1') then
			PSG_FREQ_NEXT <= WRITE_DATA(1 downto 0);
			PSG_STEREOMODE_NEXT <= WRITE_DATA(3 downto 2);
			PSG_ENVELOPE16_NEXT <= WRITE_DATA(4);
		end if;
		
		if (addr_decoded4(12)='1') then
			if (WRITE_DATA=x"3F") then
				CONFIG_ENABLE_NEXT <= '1';
			else
				CONFIG_ENABLE_NEXT <= '0';
			end if;
		end if;		

		if enable_flash=1 then 
			if (addr_decoded4(11)='1') then
				CPU_FLASH_ADDR_NEXT(17 downto 16) <= WRITE_DATA(4 downto 3);

				CPU_FLASH_CFG_NEXT <= WRITE_DATA(2);
				CPU_FLASH_REQUEST_NEXT <= WRITE_DATA(1);
				CPU_FLASH_WRITE_N_NEXT <= WRITE_DATA(0);
			end if;

			if (addr_decoded4(13)='1') then
				CPU_FLASH_ADDR_NEXT(7 downto 0) <= WRITE_DATA;
			end if;

			if (addr_decoded4(14)='1') then
				CPU_FLASH_ADDR_NEXT(15 downto 8) <= WRITE_DATA;
			end if;

			if (addr_decoded4(15)='1') then
				case CPU_FLASH_ADDR_REG(1 downto 0) is
				when "00" =>
					CPU_FLASH_DATA_NEXT(7 downto 0) <= WRITE_DATA;
				when "01" =>
					CPU_FLASH_DATA_NEXT(15 downto 8) <= WRITE_DATA;
				when "10" =>
					CPU_FLASH_DATA_NEXT(23 downto 16) <= WRITE_DATA;
				when others =>
					CPU_FLASH_DATA_NEXT(31 downto 24) <= WRITE_DATA;
				end case;
			end if;
		end if;
	end if;	
end process;

process(addr_decoded4,VERSION_LOC_REG,
SATURATE_REG,CHANNEL_MODE_REG,IRQ_EN_REG,DETECT_RIGHT_REG,
POST_DIVIDE_REG, GTIA_ENABLE_REG,
PSG_FREQ_REG, PSG_STEREOMODE_REG, PSG_ENVELOPE16_REG,
CPU_FLASH_CFG_REG,CPU_FLASH_ADDR_REG,CPU_FLASH_DATA_REG,
CPU_FLASH_REQUEST_REG, CPU_FLASH_WRITE_N_REG
)
begin
	CONFIG_DO <= (others=>'1');
	
	if (addr_decoded4(0)='1') then
			CONFIG_DO <= (others=>'0');
			CONFIG_DO(0) <= SATURATE_REG;
			CONFIG_DO(2) <= CHANNEL_MODE_REG;
			CONFIG_DO(3) <= IRQ_EN_REG;
			CONFIG_DO(4) <= DETECT_RIGHT_REG;
	end if;	
	
	if (addr_decoded4(1)='1') then
		CONFIG_DO <= (others=>'0');
		if (pokeys=1) then
			CONFIG_DO(1 downto 0) <= "00";
		elsif (pokeys=2) then
			CONFIG_DO(1 downto 0) <= "01";
		elsif (pokeys=4) then
			CONFIG_DO(1 downto 0) <= "10";
		end if;
		if (enable_sid=1) then
			CONFIG_DO(2) <= '1';
		else
			CONFIG_DO(2) <= '0';
		end if;
		if (enable_psg=1) then
			CONFIG_DO(3) <= '1';
		else
			CONFIG_DO(3) <= '0';
		end if;		
		if (enable_covox=1) then
			CONFIG_DO(4) <= '1';
		else
			CONFIG_DO(4) <= '0';
		end if;			
		if (enable_sample=1) then
			CONFIG_DO(5) <= '1';
		else
			CONFIG_DO(5) <= '0';
		end if;					
		if (enable_flash=1) then
			CONFIG_DO(6) <= '1';
		else
			CONFIG_DO(6) <= '0';
		end if;					
	end if;
	
	if (addr_decoded4(2)='1') then
		CONFIG_DO <= POST_DIVIDE_REG;
	end if;	
	
	if (addr_decoded4(3)='1') then
		CONFIG_DO <= (others=>'0');
		CONFIG_DO(3 downto 0) <= GTIA_ENABLE_REG;
		--CONFIG_DO(7 downto 4) <= SIO_ENABLE_REG; -- if we implement
	end if;
	
	if (addr_decoded4(4)='1') then
		-- version
		case VERSION_LOC_REG(2 downto 0) is			
			when "000" => 
				CONFIG_DO <= getByte(version,1);
			when "001" =>
				CONFIG_DO <= getByte(version,2);
			when "010" =>
				CONFIG_DO <= getByte(version,3);
			when "011" =>
				CONFIG_DO <= getByte(version,4);
			when "100" => 
				CONFIG_DO <= getByte(version,5);
			when "101" =>
				CONFIG_DO <= getByte(version,6);
			when "110" =>
				CONFIG_DO <= getByte(version,7);
			when "111" =>
				CONFIG_DO <= getByte(version,8);
			when others =>
		end case;		
	end if;

	if (addr_decoded4(5)='1') then
		CONFIG_DO(1 downto 0) <= PSG_FREQ_REG;
		CONFIG_DO(3 downto 2) <= PSG_STEREOMODE_REG;
		CONFIG_DO(4) <= PSG_ENVELOPE16_REG;
	end if;

	if (addr_decoded4(12)='1') then
		CONFIG_DO <= x"01";
	end if;		

	if enable_flash=1 then 
		if (addr_decoded4(11)='1') then
			CONFIG_DO(4 downto 3) <= CPU_FLASH_ADDR_REG(17 downto 16);
			CONFIG_DO(2) <= CPU_FLASH_CFG_REG;
			CONFIG_DO(1) <= CPU_FLASH_REQUEST_REG;
			CONFIG_DO(0) <= CPU_FLASH_WRITE_N_REG;
		end if;
	
		if (addr_decoded4(13)='1') then
			CONFIG_DO <= CPU_FLASH_ADDR_REG(7 downto 0);
		end if;
	
		if (addr_decoded4(14)='1') then
			CONFIG_DO <= CPU_FLASH_ADDR_REG(15 downto 8);
		end if;
	
		if (addr_decoded4(15)='1') then
			case CPU_FLASH_ADDR_REG(1 downto 0) is
			when "00" =>
				CONFIG_DO <= CPU_FLASH_DATA_REG(7 downto 0);
			when "01" =>
				CONFIG_DO <= CPU_FLASH_DATA_REG(15 downto 8);
			when "10" =>
				CONFIG_DO <= CPU_FLASH_DATA_REG(23 downto 16);
			when others =>
				CONFIG_DO <= CPU_FLASH_DATA_REG(31 downto 24);
			end case;
		end if;
	end if;
	
end process;

end generate;

-- DETECT IF RIGHT CHANNEL PLAYING
-- TODO: into another entity
process(clk,reset_n)
begin
	if (reset_n='0') then
		RIGHT_REG <= (others=>'0');
		RIGHT_PLAYING_COUNT_REG <= (others=>'0');
	elsif (clk'event and clk='1') then
		RIGHT_REG <= RIGHT_NEXT;
		RIGHT_PLAYING_COUNT_REG <= RIGHT_PLAYING_COUNT_NEXT;
	end if;
end process;

process(RIGHT_NEXT,RIGHT_REG,ENABLE_CYCLE,RIGHT_PLAYING_RECENTLY,RIGHT_PLAYING_COUNT_REG)
begin
	RIGHT_PLAYING_COUNT_NEXT <= RIGHT_PLAYING_COUNT_REG;

	if (ENABLE_CYCLE='1' and RIGHT_PLAYING_RECENTLY='1') then
		RIGHT_PLAYING_COUNT_NEXT <= RIGHT_PLAYING_COUNT_REG-1;
	end if;

	if (RIGHT_NEXT/=RIGHT_REG) then
		RIGHT_PLAYING_COUNT_NEXT <= (others=>'1');
	end if;
end process;
RIGHT_PLAYING_RECENTLY <= or_reduce(std_logic_vector(RIGHT_PLAYING_COUNT_REG));

-------------------------------------------------------
-- AUDIO mixing
process(POST_DIVIDE_REG,
	POKEY_AUDIO_0,POKEY_AUDIO_1,POKEY_AUDIO_2,POKEY_AUDIO_3, --signed
	SAMPLE_AUDIO,
	SID_AUDIO,
	PSG_AUDIO,
	GTIA_AUDIO,GTIA_ENABLE_REG,
	FANCY_ENABLE,
	RIGHT_PLAYING_RECENTLY,
	DETECT_RIGHT_REG
	)
	variable p0u : unsigned(19 downto 0);
	variable p1u : unsigned(19 downto 0);
	variable p2u : unsigned(19 downto 0);
	variable p3u : unsigned(19 downto 0);

	variable a0u : unsigned(19 downto 0);
	variable a1u : unsigned(19 downto 0);
	variable a2u: unsigned(19 downto 0);
	variable a3u: unsigned(19 downto 0);

	variable gtia0u : unsigned(19 downto 0);
	variable gtia1u : unsigned(19 downto 0);
	variable gtia2u: unsigned(19 downto 0);
	variable gtia3u: unsigned(19 downto 0);

	variable sidu: unsigned(19 downto 0);
	variable psgu1: unsigned(19 downto 0);
	variable psgu2: unsigned(19 downto 0);
	variable samu: unsigned(19 downto 0);
begin
-- 
--  0: pokey0,pokey2, pokeych1, sid0,ym0,covox0,sample0, gtia, sio in
--  1: pokey1,pokey3, pokeych2, sid1,ym1,covox1,sample1, gtia, sio in
--  2: pokey0,pokey2, pokeych3, sid0,ym0,covox0,sample0, gtia, sio in
--  3: pokey1,pokey3, pokeych4, sid1,ym1,covox1,sample1, gtia, sio in  
	gtia0u:= (others=>'0');
	gtia0u(15):= GTIA_AUDIO and GTIA_ENABLE_REG(0);
	gtia1u:= (others=>'0');
	gtia1u(15):= GTIA_AUDIO and GTIA_ENABLE_REG(1);
	gtia2u:= (others=>'0');
	gtia2u(15):= GTIA_AUDIO and GTIA_ENABLE_REG(2);
	gtia3u:= (others=>'0');
	gtia3u(15):= GTIA_AUDIO and GTIA_ENABLE_REG(3);

	p0u(19 downto 0) := (others=>'0');
	p1u(19 downto 0) := (others=>'0');
	p2u(19 downto 0) := (others=>'0');
	p3u(19 downto 0) := (others=>'0');
	p0u(14 downto 0) := unsigned(POKEY_AUDIO_0(14 downto 0));
	p1u(14 downto 0) := unsigned(POKEY_AUDIO_1(14 downto 0));
	p2u(14 downto 0) := unsigned(POKEY_AUDIO_2(14 downto 0));
	p3u(14 downto 0) := unsigned(POKEY_AUDIO_3(14 downto 0));
	p0u(15) := not(POKEY_AUDIO_0(15));
	p1u(15) := not(POKEY_AUDIO_1(15));
	p2u(15) := not(POKEY_AUDIO_2(15));	
	p3u(15) := not(POKEY_AUDIO_3(15));	

	sidu := resize(unsigned(sid_audio(0)),20);
	psgu1 := resize(unsigned(psg_audio(0)),20);
	psgu2 := resize(unsigned(psg_audio(2)),20);
	samu := resize(unsigned(sample_audio(0)),20);
	a0u := p0u + p2u + sidu + psgu1 + psgu2 + samu;

	sidu := resize(unsigned(sid_audio(1)),20);
	psgu1 := resize(unsigned(psg_audio(1)),20);
	psgu2 := resize(unsigned(psg_audio(3)),20);
	samu := resize(unsigned(sample_audio(1)),20);

	a1u := p1u + p3u + sidu + psgu1 + psgu2 + samu;
	RIGHT_NEXT <= a1u(5 downto 0);
	if (FANCY_ENABLE='0' or (RIGHT_PLAYING_RECENTLY='0' AND DETECT_RIGHT_REG='1')) then
		a1u := a0u;
	end if;
	a2u := a0u;
	a3u := a1u;

	a0u := a0u + gtia0u;
	a1u := a1u + gtia1u;
	a2u := a2u + gtia2u;
	a3u := a3u + gtia3u;

	case POST_DIVIDE_REG(1 downto 0) is
		when "01" =>
			a0u := '0'&a0u(19 downto 1);
		when "10" =>
			a0u := "00"&a0u(19 downto 2);
		when "11" =>
			a0u := "000"&a0u(19 downto 3);
		when others =>
	end case;
	
	case POST_DIVIDE_REG(3 downto 2) is
		when "01" =>
			a1u := '0'&a1u(19 downto 1);
		when "10" =>
			a1u := "00"&a1u(19 downto 2);
		when "11" =>
			a1u := "000"&a1u(19 downto 3);
		when others =>
	end case;

	case POST_DIVIDE_REG(5 downto 4) is
		when "01" =>
			a2u := '0'&a2u(19 downto 1);
		when "10" =>
			a2u := "00"&a2u(19 downto 2);
		when "11" =>
			a2u := "000"&a2u(19 downto 3);
		when others =>
	end case;
	
	case POST_DIVIDE_REG(7 downto 6) is
		when "01" =>
			a3u := '0'&a3u(19 downto 1);
		when "10" =>
			a3u := "00"&a3u(19 downto 2);
		when "11" =>
			a3u := "000"&a3u(19 downto 3);
		when others =>
	end case;	

	if or_reduce(std_logic_vector(a0u(19 downto 16)))='1' then
		AUDIO_0_UNSIGNED <= (others=>'1');
	else
		AUDIO_0_UNSIGNED <= a0u(15 downto 0);
	end if;
		
	if or_reduce(std_logic_vector(a1u(19 downto 16)))='1' then
		AUDIO_1_UNSIGNED <= (others=>'1');
	else
		AUDIO_1_UNSIGNED <= a1u(15 downto 0);
	end if;
	
	if or_reduce(std_logic_vector(a2u(19 downto 16)))='1' then
		AUDIO_2_UNSIGNED <= (others=>'1');
	else
		AUDIO_2_UNSIGNED <= a2u(15 downto 0);
	end if;
	
	if or_reduce(std_logic_vector(a3u(19 downto 16)))='1' then
		AUDIO_3_UNSIGNED <= (others=>'1');
	else
		AUDIO_3_UNSIGNED <= a3u(15 downto 0);
	end if;
end process;

--approx line level by using 5V/4 -> ok 1.25V, should be ok approx
dac_0 : entity work.filtered_sigmadelta  --pin37
GENERIC MAP
(
	IMPLEMENTATION => 2,
	LOWPASS => lowpass
)
port map
(
  reset_n => reset_n,
  clk => clk,
  clk2 => CLK116,
  ENABLE_179 => ENABLE_CYCLE,
  audin => AUDIO_0_UNSIGNED,
  AUDOUT => AUDIO_0_SIGMADELTA
);

dac_1 : entity work.filtered_sigmadelta
GENERIC MAP
(
	IMPLEMENTATION => 2,
	LOWPASS => lowpass
)
port map
(
  reset_n => reset_n,
  clk => clk,
  clk2 => CLK116,
  ENABLE_179 => ENABLE_CYCLE,
  audin => AUDIO_1_UNSIGNED,
  AUDOUT => AUDIO_1_SIGMADELTA
);

dac_2 : entity work.filtered_sigmadelta
GENERIC MAP
(
	IMPLEMENTATION => 2,
	LOWPASS => lowpass
)
port map
(
  reset_n => reset_n,
  clk => clk,
  clk2 => CLK116,
  ENABLE_179 => ENABLE_CYCLE,
  audin => AUDIO_2_UNSIGNED,
  AUDOUT => AUDIO_2_SIGMADELTA
);

dac_3 : entity work.filtered_sigmadelta
GENERIC MAP
(
	IMPLEMENTATION => 2,
	LOWPASS => lowpass
)
port map
(
  reset_n => reset_n,
  clk => clk,
  clk2 => CLK116,
  ENABLE_179 => ENABLE_CYCLE,
  audin => AUDIO_3_UNSIGNED,
  AUDOUT => AUDIO_3_SIGMADELTA
);


-- io extension
-- drive to 0 for pot reset (otherwise high imp)
-- drive keyboard lines
	i2c_master0 : entity work.i2c_master
 	generic map(input_clk=>58_000_000, bus_clk=>400_000)
	port map(
		clk=>clk,
		reset_n=>reset_n,

		ena=>i2c0_ena,
		addr=>i2c0_addr,
		rw=>i2c0_rw,
		data_wr=>i2c0_write_data,
		busy=>i2c0_busy,
		data_rd=>i2c0_read_data,
		ack_error=>i2c0_error,

		sda=>IOX_SDA,
		scl=>IOX_SCL
	);

	iox_glue : entity work.iox_glue
	port map(
		clk=>clk,
		reset_n=>reset_n,

		ena=>i2c0_ena,
		addr=>i2c0_addr,
		rw=>i2c0_rw,
		write_data=>i2c0_write_data,
		busy=>i2c0_busy,
		read_data=>i2c0_read_data,
		error=>i2c0_error,

		int=>iox_int,

		keyboard_scan=>keyboard_scan,
		keyboard_scan_enable=>keyboard_scan_enable,
		keyboard_response=>keyboard_response
	);

-- Wire up pins
ACLK <= SIO_CLOCKOUT;
BCLK <= '0' when (SIO_CLOCKIN_OE='1' and SIO_CLOCKIN_OUT='0') else 'Z';
SIO_CLOCKIN_IN <= BCLK;

SOD <= '0' when SIO_TXD='0' else 'Z';
SIO_RXD <= SID;


--1->pin37
AUD(1) <= AUDIO_0_SIGMADELTA;

-- ext AUD pins:
AUD(2) <= AUDIO_1_SIGMADELTA;
AUD(3) <= AUDIO_2_SIGMADELTA;
AUD(4) <= AUDIO_3_SIGMADELTA;

IRQ <= '0' when (IRQ_EN_REG='1' and (and_reduce(POKEY_IRQ)='0')) or (IRQ_EN_REG='0' and POKEY_IRQ(0)='0')  else 'Z';

D <= BUS_DATA when BUS_OE='1' else (others=>'Z');

POTRESET_N <= not(POTRESET);

END vhdl;
