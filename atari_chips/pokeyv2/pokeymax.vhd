---------------------------------------------------------------------------
-- (c) 2018 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

LIBRARY work;

ENTITY pokeymax IS 
	GENERIC
	(
		stereo : integer := 1; -- 0=MONO,1=STEREO,2=QUAD
		lowpass : integer := 1; -- 0=lowpass off, 1=lowpass on (leave on except if there is no space! Low impact...)
		enable_stereo_switch : integer := 0; -- 0=ext is low => mono
		enable_auto_stereo : integer := 0; -- 1=auto detect a4 => not toggling => mono
		enable_gtia_audio : integer := 1 -- 0=no gtia on l/r,1=gtia mixed on l/r
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
	
	component chipid is
			  port (
						 clkin      : in  std_logic                     := '0'; --  clkin.clk
						 reset      : in  std_logic                     := '0'; --  reset.reset
						 data_valid : out std_logic;                            -- output.valid
						 chip_id    : out std_logic_vector(63 downto 0)         --       .data
			  );
	end component;
		

	signal OSC_CLK : std_logic;
	signal PHI2_6X : std_logic;

	signal CLK : std_logic;
	signal RESET_N : std_logic;

	signal ENABLE_CYCLE : std_logic;

	-- POKEY
	SIGNAL	POKEY_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL	POKEY_WRITE_ENABLE :  STD_LOGIC;
	signal POKEY1_CHANNEL0 : std_logic_vector(3 downto 0);
	signal POKEY1_CHANNEL1 : std_logic_vector(3 downto 0);
	signal POKEY1_CHANNEL2 : std_logic_vector(3 downto 0);
	signal POKEY1_CHANNEL3 : std_logic_vector(3 downto 0);
	
	SIGNAL	POKEY2_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL	POKEY2_WRITE_ENABLE :  STD_LOGIC;
	signal POKEY2_CHANNEL0 : std_logic_vector(3 downto 0);
	signal POKEY2_CHANNEL1 : std_logic_vector(3 downto 0);
	signal POKEY2_CHANNEL2 : std_logic_vector(3 downto 0);
	signal POKEY2_CHANNEL3 : std_logic_vector(3 downto 0);

	SIGNAL	POKEY3_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL	POKEY3_WRITE_ENABLE :  STD_LOGIC;
	signal POKEY3_CHANNEL0 : std_logic_vector(3 downto 0);
	signal POKEY3_CHANNEL1 : std_logic_vector(3 downto 0);
	signal POKEY3_CHANNEL2 : std_logic_vector(3 downto 0);
	signal POKEY3_CHANNEL3 : std_logic_vector(3 downto 0);

	SIGNAL	POKEY4_DO :  STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL	POKEY4_WRITE_ENABLE :  STD_LOGIC;
	signal POKEY4_CHANNEL0 : std_logic_vector(3 downto 0);
	signal POKEY4_CHANNEL1 : std_logic_vector(3 downto 0);
	signal POKEY4_CHANNEL2 : std_logic_vector(3 downto 0);
	signal POKEY4_CHANNEL3 : std_logic_vector(3 downto 0);

	signal CHANNEL0SUM_NEXT : unsigned(11 downto 0);	
	signal CHANNEL1SUM_NEXT : unsigned(11 downto 0);
	signal CHANNEL2SUM_NEXT : unsigned(11 downto 0);
	signal CHANNEL3SUM_NEXT : unsigned(11 downto 0);
	signal CHANNEL0SUM_REG : unsigned(11 downto 0);	
	signal CHANNEL1SUM_REG : unsigned(11 downto 0);
	signal CHANNEL2SUM_REG : unsigned(11 downto 0);
	signal CHANNEL3SUM_REG : unsigned(11 downto 0);	
	
	signal SIO_CLOCKIN_IN : std_logic;
	signal SIO_CLOCKIN_OUT : std_logic;
	signal SIO_CLOCKIN_OE : std_logic;
	signal SIO_CLOCKOUT : std_logic;

	signal SIO_TXD : std_logic;
	signal SIO_RXD : std_logic;

	signal POKEY_IRQ : std_logic;
	signal POKEY2_IRQ : std_logic;
	signal POKEY3_IRQ : std_logic;
	signal POKEY4_IRQ : std_logic;

	signal ADDR_IN : std_logic_vector(5 downto 0);
	signal WRITE_DATA : std_logic_vector(7 downto 0);

	signal AUDIO_0_SIGNED : signed(15 downto 0);
	signal AUDIO_1_SIGNED : signed(15 downto 0);
	signal AUDIO_2_SIGNED : signed(15 downto 0);
	signal AUDIO_3_SIGNED : signed(15 downto 0);
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

	signal SEL_POKEY : std_logic_vector(1 downto 0);
	signal SEL_POKEY_ADJ : std_logic_vector(2 downto 0);
	signal A4_DETECT_FILTERED : std_logic;
	signal A5_DETECT_FILTERED : std_logic;

	signal CS_COMB : std_logic;

	signal AIN : std_logic_vector(5 downto 0);

	signal POTRESET : std_logic;

	signal stereo_enable : std_logic;
	signal gtia_audio : std_logic;
	
	-- config
		--config regs
	signal CHANNEL_MODE_REG : std_logic_vector(1 downto 0);
	signal GTIA_VOLUME_REG : std_logic_vector(1 downto 0);
	signal SATURATE_REG : std_logic;
	signal PRE_DIVIDE_REG : std_logic_vector(1 downto 0);
	signal POST_DIVIDE_REG : std_logic_vector(7 downto 0);	
	signal POST_MIX_REG : std_logic_vector(0 downto 0);	
	signal CHIP_ID_LOC_REG : std_logic_vector(2 downto 0);
	signal ENABLE_REG : std_logic_vector(1 downto 0);
	
	signal CHANNEL_MODE_NEXT : std_logic_vector(1 downto 0);
	signal GTIA_VOLUME_NEXT : std_logic_vector(1 downto 0);
	signal SATURATE_NEXT : std_logic;
	signal PRE_DIVIDE_NEXT : std_logic_vector(1 downto 0);
	signal POST_DIVIDE_NEXT : std_logic_vector(7 downto 0);
	signal POST_MIX_NEXT : std_logic_vector(0 downto 0);	
	signal CHIP_ID_LOC_NEXT : std_logic_vector(2 downto 0);
	signal ENABLE_NEXT : std_logic_vector(1 downto 0);
	
		--config infra
	signal config_addr_decoded : std_logic_vector(15 downto 0);	
	signal CONFIG_ENABLE_REG : std_logic;
	signal CONFIG_ENABLE_NEXT: std_logic;
	signal CONFIG_DO : std_logic_vector(7 downto 0);
	signal CONFIG_WRITE_ENABLE : std_logic;
	
		-- chip id (unique per max10 physical device)
	signal chip_id : std_logic_vector(63 downto 0);
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

	AIN <= EXT(2)&EXT(1)&A;
	
gen_gtia : if enable_gtia_audio=1 generate
       synchronizer_gtia_audio : entity work.synchronizer
                port map (clk=>clk, raw=>ext(3), sync=>gtia_audio);
end generate;

gen_gtia_off : if enable_gtia_audio=0 generate
	gtia_audio <= '0';
end generate;

bus_adapt : entity work.slave_timing_6502
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
	POKEY1_CHANNEL0,POKEY1_CHANNEL1,POKEY1_CHANNEL2,POKEY1_CHANNEL3,
	POKEY2_CHANNEL0,POKEY2_CHANNEL1,POKEY2_CHANNEL2,POKEY2_CHANNEL3,
	POKEY3_CHANNEL0,POKEY3_CHANNEL1,POKEY3_CHANNEL2,POKEY3_CHANNEL3,
	POKEY4_CHANNEL0,POKEY4_CHANNEL1,POKEY4_CHANNEL2,POKEY4_CHANNEL3,
	GTIA_AUDIO,
	GTIA_VOLUME_REG,
	CHANNEL_MODE_REG -- 0=mono, 1=stereo(L:1/3,R2/4), 2=quad(0=sum(chan0),1=sum(chan1) etc)
	)
