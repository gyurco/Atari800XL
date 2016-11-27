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

		--VGA_VS :  OUT  STD_LOGIC;
		--VGA_HS :  OUT  STD_LOGIC;
		--VGA_B :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		--VGA_G :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		--VGA_R :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		--TMDS :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);

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

component pll2
	port (
		refclk   : in  std_logic := '0'; --  refclk.clk
		rst      : in  std_logic := '0'; --   reset.reset
		outclk_0 : out std_logic;        -- outclk0.clk
		outclk_1 : out std_logic;        -- outclk1.clk
		locked   : out std_logic         --  locked.export
	);
end component;

-- SYSTEM
SIGNAL CLK : STD_LOGIC;
SIGNAL CLK_114 : STD_LOGIC;
SIGNAL SVIDEO_ECS_CLK : STD_LOGIC;
SIGNAL PLL_LOCKED : STD_LOGIC;

-- ModeLine "720x576@50"      27     720  732  795  864  576  581  586  625 -hsync -vsync (576p)
-- ModeLine "768x576@50"      29.5   768  789  858  944  576  581  586  625 -hsync -vsync
-- ModeLine " 640x 480@60Hz"  25.20  640  656  752  800  480  490  492  525 -HSync -VSync
-- ModeLine " 720x 480@60Hz"  27.00  720  736  798  858  480  489  495  525 -HSync -VSync
-- Modeline " 800x 600@60Hz"  40.00  800  840  968 1056  600  601  605  628 +HSync +VSync
-- ModeLine "1024x 768@60Hz"  65.00 1024 1048 1184 1344  768  771  777  806 -HSync -VSync
-- ModeLine "1280x 720@60Hz"  74.25 1280 1390 1430 1650  720  725  730  750 +HSync +VSync
-- ModeLine "1280x 768@60Hz"  80.14 1280 1344 1480 1680  768  769  772  795 +HSync +VSync
-- ModeLine "1280x 800@60Hz"  83.46 1280 1344 1480 1680  800  801  804  828 +HSync +VSync
-- ModeLine "1280x 960@60Hz" 108.00 1280 1376 1488 1800  960  961  964 1000 +HSync +VSync
-- ModeLine "1280x1024@60Hz" 108.00 1280 1328 1440 1688 1024 1025 1028 1066 +HSync +VSync
-- ModeLine "1360x 768@60Hz"  85.50 1360 1424 1536 1792  768  771  778  795 -HSync -VSync
-- ModeLine "1920x1080@25Hz"  74.25 1920 2448 2492 2640 1080 1084 1089 1125 +HSync +VSync
-- ModeLine "1920x1080@30Hz"  89.01 1920 2448 2492 2640 1080 1084 1089 1125 +HSync +VSync

-- Horizontal Timing constants  
constant h_pixels_across	: integer := 720 - 1;
constant h_sync_on		: integer := 732 - 1;
constant h_sync_off		: integer := 795 - 1;
constant h_end_count		: integer := 864 - 1;
-- Vertical Timing constants
constant v_pixels_down		: integer := 576 - 1;
constant v_sync_on		: integer := 581 - 1;
constant v_sync_off		: integer := 586 - 1;
constant v_end_count		: integer := 625 - 1;

signal hcnt		: std_logic_vector(11 downto 0) := "000000000000"; 	-- horizontal pixel counter
signal vcnt		: std_logic_vector(11 downto 0) := "000000000000"; 	-- vertical line counter
signal hsync		: std_logic;
signal vsync		: std_logic;
signal blank		: std_logic;
signal shift		: std_logic_vector(7 downto 0);
signal red		: std_logic_vector(7 downto 0);
signal green		: std_logic_vector(7 downto 0);
signal blue		: std_logic_vector(7 downto 0);
signal clk_hdmi		: std_logic;
signal clk_vga		: std_logic;


signal TMDS :  STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN 

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
		
ADC_SDA <= 'Z';
ADC_SCL <= 'Z';

--VGA_VS <= 'Z';
--VGA_HS <= 'Z';
--VGA_B <= (others=>'Z');
--VGA_G <= (others=>'Z');
--VGA_R <= (others=>'Z');
VGA_BLANK_N <= '0';
VGA_CLK <= '0';
		
AUDIO_LEFT <= 'Z';
AUDIO_RIGHT <= 'Z';


--GPIOA <= shift_reg(35 downto 0);
GPIOB <= (others=>'0');
GPIOC <= (others=>'0');

GPIOA(35 downto 16) <= (others=>'0');
GPIOA(0) <= '0';
GPIOA(11 downto 5) <= (others=>'0');

GPIOA(1) <= TMDS(7); -- D2P
GPIOA(2) <= TMDS(6); -- D2N
GPIOA(3) <= TMDS(5); -- D1P
GPIOA(4) <= TMDS(4); -- D1N

GPIOA(12) <= TMDS(2); -- D0N
GPIOA(13) <= TMDS(3); -- D0P
GPIOA(14) <= TMDS(0); -- C N
GPIOA(15) <= TMDS(1); -- C P

-- PLL
pll2_inst: pll2
port map (
	refclk		=> CLOCK_5,		-- 5.0 MHz

	-- out
	locked		=> open,
	outclk_0	=> clk_hdmi,	-- clk_vga * 5
	outclk_1	=> clk_vga);

-- HDMI
hdmi_inst: entity work.hdmi
port map (
	I_CLK_PIXEL	=> clk_vga,
	I_CLK_TMDS	=> clk_hdmi,	-- 472.6 MHz max

	I_HSYNC		=> hsync,
	I_VSYNC		=> vsync,
	I_BLANK		=> blank,
	I_RED		=> red,
	I_GREEN		=> green,
	I_BLUE		=> blue,
	O_TMDS		=> TMDS);

	process (clk_vga, hcnt)
	begin
		if clk_vga'event and clk_vga = '1' then
			if hcnt = h_end_count then
				hcnt <= (others => '0');
			else
				hcnt <= hcnt + 1;
			end if;
			if hcnt = h_sync_on then
				if vcnt = v_end_count then
					vcnt <= (others => '0');
					shift <= shift + 1;
				else
					vcnt <= vcnt + 1;
				end if;
			end if;
		end if;
	end process;

	hsync	<= '0' when (hcnt <= h_sync_on) or (hcnt > h_sync_off) else '1';
	vsync	<= '0' when (vcnt <= v_sync_on) or (vcnt > v_sync_off) else '1';
	blank	<= '1' when (hcnt > h_pixels_across) or (vcnt > v_pixels_down) else '0';

	red	<= "11111111" when hcnt = 0 or hcnt = h_pixels_across or vcnt = 0 or vcnt = v_pixels_down else (hcnt(7 downto 0) + shift) and "11111111";
	green	<= "11111111" when hcnt = 0 or hcnt = h_pixels_across or vcnt = 0 or vcnt = v_pixels_down else (vcnt(7 downto 0) + shift) and "11111111";
	blue	<= "11111111" when hcnt = 0 or hcnt = h_pixels_across or vcnt = 0 or vcnt = v_pixels_down else (hcnt(7 downto 0) + vcnt(7 downto 0) - shift) and "11111111";

END vhdl;
