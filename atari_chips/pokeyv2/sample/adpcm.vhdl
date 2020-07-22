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

ENTITY sample_adpcm IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;

	SYNCRESET : IN STD_LOGIC_VECTOR(3 downto 0);

	FETCH : IN STD_LOGIC_VECTOR(3 downto 0);
	update : IN STD_LOGIC_VECTOR(3 downto 0);
	data_nibble : IN STD_LOGIC_VECTOR(3 downto 0);	
	
	data_in : IN std_logic_vector(7 downto 0);
	data_out : OUT std_logic_vector(15 downto 0)
);
END sample_adpcm;

--static short step_size[] = { 
--			   16, 17, 19, 21, 23, 25, 28, 31, 34, 37,
--			   41, 45, 50, 55, 60, 66, 73, 80, 88, 97,
--			   107, 118, 130, 143, 157, 173, 190, 209, 230, 253,
--			   279, 307, 337, 371, 408, 449, 494, 544, 598, 658,
--			   724, 796, 876, 963, 1060, 1166, 1282, 1411, 1552
--			   }; //49 items
--static int step_adj[] = { -1, -1, -1, -1, 2, 5, 7, 9, -1, -1, -1, -1, 2, 5, 7, 9 };

-- ADPCM codec
--       int vlue = (2 * (code & 0x07) + 1) * step_size[decstep] / 8;
--        acc += (((code & 0x08) != 0) ? -vlue : vlue);
--
--        acc &= 0xfff; // accumulator wraps
--        if (acc & 0x800) acc |= ~0xfff; // sign extend if negative
--
--        decstep += step_adj[code & 7];
--        if (decstep < 0) decstep = 0;
--        //if (decstep > 48 * 16) decstep = 48 * 16;
--        if (decstep > 48) decstep = 48;

ARCHITECTURE vhdl OF sample_adpcm IS
	
        function stepsize_fn(x: unsigned(6 downto 0)) return unsigned is
        begin
                case x is
when "0000000" => return to_unsigned(7,15);
when "0000001" => return to_unsigned(8,15);
when "0000010" => return to_unsigned(9,15);
when "0000011" => return to_unsigned(10,15);
when "0000100" => return to_unsigned(11,15);
when "0000101" => return to_unsigned(12,15);
when "0000110" => return to_unsigned(13,15);
when "0000111" => return to_unsigned(14,15);
when "0001000" => return to_unsigned(16,15);
when "0001001" => return to_unsigned(17,15);
when "0001010" => return to_unsigned(19,15);
when "0001011" => return to_unsigned(21,15);
when "0001100" => return to_unsigned(23,15);
when "0001101" => return to_unsigned(25,15);
when "0001110" => return to_unsigned(28,15);
when "0001111" => return to_unsigned(31,15);
when "0010000" => return to_unsigned(34,15);
when "0010001" => return to_unsigned(37,15);
when "0010010" => return to_unsigned(41,15);
when "0010011" => return to_unsigned(45,15);
when "0010100" => return to_unsigned(50,15);
when "0010101" => return to_unsigned(55,15);
when "0010110" => return to_unsigned(60,15);
when "0010111" => return to_unsigned(66,15);
when "0011000" => return to_unsigned(73,15);
when "0011001" => return to_unsigned(80,15);
when "0011010" => return to_unsigned(88,15);
when "0011011" => return to_unsigned(97,15);
when "0011100" => return to_unsigned(107,15);
when "0011101" => return to_unsigned(118,15);
when "0011110" => return to_unsigned(130,15);
when "0011111" => return to_unsigned(143,15);
when "0100000" => return to_unsigned(157,15);
when "0100001" => return to_unsigned(173,15);
when "0100010" => return to_unsigned(190,15);
when "0100011" => return to_unsigned(209,15);
when "0100100" => return to_unsigned(230,15);
when "0100101" => return to_unsigned(253,15);
when "0100110" => return to_unsigned(279,15);
when "0100111" => return to_unsigned(307,15);
when "0101000" => return to_unsigned(337,15);
when "0101001" => return to_unsigned(371,15);
when "0101010" => return to_unsigned(408,15);
when "0101011" => return to_unsigned(449,15);
when "0101100" => return to_unsigned(494,15);
when "0101101" => return to_unsigned(544,15);
when "0101110" => return to_unsigned(598,15);
when "0101111" => return to_unsigned(658,15);
when "0110000" => return to_unsigned(724,15);
when "0110001" => return to_unsigned(796,15);
when "0110010" => return to_unsigned(876,15);
when "0110011" => return to_unsigned(963,15);
when "0110100" => return to_unsigned(1060,15);
when "0110101" => return to_unsigned(1166,15);
when "0110110" => return to_unsigned(1282,15);
when "0110111" => return to_unsigned(1411,15);
when "0111000" => return to_unsigned(1552,15);
when "0111001" => return to_unsigned(1707,15);
when "0111010" => return to_unsigned(1878,15);
when "0111011" => return to_unsigned(2066,15);
when "0111100" => return to_unsigned(2272,15);
when "0111101" => return to_unsigned(2499,15);
when "0111110" => return to_unsigned(2749,15);
when "0111111" => return to_unsigned(3024,15);
when "1000000" => return to_unsigned(3327,15);
when "1000001" => return to_unsigned(3660,15);
when "1000010" => return to_unsigned(4026,15);
when "1000011" => return to_unsigned(4428,15);
when "1000100" => return to_unsigned(4871,15);
when "1000101" => return to_unsigned(5358,15);
when "1000110" => return to_unsigned(5894,15);
when "1000111" => return to_unsigned(6484,15);
when "1001000" => return to_unsigned(7132,15);
when "1001001" => return to_unsigned(7845,15);
when "1001010" => return to_unsigned(8630,15);
when "1001011" => return to_unsigned(9493,15);
when "1001100" => return to_unsigned(10442,15);
when "1001101" => return to_unsigned(11487,15);
when "1001110" => return to_unsigned(12635,15);
when "1001111" => return to_unsigned(13899,15);
when "1010000" => return to_unsigned(15289,15);
when "1010001" => return to_unsigned(16818,15);
when "1010010" => return to_unsigned(18500,15);
when "1010011" => return to_unsigned(20350,15);
when "1010100" => return to_unsigned(22385,15);
when "1010101" => return to_unsigned(24623,15);
when "1010110" => return to_unsigned(27086,15);
when "1010111" => return to_unsigned(29794,15);
when "1011000" => return to_unsigned(32767,15)	;		
		  when others =>
			return to_unsigned(0,15);
                end case;
        end stepsize_fn;	

        function stepadj_fn(x: std_logic_vector(2 downto 0)) return signed is
        begin
                case x is
