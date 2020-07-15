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
	UPDATE : IN STD_LOGIC_VECTOR(3 downto 0);
	data_needed : IN STD_LOGIC_VECTOR(3 downto 0);
	
	data_nibble : IN STD_LOGIC;
	data_in : IN std_logic_vector(7 downto 0);
	data_out : OUT std_logic_vector(7 downto 0)
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
	
        function stepsize_fn(x: unsigned(5 downto 0)) return unsigned is
        begin
                case x is
        when "000000" => return to_unsigned(16/8,8);
        when "000001" => return to_unsigned(17/8,8);
        when "000010" => return to_unsigned(19/8,8);
        when "000011" => return to_unsigned(21/8,8);
        when "000100" => return to_unsigned(23/8,8);
        when "000101" => return to_unsigned(25/8,8);
        when "000110" => return to_unsigned(28/8,8);
        when "000111" => return to_unsigned(31/8,8);
        when "001000" => return to_unsigned(34/8,8);
        when "001001" => return to_unsigned(37/8,8);

        when "001010" => return to_unsigned(41/8,8);
        when "001011" => return to_unsigned(45/8,8);
        when "001100" => return to_unsigned(50/8,8);
        when "001101" => return to_unsigned(55/8,8);
        when "001110" => return to_unsigned(60/8,8);
        when "001111" => return to_unsigned(66/8,8);
        when "010000" => return to_unsigned(73/8,8);
        when "010001" => return to_unsigned(80/8,8);
        when "010010" => return to_unsigned(88/8,8);
        when "010011" => return to_unsigned(97/8,8);

        when "010100" => return to_unsigned(107/8,8);
        when "010101" => return to_unsigned(118/8,8);
        when "010110" => return to_unsigned(130/8,8);
        when "010111" => return to_unsigned(143/8,8);
        when "011000" => return to_unsigned(157/8,8);
        when "011001" => return to_unsigned(173/8,8);
        when "011010" => return to_unsigned(190/8,8);
        when "011011" => return to_unsigned(209/8,8);
        when "011100" => return to_unsigned(230/8,8);
        when "011101" => return to_unsigned(253/8,8);
		  
        when "011110" => return to_unsigned(279/8,8);		  
        when "011111" => return to_unsigned(307/8,8);	  
        when "100000" => return to_unsigned(337/8,8);
        when "100001" => return to_unsigned(371/8,8);
        when "100010" => return to_unsigned(408/8,8);
        when "100011" => return to_unsigned(449/8,8);
        when "100100" => return to_unsigned(494/8,8);
        when "100101" => return to_unsigned(544/8,8);
        when "100110" => return to_unsigned(598/8,8);		  		  
        when "100111" => return to_unsigned(658/8,8);
		  
        when "101000" => return to_unsigned(724/8,8);
        when "101001" => return to_unsigned(796/8,8);
        when "101010" => return to_unsigned(876/8,8);
        when "101011" => return to_unsigned(963/8,8);
        when "101100" => return to_unsigned(1060/8,8);
        when "101101" => return to_unsigned(1166/8,8);
        when "101110" => return to_unsigned(1282/8,8);
        when "101111" => return to_unsigned(1411/8,8);		  
        when "110000" => return to_unsigned(1552/8,8);	  
		  when others =>
			return to_unsigned(0/8,8);
                end case;
        end stepsize_fn;	

        function stepadj_fn(x: std_logic_vector(2 downto 0)) return signed is
        begin
                case x is
						when "000" => return to_signed(-1,7);
						when "001" => return to_signed(-1,7);
						when "010" => return to_signed(-1,7);
						when "011" => return to_signed(-1,7);
						when "100" => return to_signed(2,7);
						when "101" => return to_signed(5,7);
						when "110" => return to_signed(7,7);
						when "111" => return to_signed(9,7);
                end case;
        end stepadj_fn;			  
		  
	signal acc0_reg : signed(11 downto 0);
	signal acc0_next : signed(11 downto 0);

	signal acc1_reg : signed(11 downto 0);
	signal acc1_next : signed(11 downto 0);

	signal acc2_reg : signed(11 downto 0);
	signal acc2_next : signed(11 downto 0);

	signal acc3_reg : signed(11 downto 0);
	signal acc3_next : signed(11 downto 0);
	
	signal acc_next : signed(11 downto 0);
	signal acc_mux : signed(11 downto 0);

	signal decstep0_reg : unsigned(5 downto 0);
	signal decstep0_next : unsigned(5 downto 0);

	signal decstep1_reg : unsigned(5 downto 0);
	signal decstep1_next : unsigned(5 downto 0);

	signal decstep2_reg : unsigned(5 downto 0);
	signal decstep2_next : unsigned(5 downto 0);

	signal decstep3_reg : unsigned(5 downto 0);
	signal decstep3_next : unsigned(5 downto 0);
	
	signal decstep_next : unsigned(5 downto 0);
	signal decstep_mux : unsigned(5 downto 0);
	
	signal dataneeded0_reg : std_logic;
	signal dataneeded0_next : std_logic;
	
	signal dataneeded1_reg : std_logic;
	signal dataneeded1_next : std_logic;

	signal dataneeded2_reg : std_logic;
	signal dataneeded2_next : std_logic;
	
	signal dataneeded3_reg : std_logic;
	signal dataneeded3_next : std_logic;	
	
	signal dataneeded_next : std_logic;
	signal dataneeded_mux : std_logic;
	
	signal update_mux : std_logic;
	signal reset_mux : std_logic;
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
			dataneeded0_reg <= '0';
			dataneeded1_reg <= '0';
			dataneeded2_reg <= '0';
			dataneeded3_reg <= '0';
		elsif (clk'event and clk='1') then
			acc0_reg <= acc0_next;
			acc1_reg <= acc1_next;
			acc2_reg <= acc2_next;
			acc3_reg <= acc3_next;
			decstep0_reg <= decstep0_next;
			decstep1_reg <= decstep1_next;
			decstep2_reg <= decstep2_next;
			decstep3_reg <= decstep3_next;
			dataneeded0_reg <= dataneeded0_next;
			dataneeded1_reg <= dataneeded1_next;
			dataneeded2_reg <= dataneeded2_next;
			dataneeded3_reg <= dataneeded3_next;
		end if;
	end process;

	process(acc0_reg, acc1_reg, acc2_reg, acc3_reg,
		decstep0_reg, decstep1_reg, decstep2_reg, decstep3_reg,
		dataneeded0_reg, dataneeded1_reg, dataneeded2_reg, dataneeded3_reg,
	       	update, acc_next, decstep_next, dataneeded_next, data_needed)
	begin
		acc0_next <= acc0_reg;
		acc1_next <= acc1_reg;
		acc2_next <= acc2_reg;
		acc3_next <= acc3_reg;
		decstep0_next <= decstep0_reg;
		decstep1_next <= decstep1_reg;
		decstep2_next <= decstep2_reg;
		decstep3_next <= decstep3_reg;
		dataneeded0_next <= dataneeded0_reg or data_needed(0);
		dataneeded1_next <= dataneeded1_reg or data_needed(1);
		dataneeded2_next <= dataneeded2_reg or data_needed(2);
		dataneeded3_next <= dataneeded3_reg or data_needed(3);		

		case update is
		when "0001" =>
			acc0_next <= acc_next;
			decstep0_next <= decstep_next;
			dataneeded0_next <= dataneeded_next;
		when "0010" =>
			acc1_next <= acc_next;
			decstep1_next <= decstep_next;
			dataneeded1_next <= dataneeded_next;
		when "0100" =>
			acc2_next <= acc_next;
			decstep2_next <= decstep_next;
			dataneeded2_next <= dataneeded_next;
		when "1000" =>
			acc3_next <= acc_next;
			decstep3_next <= decstep_next;
			dataneeded3_next <= dataneeded_next;
		when others =>
		end case;
	end process;

	process(update,syncreset,
		acc0_reg, acc1_reg, acc2_reg, acc3_reg, 
		decstep0_reg, decstep1_reg, decstep2_reg, decstep3_reg,
		dataneeded0_reg, dataneeded1_reg, dataneeded2_reg, dataneeded3_reg
	)
	begin
		acc_mux <= (others=>'0');
		decstep_mux <= (others=>'0');
		update_mux <= '0';
		reset_mux <= '0';
		dataneeded_mux <= '0';
		case update is
		when "0001" =>
			acc_mux <= acc0_reg;
			decstep_mux <= decstep0_reg;
			dataneeded_mux <= dataneeded0_reg;
			update_mux <= '1';		
		when "0010" =>
			acc_mux <= acc1_reg;
			decstep_mux <= decstep1_reg;
			dataneeded_mux <= dataneeded1_reg;
			update_mux <= '1';
		when "0100" =>
			acc_mux <= acc2_reg;
			decstep_mux <= decstep2_reg;
			dataneeded_mux <= dataneeded2_reg;
			update_mux <= '1';
		when "1000" =>
			acc_mux <= acc3_reg;
			decstep_mux <= decstep3_reg;
			dataneeded_mux <= dataneeded3_reg;
			update_mux <= '1';
		when others =>
		end case;

		case syncreset is
		when "0001" =>
			reset_mux <= syncreset(0);
		when "0010" =>
			reset_mux <= syncreset(1);
		when "0100" =>
			reset_mux <= syncreset(2);
		when "1000" =>
			reset_mux <= syncreset(3);
		when others =>
		end case;
	end process;

	process(acc_mux,decstep_mux,update_mux,reset_mux,dataneeded_mux,
		data_in,data_nibble)

		variable code : std_logic_vector(3 downto 0);
		variable codeadj : signed(8 downto 0);
		variable stepsize : signed(8 downto 0);
		variable vlue : signed(17 downto 0);
		variable decstepnext : signed(6 downto 0);
	begin
		acc_next <= (others=>'0');
		decstep_next <= (others=>'0');
		dataneeded_next <= '0';

		if (reset_mux='0') then
			acc_next <= acc_mux;
			decstep_next <= decstep_mux;
			dataneeded_next <= dataneeded_mux;

			if (update_mux='1' and dataneeded_mux='1') then
				codeadj:= (others=>'0');
				if (data_nibble='1') then
					code:= data_in(7 downto 4);
				else
					code:= data_in(3 downto 0);
				end if;
				codeadj(4 downto 1) := signed('0'&code(2 downto 0));
				codeadj(0):= '1';
				
				if (code(3)='1') then
					codeadj:=-codeadj;
				end if;
				
				stepsize := signed('0'&stepsize_fn(decstep_mux)); -- already /8

				vlue :=codeadj*stepsize;
					
				acc_next <= acc_mux + vlue(11 downto 0);

				decstepnext := stepadj_fn(code(2 downto 0)) + signed(resize(decstep_mux,7));
				if (decstepnext>48) then
					decstepnext := to_signed(48,7);
				elsif (decstepnext<0) then
					decstepnext := to_signed(0,7);
				end if;
				decstep_next <= unsigned(decstepnext(5 downto 0));
				
			end if;
		end if;
	end process;

	data_out(7) <= not(acc_next(11));
	data_out(6 downto 0) <= std_logic_vector(acc_next(10 downto 4));
	
end vhdl;