variable p0 : unsigned(11 downto 0);	
variable p1 : unsigned(11 downto 0);
variable p2 : unsigned(11 downto 0);
variable p3 : unsigned(11 downto 0);

variable l : unsigned(11 downto 0);	
variable r : unsigned(11 downto 0);	
variable total : unsigned(11 downto 0);	

variable c0 : unsigned(11 downto 0);	
variable c1 : unsigned(11 downto 0);
variable c2 : unsigned(11 downto 0);
variable c3 : unsigned(11 downto 0);	
	
variable sum0 : unsigned(11 downto 0);	
variable sum1 : unsigned(11 downto 0);
variable sum2 : unsigned(11 downto 0);
variable sum3 : unsigned(11 downto 0);

variable GTIA_VOLUME_SUM : unsigned(9 downto 0);
begin
	p0 := resize(unsigned(POKEY1_CHANNEL0&"0000"),12) + resize(unsigned(POKEY1_CHANNEL1&"0000"),12) + resize(unsigned(POKEY1_CHANNEL2&"0000"),12) + resize(unsigned(POKEY1_CHANNEL3&"0000"),12);
	p1 := resize(unsigned(POKEY2_CHANNEL0&"0000"),12) + resize(unsigned(POKEY2_CHANNEL1&"0000"),12) + resize(unsigned(POKEY2_CHANNEL2&"0000"),12) + resize(unsigned(POKEY2_CHANNEL3&"0000"),12);
	p2 := resize(unsigned(POKEY3_CHANNEL0&"0000"),12) + resize(unsigned(POKEY3_CHANNEL1&"0000"),12) + resize(unsigned(POKEY3_CHANNEL2&"0000"),12) + resize(unsigned(POKEY3_CHANNEL3&"0000"),12);
	p3 := resize(unsigned(POKEY4_CHANNEL0&"0000"),12) + resize(unsigned(POKEY4_CHANNEL1&"0000"),12) + resize(unsigned(POKEY4_CHANNEL2&"0000"),12) + resize(unsigned(POKEY4_CHANNEL3&"0000"),12);
	
	c0 := resize(unsigned(POKEY1_CHANNEL0&"0000"),12) + resize(unsigned(POKEY2_CHANNEL0&"0000"),12) + resize(unsigned(POKEY3_CHANNEL0&"0000"),12) + resize(unsigned(POKEY4_CHANNEL0&"0000"),12);
	c1 := resize(unsigned(POKEY1_CHANNEL1&"0000"),12) + resize(unsigned(POKEY2_CHANNEL1&"0000"),12) + resize(unsigned(POKEY3_CHANNEL1&"0000"),12) + resize(unsigned(POKEY4_CHANNEL1&"0000"),12);
	c2 := resize(unsigned(POKEY1_CHANNEL2&"0000"),12) + resize(unsigned(POKEY2_CHANNEL2&"0000"),12) + resize(unsigned(POKEY3_CHANNEL2&"0000"),12) + resize(unsigned(POKEY4_CHANNEL2&"0000"),12);
	c3 := resize(unsigned(POKEY1_CHANNEL3&"0000"),12) + resize(unsigned(POKEY2_CHANNEL3&"0000"),12) + resize(unsigned(POKEY3_CHANNEL3&"0000"),12) + resize(unsigned(POKEY4_CHANNEL3&"0000"),12);	

	case CHANNEL_MODE_REG is
		when "00" =>
			sum0 := p0;
			sum1 := p0;
			sum2 := p0;
			sum3 := p0;
		when "01" =>
			l := p0+p2;
			r := p1+p3;
			total := l+r;
			sum0 := total;
			sum1 := total;
			sum2 := l;
			sum3 := r;	
		when others =>
			sum0 := c0;
			sum1 := c1;
			sum2 := c2;
			sum3 := c3;			
	end case;
	
	if (GTIA_AUDIO='1') then		
		case GTIA_VOLUME_REG is		
		when "01" =>
			GTIA_VOLUME_SUM := to_unsigned(64,10);
		when "10" =>
			GTIA_VOLUME_SUM := to_unsigned(128,10);
		when "11" =>
			GTIA_VOLUME_SUM := to_unsigned(256,10);			
		when others =>			
			GTIA_VOLUME_SUM := to_unsigned(0,10);	
		end case;
		
		sum0 := sum0 + GTIA_VOLUME_SUM;
		sum1 := sum1 + GTIA_VOLUME_SUM;
		sum2 := sum2 + GTIA_VOLUME_SUM;
		sum3 := sum3 + GTIA_VOLUME_SUM;
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
		 VOLUME_OUT_0 => AUDIO_0_SIGNED,
		 VOLUME_OUT_1 => AUDIO_1_SIGNED,
		 VOLUME_OUT_2 => AUDIO_2_SIGNED,
		 VOLUME_OUT_3 => AUDIO_3_SIGNED,
		 SATURATE => SATURATE_REG,
		 DIVIDE => PRE_DIVIDE_REG
		 );

