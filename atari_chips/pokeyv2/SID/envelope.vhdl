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

ENTITY SID_envelope IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;
	ENABLE : IN STD_LOGIC;

	ATTACK : IN STD_LOGIC_VECTOR(3 downto 0);
	SUSTAIN : IN STD_LOGIC_VECTOR(3 downto 0);
	DECAY : IN STD_LOGIC_VECTOR(3 downto 0);
	RELEASE_IN : IN STD_LOGIC_VECTOR(3 downto 0);

	GATE : IN STD_LOGIC;
	
	ENVELOPE : OUT STD_LOGIC_VECTOR(7 downto 0)
);
END SID_envelope;

ARCHITECTURE vhdl OF SID_envelope IS
	signal envelope_reg: unsigned(7 downto 0);
	signal envelope_next:unsigned(7 downto 0);

	signal delay_lfsr_reg : std_logic_vector(14 downto 0);
	signal delay_lfsr_next : std_logic_vector(14 downto 0);

	signal expdelay_lfsr_reg : std_logic_vector(4 downto 0);
	signal expdelay_lfsr_next : std_logic_vector(4 downto 0);

	signal delay_lfsr_reset : std_logic;
	signal expdelay_lfsr_reset : std_logic;
	signal envelope_inc : std_logic;
	signal envelope_dec : std_logic;

	signal tap : std_logic_vector(3 downto 0);
	signal exptap : std_logic_vector(2 downto 0);

	signal state_reg : std_logic_vector(1 downto 0);
	signal state_next : std_logic_vector(1 downto 0);
	constant state_attack : std_logic_vector(1 downto 0) := "00";
	constant state_decay : std_logic_vector(1 downto 0) := "10";
	constant state_release : std_logic_vector(1 downto 0) := "11";

