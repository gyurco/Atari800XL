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
use work.AudioTypes.all;

LIBRARY work;

ENTITY mixer IS 
PORT
(
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;

	ENABLE_CYCLE : IN STD_LOGIC;

	FANCY_ENABLE : IN STD_LOGIC;
	DETECT_RIGHT : IN STD_LOGIC;
	GTIA_ENABLE : IN STD_LOGIC_VECTOR(3 downto 0);
	POST_DIVIDE : IN STD_LOGIC_VECTOR(7 downto 0);

	POKEY_AUDIO_0 : IN UNSIGNED(15 downto 0);
	POKEY_AUDIO_1 : IN UNSIGNED(15 downto 0);
	POKEY_AUDIO_2 : IN UNSIGNED(15 downto 0);
	POKEY_AUDIO_3 : IN UNSIGNED(15 downto 0);
	SAMPLE_AUDIO : IN SAMPLE_AUDIO_TYPE(1 downto 0);
	SID_AUDIO : IN SID_AUDIO_TYPE(1 downto 0);
	PSG_AUDIO : IN PSG_AUDIO_TYPE(1 downto 0);
	GTIA_AUDIO : IN STD_LOGIC;

	AUDIO_0_UNSIGNED : out unsigned(15 downto 0);
	AUDIO_1_UNSIGNED : out unsigned(15 downto 0);
	AUDIO_2_UNSIGNED : out unsigned(15 downto 0);
	AUDIO_3_UNSIGNED : out unsigned(15 downto 0)
);
END mixer;		
		
ARCHITECTURE vhdl OF mixer IS
	-- DETECT RIGHT PLAYING
	signal RIGHT_PLAYING_RECENTLY : std_logic;
	signal RIGHT_NEXT : std_logic;
	signal RIGHT_REG : std_logic;
	signal RIGHT_PLAYING_COUNT_NEXT : unsigned(23 downto 0);
	signal RIGHT_PLAYING_COUNT_REG : unsigned(23 downto 0);
	
