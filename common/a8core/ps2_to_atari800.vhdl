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


ENTITY ps2_to_atari800 IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;
	PS2_CLK : IN STD_LOGIC;
	PS2_DAT : IN STD_LOGIC;
	
	KEYBOARD_SCAN : IN STD_LOGIC_VECTOR(5 downto 0);
	KEYBOARD_RESPONSE : OUT STD_LOGIC_VECTOR(1 downto 0);

	CONSOL_START : STD_LOGIC;
	CONSOL_SELECT : STD_LOGIC;
	CONSOL_OPTION : STD_LOGIC
);
END ps2_keyboard;

ARCHITECTURE vhdl OF ps2_keyboard IS
	signal ps2_keys_next : std_logic_vector(255 downto 0);
	signal ps2_keys_reg : std_logic_vector(255 downto 0);

	signal atari_keyboard : std_logic_vector(63 downto 0);
	SIGNAL	SHIFT_PRESSED :  STD_LOGIC;
	SIGNAL	BREAK_PRESSED :  STD_LOGIC;
	SIGNAL	CONTROL_PRESSED :  STD_LOGIC;
BEGIN
	keyboard1: ps2_keyboard
	PORT MAP
	( 
		CLK => CLK,
		RESET_N => RESET_N,
		PS2_CLK => PS2_CLK,
		PS2_DAT => PS2_DAT,
		
		KEY_EVENT => KEY_EVENT,
		KEY_VALUE => KEY_VALUE,
		KEY_EXTENDED => KEY_EXTENDED,
		KEY_UP => KEY_UP
--		KEY_EVENT : OUT STD_LOGIC; -- high for 1 cycle on new key pressed(or repeated)/released
--		KEY_VALUE : OUT STD_LOGIC_VECTOR(7 downto 0); -- valid on event, raw scan code
--		KEY_EXTENDED : OUT STD_LOGIC;           -- valid on event, if scan code extended
--		KEY_UP : OUT STD_LOGIC                 -- value on event, if key released
	);

	process(clk,reset_n)
	begin
		if (reset_n='0') then
			ps2_keys_reg <= (others=>'0');
		elsif (clk'event and clk='1') then
			ps2_keys_reg <= ps2_keys_next;
		end if;
	end process;

	-- 1 bit per PS2 key
	process(KEY_EVENT, KEY_VALUE, KEY_EXTENDED, KEY_UP)
	begin
		ps2_keys_next <= ps2_keys_reg;

		if (key_event = '1') then
			ps2_keys_next(to_integer(unsigned(KEY_EXTENDED&KEY_VALUE))) <= NOT(KEY_UP);
		end if;
	end process;

	-- map to atari key code
	process(keyboard)
	begin
		atari_keyboard <= (others=>'0');

		shift_pressed <= '0';
		control_pressed <= '0';
		break_pressed <= '0';
		consol_start <= '0';
		consol_select <= '0';
		consol_option <= '0';

		atari_keyboard(63)<=ps2_keys_regs(X"1C");
		atari_keyboard(21)<=ps2_keys_regs(X"32");
		atari_keyboard(18)<=ps2_keys_regs(X"21");
		atari_keyboard(58)<=ps2_keys_regs(X"23");
		atari_keyboard(42)<=ps2_keys_regs(X"24");
		atari_keyboard(56)<=ps2_keys_regs(X"2B");
		atari_keyboard(61)<=ps2_keys_regs(X"34");
		atari_keyboard(57)<=ps2_keys_regs(X"33");
		atari_keyboard(13)<=ps2_keys_regs(X"43");
		atari_keyboard(1)<=ps2_keys_regs(X"3B");
		atari_keyboard(5)<=ps2_keys_regs(X"42");
		atari_keyboard(0)<=ps2_keys_regs(X"4B");
		atari_keyboard(37)<=ps2_keys_regs(X"3A");
		atari_keyboard(35)<=ps2_keys_regs(X"31");
		atari_keyboard(8)<=ps2_keys_regs(X"44");
		atari_keyboard(10)<=ps2_keys_regs(X"4D");
		atari_keyboard(47)<=ps2_keys_regs(X"15");
		atari_keyboard(40)<=ps2_keys_regs(X"2D");
		atari_keyboard(62)<=ps2_keys_regs(X"1B");
		atari_keyboard(45)<=ps2_keys_regs(X"2C");
		atari_keyboard(11)<=ps2_keys_regs(X"3C");
		atari_keyboard(16)<=ps2_keys_regs(X"2A");
		atari_keyboard(46)<=ps2_keys_regs(X"1D");
		atari_keyboard(22)<=ps2_keys_regs(X"22");
		atari_keyboard(43)<=ps2_keys_regs(X"35");
		atari_keyboard(23)<=ps2_keys_regs(X"1A");
		atari_keyboard(50)<=ps2_keys_regs(X"45");
		atari_keyboard(31)<=ps2_keys_regs(X"16");
		atari_keyboard(30)<=ps2_keys_regs(X"1E");
		atari_keyboard(26)<=ps2_keys_regs(X"26");
		atari_keyboard(24)<=ps2_keys_regs(X"25");
		atari_keyboard(29)<=ps2_keys_regs(X"2E");
		atari_keyboard(27)<=ps2_keys_regs(X"36");
		atari_keyboard(51)<=ps2_keys_regs(X"3D");
		atari_keyboard(53)<=ps2_keys_regs(X"3E");
		atari_keyboard(48)<=ps2_keys_regs(X"46");
		atari_keyboard(17)<=ps2_keys_regs(X"ec");
		atari_keyboard(52)<=ps2_keys_regs(X"66");
		atari_keyboard(28)<=ps2_keys_regs(X"76");
		atari_keyboard(39)<=ps2_keys_regs(X"91");
		atari_keyboard(60)<=ps2_keys_regs(X"58");
		atari_keyboard(44)<=ps2_keys_regs(X"0D");
		atari_keyboard(12)<=ps2_keys_regs(X"5A");
		atari_keyboard(33)<=ps2_keys_regs(X"29");
		atari_keyboard(54)<=ps2_keys_regs(X"4E");
		atari_keyboard(55)<=ps2_keys_regs(X"55");
		atari_keyboard(15)<=ps2_keys_regs(X"5B");
		atari_keyboard(14)<=ps2_keys_regs(X"54");
		atari_keyboard(6)<=ps2_keys_regs(X"52");
		atari_keyboard(7)<=ps2_keys_regs(X"5D");
		atari_keyboard(38)<=ps2_keys_regs(X"4A");
		atari_keyboard(2)<=ps2_keys_regs(X"4C");
		atari_keyboard(32)<=ps2_keys_regs(X"41");
		atari_keyboard(34)<=ps2_keys_regs(X"49");

		consol_start<=ps2_keys_regs(X"06");
		consol_select<=ps2_keys_regs(X"04");
		consol_option<=ps2_keys_regs(X"0C");
		shift_pressed<=ps2_keys_regs(X"12") or ps2_keys_regs(X"59");
		control_pressed<=ps2_keys_regs(X"14") or ps2_keys_regs(X"94");
		break_pressed<=ps2_keys_reg(X"77");
	end process;

	-- provide results as if we were a grid to pokey...
	process(keyboard_scan, atari_keyboard, control_pressed, shift_pressed, break_pressed)
		begin	
			keyboard_response <= (others=>'1');		
			
			if (atari_keyboard(to_integer(unsigned(not(keyboard_scan)))) = '1') then
				keyboard_response(0) <= '0';
			end if;
			
			if (keyboard_scan(5 downto 4)="00" and break_pressed = '1') then
				keyboard_response(1) <= '0';
			end if;
			
			if (keyboard_scan(5 downto 4)="10" and shift_pressed = '1') then
				keyboard_response(1) <= '0';
			end if;

			if (keyboard_scan(5 downto 4)="11" and control_pressed = '1') then
				keyboard_response(1) <= '0';
			end if;
	end process;		 
END vhdl;

