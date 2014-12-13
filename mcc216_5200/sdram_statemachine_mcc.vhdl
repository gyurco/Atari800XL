---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY sdram_statemachine_mcc IS
generic
(
	ADDRESS_WIDTH : natural := 22;
	ROW_WIDTH : natural := 12;
	AP_BIT : natural := 10;
	COLUMN_WIDTH : natural := 8
);
PORT 
( 
	CLK_SYSTEM : IN STD_LOGIC;
	CLK_SDRAM : IN STD_LOGIC; -- this is a exact multiple of system clock
	RESET_N : in STD_LOGIC;
	
	-- interface as though SRAM - this module can take care of caching/write combining etc etc. For first cut... nothing. TODO: What extra info would help me here?
	DATA_IN : in std_logic_vector(31 downto 0);
	ADDRESS_IN : in std_logic_vector(ADDRESS_WIDTH downto 0); -- 1 extra bit for byte alignment
	READ_EN : in std_logic; -- if no reads pending may be a good time to do a refresh
	WRITE_EN : in std_logic;
	REQUEST : in std_logic; -- Toggle this to issue a new request
	BYTE_ACCESS : in std_logic; -- ldqm/udqm set based on a(0) - if 0=0111, if 1=1011. Data fields valid:7 downto 0.
	WORD_ACCESS : in std_logic; -- ldqm/udqm set based on a(0) - if 0=0011, if 1=1001. Data fields valid:15 downto 0.
	LONGWORD_ACCESS : in std_logic; -- a(0) ignored. lqdm/udqm mask is 0000
	REFRESH : in std_logic;

	REPLY : out std_logic; -- This matches the request once complete
	DATA_OUT : out std_logic_vector(31 downto 0);

	-- sdram itself
	SDRAM_ADDR : out std_logic_vector(ROW_WIDTH downto 0);
	SDRAM_DQ : inout std_logic_vector(15 downto 0);
	SDRAM_BA0 : out std_logic;
	SDRAM_BA1 : out std_logic;
	
	SDRAM_CS_N : out std_logic;
	SDRAM_RAS_N : out std_logic;
	SDRAM_CAS_N : out std_logic;
	SDRAM_WE_N : out std_logic;
	
	SDRAM_ldqm : out std_logic; -- low enable, high disable - for byte addressing - NB, cas latency applies to reads
	SDRAM_udqm : out std_logic
);
END sdram_statemachine_mcc;

