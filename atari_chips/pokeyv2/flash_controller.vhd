---------------------------------------------------------------------------
-- (c) 2020 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_MISC.all;

LIBRARY work;

ENTITY flash_controller IS 
	PORT
	(
		CLK : IN STD_LOGIC;
		RESET_N : IN STD_LOGIC;

		-- Request from device 1 (cpu)
		flash_req1_addr_config : IN STD_LOGIC; -- 1 access config, 0 access main flash
		flash_req1_addr : IN STD_LOGIC_VECTOR(12 downto 0);
		flash_req1_data_in : IN STD_LOGIC_VECTOR(31 downto 0);
		flash_req1_request : IN STD_LOGIC;
		flash_req1_write_n: IN STD_LOGIC;
		flash_req1_complete : OUT STD_LOGIC;

		-- Request from device 2 (init controller - init block ram or registers)
		flash_req2_addr : IN STD_LOGIC_VECTOR(12 downto 0);
		flash_req2_request : IN STD_LOGIC;
		flash_req2_complete : OUT STD_LOGIC;

		-- Request from device 3 (read sid tables)
		flash_req3_addr : IN STD_LOGIC_VECTOR(12 downto 0);
		flash_req3_request : IN STD_LOGIC;
		flash_req3_complete : OUT STD_LOGIC;

		-- Output
		flash_data_out : OUT STD_LOGIC_VECTOR(31 downto 0)
	);
END flash_controller;		
		
ARCHITECTURE vhdl OF flash_controller IS
	component flash is
	port (
		clock                   : in  std_logic                     := '0';             --    clk.clk
		avmm_csr_addr           : in  std_logic                     := '0';             --    csr.address
		avmm_csr_read           : in  std_logic                     := '0';             --       .read
		avmm_csr_writedata      : in  std_logic_vector(31 downto 0) := (others => '0'); --       .writedata
		avmm_csr_write          : in  std_logic                     := '0';             --       .write
		avmm_csr_readdata       : out std_logic_vector(31 downto 0);                    --       .readdata
		avmm_data_addr          : in  std_logic_vector(12 downto 0) := (others => '0'); --   data.address
		avmm_data_read          : in  std_logic                     := '0';             --       .read
		avmm_data_writedata     : in  std_logic_vector(31 downto 0) := (others => '0'); --       .writedata
		avmm_data_write         : in  std_logic                     := '0';             --       .write
		avmm_data_readdata      : out std_logic_vector(31 downto 0);                    --       .readdata
		avmm_data_waitrequest   : out std_logic;                                        --       .waitrequest
		avmm_data_readdatavalid : out std_logic;                                        --       .readdatavalid
		avmm_data_burstcount    : in  std_logic_vector(7 downto 0)  := (others => '0'); --       .burstcount
		reset_n                 : in  std_logic                     := '0'              -- nreset.reset_n
	);
	end component;

	signal flash_config_addr : std_logic;
	signal flash_config_read : std_logic;
	signal flash_config_di : std_logic_vector(31 downto 0);

	signal flash_config_write : std_logic;
	signal flash_config_do : std_logic_vector(31 downto 0);

	signal flash_data_addr : std_logic_vector(12 downto 0);
	signal flash_data_read : std_logic;
	signal flash_data_di : std_logic_vector(31 downto 0);

	signal flash_data_write : std_logic;
	signal flash_data_do : std_logic_vector(31 downto 0);

	signal flash_data_waitrequest : std_logic;

	signal flash_data_readvalid : std_logic;

	signal flash_data_burstcount : std_logic_vector(7 downto 0);

	signal state_reg : std_logic_vector(2 downto 0);
	signal state_next : std_logic_vector(2 downto 0);
	constant state_idle : std_logic_vector(2 downto 0) := "000";
	constant state_read : std_logic_vector(2 downto 0) := "001";
	constant state_write : std_logic_vector(2 downto 0) := "010";
	constant state_read_wait : std_logic_vector(2 downto 0) := "011";
	constant state_write_wait : std_logic_vector(2 downto 0) := "100";

	signal request_addr_reg : std_logic_vector(12 downto 0);
	signal request_addr_next : std_logic_vector(12 downto 0);
	signal request_di_reg : std_logic_vector(31 downto 0);
	signal request_di_next : std_logic_vector(31 downto 0);
	signal device_reg : std_logic;
	signal device_next : std_logic;
	signal output_reg : std_logic_vector(1 downto 0);
	signal output_next : std_logic_vector(1 downto 0);

	signal complete : std_logic;
	signal flash_read : std_logic;
	signal flash_readvalid : std_logic;
	signal flash_write : std_logic;
	signal flash_waitrequest : std_logic;
	signal flash_do : std_logic_vector(31 downto 0);

