---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY atari800core_mcc IS 
	PORT
	(
		FPGA_CLK :  IN  STD_LOGIC;
		PS2K_CLK :  IN  STD_LOGIC;
		PS2K_DAT :  IN  STD_LOGIC;
		PS2M_CLK :  IN  STD_LOGIC;
		PS2M_DAT :  IN  STD_LOGIC;		

		VGA_VS :  OUT  STD_LOGIC;
		VGA_HS :  OUT  STD_LOGIC;
		VGA_B :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_G :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_R :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0);
		
		JOY1_n :  IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
		JOY2_n :  IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
		
		AUDIO_L : OUT std_logic;
		AUDIO_R : OUT std_logic;

		SDRAM_BA :  OUT  STD_LOGIC_VECTOR(1 downto 0);
		SDRAM_CS_N :  OUT  STD_LOGIC;
		SDRAM_RAS_N :  OUT  STD_LOGIC;
		SDRAM_CAS_N :  OUT  STD_LOGIC;
		SDRAM_WE_N :  OUT  STD_LOGIC;
		SDRAM_DQM_n :  OUT  STD_LOGIC_vector(1 downto 0);
		SDRAM_CLK :  OUT  STD_LOGIC;
		--SDRAM_CKE :  OUT  STD_LOGIC;
		SDRAM_A :  OUT  STD_LOGIC_VECTOR(12 DOWNTO 0);
		SDRAM_DQ :  INOUT  STD_LOGIC_VECTOR(15 DOWNTO 0);

		SD_DAT0 :  IN  STD_LOGIC;
		SD_CLK :  OUT  STD_LOGIC;
		SD_CMD :  OUT  STD_LOGIC;
		SD_DAT3 :  OUT  STD_LOGIC
	);
END atari800core_mcc;

ARCHITECTURE vhdl OF atari800core_mcc IS 

component hq_dac
port (
  reset :in std_logic;
  clk :in std_logic;
  clk_ena : in std_logic;
  pcm_in : in std_logic_vector(19 downto 0);
  dac_out : out std_logic
);
end component;

COMPONENT pll
	PORT(inclk0 : IN STD_LOGIC;
		 c0 : OUT STD_LOGIC;
		 c1 : OUT STD_LOGIC;
		 c2 : OUT STD_LOGIC;
		 locked : OUT STD_LOGIC
	);
END COMPONENT;

  signal AUDIO_L_PCM : std_logic_vector(15 downto 0);
  signal AUDIO_R_PCM : std_logic_vector(15 downto 0);

  signal VGA_R_WIDE : std_logic_vector(7 downto 0);
  signal VGA_G_WIDE : std_logic_vector(7 downto 0);
  signal VGA_B_WIDE : std_logic_vector(7 downto 0);
  signal VGA_VS_RAW : std_logic;
  signal VGA_HS_RAW : std_logic;

  signal JOY1_IN_n : std_logic_vector(4 downto 0);
  signal JOY2_IN_n : std_logic_vector(4 downto 0);

  signal RESET_n : std_logic;
  signal PLL_LOCKED : std_logic;
  signal CLK : std_logic;
  signal CLK_SDRAM : std_logic;

BEGIN 

dac_left : hq_dac
port map
(
  reset => not(reset_n),
  clk => clk,
  clk_ena => '1',
  pcm_in => AUDIO_L_PCM&"0000",
  dac_out => audio_l
);

dac_right : hq_dac
port map
(
  reset => not(reset_n),
  clk => clk,
  clk_ena => '1',
  pcm_in => AUDIO_R_PCM&"0000",
  dac_out => audio_r
);

mcc_pll : pll
PORT MAP(inclk0 => FPGA_CLK,
		 c0 => CLK_SDRAM,
		 c1 => CLK,
		 c2 => SDRAM_CLK,
		 locked => PLL_LOCKED);

reset_n <= PLL_LOCKED;
JOY1_IN_N <= JOY1_n(4)&JOY1_n(0)&JOY1_n(1)&JOY1_n(2)&JOY1_n(3);
JOY2_IN_N <= JOY2_n(4)&JOY2_n(0)&JOY2_n(1)&JOY2_n(2)&JOY2_n(3);

VGA_HS <= not(VGA_HS_RAW xor VGA_VS_RAW);
VGA_VS <= not(VGA_VS_RAW);
VGA_R <= VGA_R_WIDE(7 downto 4);
VGA_G <= VGA_G_WIDE(7 downto 4);
VGA_B <= VGA_B_WIDE(7 downto 4);

atari800xl : entity work.atari800core_helloworld
	GENERIC MAP
	(
		cycle_length => 32,
		internal_ram => 16384
	)
	PORT MAP
	(
		CLK => clk,
		RESET_N => reset_n,

		VGA_VS => vga_vs_raw,
		VGA_HS => vga_hs_raw,
		VGA_B => vga_b_wide,
		VGA_G => vga_g_wide,
		VGA_R => vga_r_wide,

		AUDIO_L => AUDIO_L_PCM,
		AUDIO_R => AUDIO_R_PCM,

		JOY1_n => JOY1_IN_n,
		JOY2_n => JOY2_IN_n,

		PS2_CLK => ps2k_clk,
		PS2_DAT => ps2k_dat,

		PAL => '1'
	);

--b2v_inst20 : sdram_statemachine_mcc
--GENERIC MAP(ADDRESS_WIDTH => 22,
--			AP_BIT => 10,
--			COLUMN_WIDTH => 8,
--			ROW_WIDTH => 12
--			)
--PORT MAP(CLK_SYSTEM => CLK,
--		 CLK_SDRAM => CLK_SDRAM,
--		 RESET_N => RESET_N,
--		 READ_EN => SDRAM_READ_ENABLE,
--		 WRITE_EN => SDRAM_WRITE_ENABLE,
--		 REQUEST => SDRAM_REQUEST,
--		 BYTE_ACCESS => WIDTH_8BIT_ACCESS,
--		 WORD_ACCESS => WIDTH_16BIT_ACCESS,
--		 LONGWORD_ACCESS => WIDTH_32BIT_ACCESS,
--		 REFRESH => SDRAM_REFRESH,
--		 ADDRESS_IN => SDRAM_ADDR,
--		 DATA_IN => WRITE_DATA,
--		 SDRAM_DQ => SDRAM_DQ,
--		 REPLY => SDRAM_REQUEST_COMPLETE,
--		 SDRAM_BA0 => SDRAM_BA(0),
--		 SDRAM_BA1 => SDRAM_BA(1),
--		 --SDRAM_CKE => SDRAM_A(12), -- TODO?
--		 SDRAM_CS_N => SDRAM_CS_N,
--		 SDRAM_RAS_N => SDRAM_RAS_N,
--		 SDRAM_CAS_N => SDRAM_CAS_N,
--		 SDRAM_WE_N => SDRAM_WE_N,
--		 SDRAM_ldqm => SDRAM_DQM_n(0),
--		 SDRAM_udqm => SDRAM_DQM_n(1),
--		 DATA_OUT => SDRAM_DO,
--		 SDRAM_ADDR => SDRAM_A(12 downto 0)); -- TODO?

		
END vhdl;
