---------------------------------------------------------------------------
-- (c) 2018 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

LIBRARY work;

ENTITY sallymax IS 
	PORT
	(
		PHI0 : IN STD_LOGIC; -- need to sync to this! TODO
		RST_N : IN STD_LOGIC; -- connect me TODO

		CLK_OUT : OUT STD_LOGIC; -- Use PHI2 and internal oscillator to create a clock, feed out here
		CLK_SLOW : IN STD_LOGIC; -- ... and back in here, then to pll!		
		
		D :  INOUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		A :  OUT  STD_LOGIC_VECTOR(15 DOWNTO 0);
		W_N : OUT STD_LOGIC;

		RDY : IN STD_LOGIC;
		HALT_N : IN STD_LOGIC; -- TODO, wire this up!
		NMI_N : IN STD_LOGIC;
		IRQ_N : IN STD_LOGIC;
		S0 : IN STD_LOGIC; -- not implemented yet!
		
		SYNC : OUT STD_LOGIC;
		PHI1 : OUT STD_LOGIC;
		PHI2 : OUT STD_LOGIC;

		NC : INOUT STD_LOGIC_VECTOR(8 downto 0)
	);
END sallymax;		
		
ARCHITECTURE vhdl OF sallymax IS
	component int_osc is
	port (
		clkout : out std_logic;        -- clkout.clk
		oscena : in  std_logic := '0'  -- oscena.oscena
	);
	end component;

	component pll
		port (
			inclk0   : in  std_logic := '0';
			c0 : out std_logic;
			locked   : out std_logic
		);
	end component;

	signal OSC_CLK : std_logic;
	signal PHI2_6X : std_logic;

	signal CLK : std_logic;
	signal RESET_N : std_logic;

	signal CPU_REQUEST : std_logic;
	signal CPU_REQUEST_COMPLETE : std_logic;
	signal CPU_ADDR : std_logic_vector(15 downto 0);
	signal CPU_WRITE_DATA : std_logic_vector(7 downto 0);
	signal CPU_READ_DATA : std_logic_vector(7 downto 0);
	signal CPU_WRITE_N : std_logic;

	signal CPU_NMI_N : std_logic;
	signal CPU_IRQ_N : std_logic;

	signal BUS_ADDR : std_logic_vector(15 downto 0);
	signal BUS_ADDR_OE : std_logic;
	signal BUS_DATA : std_logic_vector(7 downto 0);
	signal BUS_DATA_OE : std_logic;
	signal BUS_WRITE_N : std_logic;
	signal BUS_WRITE_OE : std_logic;
	
	signal PLLRESET_N : std_logic;
	
BEGIN
	NC <= (others=>'Z');

	oscillator : int_osc
	port map 
	(
		clkout => OSC_CLK, 
		oscena => '1'
	);


	--phi_multiplier : entity work.phi_mult
	--port map 
	--(
	--	clkin => OSC_CLK,
	--	phi2 => PHI2,
	--	clkout => PHI2_6X -- 6x phi2, aligned!
	--);
	
	PHI2_6X <= OSC_CLK;

	pll_inst : pll
	PORT MAP(inclk0 => CLK_SLOW,
			 c0 => CLK, -- 27MHz 
			 locked => PLLRESET_N);
			 
RESET_N <= PLLRESET_N and RST_N;			

bus_adapt : entity work.timing6502
	PORT MAP
	(
		CLK => CLK,
		RESET_N => RESET_N,
		
		PHI0 => PHI0,
		HALT_N => HALT_N,		
		NMI_N => NMI_N,		
		IRQ_N => IRQ_N,		

		-- FGPA side
		ADDR_IN => CPU_ADDR,
		DATA_IN => CPU_WRITE_DATA,
		WRITE_IN => not(CPU_WRITE_N),

		DATA_OUT => CPU_READ_DATA,
		
		CPU_REQUEST => CPU_REQUEST,		
		CPU_REQUEST_COMPLETE => CPU_REQUEST_COMPLETE,
		CPU_NMI_N => CPU_NMI_N,		
		CPU_IRQ_N => CPU_IRQ_N,		

		-- bus side
		BUS_DATA_IN => D,		
		BUS_PHI1 => PHI1,
		BUS_PHI2 => PHI2,
		BUS_SUBCYCLE => open,
		BUS_ADDR_OUT => BUS_ADDR,
		BUS_ADDR_OE => BUS_ADDR_OE,
		BUS_DATA_OUT => BUS_DATA,
		BUS_DATA_OE => BUS_DATA_OE,
		BUS_WRITE_N => BUS_WRITE_N, 
		BUS_WRITE_OE => BUS_WRITE_OE
	);	
				 
cpu6502 : entity work.cpu
PORT MAP(CLK => CLK,
		 RESET => NOT(RESET_N),
		 ENABLE => RESET_N,
		 IRQ_n => CPU_IRQ_N,
		 NMI_n => CPU_NMI_N,
		 MEMORY_READY => CPU_REQUEST_COMPLETE,
		 THROTTLE => CPU_REQUEST,
		 RDY => RDY,
		 DI => CPU_READ_DATA,
		 R_W_n => CPU_WRITE_N,
		 CPU_FETCH => open,
		 A => CPU_ADDR,
		 DO => CPU_WRITE_DATA);

-- Wire up pins
CLK_OUT <= PHI2_6X;

D <= BUS_DATA when (BUS_DATA_OE='1')  else (others=>'Z');
A <= BUS_ADDR when (BUS_ADDR_OE='1') else (others=>'Z');
W_N <= BUS_WRITE_N when (BUS_WRITE_OE='1') else 'Z';

SYNC <= 'Z'; -- Not implemented yet


END vhdl;
