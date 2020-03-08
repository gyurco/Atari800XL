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

	signal SIO_CLOCKIN_IN : std_logic;
	signal SIO_CLOCKIN_OUT : std_logic;
	signal SIO_CLOCKIN_OE : std_logic;
	signal SIO_CLOCKOUT : std_logic;

	signal SIO_TXD : std_logic;
	signal SIO_RXD : std_logic;

	signal POKEY_IRQ : std_logic;

	signal ADDR_IN : std_logic_vector(5 downto 0);
	signal WRITE_DATA : std_logic_vector(7 downto 0);

	signal AUDIO_L_SIGNED : signed(15 downto 0);
	signal AUDIO_R_SIGNED : signed(15 downto 0);
	signal AUDIO_M_SIGNED : signed(15 downto 0);
	signal AUDIO_L_UNSIGNED : unsigned(15 downto 0);
	signal AUDIO_R_UNSIGNED : unsigned(15 downto 0);
	signal AUDIO_M_UNSIGNED : unsigned(15 downto 0);
	
	signal AUDIO_LEFT_LINE : std_logic;
	signal AUDIO_RIGHT_LINE : std_logic;
	signal AUDIO_MIXED_LINE : std_logic;
	signal AUDIO_MIXED_MAX : std_logic;

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
	signal A4_DETECT_FILTERED : std_logic;
	signal A5_DETECT_FILTERED : std_logic;

	signal CS_COMB : std_logic;

	signal AIN : std_logic_vector(5 downto 0);

	signal POTRESET : std_logic;

	signal stereo_enable : std_logic;
	signal gtia_audio : std_logic;
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
pokey_mixer_both : entity work.pokey_mixer_mux
GENERIC MAP
(
	LOWPASS => lowpass
)
PORT MAP(CLK => CLK,
		 ENABLE_179 => ENABLE_CYCLE,
		 CHANNEL_L_0 => POKEY1_CHANNEL0,
		 CHANNEL_L_1 => POKEY1_CHANNEL1,
		 CHANNEL_L_2 => POKEY1_CHANNEL2,
		 CHANNEL_L_3 => POKEY1_CHANNEL3,
		 CHANNEL_L2_0 => POKEY3_CHANNEL0,
		 CHANNEL_L2_1 => POKEY3_CHANNEL1,
		 CHANNEL_L2_2 => POKEY3_CHANNEL2,
		 CHANNEL_L2_3 => POKEY3_CHANNEL3,
		 CHANNEL_R_0 => POKEY2_CHANNEL0,
		 CHANNEL_R_1 => POKEY2_CHANNEL1,
		 CHANNEL_R_2 => POKEY2_CHANNEL2,
		 CHANNEL_R_3 => POKEY2_CHANNEL3,
		 CHANNEL_R2_0 => POKEY4_CHANNEL0,
		 CHANNEL_R2_1 => POKEY4_CHANNEL1,
		 CHANNEL_R2_2 => POKEY4_CHANNEL2,
		 CHANNEL_R2_3 => POKEY4_CHANNEL3,
		 GTIA_AUDIO => GTIA_AUDIO,
		 VOLUME_OUT_M => AUDIO_M_SIGNED,
		 VOLUME_OUT_L => AUDIO_L_SIGNED,
		 VOLUME_OUT_R => AUDIO_R_SIGNED);
		 
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

