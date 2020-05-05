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

ENTITY SID_wavegen_mux IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;

	OSCA_IN : IN STD_LOGIC_VECTOR(11 downto 0);
	OSCB_IN : IN STD_LOGIC_VECTOR(11 downto 0);
	OSCC_IN : IN STD_LOGIC_VECTOR(11 downto 0);

	WAVESELECT_A_IN  : IN STD_LOGIC_VECTOR(3 downto 0);
	WAVESELECT_B_IN  : IN STD_LOGIC_VECTOR(3 downto 0);
	WAVESELECT_C_IN  : IN STD_LOGIC_VECTOR(3 downto 0);

	WAVE_DATA_REQUEST : OUT MEM_READ_8BIT_REQUEST;
	WAVE_DATA_REPLY : IN MEM_READ_8BIT_READY
);
END SID_wavegen_mux;

ARCHITECTURE vhdl OF SID_wavegen_mux IS
	signal CHANNEL_REG : STD_LOGIC_VECTOR(3 downto 0) := "1000";
	-- 1000->0
	-- 0100->1
	-- 0010->2
	-- 0001->3
BEGIN

process(clk)
begin
	if (clk'event and clk='1') then
		CHANNEL_REG <= CHANNEL_NEXT;
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

