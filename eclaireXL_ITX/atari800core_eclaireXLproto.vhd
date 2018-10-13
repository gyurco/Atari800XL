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
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

LIBRARY work;

ENTITY atari800core_eclaireXLproto IS 
	GENERIC
	(
		hdmiOnGPIO : integer := 0;
		internal_rom : integer := 1;  -- if 0 expects it in sdram,is 1:16k os+basic, is 2:... TODO
		internal_ram : integer := 16384  -- at start of memory map
	);
	PORT
	(
		CLOCK_5 :  IN  STD_LOGIC;

		PS2CLK :  IN  STD_LOGIC;
		PS2DAT :  IN  STD_LOGIC;

		GPIOA :  INOUT  STD_LOGIC_VECTOR(35 DOWNTO 0);
		GPIOB :  INOUT  STD_LOGIC_VECTOR(35 DOWNTO 0);
		GPIOC:  INOUT  STD_LOGIC_VECTOR(35 DOWNTO 0);

		DRAM_BA_0 :  OUT  STD_LOGIC;
		DRAM_BA_1 :  OUT  STD_LOGIC;
		DRAM_CS_N :  OUT  STD_LOGIC;
		DRAM_RAS_N :  OUT  STD_LOGIC;
		DRAM_CAS_N :  OUT  STD_LOGIC;
		DRAM_WE_N :  OUT  STD_LOGIC;
		DRAM_LDQM :  OUT  STD_LOGIC;
		DRAM_UDQM :  OUT  STD_LOGIC;
		DRAM_CLK :  OUT  STD_LOGIC;
		DRAM_CKE :  OUT  STD_LOGIC;
		DRAM_ADDR :  OUT  STD_LOGIC_VECTOR(12 DOWNTO 0);
		DRAM_DQ :  INOUT  STD_LOGIC_VECTOR(15 DOWNTO 0);

		SD_WRITEPROTECT : IN STD_LOGIC;
		SD_DETECT : IN STD_LOGIC;
		SD_DAT1 : OUT STD_LOGIC;
		SD_DAT0 :  IN  STD_LOGIC;
		SD_CLK :  OUT  STD_LOGIC;
		SD_CMD :  OUT  STD_LOGIC;
		SD_DAT3 :  OUT  STD_LOGIC;
		SD_DAT2 : OUT STD_LOGIC;

		VGA_VS :  OUT  STD_LOGIC;
		VGA_HS :  OUT  STD_LOGIC;
		VGA_B :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		VGA_G :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		VGA_R :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);

		VGA_BLANK_N : OUT STD_LOGIC;
		VGA_CLK : OUT STD_LOGIC;
		
		AUDIO_LEFT : OUT STD_LOGIC;
		AUDIO_RIGHT : OUT STD_LOGIC;

		USB2DM: INOUT STD_LOGIC;
		USB2DP: INOUT STD_LOGIC;
		USB1DM: INOUT STD_LOGIC;
		USB1DP: INOUT STD_LOGIC;
		
		ADC_SDA: INOUT STD_LOGIC;
		ADC_SCL: INOUT STD_LOGIC
	);
END atari800core_eclaireXLproto;

ARCHITECTURE vhdl OF atari800core_eclaireXLproto IS 

	component pll_gclk
		port (
			refclk   : in  std_logic := '0'; --  refclk.clk
			rst      : in  std_logic := '0'; --   reset.reset
			outclk_0 : out std_logic        -- outclk0.clk
		);
	end component;
	
	signal ADAPTCLOCK_50 : std_logic;

	signal POTRESET : std_logic;

	signal TRIG : std_logic_vector(1 downto 0);
	signal POTIN : std_logic_vector(3 downto 0);

	signal VGA_Rint : std_logic_vector(7 downto 0);
	signal VGA_Bint : std_logic_vector(7 downto 0);