BEGIN
-- DETECT IF RIGHT CHANNEL PLAYING
-- TODO: into another entity
process(clk,reset_n)
begin
	if (reset_n='0') then
		RIGHT_REG <= '0';
		RIGHT_PLAYING_COUNT_REG <= (others=>'0');
	elsif (clk'event and clk='1') then
		RIGHT_REG <= RIGHT_NEXT;
		RIGHT_PLAYING_COUNT_REG <= RIGHT_PLAYING_COUNT_NEXT;
	end if;
end process;

process(RIGHT_NEXT,RIGHT_REG,ENABLE_CYCLE,RIGHT_PLAYING_RECENTLY,RIGHT_PLAYING_COUNT_REG)
begin
	RIGHT_PLAYING_COUNT_NEXT <= RIGHT_PLAYING_COUNT_REG;

	if (ENABLE_CYCLE='1' and RIGHT_PLAYING_RECENTLY='1') then
		RIGHT_PLAYING_COUNT_NEXT <= RIGHT_PLAYING_COUNT_REG-1;
	end if;

	if (RIGHT_NEXT/=RIGHT_REG) then
		RIGHT_PLAYING_COUNT_NEXT <= (others=>'1');
	end if;
end process;
RIGHT_PLAYING_RECENTLY <= or_reduce(std_logic_vector(RIGHT_PLAYING_COUNT_REG));

process(POST_DIVIDE,
	POKEY_AUDIO_0,POKEY_AUDIO_1,POKEY_AUDIO_2,POKEY_AUDIO_3, --signed
	SAMPLE_AUDIO,
	SID_AUDIO,
	PSG_AUDIO,
	GTIA_AUDIO,GTIA_ENABLE,
	FANCY_ENABLE,
	RIGHT_PLAYING_RECENTLY,
	DETECT_RIGHT
	)
	variable p0u : unsigned(19 downto 0);
	variable p1u : unsigned(19 downto 0);
	variable p2u : unsigned(19 downto 0);
	variable p3u : unsigned(19 downto 0);

	variable a0u : unsigned(19 downto 0);
	variable a1u : unsigned(19 downto 0);
	variable a2u: unsigned(19 downto 0);
	variable a3u: unsigned(19 downto 0);

	variable gtia0u : unsigned(19 downto 0);
	variable gtia1u : unsigned(19 downto 0);
	variable gtia2u: unsigned(19 downto 0);
	variable gtia3u: unsigned(19 downto 0);

	variable sidu: unsigned(19 downto 0);
	variable psgu: unsigned(19 downto 0);
	variable samu: unsigned(19 downto 0);
begin
-- 
--  0: pokey0,pokey2, pokeych1, sid0,ym0,covox0,sample0, gtia, sio in
--  1: pokey1,pokey3, pokeych2, sid1,ym1,covox1,sample1, gtia, sio in
--  2: pokey0,pokey2, pokeych3, sid0,ym0,covox0,sample0, gtia, sio in
--  3: pokey1,pokey3, pokeych4, sid1,ym1,covox1,sample1, gtia, sio in  
	gtia0u:= (others=>'0');
	gtia0u(15):= GTIA_AUDIO and GTIA_ENABLE(0);
	gtia1u:= (others=>'0');
	gtia1u(15):= GTIA_AUDIO and GTIA_ENABLE(1);
	gtia2u:= (others=>'0');
	gtia2u(15):= GTIA_AUDIO and GTIA_ENABLE(2);
	gtia3u:= (others=>'0');
	gtia3u(15):= GTIA_AUDIO and GTIA_ENABLE(3);

	p0u(19 downto 0) := (others=>'0');
	p1u(19 downto 0) := (others=>'0');
	p2u(19 downto 0) := (others=>'0');
	p3u(19 downto 0) := (others=>'0');
	p0u(15 downto 0) := POKEY_AUDIO_0(15 downto 0);
	p1u(15 downto 0) := POKEY_AUDIO_1(15 downto 0);
	p2u(15 downto 0) := POKEY_AUDIO_2(15 downto 0);
	p3u(15 downto 0) := POKEY_AUDIO_3(15 downto 0);

	sidu := resize(unsigned(sid_audio(0)),20);
	psgu := resize(unsigned(psg_audio(0)),20);
	samu := resize(unsigned(sample_audio(0)),20);
	a0u := p0u + p2u + sidu + psgu + samu;

	sidu := resize(unsigned(sid_audio(1)),20);
	psgu := resize(unsigned(psg_audio(1)),20);
	samu := resize(unsigned(sample_audio(1)),20);

	a1u := p1u + p3u + sidu + psgu + samu;
	RIGHT_NEXT <= xor_reduce(std_logic_vector(a1u));
	if (FANCY_ENABLE='0' or (RIGHT_PLAYING_RECENTLY='0' AND DETECT_RIGHT='1')) then
		a1u := a0u;
	end if;
	a2u := a0u;
	a3u := a1u;

	a0u := a0u + gtia0u;
	a1u := a1u + gtia1u;
	a2u := a2u + gtia2u;
	a3u := a3u + gtia3u;

	case POST_DIVIDE(1 downto 0) is
		when "01" =>
			a0u := '0'&a0u(19 downto 1);
		when "10" =>
			a0u := "00"&a0u(19 downto 2);
		when "11" =>
			a0u := "000"&a0u(19 downto 3);
		when others =>
	end case;
	
	case POST_DIVIDE(3 downto 2) is
		when "01" =>
			a1u := '0'&a1u(19 downto 1);
		when "10" =>
			a1u := "00"&a1u(19 downto 2);
		when "11" =>
			a1u := "000"&a1u(19 downto 3);
		when others =>
	end case;

	case POST_DIVIDE(5 downto 4) is
		when "01" =>
			a2u := '0'&a2u(19 downto 1);
		when "10" =>
			a2u := "00"&a2u(19 downto 2);
		when "11" =>
			a2u := "000"&a2u(19 downto 3);
		when others =>
	end case;
	
	case POST_DIVIDE(7 downto 6) is
		when "01" =>
			a3u := '0'&a3u(19 downto 1);
		when "10" =>
			a3u := "00"&a3u(19 downto 2);
		when "11" =>
			a3u := "000"&a3u(19 downto 3);
		when others =>
	end case;	

	if or_reduce(std_logic_vector(a0u(19 downto 16)))='1' then
		AUDIO_0_UNSIGNED <= (others=>'1');
	else
		AUDIO_0_UNSIGNED <= a0u(15 downto 0);
	end if;
		
	if or_reduce(std_logic_vector(a1u(19 downto 16)))='1' then
		AUDIO_1_UNSIGNED <= (others=>'1');
	else
		AUDIO_1_UNSIGNED <= a1u(15 downto 0);
	end if;
	
	if or_reduce(std_logic_vector(a2u(19 downto 16)))='1' then
		AUDIO_2_UNSIGNED <= (others=>'1');
	else
		AUDIO_2_UNSIGNED <= a2u(15 downto 0);
	end if;
	
	if or_reduce(std_logic_vector(a3u(19 downto 16)))='1' then
		AUDIO_3_UNSIGNED <= (others=>'1');
	else
		AUDIO_3_UNSIGNED <= a3u(15 downto 0);
	end if;
end process;
end vhdl;
