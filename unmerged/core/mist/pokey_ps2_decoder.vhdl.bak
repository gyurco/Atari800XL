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

ENTITY pokey_ps2_decoder IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : std_logic;
	-- ENABLE : IN STD_LOGIC; TODO Pokey debounce and scanning can be disabled
	
	-- ps2 keyboard input
	KEY_EVENT : IN STD_LOGIC;
	KEY_CODE : IN STD_LOGIC_VECTOR(7 downto 0);
	KEY_EXTENDED : IN STD_LOGIC;
	KEY_UP : IN STD_LOGIC;
	
	-- pokey output
	KBCODE : OUT STD_LOGIC_VECTOR(7 downto 0);
	KEY_HELD : OUT STD_LOGIC;
	SHIFT_PRESSED : OUT STD_LOGIC;
	BREAK_PRESSED : OUT STD_LOGIC;
	KEY_INTERRUPT : OUT STD_LOGIC;
	
	-- other output
	CONSOL_START : OUT STD_LOGIC;
	CONSOL_SELECT : OUT STD_LOGIC;
	CONSOL_OPTION : OUT STD_LOGIC;
	
	VIRTUAL_STICKS : out std_logic_vector(7 downto 0);
	VIRTUAL_TRIGGER : out std_logic_vector(3 downto 0);
	
	SYSTEM_RESET : out std_logic
);
END pokey_ps2_decoder;

ARCHITECTURE vhdl OF pokey_ps2_decoder IS
	signal left_shift_pressed_reg : std_logic;
	signal left_shift_pressed_next : std_logic;
	signal right_shift_pressed_reg : std_logic;
	signal right_shift_pressed_next : std_logic;	
	
	signal left_control_pressed_reg : std_logic;
	signal left_control_pressed_next : std_logic;	
	signal right_control_pressed_reg : std_logic;
	signal right_control_pressed_next : std_logic;	
	
	signal kbcode_next : std_logic_vector(7 downto 0);
	signal kbcode_reg : std_logic_vector(7 downto 0); -- XXX remove unused upper bits
	
	signal interrupt_next : std_logic;
	signal interrupt_reg : std_logic;
	
	signal break_next : std_logic;
	signal break_reg : std_logic;
	
	signal key_held_next : std_logic;
	signal key_held_reg : std_logic;
	
	signal start_next : std_logic;
	signal start_reg : std_logic;
	signal select_next : std_logic;
	signal select_reg : std_logic;	
	signal option_next : std_logic;
	signal option_reg : std_logic;
	
	signal virtual_up_next : std_logic;
	signal virtual_up_reg : std_logic;
	signal virtual_down_next : std_logic;
	signal virtual_down_reg : std_logic;
	signal virtual_left_next : std_logic;
	signal virtual_left_reg : std_logic;
	signal virtual_right_next : std_logic;
	signal virtual_right_reg : std_logic;
	signal virtual_stick_pressed_next : std_logic;
	signal virtual_stick_pressed_reg : std_logic;
	
	signal system_reset_next : std_logic;
	signal system_reset_reg : std_logic;	
	
	signal no_kbcode_update : std_logic;