ARCHITECTURE vhdl OF sdram_statemachine_mcc IS
component sdram_ctrl
port
(
--    //-----------------------------
--    // Clock and reset
--    //-----------------------------
--    input         rst,             // Global reset
--    input         clk,             // Master clock (72 MHz)
--    
--    output        ram_rdy_n,       // SDRAM ready
--    output        ram_ref,         // SDRAM refresh
--    output  [3:0] ram_cyc,         // SDRAM cycles
--    output  [3:0] ram_ph,          // SDRAM phases
--    output  [8:0] ram_ph_ctr,      // Phase counter
    rst : in std_logic;
	 clk : in std_logic;
	 
	 ram_rdy_n : out std_logic;
	 ram_ref : out std_logic;
	 ram_cyc : out std_logic_vector(3 downto 0);
	 ram_ph : out std_logic_vector(3 downto 0);
	 ram_ph_ctr : out std_logic_vector(8 downto 0);
	
	rden_b0 : in std_logic;
	wren_b0 : in std_logic;
	addr_b0 : in std_logic_vector(22 downto 2);
	valid_b0 : out std_logic;
	fetch_b0 : out std_logic;
	rdata_b0 : out std_logic_vector(15 downto 0);
	wdata_b0 : in std_logic_vector(15 downto 0);
	bena_b0 : in std_logic_vector(1 downto 0);

	rden_b1 : in std_logic;
	wren_b1 : in std_logic;
	addr_b1 : in std_logic_vector(22 downto 2);
	valid_b1 : out std_logic;
	fetch_b1 : out std_logic;
	rdata_b1 : out std_logic_vector(15 downto 0);
	wdata_b1 : in std_logic_vector(15 downto 0);
	bena_b1 : in std_logic_vector(1 downto 0);

	rden_b2 : in std_logic;
	wren_b2 : in std_logic;
	addr_b2 : in std_logic_vector(22 downto 2);
	valid_b2 : out std_logic;
	fetch_b2 : out std_logic;
	rdata_b2 : out std_logic_vector(15 downto 0);
	wdata_b2 : in std_logic_vector(15 downto 0);
	bena_b2 : in std_logic_vector(1 downto 0);

	rden_b3 : in std_logic;
	wren_b3 : in std_logic;
	addr_b3 : in std_logic_vector(22 downto 2);
	valid_b3 : out std_logic;
	fetch_b3 : out std_logic;
	rdata_b3 : out std_logic_vector(15 downto 0);
	wdata_b3 : in std_logic_vector(15 downto 0);
	bena_b3 : in std_logic_vector(1 downto 0);
	
--    //-----------------------------
--    // Access bank #0
--    //-----------------------------
--    input         rden_b0,         // Read enable
--    input         wren_b0,         // Write enable
--    input  [22:2] addr_b0,         // Address (up to 8 MB)
--    output        valid_b0,        // Read data valid
--    output        fetch_b0,        // Write data fetch
--    output [15:0] rdata_b0,        // Read data
--    input  [15:0] wdata_b0,        // Write data
--    input   [1:0] bena_b0,         // Byte enable
--    
--    //-----------------------------
--    // Access bank #1
--    //-----------------------------
--    input         rden_b1,         // Read enable
--    input         wren_b1,         // Write enable
--    input  [22:2] addr_b1,         // Address (up to 8 MB)
--    output        valid_b1,        // Read data valid
--    output        fetch_b1,        // Write data fetch
--    output [15:0] rdata_b1,        // Read data
--    input  [15:0] wdata_b1,        // Write data
--    input   [1:0] bena_b1,         // Byte enable
--    
--    //-----------------------------
--    // Access bank #2
--    //-----------------------------
--    input         rden_b2,         // Read enable
--    input         wren_b2,         // Write enable
--    input  [22:2] addr_b2,         // Address (up to 8 MB)
--    output        valid_b2,        // Read data valid
--    output        fetch_b2,        // Write data fetch
--    output [15:0] rdata_b2,        // Read data
--    input  [15:0] wdata_b2,        // Write data
--    input   [1:0] bena_b2,         // Byte enable
--    
--    //-----------------------------
--    // Access bank #3
--    //-----------------------------
--    input         rden_b3,         // Read enable
--    input         wren_b3,         // Write enable
--    input  [22:2] addr_b3,         // Address (up to 8 MB)
--    output        valid_b3,        // Read data valid
--    output        fetch_b3,        // Write data fetch
--    output [15:0] rdata_b3,        // Read data
--    input  [15:0] wdata_b3,        // Write data
--    input   [1:0] bena_b3,         // Byte enable
    
--    //-----------------------------
--    // SDRAM memory signals
--    //-----------------------------
--    output            sdram_cs_n,  // SDRAM chip select
--    output reg        sdram_ras_n, // SDRAM row address strobe
--    output reg        sdram_cas_n, // SDRAM column address strobe
--    output reg        sdram_we_n,  // SDRAM write enable
--    //
--    output reg  [1:0] sdram_ba,    // SDRAM bank address
--    output reg [12:0] sdram_addr,  // SDRAM address
--    //
--    output reg  [3:0] sdram_dqm_n, // SDRAM DQ masks
--    output reg        sdram_dq_oe, // SDRAM data output enable
--    output reg [31:0] sdram_dq_o,  // SDRAM data output
--    input      [31:0] sdram_dq_i   // SDRAM data input

	sdram_cs_n : out std_logic;
	sdram_ras_n : out std_logic;
	sdram_cas_n : out std_logic;
	sdram_we_n : out std_logic;
	sdram_ba : out std_logic_vector(1 downto 0);
	sdram_addr : out std_logic_vector(12 downto 0);
	sdram_dqm_n : out std_logic_vector(3 downto 0);
	sdram_dq_oe : out std_logic;
	sdram_dq_o : out std_logic_vector(31 downto 0);
	sdram_dq_i : in std_logic_vector(31 downto 0)
);
end component;

