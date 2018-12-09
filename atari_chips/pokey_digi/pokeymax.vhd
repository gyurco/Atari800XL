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
		CS1 : IN STD_LOGIC;
		CS0_N : IN STD_LOGIC;

		AUD : OUT STD_LOGIC;

		PADDLE : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);

		KEYBOARD_SCAN : OUT STD_LOGIC_VECTOR(5 downto 0);
		KEYBOARD_RESPONSE : IN STD_LOGIC_VECTOR(1 downto 0)
	);
END pokeymax;		
		
ARCHITECTURE vhdl OF pokeymax IS
	component int_osc is
	port (
		clkout : out std_logic;        -- clkout.clk
		oscena : in  std_logic := '0'  -- oscena.oscena
	);
	end component;

	component hq_dac
	port (
	  reset :in std_logic;
	  clk :in std_logic;
	  clk_ena : in std_logic;
	  pcm_in : in std_logic_vector(19 downto 0);
	  dac_out : out std_logic
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
	
	signal SIO_CLOCKIN_IN : std_logic;
	signal SIO_CLOCKIN_OUT : std_logic;
	signal SIO_CLOCKIN_OE : std_logic;
	signal SIO_CLOCKOUT : std_logic;

	signal SIO_TXD : std_logic;
	signal SIO_RXD : std_logic;

	signal POKEY_IRQ : std_logic;

	signal POT_RESET : std_logic;

	signal ADDR_IN : std_logic_vector(4 downto 0);
	signal WRITE_DATA : std_logic_vector(7 downto 0);

	signal AUDIO_L : std_logic_vector(15 downto 0);

	signal AUDIO_LEFT : std_logic;

	signal BUS_DATA : std_logic_vector(7 downto 0);
	signal BUS_OE : std_logic;

	signal REQUEST : std_logic;
	signal WRITE_N : std_logic;

	signal DO_MUX : std_logic_vector(7 downto 0);

	signal CS_COMB : std_logic;
BEGIN
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

	CS_COMB <= not(CS0_N) and CS1;

bus_adapt : entity work.slave_timing_6502
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N,
		
		-- input from the cart port
		PHI2 => PHI2,
		bus_addr(3 downto 0) => A,
		bus_addr(4) => '0',
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
		 CHANNEL_R_0 => (others=>'0'),
		 CHANNEL_R_1 => (others=>'0'),
		 CHANNEL_R_2 => (others=>'0'),
		 CHANNEL_R_3 => (others=>'0'),
		 VOLUME_OUT_M => open,
		 VOLUME_OUT_L => AUDIO_L,
		 VOLUME_OUT_R => open);
		 
pokey1 : entity work.pokey
GENERIC MAP
(
	custom_keyboard_scan => 0
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
		 POT_RESET => POT_RESET,
		 CHANNEL_0_OUT => POKEY1_CHANNEL0,
		 CHANNEL_1_OUT => POKEY1_CHANNEL1,
		 CHANNEL_2_OUT => POKEY1_CHANNEL2,
		 CHANNEL_3_OUT => POKEY1_CHANNEL3,
		 DATA_OUT => POKEY_DO,
		 keyboard_scan => KEYBOARD_SCAN
		);

	DO_MUX <= POKEY_DO;

	POKEY_WRITE_ENABLE <= NOT(WRITE_N) and REQUEST;

dac_mixed : hq_dac
port map
(
  reset => not(reset_n),
  clk => clk,
  clk_ena => '1',
  pcm_in => AUDIO_L&"0000",
  dac_out => AUDIO_LEFT
);

-- io extension
-- drive to 0 for pot reset (otherwise high imp)
-- drive keyboard lines
--		pot_reset=>pot_reset,
--		keyboard_scan=>keyboard_scan,
--		keyboard_scan_enable=>keyboard_scan_enable,
--		keyboard_response=>keyboard_response

-- Wire up pins
CLK_OUT <= PHI2_6X;

ACLK <= SIO_CLOCKOUT;
BCLK <= '0' when (SIO_CLOCKIN_OE='1' and SIO_CLOCKIN_OUT='0') else 'Z';
SIO_CLOCKIN_IN <= BCLK;

SOD <= '0' when SIO_TXD='0' else 'Z';
SIO_RXD <= SID;

--gnd
--
--1->pin37
AUD <= AUDIO_LEFT;

IRQ <= '0' when POKEY_IRQ='0' else 'Z';

D <= BUS_DATA when BUS_OE='1' else (others=>'Z');

PADDLE <= (others=>'0') when POT_RESET='1' else (others=>'Z');

END vhdl;
