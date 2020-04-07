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

ENTITY YM2149_volume_profile IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;
	ENABLE : IN STD_LOGIC;
	
	CHANNEL_A : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_B : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_C : IN STD_LOGIC_VECTOR(3 downto 0);
	
	AUDIO_OUT : OUT STD_LOGIC_VECTOR(7 downto 0)
);
END YM2149_volume_profile;

ARCHITECTURE vhdl OF YM2149_volume_profile IS
	signal vol_reg: unsigned(7 downto 0);
	signal vol_next: unsigned(7 downto 0);

	function logvolume(x: std_logic_vector(3 downto 0)) return unsigned is
	begin
		case x is
        when "0000" => return "00000001";
        when "0001" => return "00000010";
        when "0010" => return "00000011";
        when "0011" => return "00000100";
        when "0100" => return "00000110";
        when "0101" => return "00001000";
        when "0110" => return "00001011";
        when "0111" => return "00010000";
        when "1000" => return "00010111";
        when "1001" => return "00100000";
        when "1010" => return "00101101";
        when "1011" => return "01000000";
        when "1100" => return "01011010";
        when "1101" => return "01111111";
        when "1110" => return "10110100";
        when others => return "11111111"; 
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
	process(vol_reg,enable,channel_a,channel_b,channel_c)
		variable cha_log : unsigned(7 downto 0);
		variable chb_log : unsigned(7 downto 0);
		variable chc_log : unsigned(7 downto 0);
		variable chsum_log : unsigned(9 downto 0);
	begin
		vol_next <= vol_reg;
		
		-- there is this vol table array recorded from the device, best to make use of that I think once I have flash support working		
		-- for now, lets use log of each channel then sum
		-- + I'd like to review that table in octave to understand what is going on...
		-- from octave based on datasheet only: sqrt(2)^i/sqrt(2)^15;
		if (enable = '1') then
			cha_log := logvolume(channel_a);
			chb_log := logvolume(channel_b);
			chc_log := logvolume(channel_c);
			
			chsum_log := resize(cha_log,10)+resize(chb_log,10)+resize(chc_log,10);
			
			vol_next <= chsum_log(9 downto 2); -- no saturation at all?
		end if;
	end process;	
		
	-- output
	AUDIO_OUT <= STD_LOGIC_VECTOR(vol_reg);
		
END vhdl;