gen_quad : if stereo=2 generate --quad!
	process(SEL_POKEY,POKEY_DO,POKEY2_DO)
	begin
		DO_MUX <= (others =>'0');
		case SEL_POKEY is
			when "00" =>
				DO_MUX <= POKEY_DO;
			when "01" =>
				DO_MUX <= POKEY2_DO;
			when "10" =>
				DO_MUX <= POKEY3_DO;
			when "11" =>
				DO_MUX <= POKEY4_DO;
			when others =>
		end case;
	end process;

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

	process(write_n,request,sel_pokey)
	begin
		POKEY_WRITE_ENABLE <= '0';
		POKEY2_WRITE_ENABLE <= '0';
		POKEY3_WRITE_ENABLE <= '0';
		POKEY4_WRITE_ENABLE <= '0';

		if (write_n='0' and request='1') then
			case sel_pokey is
				when "00" =>
					POKEY_WRITE_ENABLE <= '1';
				when "01" =>
					POKEY2_WRITE_ENABLE <= '1';
				when "10" =>
					POKEY3_WRITE_ENABLE <= '1';
				when "11" =>
					POKEY4_WRITE_ENABLE <= '1';
				when others =>
					POKEY_WRITE_ENABLE <= '1';
			end case;
		end if;
	end process;

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
		 keyboard_response => "00",
		 pot_in=>"00000000");
end generate;

gen_stereo : if stereo=1 generate
	process(SEL_POKEY,POKEY_DO,POKEY2_DO)
	begin
		DO_MUX <= (others =>'0');
		if (SEL_POKEY(0)='1') then
			DO_MUX <= POKEY2_DO;
		else
			DO_MUX <= POKEY_DO;
		end if;
	end process;


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

	POKEY_WRITE_ENABLE <= NOT(WRITE_N) and REQUEST and NOT(SEL_POKEY(0));
	POKEY2_WRITE_ENABLE <= NOT(WRITE_N) and REQUEST and SEL_POKEY(0);

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
end generate;

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

	DO_MUX <= POKEY_DO;

	POKEY_WRITE_ENABLE <= NOT(WRITE_N) and REQUEST;
	
end generate;

AUDIO_L_UNSIGNED(14 downto 0) <= unsigned(AUDIO_L_SIGNED(14 downto 0));
AUDIO_M_UNSIGNED(14 downto 0) <= unsigned(AUDIO_M_SIGNED(14 downto 0));
AUDIO_R_UNSIGNED(14 downto 0) <= unsigned(AUDIO_R_SIGNED(14 downto 0));
AUDIO_L_UNSIGNED(15) <= not(AUDIO_L_SIGNED(15));
AUDIO_M_UNSIGNED(15) <= not(AUDIO_M_SIGNED(15));
AUDIO_R_UNSIGNED(15) <= not(AUDIO_R_SIGNED(15));	

--approx line level by using 5V/4 -> ok 1.25V, should be ok approx
dac_left_line : entity work.sigmadelta
port map
(
  reset_n => reset_n,
  clk => clk,
  audin => "00"&AUDIO_L_UNSIGNED(15 downto 2),
  AUDOUT => AUDIO_LEFT_LINE
);

dac_right_line : entity work.sigmadelta
port map
(
  reset_n => reset_n,
  clk => clk,
  audin => "00"&AUDIO_R_UNSIGNED(15 downto 2),
  AUDOUT => AUDIO_RIGHT_LINE
);

dac_mixed_line : entity work.sigmadelta
port map
(
  reset_n => reset_n,
  clk => clk,
  audin => "00"&AUDIO_M_UNSIGNED(15 downto 2),
  AUDOUT => AUDIO_MIXED_LINE
);

dac_mixed_max : entity work.sigmadelta
port map
(
  reset_n => reset_n,
  clk => clk,
  audin => AUDIO_M_UNSIGNED,
  AUDOUT => AUDIO_MIXED_MAX
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

--3
AUD(3) <= AUDIO_LEFT_LINE;
--4
AUD(4) <= AUDIO_RIGHT_LINE;
--2
AUD(2) <= AUDIO_MIXED_LINE;
--gnd
--
--1->pin37
AUD(1) <= AUDIO_MIXED_MAX;

IRQ <= '0' when POKEY_IRQ='0' else 'Z';

D <= BUS_DATA when BUS_OE='1' else (others=>'Z');

POTRESET_N <= not(POTRESET);

END vhdl;
