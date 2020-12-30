---------------------------------------------------------------------------
-- (c) 2020 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------

--See: https://sourceforge.net/p/sidplay-residfp/wiki/SID%20internals/

LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_MISC.all;

ENTITY SID_wavegen IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;

	CHANGING : IN STD_LOGIC;
	
	RINGMOD : IN STD_LOGIC;
	RINGMOD_OSC_MSB : IN STD_LOGIC;
	TEST : IN STD_LOGIC;
	LFSR_ENABLE : IN STD_LOGIC;
	OSC_IN : IN STD_LOGIC_VECTOR(11 downto 0);
	PULSE_WIDTH_IN : IN STD_LOGIC_VECTOR(11 downto 0);
	
	WAVESELECT_IN : IN STD_LOGIC_VECTOR(3 downto 0);

	WAVE_DATA_NEEDED : OUT STD_LOGIC;
	WAVE_DATA_READY : IN STD_LOGIC;
	WAVE_DATA : IN STD_LOGIC_VECTOR(11 downto 0);

	WAVE_OUT : OUT STD_LOGIC_VECTOR(11 downto 0)
);
END SID_wavegen;

ARCHITECTURE vhdl OF SID_wavegen IS
	signal wave_reg : std_logic_vector(11 downto 0);
	signal wave_next : std_logic_vector(11 downto 0);
	signal lfsr_reg : std_logic_vector(22 downto 0);
	signal lfsr_next : std_logic_vector(22 downto 0);
	signal wave_data_needed_reg : std_logic;
	signal wave_data_needed_next : std_logic;
	signal pulse_comparator_reg : std_logic;
	signal pulse_comparator_next : std_logic;
	signal multiple_wave_bits : std_logic;
BEGIN
	-- register
	process(clk, reset_n)
	begin
		if (reset_n = '0') then
			wave_reg <= (others=>'0');
			lfsr_reg <= (others=>'1');
			pulse_comparator_reg <= '0';
			wave_data_needed_reg <= '0';
		elsif (clk'event and clk='1') then
			wave_reg <= wave_next;
			lfsr_reg <= lfsr_next;
			pulse_comparator_reg <= pulse_comparator_next;
			wave_data_needed_reg <= wave_data_needed_next;
		end if;
	end process;

	-- next state - lfsr
	--23 bit lfsr, bit0=bit22 xor bit17
	-- if noise and anything else then lfsr feedback is 0, test bit can refill it
	--outputs:  20, 18, 14, 11, 9, 5, 2 and 0
	--updated on bit 19 0->1 transition
	--ref(decap):https://sourceforge.net/p/sidplay-residfp/wiki/SID%20internals%20-%20Noise%20Generator/
	process(lfsr_reg,lfsr_enable,waveselect_in,test)
		variable noise_and_others : std_logic;
	begin
		lfsr_next <= lfsr_reg;
		if (lfsr_enable='1') then
			noise_and_others := or_reduce(waveselect_in(2 downto 0)) and waveselect_in(3);

			lfsr_next(0) <= (test or (lfsr_reg(22) xor lfsr_reg(17))) and not(noise_and_others);
			lfsr_next(22 downto 1) <= lfsr_reg(21 downto 0);
		end if;
	end process;
	
	-- next state - wave
	process(multiple_wave_bits,wave_reg,osc_in,waveselect_in,pulse_width_in,lfsr_reg,test,ringmod,ringmod_osc_msb,pulse_comparator_reg,wave_data,wave_data_ready)
		variable noise : std_logic_vector(11 downto 0);
		variable pulse : std_logic_vector(11 downto 0);
		variable triangle : std_logic_vector(11 downto 0);
		variable sawtooth : std_logic_vector(11 downto 0);

		variable pulse_comparator : std_logic;
		variable triangle_xor : std_logic;
		variable triangle_xor_ext : std_logic_vector(10 downto 0);
		variable osc_xored : std_logic_vector(10 downto 0);
	begin
		wave_next <= wave_reg;

		noise:= (others=>'1');
		pulse:= (others=>'1');
		triangle:= (others=>'1');
		sawtooth:= (others=>'1');

		if (waveselect_in(3)='1') then
			noise(11 downto 4):= lfsr_reg(20)&lfsr_reg(18)&lfsr_reg(14)&lfsr_reg(11)&lfsr_reg(9)&lfsr_reg(5)&lfsr_reg(2)&lfsr_reg(0);
			--2 4 3 2 4 3 2
			noise(3 downto 0):= (others=>'0');
		end if;

		pulse_comparator_next <= '0';
		if (unsigned(osc_in)>unsigned(pulse_width_in)) then
			pulse_comparator_next <= '1'; --1 cycle delay
		end if;
		if (waveselect_in(2)='1') then
			pulse := (others=>(pulse_comparator_reg or test));
		end if;

		--ref: https://sourceforge.net/p/sidplay-residfp/wiki/SID%20internals%20-%20Triangle%20Waveform/
		triangle_xor := not(waveselect_in(1)) and                    -- sawtooth on->disable invert
			((not(ringmod) and osc_in(11)) or                 -- not ringmod ->msb makes it invert
			(ringmod and (osc_in(11) xnor ringmod_osc_msb))); -- ringmod -> both 0 or 1 -> invert
		triangle_xor_ext := (others=>triangle_xor);
		osc_xored:= osc_in(10 downto 0) xor triangle_xor_ext;

		if (waveselect_in(1)='1') then
			sawtooth := osc_in(11) & osc_xored(10 downto 0);
		end if;

		if (waveselect_in(0)='1') then
			triangle(11 downto 1) := osc_xored(10 downto 0);
			triangle(0) := '0';
		end if;

		-- AND is what the datasheet says, but it is WRONG!
		-- In fact transistors drive against each other with different resistances and
		-- a corrupt waveform is generated. 
		-- TODO: Either compute or use flash storage (optionally)
		if (multiple_wave_bits='0') then
			wave_next <= noise and pulse and sawtooth and triangle;
		else
			if (wave_data_ready='1') then
				wave_next <= wave_data and pulse;
			end if;
		end if;
	end process;	

	multiple_wave_bits <= 
	        not(waveselect_in(3)) and
		(
			(waveselect_in(0) and waveselect_in(1))
				or 
			(waveselect_in(2) and (waveselect_in(0) or waveselect_in(1)))
		)
		;
	wave_data_needed_next <= (wave_data_needed_reg or (multiple_wave_bits and changing)) and not(wave_data_ready);

	--output
	wave_out <= wave_reg;
	wave_data_needed <= wave_data_needed_reg;
		
END vhdl;
