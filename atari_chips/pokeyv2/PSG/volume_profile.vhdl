---------------------------------------------------------------------------
-- (c) 2020 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY PSG_volume_profile IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;
	ENABLE : IN STD_LOGIC;
	
	CHANNEL_A : IN STD_LOGIC_VECTOR(4 downto 0);
	CHANNEL_B : IN STD_LOGIC_VECTOR(4 downto 0);
	CHANNEL_C : IN STD_LOGIC_VECTOR(4 downto 0);

	CHANNEL_MASK : IN STD_LOGIC_VECTOR(2 downto 0); --enable channel A,B,C
	
	AUDIO_OUT : OUT STD_LOGIC_VECTOR(15 downto 0)
);
END PSG_volume_profile;

ARCHITECTURE vhdl OF PSG_volume_profile IS
	signal vol_reg: unsigned(15 downto 0);
	signal vol_next: unsigned(15 downto 0);

	function logvolume(x: std_logic_vector(4 downto 0)) return unsigned is
	begin
		case x is
	when "00000" => return "0000000000000000";
        when "00001" => return "0000000000011100";
        when "00010" => return "0000000000111101";
        when "00011" => return "0000000001100110";
        when "00100" => return "0000000010011001";
        when "00101" => return "0000000011010111";
        when "00110" => return "0000000100100011";
        when "00111" => return "0000000110000000";
        when "01000" => return "0000000111110001";
        when "01001" => return "0000001001111101";
        when "01010" => return "0000001100100111";
        when "01011" => return "0000001111111000";
        when "01100" => return "0000010011111000";
        when "01101" => return "0000011000110001";
        when "01110" => return "0000011110110001";
        when "01111" => return "0000100110000111";
        when "10000" => return "0000101111000111";
        when "10001" => return "0000111010001000";
        when "10010" => return "0001000111101000";
        when "10011" => return "0001011000001010";
        when "10100" => return "0001101100011001";
        when "10101" => return "0010000101001100";
        when "10110" => return "0010100011100011";
        when "10111" => return "0011001000101111";
        when "11000" => return "0011110110010010";
        when "11001" => return "0100101110000100";
        when "11010" => return "0101110010011000";
        when "11011" => return "0111000110000011";
        when "11100" => return "1000101100100001";
        when "11101" => return "1010101010000001";
        when "11110" => return "1101000011101111";
        when "11111" => return "1111111111111111";
		end case;
	end logvolume;	
BEGIN
	-- register
	process(clk, reset_n)
	begin
		if (reset_n = '0') then
			vol_reg <= (others=>'0');
		elsif (clk'event and clk='1') then
			vol_reg <= vol_next;
		end if;
	end process;
	
	-- next state
	process(vol_reg,enable,channel_a,channel_b,channel_c,channel_mask)
		variable cha_log : unsigned(15 downto 0);
		variable chb_log : unsigned(15 downto 0);
		variable chc_log : unsigned(15 downto 0);
		variable chsum_log : unsigned(17 downto 0);
	begin
		vol_next <= vol_reg;
		cha_log := (others=>'0');
		chb_log := (others=>'0');
		chc_log := (others=>'0');
		
		-- there is this vol table array recorded from the device, best to make use of that I think once I have flash support working		
		-- for now, lets use log of each channel then sum
		-- + I'd like to review that table in octave to understand what is going on...
		-- from octave based on datasheet only: sqrt(2)^i/sqrt(2)^15;
		if (enable = '1') then
			if (channel_mask(2)='1') then
				cha_log := logvolume(channel_a);
			end if;
			if (channel_mask(1)='1') then
				chb_log := logvolume(channel_b);
			end if;
			if (channel_mask(0)='1') then
				chc_log := logvolume(channel_c);
			end if;
			
			chsum_log := resize(cha_log,18)+resize(chb_log,18)+resize(chc_log,18);
			
			vol_next <= chsum_log(17 downto 2); -- no saturation at all?
		end if;
	end process;	
		
	-- output
	AUDIO_OUT <= STD_LOGIC_VECTOR(vol_reg);
		
END vhdl;
