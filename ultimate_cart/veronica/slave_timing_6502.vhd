LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
use IEEE.STD_LOGIC_MISC.all;

ENTITY slave_timing_6502 IS
	PORT (
				CLK: in std_logic;
				RESET_N: in std_logic;
				
				PHI2 : in std_logic; -- async to our clk:-(
				bus_addr : in std_logic_vector(12 downto 0);
				bus_data : in std_logic_vector(7 downto 0);
				bus_ctl : in std_logic;
				bus_rw : in std_logic;
				bus_s4 : in std_logic;
				bus_s5 : in std_logic;
	
				bus_data_out : out std_logic_vector(7 downto 0);
				bus_drive : out std_logic;

				ADDR_IN: out std_logic_vector(12 downto 0);
				DATA_IN: out std_logic_vector(7 downto 0);
				DATA_OUT: in std_logic_vector(7 downto 0);
				RW_N: out std_logic;
				BUS_REQUEST: out std_logic;
				S4 : out std_logic;
				s5 : out std_logic;
				ctl : out std_logic
			);
END slave_timing_6502;

ARCHITECTURE vhdl OF slave_timing_6502 IS

	signal PHI2_sync : std_logic;
	signal bus_addr_sync : std_logic_vector(12 downto 0);
	signal bus_data_sync : std_logic_vector(7 downto 0);
	signal bus_ctl_sync : std_logic;
	signal bus_rw_sync : std_logic;
	signal bus_s4_sync : std_logic;
	signal bus_s5_sync : std_logic;
	signal bus_misc_sync : std_logic_vector(3 downto 0);
	
	signal phi_edge_prev_next : std_logic;
	signal phi_edge_prev_reg: std_logic;	

	signal drive_bus_shift_next : std_logic_vector(3 downto 0);	
	signal drive_bus_shift_reg : std_logic_vector(3 downto 0);
	
	signal bus_data_out_next : std_logic_vector(7 downto 0);	
	signal bus_data_out_reg : std_logic_vector(7 downto 0);
	
begin
	process(clk,reset_n)
	begin
		if (reset_n='0') then
			phi_edge_prev_reg <= '1';
			drive_bus_shift_reg <= (others=>'0');
			bus_data_out_reg <= (others=>'0');
		elsif (clk'event and clk='1') then
			phi_edge_prev_reg <= phi_edge_prev_next;
			drive_bus_shift_reg <= drive_bus_shift_next;
			bus_data_out_reg <= bus_data_out_next;
		end if;
	end process;
	
	synchronizer_phi : entity work.synchronizer
				 port map (clk=>clk, raw=>PHI2, sync=>PHI2_SYNC);
	synchronizer_addr : entity work.synchronizer_vector
				generic map(BITS=>13)
				port map (clk=>clk, raw=>bus_addr, sync=>bus_addr_sync);
	synchronizer_data : entity work.synchronizer_vector
				generic map(BITS=>8)
				port map (clk=>clk, raw=>bus_data, sync=>bus_data_sync);				
	synchronizer_ctl : entity work.synchronizer_vector
				generic map(BITS=>4)
				port map (clk=>clk, raw=>bus_ctl&bus_rw&bus_s4&bus_s5, sync=>bus_misc_sync);
	
	bus_ctl_sync<=bus_misc_sync(3);
	bus_rw_sync<=bus_misc_sync(2);
	bus_s4_sync<=bus_misc_sync(1);
	bus_s5_sync<=bus_misc_sync(0);

	phi_edge_prev_next <= phi2_sync;
	
	addr_in <= bus_addr_sync;
	data_in <= bus_data_sync;
	rw_n <= bus_rw_sync;	
	s4 <= bus_s4_sync;
	s5 <= bus_s5_sync;
	ctl <= bus_ctl_sync;

	process(data_out, phi2_sync, phi_edge_prev_reg, drive_bus_shift_reg, bus_data_out_reg, bus_rw_sync)
	begin
		bus_request <= '0';
		drive_bus_shift_next <= drive_bus_shift_reg(2 downto 0)&'0';
		bus_data_out_next <= bus_data_out_reg;
		if (phi2_sync = '1' and phi_edge_prev_reg='0') then -- rising edge (delayed 3 cycles - we have 7 to do our output...)
			bus_request <= '1';
			drive_bus_shift_next(0) <= not(bus_rw_sync); -- driven for 4 cycles
			bus_data_out_next <= data_out;
		end if;
		bus_drive <= or_reduce(drive_bus_shift_reg(3 downto 0));
		
	end process;
	
	bus_data_out <= bus_data_out_reg;
				 
end vhdl;
