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

--EXT1: A4
--EXT2: A5/stereo
--EXT3: A6/gtia
ENTITY pokeymax IS 
	GENERIC
	(
		pokeys : integer := 1; -- 1-4
		lowpass : integer := 1; -- 0=lowpass off, 1=lowpass on (leave on except if there is no space! Low impact...)
		enable_stereo_switch : integer := 0; -- 0=ext is low => mono
		enable_auto_stereo : integer := 0; -- 1=auto detect a4 => not toggling => mono
		enable_gtia_audio : integer := 1; -- 0=no gtia on l/r,1=gtia mixed on l/r
		address_bits : integer := 4; 
		enable_config : integer := 1;
		enable_sid : integer := 0;
		enable_ym : integer := 0;
		enable_covox : integer := 0;
		enable_sample : integer := 0;
		version : integer := 0
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

		EXT : INOUT STD_LOGIC_VECTOR(3 DOWNTO 1);

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
			locked   : out std_logic
		);
	end component;

	component sid8580 IS
	PORT
	(
	        RESET : IN STD_LOGIC;
	        CLK : IN STD_LOGIC;
	        CE_1M : IN STD_LOGIC;
	
	        WE : IN STD_LOGIC;
	        ADDR : IN STD_LOGIC_VECTOR(4 downto 0);
	        DATA_IN : IN STD_LOGIC_VECTOR(7 downto 0);
	        DATA_OUT : OUT STD_LOGIC_VECTOR(7 downto 0);
	
	        POT_X : IN STD_LOGIC_VECTOR(7 downto 0);
	        POT_Y : IN STD_LOGIC_VECTOR(7 downto 0);
	
	        EXTFILTER_EN : IN STD_LOGIC;
	        AUDIO_DATA : OUT STD_LOGIC_VECTOR(17 downto 0)
	);
	END component;
		

	signal OSC_CLK : std_logic;
	signal PHI2_6X : std_logic;

	signal CLK : std_logic;
	signal RESET_N : std_logic;

	signal ENABLE_CYCLE : std_logic;

	-- WRITE ENABLES
	SIGNAL POKEY_WRITE_ENABLE : STD_LOGIC_VECTOR(3 downto 0);		
	
	SIGNAL SID_WRITE_ENABLE : STD_LOGIC_VECTOR(1 downto 0);	

	SIGNAL YM2149_READ_ENABLE : STD_LOGIC_VECTOR(1 downto 0);	
	SIGNAL YM2149_WRITE_ENABLE : STD_LOGIC_VECTOR(1 downto 0);	

	SIGNAL SAMPLE_WRITE_ENABLE : STD_LOGIC;	
	SIGNAL CONFIG_WRITE_ENABLE : STD_LOGIC;	
	
	-- DATA OUTS
	type DO_TYPE is array (NATURAL range <>) of std_logic_vector(7 downto 0);
	
	SIGNAL POKEY_DO : DO_TYPE(3 downto 0);	
	
	SIGNAL SID_DO : DO_TYPE(1 downto 0);
	
	SIGNAL YM2149_DO : DO_TYPE(1 DOWNTO 0);	
	
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

	signal ADDR_IN : std_logic_vector(address_bits-1 downto 0);
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
	type SID_AUDIO_TYPE is array(NATURAL range<>) of std_logic_vector(7 downto 0);
	signal SID_AUDIO : SID_AUDIO_TYPE(1 downto 0);
	
	-- YM2149
	signal ENABLE_YM2149 : std_logic;
	type YM2149_AUDIO_TYPE is array(NATURAL range<>) of std_logic_vector(7 downto 0);
	signal YM2149_AUDIO : YM2149_AUDIO_TYPE(1 downto 0);	
	
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

	signal AEXT : std_logic_vector(address_bits-1 downto 4);

	signal CS_COMB : std_logic;

	signal AIN : std_logic_vector(address_bits-1 downto 0);

	signal POTRESET : std_logic;

	signal fancy_enable : std_logic;
	signal gtia_audio : std_logic;
	
	-- config
		--config regs
	signal CHANNEL_MODE_REG : std_logic;
	signal SATURATE_REG : std_logic;
	signal POST_DIVIDE_REG : std_logic_vector(7 downto 0);	
	signal GTIA_ENABLE_REG : std_logic_vector(3 downto 0);
	signal VERSION_LOC_REG : std_logic_vector(2 downto 0);
	
	signal CHANNEL_MODE_NEXT : std_logic;
	signal SATURATE_NEXT : std_logic;
	signal POST_DIVIDE_NEXT : std_logic_vector(7 downto 0);
	signal GTIA_ENABLE_NEXT : std_logic_vector(3 downto 0);
	signal VERSION_LOC_NEXT : std_logic_vector(2 downto 0);
	
		--config infra
	signal config_addr_decoded : std_logic_vector(15 downto 0);	
	signal CONFIG_ENABLE_REG : std_logic;
	signal CONFIG_ENABLE_NEXT: std_logic;
	
	-- SAMPLE/COVOX
	signal SAMPLE_R_REG : std_logic_vector(7 downto 0);
	signal SAMPLE_L_REG : std_logic_vector(7 downto 0);
	signal SAMPLE_R_NEXT : std_logic_vector(7 downto 0);
	signal SAMPLE_L_NEXT : std_logic_vector(7 downto 0);
	
