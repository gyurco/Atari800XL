---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_MISC.all;

ENTITY timing6502 IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;
	
	PHI0 : IN STD_LOGIC;
	HALT_N : IN STD_LOGIC;
	IRQ_N : IN STD_LOGIC;
	NMI_N : IN STD_LOGIC;

	-- FPGA side
	ADDR_IN : IN STD_LOGIC_VECTOR(15 downto 0);
	DATA_IN : IN STD_LOGIC_VECTOR(7 downto 0);
	WRITE_IN : IN STD_LOGIC;

	DATA_OUT : OUT STD_LOGIC_VECTOR(7 downto 0);
	
	CPU_REQUEST : OUT STD_LOGIC;
	CPU_REQUEST_COMPLETE : OUT STD_LOGIC;

	CPU_IRQ_N : OUT STD_LOGIC;
	CPU_NMI_N : OUT STD_LOGIC;

	-- 6502 side
	BUS_DATA_IN : IN STD_LOGIC_VECTOR(7 downto 0);
	
	BUS_PHI1 : OUT STD_LOGIC;
	BUS_PHI2 : OUT STD_LOGIC;
	BUS_SUBCYCLE : OUT STD_LOGIC_VECTOR(4 downto 0);
	BUS_ADDR_OUT : OUT STD_LOGIC_VECTOR(15 downto 0);
	BUS_ADDR_OE : OUT STD_LOGIC;
	BUS_DATA_OUT : OUT STD_LOGIC_VECTOR(7 downto 0);
	BUS_DATA_OE : OUT STD_LOGIC;
	BUS_WRITE_N : OUT STD_LOGIC;
	BUS_WRITE_OE : OUT STD_LOGIC
);
END timing6502;

ARCHITECTURE vhdl OF timing6502 IS
	signal state_next : std_logic_vector(4 downto 0);
	signal state_reg : STD_LOGIC_VECTOR(4 DOWNTO 0);

	signal addr_next : std_logic_vector(15 downto 0);
	signal addr_reg : std_logic_vector(15 downto 0);

	signal addr_oe_next : std_logic;
	signal addr_oe_reg : std_logic;

	signal data_next : std_logic_vector(7 downto 0);
	signal data_reg : std_logic_vector(7 downto 0);

	signal data_oe_next : std_logic;
	signal data_oe_reg : std_logic;

	signal data_read_next : std_logic_vector(7 downto 0);
	signal data_read_reg : std_logic_vector(7 downto 0);

	signal phi1_next : std_logic;
	signal phi1_reg : std_logic;

	signal phi2_next : std_logic;
	signal phi2_reg : std_logic;

	signal write_n_next : std_logic;
	signal write_n_reg : std_logic;

	signal write_oe_next : std_logic;
	signal write_oe_reg : std_logic;	
	
	signal request_handling_next : std_logic;
	signal request_handling_reg : std_logic;
	
	signal PHI0_NEXT : std_logic;
	signal PHI0_REG : std_logic;
	signal NMI_N_NEXT : std_logic;	
	signal NMI_N_REG : std_logic;		
	signal IRQ_N_NEXT : std_logic;	
	signal IRQ_N_REG : std_logic;		
	signal HALT_N_NEXT : std_logic;	
	signal HALT_N_REG : std_logic;		

	signal init_next : std_logic_vector(5 downto 0);
	signal init_reg : std_logic_vector(5 downto 0);

	signal syncphi2 : std_logic;
	signal initmode : std_logic;
