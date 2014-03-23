---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY pokey_mixer IS
PORT 
( 
	CLK : IN STD_LOGIC;
	
	CHANNEL_ENABLE : IN STD_LOGIC_VECTOR(3 downto 0);
		
	CHANNEL_0 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_1 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_2 : IN STD_LOGIC_VECTOR(3 downto 0);
	CHANNEL_3 : IN STD_LOGIC_VECTOR(3 downto 0);
	
	GTIA_SOUND : IN STD_LOGIC;
	
	VOLUME_OUT : OUT STD_LOGIC_vector(15 downto 0)
);
END pokey_mixer;

ARCHITECTURE vhdl OF pokey_mixer IS
	signal volume_reg : std_logic_vector(15 downto 0);
	signal volume_next : std_logic_vector(15 downto 0);
	
	signal volume_sum : std_logic_vector(5 downto 0);
	
	signal channel_0_en : std_logic_vector(3 downto 0);
	signal channel_1_en : std_logic_vector(3 downto 0);
	signal channel_2_en : std_logic_vector(3 downto 0);
	signal channel_3_en : std_logic_vector(3 downto 0);
	
	signal gtia_en : std_logic_vector(5 downto 0);
BEGIN
	-- register
	process(clk)
	begin
		if (clk'event and clk='1') then
			volume_reg <= volume_next;
		end if;
	end process;
	
	-- next state
	process(channel_enable,channel_0,channel_1,channel_2,channel_3)
	begin
		channel_0_en <= channel_0;
		channel_1_en <= channel_1;
		channel_2_en <= channel_2;
		channel_3_en <= channel_3;
	
--		if (channel_enable(3)='0') then
--			channel_0_en <= X"0";
--		end if;
--		
--		if (channel_enable(2)='0') then
--			channel_1_en <= X"0";
--		end if;
--
--		if (channel_enable(1)='0') then
--			channel_2_en <= X"0";
--		end if;
--		
--		if (channel_enable(0)='0') then
--			channel_3_en <= X"0";
--		end if;
	end process;
	
	gtia_en <= "0000"&gtia_sound&gtia_sound;  -- only room for 3 more! TODO, regenerate...
	
	process (channel_0_en,channel_1_en,channel_2_en,channel_3_en,gtia_en)
	begin
		volume_sum <= 
			std_logic_vector
			(
					unsigned('0'&(
						unsigned('0'&CHANNEL_0_en)
						+ unsigned('0'&CHANNEL_1_en)
					)) 
					+ 
					unsigned('0'&(
						unsigned('0'&CHANNEL_2_en) + 
						unsigned('0'&CHANNEL_3_en)
					))
					+ 
					unsigned(gtia_en)
			);
	end process;
	
	process (volume_sum)
	begin
		case volume_sum is 
			when "000000" =>
				volume_next <= X"0000";
			when "000001" =>
				volume_next <= X"05e4";
			when "000010" =>
				volume_next <= X"0b90";
			when "000011" =>
				volume_next <= X"1107";
			when "000100" =>
				volume_next <= X"1649";
			when "000101" =>
				volume_next <= X"1b57";
			when "000110" =>
				volume_next <= X"2032";
			when "000111" =>
				volume_next <= X"24db";
			when "001000" =>
				volume_next <= X"2954";
			when "001001" =>
				volume_next <= X"2d9d";
			when "001010" =>
				volume_next <= X"31b8";
			when "001011" =>
				volume_next <= X"35a6";
			when "001100" =>
				volume_next <= X"3968";
			when "001101" =>
				volume_next <= X"3cff";
			when "001110" =>
				volume_next <= X"406b";
			when "001111" =>
				volume_next <= X"43af";
			when "010000" =>
				volume_next <= X"46cc";
			when "010001" =>
				volume_next <= X"49c2";
			when "010010" =>
				volume_next <= X"4c92";
			when "010011" =>
				volume_next <= X"4f3e";
			when "010100" =>
				volume_next <= X"51c7";
			when "010101" =>
				volume_next <= X"542d";
			when "010110" =>
				volume_next <= X"5673";
			when "010111" =>
				volume_next <= X"5898";
			when "011000" =>
				volume_next <= X"5a9f";
			when "011001" =>
				volume_next <= X"5c88";
			when "011010" =>
				volume_next <= X"5e55";
			when "011011" =>
				volume_next <= X"6006";
			when "011100" =>
				volume_next <= X"619d";
			when "011101" =>
				volume_next <= X"631a";
			when "011110" =>
				volume_next <= X"647f";
			when "011111" =>
				volume_next <= X"65ce";
			when "100000" =>
				volume_next <= X"6706";
			when "100001" =>
				volume_next <= X"682a";
			when "100010" =>
				volume_next <= X"6939";
			when "100011" =>
				volume_next <= X"6a37";
			when "100100" =>
				volume_next <= X"6b22";
			when "100101" =>
				volume_next <= X"6bfe";
			when "100110" =>
				volume_next <= X"6cca";
			when "100111" =>
				volume_next <= X"6d88";
			when "101000" =>
				volume_next <= X"6e38";
			when "101001" =>
				volume_next <= X"6edd";
			when "101010" =>
				volume_next <= X"6f77";
			when "101011" =>
				volume_next <= X"7008";
			when "101100" =>
				volume_next <= X"708f";
			when "101101" =>
				volume_next <= X"710f";
			when "101110" =>
				volume_next <= X"7189";
			when "101111" =>
				volume_next <= X"71fe";
			when "110000" =>
				volume_next <= X"726e";
			when "110001" =>
				volume_next <= X"72db";
			when "110010" =>
				volume_next <= X"7347";
			when "110011" =>
				volume_next <= X"73b1";
			when "110100" =>
				volume_next <= X"741c";
			when "110101" =>
				volume_next <= X"7488";
			when "110110" =>
				volume_next <= X"74f6";
			when "110111" =>
				volume_next <= X"7568";
			when "111000" =>
				volume_next <= X"75df";
			when "111001" =>
				volume_next <= X"765c";
			when "111010" =>
				volume_next <= X"76df";
			when "111011" =>
				volume_next <= X"776b";
			when "111100" =>
				volume_next <= X"7800";				
			when others =>
				volume_next <= X"79FF"; -- in case GTIA playing at full vol!
		end case;
		
	end process;
			
	-- output
	volume_out <= volume_reg;
		
END vhdl;