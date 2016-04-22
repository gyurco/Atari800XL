LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY veronica IS
	PORT (
				CLK: in std_logic;
				LED: out std_logic_vector(0 downto 0);
				
				CART_ADDR: in std_logic_vector(12 downto 0);
				CART_DATA: inout std_logic_vector(7 downto 0);
				CART_RD5: out std_logic;
				CART_RD4: out std_logic;
				CART_S5: in std_logic;
				CART_S4: in std_logic;
				CART_PHI2: in std_logic;
				CART_CTL: in std_logic;
				CART_RW: in std_logic;
				
				SD_CARD_cs: out std_logic;
				SD_CARD_sclk: out std_logic;
				SD_CARD_mosi: out std_logic;
				SD_CARD_miso: in std_logic;
				
				EXT_SRAM_ADDR: out std_logic_vector(19 downto 0);
				EXT_SRAM_DATA: inout std_logic_vector(7 downto 0);
				EXT_SRAM_CE: out std_logic;
				EXT_SRAM_OE: out std_logic;
				EXT_SRAM_WE: out std_logic
			);
END veronica;

ARCHITECTURE vhdl OF veronica IS

component FT816 is
port(
	rst : in std_logic;
	clk : in std_logic;

	-- Various clock outputs - perhaps useful for memory layer?
	clko : out std_logic;
	cyc : out std_logic_vector(4 downto 0);
	phi11 : out std_logic;
	phi12 : out std_logic;
	phi81 : out std_logic;
	phi82 : out std_logic;

	nmi : in std_logic; -- active low
	irq : in std_logic; -- active low

	rdy : in std_logic;   -- good old rdy!

	-- Some unknown inputs
	abort : in std_logic; -- another interrupt (active low)
	be : in std_logic;    -- bus enable (active high)
	err_i : in std_logic; -- set to 1 in example
	rty_i : in std_logic; -- set to 1 in example

	-- Some unknown outputs
	vpa : out std_logic; -- valid program address
	vda : out std_logic; -- valid data address (both high for op code??)
	mlb : out std_logic; -- memory busy
	vpb : out std_logic; -- ?
	e : out std_logic;   -- !m816 (emulation pin)
	mx : out std_logic;  -- status bits? m_bit when clk high, x_bit when clk low

	-- data and address bus
	ad : out std_logic_vector(23 downto 0);
	rw : out std_logic;
	db : in std_logic_vector(7 downto 0);
	dw : out std_logic_Vector(7 downto 0)
	);
end component;

	signal clk_adj : std_logic;
	signal clk_adj7x : std_logic;
	signal reset_n : std_logic;
	
	signal veronica_reset : std_logic;

	-- 65816 bus
	signal veronica_address : std_logic_vector(23 downto 0);
	signal veronica_read_data : std_logic_vector(7 downto 0);
	signal veronica_write_data : std_logic_vector(7 downto 0);
	signal veronica_w_n : std_logic;
	signal veronica_config_w_n : std_logic;
	
	-- 6502 bus
	signal atari_bus_request : std_logic;	
	signal atari_address : std_logic_vector(12 downto 0);
	signal atari_data_bus : std_logic_vector(7 downto 0);
	signal atari_read_data : std_logic_vector(7 downto 0);
	signal atari_write_data : std_logic_vector(7 downto 0);
	signal atari_w_n : std_logic;
	signal atari_config_w_n : std_logic;
	signal atari_s4_n : std_logic;
	signal atari_s5_n : std_logic;
	signal atari_ctl_n : std_logic;
	
	-- address decode
	signal veronica_config_select : std_logic;	
	signal veronica_sram_select : std_logic;
	signal veronica_sram_address: std_logic_vector(16 downto 0);	
	signal atari_config_select : std_logic;
	signal atari_sram_select : std_logic;	
	signal atari_sram_address: std_logic_vector(16 downto 0);

	-- veronica config
	signal veronica_window_address : std_logic;
	signal veronica_bank_half_select : std_logic;	
	signal veronica_config_data : std_logic_vector(7 downto 0);
	
	-- atari config
	signal atari_banka_enable : std_logic;
	signal atari_bank8_enable : std_logic;
	signal atari_bank_half_select : std_logic;
	signal atari_config_data : std_logic_vector(7 downto 0);

	-- common config
	signal common_sem : std_logic;	
	signal common_bank_select : std_logic;
	
	-- cart driving
	signal cart_bus_data_out : std_logic_vector(7 downto 0);
	signal cart_bus_drive : std_logic;
	
	-- sram driving
	signal sram_write_data : std_logic_vector(7 downto 0);
	signal sram_drive_data : std_logic;
	signal sram_read_data : std_logic_vector(7 downto 0);
	
