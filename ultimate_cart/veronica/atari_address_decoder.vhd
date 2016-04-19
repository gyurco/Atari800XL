LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
use IEEE.STD_LOGIC_MISC.all;

ENTITY atari_address_decoder IS
	PORT (
				s4_n : in std_logic;
				s5_n : in std_logic;
				ctl_n : in std_logic;
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
	signal addr_valid : std_logic;
begin

	sram_address(16) <= '1';
	sram_address(15 downto 14) <= bank_select&bank_half_select;
	sram_address(13) <= s4_n and not(s5_n);
	sram_address(12 downto 0) <= addr_in;
	
	sram_select <= bus_request and not(s4_n and s5_n);
	addr_valid <= '1' when addr_in(7 downto 0)=x"c0" else '0';
	config_select <= bus_request and not(ctl_n) and addr_valid;
	
end vhdl;