BEGIN
	IOX_RST <= 'Z'; -- TODO weak pull up in pins (see TODO file)
	EXT <= (others=>'Z');

	CS_COMB <= CS1 and not(CS0_N);

	oscillator : int_osc
	port map 
	(
		clkout => OSC_CLK, 
		oscena => '1'
	);


	--phi_multiplier : entity work.phi_mult
	--port map 
	--(
	--	clkin => OSC_CLK,
	--	phi2 => PHI2,
	--	clkout => PHI2_6X -- 6x phi2, aligned!
	--);
	
	PHI2_6X <= OSC_CLK;

	pll_inst : pll
	PORT MAP(inclk0 => CLK_SLOW,
			 c0 => CLK, -- 27MHz 
			 locked => RESET_N);


	AIN(3 downto 0) <= A;

	ADDR_BITS_ON: 
	for I in address_bits downto 5 generate
	        AIN(I-1) <= EXT(I-4);
	end generate ADDR_BITS_ON;		

gen_gtia : if enable_gtia_audio=1 generate
	assert address_bits<7 report "EXT3 already used for A6";
       synchronizer_gtia_audio : entity work.synchronizer
                port map (clk=>clk, raw=>EXT(3), sync=>gtia_audio);
end generate;

gen_gtia_off : if enable_gtia_audio=0 generate
	gtia_audio <= '0';
end generate;

bus_adapt : entity work.slave_timing_6502
	GENERIC MAP
	(
		address_bits => address_bits
	)
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N,
		
		-- input from the cart port
		PHI2 => PHI2,
		bus_addr => AIN, --TODO, more pins...
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
	GENERIC MAP
	(
		address_bits => address_bits
	)
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,
	
		A => AIN(4), -- raw...
		ADDR_IN => ADDR_IN(address_bits-1 downto 4), -- on request
	
		ADDR_OUT => AEXT(address_bits-1 downto 4)
	);
end generate;

auto_stereo_off : if enable_auto_stereo=0 generate -- manual switch
	AEXT(address_bits-1 downto 4) <= ADDR_IN(address_bits-1 downto 4);
