---------------------------------------------------------------------------
-- (c) 2024 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use IEEE.STD_LOGIC_MISC.all;

ENTITY fir_filter IS
GENERIC
(
	sample_bits : integer := 16;
	filter_bits : integer := 16;
	filter_len : integer := 2048
);
PORT 
( 
	FILTER_CLK : IN STD_LOGIC;
	RESET_N : IN STD_LOGIC;

	SAMPLE_ENABLE : IN STD_LOGIC;
	SAMPLE_DATA : IN SIGNED(sample_bits-1 downto 0);

	SAMPLE_OUT : OUT SIGNED(sample_bits-1 downto 0);

	FLASH_CLK : IN STD_LOGIC;
	FLASH_REQUEST : OUT STD_LOGIC;
	FLASH_ADDRESS : OUT STD_LOGIC_VECTOR(9 downto 0);
	FLASH_DATA : IN STD_LOGIC_VECTOR(31 downto 0);
	FLASH_READY : IN STD_LOGIC
);
END fir_filter;

ARCHITECTURE vhdl OF fir_filter IS
	function log2c(n : integer) return integer is
		variable m,p : integer;
	begin
		m := 0;
		p := 1;
		while p<n loop
			m:=m+1;
			p:=p*2;
		end loop;
		return m;
	end log2c;

	constant ADDR_WIDTH : natural := log2c(FILTER_LEN);
	signal sample_ram_write_enable : std_logic;
	signal sample_ram_address1 : std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal sample_ram_address2 : std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal sample_ram_data1_reg : std_logic_vector(SAMPLE_BITS-1 downto 0);
	signal sample_ram_data1_next : std_logic_vector(SAMPLE_BITS-1 downto 0);
	signal sample_ram_data2_reg : std_logic_vector(SAMPLE_BITS-1 downto 0);
	signal sample_ram_data2_next : std_logic_vector(SAMPLE_BITS-1 downto 0);

	signal sample_ram_write_address_reg : std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal sample_ram_write_address_next : std_logic_vector(ADDR_WIDTH-1 downto 0);

	signal sample_ram_read_address1_reg : std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal sample_ram_read_address1_next : std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal sample_ram_read_address2_reg : std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal sample_ram_read_address2_next : std_logic_vector(ADDR_WIDTH-1 downto 0);

	signal fir_rom_address_reg : std_logic_vector(ADDR_WIDTH-2 downto 0);
	signal fir_rom_address_next : std_logic_vector(ADDR_WIDTH-2 downto 0);
	signal fir_rom_data1_reg : std_logic_vector(FILTER_BITS-1 downto 0);
	signal fir_rom_data1_next : std_logic_vector(FILTER_BITS-1 downto 0);
	signal fir_rom_data2_reg : std_logic_vector(FILTER_BITS-1 downto 0);
	signal fir_rom_data2_next : std_logic_vector(FILTER_BITS-1 downto 0);

	signal mult1_reg : signed(SAMPLE_BITS+FILTER_BITS-1 downto 0);
	signal mult1_next : signed(SAMPLE_BITS+FILTER_BITS-1 downto 0); -- up to 18x18
	signal mult2_reg : signed(SAMPLE_BITS+FILTER_BITS-1 downto 0);
	signal mult2_next : signed(SAMPLE_BITS+FILTER_BITS-1 downto 0); -- up to 18x18

	signal accumulator_reg : signed(SAMPLE_BITS+FILTER_BITS-1 downto 0);
	signal accumulator_next : signed(SAMPLE_BITS+FILTER_BITS-1 downto 0); -- up to 18x18

	signal sample_out_reg : signed(SAMPLE_BITS-1 downto 0);
	signal sample_out_next : signed(SAMPLE_BITS-1 downto 0);

	signal state_reg : std_logic_vector(2 downto 0);
	signal state_next : std_logic_vector(2 downto 0);
	constant state_wait_sample : std_logic_vector(2 downto 0) := "001";
	constant state_fir_prepare : std_logic_vector(2 downto 0) := "010";
	constant state_fir_compute1 : std_logic_vector(2 downto 0) := "011";
	constant state_fir_compute2 : std_logic_vector(2 downto 0) := "100";
	constant state_fir_compute3 : std_logic_vector(2 downto 0) := "101";
	constant state_fir_compute4 : std_logic_vector(2 downto 0) := "110";
	constant state_fir_compute5 : std_logic_vector(2 downto 0) := "111";

	-- Clock domain flash
	signal fir_rom_write_enable : std_logic;
	signal fir_rom_write_address_reg : std_logic_vector(ADDR_WIDTH-2 downto 0);
	signal fir_rom_write_address_next : std_logic_vector(ADDR_WIDTH-2 downto 0);	
	
	signal flash_state_reg : std_logic_vector(1 downto 0);
	signal flash_state_next : std_logic_vector(1 downto 0);
	constant flash_state_init : std_logic_vector(1 downto 0) := "00";
	constant flash_state_request : std_logic_vector(1 downto 0) := "01";
	constant flash_state_wait : std_logic_vector(1 downto 0) := "10";
	constant flash_state_done : std_logic_vector(1 downto 0) := "11";
	
	-- pipeline
	-- rom->register
	-- register->multiplier
	-- multiplier->adder