BEGIN 
	newboard : work.atari800core_eclaireXL
	GENERIC MAP
	(
		internal_rom => internal_rom,
		internal_ram => internal_ram
	)
	PORT MAP
	(
		CLOCK_50 => ADAPTCLOCK_50,

		GPIOA => open,
		EXP => open,

		PBI_A(15) => GPIOB(31),
		PBI_A(14) => GPIOB(30),
		PBI_A(13) => GPIOB(29),
		PBI_A(12) => GPIOB(11),
		PBI_A(11) => GPIOB(5),
		PBI_A(10) => GPIOB(4),
		PBI_A(9) => GPIOB(13),
		PBI_A(8) => GPIOB(15),
		PBI_A(7) => GPIOB(17),
		PBI_A(6) => GPIOB(19),
		PBI_A(5) => GPIOB(21),
		PBI_A(4) => GPIOB(23),
		PBI_A(3) => GPIOB(25),
		PBI_A(2) => GPIOB(24),
		PBI_A(1) => GPIOB(22),
		PBI_A(0) => GPIOB(20),
		PBI_D(7) => GPIOB(7),
		PBI_D(6) => GPIOB(8),
		PBI_D(5) => GPIOB(16),
		PBI_D(4) => GPIOB(18),
		PBI_D(3) => GPIOB(9),
		PBI_D(2) => GPIOB(14),
		PBI_D(1) => GPIOB(12),
		PBI_D(0) => GPIOB(10),
		PBI_CLK => GPIOB(1),
		PBI_RW_N => GPIOB(3),
		PBI_EXTSEL_N => GPIOB(28),
		PBI_MPD_N => GPIOB(32),
		PBI_REF_N => GPIOB(33),
		PBI_IRQ_N => GPIOB(34),
		PBI_RST_N => GPIOB(35),

		CART_S4_N => GPIOB(27),
		CART_S5_N => GPIOB(6),
		CART_RD4 => GPIOB(26),
		CART_RD5 => GPIOB(2),
		CART_CCTL_N => GPIOB(0),

		SIO_CLOCKIN => GPIOA(7),
		SIO_CLOCKOUT => GPIOA(6),
		SIO_IN => GPIOA(5),
		SIO_IRQ => GPIOA(0),
		SIO_OUT => GPIOA(4),
		SIO_COMMAND => GPIOA(1),
		SIO_PROCEED => GPIOA(2),
		SIO_MOTOR_RAW => GPIOA(3),

		SER_CMD => open,
		SER_TX => open,
		SER_RX => '1',

		PORTA(7) => GPIOA(8),
		PORTA(6) => GPIOA(9),
		PORTA(5) => GPIOA(10),
		PORTA(4) => GPIOA(11),
		PORTA(3) => GPIOA(17),
		PORTA(2) => GPIOA(18),
		PORTA(1) => GPIOA(19),
		PORTA(0) => GPIOA(20),
		TRIG => TRIG,
		POTIN => POTIN,
		POTRESET => POTRESET,

		DRAM_BA_0 => DRAM_BA_0,
		DRAM_BA_1 => DRAM_BA_1,
		DRAM_CS_N => DRAM_CS_N,
		DRAM_RAS_N => DRAM_RAS_N,
		DRAM_CAS_N => DRAM_CAS_N,
		DRAM_WE_N => DRAM_WE_N,
		DRAM_LDQM => DRAM_LDQM,
		DRAM_UDQM => DRAM_UDQM,
		DRAM_CLK => DRAM_CLK,
		DRAM_CKE => DRAM_CKE,
		DRAM_ADDR => DRAM_ADDR,
		DRAM_DQ => DRAM_DQ,

		SD_WRITEPROTECT => SD_WRITEPROTECT,
		SD_DETECT => SD_DETECT,
		SD_DAT1 => SD_DAT1,
		SD_DAT0 => SD_DAT0,
		SD_CLK => SD_CLK,
		SD_CMD => SD_CMD,
		SD_DAT3 => SD_DAT3,
		SD_DAT2 => SD_DAT2,

		VGA_VS => VGA_VS,
		VGA_HS => VGA_HS,
		VGA_B => VGA_Bint,
		VGA_G => VGA_G,
		VGA_R => VGA_Rint,

		VGA_BLANK_N => VGA_BLANK_N,
		VGA_CLK => VGA_CLK,
		
		AUDIO_LEFT => AUDIO_LEFT,
		AUDIO_RIGHT => AUDIO_RIGHT,

		USB2DM => USB2DM,
		USB2DP => USB2DP,
		USB1DM => USB1DM,
		USB1DP => USB1DP,
		
		ADC_SDA => open,
		ADC_SCL => open
	);


	TRIG <= GPIOA(12)&GPIOA(21);
	GPIOA(12) <= 'Z';
	GPIOA(21) <= 'Z';
	POTIN <= GPIOA(13)&GPIOA(14)&GPIOA(15)&GPIOA(16);
	GPIOA(16 downto 13) <= "0000" when POTRESET='1' else "ZZZZ";

gen_no_hdmi : if hdmiOnGPIO=0 generate
	VGA_R <= VGA_Rint;
	VGA_B <= VGA_Bint;
end generate gen_no_hdmi;

gen_hdmi : if hdmiOnGPIO=1 generate
	VGA_R(7) <= VGA_Rint(7);
	VGA_R(6) <= VGA_Rint(6);
	VGA_R(5) <= VGA_Rint(5);
	--VGA_R(4) <= VGA_Rint(4);
	--VGA_R(3) <= VGA_Rint(3);
	VGA_R(2) <= VGA_Rint(2);
	--VGA_R(1) <= VGA_Rint(1);
	--VGA_R(0) <= VGA_Rint(0);

	VGA_B(7) <= VGA_Bint(7);
	--VGA_B(6) <= VGA_Bint(6);
	--VGA_B(5) <= VGA_Bint(5);
	--VGA_B(4) <= VGA_Bint(4);
	VGA_B(3) <= VGA_Bint(3);
	VGA_B(2) <= VGA_Bint(2);
	--VGA_B(1) <= VGA_Bint(1);
	VGA_B(0) <= VGA_Bint(0);

	GPIOC(1) <= VGA_Rint(0); -- D2P
	GPIOC(2) <= VGA_Rint(1); -- D2N
	GPIOC(3) <= VGA_Rint(4); -- D1P
	GPIOC(4) <= VGA_Rint(3); -- D1N
	
	GPIOC(12) <= VGA_Bint(1); -- D0N
	GPIOC(13) <= VGA_Bint(4); -- D0P
	GPIOC(14) <= VGA_Bint(5); -- C N
	GPIOC(15) <= VGA_Bint(6); -- C P

end generate gen_hdmi;

pll_gclk_inst : pll_gclk -- upscale clock from 5 to 50MHz and put on global clock line - so we can use more plls and fractional features!
PORT MAP(refclk => CLOCK_5,
	 outclk_0 => ADAPTCLOCK_50);


END vhdl;

