LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
use IEEE.STD_LOGIC_MISC.all;


ENTITY veronica_address_decoder IS
	PORT (
				addr_in: in std_logic_vector(15 downto 0);
				window_address : in std_logic;
				bank_half_select : in std_logic;
				bank_select : in std_logic;
				
				config_select : out std_logic;
				sram_select : out std_logic;
				sram_address : out std_logic_vector(16 downto 0)
			);
END veronica_address_decoder;

ARCHITECTURE vhdl OF veronica_address_decoder IS
	signal bank_access : std_logic;
	signal config_select_int : std_logic;
begin
	-- window_address 0=0xc0000->0xffff, 1=0x4000->0x7fff
	-- config_address 0x200->0x20f
	bank_access <= (window_address xor addr_in(15)) and addr_in(14);
	process(bank_access,bank_select,bank_half_select,addr_in)
	begin
		sram_address <= '0'&addr_in;
		if (bank_access='1') then
			sram_address(16 downto 14) <= '1'&not(bank_select)&bank_half_select;
		end if;
	end process;

	config_select_int <= not(or_reduce(addr_in(15 downto 10)&addr_in(8 downto 4))) and addr_in(9);	
	config_select <= config_select_int;
	sram_select <= not(config_select_int);
	
end vhdl;
