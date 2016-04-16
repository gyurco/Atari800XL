LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY config_regs_6502 IS
	PORT (
				CLK: in std_logic;
				RESET_N: in std_logic;
				
				SEM_OUT: out std_logic;
				BANKA_ENABLE: out std_logic;
				BANK8_ENABLE: out std_logic;
				BANK_HALF_SELECT: out std_logic;
				BANK_SELECT: out std_logic;
				ENABLE_65816: out std_logic;

				
				DATA_IN: in std_logic_vector(7 downto 0);
				DATA_OUT: out std_logic_vector(7 downto 0);
				RW_N: in std_logic
			);
END config_regs_6502;

ARCHITECTURE vhdl OF config_regs_6502 IS

	signal sem_next : std_logic;
	signal sem_reg : std_logic;

	signal banka_enable_next : std_logic;
	signal banka_enable_reg  : std_logic;
	
	signal bank8_enable_next : std_logic;
	signal bank8_enable_reg  : std_logic;	
	
	signal bank_half_next : std_logic;
	signal bank_half_reg : std_logic;

	signal bank_select_next : std_logic;
	signal bank_select_reg : std_logic;

	signal enable_65816_next : std_logic;
	signal enable_65816_reg : std_logic;
	
begin
	process(clk,reset_n)
	begin
		if (reset_n='0') then
			sem_reg <= '1';
			banka_enable_reg <= '0';
			bank8_enable_reg <= '0';
			bank_half_reg <= '1';
			bank_select_reg <= '0';
			enable_65816_reg <= '0';
		elsif (clk'event and clk='1') then
			sem_reg <= sem_next;
			banka_enable_reg <= banka_enable_next;
			bank8_enable_reg <= bank8_enable_next;
			bank_half_reg <= bank_half_next;
			bank_select_reg <= bank_select_next;
			enable_65816_reg <= enable_65816_next;
		end if;
	end process;
	
	process(data_in,rw_n,sem_reg,banka_enable_reg,bank8_enable_reg,bank_half_reg,bank_select_reg,enable_65816_reg)
	begin
		sem_next <= sem_reg;
		banka_enable_next <= banka_enable_reg;
		bank8_enable_next <= bank8_enable_reg;
		bank_half_next <= bank_half_reg;
		bank_select_next <= bank_select_reg;
		enable_65816_next <= enable_65816_reg;
		
		if (rw_n='0') then
			sem_next <= data_in(7);
			banka_enable_next <= data_in(5);
			bank8_enable_next <= data_in(4);
			bank_half_next <= data_in(3);
			bank_select_next <= data_in(1);
			enable_65816_next <= data_in(0);
		end if;
	end process;
	
	data_out <= sem_reg&'1'&banka_enable_reg&bank8_enable_reg&bank_half_reg&'1'&bank_select_reg&enable_65816_reg;
	sem_out <= sem_reg;
	banka_enable <= banka_enable_reg;
	bank8_enable <= bank8_enable_reg;
	bank_half_select<=bank_half_reg;
	bank_select<=bank_select_reg;
	enable_65816<=enable_65816_reg;
	
end vhdl;
