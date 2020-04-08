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
use IEEE.STD_LOGIC_MISC.all;

ENTITY filtered_sigmadelta IS
GENERIC
(
	lowpass : integer :=1 -- simple low pass. Was made for HDMI so can be turned off here with little impact to save resources. 
);
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;

	ENABLE_179 : IN STD_LOGIC;

	AUDIN : IN UNSIGNED(15 downto 0);
	AUDOUT : OUT std_logic
);
END filtered_sigmadelta;

ARCHITECTURE vhdl OF filtered_sigmadelta IS	
	signal AUDIO_FILTERED : unsigned(15 downto 0);
BEGIN

-- low pass filter output
gen_lowpass_on : if lowpass=1 generate
filter_0 : entity work.simple_low_pass_filter
	port map
	(
		CLK => CLK,
		AUDIO_IN => AUDIN,
		SAMPLE_IN => ENABLE_179,
		AUDIO_OUT => AUDIO_FILTERED
	);
end generate;

gen_lowpass_off : if lowpass=0 generate
AUDIO_FILTERED<=AUDIN;
end generate;

dac : entity work.sigmadelta
port map
(
  reset_n => reset_n,
  clk => clk,
  audin => AUDIO_FILTERED,
  AUDOUT => AUDOUT
);

END vhdl;

