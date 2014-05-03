library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_textio.all;

library std_developerskit ; -- used for to_string
--  use std_developerskit.std_iopak.all;

entity atari800core_mcc_tb is
end;

architecture rtl of atari800core_mcc_tb is

--  constant CLK_PERIOD : time := 1 us / (1.79*16);
--  constant CLK_PERIOD_FOUR : time := 1 us / (1.79*64);
--  constant CLK_PERIOD_THREE : time := 1 us / (1.79*48);
--  constant CLK_PERIOD_TWO : time := 1 us / (1.79*32);
  constant CLK_PERIOD : time := 36ns;
  constant CLK_PERIOD_FOUR : time := 9ns;
  constant CLK_PERIOD_THREE : time := 12ns;
  constant CLK_PERIOD_TWO : time := 18ns;
  signal CLK : std_logic;
  signal CLK_TWO : std_logic;
  signal CLK_THREE : std_logic;
  signal CLK_FOUR : std_logic;

  signal reset_n : std_logic;
  signal reset : std_logic;

  signal	VGA_VS : std_logic;
  signal	VGA_HS : std_logic;
  signal	VGA_B : std_logic_vector(3 downto 0);
  signal	VGA_G : std_logic_vector(3 downto 0);
  signal	VGA_R : std_logic_vector(3 downto 0);
  signal	AUDIO_L : std_logic;
  signal	AUDIO_R : std_logic;
  signal	SDRAM_BA : std_logic_vector(1 downto 0);
  signal	SDRAM_CS_N : std_logic;
  signal	SDRAM_RAS_N : std_logic;
  signal	SDRAM_CAS_N : std_logic;
  signal	SDRAM_WE_N : std_logic;
  signal	SDRAM_DQM_n : std_logic_vector(1 downto 0);
  signal	SDRAM_CLK : std_logic;
  signal	SDRAM_A : std_logic_vector(12 downto 0);
  signal	SDRAM_DQ : std_logic_vector(15 downto 0);

begin
	p_clk_gen_1 : process
	begin
	clk <= '1';
	wait for CLK_PERIOD/2;
	clk <= '0';
	wait for CLK_PERIOD - (CLK_PERIOD/2 );
	end process;

	p_clk_gen_2 : process
	begin
	clk_two <= '1';
	wait for CLK_PERIOD_TWO/2;
	clk_two <= '0';
	wait for CLK_PERIOD_TWO - (CLK_PERIOD_TWO/2 );
	end process;

	p_clk_gen_3 : process
	begin
	clk_three <= '1';
	wait for CLK_PERIOD_three/2;
	clk_three <= '0';
	wait for CLK_PERIOD_three - (CLK_PERIOD_three/2 );
	end process;

	p_clk_gen_4 : process
	begin
	clk_four <= '1';
	wait for CLK_PERIOD_four/2;
	clk_four <= '0';
	wait for CLK_PERIOD_four - (CLK_PERIOD_four/2 );
	end process;

	reset_n <= '0', '1' after 1000ns;

	reset <= not(reset_n);

atari : ENTITY work.atari800core_mcc 
	GENERIC map
	(
		TV => 1,
		VIDEO => 2,
		SCANDOUBLE => 1,
		internal_ram => 0,
		ext_clock => 1
	)
	port map
	(
		FPGA_CLK => '0',

		EXT_CLK_SDRAM(1) => clk_three,
		EXT_CLK(1) => clk,
		EXT_SDRAM_CLK(1) => clk_three,
                EXT_SVIDEO_DAC_CLK(1) => clk_four,
                EXT_SCANDOUBLE_CLK(1) => clk_two,
                EXT_PLL_LOCKED(1) => reset_n,

		PS2K_CLK => '1',
		PS2K_DAT => '1',
		PS2M_CLK => '1',
		PS2M_DAT => '1',

		VGA_VS => VGA_VS,
		VGA_HS => VGA_HS,
		VGA_B => VGA_B,
		VGA_G => VGA_G,
		VGA_R => VGA_R,
		
		JOY1_n => "111111",
		JOY2_n => "111111",
		
		AUDIO_L => AUDIO_L,
		AUDIO_R => AUDIO_R,

		SDRAM_BA => SDRAM_BA,
		SDRAM_CS_N => SDRAM_CS_N,
		SDRAM_RAS_N => SDRAM_RAS_N,
		SDRAM_CAS_N => SDRAM_CAS_N,
		SDRAM_WE_N => SDRAM_WE_N,
		SDRAM_DQM_n => SDRAM_DQM_n,
		SDRAM_CLK => SDRAM_CLK,
		--SDRAM_CKE :  OUT  STD_LOGIC;
		SDRAM_A => SDRAM_A,
		SDRAM_DQ => SDRAM_DQ,

		SD_DAT0 => '1',
		SD_CLK => open,
		SD_CMD => open,
		SD_DAT3 => open
	);

end rtl;

