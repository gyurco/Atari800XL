---------------------------------------------------------------------------
-- (c) 2014 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_MISC.all;

ENTITY pokey_mixer_mux IS
GENERIC
(
	lowpass : integer :=1 -- simple low pass. Was made for HDMI so can be turned off here with little impact to save resources. 
);
PORT 
( 
	CLK : IN STD_LOGIC;

	ENABLE_179 : IN STD_LOGIC;

	CHANNEL_L_0 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_L_1 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_L_2 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_L_3 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_L2_0 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_L2_1 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_L2_2 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_L2_3 : IN STD_LOGIC_VECTOR(3 downto 0);

	CHANNEL_R_0 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_R_1 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_R_2 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_R_3 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_R2_0 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_R2_1 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_R2_2 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_R2_3 : IN STD_LOGIC_VECTOR(3 downto 0);

	GTIA_AUDIO : IN STD_LOGIC;
	
	VOLUME_OUT_M : OUT STD_LOGIC_vector(15 downto 0);
	VOLUME_OUT_L : OUT STD_LOGIC_vector(15 downto 0);
	VOLUME_OUT_R : OUT STD_LOGIC_vector(15 downto 0)
);
END pokey_mixer_mux;

ARCHITECTURE vhdl OF pokey_mixer_mux IS
	signal CHANNEL_NEXT : STD_LOGIC_VECTOR(2 downto 0);
	signal CHANNEL_REG : STD_LOGIC_VECTOR(2 downto 0) := "100";
	-- 100->left
	-- 010->right
	-- 001->both!

	signal CHANNEL_0_SEL : STD_LOGIC_VECTOR(3 downto 0);
	signal CHANNEL_1_SEL : STD_LOGIC_VECTOR(3 downto 0);
	signal CHANNEL_2_SEL : STD_LOGIC_VECTOR(3 downto 0);
	signal CHANNEL_3_SEL : STD_LOGIC_VECTOR(3 downto 0);

	signal VOLUME_OUT_NEXT : STD_LOGIC_VECTOR(15 downto 0);

	signal VOLUME_OUT_L_NEXT : STD_LOGIC_VECTOR(15 downto 0);
	signal VOLUME_OUT_L_REG : STD_LOGIC_VECTOR(15 downto 0);
	signal VOLUME_OUT_R_NEXT : STD_LOGIC_VECTOR(15 downto 0);
	signal VOLUME_OUT_R_REG : STD_LOGIC_VECTOR(15 downto 0);
	signal VOLUME_OUT_M_NEXT : STD_LOGIC_VECTOR(15 downto 0);
	signal VOLUME_OUT_M_REG : STD_LOGIC_VECTOR(15 downto 0);

	signal VOLUME_POSTLOWPASS_L_REG : STD_LOGIC_VECTOR(15 downto 0);
	signal VOLUME_POSTLOWPASS_R_REG : STD_LOGIC_VECTOR(15 downto 0);
	signal VOLUME_POSTLOWPASS_M_REG : STD_LOGIC_VECTOR(15 downto 0);

	signal channel_sum : std_logic_vector(7 downto 0);
BEGIN

