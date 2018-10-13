	component ddioclkctrl is
		port (
			inclk3x   : in  std_logic                    := 'X';             -- inclk3x
			inclk2x   : in  std_logic                    := 'X';             -- inclk2x
			inclk1x   : in  std_logic                    := 'X';             -- inclk1x
			inclk0x   : in  std_logic                    := 'X';             -- inclk0x
			clkselect : in  std_logic_vector(1 downto 0) := (others => 'X'); -- clkselect
			ena       : in  std_logic                    := 'X';             -- ena
			outclk    : out std_logic                                        -- outclk
		);
	end component ddioclkctrl;

	u0 : component ddioclkctrl
		port map (
			inclk3x   => CONNECTED_TO_inclk3x,   --  altclkctrl_input.inclk3x
			inclk2x   => CONNECTED_TO_inclk2x,   --                  .inclk2x
			inclk1x   => CONNECTED_TO_inclk1x,   --                  .inclk1x
			inclk0x   => CONNECTED_TO_inclk0x,   --                  .inclk0x
			clkselect => CONNECTED_TO_clkselect, --                  .clkselect
			ena       => CONNECTED_TO_ena,       --                  .ena
			outclk    => CONNECTED_TO_outclk     -- altclkctrl_output.outclk
		);