BEGIN

	flash_data_burstcount <= (others=>'0');

	flash1 : flash
	port map
       	(
		clock                   => clk,
		avmm_csr_addr           => request_addr_reg(0),
		avmm_csr_read           => flash_config_read,
		avmm_csr_writedata      => request_di_reg,

		avmm_csr_write          => flash_config_write,
		avmm_csr_readdata       => flash_config_do,

		avmm_data_addr          => request_addr_reg,
		avmm_data_read          => flash_data_read,
		avmm_data_writedata     => request_di_reg,

		avmm_data_write         => flash_data_write,
		avmm_data_readdata      => flash_data_do,

		avmm_data_waitrequest   => flash_data_waitrequest,

		avmm_data_readdatavalid => flash_data_readvalid,

		avmm_data_burstcount    => flash_data_burstcount,

		reset_n                 => reset_n
	);

	process(clk,reset_n)
	begin
		if (reset_n='0') then
			state_reg <= state_idle;
			request_addr_reg <= (others=>'0');
			request_di_reg <= (others=>'0');
			device_reg <= '0';
			output_reg <= (others=>'0');
		elsif (clk'event and clk='1') then
			state_reg <= state_next;
			request_addr_reg <= request_addr_next;
			request_di_reg <= request_di_next;
			device_reg <= device_next;
			output_reg <= output_next;
		end if;
	end process;

	-- state machine
	-- We follow a priority strategy:
	-- dev1, dev2, dev3
	-- TODO burst!
	process(state_reg,request_addr_reg,request_di_reg,device_reg,output_reg,
		flash_req1_request,flash_req2_request,flash_req3_request,

		flash_req1_addr, flash_req1_data_in, flash_req1_write_n, flash_req1_addr_config,
		flash_req2_addr, 
		flash_req3_addr,

		flash_readvalid, flash_waitrequest
		)
	begin
		state_next <= state_reg;
		request_addr_next <= request_addr_reg;
		request_di_next <= request_di_reg;
		device_next <= device_reg;
		output_next <= output_reg;

		complete <= '0';
		flash_read <= '0';
		flash_write <= '0';

		case state_reg is
		when state_idle=>
			if (flash_req1_request='1') then
				request_addr_next <= flash_req1_addr;
				request_di_next <= flash_req1_data_in;

				if (flash_req1_write_n='1') then --read
					state_next <= state_read;
				else
					state_next <= state_write;
				end if;

				output_next <= "00";

				device_next <= flash_req1_addr_config;
			elsif (flash_req2_request='1') then
				request_addr_next <= flash_req2_addr;

				state_next <= state_read;
				output_next <= "01";
				device_next <= '0';
			elsif (flash_req3_request='1') then
				request_addr_next <= flash_req3_addr;

				state_next <= state_read;
				output_next <= "10";
				device_next <= '0';
			end if;
		when state_read=>
			flash_read <= '1';
			state_next <= state_read_wait;
		when state_read_wait =>
			complete <= flash_readvalid;
			if (flash_readvalid = '1') then
				state_next <= state_idle;
			end if;
		when state_write=>
			flash_write <= '1';
			state_next <= state_write_wait;
		when state_write_wait=>
			flash_write <= flash_waitrequest;
			complete <= not(flash_waitrequest);
			if (flash_waitrequest='0') then
				state_next <= state_idle;
			end if;
		when others=>
			state_next <= state_idle;
		end case;
	end process;

	-- mux on selected device
	process(device_reg, flash_data_do, flash_config_do,
		flash_write,flash_read,flash_data_readvalid,flash_data_waitrequest)
	begin
		flash_do <= (others=>'0');

		flash_config_read <= '0';
		flash_config_write <= '0';
		flash_data_read <= '0';
		flash_data_write <= '0';

		flash_readvalid <= '0';
		flash_waitrequest <= '0';

		if (device_reg='1') then --config
			flash_do <= flash_config_do;
			flash_config_read <= flash_read;
			flash_config_write <= flash_write;
			flash_readvalid <= '1';
		elsif (device_reg='0') then --main
			flash_do <= flash_data_do;
			flash_data_read <= flash_read;
			flash_data_write <= flash_write;
			flash_readvalid <= flash_data_readvalid;
			flash_waitrequest <= flash_data_waitrequest;
		end if;
	end process;

	-- mux on who requested
	process(output_reg,complete)
	begin
		flash_req1_complete <= '0';
		flash_req2_complete <= '0';
		flash_req3_complete <= '0';

		case (output_reg) is
		when "00" =>
			flash_req1_complete <= complete;
		when "01" =>
			flash_req2_complete <= complete;
		when others =>
			flash_req3_complete <= complete;
		end case;

	end process;

	-- outputs
	flash_data_out <= flash_do;

end vhdl;	
