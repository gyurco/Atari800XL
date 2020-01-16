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
		stereo : integer := 1 -- 0=MONO,1=STEREO
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

	signal SIO_CLOCKIN_IN : std_logic;
	signal SIO_CLOCKIN_OUT : std_logic;
	signal SIO_CLOCKIN_OE : std_logic;
	signal SIO_CLOCKOUT : std_logic;

	signal SIO_TXD : std_logic;
	signal SIO_RXD : std_logic;

	signal POKEY_IRQ : std_logic;

	signal ADDR_IN : std_logic_vector(4 downto 0);
	signal WRITE_DATA : std_logic_vector(7 downto 0);

	signal AUDIO_L : std_logic_vector(15 downto 0);
	signal AUDIO_R : std_logic_vector(15 downto 0);
	signal AUDIO_M : std_logic_vector(15 downto 0);
	signal AUDIO_L_SIGNED : signed(15 downto 0);
	signal AUDIO_R_SIGNED : signed(15 downto 0);
	signal AUDIO_M_SIGNED : signed(15 downto 0);	

	signal AUDIO_LEFT : std_logic;
	signal AUDIO_RIGHT : std_logic;
	signal AUDIO_MIXED : std_logic;

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

	signal sel_pokey2 : std_logic;

	signal CS_COMB : std_logic;

	signal AIN : std_logic_vector(4 downto 0);

	signal POTRESET : std_logic;
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

	AIN <= EXT(1)&A;
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
PORT MAP(CLK => CLK,
		 ENABLE_179 => ENABLE_CYCLE,
		 CHANNEL_L_0 => POKEY1_CHANNEL0,
		 CHANNEL_L_1 => POKEY1_CHANNEL1,
		 CHANNEL_L_2 => POKEY1_CHANNEL2,
		 CHANNEL_L_3 => POKEY1_CHANNEL3,
		 CHANNEL_R_0 => POKEY2_CHANNEL0,
		 CHANNEL_R_1 => POKEY2_CHANNEL1,
		 CHANNEL_R_2 => POKEY2_CHANNEL2,
		 CHANNEL_R_3 => POKEY2_CHANNEL3,
		 VOLUME_OUT_M => AUDIO_M,
		 VOLUME_OUT_L => AUDIO_L,
		 VOLUME_OUT_R => AUDIO_R);
		 
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

gen_stereo : if stereo=1 generate
	process(SEL_POKEY2,POKEY_DO,POKEY2_DO)
	begin
		DO_MUX <= (others =>'0');
		if (SEL_POKEY2='1') then
			DO_MUX <= POKEY2_DO;
		else
			DO_MUX <= POKEY_DO;
		end if;
	end process;

	isstereo : ENTITY work.stereo_detect
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,
	
		A => AIN, -- raw...
		ADDR_IN => ADDR_IN, -- on request
	
		SEL_POKEY2 => sel_pokey2
	);

	POKEY_WRITE_ENABLE <= NOT(WRITE_N) and REQUEST and NOT(SEL_POKEY2);
	POKEY2_WRITE_ENABLE <= NOT(WRITE_N) and REQUEST and SEL_POKEY2;

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
end generate;

gen_mono : if stereo=0 generate
	POKEY2_CHANNEL0 <= "0000";
	POKEY2_CHANNEL1 <= "0000";
	POKEY2_CHANNEL2 <= "0000";
	POKEY2_CHANNEL3 <= "0000";

	DO_MUX <= POKEY_DO;

	POKEY_WRITE_ENABLE <= NOT(WRITE_N) and REQUEST;
	
end generate;

AUDIO_L_SIGNED  <= to_signed(to_integer(unsigned(AUDIO_L))-32768,16);
AUDIO_R_SIGNED <= to_signed(to_integer(unsigned(AUDIO_R))-32768,16);
AUDIO_M_SIGNED <= to_signed(to_integer(unsigned(AUDIO_M))-32768,16);

dac_left : entity work.dac_dsm3
port map
(
  n_rst => reset_n,
  clk => clk,
  clk_ena => '1',
  din => AUDIO_L_SIGNED,
  dout => AUDIO_LEFT
);

dac_right : entity work.dac_dsm3
port map
(
  n_rst => reset_n,
  clk => clk,
  clk_ena => '1',
  din => AUDIO_R_SIGNED,
  dout => AUDIO_RIGHT
);

dac_mixed : entity work.dac_dsm3
port map
(
  n_rst => reset_n,
  clk => clk,
  clk_ena => '1',
  din => AUDIO_M_SIGNED,
  dout => AUDIO_MIXED
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
AUD(3) <= AUDIO_LEFT;
--4
AUD(4) <= AUDIO_RIGHT;
--2
AUD(2) <= AUDIO_MIXED;
--gnd
--
--1->pin37
AUD(1) <= AUDIO_MIXED;

IRQ <= '0' when POKEY_IRQ='0' else 'Z';

D <= BUS_DATA when BUS_OE='1' else (others=>'Z');

POTRESET_N <= not(POTRESET);

END vhdl;
