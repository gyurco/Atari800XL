LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

LIBRARY work;

ENTITY data_io IS 
	PORT
	(
		CLK : in std_logic;
		RESET_n : in std_logic;
		
		-- SPI connection - up to upstream to make miso 'Z' on ss_io going high
	   SPI_CLK : in std_logic;
	   SPI_SS_IO : in std_logic;
	   SPI_MISO: out std_logic;
	   SPI_MOSI : in std_logic;
		
		-- Sector access read_request
		read_request : in std_logic;
		write_request : in std_logic;
		sector : in std_logic_vector(23 downto 0);
		ready : out std_logic;
		
		-- DMA to RAM
		ADDR: out std_logic_vector(8 downto 0);
		DATA_OUT : out std_logic_vector(7 downto 0);
		DATA_IN : in std_logic_vector(7 downto 0);
		WR_EN : out std_logic
	 );
end data_io;

architecture vhdl of data_io is


   signal sbuf_next : std_logic_vector(6 downto 0);
	signal sbuf_reg : std_logic_vector(6 downto 0);
	
   signal cmd_next : std_logic_vector(7 downto 0);
	signal cmd_reg : std_logic_vector(7 downto 0);
	
	signal cnt_next : std_logic_vector(15 downto 0);
	signal cnt_reg : std_logic_vector(15 downto 0);

	signal data_in_next : std_logic_vector(7 downto 0);
	signal data_in_reg : std_logic_vector(7 downto 0);

	signal data_out_next : std_logic_vector(7 downto 0);
	signal data_out_reg : std_logic_vector(7 downto 0);

	signal addr_next : std_logic_vector(8 downto 0);
	signal addr_reg : std_logic_vector(8 downto 0);

	signal wren_next : std_logic;
	signal wren_reg : std_logic;

	signal ready_next : std_logic;
	signal ready_reg : std_logic;
	
	signal transmit_next : std_logic_vector(7 downto 0);
	signal transmit_reg : std_logic_vector(7 downto 0);
	
	signal sector_next : std_logic_vector(23 downto 0);
	signal sector_reg : std_logic_vector(23 downto 0);
	
	signal read_request_next : std_logic;
	signal read_request_reg : std_logic;
	
	signal write_request_next : std_logic;
	signal write_request_reg : std_logic;

	signal clk2 : std_logic;
