library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_textio.all;

library std_developerskit ; -- used for to_string
--  use std_developerskit.std_iopak.all;

entity sram_tb is
end;

architecture rtl of sram_tb is

  constant CLK_PERIOD : time := 1 us / (14);
  constant CLK_FAST_PERIOD : time := 1 us / (14*7);

  signal reset_n : std_logic;
  signal clk : std_logic;
  signal clk_fast : std_logic;

	signal EXT_SRAM_ADDR: std_logic_vector(19 downto 0);
	signal EXT_SRAM_DATA: std_logic_vector(7 downto 0);
	signal EXT_SRAM_CE: std_logic;
	signal EXT_SRAM_OE: std_logic;
	signal EXT_SRAM_WE: std_logic;

	-- 65816 bus
	signal veronica_address : std_logic_vector(23 downto 0);
	signal veronica_read_data : std_logic_vector(7 downto 0);
	signal veronica_write_data : std_logic_vector(7 downto 0);
	signal veronica_w_n : std_logic;
	signal veronica_config_w_n : std_logic;
	
	-- 6502 bus
	signal atari_bus_request : std_logic;	
	signal atari_address : std_logic_vector(12 downto 0);
	signal atari_data_bus : std_logic_vector(7 downto 0);
	signal atari_read_data : std_logic_vector(7 downto 0);
	signal atari_write_data : std_logic_vector(7 downto 0);
	signal atari_w_n : std_logic;
	signal atari_config_w_n : std_logic;
	signal atari_s4 : std_logic;
	signal atari_s5 : std_logic;
	signal atari_ctl : std_logic;
	
	-- address decode
	signal veronica_config_select : std_logic;	
	signal veronica_sram_select : std_logic;
	signal veronica_sram_address: std_logic_vector(16 downto 0);	
	signal atari_config_select : std_logic;
	signal atari_sram_select : std_logic;	
	signal atari_sram_address: std_logic_vector(16 downto 0);

	-- veronica config
	signal veronica_window_address : std_logic;
	signal veronica_bank_half_select : std_logic;	
	signal veronica_config_data : std_logic_vector(7 downto 0);
	
	-- atari config
	signal atari_banka_enable : std_logic;
	signal atari_bank8_enable : std_logic;
	signal atari_bank_half_select : std_logic;
	signal atari_config_data : std_logic_vector(7 downto 0);

	-- common config
	signal common_sem : std_logic;	
	signal common_bank_select : std_logic;
	
	-- cart driving
	signal cart_bus_data_out : std_logic_vector(7 downto 0);
	signal cart_bus_drive : std_logic;
	
	-- sram driving
	signal sram_write_data : std_logic_vector(7 downto 0);
	signal sram_drive_data : std_logic;
	signal sram_read_data : std_logic_vector(7 downto 0);

begin
	p_clk_gen_a : process
	begin
	clk <= '1';
	wait for CLK_PERIOD/2;
	clk <= '0';
	wait for CLK_PERIOD - (CLK_PERIOD/2 );
	end process;

	p_clk_gen_b : process
	begin
	clk_fast <= '1';
	wait for CLK_FAST_PERIOD/2;
	clk_fast <= '0';
	wait for CLK_FAST_PERIOD - (CLK_FAST_PERIOD/2 );
	end process;

	reset_n <= '0', '1' after 1000ns;

	process_setup_sram : process
	begin
	atari_bus_request <= '0';
	atari_sram_select <= '1';
	atari_sram_address <= (others=>'0');
	atari_w_n <= '1';
	atari_write_data <= (others=>'0');
	
	veronica_sram_address <= (others=>'0');
	veronica_sram_select <= '1';
	veronica_w_n <= '1';
	veronica_write_data <= (others=>'0');

	wait for 1100ns;

	wait until clk'event and clk = '1';
	atari_bus_request <= '1';
	atari_w_n <= '0';
	atari_sram_address<= '0'&x"D402";
	atari_write_data <= x"56";

	wait until clk'event and clk = '1';
	atari_w_n <= '0';
	atari_sram_address<= '0'&x"C313";
	atari_write_data <= x"65";

	wait until clk'event and clk = '1';
	atari_w_n <= '0';
	atari_sram_address<= '0'&x"D402";
	atari_write_data <= x"56";

	wait until clk'event and clk = '1';
	atari_bus_request <= '0';

	wait for 100000000us;

	end process;

	glue6: entity work.sram_mux
	port map
	(
		clk => clk,
		clk7x => clk_fast,
		reset_n => reset_n,
		
		sram_addr => EXT_SRAM_ADDR,
		sram_data_out => sram_write_data,
		sram_drive_data => sram_drive_data,
		sram_we_n => EXT_SRAM_WE,

		atari_bus_request => atari_bus_request,
		atari_sram_select => atari_sram_select,
		atari_address => atari_sram_address,
		atari_w_n => atari_w_n,
		atari_write_data => atari_write_data,
		
		veronica_address => veronica_sram_address,
		veronica_sram_select => veronica_sram_select,
		veronica_w_n => veronica_w_n,
		veronica_write_data => veronica_write_data
	);

	EXT_SRAM_DATA <= sram_write_data when sram_drive_data='1' else (others=>'Z');
	EXT_SRAM_OE <= '0';
	sram_read_data <= EXT_SRAM_DATA;

end rtl;