--------------------------------------------------------
-- PRIMARY POKEY		 
--------------------------------------------------------
pokey1 : entity work.pokey
GENERIC MAP
(
	custom_keyboard_scan => 1
)
PORT MAP(CLK => CLK,
		 ENABLE_179 => ENABLE_CYCLE,
		 WR_EN => POKEY_WRITE_ENABLE,
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
		 IRQ_N_OUT => POKEY_IRQ,
		 SIO_OUT1 => SIO_TXD,
		 SIO_OUT2 => open,
		 SIO_OUT3 => open,
		 SIO_CLOCKOUT => SIO_CLOCKOUT,
		 POT_RESET => POTRESET,
		 CHANNEL_0_OUT => POKEY1_CHANNEL0,
		 CHANNEL_1_OUT => POKEY1_CHANNEL1,
		 CHANNEL_2_OUT => POKEY1_CHANNEL2,
		 CHANNEL_3_OUT => POKEY1_CHANNEL3,
		 DATA_OUT => POKEY_DO,
		 keyboard_scan => KEYBOARD_SCAN,
		 keyboard_scan_enable => KEYBOARD_SCAN_ENABLE
		);

gen_mono : if stereo=0 generate
	POKEY2_CHANNEL0 <= "0000";
	POKEY2_CHANNEL1 <= "0000";
	POKEY2_CHANNEL2 <= "0000";
	POKEY2_CHANNEL3 <= "0000";

	POKEY3_CHANNEL0 <= "0000";
	POKEY3_CHANNEL1 <= "0000";
	POKEY3_CHANNEL2 <= "0000";
	POKEY3_CHANNEL3 <= "0000";

	POKEY4_CHANNEL0 <= "0000";
	POKEY4_CHANNEL1 <= "0000";
	POKEY4_CHANNEL2 <= "0000";
	POKEY4_CHANNEL3 <= "0000";

	SEL_POKEY <= "00";
	
	POKEY2_IRQ	 <= '1';
	POKEY3_IRQ	 <= '1';
	POKEY4_IRQ	 <= '1';	
	