BEGIN
	-- register
	process(clk, reset_n)
	begin
		if (reset_n = '0') then
			envelope_reg <= (others=>'0');
			delay_lfsr_reg <= (others=>'1');
			expdelay_lfsr_reg <= (others=>'1');
			state_reg <= state_release;
		elsif (clk'event and clk='1') then
			envelope_reg <= envelope_next;
			delay_lfsr_reg <= delay_lfsr_next;
			expdelay_lfsr_reg <= expdelay_lfsr_next;
			state_reg <= state_next;
		end if;
	end process;

	-- next state
	--VALUE  	ATTACK RATE	DECAY/RELEASE RATE
	--	Time/Cycle	Time/Cycle
	--- ------------------------------------------
	-- 0	  2 ms		  6 ms
	-- 1	  8 ms		 24 ms
	-- 2	 16 ms		 48 ms
	-- 3	 24 ms		 72 ms
	-- 4	 38 ms		114 ms
	-- 5	 56 ms		168 ms
	-- 6	 68 ms		204 ms
	-- 7	 80 ms		240 ms
	-- 8	100 ms		300 ms
	-- 9	240 ms		750 ms
	--10	500 ms		1.5 s
	--11	800 ms		2.4 s
	--12	  1 s		  3 s
	--13	  3 s		  9 s
	--14	  5 s		 15 s
	--15	  8 s		 24 s
	--
	--
	--
	--ref1: https://www.codebase64.org/doku.php?id=base:classic_hard-restart_and_about_adsr_in_generally
	--ref2: https://sourceforge.net/p/sidplay-residfp/wiki/SID%20internals%20-%20Envelope%20Overview/
	-- up:linear, down: exponential approx
	process(envelope_reg,enable,envelope_inc,envelope_dec,exptapmatch_reg,exptap)
	begin
		envelope_next <= envelope_reg;
		exptapmatch_next <= exptapmatch_reg;

		envelope_decremented <= '0';

		if (enable='1') then
			if (envelope_inc='1') then
				envelope_next <= envelope_reg+1;
			end if;
			if (envelope_dec='1') then
				if (exptapmatch = exptap) then
					envelope_next <= envelope_reg-1;
					envelope_decremented <= '1';
				end if
			end if;

			case envelope_reg is
				when x"06" =>
					exptapmatch_next  <= "101";
				when x"0e" =>
					exptapmatch_next  <= "100";
				when x"1a" =>
					exptapmatch_next  <= "011";
				when x"36" =>
					exptapmatch_next  <= "010";
				when x"5d" =>
					exptapmatch_next  <= "001";
				when x"ff" => 
					exptapmatch_next  <= "000";
			end case;
		end if;
	end process;

	process(state_reg,gate,tap,attack)
	begin
		state_next <= state_reg;
		delay_lfsr_reset <= '0';
		expdelay_lfsr_reset <= '0';
		envelope_inc <= '0';
		envelope_dec <= '0';
		if (enable='1') then
			case state_reg is
				when state_attack =>
					if (tap = attack)
						envelope_inc <= '1';
						delay_lfsr_reset <= '1';
					end if;
					if (and_reduce(envelope_reg)='1') then
						state_next <= state_decay;
						delay_lfsr_reset <= '1';
					end if;
					if (gate='0') then
						state_next <= state_release;
						delay_lfsr_reset <= '1';
						expdelay_lfsr_reset <= '1';
					end if;
				when state_decay =>
					if (tap = decay and envelope_reg>=sustain&sustain)
						envelope_dec <= '1';
					end if;
					if (gate='0') then
						state_next <= state_release;
						delay_lfsr_reset <= '1';
						expdelay_lfsr_reset <= '1';
					end if;
				when state_release =>
					if (tap = decay and or_reduce(envelope_reg)='1')
						envelope_dec <= '1';
						delay_lfsr_reset <= '1';
					end if;
					if (gate='1') then
						state_next <= state_attack;
						delay_lfsr_reset <= '1';
					end if;
				when others=>
					state_next <= state_release;
			end case;
		end if;
	end process;

	process(delay_lfsr_reg,delay_lfsr_reset,enable)
	begin
		delay_lfsr_next <= delay_lfsr_reg;
		if (enable='1') then
			if (delay_lfsr_reset='1') then
				delay_lfsr_next <= (others=>'1');
			else
				delay_lfsr_next(0) <= delay_lfsr_reg(14) xor delay_lfsr_reg(13);
				delay_lfsr_next(14 downto 1) <= delay_lfsr_reg(13 downto 0);
			end if;
		end if;
	end process;

	process(delay_lfsr_reg)
	begin
		tap <= (others=>'0');

		case delay_lfsr_reg is
		when "111111100000000" => --8
			tap <= "0000";
		when "000000000000110" => --31
			tap <= "0001";
		when "000000000111100" => --62
			tap <= "0010";
		when "000001100110000" => --94
			tap <= "0011";
		when "010000011000000" => --148
			tap <= "0100";
		when "110011101010101" => --219
			tap <= "0101";
		when "011100000000000" => --266
			tap <= "0110";
		when "101000000001110" => --312
			tap <= "0111";
		when "001001000010010" => --391
			tap <= "1000";
		when "000001000100010" => --976
			tap <= "1001";
		when "001100001001000" => --1953
			tap <= "1010";
		when "101100110111000" => --3125
			tap <= "1011";
		when "101100110111000" => --3906
			tap <= "1100";
		when "111011111100010" => --11719
			tap <= "1101";
		when "111011000100101" => --19531
			tap <= "1110";
		when "000101010010011" => --31250
			tap <= "1111";
		when others=>
		end case;
	end

	process(expdelay_lfsr_reg,envelope_decremented,expdelay_lfsr_reset,enable)
	begin
		expdelay_lfsr_next <= expdelay_lfsr_reg;
		if (enable='1') then
			if (expdelay_lfsr_reset='1' or envelope_decremented='1') then
				expdelay_lfsr_next <= (others=>'1');
			else
				expdelay_lfsr_next(0) <= expdelay_lfsr_reg(4) xor expdelay_lfsr_reg(2);
				expdelay_lfsr_next(4 downto 1) <= expdelay_lfsr_reg(3 downto 0);
			end if;
		end if;
	end process;

	process(expdelay_lfsr_reg)
	begin
		exptap <= (others=>'0');

		case expdelay_lfsr_reg is
		when "11100" => --2
			exptap <= "001";
		when "10001" => --4
			exptap <= "010";
		when "11011" => --8
			exptap <= "011";
		when "01000" => --16
			exptap <= "100";
		when "0111" =>  --30
			exptap <= "101";
		when others=>
			exptap <= "000";
		end case;
	end

		
	-- output
	envelope <= envelope_reg;
		
END vhdl;