BEGIN
	-- register
	process(clk,reset_n)
	begin
		if (reset_n = '0') then
			left_shift_pressed_reg <= '0';
			right_shift_pressed_reg <= '0';
			
			left_control_pressed_reg <= '0';
			right_control_pressed_reg <= '0';
			
			kbcode_reg <= X"3F";
			
			interrupt_reg <= '0';
			
			break_reg <= '0';
			
			key_held_reg <= '0';
			
			start_reg <= '0';
			select_reg <= '0';
			option_reg <= '0';
			
			virtual_up_reg <= '0';
			virtual_down_reg <= '0';
			virtual_left_reg <= '0';
			virtual_right_reg <= '0';
			virtual_stick_pressed_reg <= '0';
			
			system_reset_reg <= '0';
		elsif (clk'event and clk='1') then
			left_shift_pressed_reg <= left_shift_pressed_next;
			right_shift_pressed_reg <= right_shift_pressed_next;
			
			left_control_pressed_reg <= left_control_pressed_next;
			right_control_pressed_reg <= right_control_pressed_next;			
			
			kbcode_reg <= kbcode_next;
			
			interrupt_reg <= interrupt_next;
			
			break_reg <= break_next;
			
			key_held_reg <= key_held_next;
			
			start_reg <= start_next;
			select_reg <= select_next;
			option_reg <= option_next;
			
			virtual_up_reg <= virtual_up_next;
			virtual_down_reg <= virtual_down_next;
			virtual_left_reg <= virtual_left_next;
			virtual_right_reg <= virtual_right_next;
			virtual_stick_pressed_reg <= virtual_stick_pressed_next;
			
			system_reset_reg <= system_reset_next;
		end if;
	end process;
	
	-- update key pressed
	process(key_event, key_up, key_code, key_extended, left_shift_pressed_reg, right_shift_pressed_reg, left_control_pressed_reg, right_control_pressed_reg, kbcode_reg, break_reg, start_reg, select_reg, option_reg, key_held_reg, no_kbcode_update, virtual_up_reg, virtual_down_reg, virtual_left_reg, virtual_right_reg, virtual_stick_pressed_reg, system_reset_reg)
	begin
		left_shift_pressed_next <= left_shift_pressed_reg;
		right_shift_pressed_next <= right_shift_pressed_reg;
		
		left_control_pressed_next <= left_control_pressed_reg;
		right_control_pressed_next <= right_control_pressed_reg;		
	
		kbcode_next <= kbcode_reg;
		interrupt_next <= '0';
		
		break_next <= break_reg;
	
		start_next <= start_reg;
		select_next <= select_reg;
		option_next <= option_reg;
		
		virtual_up_next <= virtual_up_reg;
		virtual_down_next <= virtual_down_reg;
		virtual_left_next <= virtual_left_reg;
		virtual_right_next <= virtual_right_reg;				
		virtual_stick_pressed_next <= virtual_stick_pressed_reg;
		
		system_reset_next <= system_reset_reg;
		
		key_held_next <= key_held_reg;
		
		no_kbcode_update <= '0';
	
		-- Core functionality exactly as the Atari layout
		if (key_event = '1') then
			interrupt_next <= not(key_up);			
			key_held_next <= not(key_up);
			
			case key_extended&key_code is 
			
				-- Basic mapping - should allow all keys on Atari, just fiddly
				when 
					'0'&X"AA"|'1'&X"AA"|  -- BAT SUCCESSFUL
					'0'&X"FC"|'1'&X"FC"   -- BAT FAIL
					=>
					no_kbcode_update <= '1';
					interrupt_next <= '0';
					key_held_next <= '0';
				when '0'&X"4B" => --L
					kbcode_next <= X"00";
				when '0'&X"3B" => --J
					kbcode_next <= X"01";					
				when '0'&X"4C" => --;
					kbcode_next <= X"02";										
				when '0'&X"42" => --K
					kbcode_next <= X"05";				
				when '0'&X"79" => --+
					kbcode_next <= X"06";
				when '0'&X"7C" => --*
					kbcode_next <= X"07";
				when '0'&X"44" => --O
					kbcode_next <= X"08";
				when '0'&X"4D" => --P
					kbcode_next <= X"0A";
				when '0'&X"3C" => --U
					kbcode_next <= X"0B";
				when '0'&X"5A" => --Enter
					kbcode_next <= X"0C";
				when '0'&X"43" => --I
					kbcode_next <= X"0D";
				when '0'&X"4E" => -- -
					kbcode_next <= X"0E";
				when '0'&X"55" => -- =
					kbcode_next <= X"0F";

				when '0'&X"2A" => --V
					kbcode_next <= X"10";
				when '0'&X"05" => --Help (Using F1)
					kbcode_next <= X"11";					
				when '0'&X"21" => --C
					kbcode_next <= X"12";										
				when '0'&X"32" => --B
					kbcode_next <= X"15";				
				when '0'&X"22" => --X
					kbcode_next <= X"16";
				when '0'&X"1A" => --Z
					kbcode_next <= X"17";
				when '0'&X"25" => --4
					kbcode_next <= X"18";
				when '0'&X"26" => --3
					kbcode_next <= X"1A";
				when '0'&X"36" => --6
					kbcode_next <= X"1B";
				when '0'&X"76" => --Esc
					kbcode_next <= X"1C";
				when '0'&X"2E" => --5
					kbcode_next <= X"1D";
				when '0'&X"1E" => --2
					kbcode_next <= X"1E";
				when '0'&X"16" => --1
					kbcode_next <= X"1F";

				when '0'&X"41" => --,
					kbcode_next <= X"20";
				when '0'&X"29" => --Spc
					kbcode_next <= X"21";					
				when '0'&X"49" => --.
					kbcode_next <= X"22";										
				when '0'&X"31" => --N
					kbcode_next <= X"23";
				when '0'&X"3A" => --M
					kbcode_next <= X"25";				
				when '0'&X"4A" => --/
					kbcode_next <= X"26";
				when '1'&X"11" => --Inv
					kbcode_next <= X"27";
				when '0'&X"2D" => --R
					kbcode_next <= X"28";
				when '0'&X"24" => --E
					kbcode_next <= X"2A";
				when '0'&X"35" => --Y
					kbcode_next <= X"2B";
				when '0'&X"0D" => --Tab
					kbcode_next <= X"2C";
				when '0'&X"2C" => --T
					kbcode_next <= X"2D";
				when '0'&X"1D" => --W
					kbcode_next <= X"2E";
				when '0'&X"15" => --Q
					kbcode_next <= X"2F";					
					
				when '0'&X"46" => --9
					kbcode_next <= X"30";				
				when '0'&X"45" => --0
					kbcode_next <= X"32";										
				when '0'&X"3D" => --7
					kbcode_next <= X"33";
				when '0'&X"66" => --Backspace
					kbcode_next <= X"34";						
				when '0'&X"3E" => --8
					kbcode_next <= X"35";				
				when '0'&X"54" => --< (using [)
					kbcode_next <= X"36";
				when '0'&X"5B" => --> (using ])
					kbcode_next <= X"37";
				when '0'&X"2B" => --F
					kbcode_next <= X"38";
				when '0'&X"33" => --H
					kbcode_next <= X"39";					
				when '0'&X"23" => --D
					kbcode_next <= X"3A";
				when '0'&X"58" => --Caps
					kbcode_next <= X"3C";
				when '0'&X"34" => --G
					kbcode_next <= X"3D";
				when '0'&X"1B" => --S
					kbcode_next <= X"3E";
				when '0'&X"1C" => --A
					kbcode_next <= X"3F";

				when '0'&X"77" => --Break - XXX BUG, also presses 14, since E1 ext code...
					no_kbcode_update <= '1';
					break_next <= not(key_up);
					key_held_next <= '0';
				when '1'&X"77" => --Break
					no_kbcode_update <= '1';
					break_next <= not(key_up);
					key_held_next <= '0';
					
				-- XXX BUGS
				-- i) press shift when already holding key - does not update kbcode
				-- ii) press key, then press another, then release second key. Should go back to first...
				when '0'&X"12" => --Left shift
					no_kbcode_update <= '1';
					left_shift_pressed_next <= not(key_UP);					
					interrupt_next <= '0';
					key_held_next <= '0';
				when '0'&X"59" => --Right shift
					no_kbcode_update <= '1';
					right_shift_pressed_next <= not(key_UP);
					interrupt_next <= '0';
					key_held_next <= '0';
					
				when '0'&X"14" => --Left control
					no_kbcode_update <= '1';
					left_control_pressed_next <= not(key_UP);
					interrupt_next <= '0';
					key_held_next <= '0';
				when '1'&X"14" => --Right control
					no_kbcode_update <= '1';
					right_control_pressed_next <= not(key_UP);
					interrupt_next <= '0';			
					key_held_next <= '0';
					
				when '0'&X"06" => --Start (F2)
					no_kbcode_update <= '1';
					start_next <= not(key_UP);				
					interrupt_next <= '0';
					key_held_next <= '0';
				when '0'&X"04" => --Select (F3)
					no_kbcode_update <= '1';
					select_next <= not(key_UP);				
					interrupt_next <= '0';
					key_held_next <= '0';
				when '0'&X"0C" => --Option (F4)
					no_kbcode_update <= '1';
					option_next <= not(key_UP);
					interrupt_next <= '0';					
					key_held_next <= '0';

				-- TODO will also be useful to cursor control...
				when '1'&X"75" => -- up
					no_kbcode_update <= '1';
					virtual_up_next <= not(key_UP);
					interrupt_next <= '0';									
					key_held_next <= '0';
				when '1'&X"72" => -- down
					no_kbcode_update <= '1';
					virtual_down_next <= not(key_UP);
					interrupt_next <= '0';									
					key_held_next <= '0';
				when '1'&X"6b" => -- left
					no_kbcode_update <= '1';
					virtual_left_next <= not(key_UP);
					interrupt_next <= '0';									
					key_held_next <= '0';
				when '1'&X"74" => -- right
					no_kbcode_update <= '1';
					virtual_right_next <= not(key_UP);
					interrupt_next <= '0';	
					key_held_next <= '0';
				when '1'&X"27" => -- right windows key -> fire button
					no_kbcode_update <= '1';
					virtual_stick_pressed_next <= not(key_UP);
					interrupt_next <= '0';	
					key_held_next <= '0';					
					
				when '0'&X"07" => -- f12 => system reset
					no_kbcode_update <= '1';
					system_reset_next <= not(key_UP);
					interrupt_next <= '0';	
					key_held_next <= '0';										
					
				when others =>
					no_kbcode_update <= '1';
					-- nop
				-- Idea: Use Windows key and Alt for atari shift/control. Then use keyboard ones for 'nice' mapping as displayed on keyboard?
			end case;
			
			if (key_up = '1' or no_kbcode_update = '1') then
				kbcode_next <= kbcode_reg;				
			else
				kbcode_next(7 downto 6) <= (left_control_pressed_reg or right_control_pressed_reg)&(left_shift_pressed_reg or right_shift_pressed_reg);
			end if;
		end if;
		
		-- Then override a few for convenience
		-- e.g. if we press '#' on the keyboard we want to see '#' on the atari, even though on the atari its shift a different key.

