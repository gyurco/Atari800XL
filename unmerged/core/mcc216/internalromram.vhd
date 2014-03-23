LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY internalromram IS
  PORT(
    clock   : IN     STD_LOGIC;                             --system clock
    reset_n : IN     STD_LOGIC;                             --asynchronous reset

	ROM_ADDR : in STD_LOGIC_VECTOR(21 downto 0);
	ROM_REQUEST_COMPLETE : out STD_LOGIC;
	ROM_REQUEST : in std_logic;
	ROM_DATA : out std_logic_vector(7 downto 0);
	
	RAM_ADDR : in STD_LOGIC_VECTOR(18 downto 0);
	RAM_WR_ENABLE : in std_logic;
	RAM_DATA_IN : in STD_LOGIC_VECTOR(7 downto 0);
	RAM_REQUEST_COMPLETE : out STD_LOGIC;
	RAM_REQUEST : in std_logic;
	RAM_DATA : out std_logic_vector(7 downto 0)
	);
END internalromram;

architecture vhdl of internalromram is
component ramint IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (12 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		wren		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END component;

component romlo IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END component;

component romhi IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (12 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END component;

	signal rom_request_reg : std_logic;
	signal ram_request_reg : std_logic;
	
	signal ROMLO_DATA : std_logic_vector(7 downto 0);
	signal ROMHI_DATA : std_logic_vector(7 downto 0);
	
	signal RAM_WR_ENABLE_REAL : std_logic;
	signal IRAM_DATA : std_logic_vector(7 downto 0);

begin
	process(clock,reset_n)
	begin
		if (reset_n ='0') then
			rom_request_reg <= '0';
			ram_request_reg <= '0';
		elsif (clock'event and clock='1') then
			rom_request_reg <= rom_request;
			ram_request_reg <= ram_request;
		end if;
	end process;

	rom_request_complete <= rom_request_reg;
	ROM_DATA <= ROMLO_DATA when rom_addr(15 downto 12)=X"D" else ROMHI_DATA;	
	romlo1 : romlo
	PORT MAP(clock => clock,
			 address => rom_addr(10 downto 0),
			 q => ROMLO_data
			 );	
	romhi1 : romhi
	PORT MAP(clock => clock,
			 address => rom_addr(12 downto 0),
			 q => ROMHI_data
			 );
	
	ramint1 : ramint
	PORT MAP(clock => clock,
			 address => ram_addr(12 downto 0),
			 data => ram_data_in(7 downto 0),
			 wren => RAM_WR_ENABLE_REAL,
			 q => iram_data
			 );	
	ram_request_complete <= ram_request_reg;
	RAM_DATA <= IRAM_DATA when ram_addr(15 downto 13)= "000" else X"FF";
	RAM_WR_ENABLE_REAL <= RAM_WR_ENABLE when ram_addr(15 downto 13)="000" else '0'; -- ban writes over 8k when using int ram - HACK
end vhdl;