	LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY sram_mux IS
	PORT (
				clk : in std_logic;
				clk7x : in std_logic;
				reset_n : in std_logic;
				
				sram_addr : out std_logic_vector(19 downto 0);
				sram_data_out : out std_logic_vector(7 downto 0);
				sram_drive_data : out std_logic;
				sram_we_n : out std_logic;

				atari_bus_request : in std_logic;
				atari_sram_select : in std_logic;
				atari_address : in std_logic_vector(16 downto 0);
				atari_w_n : in std_logic;
				atari_write_data : in std_logic_vector(7 downto 0);
				
				veronica_address : in std_logic_vector(16 downto 0);
				veronica_sram_select : in std_logic;
				veronica_w_n : in std_logic;
				veronica_write_data : in std_logic_vector(7 downto 0)
			);
END sram_mux;

ARCHITECTURE vhdl OF sram_mux IS
	signal sram_we_n_next : std_logic;
	signal sram_we_n_reg : std_logic;

	signal sram_drive_data_next : std_logic;
	signal sram_drive_data_reg : std_logic;

	signal sram_write_data_next : std_logic_vector(7 downto 0);
	signal sram_write_data_reg : std_logic_vector(7 downto 0);
	
	signal tick_next : std_logic;
	signal tick_reg : std_logic;

	signal tick_last_fast_next : std_logic;
	signal tick_last_fast_reg : std_logic;
	
	signal tick_fast_next : std_logic_vector(6 downto 0);
	signal tick_fast_reg : std_logic_vector(6 downto 0);
	
	signal tick_mask : std_logic_vector(6 downto 0);
begin

	-- Back to back writes from 65816?
	process(veronica_address, veronica_write_data, veronica_w_n, veronica_sram_select,
			atari_bus_request, atari_address,atari_write_data, atari_w_n, atari_sram_select, tick_fast_reg,
			sram_we_n_next)
	begin
		sram_addr <= (others=>'0');
		sram_write_data_next <= (others=>'0');
		sram_drive_data_next <= '0';
	
		if (atari_bus_request='1') then
			sram_addr(16 downto 0) <= atari_address;
			sram_write_data_next <= atari_write_data;
			sram_we_n_next <= (atari_w_n or not(atari_sram_select) or tick_fast_reg(6));
		else
			sram_addr(16 downto 0) <= veronica_address;
			sram_write_data_next <= veronica_write_data;
			sram_we_n_next <= (veronica_w_n or not(veronica_sram_select) or tick_fast_reg(6));
		end if;


		sram_drive_data_next <= not(sram_we_n_next or tick_fast_reg(0) or tick_fast_reg(1) or tick_fast_reg(6));
	end process;
	
	-- 
	-- 12345
	-- 01111
	-- 00000
	process(clk,reset_n)
	begin
		if (reset_n='0') then
			tick_reg <= '0';
		elsif (clk'event and clk='1') then
			tick_reg <= tick_next;
		end if;
	end process;	
	tick_next <= not(tick_reg);
	
	process(clk7x,reset_n)
	begin
		if (reset_n='0') then
			tick_fast_reg <= (others=>'0');
			tick_last_fast_reg <= '0';
			sram_we_n_reg <= '1';
			sram_drive_data_reg <= '0';
			sram_write_data_reg <= (others=>'0');
		elsif (clk7x'event and clk7x='1') then
			tick_fast_reg <= tick_fast_next;
			tick_last_fast_reg <= tick_last_fast_next;
			sram_we_n_reg <= sram_we_n_next;
			sram_drive_data_reg <= sram_drive_data_next;
			sram_write_data_reg <= sram_write_data_next;
		end if;
	end process;
	tick_last_fast_next <= tick_reg;

	tick_fast_next <= tick_fast_reg(5 downto 1)&(tick_reg xor tick_last_fast_reg)&tick_fast_reg(6);
	
	-- 55 addr, 45 write pulse, 20 we -> drive
	-- 71.4 total -> 7x clock-> about 10ns
	-- 10 (we high), 60 (we low) 1 000 000
	-- 30 (no drive), 40 (drive) 0 001 111
	
	sram_we_n <= sram_we_n_reg;
	sram_drive_data <= sram_drive_data_reg;
	sram_data_out <= sram_write_data_reg;

end vhdl;