--http://atariwiki.de/wiki/Wiki.jsp?page=KBCODE
-- 			$00	$01	$02	$03	$04	$05	$06	$07	$08	$09	$0A	$0B	$0C	$0D	$0E	$0F
--		$00	L		J		;		F1		F2		K		+		*		O	 			P		U		CR		I		-		=
--		$10	V		Help	C		F3		F4		B		X		Z		4	 			3		6		Esc	5		2		1
--		$20	,		Spc	.		N	 			M		/		Inv	R	 			E		Y		Tab	T		W		Q
--		$30	9	 			0		7		BS		8		<		>		F		H		D	 			Caps	G		S		A
--together with Shift Key: add +$40
--together with Control key: add +$80

-- Would be great to have option of using real Atari keyboard, but probably not worthwhile yet.

	end process;
			
	-- output
	kbcode <= kbcode_reg;
	KEY_HELD <= key_held_reg;
	shift_pressed <= left_shift_pressed_reg or right_shift_pressed_reg;
	break_pressed <= break_reg;
	
	key_interrupt <= interrupt_reg;
	
	consol_start <= start_reg;
	consol_select <= select_reg;
	consol_option <= option_reg;
	
	VIRTUAL_STICKS <= not(virtual_right_reg&virtual_left_reg&virtual_down_reg&virtual_up_reg&virtual_right_reg&virtual_left_reg&virtual_down_reg&virtual_up_reg);
	VIRTUAL_TRIGGER <= "00"&not(virtual_stick_pressed_reg)&not(virtual_stick_pressed_reg);
	
	system_reset <= system_reset_reg;
		
END vhdl;