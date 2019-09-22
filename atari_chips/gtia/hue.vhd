---------------------------------------------------------------------------
-- (c) 2017 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE ieee.math_real.ceil;
USE ieee.math_real.log2;
use IEEE.STD_LOGIC_MISC.all;

ENTITY hue IS
PORT 
( 
	clk : in std_logic;
	reset_n : in std_logic;

	hue : in std_logic_vector(3 downto 0);
	burst : in std_logic;
	blank : in std_logic;
	vpos_lsb : in std_logic;
	pal : in std_logic;

	colour_osc : in std_logic_vector(1 downto 0);
	colour_osc_phased : out std_logic_vector(1 downto 0)
);
END hue;

ARCHITECTURE vhdl OF hue IS
	signal sin_phase : std_logic_vector(7 downto 0);
	--signal sin_phase_real :real;
	signal sin_on : std_logic;

	signal hue_adj : std_logic_vector(3 downto 0);
	signal hue_delay : std_logic_vector(3 downto 0);
	signal colour_shift : std_logic_vector(7 downto 0);
	signal base_shift : std_logic_vector(7 downto 0);

	signal colour_osc_delay_next : std_logic_vector(511 downto 0);
	signal colour_osc_delay_reg : std_logic_vector(511 downto 0);

	signal colour_osc_phased_next : std_logic_vector(1 downto 0);
	signal colour_osc_phased_reg : std_logic_vector(1 downto 0);
BEGIN
	process(clk,reset_n)
	begin
		if (reset_n='0') then
			colour_osc_delay_reg <= (others=>'0');
			colour_osc_phased_reg <= "00";
		elsif (clk'event and clk='1') then
			colour_osc_delay_reg <= colour_osc_delay_next;
			colour_osc_phased_reg <= colour_osc_phased_next;
		end if;
	end process;

	-- next state
	process(colour_osc_delay_reg,colour_osc)
	begin
		colour_osc_delay_next(511 downto 0) <= colour_osc_delay_reg(509 downto 0)&colour_osc;
	end process;

	process(colour_osc_delay_reg,sin_phase,sin_on)
		variable idx : integer;
	begin
		idx := to_integer(unsigned(sin_phase))/2;
		colour_osc_phased_next <= colour_osc_delay_reg(idx+1 downto idx);
	end process;

	-- 4.43361875MHz - PAL carrier  - i.e. 12.8 clock cycles per sin wave! so if we have 256 sine entries,+5*16/4 per cycle, +20 per cycle
	-- 3.579545MHz   - NTSC carrier - i.e. 16 clock cycles per sin wave. so if we have 256 sine entries,+16 per cycle
	-- NTSC:hue1=same phase as colour carrier, each next has 24 degree shift (adjustable) ... 17.066/256? Will 17 do?
	-- PAL:hue1=same phase as colour burst, each next has 22.5 degree shift (adjustable). adjust phase each line. 135/225 degrees for burst/hue1... 16/256, nice!

	process(hue,hue_adj,vpos_lsb,burst,pal)
		variable hue_use : std_logic_vector(3 downto 0);
	begin
		hue_adj <= "0000";

		hue_use := hue;

		if (burst = '1') then
			hue_use := x"1";
		end if;

		if pal='1' then
			-- pal has some gaps...
			if (unsigned(hue_use)>6) then
				hue_adj <= "000"&pal;
			end if;

			if (unsigned(hue_use)>10) then
				hue_adj <= "00"&pal&"0";
			end if;

			if vpos_lsb='1' then
				hue_delay <= std_logic_vector(to_unsigned(0,4)-unsigned(hue_use)-unsigned(hue_adj)); 
			else
				hue_delay <= std_logic_vector(to_unsigned(2,4)+unsigned(hue_use)+unsigned(hue_adj)); 
			end if;
		else
			hue_delay <= std_logic_vector(to_unsigned(0,4)-unsigned(hue_use));
		end if;
	end process;

	process(hue_delay,pal)
	begin
		colour_shift <= hue_delay&"0000";
		if pal='0' then
			colour_shift <= std_logic_vector(unsigned(hue_delay&"0000") + unsigned("000"&hue_delay&"0"));
		end if;
	end process;

	process(pal)
	begin
		if (pal = '1') then
			base_shift <= std_logic_vector(to_unsigned(112,8)); -- 157.5 degrees (256*157.5/360)
		else
			base_shift <= std_logic_vector(to_unsigned(248,8)); -- -12 degrees (256*348/360)
		end if;
	end process;

	process(blank,burst,colour_shift,hue,sin_phase,base_shift)
	begin
		sin_on <= '0';

		sin_phase <=std_logic_vector(unsigned(base_shift)+unsigned(colour_shift));
		--sin_phase_real <= real(to_integer(unsigned(sin_phase)))*real(360)/real(256);

		if (blank='1') then
			sin_on <= burst;
		else
			sin_on <= or_reduce(hue);
		end if;
	end process;

	colour_osc_phased <= colour_osc_phased_reg when sin_on='1' else "00";

END vhdl;

