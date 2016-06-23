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

LIBRARY work;

ENTITY atari800core_eclaireXL IS 
	PORT
	(
		CLOCK_5 :  IN  STD_LOGIC;

		PS2CLK :  IN  STD_LOGIC;
		PS2DAT :  IN  STD_LOGIC;

		GPIOA :  INOUT  STD_LOGIC_VECTOR(35 DOWNTO 0);
		GPIOB :  INOUT  STD_LOGIC_VECTOR(35 DOWNTO 0);
		GPIOC:  INOUT  STD_LOGIC_VECTOR(35 DOWNTO 0);

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
		USB1DP: INOUT STD_LOGIC;
		
		ADC_SDA: INOUT STD_LOGIC;
		ADC_SCL: INOUT STD_LOGIC
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
		outclk_2 : out std_logic;        -- outclk2.clk
		outclk_3 : out std_logic;        -- outclk3.clk
		locked   : out std_logic         --  locked.export
	);
end component;

-- VIDEO
signal VIDEO_VS : std_logic;
signal VIDEO_HS : std_logic;
signal VIDEO_BLANK : std_logic;

-- AUDIO
signal AUDIO_L_CORE : std_logic_vector(15 downto 0);
signal AUDIO_R_CORE : std_logic_vector(15 downto 0);

-- SYSTEM
SIGNAL CLK : STD_LOGIC;
SIGNAL CLK_114 : STD_LOGIC;
SIGNAL CLK_SDRAM : STD_LOGIC;
SIGNAL RESET_N : STD_LOGIC;
signal SDRAM_RESET_N : std_logic;
SIGNAL PLL_LOCKED : STD_LOGIC;

BEGIN 

core : entity work.atari800core_helloworld
	generic map
	(
		cycle_length => 32;
	);
	port map
	(
		CLK => clk_pll,
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
		JOY1_n => "11111";
		JOY2_n => "11111";

		-- KEYBOARD
		PS2_CLK => ps2clk,
		PS2_DAT => ps2dat,

		-- video standard
		PAL => "1"
	);

VGA_HS <= not(VIDEO_HS xor VIDEO_VS);
VGA_VS <= not(VIDEO_VS);
VGA_BLANK_N <= NOT(VIDEO_BLANK);
VGA_CLK <= CLK;

dac_left : hq_dac
port map
(
  reset => not(reset_n),
  clk => clk,
  clk_ena => '1',
  pcm_in => AUDIO_L_CORE&"0000",
  dac_out => AUDIO_LEFT
);

dac_right : hq_dac
port map
(
  reset => not(reset_n),
  clk => clk,
  clk_ena => '1',
  pcm_in => AUDIO_R_CORE&"0000",
  dac_out => AUDIO_RIGHT
);

pllinstance : pll
PORT MAP(refclk => CLOCK_5,
		 outclk_0 => CLK_114,
		 outclk_1 => CLK,
		 outclk_2 => DRAM_CLK,
		 outclk_3 => SVIDEO_ECS_CLK,
		 locked => PLL_LOCKED);

END vhdl;
