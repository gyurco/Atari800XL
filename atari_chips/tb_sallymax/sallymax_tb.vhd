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

  constant CLK_BUS_PERIOD : time := 1 us / (1.79*32);

  signal reset_n : std_logic;
  signal clk_phi0 : std_logic;

  signal clk_routed : std_logic;

  signal bus_addr : std_logic_vector(15 downto 0);
  signal bus_data : std_logic_vector(7 downto 0);
  signal bus_rw : std_logic;

begin
	p_clk_gen_b : process
	begin
	clk_phi0 <= '1';
	wait for CLK_BUS_PERIOD/2;
	clk_phi0 <= '0';
	wait for CLK_BUS_PERIOD - (CLK_BUS_PERIOD/2 );
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
		S0 => '1'
	);

end rtl;

