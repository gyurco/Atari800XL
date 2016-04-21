LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
use IEEE.STD_LOGIC_MISC.all;

ENTITY slave_timing_6502 IS
	PORT (
				CLK7x: in std_logic;
				RESET_N: in std_logic;
				
				PHI2 : in std_logic; -- async to our clk7x:-(
				bus_addr : in std_logic_vector(12 downto 0);
				bus_data : in std_logic_vector(7 downto 0);
				bus_ctl_n : in std_logic;
				bus_rw_n : in std_logic;
				bus_s4_n : in std_logic;
				bus_s5_n : in std_logic;
	
				bus_data_out : out std_logic_vector(7 downto 0);
				bus_drive : out std_logic;

				ADDR_IN: out std_logic_vector(12 downto 0);
				DATA_IN: out std_logic_vector(7 downto 0);
				DATA_OUT: in std_logic_vector(7 downto 0);
				RW_N: out std_logic;
				INTERNAL_MEMORY_REQUEST: out std_logic;
				S4_N : out std_logic;
				s5_N : out std_logic;
				ctl_n : out std_logic
			);
END slave_timing_6502;

ARCHITECTURE vhdl OF slave_timing_6502 IS

	signal PHI2_sync : std_logic;
	
	signal phi_edge_prev_next : std_logic;
	signal phi_edge_prev_reg: std_logic;	

	signal delay_next : std_logic_vector(30 downto 0);	
	signal delay_reg : std_logic_vector(30 downto 0);
	
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
	constant state_phi : std_logic_vector(2 downto 0) := "000";
	constant state_write_request : std_logic_vector(2 downto 0) := "001";
	constant state_read_request : std_logic_vector(2 downto 0) := "010";
	constant state_read_output_start : std_logic_vector(2 downto 0) := "011";
	constant state_read_output_end : std_logic_vector(2 downto 0) := "100";
	
begin
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

			state_reg <= state_phi;
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
	
	addr_in <= bus_addr_in_reg;
	data_in <= bus_data_in_reg;
	rw_n <= bus_rw_n_reg;	
	s4_n <= bus_s4_n_reg;
	s5_n <= bus_s5_n_reg;
	ctl_n <= bus_ctl_n_reg;

	process(data_out, phi2_sync, phi_edge_prev_reg, delay_reg, bus_data_out_reg, 
		bus_rw_n_reg,bus_addr_in_reg,bus_data_in_reg,
		bus_s4_n_reg,bus_s5_n_reg,bus_ctl_n_reg,
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
		delay_next <= delay_reg(29 downto 0)&'0';
		bus_data_out_next <= bus_data_out_reg;
		bus_drive_next <= bus_drive_reg;


		-- LLLLLLLHHHHHHH
		-- XXAAAAAAAAAAAA
		-- XXXXXXXXXXDDDD
		state_next <= state_reg;
		case (state_reg) is
			when state_phi =>
				if (phi2_sync = '1' and phi_edge_prev_reg='0') then -- falling edge (3 cycles delayed)
					delay_next(0) <= '1';

					-- snap control signals, should be stable by now
					bus_addr_in_next <= bus_addr;
					bus_rw_n_next <= bus_rw_n;
					bus_s4_n_next <= bus_s4_n;
					bus_s5_n_next <= bus_s5_n;
					bus_ctl_n_next <= bus_ctl_n;

					if (bus_rw_n='1') then -- read
						state_next <= state_read_request;
					else
						state_next <= state_write_request;
					end if;
				end if;
			when state_write_request =>
				if (delay_reg(19)='1') then -- n+4 cycles
					bus_data_in_next <= bus_data;
				end if;
				if (delay_reg(20)='1') then -- n+4 cycles
					internal_memory_request <= '1';
					state_next <= state_phi;
				end if;
			when state_read_request =>
				if (delay_reg(0)='1') then -- n+4 cycles
					state_next <= state_read_output_start;
					internal_memory_request <= '1';
				end if;
			when state_read_output_start =>
				if (delay_reg(16)='1') then -- n+4 cycles
					bus_data_out_next <= data_out;
					bus_drive_next <= '1';
					state_next <= state_read_output_start;
				end if;
			when state_read_output_end =>
				if (delay_reg(30)='1') then -- n+4 cycles
					bus_drive_next <= '0';
					state_next <= state_phi;
				end if;
			when others =>
		end case;
		
	end process;
	
	bus_data_out <= bus_data_out_reg;
	bus_drive <= bus_drive_reg;
				 
end vhdl;
