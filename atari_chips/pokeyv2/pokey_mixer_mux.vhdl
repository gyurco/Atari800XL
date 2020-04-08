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

ENTITY pokey_mixer_mux IS
PORT 
( 
	CLK : IN STD_LOGIC;

	ENABLE_179 : IN STD_LOGIC;

	CHANNEL_0 : IN unsigned(5 downto 0);
	CHANNEL_1 : IN unsigned(5 downto 0);
	CHANNEL_2 : IN unsigned(5 downto 0);
	CHANNEL_3 : IN unsigned(5 downto 0);
	
	VOLUME_OUT_0 : OUT SIGNED(15 downto 0);
	VOLUME_OUT_1 : OUT SIGNED(15 downto 0);
	VOLUME_OUT_2 : OUT SIGNED(15 downto 0);
	VOLUME_OUT_3 : OUT SIGNED(15 downto 0);
	
	SATURATE : IN STD_LOGIC
);
END pokey_mixer_mux;

ARCHITECTURE vhdl OF pokey_mixer_mux IS
	signal CHANNEL_NEXT : STD_LOGIC_VECTOR(3 downto 0);
	signal CHANNEL_REG : STD_LOGIC_VECTOR(3 downto 0) := "1000";
	-- 1000->0
	-- 0100->1
	-- 0010->2
	-- 0001->3

	signal CHANNEL_0_SEL : STD_LOGIC_VECTOR(3 downto 0);
	signal CHANNEL_1_SEL : STD_LOGIC_VECTOR(3 downto 0);
	signal CHANNEL_2_SEL : STD_LOGIC_VECTOR(3 downto 0);
	signal CHANNEL_3_SEL : STD_LOGIC_VECTOR(3 downto 0);

	signal VOLUME_OUT_NEXT : signed(15 downto 0);

	signal VOLUME_OUT_0_NEXT : signed(15 downto 0);
	signal VOLUME_OUT_0_REG : signed(15 downto 0);
	signal VOLUME_OUT_1_NEXT : signed(15 downto 0);
	signal VOLUME_OUT_1_REG : signed(15 downto 0);
	signal VOLUME_OUT_2_NEXT : signed(15 downto 0);
	signal VOLUME_OUT_2_REG : signed(15 downto 0);
	signal VOLUME_OUT_3_NEXT : signed(15 downto 0);
	signal VOLUME_OUT_3_REG : signed(15 downto 0);

	signal channel_sum_out : unsigned(5 downto 0);
BEGIN

process(clk)
begin
	if (clk'event and clk='1') then
		CHANNEL_REG <= CHANNEL_NEXT;

		VOLUME_OUT_0_REG <= VOLUME_OUT_0_NEXT;
		VOLUME_OUT_1_REG <= VOLUME_OUT_1_NEXT;
		VOLUME_OUT_2_REG <= VOLUME_OUT_2_NEXT;
		VOLUME_OUT_3_REG <= VOLUME_OUT_3_NEXT;
	END IF;
END PROCESS;

-- takes a few cycles for each channel
CHANNEL_NEXT(2 downto 0) <= CHANNEL_REG(3 downto 1);
CHANNEL_NEXT(3) <= CHANNEL_REG(0);

-- mux input
PROCESS(
	CHANNEL_0,CHANNEL_1,CHANNEL_2,CHANNEL_3,
	channel_reg
	)	
	variable channel_sum : unsigned(5 downto 0);
BEGIN
	channel_sum := (OTHERS=>'0');

	case channel_reg is
   when "1000" => -- 0
		channel_sum := CHANNEL_0;
   when "0100" => -- 1
		channel_sum := CHANNEL_1;
   when "0010" => -- 2
		channel_sum := CHANNEL_2;
   --when "0000001" => -- 3
	when others =>
		channel_sum := CHANNEL_3;
	end case;
	
	channel_sum_out <= channel_sum;

END PROCESS;

-- shared mixer
shared_pokey_mixer : entity work.pokey_mixer
	port map
	(
		CLK => CLK, -- takes 2 cycle...

		sum => channel_sum_out,
		
		saturate => saturate,

		VOLUME_OUT_NEXT => VOLUME_OUT_NEXT
	);

-- mux output
PROCESS(
	VOLUME_OUT_NEXT,
	VOLUME_OUT_0_REG,
	VOLUME_OUT_1_REG,
	VOLUME_OUT_2_REG,
	VOLUME_OUT_3_REG,
	CHANNEL_REG)
BEGIN
	VOLUME_OUT_0_NEXT <= VOLUME_OUT_0_REG;
	VOLUME_OUT_1_NEXT <= VOLUME_OUT_1_REG;
	VOLUME_OUT_2_NEXT <= VOLUME_OUT_2_REG;
	VOLUME_OUT_3_NEXT <= VOLUME_OUT_3_REG;

	case channel_reg is
   when "0100" => -- 0
		VOLUME_OUT_0_NEXT <= VOLUME_OUT_NEXT;
   when "0010" => -- 1
		VOLUME_OUT_1_NEXT <= VOLUME_OUT_NEXT;
   when "0001" => -- 2
		VOLUME_OUT_2_NEXT <= VOLUME_OUT_NEXT;
   when others=>     -- 3
		VOLUME_OUT_3_NEXT <= VOLUME_OUT_NEXT;		
	end case;
END PROCESS;

-- output
	VOLUME_OUT_0 <= signed(VOLUME_OUT_0_REG);
	VOLUME_OUT_1 <= signed(VOLUME_OUT_1_REG);
	VOLUME_OUT_2 <= signed(VOLUME_OUT_2_REG);
	VOLUME_OUT_3 <= signed(VOLUME_OUT_3_REG);

END vhdl;

