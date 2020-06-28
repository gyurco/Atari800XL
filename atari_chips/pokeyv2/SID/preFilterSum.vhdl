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

ENTITY SID_preFilterSum IS
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;
	ENABLE : IN STD_LOGIC;
	
	CHANNEL_A : IN SIGNED(15 downto 0);
	CHANNEL_B : IN SIGNED(15 downto 0);
	CHANNEL_C : IN SIGNED(15 downto 0);
	CHANNEL_C_CUTDIRECT : IN STD_LOGIC;
	FILTER_EN : IN STD_LOGIC_VECTOR(2 downto 0);

	PREFILTER_OUT : OUT SIGNED(15 downto 0); 
	DIRECT_OUT : OUT SIGNED(15 downto 0)     -- Only chdis/4 amplitude
);
END SID_preFilterSum;

ARCHITECTURE vhdl OF SID_preFilterSum IS
	signal prefilter_reg: signed(15 downto 0);
	signal prefilter_next: signed(15 downto 0);
	signal direct_reg: signed(15 downto 0);
	signal direct_next: signed(15 downto 0);
	signal acc_reg: signed(17 downto 0);
	signal acc_next: signed(17 downto 0);	
	signal phase_reg : unsigned(2 downto 0);
	signal phase_next : unsigned(2 downto 0);
	
	signal channel_mux : signed(15 downto 0);
	signal channel_sel : std_logic_vector(1 downto 0);
BEGIN
	-- register
	process(clk, reset_n)
	begin
		if (reset_n = '0') then
			prefilter_reg <= (others=>'0');
			direct_reg <= (others=>'0');
			acc_reg <= (others=>'0');
			phase_reg <= (others=>'0');
		elsif (clk'event and clk='1') then
			prefilter_reg <= prefilter_next;
			direct_reg <= direct_next;
			acc_reg <= acc_next;
			phase_reg <= phase_next;
		end if;
	end process;
	
	-- next state
	process(phase_reg,acc_reg,prefilter_reg,direct_reg,enable,channel_c_cutdirect,filter_en,channel_mux)
		variable filter_en0_ext : std_logic_vector(1 downto 0);
		variable filter_en1_ext : std_logic_vector(1 downto 0);
		variable filter_en2_ext : std_logic_vector(1 downto 0);
		variable filter_en2cd_ext : std_logic_vector(1 downto 0);
		
		variable adder_result : signed(17 downto 0);
	begin
		prefilter_next <= prefilter_reg;
		direct_next <= direct_reg;
		acc_next <= acc_reg;
		phase_next <= phase_reg;
				
		filter_en0_ext := (others=>filter_en(0));
		filter_en1_ext := (others=>filter_en(1));
		filter_en2_ext := (others=>filter_en(2));
		filter_en2cd_ext := (others=>filter_en(2) or channel_c_cutdirect);		
		
		channel_sel <= (others=>'0');
		
		phase_next <= phase_reg+1;
		
		adder_result := acc_reg + channel_mux;	
	   acc_next <= adder_result;	
		
		case phase_reg is
		when "000" =>
			channel_sel <= "01" and filter_en0_ext;
		when "001" =>
			channel_sel <= "10" and filter_en1_ext;
		when "010" =>
			channel_sel <= "11" and filter_en2_ext;		
			prefilter_next	<= adder_result(17 downto 2);
			acc_next <= (others=>'0');
		when "011" =>
			channel_sel <= "01" and not(filter_en0_ext);
		when "100" =>
			channel_sel <= "10" and not(filter_en1_ext);
		when "101" =>
			channel_sel <= "11" and not(filter_en2cd_ext);
			phase_next <= (others=>'0');
			direct_next <= adder_result(17 downto 2);
			acc_next <= (others=>'0');
		when others =>
		end case;		
		
	end process;	
	
	process(channel_sel,channel_a,channel_b,channel_c)
	begin
		channel_mux <= (others=>'0');
		case channel_sel is
		when "01" =>
			channel_mux <= channel_a;
		when "10" =>
			channel_mux <= channel_b;
		when "11" =>
			channel_mux <= channel_c;
		when others =>
		end case;
	end process;
		
	-- output
	prefilter_out <= prefilter_reg;
	direct_out <= direct_reg;
		
END vhdl;