begin	 
	clk2 <= clk or spi_ss_io;

	process(clk2,reset_n,spi_ss_io)
	begin
		if (spi_ss_io = '1') then
			cnt_reg <= (others=>'0');
			cmd_reg <= (others=>'0');
			wren_reg <= '0';
		elsif (reset_n = '0') then
			cnt_reg <= (others=>'0');
			cmd_reg <= (others=>'0');
			sbuf_reg <= (others=>'0');
			
			addr_reg <= (others => '0');
			data_in_reg <= (others => '0');
			data_out_reg <= (others => '0');
			wren_reg <= '0';			
			
			ready_reg <= '0';
			
			transmit_reg <= (others=>'0');
			
			read_request_reg <= '0';
			write_request_reg <= '0';
			sector_reg <=(others=>'0');
		elsif (clk2'event and clk2='1') then
			cnt_reg <= cnt_next;
			cmd_reg <= cmd_next;
			sbuf_reg <= sbuf_next;			
			
			addr_reg <= addr_next;
			data_in_reg <= data_in_next;
			data_out_reg <= data_out_next;
			wren_reg <= wren_next;
			
			ready_reg <= ready_next;
		
			transmit_reg <= transmit_next;

			read_request_reg <= read_request_next;
			write_request_reg <= write_request_next;
			sector_reg <= sector_next;			
		end if;
	end process;	
	
--	clk_sync : synchronizer
--	PORT MAP ( CLK => clk, raw => spi_clk, sync=>spi_clk_next);
--spi_clk_next <= spi_clk;

--	input_sync : synchronizer
--	PORT MAP ( CLK => clk, raw => spi_mosi, sync=>spi_mosi_next);

--	select_sync : synchronizer
--	PORT MAP ( CLK => clk, raw => spi_ss_io, sync=>spi_ss_next);

	data_in_next <= data_in;

	process(spi_ss_io,cnt_reg, sbuf_reg, transmit_reg, spi_mosi, addr_reg, cmd_reg, sector_reg, write_request_reg, read_request_reg, ready_reg,read_request,write_request,sector,data_in_reg)
	begin
		cnt_next <= cnt_reg;
		sbuf_next <= sbuf_reg;
		cmd_next <= cmd_reg;
		ready_next <= ready_reg and (read_request or write_request); -- stay ready until read_request cleared (received by other end)
		
		transmit_next <= transmit_reg;
		
		wren_next <= '0';
		data_out_next <= (others=>'0');		
		addr_next <= addr_reg;
		
		sector_next <= sector_reg;
		read_request_next <= read_request_reg;		
		write_request_next <= write_request_reg;		
		
--- It polls get_status 10 times a second
--- it uses SPI_SS2 for this
--- it sends command code 0x50
--- reads 4 bytes afterwards

--- it reports whenever the returned value is different then the one from previous get_status

--- if the lowest byte of the status (the last transmitted of the four) is 0xa5:
--- a sector is read from sd card with the sector no being the upper/first three bytes transmitted
--- if the sector could be read
--- SPI_SS2 is activated
--- command byte 0x51 is sent
--- all 512 sector bytes are sent
		
		--if (spi_clk_reg = '1' and spi_clk_next = '0') then
		transmit_next(7 downto 1) <= transmit_reg(6 downto 0);
		transmit_next(0) <= '0';

		cnt_next <= std_logic_vector(unsigned(cnt_reg) + 1);		
		
		sbuf_next(6 downto 1) <= sbuf_reg(5 downto 0);
		sbuf_next(0) <= SPI_MOSI;

		if (cnt_reg = X"0000") then
			addr_next <= (others=>'0');
		end if;
			
		if (cnt_reg = X"0007") then
			cmd_next(7 downto 1) <= sbuf_reg;
			cmd_next(0) <= SPI_MOSI;
			
			sector_next <= sector;
			read_request_next <= read_request;		
			write_request_next <= write_request;		
		end if;
			
		--end if;
		
		case cmd_reg is
		when X"50" => --get status
			case cnt_reg is 
			when X"0008" =>
				transmit_next <= sector_reg(23 downto 16);
			when X"0010" =>
				transmit_next <= sector_reg(15 downto 8);
			when X"0018" =>
				transmit_next <= sector_reg(7 downto 0);				
			when X"0020" =>
				transmit_next <= "101001"&write_request_reg&read_request_reg; --read read_request
			when others =>
				-- nothing
			end case;
		when X"51" => --sector read from sd, write it...
			if (cnt_reg = X"0008") then
				addr_next <= (others=>'1');
			end if;
			if (cnt_reg(2 downto 0) = "111") then
				addr_next <= std_logic_vector(unsigned(addr_reg) + 1);
				data_out_next(7 downto 1) <= sbuf_reg;
				data_out_next(0) <= SPI_MOSI;
				wren_next <= read_request;
				
				if (cnt_reg(12) = '1')then
					ready_next <= '1';
				end if;
			end if;
		when X"52" => -- read from write, write to sd
			if (cnt_reg(2 downto 0) = "000") then
				addr_next <= std_logic_vector(unsigned(addr_reg) + 1);
				transmit_next <= data_in_reg;
				
				if (cnt_reg(12) = '1')then
					ready_next <= '1';
				end if;
			end if;
		when others =>
			-- nop
		end case;
	end process;

	-- outputs
	addr <= addr_next;
	data_out <= data_out_next;
	wr_en <= wren_next;
	
	ready <= ready_reg;

	spi_miso <= transmit_next(7);
end vhdl;
