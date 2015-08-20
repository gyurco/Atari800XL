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

entity gpiov3 is
generic
(
	cartridge_cycle_length : in integer := 32
);
port
(
	clk : in std_logic;
	reset_n : in std_logic;
	
	gpio_enable : in std_logic;

	-- pia
	porta_in : out std_logic_vector(7 downto 0);
	porta_out : in std_logic_vector(7 downto 0);
	porta_output : in std_logic_vector(7 downto 0);
	CA1_IN : OUT STD_LOGIC;
	CA2_DIR_OUT : IN std_logic;
	CA2_OUT : IN std_logic;
	CA2_IN : OUT STD_LOGIC;
	CB1_IN : OUT STD_LOGIC;
	CB2_DIR_OUT : IN std_logic;
	CB2_OUT : IN std_logic;
	CB2_IN : OUT STD_LOGIC;
	
	-- gtia
	trig_in : out std_logic_vector(3 downto 0);
	
	-- antic
	lightpen : out std_logic;
	
	-- pokey
	pot_reset : in std_logic;
	pot_in : out std_logic_vector(7 downto 0);
	keyboard_scan : in std_logic_vector(5 downto 0);
	keyboard_response : out std_logic_vector(1 downto 0);
	SIO_IN : OUT STD_LOGIC;
	SIO_OUT : IN STD_LOGIC;
	SIO_CLOCKIN : OUT STD_LOGIC;
	SIO_CLOCKOUT : IN STD_LOGIC;
	
	-- cartridge
	enable_179_early : in std_logic;
	pbi_addr_out : in std_logic_vector(15 downto 0);
	pbi_write_enable : in std_logic;
	cart_data_read : out std_logic_vector(7 downto 0);
	cart_request : in std_logic;
	cart_complete : out std_logic;
	cart_data_write : in std_logic_vector(7 downto 0);
	rd4 : out std_logic;
	rd5 : out std_logic;
	s4_n : in std_logic;
	s5_n : in std_logic;
	cctl_n : in std_logic;
	
	-- gpio connections
	GPIO_0_IN : in std_logic_vector(35 downto 0);
	GPIO_0_OUT : out std_logic_vector(35 downto 0);
	GPIO_0_DIR_OUT : out std_logic_vector(35 downto 0);
	GPIO_1_IN : in std_logic_vector(35 downto 0);
	GPIO_1_OUT : out std_logic_vector(35 downto 0);
	GPIO_1_DIR_OUT : out std_logic_vector(35 downto 0)
);
end gpiov3;

architecture vhdl of gpiov3 is
	signal shift_next : std_logic_vector(71 downto 0);
	signal shift_reg : std_logic_vector(71 downto 0);
begin	
	CA2_in <= '1';
	CB2_in <= '1';
	SIO_IN <= '1';
	
	pot_in <= (others=>'0');
	porta_in <= (others=>'1');
	trig_in <= "0111";
		
	lightpen <= '1';
	
	-- keyboard
	keyboard_response <= (others=>'1');
	
	cart_data_read <= (others=>'1');
	cart_complete <= '1';

	rd4 <= '0';
	rd5 <= '0';

	process(clk,reset_n)
	begin
		if (reset_n='0') then
			shift_reg(71 downto 1) <= (others=>'0');
			shift_reg(0) <= '1';
		elsif (clk'event and clk='1') then
			shift_reg <= shift_next;
		end if;
	end process;

	process(shift_reg,enable_179_early)
	begin
		shift_next <= shift_reg;
		if (enable_179_early = '1') then
			shift_next(71 downto 1) <= shift_reg(70 downto 0);
			shift_next(0) <= shift_reg(71);
		end if;
	end process;

	GPIO_0_OUT <= shift_reg(71 downto 36);
	--GPIO_0_DIR_OUT <= shift_reg(71 downto 36);
	GPIO_0_DIR_OUT <= (others=>'1');
	GPIO_1_OUT <= shift_reg(35 downto 0);
	--GPIO_1_DIR_OUT <= shift_reg(35 downto 0);
	GPIO_1_DIR_OUT <= (others=>'1');

end vhdl;

