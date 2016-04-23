library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_textio.all;

library std_developerskit ; -- used for to_string
--  use std_developerskit.std_iopak.all;

entity veronica_tb is
end;

architecture rtl of veronica_tb is

  constant CLK_PERIOD : time := 1 us / (40);
  constant CLK_CART_PERIOD : time := 1 us / (1.79*32);

  signal reset_n : std_logic;
  signal clk : std_logic;
  signal clk_cart : std_logic;

	signal EXT_SRAM_ADDR: std_logic_vector(19 downto 0);
	signal EXT_SRAM_DATA: std_logic_vector(7 downto 0);
	signal EXT_SRAM_CE: std_logic;
	signal EXT_SRAM_OE: std_logic;
	signal EXT_SRAM_WE: std_logic;

	signal CART_ADDR: std_logic_vector(12 downto 0);
	signal CART_DATA: std_logic_vector(7 downto 0);
	signal CART_RD5: std_logic;
	signal CART_RD4: std_logic;
	signal CART_S5: std_logic;
	signal CART_S4: std_logic;
	signal CART_PHI2: std_logic;
	signal CART_CTL: std_logic;
	signal CART_RW: std_logic;

	signal LED : std_logic_vector(0 downto 0);
	signal SD_CARD_cs: std_logic;
	signal SD_CARD_sclk: std_logic;
	signal SD_CARD_mosi: std_logic;
	signal SD_CARD_miso: std_logic;
				
	-- 6502 bus other side
	signal enable_179_early : std_logic;
	signal cart_request : std_logic;
	signal pbi_addr_out : std_logic_vector(15 downto 0);
	signal cart_data_write : std_logic_vector(7 downto 0);
	signal pbi_write_enable : std_logic;
	signal s4_n : std_logic;
	signal s5_n : std_logic;
	signal cctl_n : std_logic;
	signal cart_data_read : std_logic_vector(7 downto 0);
	signal cart_complete : std_logic;

	signal bus_data_in : std_logic_vector(7 downto 0);
	signal bus_data_out : std_logic_vector(7 downto 0);
	signal bus_data_oe : std_logic;
	signal bus_addr_out : std_logic_vector(15 downto 0);
	signal bus_addr_oe : std_logic;
	signal bus_write_n : std_logic;
	signal bus_s4_n : std_logic;
	signal bus_s5_n : std_logic;
	signal bus_cctl_n : std_logic;
	signal bus_control_oe : std_logic;

