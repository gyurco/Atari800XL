LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
use IEEE.STD_LOGIC_MISC.all;

ENTITY slave_timing_6502 IS
	PORT (
				CLK: in std_logic;
				CLK7x: in std_logic;
				RESET_N: in std_logic;
				
				-- input from the cart port
				PHI2 : in std_logic; -- async to our clk7x:-(
				bus_addr : in std_logic_vector(12 downto 0);
				bus_data : in std_logic_vector(7 downto 0);
				bus_ctl_n : in std_logic;
				bus_rw_n : in std_logic;
				bus_s4_n : in std_logic;
				bus_s5_n : in std_logic;
	
				-- output to the cart port
				bus_data_out : out std_logic_vector(7 downto 0);
				bus_drive : out std_logic;

				-- request for a memory bus cycle (read or write)
				BUS_REQUEST: out std_logic;
				ADDR_IN: out std_logic_vector(12 downto 0);
				DATA_IN: out std_logic_vector(7 downto 0);
				RW_N: out std_logic;
				S4_N : out std_logic;
				s5_N : out std_logic;
				ctl_n : out std_logic;

				DATA_OUT: in std_logic_vector(7 downto 0) -- read_data
			);
END slave_timing_6502;

ARCHITECTURE vhdl OF slave_timing_6502 IS

	signal PHI2_sync : std_logic;
	
	signal phi_edge_prev_next : std_logic;
	signal phi_edge_prev_reg: std_logic;	

	signal delay_next : std_logic_vector(60 downto 0);	
	signal delay_reg : std_logic_vector(60 downto 0);
	
	signal bus_data_out_next : std_logic_vector(7 downto 0);	
	signal bus_data_out_reg : std_logic_vector(7 downto 0);

	signal bus_drive_next : std_logic;
	signal bus_drive_reg : std_logic;

	signal bus_data_in_next : std_logic_vector(7 downto 0);	
	signal bus_data_in_reg : std_logic_vector(7 downto 0);
	signal bus_addr_in_next : std_logic_vector(12 downto 0);	
	signal bus_addr_in_reg : std_logic_vector(12 downto 0);
	signal bus_rw_n_next : std_logic;
	signal bus_rw_n_reg : std_logic;
	signal bus_s4_n_next : std_logic;
	signal bus_s4_n_reg : std_logic;
	signal bus_s5_n_next : std_logic;
	signal bus_s5_n_reg : std_logic;
	signal bus_ctl_n_next : std_logic;
	signal bus_ctl_n_reg : std_logic;

	signal state_reg : std_logic_vector(2 downto 0);
	signal state_next : std_logic_vector(2 downto 0);
	constant state_wait_addrctl : std_logic_vector(2 downto 0) := "001";
	constant state_write_request : std_logic_vector(2 downto 0) := "010";
	constant state_read_output_start : std_logic_vector(2 downto 0) := "011";
	constant state_read_output_end : std_logic_vector(2 downto 0) := "100";

	signal internal_memory_request : std_logic;
	signal registered_read_data : std_logic_vector(7 downto 0);

	-- slow half - for output

	signal slow_bus_data_in_reg : std_logic_vector(7 downto 0);
	signal slow_bus_addr_in_reg : std_logic_vector(12 downto 0);
	signal slow_bus_rw_n_reg : std_logic;
	signal slow_bus_s4_n_reg : std_logic;
	signal slow_bus_s5_n_reg : std_logic;
	signal slow_bus_ctl_n_reg : std_logic;
	
begin
	-- Fast half, for accurate sampling of the 6502 bus - which is quirky on Atari - e.g. phi2 is often not in time with the data lines on writes!!

	process(clk7x,reset_n)
	begin
		if (reset_n='0') then
			phi_edge_prev_reg <= '1';
			delay_reg <= (others=>'0');
			bus_data_out_reg <= (others=>'0');
			bus_drive_reg <= '0';

			bus_rw_n_reg <= '1';
			bus_data_in_reg <= (others=>'0');
			bus_addr_in_reg <= (others=>'0');
			bus_s4_n_reg <= '1';
			bus_s5_n_reg <= '1';
			bus_ctl_n_reg <= '1';

			state_reg <= state_wait_addrctl;
		elsif (clk7x'event and clk7x='1') then
			phi_edge_prev_reg <= phi_edge_prev_next;
			delay_reg <= delay_next;
			bus_data_out_reg <= bus_data_out_next;
			bus_drive_reg <= bus_drive_next;

			bus_rw_n_reg <= bus_rw_n_next;
			bus_data_in_reg <= bus_data_in_next;
			bus_addr_in_reg <= bus_addr_in_next;
			bus_s4_n_reg <= bus_s4_n_next;
			bus_s5_n_reg <= bus_s5_n_next;
			bus_ctl_n_reg <= bus_ctl_n_next;

			state_reg <= state_next;
		end if;
	end process;
	
	synchronizer_phi : entity work.synchronizer
				 port map (clk=>clk7x, raw=>PHI2, sync=>PHI2_SYNC);

	phi_edge_prev_next <= phi2_sync;

	process(registered_read_data, phi2_sync, phi_edge_prev_reg, delay_reg, 
		bus_drive_reg,bus_data_out_reg, 
		bus_rw_n_reg,bus_addr_in_reg,bus_data_in_reg,
		bus_s4_n_reg,bus_s5_n_reg,bus_ctl_n_reg,
		bus_rw_n,
		bus_s4_n,bus_s5_n,bus_ctl_n,
		bus_data,bus_addr,
		state_reg)
	begin
		-- maintain snap (only read bus when safe!)
		bus_addr_in_next <= bus_addr_in_reg;
		bus_data_in_next <= bus_data_in_reg;
		bus_rw_n_next <= bus_rw_n_reg;
		bus_s4_n_next <= bus_s4_n_reg;
		bus_s5_n_next <= bus_s5_n_reg;
		bus_ctl_n_next <= bus_ctl_n_reg;

		internal_memory_request <= '0';
		delay_next <= delay_reg(59 downto 0)&(not(phi2_sync) and phi_edge_prev_reg);
		bus_data_out_next <= bus_data_out_reg;
		bus_drive_next <= bus_drive_reg;


		-- LLLLLLLHHHHHHH
		-- XXAAAAAAAAAAAA
		-- XXXXXXXXXXDDDD
		state_next <= state_reg;
		case (state_reg) is
			when state_wait_addrctl =>
				if ((not(bus_s4_n and bus_s5_n and bus_ctl_n) and delay_reg(17))='1') then -- n+4 cycles
					-- snap control signals, should be stable by now
					bus_addr_in_next <= bus_addr;
					bus_rw_n_next <= bus_rw_n;
					bus_s4_n_next <= bus_s4_n;
					bus_s5_n_next <= bus_s5_n;
					bus_ctl_n_next <= bus_ctl_n;

					if (bus_rw_n='1') then -- read
						state_next <= state_read_output_start;
						internal_memory_request <= '1';
					else
						state_next <= state_write_request;
					end if;
				end if;
			when state_write_request =>
				if (delay_reg(47)='1') then -- n+4 cycles
					bus_data_in_next <= bus_data;
				end if;
				if (delay_reg(48)='1') then -- n+4 cycles
					internal_memory_request <= '1';
					state_next <= state_wait_addrctl;
				end if;
			when state_read_output_start =>
				if (delay_reg(38)='1') then -- n+4 cycles
					bus_data_out_next <= registered_read_data;
					bus_drive_next <= '1';
					state_next <= state_read_output_end;
				end if;
			when state_read_output_end =>
				if (delay_reg(56)='1') then -- n+4 cycles
					bus_drive_next <= '0';
					state_next <= state_wait_addrctl;
				end if;
			when others =>
		end case;
		
	end process;

		-- Fast outputs
	bus_data_out <= bus_data_out_reg;
	bus_drive <= bus_drive_reg;

	-- Slow half

	process(clk,reset_n)
	begin
		if (reset_n='0') then
			slow_bus_addr_in_reg <= (others=>'0');
			slow_bus_data_in_reg <= (others=>'0');
			slow_bus_rw_n_reg <= '1';
			slow_bus_s4_n_reg <= '1';
			slow_bus_s5_n_reg <= '1';
			slow_bus_ctl_n_reg <= '1';
		elsif (clk'event and clk='1')  then
			slow_bus_addr_in_reg <= bus_addr_in_reg;
			slow_bus_data_in_reg <= bus_data_in_reg;
			slow_bus_rw_n_reg <= bus_rw_n_reg;
			slow_bus_s4_n_reg <= bus_s4_n_reg;
			slow_bus_s5_n_reg <= bus_s5_n_reg;
			slow_bus_ctl_n_reg <= bus_ctl_n_reg;
		end if;
	end process;

	glue3a: entity work.memory_timing_bridge
	port map
	(
		clk => clk,
		clk7x => clk7x,
		reset_n => reset_n,

		fast_memory_request => internal_memory_request,
		registered_read_data => registered_read_data,

		memory_request => bus_request,
		read_data => data_out
	);

	-- slow outputs
	addr_in <= slow_bus_addr_in_reg;
	data_in <= slow_bus_data_in_reg;
	rw_n <= slow_bus_rw_n_reg;	
	s4_n <= slow_bus_s4_n_reg;
	s5_n <= slow_bus_s5_n_reg;
	ctl_n <= slow_bus_ctl_n_reg;

end vhdl;