process(clk)
begin
	if (clk'event and clk='1') then
		CHANNEL_REG <= CHANNEL_NEXT;
		CHANNEL_REG <= CHANNEL_NEXT;

		VOLUME_OUT_L_REG <= VOLUME_OUT_L_NEXT;
		VOLUME_OUT_R_REG <= VOLUME_OUT_R_NEXT;
		VOLUME_OUT_M_REG <= VOLUME_OUT_M_NEXT;
	END IF;
END PROCESS;

-- takes a few cycles for each channel
CHANNEL_NEXT(1 downto 0) <= CHANNEL_REG(2 downto 1);
CHANNEL_NEXT(2) <= CHANNEL_REG(0);
CHANNEL_NEXT(1 downto 0) <= CHANNEL_REG(2 downto 1);
CHANNEL_NEXT(2) <= CHANNEL_REG(0);

-- mux input
PROCESS(
	CHANNEL_L_0, CHANNEL_L_1, CHANNEL_L_2, CHANNEL_L_3,
	CHANNEL_R_0, CHANNEL_R_1, CHANNEL_R_2, CHANNEL_R_3,
	GTIA_AUDIO,
	channel_reg
	)
	variable left_sum : unsigned(7 downto 0);
	variable right_sum : unsigned(7 downto 0);
	variable both_sum : unsigned(7 downto 0);
	variable gtia_sum : unsigned(7 downto 0);
	variable left_gtia_sum : unsigned(7 downto 0);
	variable right_gtia_sum : unsigned(7 downto 0);
BEGIN
	channel_sum <= (OTHERS=>'0');

	left_sum := 
		(resize(unsigned(CHANNEL_L_0),8) + resize(unsigned(CHANNEL_L_1),8)) +
		(resize(unsigned(CHANNEL_L_2),8) + resize(unsigned(CHANNEL_L_3),8)) +
		(resize(unsigned(CHANNEL_L2_0),8) + resize(unsigned(CHANNEL_L2_1),8)) +
		(resize(unsigned(CHANNEL_L2_2),8) + resize(unsigned(CHANNEL_L2_3),8));
	right_sum := 
		(resize(unsigned(CHANNEL_R_0),8) + resize(unsigned(CHANNEL_R_1),8)) +
		(resize(unsigned(CHANNEL_R_2),8) + resize(unsigned(CHANNEL_R_3),8)) +
		(resize(unsigned(CHANNEL_R2_0),8) + resize(unsigned(CHANNEL_R2_1),8)) +
		(resize(unsigned(CHANNEL_R2_2),8) + resize(unsigned(CHANNEL_R2_3),8));
	if (gtia_audio='1') then
		gtia_sum := to_unsigned(8,8); -- TODO: review volume
	else
		gtia_sum := to_unsigned(0,8);
	end if;
	both_sum := left_sum + right_sum;
	left_gtia_sum := left_sum + gtia_sum;
	right_gtia_sum := right_sum + gtia_sum;

	case channel_reg is
	when "100" => -- left
		channel_sum <= std_logic_vector(left_gtia_sum);
	when "010" => -- right
		channel_sum <= std_logic_vector(right_gtia_sum);
	when others => -- both
		channel_sum <= std_logic_vector(both_sum);
	end case;

END PROCESS;

-- shared mixer
shared_pokey_mixer : entity work.pokey_mixer
	port map
	(
		CLK => CLK, -- takes 2 cycle...

		sum => channel_sum,

		VOLUME_OUT_NEXT => VOLUME_OUT_NEXT
	);

-- mux output
PROCESS(
	VOLUME_OUT_NEXT,
	VOLUME_OUT_L_REG,
	VOLUME_OUT_R_REG,
	VOLUME_OUT_M_REG,
	CHANNEL_REG)
BEGIN
	VOLUME_OUT_L_NEXT <= VOLUME_OUT_L_REG;
	VOLUME_OUT_R_NEXT <= VOLUME_OUT_R_REG;
	VOLUME_OUT_M_NEXT <= VOLUME_OUT_M_REG;

	case channel_reg is
	when "010" => -- left
		VOLUME_OUT_L_NEXT <= VOLUME_OUT_NEXT;
	when "001" => -- right
		VOLUME_OUT_R_NEXT <= VOLUME_OUT_NEXT;
	when others => -- both
		VOLUME_OUT_M_NEXT <= VOLUME_OUT_NEXT;
	end case;
END PROCESS;


-- low pass filter output
gen_lowpass_on : if lowpass=1 generate
filter_left : entity work.simple_low_pass_filter
	port map
	(
		CLK => CLK,
		AUDIO_IN => VOLUME_OUT_L_REG,
		SAMPLE_IN => ENABLE_179,
		AUDIO_OUT => VOLUME_POSTLOWPASS_L_REG
	);
filter_right : entity work.simple_low_pass_filter
	port map
	(
		CLK => CLK,
		AUDIO_IN => VOLUME_OUT_R_REG,
		SAMPLE_IN => ENABLE_179,
		AUDIO_OUT => VOLUME_POSTLOWPASS_R_REG
	);
filter_both : entity work.simple_low_pass_filter
	port map
	(
		CLK => CLK,
		AUDIO_IN => VOLUME_OUT_M_REG,
		SAMPLE_IN => ENABLE_179,
		AUDIO_OUT => VOLUME_POSTLOWPASS_M_REG
	);
end generate;

gen_lowpass_off : if lowpass=0 generate
VOLUME_POSTLOWPASS_L_REG<=VOLUME_OUT_L_REG;
VOLUME_POSTLOWPASS_M_REG<=VOLUME_OUT_M_REG;
VOLUME_POSTLOWPASS_R_REG<=VOLUME_OUT_R_REG;
end generate;

-- output
	VOLUME_OUT_L <= VOLUME_POSTLOWPASS_L_REG;
	VOLUME_OUT_R <= VOLUME_POSTLOWPASS_R_REG;
	VOLUME_OUT_M <= VOLUME_POSTLOWPASS_M_REG;

END vhdl;

