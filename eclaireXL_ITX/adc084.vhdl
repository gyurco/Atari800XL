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
use IEEE.STD_LOGIC_MISC.all;

-- 3.2MHz to 8 MHz, rather thsn 400KHz...
-- Different data in and data in - is it still i2c?
-- Write data in 16 cycles -> clocked in on rising edge
-- Result in out -> clocked on failling edge
--
-- 16 cycle process
-- data_in is ctrl7,ctrl6,ctrl5,ctrl4,ctrl3,ctrl2,ctrl1,ctrl0,na*8
-- data_out is l,l,l,l,d7,d6,d5,d4,d3,d2,d1,d0,l,l,l,l,l
-- cs-> low, 4 clock cycles then data

ENTITY adc084 IS
PORT 
( 
	CLK : IN STD_LOGIC; -- about 58MHz...
	RESET_N : IN STD_LOGIC;

	-- ADC side
	CS : OUT STD_LOGIC;
	SCLK : OUT STD_LOGIC;
	DOUT : IN STD_LOGIC;
	DIN : OUT STD_LOGIC;

	-- SAMPLED side
	CH1OUT : OUT STD_LOGIC_VECTOR(7 downto 0);
	CH2OUT : OUT STD_LOGIC_VECTOR(7 downto 0);
	CH3OUT : OUT STD_LOGIC_VECTOR(7 downto 0);
	CH4OUT : OUT STD_LOGIC_VECTOR(7 downto 0)
);
END adc084;

ARCHITECTURE vhdl OF adc084 IS
	signal cycle_next : std_logic_vector(21 downto 0);
	signal cycle_reg : STD_LOGIC_VECTOR(21 DOWNTO 0);

	signal channel_next : std_logic_vector(1 downto 0);
	signal channel_reg : std_logic_vector(1 downto 0);

	signal sclk_next : std_logic;
	signal sclk_reg : std_logic;

	signal alt_next : std_logic;
	signal alt_reg : std_logic;

	signal din_next : std_logic;
	signal din_reg : std_logic;

	signal cs_reg : std_logic;
	signal cs_next : std_logic;

	signal enable : std_logic;

	signal cap_next : std_logic_vector(7 downto 0);
	signal cap_reg : std_logic_vector(7 downto 0);

	signal ch1_next : std_logic_vector(7 downto 0);
	signal ch2_next : std_logic_vector(7 downto 0);
	signal ch3_next : std_logic_vector(7 downto 0);
	signal ch4_next : std_logic_vector(7 downto 0);

	signal ch1_reg : std_logic_vector(7 downto 0);
	signal ch2_reg : std_logic_vector(7 downto 0);
	signal ch3_reg : std_logic_vector(7 downto 0);
	signal ch4_reg : std_logic_vector(7 downto 0);

	signal store : std_logic;
BEGIN
	-- regs
	process(clk, reset_n)
	begin
		if (reset_n='0') then
			cycle_reg <= "0000000000000000000001";
			channel_reg <= "01";
			ch1_reg <= (others=>'0');
			ch2_reg <= (others=>'0');
			ch3_reg <= (others=>'0');
			ch4_reg <= (others=>'0');
			cap_reg <= (others=>'0');
			sclk_reg <= '1';
			din_reg <= '0';
			cs_reg <= '1';
			alt_reg <= '1';
		elsif (clk'event and clk='1') then
			cycle_reg <= cycle_next;
			channel_reg <= channel_next;
			ch1_reg <= ch1_next;
			ch2_reg <= ch2_next;
			ch3_reg <= ch3_next;
			ch4_reg <= ch4_next;
			cap_reg <= cap_next;
			sclk_reg <= sclk_next;
			din_reg <= din_next;
			cs_reg <= cs_next;
			alt_reg <= alt_next;
		end if;
	end process;

enable_div_clk : entity work.enable_divider
	generic map (COUNT=>8) -- cycle_length
	port map(clk=>clk,reset_n=>reset_n,enable_in=>'1',enable_out=>enable);

	-- main coms engine
	process(enable,cycle_reg,cap_reg,din_reg,alt_reg,sclk_reg,cs_reg,channel_reg,dout)
	begin
		cycle_next <= cycle_reg;
		cap_next <= cap_reg;
		sclk_next <= sclk_reg;
		alt_next <= alt_reg;
		cs_next <= cs_reg;

		din_next <= din_reg;
		store <= '0';

		if (enable='1') then
			sclk_next <= or_reduce(not(sclk_reg)&cycle_reg(21 downto 16));
			cs_next <= or_reduce(cycle_reg(20 downto 17));
			alt_next <= not(alt_reg);
			if (alt_reg = '1') then -- was 1, next is 0 -> falling edge
				din_next <= (channel_reg(1) and cycle_reg(3)) or (channel_reg(0) and cycle_reg(4));
			end if;

			if (alt_reg = '0') then -- was 0, next is 1 -> rising edge
				cycle_next <= cycle_reg(20 downto 0)&cycle_reg(21);
				cap_next(0) <= dout;

				cap_next(7 downto 1) <= cap_reg(6 downto 0);
--	signal cap_next : std_logic_vector(7 downto 0);
--	signal cap_reg : std_logic_vector(7 downto 0);

				store <= cycle_reg(12);
			end if;
		end if;
	end process;

	-- store channel
	process(store,channel_reg,cap_reg,ch1_reg,ch2_reg,ch3_reg,ch4_reg)
	begin
		channel_next <= channel_reg;
		ch1_next <= ch1_reg;
		ch2_next <= ch2_reg;
		ch3_next <= ch3_reg;
		ch4_next <= ch4_reg;

		if (store = '1') then
			channel_next <= std_logic_vector(unsigned(channel_reg) + 1);
			--channel_next <= "01";
			--ch2_next <= cap_reg;

			case channel_reg is
			when "00" =>
				ch4_next <= cap_reg;
			when "01" =>
				ch1_next <= cap_reg;
			when "10" =>
				ch2_next <= cap_reg;
			when "11" =>
				ch3_next <= cap_reg;
			when others =>
			end case; 
		end if;
	end process;

	sclk <= sclk_reg;
	din <= din_reg;
	cs <= cs_reg;
	ch1out <= ch1_reg;
	ch2out <= ch2_reg;
	ch3out <= ch3_reg;
	ch4out <= ch4_reg;

END vhdl;