end generate;		
		
--------------------------------------------------------		
-- SECONDARY POKEY		 
--------------------------------------------------------
gen_stereo : if stereo=1 generate

switch_stereo : if enable_stereo_switch=1 generate 
       synchronizer_stereo_enable : entity work.synchronizer
                port map (clk=>clk, raw=>ext(2), sync=>stereo_enable);
end generate;

switch_stereo_off : if enable_stereo_switch=0 generate 
	stereo_enable <= '1';
end generate;


auto_stereo : if enable_auto_stereo=1 generate -- auto detect
	isstereo : ENTITY work.stereo_detect
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,
	
		A => AIN(4), -- raw...
		ADDR_IN => ADDR_IN(4), -- on request
	
		SEL_POKEY2 => A4_DETECT_FILTERED
	);
end generate;

auto_stereo_off : if enable_auto_stereo=0 generate -- manual switch
	A4_DETECT_FILTERED <= ADDR_IN(4);
end generate;

	SEL_POKEY(0) <= A4_DETECT_FILTERED and stereo_enable;
	SEL_POKEY(1) <= '0';
	
pokey2 : entity work.pokey
PORT MAP(CLK => CLK,
		 ENABLE_179 => ENABLE_CYCLE,
		 WR_EN => POKEY2_WRITE_ENABLE,
		 RESET_N => RESET_N,
		 ADDR => ADDR_IN(3 DOWNTO 0),
		 DATA_IN => WRITE_DATA(7 DOWNTO 0),
		 CHANNEL_0_OUT => POKEY2_CHANNEL0,
		 CHANNEL_1_OUT => POKEY2_CHANNEL1,
		 CHANNEL_2_OUT => POKEY2_CHANNEL2,
		 CHANNEL_3_OUT => POKEY2_CHANNEL3,
		 DATA_OUT => POKEY2_DO,
		 SIO_IN1 => '1',
		 SIO_IN2 => '1',
		 SIO_IN3 => '1',
		 IRQ_N_OUT => POKEY2_IRQ,
		 keyboard_response => "00",
		 pot_in=>"00000000");

	POKEY3_CHANNEL0 <= "0000";
	POKEY3_CHANNEL1 <= "0000";
	POKEY3_CHANNEL2 <= "0000";
	POKEY3_CHANNEL3 <= "0000";

	POKEY4_CHANNEL0 <= "0000";
	POKEY4_CHANNEL1 <= "0000";
	POKEY4_CHANNEL2 <= "0000";
	POKEY4_CHANNEL3 <= "0000";	
	
	POKEY3_DO <= (others=>'0');
	POKEY4_DO <= (others=>'0');
	
	POKEY3_IRQ	 <= '1';
	POKEY4_IRQ	 <= '1';
end generate;

--------------------------------------------------------		
-- QUAD POKEY
--------------------------------------------------------
gen_quad : if stereo=2 generate --quad!
auto_stereo : if enable_auto_stereo=1 generate -- auto detect
	isstereo : ENTITY work.stereo_detect
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,
	
		A => AIN(4), -- raw...
		ADDR_IN => ADDR_IN(4), -- on request
	
		SEL_POKEY2 => A4_DETECT_FILTERED
	);
	isquad : ENTITY work.stereo_detect
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,
	
		A => AIN(5), -- raw...
		ADDR_IN => ADDR_IN(5), -- on request
	
		SEL_POKEY2 => A5_DETECT_FILTERED
	);