end generate;
	
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
	CHANNEL_MODE_REG, -- 0=pokeys have a channel each,1=ch 0 summed, ch 1 summed, ch 2 summed etc
	FANCY_ENABLE
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
	
	if (FANCY_ENABLE='0') then
		p1 := p0;
		p2 := p0;
		p3 := p0;
	end if;
	
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
GENERIC MAP
(
	LOWPASS => lowpass
)
PORT MAP(CLK => CLK,
		 ENABLE_179 => ENABLE_CYCLE,
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

sid_on : if enable_sid=1 generate 
SID_CLK_ENABLE <= '1'; -- TODO

sid1 : sid8580
PORT MAP(
	RESET => NOT(RESET_N),
	CLK => CLK,
	CE_1M => SID_CLK_ENABLE, --1MHz
	WE => SID_WRITE_ENABLE(0),
	ADDR => ADDR_IN(4 downto 0),
	DATA_IN => WRITE_DATA(7 downto 0),
	DATA_OUT => SID_DO(0),
	POT_X => (others=>'0'),
	POT_Y => (others=>'0'),
	EXTFILTER_EN => '0',
	AUDIO_DATA(17 downto 10) => SID_AUDIO(0), --TODO: review volume, can't really be 17 bits!!
	AUDIO_DATA(9 downto 0) => open
);

sid2 : sid8580
PORT MAP(
	RESET => NOT(RESET_N),
	CLK => CLK,
	CE_1M => SID_CLK_ENABLE, --1MHz
	WE => SID_WRITE_ENABLE(1),
	ADDR => ADDR_IN(4 downto 0),
	DATA_IN => WRITE_DATA(7 downto 0),
	DATA_OUT => SID_DO(1),
	POT_X => (others=>'0'),
	POT_Y => (others=>'0'),
	EXTFILTER_EN => '0',
	AUDIO_DATA(17 downto 10) => SID_AUDIO(1),
	AUDIO_DATA(9 downto 0) => open
);
end generate sid_on;		
--------------------------------------------------------
-- YM2149
--------------------------------------------------------
ym_on : if enable_ym=1 generate 
YM2149_1 : entity work.YM2149
  port map(
	clk=>clk,
	reset_n=>reset_n,
	enable=>'1', --TODO, frequency
	addr=>addr_in(3 downto 0),
	write_enable=>YM2149_WRITE_ENABLE(0),
	di=>write_data,
	do=>YM2149_DO(0),
	audio=>YM2149_AUDIO(0)
	);
	
YM2149_2 : entity work.YM2149
  port map(
	clk=>clk,
	reset_n=>reset_n,
	enable=>'1', --TODO, frequency
	addr=>addr_in(3 downto 0),
	write_enable=>YM2149_WRITE_ENABLE(1),
	di=>write_data,
	do=>YM2149_DO(1),
	audio=>YM2149_AUDIO(1)
	);
end generate ym_on;		
	
--------------------------------------------------------
-- COVOX
--------------------------------------------------------
covox_on : if enable_covox=1 generate 
process(ADDR_IN,SAMPLE_L_REG,SAMPLE_R_REG)
begin
	if (ADDR_IN(0)='1') then
		SAMPLE_DO <= SAMPLE_L_REG;
	else
		SAMPLE_DO <= SAMPLE_R_REG;
	end if;
end process;

process(ADDR_IN, SAMPLE_WRITE_ENABLE,
SAMPLE_L_REG,SAMPLE_R_REG,WRITE_DATA)
begin
	SAMPLE_L_NEXT <= SAMPLE_L_REG;
	SAMPLE_R_NEXT <= SAMPLE_R_REG;

	if (SAMPLE_WRITE_ENABLE='1') then
		if (ADDR_IN(0)='1') then
			SAMPLE_L_NEXT <= WRITE_DATA;
		else
			SAMPLE_R_NEXT <= WRITE_DATA;
		end if;
	end if;
end process;

process(clk,reset_n)
begin
	if (reset_n='0') then
		SAMPLE_L_REG <= (others=>'0');
		SAMPLE_R_REG <= (others=>'0');
	elsif (clk'event and clk='1') then
		SAMPLE_L_REG <= SAMPLE_L_NEXT;
		SAMPLE_R_REG <= SAMPLE_R_NEXT;
	end if;
end process;

end generate covox_on;
		
--------------------------------------------------------		
-- BASIC/FANCY SWITCH
--------------------------------------------------------			
switch_stereo : if enable_stereo_switch=1 generate 
  	assert address_bits<6 report "EXT2 already used for A5";
       synchronizer_fancy_enable : entity work.synchronizer
                port map (clk=>clk, raw=>EXT(2), sync=>fancy_enable);
end generate;

switch_stereo_off : if enable_stereo_switch=0 generate 
	fancy_enable <= '1';
end generate;
	
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

process(CONFIG_ENABLE_REG,AEXT,config_addr_decoded,fancy_enable)
	variable addr_bits : std_logic_vector(3 downto 0);
begin
	-- choose which bank
	addr_bits := (others=>'0');
	addr_bits(address_bits-5 downto 0) := AEXT;
	
	if (fancy_enable='0') then
		addr_bits := (others=>'0');
	end if;
		
	if ((config_enable_reg='1' and addr_bits="0001") or (addr_bits(3 downto 2) = "00" and config_addr_decoded(12)='1')) then
		addr_bits := x"f";
	end if;
	
	DEVICE_ADDR <= addr_bits;
end process;			

process(
	DEVICE_ADDR,
	POKEY_DO,
	SID_DO,
	YM2149_DO,
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
	YM2149_WRITE_ENABLE <= (others=>'0');
	YM2149_READ_ENABLE <= (others=>'0');
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
			DO_MUX <= YM2149_DO(0);
			YM2149_WRITE_ENABLE(0) <= writereq;
			YM2149_READ_ENABLE(0) <= readreq;
		when x"b" =>
			DO_MUX <= YM2149_DO(1);			
			YM2149_WRITE_ENABLE(1) <= writereq;
			YM2149_READ_ENABLE(1) <= readreq;
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
		CHANNEL_MODE_REG <= '0';
		SATURATE_REG <= '1';
		POST_DIVIDE_REG <= "10100000"; -- 1/2 5v, 3/4 1v
		GTIA_ENABLE_REG <= "1100"; -- external only
		CONFIG_ENABLE_REG <= '0';
		VERSION_LOC_REG <= (others=>'0');
	elsif (clk'event and clk='1') then
		CHANNEL_MODE_REG <= CHANNEL_MODE_NEXT;
		SATURATE_REG <= SATURATE_NEXT;
		POST_DIVIDE_REG <= POST_DIVIDE_NEXT;
		GTIA_ENABLE_REG <= GTIA_ENABLE_NEXT;
		CONFIG_ENABLE_REG <= CONFIG_ENABLE_NEXT;
		VERSION_LOC_REG <= VERSION_LOC_NEXT;
	end if;
end process;

-- default config

gen_config : if enable_config=1 generate

decode_addr1 : entity work.complete_address_decoder
	generic map(width=>4)
	port map (addr_in=>ADDR_IN(3 downto 0), addr_decoded=>config_addr_decoded);
	
process(CONFIG_WRITE_ENABLE, WRITE_DATA, config_addr_decoded,
	SATURATE_REG,CHANNEL_MODE_REG,
	CONFIG_ENABLE_REG,
	POST_DIVIDE_REG,
	GTIA_ENABLE_REG,
	VERSION_LOC_REG
)
begin
	SATURATE_NEXT <= SATURATE_REG;
	CHANNEL_MODE_NEXT <= CHANNEL_MODE_REG;

	POST_DIVIDE_NEXT <= POST_DIVIDE_REG;
	
	GTIA_ENABLE_NEXT <= GTIA_ENABLE_REG;
	
	CONFIG_ENABLE_NEXT <= CONFIG_ENABLE_REG;
	
	VERSION_LOC_NEXT <= VERSION_LOC_REG;
	
	if (CONFIG_WRITE_ENABLE='1') then
		if (config_addr_decoded(0)='1') then
			SATURATE_NEXT <= WRITE_DATA(0);
			CHANNEL_MODE_NEXT <= WRITE_DATA(2);
		end if;
		
		if (config_addr_decoded(2)='1') then
			POST_DIVIDE_NEXT <= WRITE_DATA;
		end if;
				
		if (config_addr_decoded(3)='1') then			
			GTIA_ENABLE_NEXT <= WRITE_DATA(3 downto 0);
		end if;		

		if (config_addr_decoded(4)='1') then
			VERSION_LOC_NEXT <= WRITE_DATA(2 downto 0);
		end if;
		
		if (config_addr_decoded(12)='1') then
			if (WRITE_DATA=x"3F") then
				CONFIG_ENABLE_NEXT <= '1';
			else
				CONFIG_ENABLE_NEXT <= '0';
			end if;
		end if;		
	end if;	
end process;

process(config_addr_decoded,VERSION_LOC_REG,
SATURATE_REG,CHANNEL_MODE_REG, 
POST_DIVIDE_REG, GTIA_ENABLE_REG)
begin
	CONFIG_DO <= (others=>'1');
	
	if (config_addr_decoded(0)='1') then
			CONFIG_DO <= (others=>'0');
			CONFIG_DO(0) <= SATURATE_REG;
			CONFIG_DO(2) <= CHANNEL_MODE_REG;
	end if;	
	
	if (config_addr_decoded(1)='1') then
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
		if (enable_ym=1) then
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
	end if;
	
	if (config_addr_decoded(2)='1') then
		CONFIG_DO <= POST_DIVIDE_REG;
	end if;	
	
	if (config_addr_decoded(3)='1') then
		CONFIG_DO <= (others=>'0');
		CONFIG_DO(3 downto 0) <= GTIA_ENABLE_REG;
		--CONFIG_DO(7 downto 4) <= SIO_ENABLE_REG; -- if we implement
	end if;
	
	if (config_addr_decoded(4)='1') then
		-- version
		CONFIG_DO(7 downto 4) <= x"4";				
		case VERSION_LOC_REG(2 downto 0) is			
			when "000" => 
				CONFIG_DO <= x"50"; --P
			when "001" =>
				CONFIG_DO <= x"4D"; --M
			when "010" =>
				CONFIG_DO(3 downto 0) <= std_logic_vector(to_unsigned((version/100000) mod 10,4));
			when "011" =>
				CONFIG_DO(3 downto 0) <= std_logic_vector(to_unsigned((version/10000) mod 10,4)); 
			when "100" => 
				CONFIG_DO(3 downto 0) <= std_logic_vector(to_unsigned((version/1000) mod 10,4));
			when "101" =>
				CONFIG_DO(3 downto 0) <= std_logic_vector(to_unsigned((version/100) mod 10,4));
			when "110" =>
				CONFIG_DO(3 downto 0) <= std_logic_vector(to_unsigned((version/10) mod 10,4));
			when "111" =>
				CONFIG_DO(3 downto 0) <= std_logic_vector(to_unsigned((version/1) mod 10,4));
			when others =>
		end case;		
	end if;
	
	if (config_addr_decoded(12)='1') then
		CONFIG_DO <= x"01";
	end if;		
	
end process;

end generate;


-- d20c 
-- r:1 -> pokeymax (confirm original...)
-- w:003f -> config mode?
---- + SIO fifo regs (compatible?) TODO
----0xxxxxxx - initialization (FIFO cache cleaning)
----10aaaaaa - set temporary border value (as AUDF3 content, $00...$3F)
----11aaaaaa - set default border value 

-- when in config mode pokey regs replaced with
-- d000: audio Mode W
--          10: pre_divide   (00=1,01=2,10=4)
--        32  : saturate     (00=off,01=pokey,10/11 reserved -> user configurable curve?)
--      54    : channel mode (00(mono)=TTTT, 01(stereo)=TTLR (Mix,Mix,L=0+2,R=1+3), 10(split)=0123 (0=sum(channel0),1=sum(channel1) etc), 11(stereoNoMix)=TTLR (L=0+2,R=1+3,L,R)
--    76      : gtia volume  (0=0,1=16,2=32,3=64 - volume)
-- d001: saturate curve data shift ref (future core)
-- d002: bank R/W
--          10: pokeys       (00=1 pokey,01=2 pokeys,11=4 pokeys)               ;   d000-d03f
--        32  : others       (00=off,01=dual sid,10=dual ym2149,11=covox/sample);   d040-d07f;
--      54    : others       (00=off,01=dual sid,10=dual ym2149,11=covox/sample);   d080-d0bf; (future hardware)
--    76      : others       (00=off,01=dual sid,10=dual ym2149,11=covox/sample);   d0c0-d0ff; (future hardware)
-- d003: capability R
--          10: pokeys       (00=1,01=2,10=4);
--         2  : sid          (0=0,1=dual sid);
--        3   : ym2149       (0=0,1=dual ym2149);
--       4    : covox        (0=0,1=covox);
--      5     : sample       (0=0,1=sample);
-- d004: post_divide W
--          10: 00=0,01=2,10=4 channel 0 (default 0 - 0-5v)
--        32  : 00=0,01=2,10=4 channel 1 (default 4 - 0-1.25v)
--      54    : 00=0,01=2,10=4 channel 2 (default 4 - 0-1.25v)
--    76      : 00=0,01=2,10=4 channel 3 (default 4 - 0-1.25v)
-- d005: post mix/gtia en W
--           0: 0=direct, 1=TTLR (after saturation/divide)
--    7654    : gtia on/off per channel: 7=channel3,6=channel2 etc
-- d006: chip id   (W(which bytes to read, i.e. 4-bit address, also used for copyright), R:read the max10 64-bit id) d000-d03f;
-- d007: copyright (R: read a short message, byte at a time!)

-------------------------------------------------------
-- AUDIO mixing
process(POST_DIVIDE_REG,
	POKEY_AUDIO_0,POKEY_AUDIO_1,POKEY_AUDIO_2,POKEY_AUDIO_3 --signed
	)
	variable a0u : unsigned(15 downto 0);
	variable a1u : unsigned(15 downto 0);
	variable a2u : unsigned(15 downto 0);
	variable a3u : unsigned(15 downto 0);
	variable l : unsigned(15 downto 0);
	variable r : unsigned(15 downto 0);
	variable total : unsigned(15 downto 0);
begin
-- 
--  0: pokey0,pokey2, pokeych1, sid0,ym0,covox0,sample0, gtia, sio in
--  1: pokey1,pokey3, pokeych2, sid1,ym1,covox1,sample1, gtia, sio in
--  2: pokey0,pokey2, pokeych3, sid0,ym0,covox0,sample0, gtia, sio in
--  3: pokey1,pokey3, pokeych4, sid1,ym1,covox1,sample1, gtia, sio in  
	a0u(14 downto 0) := unsigned(POKEY_AUDIO_0(14 downto 0));
	a1u(14 downto 0) := unsigned(POKEY_AUDIO_1(14 downto 0));
	a2u(14 downto 0) := unsigned(POKEY_AUDIO_2(14 downto 0));
	a3u(14 downto 0) := unsigned(POKEY_AUDIO_3(14 downto 0));
	a0u(15) := not(POKEY_AUDIO_0(15));
	a1u(15) := not(POKEY_AUDIO_1(15));
	a2u(15) := not(POKEY_AUDIO_2(15));	
	a3u(15) := not(POKEY_AUDIO_3(15));	
	
	case POST_DIVIDE_REG(1 downto 0) is
		when "01" =>
			a0u := '0'&a0u(15 downto 1);
		when "10" =>
			a0u := "00"&a0u(15 downto 2);
		when others =>
	end case;
	
	case POST_DIVIDE_REG(3 downto 2) is
		when "01" =>
			a1u := '0'&a1u(15 downto 1);
		when "10" =>
			a1u := "00"&a1u(15 downto 2);
		when others =>
	end case;

	case POST_DIVIDE_REG(5 downto 4) is
		when "01" =>
			a2u := '0'&a2u(15 downto 1);
		when "10" =>
			a2u := "00"&a2u(15 downto 2);
		when others =>
	end case;
	
	case POST_DIVIDE_REG(7 downto 6) is
		when "01" =>
			a3u := '0'&a3u(15 downto 1);
		when "10" =>
			a3u := "00"&a3u(15 downto 2);
		when others =>
	end case;	
		
	l := a0u+a2u;
	r := a1u+a3u;
	total:= l+r;
	
	-- TODO!
	AUDIO_0_UNSIGNED <= a0u;
	AUDIO_1_UNSIGNED <= a1u;
	AUDIO_2_UNSIGNED <= a2u;
	AUDIO_3_UNSIGNED <= a3u;			
end process;

--approx line level by using 5V/4 -> ok 1.25V, should be ok approx
dac_0 : entity work.sigmadelta  --pin37
port map
(
  reset_n => reset_n,
  clk => clk,
  audin => AUDIO_0_UNSIGNED,
  AUDOUT => AUDIO_0_SIGMADELTA
);

dac_1 : entity work.sigmadelta
port map
(
  reset_n => reset_n,
  clk => clk,
  audin => AUDIO_1_UNSIGNED,
  AUDOUT => AUDIO_1_SIGMADELTA
);

dac_2 : entity work.sigmadelta
port map
(
  reset_n => reset_n,
  clk => clk,
  audin => AUDIO_2_UNSIGNED,
  AUDOUT => AUDIO_2_SIGMADELTA
);

dac_3 : entity work.sigmadelta
port map
(
  reset_n => reset_n,
  clk => clk,
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
CLK_OUT <= PHI2_6X;

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

IRQ <= '0' when (and_reduce(POKEY_IRQ))='0' else 'Z';

D <= BUS_DATA when BUS_OE='1' else (others=>'Z');

POTRESET_N <= not(POTRESET);

END vhdl;
