LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
use IEEE.STD_LOGIC_MISC.all;

ENTITY atari_address_decoder IS
	PORT (
				s4 : in std_logic;
				s5 : in std_logic;
				ctl : in std_logic;
				addr_in: in std_logic_vector(12 downto 0);
				bus_request: in std_logic;
				
				bank_half_select : in std_logic;
				bank_select : in std_logic;
				
				config_select : out std_logic;
				sram_select : out std_logic;
				sram_address : out std_logic_vector(16 downto 0)
			);
END atari_address_decoder;

ARCHITECTURE vhdl OF atari_address_decoder IS
begin

	sram_address(16) <= '1';
	sram_address(15 downto 14) <= bank_select&bank_half_select;
	sram_address(13) <= not(s4) and s5;
	sram_address(12 downto 0) <= addr_in;
	
	sram_select <= bus_request and (s4 or s5);
	config_select <= bus_request and ctl and or_reduce(addr_in(7 downto 6)&not(addr_in(5 downto 0)));
	
end vhdl;
