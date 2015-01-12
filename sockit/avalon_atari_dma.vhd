---------------------------------------------------------------------------
-- (c) 2014 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_misc.all;

ENTITY avalon_atari_dma IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;
	
	-- avalon signals
	CHIPSELECT : IN STD_LOGIC;
	ADDRESS : IN STD_LOGIC_VECTOR(21 downto 0);
	READ: IN STD_LOGIC;
	READDATA : OUT STD_LOGIC_VECTOR(31 downto 0);
	WRITE : IN STD_LOGIC;
	WRITEDATA : IN STD_LOGIC_VECTOR(31 downto 0);
	BYTEENABLE : IN STD_LOGIC_VECTOR(3 downto 0);
	WAITREQUEST : OUT STD_LOGIC;
	
	-- atari dma signals
	DMA_FETCH : OUT STD_LOGIC;
	DMA_READ_ENABLE : OUT STD_LOGIC;
	DMA_32BIT_WRITE_ENABLE : OUT STD_LOGIC; -- cough, width for read or writes...
	DMA_8BIT_WRITE_ENABLE : OUT STD_LOGIC;
	DMA_ADDR : OUT STD_LOGIC_VECTOR(23 downto 0);
	DMA_WRITE_DATA : OUT STD_LOGIC_VECTOR(31 downto 0);
	MEMORY_READY_DMA : IN STD_LOGIC;
	DMA_MEMORY_DATA : IN STD_LOGIC_VECTOR(31 downto 0)
);
END avalon_atari_dma;

ARCHITECTURE vhdl OF avalon_atari_dma IS
	SIGNAL BYTE_ADDRESS : STD_LOGIC_VECTOR(1 downto 0);
	SIGNAL SPECIAL_MEM : STD_LOGIC;
	SIGNAL DMA_MEMORY_DATA_LOW : STD_LOGIC_VECTOR(7 downto 0);
BEGIN
	DMA_FETCH <= (READ or WRITE) and CHIPSELECT;
	DMA_READ_ENABLE <= READ;
	DMA_ADDR <= ADDRESS&BYTE_ADDRESS;
	WAITREQUEST <= NOT(MEMORY_READY_DMA) or not(RESET_N);

        process(ADDRESS)
        begin
                special_mem <= '0';
                -- $00000-$0FFFF = Own ROM/RAM
                -- $10000-$1FFFF = Atari
                -- $20000-$2FFFF = Atari - savestate (gtia/antic/pokey have memory behind them)
                if (or_reduce(std_logic_vector(ADDRESS(21 downto 19))) = '0') then -- special area
                        special_mem <= ADDRESS(15);
                end if;
        end process;

	process(SPECIAL_MEM, DMA_MEMORY_DATA)
	begin
		DMA_MEMORY_DATA_LOW <= DMA_MEMORY_DATA(7 downto 0);
		if (SPECIAL_MEM = '1') then
			DMA_MEMORY_DATA_LOW <= DMA_MEMORY_DATA(15 downto 8);
		end if;
	end process;

	process(BYTEENABLE, DMA_MEMORY_DATA_LOW, WRITEDATA, SPECIAL_MEM)
	begin
		BYTE_ADDRESS <= "00";
		DMA_8BIT_WRITE_ENABLE <= '0';
		DMA_32BIT_WRITE_ENABLE <= '0';
		READDATA <= DMA_MEMORY_DATA;
		DMA_WRITE_DATA <= WRITEDATA;

		case BYTEENABLE is
		when "0001" =>
			DMA_8BIT_WRITE_ENABLE <= '1';
			READDATA <= DMA_MEMORY_DATA_LOW&DMA_MEMORY_DATA_LOW&DMA_MEMORY_DATA_LOW&DMA_MEMORY_DATA_LOW;
			DMA_WRITE_DATA <= x"000000"&WRITEDATA(7 downto 0);
		when "0010" =>
			BYTE_ADDRESS <= "01";
			DMA_8BIT_WRITE_ENABLE <= '1';
			READDATA <= DMA_MEMORY_DATA_LOW&DMA_MEMORY_DATA_LOW&DMA_MEMORY_DATA_LOW&DMA_MEMORY_DATA_LOW;
			DMA_WRITE_DATA <= x"000000"&WRITEDATA(15 downto 8);
		when "0100" =>
			BYTE_ADDRESS <= "10";
			DMA_8BIT_WRITE_ENABLE <= '1';
			READDATA <= DMA_MEMORY_DATA_LOW&DMA_MEMORY_DATA_LOW&DMA_MEMORY_DATA_LOW&DMA_MEMORY_DATA_LOW;
			DMA_WRITE_DATA <= x"000000"&WRITEDATA(23 downto 16);
		when "1000" =>
			BYTE_ADDRESS <= "11";
			DMA_8BIT_WRITE_ENABLE <= '1';
			READDATA <= DMA_MEMORY_DATA_LOW&DMA_MEMORY_DATA_LOW&DMA_MEMORY_DATA_LOW&DMA_MEMORY_DATA_LOW;
			DMA_WRITE_DATA <= x"000000"&WRITEDATA(31 downto 24);
		when "1111" =>
			DMA_32BIT_WRITE_ENABLE <= '1';
		when others =>
			-- invalid
		end case;
	end process;
END vhdl;
