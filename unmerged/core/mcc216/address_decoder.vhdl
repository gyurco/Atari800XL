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
use IEEE.STD_LOGIC_MISC.all;


ENTITY address_decoder IS
PORT 
( 
	CLK : IN STD_LOGIC;
	
	-- bus masters - either CPU or antic
	-- antic has priority and is slected when ANTIC_FETCH high
	CPU_ADDR : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
	CPU_FETCH : in std_logic;
	CPU_WRITE_N : IN STD_LOGIC;
	CPU_WRITE_DATA : in std_logic_vector(7 downto 0);	
	
	ANTIC_ADDR : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
	ANTIC_FETCH : IN STD_LOGIC;
	antic_refresh : in std_logic; -- use for sdram refresh (sdram needs more, but this is a start)

	ZPU_ADDR : in std_logic_vector(23 downto 0);	
	ZPU_FETCH : in std_logic;
	ZPU_READ_ENABLE : in std_logic;
	ZPU_32BIT_WRITE_ENABLE : in std_logic; -- common case
	ZPU_16BIT_WRITE_ENABLE : in std_logic; -- for sram
	ZPU_8BIT_WRITE_ENABLE : in std_logic; -- for hardware regs	
	ZPU_WRITE_DATA : in std_logic_vector(31 downto 0);
	
	-- sources of data
	ROM_DATA : IN STD_LOGIC_VECTOR(7 downto 0);	-- flash rom
	GTIA_DATA : IN STD_LOGIC_VECTOR(7 downto 0);
	CACHE_GTIA_DATA : IN STD_LOGIC_VECTOR(7 downto 0);
	POKEY_DATA : IN STD_LOGIC_VECTOR(7 downto 0);
	CACHE_POKEY_DATA : IN STD_LOGIC_VECTOR(7 downto 0);
	POKEY2_DATA : IN STD_LOGIC_VECTOR(7 downto 0);	
	CACHE_POKEY2_DATA : IN STD_LOGIC_VECTOR(7 downto 0);	
	ANTIC_DATA : IN STD_LOGIC_VECTOR(7 downto 0);
	CACHE_ANTIC_DATA : IN STD_LOGIC_VECTOR(7 downto 0);	
	PIA_DATA : IN STD_LOGIC_VECTOR(7 downto 0);
	RAM_DATA : IN STD_LOGIC_VECTOR(15 downto 0);
	CART_ROM_DATA : in std_logic_Vector(7 downto 0);
	
	-- completion flags
	RAM_REQUEST_COMPLETE : IN STD_LOGIC;
	ROM_REQUEST_COMPLETE : IN STD_LOGIC;
	CART_REQUEST_COMPLETE : IN STD_LOGIC;
	
	-- configuration options	
	PORTB : IN STD_LOGIC_VECTOR(7 downto 0);
	
	reset_n : in std_logic;
	
	rom_select : in std_logic_vector(1 downto 0);
	
	ram_select : in std_logic_vector(1 downto 0);
	
	CART_RD4 : in std_logic;
	CART_RD5 : in std_logic;
	
	use_sdram : in std_logic;
		
	-- Memory read mux output
	MEMORY_DATA : OUT STD_LOGIC_VECTOR(31 downto 0);
	
	-- Flash and internal RAM take 2 cycles to access. SRAM takes 1 cycle.
	-- Allow us to say we're not ready for a cycle
	MEMORY_READY_ANTIC : OUT STD_LOGIC;
	MEMORY_READY_ZPU : OUT STD_LOGIC;
	MEMORY_READY_CPU : out std_logic;	
	
	-- Each chip does not have whole address bus, so several are addressed at once
	-- For reads not an issue, but for writes we need to only write to a single place!
		-- these all take 1 cycle, so fine to leave device selected in general
	GTIA_WR_ENABLE : OUT STD_LOGIC;
	POKEY_WR_ENABLE : OUT STD_LOGIC;
	POKEY2_WR_ENABLE : OUT STD_LOGIC;
	ANTIC_WR_ENABLE : OUT STD_LOGIC;
	PIA_WR_ENABLE : OUT STD_LOGIC;
	PIA_RD_ENABLE : OUT STD_LOGIC; -- ... except PIA takes action on reads!
	RAM_WR_ENABLE : OUT STD_LOGIC;	
	PBI_WR_ENABLE : OUT STD_LOGIC;
	
	-- ROM and RAM have extended address busses to allow for bank switching etc.
	ROM_ADDR : OUT STD_LOGIC_VECTOR(21 downto 0);
	RAM_ADDR : OUT STD_LOGIC_VECTOR(18 downto 0);
	PBI_ADDR : out  std_logic_vector(15 downto 0);
	
	RAM_REQUEST : out std_logic;
	ROM_REQUEST : out std_logic;
	CART_REQUEST : out std_logic;
	
	CART_S4_n : out std_logic;
	CART_S5_n : out std_logic;
	CART_CCTL_n : out std_logic;
	
	-- width of access
	WIDTH_8bit_ACCESS : out std_logic;
	WIDTH_16bit_ACCESS : out std_logic;
	WIDTH_32bit_ACCESS : out std_logic;
	
		-- interface as though SRAM - this module can take care of caching/write combining etc etc. For first cut... nothing. TODO: What extra info would help me here?
	SDRAM_ADDR : out std_logic_vector(22 downto 0); -- 1 extra bit for byte alignment
	SDRAM_READ_EN : out std_logic; -- if no reads pending may be a good time to do a refresh
	SDRAM_WRITE_EN : out std_logic;
	--SDRAM_REQUEST : out std_logic; -- Toggle this to issue a new request
	SDRAM_REQUEST : out std_logic; -- Usual pattern
	SDRAM_REFRESH : out std_logic;

	--SDRAM_REPLY : in std_logic; -- This matches the request once complete
	SDRAM_REQUEST_COMPLETE : in std_logic;
	SDRAM_DATA : in std_logic_vector(31 downto 0);
	
	WRITE_DATA : out std_logic_vector(31 downto 0)
);

