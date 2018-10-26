LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
use IEEE.STD_LOGIC_MISC.all;

ENTITY slave_timing_6502 IS
	PORT (
				CLK: in std_logic;
				RESET_N: in std_logic;
				
				-- input from the cart port
				PHI2 : in std_logic; -- async to our clk (ish):-(
				bus_addr : in std_logic_vector(4 downto 0);
				bus_data : in std_logic_vector(7 downto 0);
				bus_cs : in std_logic;
				bus_rw_n : in std_logic;
	
				-- output to the cart port
				bus_data_out : out std_logic_vector(7 downto 0);
				bus_drive : out std_logic;

				-- request for a memory bus cycle (read or write)
				BUS_REQUEST: out std_logic;
				ADDR_IN: out std_logic_vector(4 downto 0);
				DATA_IN: out std_logic_vector(7 downto 0);
				RW_N: out std_logic;
				CS : out std_logic;

				ENABLE_CYCLE : out std_logic;
				HALT_N : in std_logic;
				HALT_N_OUT : out std_logic;

				DATA_OUT: in std_logic_vector(7 downto 0) -- read_data
			);
END slave_timing_6502;

ARCHITECTURE vhdl OF slave_timing_6502 IS

	signal PHI2_sync : std_logic;
	
	signal phi_edge_prev_next : std_logic;
	signal phi_edge_prev_reg: std_logic;	

	signal halt_n_next : std_logic;
	signal halt_n_reg: std_logic;	

	signal delay_next : std_logic_vector(31 downto 0);	
	signal delay_reg : std_logic_vector(31 downto 0);
	
	signal bus_data_out_next : std_logic_vector(7 downto 0);	
	signal bus_data_out_reg : std_logic_vector(7 downto 0);

	signal bus_drive_next : std_logic;
	signal bus_drive_reg : std_logic;

	signal bus_data_in_next : std_logic_vector(7 downto 0);	
	signal bus_data_in_reg : std_logic_vector(7 downto 0);
	signal bus_addr_in_next : std_logic_vector(4 downto 0);	
	signal bus_addr_in_reg : std_logic_vector(4 downto 0);
	signal bus_rw_n_next : std_logic;
	signal bus_rw_n_reg : std_logic;
	signal bus_cs_next : std_logic;
	signal bus_cs_reg : std_logic;

	signal state_reg : std_logic_vector(2 downto 0);
	signal state_next : std_logic_vector(2 downto 0);
	constant state_wait_addrctl : std_logic_vector(2 downto 0) := "001";
	constant state_write_request : std_logic_vector(2 downto 0) := "010";
	constant state_read_output_start : std_logic_vector(2 downto 0) := "011";
	constant state_read_output_end : std_logic_vector(2 downto 0) := "100";
	constant state_read_output_fetch : std_logic_vector(2 downto 0) := "101";

	signal internal_memory_request : std_logic;
	signal registered_read_data_next : std_logic_vector(7 downto 0);
	signal registered_read_data_reg : std_logic_vector(7 downto 0);
begin
	-- Fast half, for accurate sampling of the 6502 bus - which is quirky on Atari - e.g. phi2 is often not in time with the data lines on writes!!

	process(clk,reset_n)
	begin
		if (reset_n='0') then
			phi_edge_prev_reg <= '1';
			delay_reg <= (others=>'0');
			bus_data_out_reg <= (others=>'0');
			bus_drive_reg <= '0';

			bus_cs_reg <= '1';
			bus_rw_n_reg <= '1';
			bus_data_in_reg <= (others=>'0');
			bus_addr_in_reg <= (others=>'0');

			registered_read_data_reg <= (others=>'0');

			state_reg <= state_wait_addrctl;

			halt_n_reg <= '1';
		elsif (clk'event and clk='1') then
			phi_edge_prev_reg <= phi_edge_prev_next;
			delay_reg <= delay_next;
			bus_data_out_reg <= bus_data_out_next;
			bus_drive_reg <= bus_drive_next;

			registered_read_data_reg <= registered_read_data_next;

			bus_cs_reg <= bus_cs_next;
			bus_rw_n_reg <= bus_rw_n_next;
			bus_data_in_reg <= bus_data_in_next;
			bus_addr_in_reg <= bus_addr_in_next;

			state_reg <= state_next;

			halt_n_reg <= halt_n_next;
		end if;
	end process;
	
	synchronizer_phi : entity work.synchronizer
				 port map (clk=>clk, raw=>PHI2, sync=>PHI2_SYNC);

	phi_edge_prev_next <= phi2_sync;

	process(registered_read_data_reg, data_out,phi2_sync, phi_edge_prev_reg, delay_reg, 
		bus_drive_reg,bus_data_out_reg, 
		bus_rw_n_reg,bus_addr_in_reg,bus_data_in_reg,
		bus_rw_n,
		bus_cs,bus_cs_reg,
		bus_data,bus_addr,
		state_reg)
	begin
		-- maintain snap (only read bus when safe!)
		bus_addr_in_next <= bus_addr_in_reg;
		bus_data_in_next <= bus_data_in_reg;
		bus_rw_n_next <= bus_rw_n_reg;

		internal_memory_request <= '0';
		delay_next <= delay_reg(30 downto 0)&(not(phi2_sync) and phi_edge_prev_reg);
		bus_data_out_next <= bus_data_out_reg;
		bus_drive_next <= bus_drive_reg;
		bus_cs_next <= bus_cs_reg;

		registered_read_data_next <= registered_read_data_reg;

		-- LLLLLLLHHHHHHH
		-- XXAAAAAAAAAAAA
		-- XXXXXXXXXXDDDD
		state_next <= state_reg;
		case (state_reg) is
			when state_wait_addrctl =>
				if ((bus_cs and delay_reg(11))='1') then
					-- snap control signals, should be stable by now
					bus_addr_in_next <= bus_addr;
					bus_rw_n_next <= bus_rw_n;
					bus_cs_next <= bus_cs;

					if (bus_rw_n='1') then -- read
						state_next <= state_read_output_fetch;
					else
						state_next <= state_write_request;
					end if;
				end if;
			when state_write_request =>
				if (delay_reg(26)='1') then
					bus_data_in_next <= bus_data;
				end if;
				if (delay_reg(27)='1') then
					internal_memory_request <= '1';
					state_next <= state_wait_addrctl;
				end if;
			when state_read_output_fetch =>
				state_next <= state_read_output_start;
				internal_memory_request <= '1';
				registered_read_data_next <= data_out;
			when state_read_output_start =>
				if (delay_reg(20)='1') then
					bus_data_out_next <= registered_read_data_reg;
					bus_drive_next <= '1';
					state_next <= state_read_output_end;
				end if;
			when state_read_output_end =>
				if (delay_reg(31)='1') then
					bus_drive_next <= '0';
					state_next <= state_wait_addrctl;
				end if;
			when others =>
		end case;
		
	end process;

	process(delay_reg,halt_n,halt_n_reg)
	begin
		halt_n_next <= halt_n_reg;
		if (delay_reg(29)='1') then
			halt_n_next <= halt_n;
		end if;
	end process;

	bus_data_out <= bus_data_out_reg;
	bus_drive <= bus_drive_reg;
	bus_request <= internal_memory_request;
	addr_in <= bus_addr_in_reg;
	data_in <= bus_data_in_reg;
	rw_n <= bus_rw_n_reg;	
	CS <= bus_cs_reg;

	enable_cycle <= delay_reg(29);
	halt_n_out <= halt_n_reg;

end vhdl;
