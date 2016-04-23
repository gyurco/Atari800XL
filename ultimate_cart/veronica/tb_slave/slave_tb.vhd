library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_textio.all;

library std_developerskit ; -- used for to_string
--  use std_developerskit.std_iopak.all;

entity slave_tb is
end;

architecture rtl of slave_tb is

  constant CLK_FAST_PERIOD : time := 1 us / (14*7);
  constant CLK_PERIOD : time := 1 us / (14);
  constant CLK_CART_PERIOD : time := 1 us / (1.79*32);

  signal reset_n : std_logic;
  signal clk7x : std_logic;
  signal clk : std_logic;
  signal clk_cart : std_logic;

	signal EXT_SRAM_ADDR: std_logic_vector(19 downto 0);
	signal EXT_SRAM_DATA: std_logic_vector(7 downto 0);
	signal EXT_SRAM_CE: std_logic;
	signal EXT_SRAM_OE: std_logic;
	signal EXT_SRAM_WE: std_logic;

	signal CART_ADDR: std_logic_vector(12 downto 0);
	signal CART_DATA: std_logic_vector(7 downto 0);
	signal CART_RD5: std_logic;
	signal CART_RD4: std_logic;
	signal CART_S5: std_logic;
	signal CART_S4: std_logic;
	signal CART_PHI2: std_logic;
	signal CART_CTL: std_logic;
	signal CART_RW: std_logic;

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

	-- 6502 bus other side
	signal enable_179_early : std_logic;
	signal cart_request : std_logic;
	signal pbi_addr_out : std_logic_vector(15 downto 0);
	signal cart_data_write : std_logic_vector(7 downto 0);
	signal pbi_write_enable : std_logic;
	signal s4_n : std_logic;
	signal s5_n : std_logic;
	signal cctl_n : std_logic;
	signal cart_data_read : std_logic_vector(7 downto 0);
	signal cart_complete : std_logic;

	signal bus_data_in : std_logic_vector(7 downto 0);
	signal bus_data_out : std_logic_vector(7 downto 0);
	signal bus_data_oe : std_logic;
	signal bus_addr_out : std_logic_vector(15 downto 0);
	signal bus_addr_oe : std_logic;
	signal bus_write_n : std_logic;
	signal bus_s4_n : std_logic;
	signal bus_s5_n : std_logic;
	signal bus_cctl_n : std_logic;
	signal bus_control_oe : std_logic;

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
	clk_cart <= '1';
	wait for CLK_CART_PERIOD/2;
	clk_cart <= '0';
	wait for CLK_CART_PERIOD - (CLK_CART_PERIOD/2 );
	end process;

	p_clk_gen_c : process
	begin
	clk7x <= '1';
	wait for CLK_FAST_PERIOD/2;
	clk7x <= '0';
	wait for CLK_FAST_PERIOD - (CLK_FAST_PERIOD/2 );
	end process;

	reset_n <= '0', '1' after 1000ns;

	process_enable : process
	begin
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '1'; -- HERE!
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';


	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';


	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';


	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';

	end process;

	process_setup_sram : process
	begin
	cart_request <= '0';
	pbi_addr_out <= (others=>'0');
	cart_data_write <= (others=>'0');
	pbi_write_enable <= '0';
	s4_n <= '1';
	s5_n <= '1';
	cctl_n <= '1';

	wait for 3000ns;

	wait until enable_179_early'event and enable_179_early = '1';
	cart_request <= '1';
	pbi_addr_out <= x"D402";
	cart_data_write <= x"65";
	pbi_write_enable <= '1';
	s4_n <= '0';

	wait until enable_179_early'event and enable_179_early = '1';
	cart_request <= '1';
	pbi_addr_out <= x"D513";
	cart_data_write <= x"56";
	pbi_write_enable <= '1';
	s5_n <= '0';
	s4_n <= '1';

	wait until enable_179_early'event and enable_179_early = '1';
	cart_request <= '1';
	pbi_addr_out <= x"D402";
	cart_data_write <= x"65";
	pbi_write_enable <= '1';

	wait until enable_179_early'event and enable_179_early = '1';
	cart_request <= '0';

	wait for 100000000us;

	end process;

	glue3: entity work.slave_timing_6502
	port map
	(
		clk => clk,
		clk7x => clk7x,
		reset_n => reset_n,
		phi2 => CART_PHI2,
		bus_addr => CART_ADDR,
		bus_data => CART_DATA,
		bus_ctl_n => CART_CTL,
		bus_rw_n => CART_RW,
		bus_s4_n => CART_S4,
		bus_s5_n => CART_S5,
		
		bus_data_out => cart_bus_data_out,
		bus_drive => cart_bus_drive,
		
		s4_n => atari_s4,
		s5_n => atari_s5,
		ctl_n => atari_ctl,
		addr_in => atari_address,
		data_in => atari_write_data,
		data_out => atari_read_data,
		rw_n => atari_w_n,
		bus_request => atari_bus_request
	);
	CART_DATA <= cart_bus_data_out when cart_bus_drive='1' else (others=>'Z');


	atari_read_data <= x"12" when atari_bus_request='1' else (others=>'U');
	bus_adaptor : ENTITY work.timing6502
	GENERIC MAP
	(
		CYCLE_LENGTH => 32,
		CONTROl_BITS => 3
	)
	PORT MAP
	( 
		CLK => clk_cart,
		RESET_N => reset_n,
	
		-- FPGA side
		ENABLE_179_EARLY =>enable_179_early,
	
		REQUEST => cart_request,
		ADDR_IN => pbi_addr_out,
		DATA_IN => cart_data_write,
		WRITE_IN => pbi_write_enable,
		CONTROL_N_IN => s4_n&s5_n&cctl_n,
	
		DATA_OUT => cart_data_read,
		COMPLETE => cart_complete,
	
		-- 6502 side
		BUS_DATA_IN => CART_DATA,
		
		BUS_PHI1 => open,
		BUS_PHI2 => CART_PHI2,
		BUS_SUBCYCLE => open,
		BUS_ADDR_OUT => bus_addr_out,
		BUS_ADDR_OE => bus_addr_oe,
		BUS_DATA_OUT => bus_data_out,
		BUS_DATA_OE => bus_data_oe,
		BUS_WRITE_N => CART_RW,
		BUS_CONTROL_N(2) => bus_s4_n,
		BUS_CONTROL_N(1) => bus_s5_n,
		BUS_CONTROL_N(0) => bus_cctl_n,
		BUS_CONTROL_OE => bus_control_oe
	);
	CART_ADDR <= bus_addr_out when bus_addr_oe='1' else (others=>'Z');
	CART_DATA <= bus_data_out when bus_data_oe='1' else (others=>'Z');
	CART_S4 <= bus_s4_n when bus_control_oe='1' else 'Z';
	CART_S5 <= bus_s5_n when bus_control_oe='1' else 'Z';
	CART_CTL <= bus_cctl_n when bus_control_oe='1' else 'Z';

end rtl;

