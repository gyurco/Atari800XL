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
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_MISC.all;

LIBRARY work;

ENTITY SID_top IS 
	PORT
	(
		CLK : in std_logic;
		RESET_N : in std_logic;
		
		ENABLE : in std_logic;

		ADDR : in std_logic_vector(4 downto 0); 
		WRITE_ENABLE : in std_logic;
		
		DI : in std_logic_vector(7 downto 0);
		DO : out std_logic_vector(7 downto 0);
		
		AUDIO : out std_logic_vector(15 downto 0);
	);
END SID_top;		
		
ARCHITECTURE vhdl OF SID_top IS
	-- frequency (added to 24 bit osc on each tick)
	signal freq_adj_channel_a_reg : std_logic_vector(15 downto 0);
	signal freq_adj_channel_a_next : std_logic_vector(15 downto 0);
	signal freq_adj_channel_b_reg : std_logic_vector(15 downto 0);
	signal freq_adj_channel_b_next : std_logic_vector(15 downto 0);
	signal freq_adj_channel_c_reg : std_logic_vector(15 downto 0);
	signal freq_adj_channel_c_next : std_logic_vector(15 downto 0);

	-- pulse waveform duty cycle 
	signal pulse_width_channel_a_reg : std_logic_vector(11 downto 0);
	signal pulse_width_channel_a_next : std_logic_vector(11 downto 0);
	signal pulse_width_channel_b_reg : std_logic_vector(11 downto 0);
	signal pulse_width_channel_b_next : std_logic_vector(11 downto 0);
	signal pulse_width_channel_c_reg : std_logic_vector(11 downto 0);
	signal pulse_width_channel_c_next : std_logic_vector(11 downto 0);
	
	-- waveform
	signal waveselect_a_reg : std_logic_vector(3 downto 0);
	signal waveselect_a_next : std_logic_vector(3 downto 0);	
	signal waveselect_b_reg : std_logic_vector(3 downto 0);
	signal waveselect_b_next : std_logic_vector(3 downto 0);	
	signal waveselect_c_reg : std_logic_vector(3 downto 0);
	signal waveselect_c_next : std_logic_vector(3 downto 0);	

	--ring mod, sync, gate
	signal control_a_reg : std_logic_vector(3 downto 0);
	signal control_a_next : std_logic_vector(3 downto 0);	
	signal control_b_reg : std_logic_vector(3 downto 0);
	signal control_b_next : std_logic_vector(3 downto 0);	
	signal control_c_reg : std_logic_vector(3 downto 0);
	signal control_c_next : std_logic_vector(3 downto 0);	

	-- ADSR envelope - attack/decay/sustain/release
	signal envelope_attack_a_reg : std_logic_vector(3 downto 0);
	signal envelope_attack_a_next : std_logic_vector(3 downto 0);	
	signal envelope_attack_b_reg : std_logic_vector(3 downto 0);
	signal envelope_attack_b_next : std_logic_vector(3 downto 0);	
	signal envelope_attack_c_reg : std_logic_vector(3 downto 0);
	signal envelope_attack_c_next : std_logic_vector(3 downto 0);	

	signal envelope_decay_a_reg : std_logic_vector(3 downto 0);
	signal envelope_decay_a_next : std_logic_vector(3 downto 0);	
	signal envelope_decay_b_reg : std_logic_vector(3 downto 0);
	signal envelope_decay_b_next : std_logic_vector(3 downto 0);	
	signal envelope_decay_c_reg : std_logic_vector(3 downto 0);
	signal envelope_decay_c_next : std_logic_vector(3 downto 0);	

	signal envelope_sustain_a_reg : std_logic_vector(3 downto 0);
	signal envelope_sustain_a_next : std_logic_vector(3 downto 0);	
	signal envelope_sustain_b_reg : std_logic_vector(3 downto 0);
	signal envelope_sustain_b_next : std_logic_vector(3 downto 0);	
	signal envelope_sustain_c_reg : std_logic_vector(3 downto 0);
	signal envelope_sustain_c_next : std_logic_vector(3 downto 0);	

	signal envelope_release_a_reg : std_logic_vector(3 downto 0);
	signal envelope_release_a_next : std_logic_vector(3 downto 0);	
	signal envelope_release_b_reg : std_logic_vector(3 downto 0);
	signal envelope_release_b_next : std_logic_vector(3 downto 0);	
	signal envelope_release_c_reg : std_logic_vector(3 downto 0);
	signal envelope_release_c_next : std_logic_vector(3 downto 0);	
	
	-- state variable filter params
	signal statevariable_fcutoff_reg : std_logic_vector(10 downto 0); --30Hz to 12KHz, linear
	signal statevariable_fcutoff_next : std_logic_vector(10 downto 0);
	signal statevariable_Q_reg : std_logic_vector(3 downto 0); --resonance
	signal statevariable_Q_next : std_logic_vector(3 downto 0);

	-- which channels are filtered?
	signal filter_en_reg : std_logic_vector(2 downto 0);
	signal filter_en_next : std_logic_vector(2 downto 0);

	-- which filters are we using?
	signal filter_sel_reg : std_logic_vector(2 downto 0); --hp/bp/lp
	signal filter_sel_next : std_logic_vector(2 downto 0);

	-- allow ch3 to be silent, if using it for modulation
	signal ch3silent_reg : std_logic;
	signal ch3silent_next : std_logic;

	-- overall volume
	signal vol_reg : std_logic_vector(3 downto 0);
	signal vol_next : std_logic_vector(3 downto 0);

	-- op regs
	signal addr_decoded : std_logic_vector(31 downto 0);
	
	signal audio_reg: std_logic_vector(15 downto 0);
