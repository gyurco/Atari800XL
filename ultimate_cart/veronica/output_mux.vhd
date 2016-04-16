LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY output_mux IS
	PORT (
				config_select : in std_logic;
				sram_select : in std_logic;
				
				config_data : in std_logic_vector(7 downto 0);
				sram_data : in std_logic_vector(7 downto 0);
				
				read_data : out std_logic_vector(7 downto 0)
			);
END output_mux;

ARCHITECTURE vhdl OF output_mux IS
begin
	process(config_select,sram_select,config_data,sram_data)
	begin
		read_data <= sram_data;
		if (config_select='1') then
			read_data <= config_data;
		end if;
	end process;
end vhdl;