BEGIN
	process(filter_clk,reset_n)
	begin
		if (reset_n='0') then
			sample_ram_write_address_reg <= (others=>'0');
			sample_ram_read_address1_reg <= (others=>'0');
			sample_ram_read_address2_reg <= (others=>'0');
			fir_rom_address_reg <= (others=>'0');
			mult1_reg <= (others=>'0');
			mult2_reg <= (others=>'0');
			accumulator_reg <= (others=>'0');
			sample_out_reg <= (others=>'0');
			state_reg <= state_wait_sample;
			sample_ram_data1_reg <= (others=>'0');
			sample_ram_data2_reg <= (others=>'0');
			fir_rom_data1_reg <= (others=>'0');
			fir_rom_data2_reg <= (others=>'0');
		elsif (filter_clk'event and filter_clk='1') then
			sample_ram_write_address_reg <= sample_ram_write_address_next;
			sample_ram_read_address1_reg <= sample_ram_read_address1_next;
			sample_ram_read_address2_reg <= sample_ram_read_address2_next;
			fir_rom_address_reg <= fir_rom_address_next;
			mult1_reg <= mult1_next;
			mult2_reg <= mult2_next;
			accumulator_reg <= accumulator_next;
			sample_out_reg <= sample_out_next;
			state_reg <= state_next;
			sample_ram_data1_reg <= sample_ram_data1_next;
			sample_ram_data2_reg <= sample_ram_data2_next;
			fir_rom_data1_reg <= fir_rom_data1_next;
			fir_rom_data2_reg <= fir_rom_data2_next;
		end if;
	end process;
	
	process(flash_clk,reset_n)
	begin
		if (reset_n='0') then
			flash_state_reg <= flash_state_init;
			fir_rom_write_address_reg <= (others=>'0');
		elsif (flash_clk'event and flash_clk='1') then
			flash_state_reg <= flash_state_next;
			fir_rom_write_address_reg <= fir_rom_write_address_next;		
		end if;
	end process;	

	sample_buffer_inst : entity work.fir_sample_buffer
	PORT MAP
	(
		address_a		=> sample_ram_address1,
		address_b		=> sample_ram_address2,
		clock		=> filter_clk,
		data_a		=> std_logic_vector(sample_data),
		data_b		=> (others=>'0'),
		wren_a		=> sample_ram_write_enable,
		wren_b		=> '0',
		q_a		=> sample_ram_data1_next,
		q_b		=> sample_ram_data2_next
	);
	
	fir_data_inst : entity work.fir_buffer
	PORT MAP
	(
	   rdclock => filter_clk,			  
		rdaddress => fir_rom_address_reg,
		q((filter_bits*2)-1 downto filter_bits) => fir_rom_data1_next,
		q(filter_bits-1 downto 0) => fir_rom_data2_next,
	
		wrclock => flash_clk,
		wraddress => fir_rom_write_address_reg,				
		data => flash_data,
		wren => fir_rom_write_enable
	);

	-- res = sum(Fi*Si)
	-- so...
	-- sample in -> store sample
	-- iterate over filter and samples doing multiply and add
	-- store result in register

	process(state_reg,
		sample_enable,
		sample_ram_data1_reg,sample_ram_data2_reg,fir_rom_data1_reg,fir_rom_data2_reg,mult1_reg,mult2_reg,accumulator_reg,
		sample_ram_write_address_reg,sample_ram_read_address1_reg, sample_ram_read_address2_reg,
		fir_rom_address_reg,
		sample_out_reg		
	) is
	begin
		state_next <= state_reg;

		sample_ram_write_address_next <= sample_ram_write_address_reg;

		sample_ram_read_address1_next <= std_logic_vector(unsigned(sample_ram_read_address1_reg)-2);
		sample_ram_read_address2_next <= std_logic_vector(unsigned(sample_ram_read_address2_reg)-2);
		fir_rom_address_next <= std_logic_vector(unsigned(fir_rom_address_reg)+1);

		sample_out_next <= sample_out_reg;

		mult1_next <= signed(sample_ram_data1_reg) * signed(fir_rom_data1_reg);
		mult2_next <= signed(sample_ram_data2_reg) * signed(fir_rom_data2_reg);
		accumulator_next <= accumulator_reg + mult1_reg + mult2_reg;

		sample_ram_write_enable <= '0';
		sample_ram_address1 <= sample_ram_read_address1_reg;
		sample_ram_address2 <= sample_ram_read_address2_reg;

		if (sample_enable='1') then
			sample_ram_write_address_next <= std_logic_vector(unsigned(sample_ram_write_address_reg)-1);
		end if;

		case state_reg is
			when state_wait_sample =>
				sample_ram_write_enable <= sample_enable;
				sample_ram_address1 <= sample_ram_write_address_reg;
				if (sample_enable='1') then
					state_next <= state_fir_prepare;
					--sample_ram_read_address1_next <= std_logic_vector(unsigned(sample_ram_write_address_reg) + to_unsigned(filter_len-1,ADDR_WIDTH));
					--sample_ram_read_address2_next <= std_logic_vector(unsigned(sample_ram_write_address_reg) + to_unsigned(filter_len-2,ADDR_WIDTH));
					sample_ram_read_address1_next <= std_logic_vector(unsigned(sample_ram_write_address_reg) + to_unsigned(0,ADDR_WIDTH));
					sample_ram_read_address2_next <= std_logic_vector(unsigned(sample_ram_write_address_reg) + to_unsigned(-1,ADDR_WIDTH));
					fir_rom_address_next <= (others=>'0');
				end if;
			when state_fir_prepare =>
				state_next <= state_fir_compute1;
			when state_fir_compute1 =>
				state_next <= state_fir_compute2;
			when state_fir_compute2 =>
				state_next <= state_fir_compute3;
			when state_fir_compute3 =>
				state_next <= state_fir_compute4;
				accumulator_next <= (others=>'0');
			when state_fir_compute4 => --6
				-- pipeline is ready, we have data to add to the accumulator
				state_next <= state_fir_compute5;
			when state_fir_compute5 =>
				-- When entering this state we have the accum res
				-- If we have fir length of 1, then it will be 0 in compute1,-1 in compute2 and -2 in compute3. So done==-2 (ffff...ffe)

				if (fir_rom_address_reg = std_logic_vector(to_unsigned((filter_len/2)-1,ADDR_WIDTH-1) + 5)) then
					state_next <= state_wait_sample;
					sample_out_next <= accumulator_reg(FILTER_BITS+SAMPLE_BITS-2 downto FILTER_BITS-1);
				end if;
			when others=>
				state_next <=state_wait_sample;
		end case;

	end process;
	
	-- write domain
	process(flash_state_reg,
		fir_rom_write_address_reg,
		flash_ready
	) is
	begin
		flash_state_next <= flash_state_reg;

		fir_rom_write_address_next <= fir_rom_write_address_reg;
		
		fir_rom_write_enable <= '0';
		flash_request <= '0';

		case flash_state_reg is
			when flash_state_init =>
				fir_rom_write_address_next <= std_logic_vector(to_unsigned(filter_len/2-1,ADDR_WIDTH-1));
				flash_state_next <= flash_state_request;
			when flash_state_request =>
				flash_request <= '1';
				flash_state_next <= flash_state_wait;
			when flash_state_wait =>			    
				flash_request <= '1';
				if (flash_ready = '1') then 
					fir_rom_write_enable <= '1';
					fir_rom_write_address_next <= std_logic_vector(unsigned(fir_rom_write_address_reg)-1);
					flash_request <= '0';

					if (or_reduce(fir_rom_write_address_reg)='0') then
						flash_state_next <= flash_state_done;
					else
						flash_state_next <= flash_state_wait;
					end if;
				end if;
			when flash_state_done =>
				-- nothing
				
			when others=>
				flash_state_next <=flash_state_init;
		end case;
	end process;	

	-- outputs
	sample_out <= sample_out_reg;
	
	FLASH_ADDRESS <= fir_rom_write_address_reg;

end vhdl;

--ARCHITECTURE rtl OF sync_rom IS
--BEGIN
--PROCESS (clock)
--	BEGIN
--	IF rising_edge (clock) THEN
--		CASE address IS
--			WHEN "00000000" => data_out <= "101111";
--			WHEN "00000001" => data_out <= "110110";
--			...
--			WHEN "11111110" => data_out <= "000001";
--			WHEN "11111111" => data_out <= "101010";
--			WHEN OTHERS     => data_out <= "101111";
--		END CASE;
--	END IF;
--	END PROCESS;
--END rtl;