END address_decoder;

ARCHITECTURE vhdl OF address_decoder IS
	signal ADDR_next : std_logic_vector(23 downto 0);
	signal ADDR_reg : std_logic_vector(23 downto 0);

	signal DATA_WRITE_next : std_logic_vector(31 downto 0);
	signal DATA_WRITE_reg : std_logic_vector(31 downto 0);
	
	signal width_8bit_next : std_logic;
	signal width_16bit_next : std_logic;
	signal width_32bit_next : std_logic;
	signal write_enable_next : std_logic;

	signal width_8bit_reg : std_logic;
	signal width_16bit_reg : std_logic;
	signal width_32bit_reg : std_logic;
	signal write_enable_reg : std_logic;
	
	signal request_complete : std_logic;
	signal notify_antic : std_logic;
	signal notify_zpu : std_logic;
	signal notify_cpu : std_logic;
	signal start_request : std_logic;
	
	signal extended_access_cpu_or_antic : std_logic;
	signal extended_access_antic : std_logic;
	signal extended_access_cpu: std_logic; -- 130XE and compy shop switch antic seperately
	
	signal extended_access_either: std_logic; -- RAMBO switches both together using CPU bit

	-- even though we have 3 targets (flash, ram, rom) and 3 masters, only allow access to one a a time - simpler.
	signal state_next : std_logic_vector(1 downto 0);
	signal state_reg : std_logic_vector(1 downto 0);
	constant state_idle : std_logic_vector(1 downto 0) := "00";
	constant state_waiting_cpu : std_logic_vector(1 downto 0) := "01";
	constant state_waiting_zpu : std_logic_vector(1 downto 0) := "10";
	constant state_waiting_antic : std_logic_vector(1 downto 0) := "11";
		
	signal ram_chip_select : std_logic;
	signal sdram_chip_select : std_logic;
	
--	signal sdram_request_next : std_logic;
--	signal sdram_request_reg : std_logic;
--	signal SDRAM_REQUEST_COMPLETE	: std_logic;
	
	signal fetch_priority : std_logic_vector(2 downto 0);
	
	signal fetch_wait_next : std_logic_vector(8 downto 0);
	signal fetch_wait_reg : std_logic_vector(8 downto 0);	
	
