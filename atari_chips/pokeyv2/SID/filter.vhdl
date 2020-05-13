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

-- Fixed point implementation of a variable state filter
-- A handy filter 3 op amps that can do low pass, band pass and high pass at once
-- SID used this, but had ... some shortcuts that made it rather imperfect
-- This implementation is correct (I hope!), but will need some tweaks to replicate the broken
-- sound of the 6581

ENTITY SID_filter IS
GENERIC
(
	CLKSPEED : IN integer; --In Hz
	FMIN : IN integer;   --In Hz
	FMAX : IN integer;   --In Hz
	QMULT : IN integer;  --Scale Q
	QOFF : IN integer    --Offset for Q
)
PORT 
( 
	CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;

	INPUT : IN STD_LOGIC_VECTOR(15 downto 0);

	LOWPASS : OUT STD_LOGIC_VECTOR(15 downto 0);
	BANDPASS : OUT STD_LOGIC_VECTOR(15 downto 0);
	HIGHPASS : OUT STD_LOGIC_VECTOR(15 downto 0);

	CUTOFF_FREQUENCY : IN STD_LOGIC_VECTOR(10 downto 0);
	Q : IN STD_LOGIC_VECTOR(3 downto 0)
)
END SID_filter;

-- matlab pseudocode...
--  f = 2*sin(pi*fCutoff/clkrate);
--
--  Q = 0.707;    % 0.5 to infinity
--    q = 1.0 / Q;
--    sum3 = 0;
--    sum2 = 0;
--    for i=1:numel(indata)
--      input = indata(i);
--
--      multq = sum2 * q;
--
--      sum1 = input + (-multq) + (-sum3);
--
--      mult1 = f * sum1;
--      sum2 = mult1 + sum2;
--
--      mult2 = f * sum2;
--      sum3 = mult2 + sum3;
--
--      res(ceil(i*outrate/inrate)) = sum3;
--    end

-- as fixed point
--    sum1 = int64(0);
--    sum2 = int64(0);
--    sum3 = int64(0);
--    q = 1.0 / Q;
--    q = int64(round(q*65536));%2.16u
--    indata = indata/2; %rescale to -0.5 to 0.5
--    indata2 = int64(round(indata*2^24));
--    f = int64(round(f*2^21)); %0.21u
--    for i=1:numel(indata2)
--      input = indata2(i);%18.24
--
--      multq = (sum2/2^6) * q; %18.24s * 2.16u
--      %multq: 20.34s
--      %multq->18.24s
--      multq = multq/(2^10);
--      sum1 = input + (-multq) + (-sum3); %all 18.24s
--      mult1 = f * sum1/(2^6); %0.21u * 18.18s
--      %mult1: 15.39s
--      %mult1->18.24s
--      mult1 = mult1/(2^15);
--      sum2 = mult1 + sum2; %all 18.24s
--      mult2 = f * (sum2/2^6); %0.21u * 18.18s
--      %mult2: 15.39s
--      %mult2->18.24s
--      mult2 = mult2/(2^15);
--      sum3 = mult2 + sum3; %all 18.24s
--
--      res(ceil(i*outrate/inrate)) = sum3/(2^6);
--    end
--    res = res/2^18;
--    res = res*2;

ARCHITECTURE vhdl OF SID_filter IS
	multq_reg : signed(53 downto 0);
	multq_next : signed(53 downto 0);

	mult1_reg : signed(53 downto 0);
	mult1_next : signed(53 downto 0);

	mult2_reg : signed(53 downto 0);
	mult2_next : signed(53 downto 0);

	f_reg : unsigned(17 downto 0);
	f_next :  unsigned(17 downto 0);

	q_reg : unsigned(17 downto 0);
	q_next :  unsigned(17 downto 0);

	lp_reg : signed(15 downto 0);
	lp_next : signed(15 downto 0);

	bp_reg : signed(15 downto 0);
	bp_next : signed(15 downto 0);

	hp_reg : signed(15 downto 0);
	hp_next : signed(15 downto 0);

	--    q = 1.0 / Q;
	--    q = int64(round(q*65536));%2.16u
	function compute_q(Qval : integer) return unsigned is
   		 variable ret : unsigned(17 downto 0);
	begin
		ret := to_unsigned(integer(65536.0/(real(Qval)*QMULT + QOFF))),18);
		return ret;
	end function compute_q;
