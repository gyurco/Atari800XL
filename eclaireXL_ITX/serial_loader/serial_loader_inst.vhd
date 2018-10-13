	component serial_loader is
		port (
			noe_in : in std_logic := 'X'  -- noe
		);
	end component serial_loader;

	u0 : component serial_loader
		port map (
			noe_in => CONNECTED_TO_noe_in  -- noe_in.noe
		);