when "000" => return to_signed(-1,5);
when "001" => return to_signed(-1,5);
when "010" => return to_signed(-1,5);
when "011" => return to_signed(-1,5);
when "100" => return to_signed(2,5);
when "101" => return to_signed(4,5);
when "110" => return to_signed(6,5);
when "111" => return to_signed(8,5);
                end case;
        end stepadj_fn;			  
		  
	signal acc0_reg : signed(15 downto 0);
	signal acc0_next : signed(15 downto 0);

	signal acc1_reg : signed(15 downto 0);
	signal acc1_next : signed(15 downto 0);

	signal acc2_reg : signed(15 downto 0);
	signal acc2_next : signed(15 downto 0);

	signal acc3_reg : signed(15 downto 0);
	signal acc3_next : signed(15 downto 0);
	
	signal acc_next : signed(15 downto 0);
	signal acc_mux : signed(15 downto 0);

	signal decstep0_reg : unsigned(6 downto 0);
	signal decstep0_next : unsigned(6 downto 0);

	signal decstep1_reg : unsigned(6 downto 0);
	signal decstep1_next : unsigned(6 downto 0);

	signal decstep2_reg : unsigned(6 downto 0);
	signal decstep2_next : unsigned(6 downto 0);

	signal decstep3_reg : unsigned(6 downto 0);
	signal decstep3_next : unsigned(6 downto 0);
	
	signal decstep_next : unsigned(6 downto 0);
	signal decstep_mux : unsigned(6 downto 0);
	
	signal write_ch0 : std_logic;
	signal write_ch1 : std_logic;
	signal write_ch2 : std_logic;
	signal write_ch3 : std_logic;
	
	signal sel : std_logic_vector(3 downto 0);

	signal syncreset_next : std_logic_vector(3 downto 0);
	signal syncreset_reg : std_logic_vector(3 downto 0);
	
	signal data_nibble_mux: std_logic;