begin
	

	pll1:entity work.pll_veronica
	PORT map
	(
		inclk0 => clk,
		c0 => clk_adj,     -- 14MHz (>70ns/cycle)
		c1 => clk_adj7x,   -- 98MHz
		locked => reset_n 
	);
	

	cpu_65816_rob:FT816
		port map (
			rst => reset_n and veronica_reset,
			clk => clk_adj,
			nmi => '1',
			irq => '1',
			rdy => not(atari_bus_request), -- 6502 priority for sram access!
			abort => '1',
			be => '1',
			err_i => '1',
			rty_i => '1',
			ad => veronica_address,
			rw => veronica_w_n,
			dw => veronica_write_data,
			db => veronica_read_data
		);
		
	SD_CARD_cs <= 'Z';
	SD_CARD_sclk <= 'Z';
	LED(0) <= '1';

	veronica_config_w_n <= veronica_w_n or not(veronica_config_select);
	
	glue1: entity work.config_regs_veronica
	port map
	(
		clk => clk_adj,
		reset_n => reset_n,
		
		sem_in => common_sem,
		window_address => veronica_window_address,
		bank_half_select => veronica_bank_half_select,
		
		data_in => veronica_write_data,
		data_out => veronica_config_data,
		rw_n => veronica_config_w_n
	);
	
	
	atari_config_w_n <= atari_w_n or not(atari_config_select);
	
	glue2: entity work.config_regs_6502
	port map
	(
		clk => clk_adj,
		reset_n => reset_n,	
	
		sem_out => common_sem,
		banka_enable => atari_banka_enable,
		bank8_enable => atari_bank8_enable,
		bank_half_select => atari_bank_half_select,
		bank_select => common_bank_select,
		enable_65816 => veronica_reset,
		
		data_in => atari_write_data,
		data_out => atari_config_data,
		rw_n => atari_config_w_n		
	);	
	
	glue3: entity work.slave_timing_6502
	port map
	(
		clk => clk_adj,
		clk7x => clk_adj7x,
		reset_n => reset_n,
		phi2 => CART_PHI2,
		bus_addr => CART_ADDR,
		bus_data => CART_DATA,
		bus_ctl_n => CART_CTL,
		bus_rw_n => CART_RW,
		bus_s4_n => CART_S4,
		bus_s5_n => CART_S5,
		
		bus_data_out => cart_bus_data_out,
		bus_drive => cart_bus_drive,
		
		s4_n => atari_s4_n,
		s5_n => atari_s5_n,
		ctl_n => atari_ctl_n,
		addr_in => atari_address,
		data_in => atari_write_data,
		rw_n => atari_w_n,

		bus_request => atari_bus_request,
		data_out => atari_read_data
	);
	CART_DATA <= cart_bus_data_out when cart_bus_drive='1' else (others=>'Z');

	glue4: entity work.atari_address_decoder
	port map
	(       
		s4_n => atari_s4_n,
		s5_n => atari_s5_n,
		ctl_n => atari_ctl_n,
		addr_in => atari_address,
		bus_request => atari_bus_request,
		
		bank_half_select => atari_bank_half_select,
		bank_select => common_bank_select,
		
		config_select => atari_config_select,
		sram_select => atari_sram_select,
		sram_address => atari_sram_address
	);

	glue5: entity work.veronica_address_decoder
	port map
	(
			addr_in => veronica_address(15 downto 0),
			
			window_address => veronica_window_address,
			bank_half_select => veronica_bank_half_select,
			bank_select => common_bank_select,	
			
			config_select => veronica_config_select,
			sram_select => veronica_sram_select,
			sram_address => veronica_sram_address
	);

	glue6: entity work.sram_mux
	port map
	(
		clk => clk_adj,
		clk7x => clk_adj7x,
		reset_n => reset_n,
		
		sram_addr => EXT_SRAM_ADDR,
		sram_data_out => sram_write_data,
		sram_drive_data => sram_drive_data,
		sram_we_n => EXT_SRAM_WE,

		atari_bus_request => atari_bus_request,
		atari_sram_select => atari_sram_select,
		atari_address => atari_sram_address,
		atari_w_n => atari_w_n,
		atari_write_data => atari_write_data,
		
		veronica_address => veronica_sram_address,
		veronica_sram_select => veronica_sram_select,
		veronica_w_n => veronica_w_n,
		veronica_write_data => veronica_write_data
	);
	
	EXT_SRAM_DATA <= sram_write_data when sram_drive_data='1' else (others=>'Z');
	EXT_SRAM_OE <= '0';
	sram_read_data <= EXT_SRAM_DATA;
	
	glue7: entity work.output_mux
	port map
	(
		config_select => atari_config_select,
		sram_select => atari_sram_select,
		
		config_data => atari_config_data,
		sram_data => sram_read_data,
		
		read_data => atari_read_data	
	);
	
	glue8: entity work.output_mux
	port map
	(
		config_select => veronica_config_select,
		sram_select => veronica_sram_select,
		
		config_data => veronica_config_data,
		sram_data => sram_read_data,
		
		read_data => veronica_read_data
	);
	
	EXT_SRAM_CE <= '0';
	
	cart_rd4 <= '1' when atari_bank8_enable='1' else 'Z';
	cart_rd5 <= '1' when atari_banka_enable='1' else 'Z';
	
	sd_card_mosi <= 'Z';

-- DONE:Instantiate 65816 (review 2 changes needed - one in particular deleted something, still needed?)

-- SRAM adaptor for 6502 and 65816 (55ns SRAM)

-- veronica reg
-- 64KB - 65816
-- 32KB - bank1 (either 6502 or 65816)
-- 32KB - bank2 (either 6502 or 65816)

-- 65816 memory map:
-- 0x0000-0xffff - first 64k (-below...)
-- 0x0200-0x020f - control reg
--	7-semaphore
--      6-window at 0xc0000-0xffff(0) or 0x4000-7fff
--      5-0=half A,1=half B
--      4-0 res (read as 1)
-- 6502 memory map:
-- in cart space...

-- How to mux ram access? 1/8 6502 and 7/8 65816?

end vhdl;