end generate;

auto_stereo_off : if enable_auto_stereo=0 generate -- manual switch
	A4_DETECT_FILTERED <= ADDR_IN(4);
	A5_DETECT_FILTERED <= ADDR_IN(5);
end generate;

	SEL_POKEY(0) <= A4_DETECT_FILTERED;
	SEL_POKEY(1) <= A5_DETECT_FILTERED;

pokey2 : entity work.pokey
GENERIC MAP
(
	custom_keyboard_scan => 1
)
PORT MAP(CLK => CLK,
		 ENABLE_179 => ENABLE_CYCLE,
		 WR_EN => POKEY2_WRITE_ENABLE,
		 RESET_N => RESET_N,
		 ADDR => ADDR_IN(3 DOWNTO 0),
		 DATA_IN => WRITE_DATA(7 DOWNTO 0),
		 CHANNEL_0_OUT => POKEY2_CHANNEL0,
		 CHANNEL_1_OUT => POKEY2_CHANNEL1,
		 CHANNEL_2_OUT => POKEY2_CHANNEL2,
		 CHANNEL_3_OUT => POKEY2_CHANNEL3,
		 DATA_OUT => POKEY2_DO,
		 SIO_IN1 => '1',
		 SIO_IN2 => '1',
		 SIO_IN3 => '1',
		 IRQ_N_OUT => POKEY2_IRQ,
		 keyboard_response => "00",
		 pot_in=>"00000000");

pokey3 : entity work.pokey
GENERIC MAP
(
	custom_keyboard_scan => 2
)
PORT MAP(CLK => CLK,
		 ENABLE_179 => ENABLE_CYCLE,
		 WR_EN => POKEY3_WRITE_ENABLE,
		 RESET_N => RESET_N,
		 ADDR => ADDR_IN(3 DOWNTO 0),
		 DATA_IN => WRITE_DATA(7 DOWNTO 0),
		 CHANNEL_0_OUT => POKEY3_CHANNEL0,
		 CHANNEL_1_OUT => POKEY3_CHANNEL1,
		 CHANNEL_2_OUT => POKEY3_CHANNEL2,
		 CHANNEL_3_OUT => POKEY3_CHANNEL3,
		 DATA_OUT => POKEY3_DO,
		 SIO_IN1 => '1',
		 SIO_IN2 => '1',
		 SIO_IN3 => '1',
		 IRQ_N_OUT => POKEY3_IRQ,
		 keyboard_response => "00",
		 pot_in=>"00000000");

pokey4 : entity work.pokey
GENERIC MAP
(
	custom_keyboard_scan => 2
)
PORT MAP(CLK => CLK,
		 ENABLE_179 => ENABLE_CYCLE,
		 WR_EN => POKEY4_WRITE_ENABLE,
		 RESET_N => RESET_N,
		 ADDR => ADDR_IN(3 DOWNTO 0),
		 DATA_IN => WRITE_DATA(7 DOWNTO 0),
		 CHANNEL_0_OUT => POKEY4_CHANNEL0,
		 CHANNEL_1_OUT => POKEY4_CHANNEL1,
		 CHANNEL_2_OUT => POKEY4_CHANNEL2,
		 CHANNEL_3_OUT => POKEY4_CHANNEL3,
		 DATA_OUT => POKEY4_DO,
		 SIO_IN1 => '1',
		 SIO_IN2 => '1',
		 SIO_IN3 => '1',
		 IRQ_N_OUT => POKEY4_IRQ,
		 keyboard_response => "00",
		 pot_in=>"00000000");
end generate;

-------------------------------------------------------
-- COMMON, data bus

SEL_POKEY_ADJ <= (CONFIG_ENABLE_REG and SEL_POKEY(0) and not(SEL_POKEY(1)))&(SEL_POKEY and ENABLE_REG);

process(SEL_POKEY_ADJ,POKEY_DO,POKEY2_DO,POKEY3_DO,POKEY4_DO,CONFIG_DO,config_addr_decoded)
begin
	DO_MUX <= (others =>'0');
	case SEL_POKEY_ADJ is
		when "000"|"100" =>
			if (config_addr_decoded(12)='1') then
				DO_MUX <= CONFIG_DO;
			else
				DO_MUX <= POKEY_DO;
			end if;
		when "001" =>
			DO_MUX <= POKEY2_DO;
		when "010" =>
			DO_MUX <= POKEY3_DO;
		when "011" =>
			DO_MUX <= POKEY4_DO;
		when "101" =>
			DO_MUX <= CONFIG_DO;
		when others =>
	end case;