BEGIN
	process(clk,reset_n)
	begin
		if (reset_n='0') then
			freq_adj_channel_a_reg <= (others=>'0');
			freq_adj_channel_b_reg <= (others=>'0');
			freq_adj_channel_c_reg <= (others=>'0');
			pulse_width_channel_a_reg <= (others=>'0');
			pulse_width_channel_b_reg <= (others=>'0');
			pulse_width_channel_c_reg <= (others=>'0');
			waveselect_a_reg <= (others=>'0');
			waveselect_b_reg <= (others=>'0');
			waveselect_c_reg <= (others=>'0');
			control_a_reg <= (others=>'0');
			control_b_reg <= (others=>'0');
			control_c_reg <= (others=>'0');
			envelope_attack_a_reg <= (others=>'0');
			envelope_attack_b_reg <= (others=>'0');
			envelope_attack_c_reg <= (others=>'0');
			envelope_decay_a_reg <= (others=>'0');
			envelope_decay_b_reg <= (others=>'0');
			envelope_decay_c_reg <= (others=>'0');
			envelope_sustain_a_reg <= (others=>'0');
			envelope_sustain_b_reg <= (others=>'0');
			envelope_sustain_c_reg <= (others=>'0');
			envelope_release_a_reg <= (others=>'0');
			envelope_release_b_reg <= (others=>'0');
			envelope_release_c_reg <= (others=>'0');
			statevariable_fcutoff_reg <= (others=>'0');
			statevariable_Q_Reg <= (others=>'0');
			filter_en_reg <= (others=>'0');
			filter_sel_reg <= (others=>'0');
			ch3silent_reg <= (others=>'0');
			vol_reg <= (others=>'0');
		elsif (clk'event and clk='1') then
			freq_adj_channel_a_reg <= freq_adj_channel_a_next;
			freq_adj_channel_b_reg <= freq_adj_channel_b_next;
			freq_adj_channel_c_reg <= freq_adj_channel_c_next;
			pulse_width_channel_a_reg <= pulse_width_channel_a_next;
			pulse_width_channel_b_reg <= pulse_width_channel_b_next;
			pulse_width_channel_c_reg <= pulse_width_channel_c_next;
			waveselect_a_reg <= waveselect_a_next;
			waveselect_b_reg <= waveselect_b_next;
			waveselect_c_reg <= waveselect_c_next;
			control_a_reg <= control_a_next;
			control_b_reg <= control_b_next;
			control_c_reg <= control_c_next;
			envelope_attack_a_reg <= envelope_attack_a_next;
			envelope_attack_b_reg <= envelope_attack_b_next;
			envelope_attack_c_reg <= envelope_attack_c_next;
			envelope_decay_a_reg <= envelope_decay_a_next;
			envelope_decay_b_reg <= envelope_decay_b_next;
			envelope_decay_c_reg <= envelope_decay_c_next;
			envelope_sustain_a_reg <= envelope_sustain_a_next;
			envelope_sustain_b_reg <= envelope_sustain_b_next;
			envelope_sustain_c_reg <= envelope_sustain_c_next;
			envelope_release_a_reg <= envelope_release_a_next;
			envelope_release_b_reg <= envelope_release_b_next;
			envelope_release_c_reg <= envelope_release_c_next;
			statevariable_fcutoff_reg <= statevariable_fcutoff_next;
			statevariable_Q_Reg <= statevariable_Q_next;
			filter_en_reg <= filter_en_next;
			filter_sel_reg <= filter_sel_next;
			ch3silent_reg <= ch3silent_next;
			vol_reg <= vol_next;
		end if;
	end process;
	
decode_addr1 : entity work.complete_address_decoder
	generic map(width=>5)
	port map (addr_in=>ADDR(4 downto 0), addr_decoded=>addr_decoded);	
	
	process(addr_decoded,write_enable,di,
		freq_adj_channel_a_reg,
		freq_adj_channel_b_reg,
		freq_adj_channel_c_reg,
		pulse_width_channel_a_reg,
		pulse_width_channel_b_reg,
		pulse_width_channel_c_reg,
		waveselect_a_reg,
		waveselect_b_reg,
		waveselect_c_reg,
		control_a_reg,
		control_b_reg,
		control_c_reg,
		envelope_attack_a_reg,
		envelope_attack_b_reg,
		envelope_attack_c_reg,
		envelope_decay_a_reg,
		envelope_decay_b_reg,
		envelope_decay_c_reg,
		envelope_sustain_a_reg,
		envelope_sustain_b_reg,
		envelope_sustain_c_reg,
		envelope_release_a_reg,
		envelope_release_b_reg,
		envelope_release_c_reg,
		statevariable_fcutoff_reg,
		statevariable_Q_Reg,
		filter_en_reg,
		filter_sel_reg,
		ch3silent_reg,
		vol_reg
		)
	begin
		freq_adj_channel_a_next <= freq_adj_channel_a_reg;
		freq_adj_channel_b_next <= freq_adj_channel_b_reg;
		freq_adj_channel_c_next <= freq_adj_channel_c_reg;
		pulse_width_channel_a_next <= pulse_width_channel_a_reg;
		pulse_width_channel_b_next <= pulse_width_channel_b_reg;
		pulse_width_channel_c_next <= pulse_width_channel_c_reg;
		waveselect_a_next <= waveselect_a_reg;
		waveselect_b_next <= waveselect_b_reg;
		waveselect_c_next <= waveselect_c_reg;
		control_a_next <= control_a_reg;
		control_b_next <= control_b_reg;
		control_c_next <= control_c_reg;
		envelope_attack_a_next <= envelope_attack_a_reg;
		envelope_attack_b_next <= envelope_attack_b_reg;
		envelope_attack_c_next <= envelope_attack_c_reg;
		envelope_decay_a_next <= envelope_decay_a_reg;
		envelope_decay_b_next <= envelope_decay_b_reg;
		envelope_decay_c_next <= envelope_decay_c_reg;
		envelope_sustain_a_next <= envelope_sustain_a_reg;
		envelope_sustain_b_next <= envelope_sustain_b_reg;
		envelope_sustain_c_next <= envelope_sustain_c_reg;
		envelope_release_a_next <= envelope_release_a_reg;
		envelope_release_b_next <= envelope_release_b_reg;
		envelope_release_c_next <= envelope_release_c_reg;
		statevariable_fcutoff_next <= statevariable_fcutoff_reg;
		statevariable_Q_Reg <= statevariable_Q_reg;
		filter_en_next <= filter_en_reg;
		filter_sel_next <= filter_sel_reg;
		ch3silent_next <= ch3silent_reg;
		vol_next <= vol_reg;
	
		if (write_enable='1') then
			--ch a
			if (addr_decoded(0)='1') then
				freq_adj_channel_a_next(7 downto 0) <= di;
			end if;
			if (addr_decoded(1)='1') then
				freq_adj_channel_a_next(15 downto 8) <= di;
			end if;
			if (addr_decoded(2)='1') then
				pulse_width_channel_a_next(7 downto 0) <= di;
			end if;
			if (addr_decoded(3)='1') then
				pulse_width_channel_a_next(11 downto 8) <= di(3 downto 0);
			end if;
			if (addr_decoded(4)='1') then
				control_a_next <= di(3 downto 0);
				waveselect_a_next <= di(7 downto 4);
			end if;
			if (addr_decoded(5)='1') then
				envelope_attack_a_next <= di(7 downto 4);
				envelope_decay_a_next <= di(3 downto 0);
			end if;
			if (addr_decoded(6)='1') then
				envelope_sustain_a_next <= di(7 downto 4);
				envelope_release_a_next <= di(3 downto 0);
			end if;

			--ch b
			if (addr_decoded(7)='1') then
				freq_adj_channel_b_next(7 downto 0) <= di;
			end if;
			if (addr_decoded(8)='1') then
				freq_adj_channel_b_next(15 downto 8) <= di;
			end if;
			if (addr_decoded(9)='1') then
				pulse_width_channel_b_next(7 downto 0) <= di;
			end if;
			if (addr_decoded(10)='1') then
				pulse_width_channel_b_next(11 downto 8) <= di(3 downto 0);
			end if;
			if (addr_decoded(11)='1') then
				control_b_next <= di(3 downto 0);
				waveselect_b_next <= di(7 downto 4);
			end if;
			if (addr_decoded(12)='1') then
				envelope_attack_b_next <= di(7 downto 4);
				envelope_decay_b_next <= di(3 downto 0);
			end if;
			if (addr_decoded(13)='1') then
				envelope_sustain_b_next <= di(7 downto 4);
				envelope_release_b_next <= di(3 downto 0);
			end if;

			--ch c
			if (addr_decoded(14)='1') then
				freq_adj_channel_c_next(7 downto 0) <= di;
			end if;
			if (addr_decoded(15)='1') then
				freq_adj_channel_c_next(15 downto 8) <= di;
			end if;
			if (addr_decoded(16)='1') then
				pulse_width_channel_c_next(7 downto 0) <= di;
			end if;
			if (addr_decoded(17)='1') then
				pulse_width_channel_c_next(11 downto 8) <= di(3 downto 0);
			end if;
			if (addr_decoded(18)='1') then
				control_c_next <= di(3 downto 0);
				waveselect_c_next <= di(7 downto 4);
			end if;
			if (addr_decoded(19)='1') then
				envelope_attack_c_next <= di(7 downto 4);
				envelope_decay_c_next <= di(3 downto 0);
			end if;
			if (addr_decoded(20)='1') then
				envelope_sustain_c_next <= di(7 downto 4);
				envelope_release_c_next <= di(3 downto 0);
			end if;

			--filter
			if (addr_decoded(21)='1') then
				statevariable_fcutoff_next(2 downto 0) <= di(2 downto 0);
			end if;
			if (addr_decoded(22)='1') then
				statevariable_fcutoff_next(10 downto 3) <= di;
			end if;
			if (addr_decoded(23)='1') then
				statevariable_Q_next <= di(7 downto 4);
				filter_en_next <= di(3 downto 0);
			end if;
			if (addr_decoded(24)='1') then
				ch3silence_next <= di(7);
				filter_sel_next <= di(6 downto 4);
				vol_next <= di(3 downto 0);
			end if;
		end if;
	end process;
	
	process(addr_decoded,
		wave_c_reg,
		envelope_c_reg
		)
	begin
		do <= (others=>'0');
	
		--if (addr_decoded(25)='1') then
		--	do <= potx_reg;
		--end if;
		--if (addr_decoded(26)='1') then
		--	do <= poty_reg;
		--end if;
		if (addr_decoded(27)='1') then
			do <= wave_c_reg(7 downto 0);
		end if;
		if (addr_decoded(28)='1') then
			do <= envelope_c_reg;
		end if;
	end process;	

	-- osc a
	osc_a : entity work.SID_oscillator
	PORT MAP
	(
		CLK => clk,
		RESET_N => reset_n,
		ENABLE => enable,
		
		BITS_OUT => osc_a_reg,

		SYNC_IN => sync_a,
		SYNC_OUT => osc_a_sync_out,
		
		ADJ => freq_adj_channel_a_reg
	);
	sync_a <= control_a_reg(1) and osc_c_sync_out;

	-- osc b
	osc_b : entity work.SID_oscillator
	PORT MAP
	(
		CLK => clk,
		RESET_N => reset_n,
		ENABLE => enable,
		
		BITS_OUT => osc_b_reg,

		SYNC_IN => sync_b,
		SYNC_OUT => osc_b_sync_out,
		
		ADJ => freq_adj_channel_b_reg
	);
	sync_b <= control_b_reg(1) and osc_a_sync_out;

	-- osc c
	osc_c : entity work.SID_oscillator
	PORT MAP
	(
		CLK => clk,
		RESET_N => reset_n,
		ENABLE => enable,
		
		BITS_OUT => osc_c_reg,

		SYNC_IN => sync_c,
		SYNC_OUT => osc_c_sync_out,
		
		ADJ => freq_adj_channel_c_reg
	);
	sync_c <= control_c_reg(1) and osc_b_sync_out;

	--wave generator mux
	wavegen : entity work.SID_wavegen_mux
	PORT MAP
	(
		CLK => clk,
		RESET_N => reset_n,

		OSCA_IN => osc_a_reg,
		OSCB_IN => osc_b_reg,
		OSCC_IN => osc_c_reg,

		WAVESELECT_A_IN => waveselect_a_reg,
		WAVESELECT_B_IN => waveselect_b_reg,
		WAVESELECT_C_IN => waveselect_c_reg,

		WAVE_DATA_REQUEST => wave_data_request,
		WAVE_DATA_REPLY => wave_data_reply
	);
	
	-- noise
	--17-bit LFSR with taps at bits 17 and 14
	--ref:https://listengine.tuxfamily.org/lists.tuxfamily.org/hatari-devel/2012/09/msg00045.html	
	
	-- noise freq->noise_tick->noise_val
	noise_ticker : entity work.SID_freqdiv
	GENERIC MAP
	(
		bits => 5
	)	
	PORT MAP
	(
		CLK => clk,
		RESET_N => reset_n,
		ENABLE => core_tick,
		
		BIT_OUT => noise_tick,
		
		THRESHOLD => unsigned(period_noise_reg)
	);
	
	noise : entity work.SID_noise
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,
		ENABLE => noise_tick,
		
		BIT_OUT => noise_lfsr_tick
	);
	
	-- mix noise and channel
	mix_a : entity work.SID_mixer
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,		
		ENABLE => enable,
		
		NOISE => noise_lfsr_tick,
		CHANNEL => channel_a_tick,
		
		NOISE_OFF => mixer_noise_reg(0),
		TONE_OFF => mixer_tone_reg(0),
		
		BIT_OUT => channel_a_val
	);
	
	mix_b : entity work.SID_mixer
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,		
		ENABLE => enable,
		
		NOISE => noise_lfsr_tick,
		CHANNEL => channel_b_tick,
		
		NOISE_OFF => mixer_noise_reg(1),
		TONE_OFF => mixer_tone_reg(1),		
		
		BIT_OUT => channel_b_val
	);	
	
	mix_c : entity work.SID_mixer
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,		
		ENABLE => enable,
		
		NOISE => noise_lfsr_tick,
		CHANNEL => channel_c_tick,
		
		NOISE_OFF => mixer_noise_reg(2),
		TONE_OFF => mixer_tone_reg(2),		
		
		BIT_OUT => channel_c_val
	);		

	-- envelope
	envelope : entity work.SID_envelope
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,		
		ENABLE => core_tick,
		
		STEP32 => envelope32,
		COUNT_RESET => envelope_count_reset,
		SHAPE => shape_envelope_reg,
		PERIOD => period_envelope_reg,

		ENVELOPE => envelope_reg
	);		
	
	-- volume
	vol_a : entity work.SID_volume
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,		
		ENABLE => enable,
		
		CHANNEL => channel_a_val,
		FIXED => vol_channel_a_reg,
		ENVELOPE => envelope_reg,
		
		VOL_OUT => channel_a_vol
	);		
	
	vol_b : entity work.SID_volume
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,		
		ENABLE => enable,
		
		CHANNEL => channel_b_val,
		FIXED => vol_channel_b_reg,
		ENVELOPE => envelope_reg,
		
		VOL_OUT => channel_b_vol
	);		
	
	vol_c : entity work.SID_volume
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,		
		ENABLE => enable,
		
		CHANNEL => channel_c_val,
		FIXED => vol_channel_c_reg,
		ENVELOPE => envelope_reg,
		
		VOL_OUT => channel_c_vol
	);		
	
	-- combine channels/apply log volume curve
	vol_profile1 : entity work.SID_volume_profile
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,		
		ENABLE => enable,
		
		CHANNEL_A => channel_a_vol,
		CHANNEL_B => channel_b_vol,
		CHANNEL_C => channel_c_vol,

		CHANNEL_MASK => mask1,
		
		AUDIO_OUT => audio1_reg
	);	

	vol_profile2 : entity work.SID_volume_profile
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,		
		ENABLE => enable,
		
		CHANNEL_A => channel_a_vol,
		CHANNEL_B => channel_b_vol,
		CHANNEL_C => channel_c_vol,

		CHANNEL_MASK => mask2,
		
		AUDIO_OUT => audio2_reg
	);	

	--outputs
	
	AUDIO <= audio_reg;
	
end vhdl;