signal SDRAM_CKE_dummy : std_logic;

signal sdram_valid_b0_dummy : std_logic;
signal sdram_valid_b1_dummy : std_logic;
signal sdram_valid_b2_dummy : std_logic;
signal sdram_valid_b3_dummy : std_logic;

signal sdram_fetch_b0_dummy : std_logic;
signal sdram_fetch_b1_dummy : std_logic;
signal sdram_fetch_b2_dummy : std_logic;
signal sdram_fetch_b3_dummy : std_logic;

signal sdram_read_b0_dummy : std_logic_vector(15 downto 0);
signal sdram_read_b1_dummy : std_logic_vector(15 downto 0);
signal sdram_read_b2_dummy : std_logic_vector(15 downto 0);
signal sdram_read_b3_dummy : std_logic_vector(15 downto 0);

signal reset : std_logic;

signal sdram_ctl_rdy_dummy : std_logic;
signal sdram_ctl_ref_dummy : std_logic;
signal sdram_ctl_cyc_dummy : std_logic_vector(3 downto 0);
signal sdram_ctl_ph_dummy : std_logic_vector(3 downto 0);
signal sdram_ctl_ph_ctr_dummy : std_logic_vector(8 downto 0);

signal SDRAM_VALID : std_logic;
signal SDRAM_FETCH : std_logic;

signal SDRAM_dq_oe : std_logic;
signal sdram_dq_o : std_logic_vector(31 downto 0);
signal sdram_dq_i : std_logic_vector(31 downto 0);
signal sdram_dqm_N_temp : std_logic_vector(3 downto 0);

signal sdram_ba : std_logic_vector(1 downto 0);

signal sdram_enable_byte : std_logic_vector(1 downto 0);

signal sdram_reply_reg : std_logic;
signal state_reg : std_logic_vector(2 downto 0);
signal store_data_in_reg : std_logic_vector(47 downto 0);
signal data_out_reg : std_logic_vector(31 downto 0);
signal sdram_reply_next : std_logic;
signal state_next : std_logic_vector(2 downto 0);
signal store_data_in_next : std_logic_vector(47 downto 0);
signal data_out_next : std_logic_vector(31 downto 0);

constant state_idle : std_logic_vector(2 downto 0) := "000";
constant state_write_wait_1 : std_logic_vector(2 downto 0) := "001";
constant state_write_wait_2 : std_logic_vector(2 downto 0) := "010";
constant state_write_wait_3 : std_logic_vector(2 downto 0) := "111";
constant state_read_wait_1 : std_logic_vector(2 downto 0) := "011";
constant state_read_wait_2 : std_logic_vector(2 downto 0) := "100";
constant state_read_wait_3 : std_logic_vector(2 downto 0) := "101";
constant state_read_wait_4 : std_logic_vector(2 downto 0) := "110";


signal internal_data_in : std_logic_vector(15 downto 0);
signal internal_data_out : std_logic_vector(15 downto 0);

signal write_en_next : std_logic;
signal write_en_reg : std_logic;

signal read_en_next : std_logic;
signal read_en_reg : std_logic;

signal SDRAM_ADDR_temp : std_logic_vector(12 downto 0);

begin


reset <= not(reset_n);

