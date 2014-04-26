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

  constant CLK_A_PERIOD : time := 1 us / (1.79*16);

  signal CLK_A : std_logic;

  constant CLK_B_PERIOD : time := 3 us / (1.79*16);

  signal CLK_B : std_logic;

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
	p_clk_gen_a : process
	begin
	clk_a <= '1';
	wait for CLK_A_PERIOD/2;
	clk_a <= '0';
	wait for CLK_A_PERIOD - (CLK_A_PERIOD/2 );
	end process;

	p_clk_gen_b : process
	begin
	clk_b <= '1';
	wait for CLK_B_PERIOD/2;
	clk_b <= '0';
	wait for CLK_B_PERIOD - (CLK_B_PERIOD/2 );
	end process;

	reset_n <= '0', '1' after 1000ns;

	reset <= not(reset_n);

atari : ENTITY work.atari800core_mcc 
	port map
	(
		CLK => clk_b,
		CLK_SDRAM =>clk_a,
		PLL_LOCKED=>reset_n,

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

