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
	signal gpio0_out_next : std_logic_vector(35 downto 0);
	signal gpio0_out_reg : std_logic_vector(35 downto 0);
	signal gpio1_out_next : std_logic_vector(35 downto 0);
	signal gpio1_out_reg : std_logic_vector(35 downto 0);
	signal gpio0_dir_next : std_logic_vector(35 downto 0);
	signal gpio0_dir_reg : std_logic_vector(35 downto 0);
	signal gpio1_dir_next : std_logic_vector(35 downto 0);
	signal gpio1_dir_reg : std_logic_vector(35 downto 0);

	signal bit_next : std_logic_vector(5 downto 0);
	signal bit_reg : std_logic_vector(5 downto 0);

	constant state_clear : std_logic_vector(1 downto 0) := "00";
	constant state_read : std_logic_vector(1 downto 0) := "01";
	constant state_drive : std_logic_vector(1 downto 0) := "10";
	signal state_next : std_logic_vector(1 downto 0);
	signal state_reg : std_logic_vector(1 downto 0);

	signal mem_write : std_logic;
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
			bit_reg <= (others=>'0');
			gpio0_out_reg <= (others=>'0');
			gpio1_out_reg <= (others=>'0');
			gpio0_dir_reg <= (others=>'1');
			gpio1_dir_reg <= (others=>'1');
			state_reg <= state_clear;
		elsif (clk'event and clk='1') then
			bit_reg <= bit_next;
			gpio0_out_reg <= gpio0_out_next;
			gpio1_out_reg <= gpio1_out_next;
			gpio0_dir_reg <= gpio0_dir_next;
			gpio1_dir_reg <= gpio1_dir_next;
			state_reg <= state_next;
		end if;
	end process;

	-- Process is as follows
	-- i) drive all to 0, drive on everywhere
	-- ii) drive a bit to 1, drive on only that bit
	-- iii) read the value of all gpios and store
	-- iv) next bit
	process(enable_179_early,state_reg,bit_reg,gpio0_out_reg,gpio0_dir_reg,gpio1_out_reg,gpio1_dir_reg,gpio_0_in,gpio_1_in)
	begin
		bit_next <= bit_reg;
		gpio0_out_next <= gpio0_out_reg;
		gpio1_out_next <= gpio1_out_reg;
		gpio0_dir_next <= gpio0_dir_reg;
		gpio1_dir_next <= gpio1_dir_reg;
		state_next <= state_reg;
		mem_write <= '0';

		if (enable_179_early = '1') then
			case state_reg is
				when state_clear =>
					state_next <= state_drive;

					-- prepare to drive
					gpio0_out_next <= (others=>'0');
					gpio1_out_next <= (others=>'0');
					gpio0_dir_next <= (others=>'0');
					gpio1_dir_next <= (others=>'0');
					gpio0_out_next(to_integer(unsigned(bit_reg))) <= '1';
					gpio0_dir_next(to_integer(unsigned(bit_reg))) <= '1';

				when state_drive =>
					state_next <= state_read;

					--prepare to read
					gpio0_dir_next <= (others=>'0');
					gpio1_dir_next <= (others=>'0');

				when state_read =>
					state_next <= state_clear;

					-- store to ram
					mem_write <= '1';

					-- prepare to clear
					gpio0_out_next <= (others=>'0');
					gpio1_out_next <= (others=>'0');
					gpio0_dir_next <= (others=>'1');
					gpio1_dir_next <= (others=>'1');

					-- next bit!
					bit_next <= std_logic_vector(unsigned(bit_reg)+1);
					if (bit_reg=std_logic_vector(to_unsigned(35,6))) then
						bit_next <= (others=>'0');
					end if;

				when others=>
					state_next <= state_clear;
			end case;
		end if;
	end process;

gpioram: ENTITY work.gpioram
	PORT MAP
	(
		address => bit_reg,
		clock => clk,
		data => gpio_0_in&gpio_1_in,
		wren => mem_write,
		q => open
	);

	GPIO_0_OUT <= gpio0_out_reg;
	GPIO_0_DIR_OUT <= gpio0_dir_reg;
	GPIO_1_OUT <= gpio1_out_reg;
	GPIO_1_DIR_OUT <= gpio1_dir_reg;

end vhdl;