begin
	p_clk_gen_a : process
	begin
	clk <= '1';
	wait for CLK_PERIOD/2;
	clk <= '0';
	wait for CLK_PERIOD - (CLK_PERIOD/2 );
	end process;

	p_clk_gen_b : process
	begin
	clk_cart <= '1';
	wait for CLK_CART_PERIOD/2;
	clk_cart <= '0';
	wait for CLK_CART_PERIOD - (CLK_CART_PERIOD/2 );
	end process;

	reset_n <= '0', '1' after 1000ns;

	process_enable : process
	begin
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '1'; -- HERE!
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';


	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';


	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';


	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';
	wait until clk_cart'event and clk_cart = '1';
	enable_179_early <= '0';

	end process;

	process_setup_sram : process
	begin
	cart_request <= '0';
	pbi_addr_out <= (others=>'0');
	cart_data_write <= (others=>'0');
	pbi_write_enable <= '0';
	s4_n <= '1';
	s5_n <= '1';
	cctl_n <= '1';

	wait for 3000ns;

	wait until enable_179_early'event and enable_179_early = '1';
	cart_request <= '1';
	pbi_addr_out <= x"D5C1";
	cart_data_write <= x"ec";
	pbi_write_enable <= '1';
	cctl_n <= '0';

	wait until enable_179_early'event and enable_179_early = '1';
	cart_request <= '1';
	pbi_write_enable <= '0';

	wait until enable_179_early'event and enable_179_early = '1';
	pbi_addr_out <= x"D5c0";

	wait until enable_179_early'event and enable_179_early = '1';
	--cart_data_write <= x"ec";
	cart_data_write <= x"ed";
	pbi_write_enable <= '1';

	wait until enable_179_early'event and enable_179_early = '1';
	pbi_write_enable <= '0';

	wait until enable_179_early'event and enable_179_early = '1';
	cart_request <= '0';
	cctl_n <= '1';

	wait for 100000000us;

	end process;

	thebigone: entity work.veronica
	port map
	(
		CLK => clk,
		LED => LED,


		CART_ADDR => CART_ADDR,
		CART_DATA => CART_DATA,
		CART_RD5 => CART_RD5,
		CART_RD4 => CART_RD4,
		CART_S5 => CART_S5,
		CART_S4 => CART_S4,
		CART_PHI2 => CART_PHI2,
		CART_CTL => CART_CTL,
		CART_RW => CART_RW,
		
		SD_CARD_cs => SD_CARD_cs,
		SD_CARD_sclk => SD_CARD_sclk,
		SD_CARD_mosi => SD_CARD_mosi,
		SD_CARD_miso => SD_CARD_miso,
		
		EXT_SRAM_ADDR => EXT_SRAM_ADDR,
		EXT_SRAM_DATA => EXT_SRAM_DATA,
		EXT_SRAM_CE => EXT_SRAM_CE,
		EXT_SRAM_OE => EXT_SRAM_OE,
		EXT_SRAM_WE => EXT_SRAM_WE
	);

	bus_adaptor : ENTITY work.timing6502
	GENERIC MAP
	(
		CYCLE_LENGTH => 32,
		CONTROl_BITS => 3
	)
	PORT MAP
	( 
		CLK => clk_cart,
		RESET_N => reset_n,
	
		-- FPGA side
		ENABLE_179_EARLY =>enable_179_early,
	
		REQUEST => cart_request,
		ADDR_IN => pbi_addr_out,
		DATA_IN => cart_data_write,
		WRITE_IN => pbi_write_enable,
		CONTROL_N_IN => s4_n&s5_n&cctl_n,
	
		DATA_OUT => cart_data_read,
		COMPLETE => cart_complete,
	
		-- 6502 side
		BUS_DATA_IN => CART_DATA,
		
		BUS_PHI1 => open,
		BUS_PHI2 => CART_PHI2,
		BUS_SUBCYCLE => open,
		BUS_ADDR_OUT => bus_addr_out,
		BUS_ADDR_OE => bus_addr_oe,
		BUS_DATA_OUT => bus_data_out,
		BUS_DATA_OE => bus_data_oe,
		BUS_WRITE_N => CART_RW,
		BUS_CONTROL_N(2) => bus_s4_n,
		BUS_CONTROL_N(1) => bus_s5_n,
		BUS_CONTROL_N(0) => bus_cctl_n,
		BUS_CONTROL_OE => bus_control_oe
	);
	CART_ADDR <= bus_addr_out(12 downto 0) when bus_addr_oe='1' else (others=>'Z');
	CART_DATA <= bus_data_out when bus_data_oe='1' else (others=>'Z');
	CART_S4 <= bus_s4_n when bus_control_oe='1' else 'Z';
	CART_S5 <= bus_s5_n when bus_control_oe='1' else 'Z';
	CART_CTL <= bus_cctl_n when bus_control_oe='1' else 'Z';