BEGIN
		-- register
	process(clk,reset_n)
	begin
		if (reset_n='0') then
			addr_reg <= (others=>'0');
			state_reg <= state_idle;
			width_8bit_reg <= '0';
			width_16bit_reg <= '0';
			width_32bit_reg <= '0';
			write_enable_reg <= '0';
			data_write_reg <= (others=> '0');
			--sdram_request_reg <= '0';
			fetch_wait_reg <= (others=>'0');
		elsif (clk'event and clk='1') then
			addr_reg <= addr_next;
			state_reg <= state_next;
			width_8bit_reg <= width_8bit_next;
			width_16bit_reg <= width_16bit_next;
			width_32bit_reg <= width_32bit_next;
			write_enable_reg <= write_enable_next;
			data_write_reg <= data_WRITE_next;
			--sdram_request_reg <= sdram_request_next;
			fetch_wait_reg <= fetch_wait_next;
		end if;
	end process;
	
	-- ANTIC FETCH
	
	-- concept
	-- bus master sends request - antic or cpu
	-- antic has priority
	-- cpu may be idle
	-- once request complete MEMORY_READY is set
	-- if request interrupted then results are LOST - memory ready not set until priority request satisfied
	
	-- so
	-- memory_ready <= device_ready;
	
	-- problem
	-- request -> device access -> interrupt -> device finishes -> ignored? -> device access
	
	-- state machine
	
	-- state machine impl
	fetch_priority <= ANTIC_FETCH&ZPU_FETCH&CPU_FETCH;
	process(fetch_wait_reg, state_reg, addr_reg, data_write_reg, width_8bit_reg, width_16bit_reg, width_32bit_reg, write_enable_reg, fetch_priority, antic_addr, zpu_addr, cpu_addr, request_complete, zpu_8bit_write_enable,zpu_16bit_write_enable,zpu_32bit_write_enable,zpu_read_enable, cpu_write_n, CPU_WRITE_DATA, ZPU_WRITE_DATA)
	begin
		start_request <= '0';
		notify_antic <= '0';
		notify_cpu <= '0';
		notify_zpu <= '0';
		state_next <= state_reg;
		fetch_wait_next <= std_logic_vector(unsigned(fetch_wait_reg) +1);

		addr_next <= addr_reg;
		data_WRITE_next <= data_WRITE_reg;
		width_8bit_next <= width_8bit_reg;		
		width_16bit_next <= width_16bit_reg;		
		width_32bit_next <= width_32bit_reg;		
		write_enable_next <= write_enable_reg;
		
		case state_reg is
			when state_idle =>
				fetch_wait_next <= (others=>'0');
				write_enable_next <= '0';
				width_8bit_next <= '0';
				width_16bit_next <= '0';
				width_32bit_next <= '0';	
				data_WRITE_next <= (others => '0');
				addr_next <= zpu_ADDR(23 downto 16)&cpu_ADDR(15 downto 0);				
				
				case fetch_priority is
				when "100"|"101"|"110"|"111" => -- antic wins
					start_request <= '1';
					addr_next <= "00000000"&antic_ADDR;
					width_8bit_next <= '1';					
					if (request_complete = '1') then
						notify_antic <= '1';
					else
						state_next <= state_waiting_antic;
					end if;
				when "010"|"011" => -- zpu wins (zpu usually accesses own ROM memory - this is NOT a zpu_fetch)
					start_request <= '1';
					addr_next <= zpu_ADDR;
					data_WRITE_next <= zpu_wRITE_DATA;

					width_8bit_next <= zpu_8BIT_WRITE_ENABLE or (zpu_READ_ENABLE and (zpu_addr(0) or zpu_addr(1)));
					width_16bit_next <= zpu_16BIT_WRITE_ENABLE;
					width_32bit_next <= zpu_32BIT_WRITE_ENABLE or (zpu_READ_ENABLE and not(zpu_addr(0) or zpu_addr(1))); -- narrower devices just return 8 bits on read
					
					write_enable_next <= not(zpu_READ_ENABLE);
					
					if (request_complete = '1') then
						notify_zpu <= '1';
					else
						state_next <= state_waiting_zpu;
					end if;					
				when "001" => -- 6502 wins
					start_request <= '1';
					addr_next <= "00000000"&cpu_ADDR;
					data_WRITE_next(7 downto 0) <= cpu_WRITE_DATA;
					width_8bit_next <= '1';
					write_enable_next <= not(cpu_WRITE_N);
					if (request_complete = '1') then
						notify_cpu <= '1';
					else
						state_next <= state_waiting_cpu;
					end if;
				when "000" =>
					-- no requests
				end case;
			when state_waiting_antic =>
				if (request_complete = '1') then
					notify_antic <= '1';
					state_next <= state_idle;
				end if;
			when state_waiting_zpu =>
				if (request_complete = '1') then
					notify_zpu <= '1';
					state_next <= state_idle;
				end if;
			when state_waiting_cpu =>
				if (request_complete = '1') then
					notify_cpu <= '1';
					state_next <= state_idle;
				end if;				
		end case;
	end process;
	
	-- output
	MEMORY_READY_ANTIC <= notify_antic;
	MEMORY_READY_ZPU <= notify_zpu;
	MEMORY_READY_CPU <= notify_cpu;
	
	RAM_REQUEST <= ram_chip_select;
		
	SDRAM_REQUEST <= sdram_chip_select;
	--SDRAM_REQUEST <= sdram_request_next;
	SDRAM_REFRESH <= fetch_wait_reg(7); -- TODO, BROKEN! antic_refresh;
	SDRAM_READ_EN <= not(write_enable_next);
	SDRAM_WRITE_EN <= write_enable_next;
	
	WIDTH_8bit_ACCESS <= width_8bit_next;
	WIDTH_16bit_ACCESS <= width_16bit_next;
	WIDTH_32bit_ACCESS <= width_32bit_next;	
	
	WRITE_DATA <= DATA_WRITE_next;

	-- a little sdram glue - move to sdram wrapper? TODO
	--SDRAM_REQUEST_COMPLETE <= (SDRAM_REPLY xnor sdram_request_reg) and not(start_request);
	--sdram_request_next <= sdram_request_reg xor sdram_chip_select;	
	
	-- Calculate which memory area to use
	extended_access_cpu_or_antic <= extended_access_antic or extended_access_cpu;
	extended_access_antic <= (antic_fetch and not(portb(5)));
	extended_access_cpu <= not(antic_fetch) and not(portb(4));
	
	extended_access_either <= not(portb(4));
	
  	process(
		-- address and writing absolutely points us at a device
		ADDR_next,WRITE_enable_next, 
	
		-- except for these additional special address bits	
		portb, 
		antic_fetch,
		rom_select,
		extended_access_cpu_or_antic,extended_access_either,ram_select,cart_rd4,cart_rd5,
		use_sdram,
		
		-- input data from n sources
		GTIA_DATA,POKEY_DATA,POKEY2_DATA,PIA_DATA,ANTIC_DATA,CART_ROM_DATA,ROM_DATA,RAM_DATA,SDRAM_DATA,
		CACHE_GTIA_DATA,CACHE_POKEY_DATA,CACHE_POKEY2_DATA,CACHE_ANTIC_DATA,
		
		-- input data from n sources complete?
		-- hardware regs take 1 cycle, so always complete		
		ram_request_complete,sdram_request_complete,rom_request_complete,cart_request_complete,
		
		-- on new access this is set - we must select the appropriate device - for this cycle only
		start_request
	)
	begin
		MEMORY_DATA <= (others => '1');
		
		ROM_ADDR <= (others=>'0');
		RAM_ADDR <= addr_next(18 downto 0);
		SDRAM_ADDR <= addr_next(22 downto 0);
		
		PBI_ADDR <= ADDR_next(15 downto 0);
		
		request_complete <= '0';
		
		GTIA_WR_ENABLE <= '0';
		POKEY_WR_ENABLE <= '0';
		POKEY2_WR_ENABLE <= '0';
		ANTIC_WR_ENABLE <= '0';
		PIA_WR_ENABLE <= '0';
		PIA_RD_ENABLE <= '0';
		PBI_WR_ENABLE <= '0';

		RAM_WR_ENABLE <= write_enable_next;
		SDRAM_WRITE_EN <= write_enable_next;		
		
		CART_S4_n <= '1';
		CART_S5_n <= '1';
		CART_CCTL_n <= '1';
		
		rom_request <= '0';
		cart_request <= '0';
		
		ram_chip_select <= '0';
		sdram_chip_select <= '0';

	--	if (addr_next(23 downto 17) = "0000000" ) then -- bit 16 left out on purpose, so the Atari 64k is available as 64k-128k for zpu. The zpu has rom at 0-64k...
		if (or_reduce(addr_next(23 downto 18)) = '0' ) then -- bit 16,17 left out on purpose, so the Atari 64k is available as 64k-128k for zpu. The zpu has rom at 0-64k...

		RAM_ADDR(18 downto 16) <= "000";	
		SDRAM_ADDR(22 downto 16) <= "0000000";
	
		case addr_next(15 downto 8) is 
				-- GTIA
				when X"D0" =>
					GTIA_WR_ENABLE <= write_enable_next;
					MEMORY_DATA(7 downto 0) <= GTIA_DATA;
					MEMORY_DATA(15 downto 8) <= CACHE_GTIA_DATA;
					request_complete <= '1';
			
				-- POKEY
				when X"D2" =>				
					if (addr_next(4) = '0') then
						POKEY_WR_ENABLE <= write_enable_next;
						MEMORY_DATA(7 downto 0) <= POKEY_DATA;
						MEMORY_DATA(15 downto 8) <= CACHE_POKEY_DATA;
					else
						POKEY2_WR_ENABLE <= write_enable_next;
						MEMORY_DATA(7 downto 0) <= POKEY2_DATA;
						MEMORY_DATA(15 downto 8) <= CACHE_POKEY2_DATA;
					end if;
					request_complete <= '1';

				-- PIA
				when X"D3" =>
					PIA_WR_ENABLE <= write_enable_next;
					PIA_RD_ENABLE <= '1';
					MEMORY_DATA(7 downto 0) <= PIA_DATA;
					request_complete <= '1';
					
				-- ANTIC
				when X"D4" =>
					ANTIC_WR_ENABLE <= write_enable_next;
					MEMORY_DATA(7 downto 0) <= ANTIC_DATA;
					MEMORY_DATA(15 downto 8) <= CACHE_ANTIC_DATA;
					request_complete <= '1';
					
				-- CART_CONFIG -- TODO - wait for n cycles (for now non-turbo mode should work?)
				when X"D5" =>
					if ((CART_RD4 or CART_RD5) = '1') then
						PBI_WR_ENABLE <= write_enable_next;
						MEMORY_DATA(7 downto 0) <= CART_ROM_DATA;
						cart_request <= start_request;
						CART_CCTL_n <= '0';
						request_complete <= CART_REQUEST_COMPLETE;
					else
						MEMORY_DATA(7 downto 0) <= X"FF";
						request_complete <= '1';
					end if;
					
				-- XE RAM
				when 
					X"40"|X"41"|X"42"|X"43"|X"44"|X"45"|X"46"|X"47"|X"48"|X"49"|X"4A"|X"4B"|X"4C"|X"4D"|X"4E"|X"4F"
					|X"58"|X"59"|X"5A"|X"5B"|X"5C"|X"5D"|X"5E"|X"5F"
					|X"60"|X"61"|X"62"|X"63"|X"64"|X"65"|X"66"|X"67"|X"68"|X"69"|X"6A"|X"6B"|X"6C"|X"6D"|X"6E"|X"6F"
					|X"70"|X"71"|X"72"|X"73"|X"74"|X"75"|X"76"|X"77"|X"78"|X"79"|X"7A"|X"7B"|X"7C"|X"7D"|X"7E"|X"7F" =>
					
					if (use_sdram = '1') then
						MEMORY_DATA(7 downto 0) <= SDRAM_DATA(7 downto 0);
						sdram_chip_select <= start_request;
						request_complete <= sdram_request_COMPLETE;														
					else
						MEMORY_DATA(7 downto 0) <= RAM_DATA(7 downto 0);
						ram_chip_select <= start_request;
						request_complete <= ram_request_COMPLETE;									
					end if;
					
					case ram_select is
						when "00" => -- 64k
							-- default
						when "01" => -- 128k					
							RAM_ADDR(18 downto 14) <= extended_access_cpu_or_antic&"00"&portb(3 downto 2);
							SDRAM_ADDR(18 downto 14) <= extended_access_cpu_or_antic&"00"&portb(3 downto 2);						
						when "10" => -- 320k compy shop
							RAM_ADDR(18 downto 14) <= extended_access_cpu_or_antic&portb(7 downto 6)&portb(3 downto 2);
							SDRAM_ADDR(18 downto 14) <= extended_access_cpu_or_antic&portb(7 downto 6)&portb(3 downto 2);
						when "11" => -- 320k rambo
							RAM_ADDR(18 downto 14) <= extended_access_either&portb(6 downto 5)&portb(3 downto 2);				
							SDRAM_ADDR(18 downto 14) <= extended_access_either&portb(6 downto 5)&portb(3 downto 2);				
					end case;
					
				-- SELF TEST ROM 0x5000->0x57ff and XE RAM
				when 
					X"50"|X"51"|X"52"|X"53"|X"54"|X"55"|X"56"|X"57" =>
									
					if (portb(7) = '0' and portb(0) = '1') then
						--request_complete <= ROM_REQUEST_COMPLETE;
						--MEMORY_DATA(7 downto 0) <= ROM_DATA;
						--rom_request <= start_request;					
						MEMORY_DATA(7 downto 0) <= SDRAM_DATA(7 downto 0);
						
						if (write_enable_next = '1') then
							request_complete <= '1';
						else
							request_complete <= sdram_request_COMPLETE;							
							sdram_chip_select <= start_request;							
						end if;
						--ROM_ADDR <= "000000"&"00010"&ADDR(10 downto 0); -- x01000 based 2k (i.e. self test is 4k in - usually under hardware regs)
						case rom_select is
							when "00" =>
								ROM_ADDR <= "000000"&"00"&"010"&ADDR_next(10 downto 0); -- x01000 based 2k
						    SDRAM_ADDR <="0010000"&"00"&"010"&ADDR_next(10 downto 0); -- x01000 based 2k
							when "01" =>
								ROM_ADDR <= "000000"&"01"&"010"&ADDR_next(10 downto 0); -- x05000 based 2k
							 SDRAM_ADDR <="0010000"&"01"&"010"&ADDR_next(10 downto 0); -- x05000 based 2k								
							when "10" =>
								ROM_ADDR <= "000000"&"10"&"010"&ADDR_next(10 downto 0); -- x09000 based 2k
							 SDRAM_ADDR <="0010000"&"10"&"010"&ADDR_next(10 downto 0); -- x09000 based 2k							
							when "11" =>
								ROM_ADDR <= "000001"&"00"&"010"&ADDR_next(10 downto 0); -- x11000 based 2k (0xd000 already taken by basic!)
							SDRAM_ADDR <= "0010001"&"00"&"010"&ADDR_next(10 downto 0); -- x11000 based 2k (0xd000 already taken by basic!)								
						end case;														
					else				
						if (use_sdram = '1') then
							MEMORY_DATA(7 downto 0) <= SDRAM_DATA(7 downto 0);
							sdram_chip_select <= start_request;
							request_complete <= sdram_request_COMPLETE;														
						else
							MEMORY_DATA(7 downto 0) <= RAM_DATA(7 downto 0);
							ram_chip_select <= start_request;
							request_complete <= ram_request_COMPLETE;									
						end if;
						
						case ram_select is
							when "00" => -- 64k
								-- default
							when "01" => -- 128k					
								RAM_ADDR(18 downto 14) <= extended_access_cpu_or_antic&"00"&portb(3 downto 2);
								SDRAM_ADDR(18 downto 14) <= extended_access_cpu_or_antic&"00"&portb(3 downto 2);						
							when "10" => -- 320k compy shop
								RAM_ADDR(18 downto 14) <= extended_access_cpu_or_antic&portb(7 downto 6)&portb(3 downto 2);
								SDRAM_ADDR(18 downto 14) <= extended_access_cpu_or_antic&portb(7 downto 6)&portb(3 downto 2);
							when "11" => -- 320k rambo
								RAM_ADDR(18 downto 14) <= extended_access_either&portb(6 downto 5)&portb(3 downto 2);				
								SDRAM_ADDR(18 downto 14) <= extended_access_either&portb(6 downto 5)&portb(3 downto 2);				
						end case;
					end if;
				
				-- 0x80 cart
				when
					X"80"|X"81"|X"82"|X"83"|X"84"|X"85"|X"86"|X"87"|X"88"|X"89"|X"8A"|X"8B"|X"8C"|X"8D"|X"8E"|X"8F"
					|X"90"|X"91"|X"92"|X"93"|X"94"|X"95"|X"96"|X"97"|X"98"|X"99"|X"9A"|X"9B"|X"9C"|X"9D"|X"9E"|X"9F" =>
		
					if (cart_rd4 = '1') then
						MEMORY_DATA(7 downto 0) <= CART_ROM_DATA;
						rom_request <= start_request;
						CART_S4_n <= '0';
						request_complete <= CART_REQUEST_COMPLETE;
					else
						if (use_sdram = '1') then
							MEMORY_DATA(7 downto 0) <= SDRAM_DATA(7 downto 0);
							sdram_chip_select <= start_request;
							request_complete <= sdram_request_COMPLETE;														
						else
							MEMORY_DATA(7 downto 0) <= RAM_DATA(7 downto 0);
							ram_chip_select <= start_request;
							request_complete <= ram_request_COMPLETE;									
						end if;
					end if;	
			
				-- 0xa0 cart (BASIC ROM 0xa000 - 0xbfff (8k))
				when 
					X"A0"|X"A1"|X"A2"|X"A3"|X"A4"|X"A5"|X"A6"|X"A7"|X"A8"|X"A9"|X"AA"|X"AB"|X"AC"|X"AD"|X"AE"|X"AF"
					|X"B0"|X"B1"|X"B2"|X"B3"|X"B4"|X"B5"|X"B6"|X"B7"|X"B8"|X"B9"|X"BA"|X"BB"|X"BC"|X"BD"|X"BE"|X"BF" =>
					
					if (cart_rd5 = '1') then
						MEMORY_DATA(7 downto 0) <= CART_ROM_DATA;
						cart_request <= start_request;
						CART_S5_n <= '0';
						request_complete <= CART_REQUEST_COMPLETE;
					else
						if (portb(1) = '0') then
							--request_complete <= ROM_REQUEST_COMPLETE;
							--MEMORY_DATA(7 downto 0) <= ROM_DATA;
							--rom_request <= start_request;					
							MEMORY_DATA(7 downto 0) <= SDRAM_DATA(7 downto 0);
							if (write_enable_next = '1') then
								request_complete <= '1';
							else
								request_complete <= sdram_request_COMPLETE;							
								sdram_chip_select <= start_request;								
							end if;
						
							ROM_ADDR <= "000000"&"110"&ADDR_next(12 downto 0); -- x0C000 based 8k
						 SDRAM_ADDR <="0010000"&"110"&ADDR_next(12 downto 0); -- x0C000 based 8k							
						else
							if (use_sdram = '1') then
								MEMORY_DATA(7 downto 0) <= SDRAM_DATA(7 downto 0);
								sdram_chip_select <= start_request;
								request_complete <= sdram_request_COMPLETE;														
							else
								MEMORY_DATA(7 downto 0) <= RAM_DATA(7 downto 0);
								ram_chip_select <= start_request;
								request_complete <= ram_request_COMPLETE;									
							end if;
						end if;
					end if;
					
				-- OS ROM 0xc00->0xcff				
				-- OS ROM d800->0xfff
				when 
					X"C0"|X"C1"|X"C2"|X"C3"|X"C4"|X"C5"|X"C6"|X"C7"|X"C8"|X"C9"|X"CA"|X"CB"|X"CC"|X"CD"|X"CE"|X"CF"
					|X"D8"|X"D9"|X"DA"|X"DB"|X"DC"|X"DD"|X"DE"|X"DF"
					|X"E0"|X"E1"|X"E2"|X"E3"|X"E4"|X"E5"|X"E6"|X"E7"|X"E8"|X"E9"|X"EA"|X"EB"|X"EC"|X"ED"|X"EE"|X"EF"
					|X"F0"|X"F1"|X"F2"|X"F3"|X"F4"|X"F5"|X"F6"|X"F7"|X"F8"|X"F9"|X"FA"|X"FB"|X"FC"|X"FD"|X"FE"|X"FF" =>
					
					if (portb(0) = '1') then
						--request_complete <= ROM_REQUEST_COMPLETE;
						--MEMORY_DATA(7 downto 0) <= ROM_DATA;
						--rom_request <= start_request;					
						MEMORY_DATA(7 downto 0) <= SDRAM_DATA(7 downto 0);
						if (write_enable_next = '1') then
							request_complete <= '1';
						else
							request_complete <= sdram_request_COMPLETE;							
							sdram_chip_select <= start_request;							
						end if;																			

						case rom_select is
							when "00" =>
								ROM_ADDR <= "000000"&"00"&ADDR_next(13 downto 0); -- x00000 based 16k
							SDRAM_ADDR <= "0010000"&"00"&ADDR_next(13 downto 0); -- x00000 based 16k
							when "01" =>
								ROM_ADDR <= "000000"&"01"&ADDR_next(13 downto 0); -- x04000 based 16k
							SDRAM_ADDR <= "0010000"&"01"&ADDR_next(13 downto 0); -- x04000 based 16k
							when "10" =>
								ROM_ADDR <= "000000"&"10"&ADDR_next(13 downto 0); -- x08000 based 16k
							SDRAM_ADDR <= "0010000"&"10"&ADDR_next(13 downto 0); -- x08000 based 16k
							when "11" =>
								ROM_ADDR <= "000001"&"00"&ADDR_next(13 downto 0); -- x10000 based 16k (0xc000 already taken by basic!)
							SDRAM_ADDR <= "0010001"&"00"&ADDR_next(13 downto 0); -- x10000 based 16k (0xc000 already taken by basic!)
						end case;
								
					else
						if (use_sdram = '1') then
							MEMORY_DATA(7 downto 0) <= SDRAM_DATA(7 downto 0);
							sdram_chip_select <= start_request;
							request_complete <= sdram_request_COMPLETE;														
						else
							MEMORY_DATA(7 downto 0) <= RAM_DATA(7 downto 0);
							ram_chip_select <= start_request;
							request_complete <= ram_request_COMPLETE;									
						end if;
					end if;
					
				when others =>
					if (use_sdram = '1') then
						MEMORY_DATA(7 downto 0) <= SDRAM_DATA(7 downto 0);
						sdram_chip_select <= start_request;
						request_complete <= sdram_request_COMPLETE;														
					else
						MEMORY_DATA(7 downto 0) <= RAM_DATA(7 downto 0);
						ram_chip_select <= start_request;
						request_complete <= ram_request_COMPLETE;									
					end if;
			end case;				
		else		
			case addr_next(23 downto 21) is			
				when "000" =>				
					-- internal area for zpu, never happens!
				when "001" => -- sram, 512K
					MEMORY_DATA(15 downto 0) <= RAM_DATA;
					ram_chip_select <= start_request;
					request_complete <= ram_request_COMPLETE;									
					RAM_ADDR <= addr_next(18 downto 0);

				when "010"|"011" => -- flash rom, 4MB
					request_complete <= ROM_REQUEST_COMPLETE;
					MEMORY_DATA(7 downto 0) <= ROM_DATA;
					rom_request <= start_request;
					ROM_ADDR <= addr_next(21 downto 0);
					
				when "100"|"101"|"110"|"111" => -- sdram, 8MB
					MEMORY_DATA <= SDRAM_DATA;
					sdram_chip_select <= start_request;
					request_complete <= sdram_request_COMPLETE;	
					SDRAM_ADDR <= addr_next(22 downto 0);				
			end case;
		end if;
		
--		case addr_next(15 downto 0) is
--			when X"FFFC" =>
--				MEMORY_DATA(7 downto 0) <= X"00";
--			when X"FFFD" =>
--				MEMORY_DATA(7 downto 0) <= X"06";
--			when X"0600" => --JSR 0610
--				MEMORY_DATA(7 downto 0) <= X"20";
--			when X"0601" =>
--				MEMORY_DATA(7 downto 0) <= X"10";
--			when X"0602" =>
--				MEMORY_DATA(7 downto 0) <= X"06";
--			when X"0603" => --JMP
--				MEMORY_DATA(7 downto 0) <= X"4C";
--			when X"0604" =>
--				MEMORY_DATA(7 downto 0) <= X"00";
--			when X"0605" =>
--				MEMORY_DATA(7 downto 0) <= X"06";
--			when X"0610" => --LDA RANDOM, STA 0x10, LDA 0x10, RTS
--				MEMORY_DATA(7 downto 0) <= X"AD";
--			when X"0611" =>
--				MEMORY_DATA(7 downto 0) <= X"0A";
--			when X"0612" =>
--				MEMORY_DATA(7 downto 0) <= X"D2";
--			when X"0613" =>
--				MEMORY_DATA(7 downto 0) <= X"85";
--			when X"0614" =>
--				MEMORY_DATA(7 downto 0) <= X"10";
--			when X"0615" =>
--				MEMORY_DATA(7 downto 0) <= X"44";
--			when X"0616" =>
--				MEMORY_DATA(7 downto 0) <= X"10";
--			when X"0617" =>
--				MEMORY_DATA(7 downto 0) <= X"60";
--			when others =>
--		end case;
			
	end process;
END vhdl;
