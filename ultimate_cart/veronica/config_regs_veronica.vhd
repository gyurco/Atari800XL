LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY config_regs_veronica IS
	PORT (
				CLK: in std_logic;
				RESET_N: in std_logic;
				
				SEM_IN: in std_logic;
				WINDOW_ADDRESS: out std_logic;
				BANK_HALF_SELECT: out std_logic;
				
				SEM_WRITE : out std_logic;
				SEM_VALUE : out std_logic;
				
				DATA_IN: in std_logic_vector(7 downto 0);
				DATA_OUT: out std_logic_vector(7 downto 0);
				RW_N: in std_logic
			);
END config_regs_veronica;


ARCHITECTURE vhdl OF config_regs_veronica IS
	signal window_address_next : std_logic;
	signal window_address_reg  : std_logic;
	
	signal bank_half_next : std_logic;
	signal bank_half_reg : std_logic;
	
begin
	process(clk,reset_n)
	begin
		if (reset_n='0') then
			window_address_reg <= '0';
			bank_half_reg <= '1';
		elsif (clk'event and clk='1') then
			window_address_reg <= window_address_next;
			bank_half_reg <= bank_half_next;
		end if;
	end process;
	
	process(rw_n,window_address_reg,bank_half_reg,data_in)
	begin
		window_address_next <= window_address_reg;
		bank_half_next <= bank_half_reg;
		sem_write <= '0';
		sem_value <= '0'; -- Not important
		
		if (rw_n='0') then
			window_address_next <= data_in(6);
			bank_half_next <= data_in(5);
			sem_write <= '1';
			sem_value <= not(data_in(7));
		end if;
	end process;
	
	data_out <= not(sem_in)&window_address_reg&bank_half_reg&"11111";
	window_address <= window_address_reg;
	bank_half_select <= bank_half_reg;

end vhdl;