end process;

process(write_n,request,sel_pokey_adj,config_addr_decoded)
begin
	POKEY_WRITE_ENABLE <= '0';
	POKEY2_WRITE_ENABLE <= '0';
	POKEY3_WRITE_ENABLE <= '0';
	POKEY4_WRITE_ENABLE <= '0';
	CONFIG_WRITE_ENABLE <= '0';

	if (write_n='0' and request='1') then
		case sel_pokey_adj is
			when "000" =>
				POKEY_WRITE_ENABLE <= '1';
			when "001" =>
				if (config_addr_decoded(12)='1') then
					CONFIG_WRITE_ENABLE <= '1';
				else
					POKEY2_WRITE_ENABLE <= '1';
				end if;
			when "010" =>
				POKEY3_WRITE_ENABLE <= '1';
			when "011" =>
				POKEY4_WRITE_ENABLE <= '1';
			when "101" =>				
				CONFIG_WRITE_ENABLE <= '1';				
			when others =>
		end case;
	end if;
end process;

-------------------------------------------------------
-- Configuration

process(clk,reset_n)
begin
	if (reset_n='0') then
		CHANNEL_MODE_REG <= "01";
		GTIA_VOLUME_REG <= "01";
		SATURATE_REG <= '1';
		PRE_DIVIDE_REG <= "00";
		ENABLE_REG <= "11";
		POST_DIVIDE_REG <= "10101000"; -- all /4 except internal by default	
		POST_MIX_REG <= "0"; -- direct
		CONFIG_ENABLE_REG <= '0';
		CHIP_ID_LOC_REG <= (others=>'0');
	elsif (clk'event and clk='1') then
		CHANNEL_MODE_REG <= CHANNEL_MODE_NEXT;
		GTIA_VOLUME_REG <= GTIA_VOLUME_NEXT;
		SATURATE_REG <= SATURATE_NEXT;
		PRE_DIVIDE_REG <= PRE_DIVIDE_NEXT;
		ENABLE_REG <= ENABLE_NEXT;
		POST_DIVIDE_REG <= POST_DIVIDE_NEXT;
		POST_MIX_REG <= POST_MIX_NEXT;
		CONFIG_ENABLE_REG <= CONFIG_ENABLE_NEXT;
		CHIP_ID_LOC_REG <= CHIP_ID_LOC_NEXT;
	end if;
end process;

-- default config


decode_addr1 : entity work.complete_address_decoder
	generic map(width=>4)
	port map (addr_in=>ADDR_IN(3 downto 0), addr_decoded=>config_addr_decoded);
	
process(CONFIG_WRITE_ENABLE, WRITE_DATA, config_addr_decoded,
	PRE_DIVIDE_REG,SATURATE_REG,CHANNEL_MODE_REG,GTIA_VOLUME_REG,
	CONFIG_ENABLE_REG,
	ENABLE_REG,
	POST_DIVIDE_REG,
	POST_MIX_REG,
	CHIP_ID_LOC_REG
)
begin
	PRE_DIVIDE_NEXT <= PRE_DIVIDE_REG;
	SATURATE_NEXT <= SATURATE_REG;
	CHANNEL_MODE_NEXT <= CHANNEL_MODE_REG;
	GTIA_VOLUME_NEXT <= GTIA_VOLUME_REG;
	
	ENABLE_NEXT <= ENABLE_REG;

	POST_DIVIDE_NEXT <= POST_DIVIDE_REG;
	
	POST_MIX_NEXT <= POST_MIX_REG;
	
	CONFIG_ENABLE_NEXT <= CONFIG_ENABLE_REG;
	
	CHIP_ID_LOC_NEXT <= CHIP_ID_LOC_REG;
	
	if (CONFIG_WRITE_ENABLE='1') then
		if (config_addr_decoded(0)='1') then
			PRE_DIVIDE_NEXT <= WRITE_DATA(1 downto 0);
			SATURATE_NEXT <= WRITE_DATA(2);
			CHANNEL_MODE_NEXT <= WRITE_DATA(5 downto 4);
			GTIA_VOLUME_NEXT <= WRITE_DATA(7 downto 6);
		end if;
	
		if (config_addr_decoded(2)='1') then
			ENABLE_NEXT <= WRITE_DATA(1 downto 0);
		end if;
		
		if (config_addr_decoded(4)='1') then
			POST_DIVIDE_NEXT <= WRITE_DATA;
		end if;
				
		if (config_addr_decoded(5)='1') then
			POST_MIX_NEXT <= WRITE_DATA(0 downto 0);
		end if;		

		if (config_addr_decoded(6)='1') then
			CHIP_ID_LOC_NEXT <= WRITE_DATA(2 downto 0);
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

chipid1 : chipid
port map
(
	clkin=>clk,
	reset=>not(reset_n),
	data_valid=>open,
	chip_id=>chip_id
);

process(config_addr_decoded,ENABLE_REG,CHIP_ID_LOC_REG,CHIP_ID,
PRE_DIVIDE_REG,SATURATE_REG,CHANNEL_MODE_REG,GTIA_VOLUME_REG, 
POST_DIVIDE_REG,POST_MIX_REG)
begin
	CONFIG_DO <= (others=>'1');
	
	if (config_addr_decoded(0)='1') then
			CONFIG_DO <= (others=>'0');
			CONFIG_DO(1 downto 0) <= PRE_DIVIDE_REG;
			CONFIG_DO(2) <= SATURATE_REG;
			CONFIG_DO(5 downto 4) <= CHANNEL_MODE_REG;
			CONFIG_DO(7 downto 6) <= GTIA_VOLUME_REG;
	end if;	
	
	if (config_addr_decoded(2)='1') then
		CONFIG_DO(7 downto 2) <= (others=>'0');
		CONFIG_DO(1 downto 0) <= ENABLE_REG;
	end if;
	
	if (config_addr_decoded(3)='1') then
		CONFIG_DO <= (others=>'0');
		if (stereo=0) then
			CONFIG_DO(1 downto 0) <= "00";
		elsif (stereo=1) then
			CONFIG_DO(1 downto 0) <= "01";
		elsif (stereo=2) then
			CONFIG_DO(1 downto 0) <= "10";
		end if;
	end if;
	
	if (config_addr_decoded(4)='1') then
		CONFIG_DO <= POST_DIVIDE_REG;
	end if;	
	
	if (config_addr_decoded(5)='1') then
		CONFIG_DO(7 downto 1) <= (others=>'0');
		CONFIG_DO(0 downto 0) <= POST_MIX_REG;
	end if;
	
	if (config_addr_decoded(6)='1') then
		case CHIP_ID_LOC_REG is
			when "000" => 
				CONFIG_DO <= CHIP_ID(7 downto 0);
			when "001" =>
				CONFIG_DO <= CHIP_ID(15 downto 8);
			when "010" =>
				CONFIG_DO <= CHIP_ID(23 downto 16);
			when "011" =>
				CONFIG_DO <= CHIP_ID(31 downto 24);
			when "100" => 
				CONFIG_DO <= CHIP_ID(39 downto 32);
			when "101" =>
				CONFIG_DO <= CHIP_ID(47 downto 40);
			when "110" =>
				CONFIG_DO <= CHIP_ID(55 downto 48);
			when "111" =>
				CONFIG_DO <= CHIP_ID(63 downto 56);				
			when others =>
		end case;
	end if;

	if (config_addr_decoded(7)='1') then
		-- copyright
		case CHIP_ID_LOC_REG is
			when "000" => 
				CONFIG_DO <= x"52"; --R
			when "001" =>
				CONFIG_DO <= x"45"; --E
			when "010" =>
				CONFIG_DO <= x"54"; --T
			when "011" =>
				CONFIG_DO <= x"52"; --R
			when "100" => 
				CONFIG_DO <= x"4F"; --O
			when "101" =>
				CONFIG_DO <= x"4E"; --N
			when "110" =>
				CONFIG_DO <= x"49"; --I
			when "111" =>
				CONFIG_DO <= x"43"; --C
			when others =>
		end case;		
	end if;
	
	if (config_addr_decoded(12)='1') then
		CONFIG_DO <= x"01";
	end if;		
	
end process;


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
--      54    : channel mode (00(mono)=TTTT, 01(stereo)=TTLR (L=0+2,R=1+3), 10(split)=0123 (0=sum(channel0),1=sum(channel1) etc)
--    76      : gtia volume  (0=0,1=16,2=32,3=64 - volume)
-- d001: saturate curve data shift ref (future core)
-- d002: enable R/W
--          10: pokeys       (00=1,01=2,11=4);   d000-d03f;
--        32  : others       (00=off,01=dual sid,10=dual ym2149,11=covox/sample);   d040-d07f;
--      54    : others       (00=off,01=dual sid,10=dual ym2149,11=covox/sample);   d080-d0bf; (future hardware)
--    76      : others       (00=off,01=dual sid,10=dual ym2149,11=covox/sample);   d0c0-d0ff; (future hardware)
-- d003: capability R
--          10: pokeys       (00=1,01=2,10=4);
--         2  : sid          (0=0,1=dual sid);
--        3   : ym2149       (0=0,1=dual ym2149);
--       4    : covox/sample (0=0,1=covox/sample);
-- d004: post_divide W
--          10: 00=0,01=2,10=4 channel 0 (default 0 - 0-5v)
--        32  : 00=0,01=2,10=4 channel 1 (default 4 - 0-1.25v)
--      54    : 00=0,01=2,10=4 channel 2 (default 4 - 0-1.25v)
--    76      : 00=0,01=2,10=4 channel 3 (default 4 - 0-1.25v)
-- d005: post mix W
--           0: 0=direct, 1=TTLR (after saturation/divide)
-- d006: chip id   (W(which bits), R:read the max10 id) d000-d03f;
-- d007: copyright (R: read a short message, byte at a time!)

--	signal channel_mode : std_logic_vector(1 downto 0);
--	signal GTIA_VOLUME : std_logic;
--	--signal FORCE_MONO : std_logic;
--	signal SATURATE : std_logic;
--	signal PRE_DIVIDE : std_logic_vector(1 downto 0);
--	signal POST_DIVIDE : std_logic_vector(7 downto 0);

-------------------------------------------------------
-- AUDIO mixing
process(POST_DIVIDE_REG,POST_MIX_REG,AUDIO_0_SIGNED,AUDIO_1_SIGNED,AUDIO_2_SIGNED,AUDIO_3_SIGNED)
	variable a0u : unsigned(15 downto 0);
	variable a1u : unsigned(15 downto 0);
	variable a2u : unsigned(15 downto 0);
	variable a3u : unsigned(15 downto 0);
begin
	a0u(14 downto 0) := unsigned(AUDIO_0_SIGNED(14 downto 0));
	a1u(14 downto 0) := unsigned(AUDIO_1_SIGNED(14 downto 0));
	a2u(14 downto 0) := unsigned(AUDIO_2_SIGNED(14 downto 0));
	a3u(14 downto 0) := unsigned(AUDIO_3_SIGNED(14 downto 0));
	a0u(15) := not(AUDIO_0_SIGNED(15));
	a1u(15) := not(AUDIO_1_SIGNED(15));
	a2u(15) := not(AUDIO_2_SIGNED(15));	
	a3u(15) := not(AUDIO_3_SIGNED(15));	
	
	case POST_DIVIDE_REG(1 downto 0) is
		when "01" =>
			a0u(15) := '0';
			a0u(14 downto 0) := a0u(15 downto 1);
		when "10" =>
			a0u(15 downto 14) := "00";
			a0u(13 downto 0) := a0u(15 downto 2);
		when others =>
	end case;
	
	case POST_DIVIDE_REG(3 downto 2) is
		when "01" =>
			a1u(15) := '0';
			a1u(14 downto 0) := a1u(15 downto 1);
		when "10" =>
			a1u(15 downto 14) := "00";
			a1u(13 downto 0) := a1u(15 downto 2);
		when others =>
	end case;

	case POST_DIVIDE_REG(5 downto 4) is
		when "01" =>
			a2u(15) := '0';
			a2u(14 downto 0) := a2u(15 downto 1);
		when "10" =>
			a2u(15 downto 14) := "00";
			a2u(13 downto 0) := a2u(15 downto 2);
		when others =>
	end case;
	
	case POST_DIVIDE_REG(7 downto 6) is
		when "01" =>
			a3u(15) := '0';
			a3u(14 downto 0) := a3u(15 downto 1);
		when "10" =>
			a3u(15 downto 14) := "00";
			a3u(13 downto 0) := a3u(15 downto 2);
		when others =>
	end case;	
	
	case POST_MIX_REG is
		when "0" =>
			-- DIRECT
			AUDIO_0_UNSIGNED <= a0u;
			AUDIO_1_UNSIGNED <= a1u;
			AUDIO_2_UNSIGNED <= a2u;
			AUDIO_3_UNSIGNED <= a3u;			
		when "1" =>
			-- STEREO, post pokey
			AUDIO_0_UNSIGNED <= a0u+a1u+a2u+a3u; -- must also /4
			AUDIO_1_UNSIGNED <= a0u+a1u+a2u+a3u; -- must also /4
			AUDIO_2_UNSIGNED <= a0u+a2u; -- L must also /2
			AUDIO_3_UNSIGNED <= a1u+a3u; -- R must also /2
	end case;	
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

IRQ <= '0' when (POKEY_IRQ AND POKEY2_IRQ AND POKEY3_IRQ and POKEY4_IRQ)='0' else 'Z';

D <= BUS_DATA when BUS_OE='1' else (others=>'Z');

POTRESET_N <= not(POTRESET);

END vhdl;