BEGIN
	-- register
	process(clk, reset_n)
	begin
		if (reset_n = '0') then
			f_reg <= (others=>'0');
			q_reg <= (others=>'0');
			multq_reg <= (others=>'0');
			mult1_reg <= (others=>'0');
			mult2_reg <= (others=>'0');
			lp_reg <= (others=>'0');
			bp_reg <= (others=>'0');
			hp_reg <= (others=>'0');
		elsif (clk'event and clk='1') then
			f_reg <= f_next;
			q_reg <= q_next;
			multq_reg <= multq_next;
			mult1_reg <= mult1_next;
			mult2_reg <= mult2_next;
			lp_reg <= lp_next;
			bp_reg <= bp_next;
			hp_reg <= hp_next;
		end if;
	end process;

	-- next state
	process(Q)
	begin
		q_next <= (others=>'0');

		for I in 0 to 15 loop
			if (Q = I) then
				q_next <= compute_q(I);
			end if;
		end loop;
	end process;

	process(CUTOFF_FREQUENCY)
		variable f_min : real;
		variable f_max : real;

		variable f_offset : unsigned(17 downto 0); --0.21(000,18)
		variable f_scale : unsigned(17 downto 0); --0.21(000,18)
	begin
		--f = 2*sin(pi*10000/inrate);
		--CUTOFF_FREQUENCY : IN STD_LOGIC_VECTOR(10 downto 0);
		--CLKSPEED : IN integer; --In Hz
		--FMIN : IN integer;   --In Hz
		--FMAX : IN integer;   --In Hz

		f_min := 2*sin(pi*FMIN/CLKSPEED);
		f_max := 2*sin(pi*FMAX/CLKSPEED);
		f_offset := integer(f_min*2^21);
		f_scale  := integer(2^21*((f_max-f_min)/2^11));

		f_next <= f_scale * resize(unsigned(CUTOFF_FREQUENCY),18) + f_offset;
	end process;

	process(input,q_reg,f_reg,multq_reg,mult1_reg,mult2_reg)
		variable sum1 : signed(41 downto 0);
		variable sum2 : signed(41 downto 0);
		variable sum3 : signed(41 downto 0);

		variable multq : signed(41 downto 0);
		variable mult1 : signed(41 downto 0);
		variable mult2 : signed(41 downto 0);
		variable inputadj : signed(41 downto 0);
	begin
		multq_next <= sum2(41 downto 6) * q_reg; --18.18s * 2.16u
		--multq: 20.34s
		--multq->18.24s
		multq := multq_reg(51 downto 10);
		inputadj(23 downto 0) := 0;
		inputadj(41 downto 24) := resize(input,18) - 32768; -- to signed
		sum1 := inputadj + (-multq) + (-sum3); --all 18.24s

		mult1_next <= f_reg * sum1(41 downto 6); --0.21u * 18.18s
		--mult1: 15.39s
		--mult1->18.24s
		mult1 := resize(mult1_reg(51 downto 15),42);
		sum2 := mult1 + sum2; --all 18.24s

		mult2_next = f_reg * sum2(41 downto 6); -- 0.21u * 18.18s
		--mult2: 15.39s
		--mult2->18.24s
		mult2 := resize(mult2_reg(51 downto 15),42);
		sum3 := mult2 + sum3; --all 18.24s
		
		lp_next <= sum3(41 downto 24) + 32768;
		bp_next <= sum2(41 downto 24) + 32768;
		hp_next <= sum1(41 downto 24) + 32768;
	end process;	

	--output
	lowpass <= lp_reg;
	bandpass <= bp_reg;
	highpass <= hp_reg;
		
END vhdl;