BEGIN
	-- register
	process(clk,reset_n)
	begin
		if (reset_n='0') then
			acc0_reg <= (others=>'0');
			acc1_reg <= (others=>'0');
			acc2_reg <= (others=>'0');
			acc3_reg <= (others=>'0');
			decstep0_reg <= (others=>'0');
			decstep1_reg <= (others=>'0');
			decstep2_reg <= (others=>'0');
			decstep3_reg <= (others=>'0');
			syncreset_reg <= (others=>'0');
		elsif (clk'event and clk='1') then
			acc0_reg <= acc0_next;
			acc1_reg <= acc1_next;
			acc2_reg <= acc2_next;
			acc3_reg <= acc3_next;
			decstep0_reg <= decstep0_next;
			decstep1_reg <= decstep1_next;
			decstep2_reg <= decstep2_next;
			decstep3_reg <= decstep3_next;
			syncreset_reg <= syncreset_next;
		end if;
	end process;

	write_ch0 <= update(0);
	write_ch1 <= update(1);
	write_ch2 <= update(2);
	write_ch3 <= update(3);
	
	process(acc0_reg, acc1_reg, acc2_reg, acc3_reg,
		decstep0_reg, decstep1_reg, decstep2_reg, decstep3_reg,
	       	acc_next, decstep_next,
				write_ch0,write_ch1,write_ch2,write_ch3)
	begin
		acc0_next <= acc0_reg;
		acc1_next <= acc1_reg;
		acc2_next <= acc2_reg;
		acc3_next <= acc3_reg;
		decstep0_next <= decstep0_reg;
		decstep1_next <= decstep1_reg;
		decstep2_next <= decstep2_reg;
		decstep3_next <= decstep3_reg;
	
	   if (write_ch0='1') then
			acc0_next <= acc_next;			
			decstep0_next <= decstep_next;			
		end if;
		
	   if (write_ch1='1') then
			acc1_next <= acc_next;			
			decstep1_next <= decstep_next;			
		end if;

	  if (write_ch2='1') then
			acc2_next <= acc_next;			
			decstep2_next <= decstep_next;			
		end if;

	   if (write_ch3='1') then
			acc3_next <= acc_next;			
			decstep3_next <= decstep_next;			
		end if;		
	end process;

	sel <= fetch or update;

	process(sel,syncreset_reg, syncreset, update,
		acc0_reg, acc1_reg, acc2_reg, acc3_reg, 
		decstep0_reg, decstep1_reg, decstep2_reg, decstep3_reg,
		data_nibble
	)
	begin
		acc_mux <= (others=>'0');
		decstep_mux <= (others=>'0');
		data_nibble_mux <= '0';

		syncreset_next <= (syncreset or syncreset_reg) and not(update);

		case sel is
		when "0001" =>
			acc_mux <= acc0_reg;
			decstep_mux <= decstep0_reg;
			data_nibble_mux <= data_nibble(0);
		when "0010" =>
			acc_mux <= acc1_reg;
			decstep_mux <= decstep1_reg;
			data_nibble_mux <= data_nibble(1);
		when "0100" =>
			acc_mux <= acc2_reg;
			decstep_mux <= decstep2_reg;			
			data_nibble_mux <= data_nibble(2);
		when "1000" =>
			acc_mux <= acc3_reg;
			decstep_mux <= decstep3_reg;
			data_nibble_mux <= data_nibble(3);
		when others =>
		end case;
		
		if (or_reduce(syncreset_reg or syncreset)='1') then
			acc_mux <= (others=>'0');
			decstep_mux <= (others=>'0');
		end if;
	end process;

	process(acc_mux,decstep_mux,
		data_in,data_nibble_mux)

		variable code : std_logic_vector(3 downto 0);
		variable codeadj : signed(8 downto 0);
		variable stepsize : signed(17 downto 0);
		variable vlue : signed(26 downto 0);
		variable vlue8 : signed(16 downto 0);
		variable decstepnext : signed(7 downto 0);
		variable acc_sum : signed(16 downto 0);
		variable oflow : boolean;
	begin
		acc_next <= acc_mux;
		decstep_next <= decstep_mux;
		
		codeadj:= (others=>'0');
		if (data_nibble_mux='0') then
			code:= data_in(7 downto 4);
		else
			code:= data_in(3 downto 0);
		end if;

		codeadj := resize(signed('0'&code(2 downto 0)),8)&"1";
		
		stepsize := resize(signed('0'&stepsize_fn(decstep_mux)),18);

		vlue :=codeadj*stepsize;

		if (code(3)='0') then
			vlue8 := vlue(19 downto 3);
		else
			vlue8 := -vlue(19 downto 3);
		end if;

		acc_sum := resize(acc_mux,17) + vlue8;
		oflow := acc_sum(16)/=acc_sum(15);
		if (oflow) then
			acc_next <= resize(acc_sum(16 downto 16),16);
		else
			acc_next <= acc_sum(15 downto 0);
		end if;

		decstepnext := resize(stepadj_fn(code(2 downto 0)),8) + signed(resize(decstep_mux,8));
		if (decstepnext>88) then
			decstepnext := to_signed(88,8);
		elsif (decstepnext<0) then
			decstepnext := to_signed(0,8);
		end if;
		decstep_next <= unsigned(decstepnext(6 downto 0));			
	end process;

	data_out(15) <= not(acc_mux(15));
	data_out(14 downto 0) <= std_logic_vector(acc_mux(14 downto 0));
	
end vhdl;

