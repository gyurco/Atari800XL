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
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_MISC.all;

LIBRARY work;

ENTITY atari800core_eclaireXL IS 
	PORT
	(
		CLOCK_50 :  IN  STD_LOGIC;

		GPIO :  INOUT  STD_LOGIC_VECTOR(16 DOWNTO 0);

		PBI_A :  INOUT  STD_LOGIC_VECTOR(15 DOWNTO 0);
		PBI_D :  INOUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		PBI_CLK :  INOUT  STD_LOGIC;
		PBI_RW_N :  INOUT  STD_LOGIC;
		PBI_EXTSEL_N :  INOUT  STD_LOGIC;
		PBI_MPD_N :  INOUT  STD_LOGIC;
		PBI_REF_N :  INOUT  STD_LOGIC;
		PBI_IRQ_N :  INOUT  STD_LOGIC;
		PBI_RST_N :  INOUT  STD_LOGIC;

		CART_S4_N :  INOUT  STD_LOGIC;
		CART_S5_N :  INOUT  STD_LOGIC;
		CART_RD4 :  INOUT  STD_LOGIC;
		CART_RD5 :  INOUT  STD_LOGIC;
		CART_CCTL_N :  INOUT  STD_LOGIC;

		SIO_CLOCKIN :  INOUT  STD_LOGIC;
		SIO_CLOCKOUT :  INOUT  STD_LOGIC;
		SIO_IN :  INOUT  STD_LOGIC;
		SIO_IRQ :  INOUT  STD_LOGIC;
		SIO_OUT :  INOUT  STD_LOGIC;
		SIO_COMMAND :  INOUT  STD_LOGIC;
		SIO_PROCEED :  INOUT  STD_LOGIC;
		SIO_MOTOR_RAW :  INOUT  STD_LOGIC;

		SER_CMD :  INOUT  STD_LOGIC;
		SER_TX :  INOUT  STD_LOGIC;
		SER_RX :  INOUT  STD_LOGIC;

		PORTA :  INOUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		TRIG :  INOUT  STD_LOGIC_VECTOR(1 DOWNTO 0);
		POTIN :  INOUT  STD_LOGIC_VECTOR(3 DOWNTO 0);
		POTRESET :  INOUT  STD_LOGIC;

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

		VGA_BLANK_N : OUT STD_LOGIC;
		VGA_CLK : OUT STD_LOGIC;
		
		AUDIO_LEFT : OUT STD_LOGIC;
		AUDIO_RIGHT : OUT STD_LOGIC;

		USB2DM: INOUT STD_LOGIC;
		USB2DP: INOUT STD_LOGIC;
		USB1DM: INOUT STD_LOGIC;
		USB1DP: INOUT STD_LOGIC
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

component pll
	port (
		refclk   : in  std_logic := '0'; --  refclk.clk
		rst      : in  std_logic := '0'; --   reset.reset
		outclk_0 : out std_logic;        -- outclk0.clk
		outclk_1 : out std_logic;        -- outclk1.clk
		locked   : out std_logic         --  locked.export
	);
end component;


-- VIDEO
signal VIDEO_VS : std_logic;
signal VIDEO_HS : std_logic;

-- AUDIO
signal AUDIO_L_CORE : std_logic_vector(15 downto 0);
signal AUDIO_R_CORE : std_logic_vector(15 downto 0);

-- SYSTEM
SIGNAL CLOCK_5 : STD_LOGIC;
SIGNAL CLK : STD_LOGIC;
SIGNAL PLL_LOCKED : STD_LOGIC;

-- GPIO test
signal count_reg : std_logic_vector(18 downto 0);
signal count_next : std_logic_vector(18 downto 0);
signal shift_reg : std_logic_vector(7 downto 0);
signal shift_next : std_logic_vector(7 downto 0);
signal shift_trigger : std_logic;

signal sio_read : std_logic_vector(7 downto 0);

BEGIN 

pllinstance : pll
PORT MAP(refclk => CLOCK_50,
		 outclk_0 => CLOCK_5,
		 outclk_1 => CLK,
		 locked => PLL_LOCKED);


DRAM_CS_N <= '1';
DRAM_BA_0 <= 'Z';
DRAM_BA_1 <= 'Z';
DRAM_RAS_N <= 'Z';
DRAM_CAS_N <= 'Z';
DRAM_WE_N <= 'Z';
DRAM_LDQM <= 'Z';
DRAM_UDQM <= 'Z';
DRAM_CKE <= 'Z';
DRAM_ADDR <= (others=>'Z');
DRAM_DQ <= (others=>'Z');

SD_DAT1 <= 'Z';
SD_DAT2 <= 'Z';
SD_DAT3 <= 'Z';
SD_CMD <= 'Z';
SD_CLK <= 'Z';

USB2DM <= 'Z';
USB2DP <= 'Z';
USB1DM <= 'Z';
USB1DP <= 'Z';
		
--VGA_VS <= 'Z';
--VGA_HS <= 'Z';
--VGA_B <= (others=>'Z');
--VGA_G <= (others=>'Z');
--VGA_R <= (others=>'Z');
--VGA_BLANK_N <= 'Z';
--VGA_CLK <= 'Z';
		
--AUDIO_LEFT <= 'Z';
--AUDIO_RIGHT <= 'Z';

PBI_CLK <= 'Z';
PBI_RW_N <= 'Z';
PBI_EXTSEL_N <= 'Z';
PBI_MPD_N <= 'Z';
PBI_REF_N <= 'Z';
PBI_IRQ_N <= 'Z';
PBI_RST_N <= 'Z';

CART_S4_N <= 'Z';
CART_S5_N <= 'Z';
CART_RD4 <= 'Z';
CART_RD5 <= 'Z';
CART_CCTL_N <= 'Z';

--SIO_CLOCKIN <= 'Z';
--SIO_CLOCKOUT <= 'Z';
--SIO_IN <= 'Z';
--SIO_IRQ <= 'Z';
--SIO_OUT <= 'Z';
--SIO_COMMAND <= 'Z';
--SIO_PROCEED <= 'Z';
--SIO_MOTOR_RAW <= 'Z';

SER_CMD <= 'Z';
SER_TX <= 'Z';
SER_RX <= 'Z';

POTIN <= (others=>'Z');
POTRESET <= 'Z';

process(clock_5,pll_locked)
begin
	if (pll_locked='0') then
		shift_reg(7 downto 1) <= (others=>'0');
		shift_reg(0) <= '1';
		count_reg <= (others=>'0');
	elsif (clock_5'event and clock_5='1') then
		shift_reg <= shift_next;
		count_reg <= count_next;
	end if;
end process;

process(shift_reg,shift_trigger)
begin
	shift_next <= shift_reg;
	if (shift_trigger='1') then
		shift_next(7 downto 0) <= shift_reg(6 downto 0)&shift_reg(7);
	end if;
end process;

process(count_reg)
begin
	count_next <= std_logic_vector(unsigned(count_reg)+1);
	shift_trigger <= and_reduce(count_reg);
end process;

--GPIO <= shift_reg(7 downto 0)&shift_reg(7 downto 0)&shift_reg(7 downto 7);
PORTA <= shift_reg(7 downto 0);
TRIG <= shift_reg(1 downto 0);
PBI_A <= shift_reg(7 downto 0)&shift_reg(7 downto 0);
PBI_D <= shift_reg(7 downto 0);

GPIO(16 downto 8) <= (others=>'0');
GPIO(7 downto 0) <= sio_read xor shift_reg;

SIO_CLOCKIN <= 'Z' when shift_reg(7)='1' else '0';
SIO_CLOCKOUT <= 'Z' when shift_reg(6)='1' else '0';
SIO_IN <= 'Z' when shift_reg(5)='1' else '0';
SIO_IRQ <= 'Z' when shift_reg(4)='1' else '0';
SIO_OUT <= 'Z' when shift_reg(3)='1' else '0';
SIO_COMMAND <= 'Z' when shift_reg(2)='1' else '0';
SIO_PROCEED <= 'Z' when shift_reg(1)='1' else '0';
SIO_MOTOR_RAW <= 'Z' when shift_reg(0)='1' else '0';

sio_read(7) <= SIO_CLOCKIN;
sio_read(6) <= SIO_CLOCKOUT;
sio_read(5) <= SIO_IN;
sio_read(4) <= SIO_IRQ;
sio_read(3) <= SIO_OUT;
sio_read(2) <= SIO_COMMAND;
sio_read(1) <= SIO_PROCEED;
sio_read(0) <= SIO_MOTOR_RAW;


core : entity work.atari800core_helloworld
	generic map
	(
		cycle_length => 32,
		internal_ram => 65536
	)
	port map
	(
		CLK => clk,
		RESET_N => pll_locked,

		-- VIDEO OUT - PAL/NTSC, original Atari timings approx (may be higher res)
		VIDEO_VS => video_vs,
		VIDEO_HS => video_hs,
		VIDEO_B => vga_b,
		VIDEO_G => vga_g,
		VIDEO_R => vga_r,

		-- AUDIO OUT - Pokey/GTIA 1-bit and Covox all mixed
		-- TODO - choose stereo/mono pokey
		AUDIO_L => audio_l_core,
		AUDIO_R => audio_r_core,

		-- JOYSTICK
		JOY1_n => "11111",
		JOY2_n => "11111",

		-- KEYBOARD
		PS2_CLK => '0',
		PS2_DAT => '0',

		-- video standard
		PAL => '1'
	);

VGA_HS <= not(VIDEO_HS xor VIDEO_VS);
VGA_VS <= not(VIDEO_VS);
VGA_BLANK_N <= '1';
VGA_CLK <= CLK;

dac_left : hq_dac
port map
(
  reset => not(pll_locked),
  clk => clk,
  clk_ena => '1',
  pcm_in => AUDIO_L_CORE&"0000",
  dac_out => AUDIO_LEFT
);

dac_right : hq_dac
port map
(
  reset => not(pll_locked),
  clk => clk,
  clk_ena => '1',
  pcm_in => AUDIO_R_CORE&"0000",
  dac_out => AUDIO_RIGHT
);

END vhdl;
