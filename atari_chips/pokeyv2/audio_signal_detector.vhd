---------------------------------------------------------------------------
-- (c) 2024 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_MISC.all;
use work.AudioTypes.all;

LIBRARY work;

ENTITY audio_signal_detector IS 
	PORT
	(
		CLK : IN STD_LOGIC;
		RESET_N : IN STD_LOGIC;
		AUDIO : IN SIGNED(15 downto 0);
		SAMPLE : IN STD_LOGIC;
		VOLUME: IN STD_LOGIC_VECTOR(1 downto 0);
		
		DETECT_OUT : OUT STD_LOGIC
	);
END audio_signal_detector;		
		
ARCHITECTURE vhdl OF audio_signal_detector IS
	-- find zero
	signal moving_avg_reg : signed(15 downto 0);
	signal moving_avg_next : signed(15 downto 0);

	-- amplitude detector
	signal min_level_reg : signed(11 downto 0);
	signal min_level_next : signed(11 downto 0);

	signal max_level_reg : signed(11 downto 0);
	signal max_level_next : signed(11 downto 0);

	signal amplitude_reg  : unsigned(11 downto 0);
	signal amplitude_next : unsigned(11 downto 0); 

	-- zero crossing	
	signal zero_crosses_reg : unsigned(10 downto 0);
	signal zero_crosses_next : unsigned(10 downto 0);

	signal above_zero_reg : std_logic;
	signal above_zero_next : std_logic;

	-- when to check
	signal enable_check_pre : std_logic;
	signal enable_check : std_logic;

	-- how to interpret results
	signal enabled_reg : unsigned(6 downto 0);
	signal enabled_next : unsigned(6 downto 0);
	
BEGIN
	 process(CLK,reset_n)
	 begin
	   if (reset_n='0') then
			enabled_reg <= (others=>'0');
			min_level_reg <= (others=>'1');
			max_level_reg <= (others=>'0');			
			amplitude_reg <= (others=>'0');			
			zero_crosses_reg <= (others=>'0');
			above_zero_reg <= '0';
			moving_avg_reg <= (others=>'0');
		elsif (CLK'event and CLK='1') then
			enabled_reg <= enabled_next;
			min_level_reg <= min_level_next;
			max_level_reg <= max_level_next;
			amplitude_reg <= amplitude_next;
			zero_crosses_reg <= zero_crosses_next;
			above_zero_reg <= above_zero_next;
			moving_avg_reg <= moving_avg_next;
		end if;
	 end process;	
	 
enable_div : work.enable_divider
	generic map (COUNT=>1024)
	port map(clk=>CLK,reset_n=>reset_n,enable_in=>'1',enable_out=>enable_check_pre);

enable_div2 : work.enable_divider
	generic map (COUNT=>1024)
	port map(clk=>CLK,reset_n=>reset_n,enable_in=>enable_check_pre,enable_out=>enable_check);

-- moving avg
process(moving_avg_reg,sample,audio)
begin
	moving_avg_next <= moving_avg_reg;
	
	if (sample='1') then
		--moving_avg_next <= resize(moving_avg_reg(15 downto 1),16) + resize(moving_avg_reg(15 downto 2),16) + resize(moving_avg_reg(15 downto 3),16) + resize(moving_avg_reg(15 downto 4),16)+ resize(moving_avg_reg(15 downto 5),16) + resize(audio(15 downto 5),16);
		moving_avg_next <= (moving_avg_reg - resize(moving_avg_reg(15 downto 5),16)) + resize(audio(15 downto 5),16);
	end if;
end process;	
	
-- zero crossing
process(audio,moving_avg_reg,zero_crosses_reg,above_zero_reg,enable_check)
	variable audio_nodc : signed(15 downto 0);
begin
	above_zero_next <= above_zero_reg;
	zero_crosses_next <= zero_crosses_reg;

	audio_nodc := audio - moving_avg_reg;
	
	above_zero_next <= not(audio_nodc(15));

	if ((above_zero_reg xor not(audio_nodc(15)))='1') then
		zero_crosses_next <= zero_crosses_reg+1;
	end if;

	if (enable_check='1') then
		zero_crosses_next <= (others=>'0');
	end if;
end process;

-- amplitude
process(audio,min_level_reg,max_level_reg,amplitude_reg,enable_check,enabled_reg)
begin
	min_level_next <= min_level_reg;
	max_level_next <= max_level_reg;
	amplitude_next <= unsigned(max_level_reg-min_level_reg);

	if (audio(15 downto 4)<min_level_reg) then
		min_level_next <= audio(15 downto 4);
	end if;

	if (audio(15 downto 4)>max_level_reg) then
		max_level_next <= audio(15 downto 4);
	end if;	

	if (enable_check='1') then
		min_level_next(11) <= '0';
		min_level_next(10 downto 0) <= (others=>'1');
		max_level_next(11) <= '1';
		max_level_next(10 downto 0) <= (others=>'0');
	end if;
end process;

process(audio,amplitude_reg,zero_crosses_reg,enable_check,enabled_reg,volume)
	variable detected : std_logic;
	variable amplitude_threshold : unsigned(11 downto 0);
	variable zero_crosses_threshold : unsigned(10 downto 0);
begin
	enabled_next <= enabled_reg;

	case volume is
	when "01" =>
		amplitude_threshold := to_unsigned(32,12);
	when "10" =>
		amplitude_threshold := to_unsigned(64,12);
	when others =>
		amplitude_threshold := to_unsigned(128,12);
	end case;

	zero_crosses_threshold := to_unsigned(256,11);
	
	if (enable_check='1') then
		detected := '0';
		if (amplitude_reg>amplitude_threshold and zero_crosses_reg<zero_crosses_threshold) then
			detected := '1';
		end if;	
		if (detected='1' and enabled_reg<119) then
			enabled_next <= enabled_reg+8;
		end if;
		if (detected='0' and enabled_reg>0) then
			enabled_next <= enabled_reg-1;
		end if;		
	end if;
end process;

process(enabled_reg)
begin
	detect_out <= '0';
	if (enabled_reg>=64) then
		detect_out <= '1';
	end if;		
	
end process;

END vhdl;
