library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_textio.all;

library std_developerskit ; -- used for to_string
--  use std_developerskit.std_iopak.all;

entity gtiamax_tb is
end;

architecture rtl of gtiamax_tb is

  constant CLK_BUS_PERIOD : time := 1 us / (1.79*32);

  constant CLK_FAST_BUS_PERIOD : time := 1 us / (1.79*2);

  signal reset_n : std_logic;
  signal clk_cart : std_logic;
  signal clk_fast : std_logic;

  signal clk_routed : std_logic;

	signal BUS_ADDR: std_logic_vector(15 downto 0);
	signal BUS_DATA: std_logic_vector(7 downto 0);
	signal BUS_PHI2: std_logic;
	signal BUS_CS_N: std_logic;
	signal BUS_RW: std_logic;

	-- 6502 bus other side
	signal enable_179_early : std_logic;
	signal cart_request : std_logic;
	signal pbi_addr_out : std_logic_vector(15 downto 0);
	signal cart_data_write : std_logic_vector(7 downto 0);
	signal pbi_write_enable : std_logic;
	signal CS_N : std_logic;
	signal cart_data_read : std_logic_vector(7 downto 0);
	signal cart_complete : std_logic;

	signal bus_data_in : std_logic_vector(7 downto 0);
	signal bus_data_out : std_logic_vector(7 downto 0);
	signal bus_data_oe : std_logic;
	signal bus_addr_out : std_logic_vector(15 downto 0);
	signal bus_addr_oe : std_logic;
	signal bus_write_n : std_logic;
	signal bus_control_oe : std_logic;
	signal bus_cs_n_out : std_logic;

	signal iox_sda : std_logic;
	signal iox_scl : std_logic;

begin
	p_clk_gen_b : process
	begin
	clk_cart <= '1';
	wait for CLK_BUS_PERIOD/2;
	clk_cart <= '0';
	wait for CLK_BUS_PERIOD - (CLK_BUS_PERIOD/2 );
	end process;

	p_clk_gen_c : process
	begin
	clk_fast <= '1';
	wait for 3*CLK_FAST_BUS_PERIOD/4;
	clk_fast <= '0';
	wait for CLK_FAST_BUS_PERIOD - (3*CLK_FAST_BUS_PERIOD/4 );
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

	wait for 6000ns;

	wait until enable_179_early'event and enable_179_early = '1';
	cart_request <= '1';
	pbi_addr_out <= x"D000";
	cart_data_write <= x"fe";
	pbi_write_enable <= '1';

	wait until enable_179_early'event and enable_179_early = '1';
	cart_request <= '1';
	pbi_write_enable <= '0';

	wait until enable_179_early'event and enable_179_early = '1';
	pbi_addr_out <= x"D001";

	wait until enable_179_early'event and enable_179_early = '1';
	--cart_data_write <= x"ec";
	cart_data_write <= x"ef";
	pbi_write_enable <= '1';

	wait until enable_179_early'event and enable_179_early = '1';
	cart_request <= '1';
	pbi_addr_out <= x"D008";
	cart_data_write <= x"40";
	pbi_write_enable <= '1';

	wait until enable_179_early'event and enable_179_early = '1';
	pbi_write_enable <= '0';

	wait until enable_179_early'event and enable_179_early = '1';
	cart_request <= '1';
	pbi_addr_out <= x"D00a";

	wait until enable_179_early'event and enable_179_early = '1';
	wait until enable_179_early'event and enable_179_early = '1';
	wait until enable_179_early'event and enable_179_early = '1';
	wait until enable_179_early'event and enable_179_early = '1';
	wait until enable_179_early'event and enable_179_early = '1';
	wait until enable_179_early'event and enable_179_early = '1';
	wait until enable_179_early'event and enable_179_early = '1';
	wait until enable_179_early'event and enable_179_early = '1';
	wait until enable_179_early'event and enable_179_early = '1';

	wait until enable_179_early'event and enable_179_early = '1';
	cart_request <= '0';

	wait until enable_179_early'event and enable_179_early = '1';
	cart_request <= '1';
	pbi_addr_out <= x"D00f";
	cart_data_write <= x"03";
	pbi_write_enable <= '1';

	wait until enable_179_early'event and enable_179_early = '1';
	cart_request <= '0';
	pbi_write_enable <= '0';

	wait for 100000000us;

	end process;

	thebigone: entity work.gtiamax
	port map
	(
		PHI2 => BUS_PHI2,
		CLK_OUT => CLK_ROUTED,
		CLK_SLOW => CLK_ROUTED,


		A => BUS_ADDR(4 downto 0),
		D => BUS_DATA,
		CS_N => BUS_CS_N,
		W_N => BUS_RW,


		S => open,
		T => "1010",

		AN => "000",
		HALT_N =>'1',

		OSC => clk_fast,
		FO0 => open,
		PAL => '0',

		CAD3 => '0',

		CSYNC => open,
		COLOR => open,
		LUM => open

	);

	bus_adaptor : ENTITY work.timing6502
	GENERIC MAP
	(
		CYCLE_LENGTH => 32,
		CONTROl_BITS => 1
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
		CONTROL_N_IN(0) => CS_N,
	
		DATA_OUT => cart_data_read,
		COMPLETE => cart_complete,
	
		-- 6502 side
		BUS_DATA_IN => BUS_DATA,
		
		BUS_PHI1 => open,
		BUS_PHI2 => BUS_PHI2,
		BUS_SUBCYCLE => open,
		BUS_ADDR_OUT => bus_addr_out,
		BUS_ADDR_OE => bus_addr_oe,
		BUS_DATA_OUT => bus_data_out,
		BUS_DATA_OE => bus_data_oe,
		BUS_WRITE_N => BUS_RW,
		BUS_CONTROL_OE => BUS_CONTROL_OE,
		BUS_CONTROL_N(0) => BUS_CS_N_OUT
	);
	BUS_ADDR <= bus_addr_out(15 downto 0) when bus_addr_oe='1' else (others=>'Z');
	BUS_DATA <= bus_data_out when bus_data_oe='1' else (others=>'Z');
	CS_N <= '0' when pbi_addr_out(15 downto 8)= x"D0" else '1';
	BUS_CS_N <= BUS_CS_N_OUT when BUS_CONTROL_OE='1' else 'Z';

	i2cslave : entity work.I2C_slave
	generic map (
		SLAVE_ADDR => "0100000"
	)
	port map (
		scl => iox_scl,
		sda => iox_sda,
		clk => clk_routed,
		rst => not(reset_n),

		read_req => open,
		data_to_master => x"5a",
		data_valid => '1',
		data_from_master => open
	);

	iox_scl <= 'H';
	iox_sda <= 'H';

end rtl;