--	sram_model : entity work.sram
--	generic map
--	(
--		clear_on_power_up: boolean := FALSE;    -- if TRUE, RAM is initialized with zeroes at start of simulation
--		                                        -- Clearing of RAM is carried out before download takes place
--		
--		download_on_power_up: boolean := TRUE;  -- if TRUE, RAM is downloaded at start of simulation 
--		  
--		trace_ram_load: boolean := TRUE;        -- Echoes the data downloaded to the RAM on the screen
--		                                        -- (included for debugging purposes)
--		
--		
--		enable_nWE_only_control: boolean := TRUE;  -- Read-/write access controlled by nWE only
--		                                           -- nOE may be kept active all the time
--		
--		
--		
--		-- Configuring RAM size
--		
--		size:      INTEGER :=  8;  -- number of memory words
--		adr_width: INTEGER :=  3;  -- number of address bits
--		width:     INTEGER :=  8;  -- number of bits per memory word
--		
--		
--		-- READ-cycle timing parameters
--		
--		tAA_max:    TIME := 20 NS; -- Address Access Time
--		tOHA_min:   TIME :=  3 NS; -- Output Hold Time
--		tACE_max:   TIME := 20 NS; -- nCE/CE2 Access Time
--		tDOE_max:   TIME :=  8 NS; -- nOE Access Time
--		tLZOE_min:  TIME :=  0 NS; -- nOE to Low-Z Output
--		tHZOE_max:  TIME :=  8 NS; --  OE to High-Z Output
--		tLZCE_min:  TIME :=  3 NS; -- nCE/CE2 to Low-Z Output
--		tHZCE_max:  TIME := 10 NS; --  CE/nCE2 to High Z Output
--		
--		
--		-- WRITE-cycle timing parameters
--		
--		tWC_min:    TIME := 20 NS; -- Write Cycle Time
--		tSCE_min:   TIME := 18 NS; -- nCE/CE2 to Write End
--		tAW_min:    TIME := 15 NS; -- tAW Address Set-up Time to Write End
--		tHA_min:    TIME :=  0 NS; -- tHA Address Hold from Write End
--		tSA_min:    TIME :=  0 NS; -- Address Set-up Time
--		tPWE_min:   TIME := 13 NS; -- nWE Pulse Width
--		tSD_min:    TIME := 10 NS; -- Data Set-up to Write End
--		tHD_min:    TIME :=  0 NS; -- Data Hold from Write End
--		tHZWE_max:  TIME := 10 NS; -- nWE Low to High-Z Output
--		tLZWE_min:  TIME :=  0 NS  -- nWE High to Low-Z Output
--	);
--	port map
--	(
--		nCE: IN std_logic := '1';  -- low-active Chip-Enable of the SRAM device; defaults to '1' (inactive)
--		nOE: IN std_logic := '1';  -- low-active Output-Enable of the SRAM device; defaults to '1' (inactive)
--		nWE: IN std_logic := '1';  -- low-active Write-Enable of the SRAM device; defaults to '1' (inactive)
--		
--		A:   IN std_logic_vector(adr_width-1 downto 0); -- address bus of the SRAM device
--		D:   INOUT std_logic_vector(width-1 downto 0);  -- bidirectional data bus to/from the SRAM device
--		
--		CE2: IN std_logic := '1';  -- high-active Chip-Enable of the SRAM device; defaults to '1'  (active) 
--		
--		
--		download: IN boolean := FALSE;    -- A FALSE-to-TRUE transition on this signal downloads the data
--		                                  -- in file specified by download_filename to the RAM
--		
--		download_filename: IN string := "sram_load.dat";  -- name of the download source file
--		                                                  --            Passing the filename via a port of type
--		                                                  -- ********** string may cause a problem with some
--		                                                  -- WATCH OUT! simulators. The string signal assigned
--		                                                  -- ********** to the port at least should have the
--		                                                  --            same length as the default value.
--		
--		dump: IN boolean := FALSE;       -- A FALSE-to-TRUE transition on this signal dumps
--		                                 -- the current content of the memory to the file
--		                                 -- specified by dump_filename.
--		dump_start: IN natural := 0;     -- Written to the dump-file are the memory words from memory address 
--		dump_end: IN natural := size-1;  -- dump_start to address dump_end (default: all addresses)
--		
--		dump_filename: IN string := "sram_dump.dat"  -- name of the dump destination file
--                                                 -- (See note at port  download_filename)
--	);

end rtl;

