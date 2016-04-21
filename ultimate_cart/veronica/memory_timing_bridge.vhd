LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY memory_timing_bridge IS
PORT 
( 
	clk : in std_logic;
	clk7x : in std_logic;
	reset_n : in std_logic;

	fast_memory_request : in std_logic;
	registered_read_data : out std_logic_vector(7 downto 0);

	memory_request : out std_logic;
	read_data : in std_logic_vector(7 downto 0)
);
END memory_timing_bridge;

ARCHITECTURE vhdl OF memory_timing_bridge IS
	signal memory_next : std_logic_vector(7 downto 0);
	signal memory_reg : std_logic_vector(7 downto 0);

	signal fast_request_toggle_next : std_logic;
	signal fast_request_toggle_reg : std_logic;
	signal slow_request_toggle_next : std_logic;
	signal slow_request_toggle_reg : std_logic;

	signal make_request_next : std_logic;
	signal make_request_reg : std_logic;
begin
	-- register
	process(clk)
	begin
		if (reset_n='0') then
			memory_reg <= (others=>'0');
			slow_request_toggle_reg <= '0';
			make_request_reg <= '0';
		elsif (clk'event and clk='1')  then
			memory_reg <= memory_next;
			slow_request_toggle_reg <= slow_request_toggle_next;
			make_request_reg <= make_request_next;
		end if;
	end process;

	process(clk7x)
	begin
		if (reset_n='0') then
			fast_request_toggle_reg <= '0';
		elsif (clk'event and clk='1') then						
			fast_request_toggle_reg <= fast_request_toggle_next;
		end if;
	end process;

	fast_request_toggle_next <= fast_request_toggle_reg xor fast_memory_request;

	process(memory_reg,read_data,make_request_reg)
	begin
		memory_next <= memory_reg;

		if (make_request_reg = '1') then
			memory_next <= read_data;
		end if;
	end process;

	make_request_next <= slow_request_toggle_reg xor fast_request_toggle_reg;

	registered_read_data <= memory_reg;

	memory_request <= make_request_reg;
	
end vhdl;


