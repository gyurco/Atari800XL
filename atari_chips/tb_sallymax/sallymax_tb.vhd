library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_textio.all;

library std_developerskit ; -- used for to_string
--  use std_developerskit.std_iopak.all;

entity sallymax_tb is
end;

architecture rtl of sallymax_tb is

  constant CLK_BUS_PERIOD : time := 1 us / (1.79);
  constant CLK_FAST_PERIOD : time := 1 us / (1.79*32);

  signal reset_n : std_logic;
  signal clk_phi0 : std_logic;
  signal clk_fast : std_logic;

  signal clk_routed : std_logic;

  signal bus_addr : std_logic_vector(15 downto 0);
  signal bus_data : std_logic_vector(7 downto 0);
  signal bus_data_out : std_logic_vector(7 downto 0);
  signal bus_drive : std_logic;
  signal bus_rw : std_logic;

  signal bus_phi1 : std_logic;
  signal bus_phi2 : std_logic;

  signal slave_request : std_logic;
  signal slave_addr : std_logic_vector(15 downto 0);
  signal slave_data_in : std_logic_vector(7 downto 0);
  signal slave_data_out : std_logic_vector(7 downto 0);
  signal slave_rw_n : std_logic;
  signal slave_cs : std_logic;

begin
	p_clk_gen_b : process
	begin
	clk_phi0 <= '1';
	wait for CLK_BUS_PERIOD/2;
	clk_phi0 <= '0';
	wait for CLK_BUS_PERIOD - (CLK_BUS_PERIOD/2 );
	end process;

	p_clk_gen_f : process
	begin
	clk_fast <= '1';
	wait for CLK_FAST_PERIOD/2;
	clk_fast <= '0';
	wait for CLK_FAST_PERIOD - (CLK_FAST_PERIOD/2 );
	end process;

	reset_n <= '0', '1' after 1000ns;

	thebigone: entity work.sallymax
	port map
	(
		PHI0 => clk_phi0,
		RST_N => reset_n,
		CLK_OUT => CLK_ROUTED,
		CLK_SLOW => CLK_ROUTED,


		A => BUS_ADDR,
		D => BUS_DATA,
		W_N => BUS_RW,

		RDY => '1',
		HALT_N => '1',
		NMI_N => '1',
		IRQ_N => '1',
		S0 => '1',

		phi2 => bus_phi2,
		phi1 => bus_phi1
	);

	busadapt : entity work.slave_timing_6502
	port map
	(
		CLK => clk_fast,
		RESET_N => reset_n,
				
		PHI2 => bus_phi2,
		bus_addr => bus_addr,
		bus_data => bus_data,
		bus_cs => '1',
		bus_rw_n => bus_rw,

		bus_data_out => bus_data_out,
		bus_drive => bus_drive,

		BUS_REQUEST => slave_request,
		ADDR_IN => slave_addr, 
		DATA_IN => slave_data_in,
		RW_N => slave_rw_n,
		CS => slave_cs,

		ENABLE_CYCLE => open,

		DATA_OUT => slave_data_out
	);

	bus_data <= bus_data_out when bus_drive='1' else (others=>'Z');

	process
	begin
		wait until reset_n='1';

		wait until slave_request='1';
		slave_data_out <= x"00";
		wait until slave_request='0';

		wait until slave_request='1';
		slave_data_out <= x"e0";
		wait until slave_request='0';

		wait until slave_request='1';
		slave_data_out <= x"ea";
		wait until slave_request='0';

		wait until slave_request='1';
		slave_data_out <= x"ea";
		wait until slave_request='0';
		wait until slave_request='1';
		slave_data_out <= x"ea";
		wait until slave_request='0';
		wait until slave_request='1';
		slave_data_out <= x"ea";
		wait until slave_request='0';
		wait until slave_request='1';
		slave_data_out <= x"ea";
		wait until slave_request='0';
		wait until slave_request='1';
		slave_data_out <= x"ea";
		wait until slave_request='0';
		wait until slave_request='1';
		slave_data_out <= x"ea";
		wait until slave_request='0';
		wait until slave_request='1';
		slave_data_out <= x"ea";
		wait until slave_request='0';

		wait until slave_request='1';
		slave_data_out <= x"ea";
		wait until slave_request='0';
		
	end process;

end rtl;