process(clk_system, reset_n)
begin
	if (reset_n = '0') then
		sdram_reply_reg <= '0';
		state_reg <= state_idle;
		store_data_in_reg <= (others=>'0');
		data_out_reg <= (others=>'0');
		write_en_reg <= '0';
		read_en_reg <= '0';
	elsif (clk_system'event and clk_system = '1') then
		sdram_reply_reg <= sdram_reply_next;
		state_reg <= state_next;
		store_data_in_reg <= store_data_in_next;
		data_out_reg <= data_out_next;
		write_en_reg <= write_en_next;
		read_en_reg <= read_en_next;		
	end if;
end process;	

data_out <= data_out_reg;
reply <= sdram_reply_reg;

process(read_en_reg, write_en_reg, state_reg, request, write_en, store_data_in_reg, internal_data_in, data_in, sdram_reply_reg, byte_access, longword_access, address_in, sdram_valid, sdram_fetch)
begin
	sdram_reply_next <= sdram_reply_reg;
	state_next <= state_reg;
	store_data_in_next <= store_data_in_reg;
	data_out_next <= (others=>'0');
	
	read_en_next <= read_en_reg;
	write_en_next <= write_en_reg;
	
	internal_data_out <= (others=>'0');
	sdram_enable_byte <= "11";

	case state_reg is
	when state_idle => 
		sdram_reply_next <= '0';
		if (request = '1') then
			if (write_en = '1') then
				-- 4 byte write
				state_next <= state_write_wait_1;
				write_en_next <= '1';
			else
				-- 8 byte read
				state_next <= state_read_wait_1;
				read_en_next <= '1';
				-- TODO - read from cached?
			end if;
		end if;
	when state_write_wait_1 =>
		if (sdram_fetch = '1') then
			state_next <= state_write_wait_2;
		end if;
		internal_data_out <= data_in(31 downto 16);
	when state_write_wait_2 =>
		state_next <= state_write_wait_3;
		if (byte_access = '1') then			
			internal_data_out <= data_in(7 downto 0)&data_in(7 downto 0);
			case address_in(1 downto 0) is
			when "00" =>
				sdram_enable_byte <= "01";
			when "01" =>	
				sdram_enable_byte <= "10";				
			when "10" =>
				sdram_enable_byte <= "00";								
			when "11" =>	
				sdram_enable_byte <= "00";												
			end case;	
		elsif (longword_access = '1') then
			internal_data_out <= data_in(15 downto 0);
		end if;
		sdram_reply_next <= '1';	
	when state_write_wait_3 =>
		state_next <= state_idle;
		write_en_next <= '0';		
		if (byte_access = '1') then			
			internal_data_out <= data_in(7 downto 0)&data_in(7 downto 0);
			case address_in(1 downto 0) is
			when "00" =>
				sdram_enable_byte <= "00";
			when "01" =>	
				sdram_enable_byte <= "00";				
			when "10" =>
				sdram_enable_byte <= "01";								
			when "11" =>	
				sdram_enable_byte <= "10";												
			end case;	
		elsif (longword_access = '1') then
			internal_data_out <= data_in(31 downto 16);
		end if;
		sdram_reply_next <= '0';
	when state_read_wait_1 =>
		if (sdram_valid = '1') then
			state_next <= state_read_wait_2;
			store_data_in_next(15 downto 0) <= internal_data_in;
		end if;
	when state_read_wait_2 =>
		state_next <= state_read_wait_3;
		store_data_in_next(31 downto 16) <= internal_data_in;
	when state_read_wait_3 =>
		state_next <= state_read_wait_4;
		store_data_in_next(47 downto 32) <= internal_data_in;
	when state_read_wait_4 =>
		read_en_next <= '0';
		state_next <= state_idle;
		--store_data_in_next(63 downto 48) <= internal_data_in;
		sdram_reply_next <= '1';
		if (byte_access = '1') then
			case address_in(2 downto 0) is
			when "000" =>
				data_out_next(7 downto 0) <= store_data_in_reg(7 downto 0);
			when "001" =>
				data_out_next(7 downto 0) <= store_data_in_reg(15 downto 8);
			when "010" =>
				data_out_next(7 downto 0) <= store_data_in_reg(23 downto 16);
			when "011" =>
				data_out_next(7 downto 0) <= store_data_in_reg(31 downto 24);
			when "100" =>
				data_out_next(7 downto 0) <= store_data_in_reg(39 downto 32);
			when "101" =>
				data_out_next(7 downto 0) <= store_data_in_reg(47 downto 40);
			when "110" =>
				data_out_next(7 downto 0) <= internal_data_in(7 downto 0);
			when "111" =>
				data_out_next(7 downto 0) <= internal_data_in(15 downto 8);
			end case;
		elsif (longword_access = '1') then
			case address_in(2 downto 0) is -- aligned only!
			when "000" =>
				data_out_next <= store_data_in_reg(31 downto 0);
			when "100" =>
				data_out_next <= internal_data_in&store_data_in_reg(47 downto 32);
			when others =>
				-- NOP
			end case;		
		end if;
	end case;	
end process;


sdram_mcc : sdram_ctrl 
	PORT map
	(
		rst => reset,
		clk => clk_SYSTEM,
		
		ram_rdy_n => sdram_ctl_rdy_dummy,
		ram_ref => sdram_ctl_ref_dummy,
		ram_cyc => sdram_ctl_cyc_dummy,
		ram_ph => sdram_ctl_ph_dummy,
		ram_ph_ctr => sdram_ctl_ph_ctr_dummy,

		 --BYTE_ACCESS : IN STD_LOGIC;
		 --WORD_ACCESS : IN STD_LOGIC;
		 --LONGWORD_ACCESS : IN STD_LOGIC;		
		 
		rden_b0 => READ_EN_reg,
		wren_b0 => WRITE_EN_reg,
		addr_b0 => ADDRESS_IN(22 downto 2),
		valid_b0 => SDRAM_VALID,
		fetch_b0 => SDRAM_FETCH,
		rdata_b0 => INTERNAL_DATA_IN(15 downto 0),
		wdata_b0 => INTERNAL_DATA_OUT(15 downto 0),
		bena_b0 => sdram_enable_byte,

		rden_b1 => '0',
		wren_b1 => '0',
		addr_b1 => (others=>'0'),
		valid_b1 => sdram_valid_b1_dummy,
		fetch_b1 => sdram_fetch_b1_dummy,
		rdata_b1 => sdram_read_b1_dummy,
		wdata_b1 => (others=>'0'),
		bena_b1 => "00",

		rden_b2 => '0',
		wren_b2 => '0',
		addr_b2 => (others=>'0'),
		valid_b2 => sdram_valid_b2_dummy,
		fetch_b2 => sdram_fetch_b2_dummy,
		rdata_b2 => sdram_read_b2_dummy,
		wdata_b2 => (others=>'0'),
		bena_b2 => "00",

		rden_b3 => '0',
		wren_b3 => '0',
		addr_b3 => (others=>'0'),
		valid_b3 => sdram_valid_b3_dummy,
		fetch_b3 => sdram_fetch_b3_dummy,		
		rdata_b3 => sdram_read_b3_dummy,
		wdata_b3 => (others=>'0'),
		bena_b3 => "00",	
		
		sdram_cs_n => SDRAM_CS_N,
		sdram_ras_n => SDRAM_RAS_N,
		sdram_cas_n => SDRAM_CAS_N,
		sdram_we_n => SDRAM_WE_N,
		sdram_ba => SDRAM_BA,
		sdram_addr => SDRAM_ADDR_temp,
		sdram_dqm_n => sdram_dqm_N_temp,
		sdram_dq_oe => sdram_dq_oe,
		sdram_dq_o => sdram_dq_o,
		sdram_dq_i => sdram_dq_i
);
sdram_dq <= sdram_dq_o(15 downto 0) when sdram_dq_oe='1' else (others=>'Z');
sdram_dq_i(15 downto 0) <= sdram_dq;
sdram_dq_i(31 downto 16) <= (others=>'0');
SDRAM_LDQM<= sdram_dqm_N_temp(0);
SDRAM_UDQM<= sdram_dqm_N_temp(1);
SDRAM_BA0 <= sdram_ba(0);
SDRAM_BA1 <= sdram_ba(1);

SDRAM_ADDR(12) <= '1';
SDRAM_ADDR(11 downto 0) <= SDRAM_ADDR_temp(11 downto 0);

end vhdl;