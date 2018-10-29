LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
use IEEE.STD_LOGIC_MISC.all;

ENTITY timing_antic IS
	PORT (
			CLK: in std_logic;
			RESET_N: in std_logic;
				
			-- input from the cart port
			PHI2 : in std_logic; -- async to our clk (ish):-(
			bus_addr : in std_logic_vector(15 downto 0);
			bus_data : in std_logic_vector(7 downto 0);
			bus_rw_n : in std_logic;

			bus_lp_n : in std_logic;
			bus_rnmi_n : in std_logic;
	
			-- output to the cart port
			bus_data_out : out std_logic_vector(7 downto 0);
			bus_data_oe : out std_logic;
			bus_addr_out : out std_logic_vector(15 downto 0);
			bus_addr_oe : out std_logic;
			bus_rdy : out std_logic;
			bus_ref_n : out std_logic;
			bus_ref_n_oe : out std_logic;
			bus_halt_n : out std_logic;
			bus_halt_n_oe : out std_logic;
			bus_an_out : out std_logic_vector(2 downto 0);

			-- request for a memory bus cycle (read or write)
			BUS_REQUEST: out std_logic;
			ADDR_IN: out std_logic_vector(15 downto 0);
			DATA_IN: out std_logic_vector(7 downto 0);
			RW_N: out std_logic;
			LIGHTPEN : out std_logic;

			ENABLE_CYCLE : out std_logic;

			DATA_OUT: in std_logic_vector(7 downto 0); -- read_data

			-- antic bus master
			ADDR_OUT : in std_logic_vector(15 downto 0);
			CYCLE_TYPE : in std_logic_vector(2 downto 0); --000=cpu,001=dma,010=refresh,011=undef,100=undef,101=dma_wsync,110=refresh_wsync,101=undef
	
			-- antic an0 output
			AN_OUT : out std_logic_vector(2 downto 0);
			AN_OUT_ENABLE : out std_logic;
			FO0 : in std_logic
	);
END timing_antic;

ARCHITECTURE vhdl OF timing_antic IS

	signal PHI2_sync : std_logic;
	
	signal phi_edge_prev_next : std_logic;
	signal phi_edge_prev_reg: std_logic;	

	signal delay_next : std_logic_vector(31 downto 0);	
	signal delay_reg : std_logic_vector(31 downto 0);
	
	signal bus_data_out_next : std_logic_vector(7 downto 0);	
	signal bus_data_out_reg : std_logic_vector(7 downto 0);

	signal bus_data_oe_next : std_logic;
	signal bus_data_oe_reg : std_logic;

	signal bus_data_in_next : std_logic_vector(7 downto 0);	
	signal bus_data_in_reg : std_logic_vector(7 downto 0);
	signal bus_addr_in_next : std_logic_vector(15 downto 0);	
	signal bus_addr_in_reg : std_logic_vector(15 downto 0);
	signal bus_rw_n_next : std_logic;
	signal bus_rw_n_reg : std_logic;

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
			bus_data_oe_reg <= '0';

			bus_rw_n_reg <= '1';
			bus_data_in_reg <= (others=>'0');
			bus_addr_in_reg <= (others=>'0');

			registered_read_data_reg <= (others=>'0');

			state_reg <= state_wait_addrctl;
		elsif (clk'event and clk='1') then
			phi_edge_prev_reg <= phi_edge_prev_next;
			delay_reg <= delay_next;
			bus_data_out_reg <= bus_data_out_next;
			bus_data_oe_reg <= bus_data_oe_next;

			registered_read_data_reg <= registered_read_data_next;

			bus_rw_n_reg <= bus_rw_n_next;
			bus_data_in_reg <= bus_data_in_next;
			bus_addr_in_reg <= bus_addr_in_next;

			state_reg <= state_next;
		end if;
	end process;
	
	synchronizer_phi : entity work.synchronizer
				 port map (clk=>clk, raw=>PHI2, sync=>PHI2_SYNC);

	phi_edge_prev_next <= phi2_sync;

	process(registered_read_data_reg, data_out,phi2_sync, phi_edge_prev_reg, delay_reg, 
		bus_data_oe_reg,bus_data_out_reg, 
		bus_rw_n_reg,bus_addr_in_reg,bus_data_in_reg,
		bus_rw_n,
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
		bus_data_oe_next <= bus_data_oe_reg;

		registered_read_data_next <= registered_read_data_reg;

		-- LLLLLLLHHHHHHH
		-- XXAAAAAAAAAAAA
		-- XXXXXXXXXXDDDD
		state_next <= state_reg;
		case (state_reg) is
			when state_wait_addrctl =>
				if (delay_reg(11)='1' and bus_addr(15 downto 8)=x"D4") then
					-- snap control signals, should be stable by now
					bus_addr_in_next <= bus_addr;
					bus_rw_n_next <= bus_rw_n;

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
					bus_data_oe_next <= '1';
					state_next <= state_read_output_end;
				end if;
			when state_read_output_end =>
				if (delay_reg(31)='1') then
					bus_data_oe_next <= '0';
					state_next <= state_wait_addrctl;
				end if;
			when others =>
		end case;
		
	end process;

	-- at some point, we need to ask antic what next cycle is:
	-- i) normal, cpu controlled
	-- ii) antic dma
	-- iii) antic refresh
	-- Then depending on the type, switch state machine to a different mode...
	-- typically we find this out on the 'enable cycle' at the end of the 6502 cycle, but this is TOO late for asserting HALT.
	-- in sallymax its on cycle 28,
	-- i'm clockin in writes to antic on cycle 27 and doing next cycle on 29 currently. 
	-- ideally I'd know prior to the write...

	bus_data_out <= bus_data_out_reg;
	bus_data_oe <= bus_data_oe_reg;
	bus_request <= internal_memory_request;
	addr_in <= bus_addr_in_reg;
	data_in <= bus_data_in_reg;
	rw_n <= bus_rw_n_reg;	

	enable_cycle <= delay_reg(29);

end vhdl;
