	component sfl is
		port (
			noe_in              : in  std_logic                    := 'X';             -- noe
			dclk_in             : in  std_logic                    := 'X';             -- dclkin
			ncso_in             : in  std_logic                    := 'X';             -- scein
			data_in             : in  std_logic_vector(3 downto 0) := (others => 'X'); -- data_in
			data_oe             : in  std_logic_vector(3 downto 0) := (others => 'X'); -- data_oe
			asmi_access_granted : in  std_logic                    := 'X';             -- asmi_access_granted
			data_out            : out std_logic_vector(3 downto 0);                    -- data_out
			asmi_access_request : out std_logic                                        -- asmi_access_request
		);
	end component sfl;

	u0 : component sfl
		port map (
			noe_in              => CONNECTED_TO_noe_in,              --              noe_in.noe
			dclk_in             => CONNECTED_TO_dclk_in,             --             dclk_in.dclkin
			ncso_in             => CONNECTED_TO_ncso_in,             --             ncso_in.scein
			data_in             => CONNECTED_TO_data_in,             --             data_in.data_in
			data_oe             => CONNECTED_TO_data_oe,             --             data_oe.data_oe
			asmi_access_granted => CONNECTED_TO_asmi_access_granted, -- asmi_access_granted.asmi_access_granted
			data_out            => CONNECTED_TO_data_out,            --            data_out.data_out
			asmi_access_request => CONNECTED_TO_asmi_access_request  -- asmi_access_request.asmi_access_request
		);

