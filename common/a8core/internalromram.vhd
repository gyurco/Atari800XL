LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY internalromram IS
	GENERIC
	(
		internal_rom : integer := 1;  
		internal_ram : integer := 16384 
	);
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
component generic_ram_infer IS
        generic
        (
                ADDRESS_WIDTH : natural := 9;
                SPACE : natural := 512;
                DATA_WIDTH : natural := 8
        );
   PORT
   (
      clock: IN   std_logic;
      data:  IN   std_logic_vector (data_width-1 DOWNTO 0);
      address:  IN   std_logic_vector(address_width-1 downto 0);
      we:    IN   std_logic;
      q:     OUT  std_logic_vector (data_width-1 DOWNTO 0)
   );
END component;

component os16 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END component;

component basic IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (12 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END component;

	signal rom_request_reg : std_logic;
	signal ram_request_reg : std_logic;
	
	signal ROM16_DATA : std_logic_vector(7 downto 0);
	signal BASIC_DATA : std_logic_vector(7 downto 0);	
	
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

gen_internal_os : if internal_rom=1 generate
	rom16a : os16
	PORT MAP(clock => clock,
			 address => rom_addr(13 downto 0),
			 q => ROM16_data
			 );

	basic1 : basic
	PORT MAP(clock => clock,
			 address => rom_addr(12 downto 0),
			 q => BASIC_data
			 );			 

	process(rom16_data,basic_data, rom_addr(15 downto 0))
	begin
		ROM_DATA <= ROM16_DATA;
		if (rom_addr(15)='1') then
			ROM_DATA <= BASIC_DATA;
		end if;
	end process;

	rom_request_complete <= rom_request_reg;
	
end generate;
gen_no_internal_os : if internal_rom=0 generate
	ROM16_data <= (others=>'0');

	rom_request_complete <= '0';
end generate;
	
gen_internal_ram: if internal_ram>0 generate
	ramint1 : generic_ram_infer
        generic map
        (
                ADDRESS_WIDTH => 19,
                SPACE => internal_ram,
                DATA_WIDTH =>8
        )
	PORT MAP(clock => clock,
			 address => ram_addr,
			 data => ram_data_in(7 downto 0),
			 we => RAM_WR_ENABLE,
			 q => ram_data
			 );	
	ram_request_complete <= ram_request_reg;
end generate;
gen_no_internal_ram : if internal_ram=0 generate
	ram_request_complete <='0';
	ram_data <= (others=>'1');
end generate;
        
end vhdl;