BEGIN
	-- regs

	process(clk, reset_n)
	begin
		if (reset_n='0') then
			state_reg <= "01100";
			addr_reg <= (others=>'0');
			addr_oe_reg <= '0';
			data_reg <= (others=>'0');
			data_read_reg <= (others=>'0');
			data_oe_reg <= '0';
			phi1_reg <= '0';
			phi2_reg <= '0';
			write_n_reg <= '1';
			write_oe_reg <= '0';
			request_handling_reg <= '0';
			
			PHI0_REG <= '1';			
			IRQ_N_REG <= '1';
			NMI_N_REG <= '1';
			HALT_N_REG <= '1';
			init_reg <= (others=>'0');
		elsif (clk'event and clk='1') then
			state_reg <= state_next;
			addr_reg <= addr_next;
			addr_oe_reg <= addr_oe_next;
			data_reg <= data_next;
			data_read_reg <= data_read_next;
			data_oe_reg <= data_oe_next;
			phi1_reg <= phi1_next;
			phi2_reg <= phi2_next;
			write_n_reg <= write_n_next;
			write_oe_reg <= write_oe_next;
			request_handling_reg <= request_handling_next;
			
			PHI0_REG <= PHI0_NEXT;			
			IRQ_N_REG <= IRQ_N_NEXT;
			NMI_N_REG <= NMI_N_NEXT;
			HALT_N_REG <= HALT_N_NEXT;

			init_reg <= init_next;
		end if;			
	end process;
	
	PHI0_sync : entity work.synchronizer	
		port map (clk=>clk, raw=>PHI0, sync=>PHI0_NEXT);	

	process(init_reg,phi0_reg,phi0_next)
	begin
		init_next <= init_reg;
		initmode <= '0';
		syncphi2 <= '0';

		if (phi0_reg = '0' and phi0_next='1') then
			init_next(5 downto 0) <= init_reg(4 downto 0)&'1';
			syncphi2 <= '1';
		end if;

		if (and_reduce(init_reg)='0') then
			initmode <= '1';
		end if;
	end process;

	-- next state
	process(initmode, syncphi2, state_reg, phi1_reg, phi2_reg, addr_in, data_in, addr_reg, addr_oe_reg, data_reg, data_oe_reg, data_read_reg, bus_data_in, write_n_reg, write_in, request_handling_reg, write_oe_reg, irq_n_reg, nmi_n_reg, halt_n_reg, nmi_n, irq_n, halt_n)
	begin
		CPU_REQUEST_COMPLETE <= '0';
	
		state_next <= state_reg;
		phi1_next <= phi1_reg;
		phi2_next <= phi2_reg;
		addr_next <= addr_reg;
		addr_oe_next <= addr_oe_reg;
		data_next <= data_reg;
		data_oe_next <= data_oe_reg;
		data_read_next <= data_read_reg;
		write_n_next <= write_n_reg;		
		request_handling_next <= request_handling_reg;
		write_oe_next <= write_oe_reg;
		irq_n_next <= irq_n_reg;
		nmi_n_next <= nmi_n_reg;
		halt_n_next <= halt_n_reg;

		if (initmode = '0') then
			state_next <= std_logic_vector(unsigned(state_reg)+1);		
		end if;

		if (syncphi2 = '1') then
			state_next <= "01110";
		end if;

		case state_reg is
		when "00000" =>
			addr_next <= addr_in;
			data_next <= data_in;
			write_n_next <= not(write_in);
			request_handling_next <= halt_n_reg;
		when "00010"=>
			addr_oe_next <= request_handling_reg;
			write_oe_next <= request_handling_reg;
		when "01100" =>
			phi1_next <= '0';
		when "01110" =>
			phi2_next <= '1';
		when "10010" =>
			if (write_in = '1') then
				data_oe_next <= request_handling_reg;
			end if;
		when "11100" =>			
			data_read_next <= bus_data_in;
			phi2_next <= '0';
		when "11101" =>
			request_handling_next <= '0';
			CPU_REQUEST_COMPLETE <= request_handling_reg;
			nmi_n_next <= nmi_n;
			irq_n_next <= irq_n;
			halt_n_next <= halt_n;
		when "11110" =>
			addr_next <= (others=>'0');
			addr_oe_next <= '0';
			write_oe_next <= '0';
			data_oe_next <= '0';
			write_n_next <= '1';
			phi1_next <= '1';
		when others=>
		end case;

	end process;

	-- outputs
	BUS_SUBCYCLE <= state_reg;
	BUS_PHI1 <= phi1_reg;
	BUS_PHI2 <= phi2_reg;
	BUS_ADDR_OUT <= addr_reg;
	BUS_ADDR_OE <= addr_oe_reg;
	BUS_DATA_OUT <= data_reg;
	BUS_DATA_OE <= data_oe_reg;
	BUS_WRITE_N <= write_n_reg;
	BUS_WRITE_OE <= write_oe_reg;
	
	DATA_OUT <= data_read_reg;
	
	CPU_REQUEST <= request_handling_reg;
	CPU_NMI_N <= NMI_N_REG;
	CPU_IRQ_N <= IRQ_N_REG;
	
END vhdl;
