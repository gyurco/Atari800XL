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

LIBRARY work;

ENTITY sample_top IS 
	PORT
	(
		CLK : in std_logic;
		RESET_N : in std_logic;

		ENABLE : in std_logic;
		
		WRITE_ENABLE : in std_logic;
		ADDR : in std_logic_vector(4 downto 0);
		DI : in std_logic_vector(7 downto 0);

		DO : out std_logic_vector(7 downto 0);
		AUDIO0 : out std_logic_vector(15 downto 0);
		AUDIO1 : out std_logic_vector(15 downto 0);
		IRQ : out std_logic;

		RAM_ADDR : out std_logic_vector(15 downto 0);
		RAM_WRITE_ENABLE : out std_logic;
		RAM_DATA : in std_logic_vector(7 downto 0) -- next cycle: TODO, what if we use rom?
	);
END sample_top;		
		
ARCHITECTURE vhdl OF sample_top IS
	signal CH1_REG : std_logic_vector(15 downto 0);
	signal CH0_REG : std_logic_vector(15 downto 0);
	signal CH1_NEXT : std_logic_vector(15 downto 0);
	signal CH0_NEXT : std_logic_vector(15 downto 0);
	signal CH3_REG : std_logic_vector(15 downto 0);
	signal CH2_REG : std_logic_vector(15 downto 0);
	signal CH3_NEXT : std_logic_vector(15 downto 0);
	signal CH2_NEXT : std_logic_vector(15 downto 0);

        signal ram_cpu_addr_next : std_logic_vector(15 downto 0);
        signal ram_cpu_addr_reg : std_logic_vector(15 downto 0);
        signal ram_cpu_write_enable : std_logic;
        signal ram_cpu_do : std_logic_vector(7 downto 0);

	signal ch0_start_addr_reg : std_logic_vector(15 downto 0);
	signal ch0_start_addr_next : std_logic_vector(15 downto 0);
	signal ch0_len_reg : std_logic_vector(11 downto 0);
	signal ch0_len_next : std_logic_vector(11 downto 0);
	signal ch0_period_reg : std_logic_vector(11 downto 0);
	signal ch0_period_next : std_logic_vector(11 downto 0);
	signal ch0_volume_reg : std_logic_vector(5 downto 0);
	signal ch0_volume_next : std_logic_vector(5 downto 0);

	signal ch1_start_addr_reg : std_logic_vector(15 downto 0);
	signal ch1_start_addr_next : std_logic_vector(15 downto 0);
	signal ch1_len_reg : std_logic_vector(11 downto 0);
	signal ch1_len_next : std_logic_vector(11 downto 0);
	signal ch1_period_reg : std_logic_vector(11 downto 0);
	signal ch1_period_next : std_logic_vector(11 downto 0);
	signal ch1_volume_reg : std_logic_vector(5 downto 0);
	signal ch1_volume_next : std_logic_vector(5 downto 0);

	signal ch2_start_addr_reg : std_logic_vector(15 downto 0);
	signal ch2_start_addr_next : std_logic_vector(15 downto 0);
	signal ch2_len_reg : std_logic_vector(11 downto 0);
	signal ch2_len_next : std_logic_vector(11 downto 0);
	signal ch2_period_reg : std_logic_vector(11 downto 0);
	signal ch2_period_next : std_logic_vector(11 downto 0);
	signal ch2_volume_reg : std_logic_vector(5 downto 0);
	signal ch2_volume_next : std_logic_vector(5 downto 0);

	signal ch3_start_addr_reg : std_logic_vector(15 downto 0);
	signal ch3_start_addr_next : std_logic_vector(15 downto 0);
	signal ch3_len_reg : std_logic_vector(11 downto 0);
	signal ch3_len_next : std_logic_vector(11 downto 0);
	signal ch3_period_reg : std_logic_vector(11 downto 0);
	signal ch3_period_next : std_logic_vector(11 downto 0);
	signal ch3_volume_reg : std_logic_vector(5 downto 0);
	signal ch3_volume_next : std_logic_vector(5 downto 0);
	
	signal dma : std_logic_vector(3 downto 0);
	signal dma_on_reg : std_logic_vector(3 downto 0);
	signal dma_on_next : std_logic_vector(3 downto 0);
	signal channel_reg : std_logic_vector(2 downto 0);
	signal channel_next : std_logic_vector(2 downto 0);
	signal ch0_addr : std_logic_vector(16 downto 0);
	signal ch1_addr : std_logic_vector(16 downto 0);
	signal ch2_addr : std_logic_vector(16 downto 0);
	signal ch3_addr : std_logic_vector(16 downto 0);

	signal irq_en_reg : std_logic_vector(3 downto 0);
	signal irq_en_next : std_logic_vector(3 downto 0);
	signal irq_trigger : std_logic_vector(3 downto 0);
	signal data_request : std_logic_vector(3 downto 0);
	signal irq_clear_n : std_logic_vector(3 downto 0);
	signal irq_active_reg : std_logic_vector(3 downto 0);
	signal irq_active_next : std_logic_vector(3 downto 0);

	signal adpcm_decoded : std_logic_vector(15 downto 0);
	signal adpcm_reg : std_logic_vector(3 downto 0);
	signal adpcm_next : std_logic_vector(3 downto 0);

	signal addr_decoded5 : std_logic_vector(31 downto 0);	

	signal enable_cycle_shift_reg : std_logic_vector(4 downto 0);
	signal enable_cycle_shift_next : std_logic_vector(4 downto 0);

BEGIN

	decode_addr2 : entity work.complete_address_decoder
		generic map(width=>5)
		port map (addr_in=>ADDR(4 downto 0), addr_decoded=>addr_decoded5);

	process(addr_decoded5,CH0_REG,CH1_REG,CH2_REG,CH3_REG,
		ram_cpu_addr_reg, ram_cpu_do, 
		irq_en_reg,irq_active_reg
		)
	begin
		DO <= (others=>'0');
	
		if (addr_decoded5(0)='1') then
			DO <= CH0_REG(15 downto 8);
		end if;
	
		if (addr_decoded5(1)='1') then
			DO <= CH1_REG(15 downto 8);
		end if;
	
		if (addr_decoded5(2)='1') then
			DO <= CH2_REG(15 downto 8);
		end if;
	
		if (addr_decoded5(3)='1') then
			DO <= CH3_REG(15 downto 8);
		end if;
	
		if (addr_decoded5(4)='1') then
			DO <= ram_cpu_addr_reg(7 downto 0);
		end if;
		if (addr_decoded5(5)='1') then
			DO <= ram_cpu_addr_reg(15 downto 8);
		end if;
		if (addr_decoded5(6)='1') then --manual addr inc
			DO <= ram_cpu_do;
		end if;
		if (addr_decoded5(17)='1') then
			DO(3 downto 0) <= irq_en_reg;
		end if;
		if (addr_decoded5(18)='1') then
			DO(3 downto 0) <= irq_active_reg;
		end if;
	end process;
	
	adpcm_decoder : entity work.sample_adpcm
		port map (clk=>clk,reset_n=>reset_n,syncreset=>irq_trigger,fetch=>dma,update=>data_request,data_nibble=>ch3_addr(0)&ch2_addr(0)&ch1_addr(0)&ch0_addr(0),data_in=>ram_data, data_out=>adpcm_decoded);
		-- TODO -> feed in data slower and each nibble
	
	process(addr_decoded5, WRITE_ENABLE,
	CH0_REG,CH1_REG,CH2_REG,CH3_REG,DI,
	ram_cpu_addr_reg,
	ch0_start_addr_reg, ch0_len_reg, ch0_period_reg, ch0_volume_reg,
	ch1_start_addr_reg, ch1_len_reg, ch1_period_reg, ch1_volume_reg,
	ch2_start_addr_reg, ch2_len_reg, ch2_period_reg, ch2_volume_reg,
	ch3_start_addr_reg, ch3_len_reg, ch3_period_reg, ch3_volume_reg,
	dma_on_reg,dma,ram_data,
	channel_reg,
	irq_en_reg,irq_active_reg,irq_trigger,irq_clear_n,
	adpcm_decoded,adpcm_reg
	)
		variable ram_player_do_u : std_logic_vector(7 downto 0);
	begin
		CH0_NEXT <= CH0_REG;
		CH1_NEXT <= CH1_REG;
		CH2_NEXT <= CH2_REG;
		CH3_NEXT <= CH3_REG;
	
		ram_cpu_write_enable <= '0';
		ram_cpu_addr_next <= ram_cpu_addr_reg;
	
		ch0_start_addr_next <= ch0_start_addr_reg;
		ch0_len_next <= ch0_len_reg;
		ch0_period_next <= ch0_period_reg;
		ch0_volume_next <= ch0_volume_reg;
	
		ch1_start_addr_next <= ch1_start_addr_reg;
		ch1_len_next <= ch1_len_reg;
		ch1_period_next <= ch1_period_reg;
		ch1_volume_next <= ch1_volume_reg;
	
		ch2_start_addr_next <= ch2_start_addr_reg;
		ch2_len_next <= ch2_len_reg;
		ch2_period_next <= ch2_period_reg;
		ch2_volume_next <= ch2_volume_reg;
	
		ch3_start_addr_next <= ch3_start_addr_reg;
		ch3_len_next <= ch3_len_reg;
		ch3_period_next <= ch3_period_reg;
		ch3_volume_next <= ch3_volume_reg;
	
		dma_on_next <= dma_on_reg;
	
		channel_next <= channel_reg;
	
		irq_clear_n <= (others=>'1');
		irq_en_next <= irq_en_reg;
		irq_active_next <= (irq_active_reg or irq_trigger) and irq_en_reg and irq_clear_n;
	
		adpcm_next <= adpcm_reg;
	
		ram_player_do_u(7) := NOT(ram_data(7));
		ram_player_do_u(6 downto 0) := ram_data(6 downto 0);
	
		case dma is
		when "0001"=>
			if (adpcm_reg(0)='0') then
				CH0_NEXT <= ram_player_do_u&"00000000";
			else
				CH0_NEXT <= adpcm_decoded;
			end if;
		when "0010" =>
			if (adpcm_reg(1)='0') then
				CH1_NEXT <= ram_player_do_u&"00000000";
			else
				CH1_NEXT <= adpcm_decoded;
			end if;
		when "0100" =>
			if (adpcm_reg(2)='0') then
				CH2_NEXT <= ram_player_do_u&"00000000";
			else
				CH2_NEXT <= adpcm_decoded;
			end if;
		when "1000" => 
			if (adpcm_reg(3)='0') then
				CH3_NEXT <= ram_player_do_u&"00000000";
			else
				CH3_NEXT <= adpcm_decoded;
			end if;
		when others =>
			if (write_enable='1') then
				if (addr_decoded5(0)='1') then
					CH0_NEXT(15 downto 8) <= DI;
				end if;
				if (addr_decoded5(1)='1') then
					CH1_NEXT(15 downto 8) <= DI;
				end if;
				if (addr_decoded5(2)='1') then
					CH2_NEXT(15 downto 8) <= DI;
				end if;
				if (addr_decoded5(3)='1') then
					CH3_NEXT(15 downto 8) <= DI;
				end if;
	
				if (addr_decoded5(4)='1') then
					ram_cpu_addr_next(7 downto 0) <= DI;
				end if;
				if (addr_decoded5(5)='1') then
					ram_cpu_addr_next(15 downto 8) <= DI;
				end if;
				if (addr_decoded5(6)='1') then --manual addr inc
					ram_cpu_write_enable <= '1';
				end if;
				if (addr_decoded5(7)='1') then --auto addr inc
					ram_cpu_write_enable <= '1';
					ram_cpu_addr_next <= ram_cpu_addr_reg + 1;
				end if;
	
				if (addr_decoded5(8)='1') then
					channel_next(2 downto 0) <= DI(2 downto 0);
				end if;
	
				case channel_reg is
					when "001" =>
						if (addr_decoded5(9)='1') then
							ch0_start_addr_next(7 downto 0) <= DI;
						end if;
						if (addr_decoded5(10)='1') then
							ch0_start_addr_next(15 downto 8) <= DI;
						end if;
						if (addr_decoded5(11)='1') then
							ch0_len_next(7 downto 0) <= DI;
						end if;
						if (addr_decoded5(12)='1') then
							ch0_len_next(11 downto 8) <= DI(3 downto 0);
						end if;
						if (addr_decoded5(13)='1') then
							ch0_period_next(7 downto 0) <= DI;
						end if;
						if (addr_decoded5(14)='1') then
							ch0_period_next(11 downto 8) <= DI(3 downto 0);
						end if;
						if (addr_decoded5(15)='1') then
							ch0_volume_next(5 downto 0) <= DI(5 downto 0);
						end if;
					when "010" =>
						if (addr_decoded5(9)='1') then
							ch1_start_addr_next(7 downto 0) <= DI;
						end if;
						if (addr_decoded5(10)='1') then
							ch1_start_addr_next(15 downto 8) <= DI;
						end if;
						if (addr_decoded5(11)='1') then
							ch1_len_next(7 downto 0) <= DI;
						end if;
						if (addr_decoded5(12)='1') then
							ch1_len_next(11 downto 8) <= DI(3 downto 0);
						end if;
						if (addr_decoded5(13)='1') then
							ch1_period_next(7 downto 0) <= DI;
						end if;
						if (addr_decoded5(14)='1') then
							ch1_period_next(11 downto 8) <= DI(3 downto 0);
						end if;
						if (addr_decoded5(15)='1') then
							ch1_volume_next(5 downto 0) <= DI(5 downto 0);
						end if;
					when "011" =>
						if (addr_decoded5(9)='1') then
							ch2_start_addr_next(7 downto 0) <= DI;
						end if;
						if (addr_decoded5(10)='1') then
							ch2_start_addr_next(15 downto 8) <= DI;
						end if;
						if (addr_decoded5(11)='1') then
							ch2_len_next(7 downto 0) <= DI;
						end if;
						if (addr_decoded5(12)='1') then
							ch2_len_next(11 downto 8) <= DI(3 downto 0);
						end if;
						if (addr_decoded5(13)='1') then
							ch2_period_next(7 downto 0) <= DI;
						end if;
						if (addr_decoded5(14)='1') then
							ch2_period_next(11 downto 8) <= DI(3 downto 0);
						end if;
						if (addr_decoded5(15)='1') then
							ch2_volume_next(5 downto 0) <= DI(5 downto 0);
						end if;
					when "100" =>
						if (addr_decoded5(9)='1') then
							ch3_start_addr_next(7 downto 0) <= DI;
						end if;
						if (addr_decoded5(10)='1') then
							ch3_start_addr_next(15 downto 8) <= DI;
						end if;
						if (addr_decoded5(11)='1') then
							ch3_len_next(7 downto 0) <= DI;
						end if;
						if (addr_decoded5(12)='1') then
							ch3_len_next(11 downto 8) <= DI(3 downto 0);
						end if;
						if (addr_decoded5(13)='1') then
							ch3_period_next(7 downto 0) <= DI;
						end if;
						if (addr_decoded5(14)='1') then
							ch3_period_next(11 downto 8) <= DI(3 downto 0);
						end if;
						if (addr_decoded5(15)='1') then
							ch3_volume_next(5 downto 0) <= DI(5 downto 0);
						end if;
					when others =>
				end case;
				if (addr_decoded5(16)='1') then
					dma_on_next <= DI(3 downto 0);
				end if;
				if (addr_decoded5(17)='1') then
					irq_en_next <= DI(3 downto 0);
				end if;
				if (addr_decoded5(18)='1') then
					irq_clear_n <= DI(3 downto 0); --write 0 to disable
				end if;
				if (addr_decoded5(19)='1') then
					adpcm_next <= DI(3 downto 0); 
				end if;
			end if;
		end case;
	end process;
	
	ch0_inst: entity work.sample_channel
	PORT MAP
	( 
		CLK => CLK,
		RESET_N => RESET_N,
		ENABLE => ENABLE_CYCLE_SHIFT_REG(0),
	
		syncreset => (dma_on_next(0) xor dma_on_reg(0)),
		start_addr => ch0_start_addr_reg,
		len => ch0_len_reg,
		period => ch0_period_reg,
		
		twocycles => adpcm_reg(0),
		
		addr => ch0_addr,
		irq => irq_trigger(0),
		req => data_request(0)
	);
	
	ch1_inst: entity work.sample_channel
	PORT MAP
	( 
		CLK => CLK,
		RESET_N => RESET_N,
		ENABLE => ENABLE_CYCLE_SHIFT_REG(1),
	
		syncreset => (dma_on_next(1) xor dma_on_reg(1)),
		start_addr => ch1_start_addr_reg,
		len => ch1_len_reg,
		period => ch1_period_reg,
		
		twocycles => adpcm_reg(1),
		
		addr => ch1_addr,
		irq => irq_trigger(1),
		req => data_request(1)
	);
	
	ch2_inst: entity work.sample_channel
	PORT MAP
	( 
		CLK => CLK,
		RESET_N => RESET_N,
		ENABLE => ENABLE_CYCLE_SHIFT_REG(2),
	
		syncreset => (dma_on_next(2) xor dma_on_reg(2)),
		start_addr => ch2_start_addr_reg,
		len => ch2_len_reg,
		period => ch2_period_reg,
		
		twocycles => adpcm_reg(2),
		
		addr => ch2_addr,
		irq => irq_trigger(2),
		req => data_request(2)
	);
	
	ch3_inst: entity work.sample_channel
	PORT MAP
	( 
		CLK => CLK,
		RESET_N => RESET_N,
		ENABLE => ENABLE_CYCLE_SHIFT_REG(3),
	
		syncreset => (dma_on_next(3) xor dma_on_reg(3)),
		start_addr => ch3_start_addr_reg,
		len => ch3_len_reg,
		period => ch3_period_reg,
		
		twocycles => adpcm_reg(3),
		
		addr => ch3_addr,
		irq => irq_trigger(3),
		req => data_request(3)
	);
	
	process (ch0_reg,ch1_reg,ch2_reg,ch3_reg,
		ch0_volume_reg,ch1_volume_reg,ch2_volume_reg,ch3_volume_reg)
		variable l : unsigned(26 downto 0);
		variable r : unsigned(26 downto 0);
	begin
		l :=     resize(unsigned(CH0_REG),18)*resize(unsigned(ch0_volume_reg),9);
		l := l + resize(unsigned(CH3_REG),18)*resize(unsigned(ch3_volume_reg),9);
		r :=     resize(unsigned(CH1_REG),18)*resize(unsigned(ch1_volume_reg),9);
	        r := r + resize(unsigned(CH2_REG),18)*resize(unsigned(ch2_volume_reg),9);
		-- TODO: probably need to register here?
		AUDIO0 <= std_logic_vector(l(21 downto 6));
		AUDIO1 <= std_logic_vector(r(21 downto 6));
	
		-- TODO: modulation?
		-- TODO: samples from rom and put in voice samples after core?
		-- TODO: 4 bit mode?
	
		-- options to set: per channel: modulate volume(4),modulate period(4),sample bits(4)
	end process;
	
	process(ch0_addr,ch1_addr,ch2_addr,ch3_addr,
		ram_cpu_addr_reg,
		enable_cycle_shift_reg,
		dma_on_reg)
	begin
		dma <= (others=>'0');

		ram_addr <= ram_cpu_addr_reg;
	
		case (enable_cycle_shift_reg) is
		when "00001" => 
	        	ram_addr <= ch0_addr(16 downto 1);			
		when "00010" => 
	        	ram_addr <= ch1_addr(16 downto 1);
				dma(0) <= dma_on_reg(0);
		when "00100" => 
	        	ram_addr <= ch2_addr(16 downto 1);			
				dma(1) <= dma_on_reg(1);
		when "01000" => 
	        	ram_addr <= ch3_addr(16 downto 1);
				dma(2) <= dma_on_reg(2);
		when "10000" => 
				dma(3) <= dma_on_reg(3);
		when others =>
		end case;
	end process;
	
	process(clk,reset_n)
	begin
		if (reset_n='0') then
			CH0_REG <= (others=>'0');
			CH1_REG <= (others=>'0');
			CH2_REG <= (others=>'0');
			CH3_REG <= (others=>'0');
			ram_cpu_addr_reg <= (others=>'0');
	
			ch0_start_addr_reg <= (others=>'0');
			ch0_len_reg <= (others=>'0');
			ch0_period_reg <= (others=>'0');
			ch0_volume_reg <= (others=>'1');
	
			ch1_start_addr_reg <= (others=>'0');
			ch1_len_reg <= (others=>'0');
			ch1_period_reg <= (others=>'0');
			ch1_volume_reg <= (others=>'1');
	
			ch2_start_addr_reg <= (others=>'0');
			ch2_len_reg <= (others=>'0');
			ch2_period_reg <= (others=>'0');
			ch2_volume_reg <= (others=>'1');
	
			ch3_start_addr_reg <= (others=>'0');
			ch3_len_reg <= (others=>'0');
			ch3_period_reg <= (others=>'0');
			ch3_volume_reg <= (others=>'1');
	
			dma_on_reg <= (others=>'0');
			irq_en_reg <= (others=>'0');
			irq_active_reg <= (others=>'0');
			channel_reg <= (others=>'0');
			
			adpcm_reg <= (others=>'0');
	
			ENABLE_CYCLE_SHIFT_REG <= (others=>'0');
		elsif (clk'event and clk='1') then
			CH0_REG <= CH0_NEXT;
			CH1_REG <= CH1_NEXT;
			CH2_REG <= CH2_NEXT;
			CH3_REG <= CH3_NEXT;
			ram_cpu_addr_reg <= ram_cpu_addr_next;
	
			ch0_start_addr_reg <= ch0_start_addr_next;
			ch0_len_reg <= ch0_len_next;
			ch0_period_reg <= ch0_period_next;
			ch0_volume_reg <= ch0_volume_next;
	
			ch1_start_addr_reg <= ch1_start_addr_next;
			ch1_len_reg <= ch1_len_next;
			ch1_period_reg <= ch1_period_next;
			ch1_volume_reg <= ch1_volume_next;
	
			ch2_start_addr_reg <= ch2_start_addr_next;
			ch2_len_reg <= ch2_len_next;
			ch2_period_reg <= ch2_period_next;
			ch2_volume_reg <= ch2_volume_next;
	
			ch3_start_addr_reg <= ch3_start_addr_next;
			ch3_len_reg <= ch3_len_next;
			ch3_period_reg <= ch3_period_next;
			ch3_volume_reg <= ch3_volume_next;
	
			dma_on_reg <= dma_on_next;
			irq_en_reg <= irq_en_next;
			irq_active_reg <= irq_active_next;
			channel_reg <= channel_next;
	
			adpcm_reg <= adpcm_next;
	
			ENABLE_CYCLE_SHIFT_REG <= ENABLE_CYCLE_SHIFT_NEXT;
		end if;
	end process;
	
	ENABLE_CYCLE_SHIFT_NEXT <= ENABLE_CYCLE_SHIFT_REG(3 downto 0)&ENABLE;

	IRQ <= or_reduce(irq_active_reg);

	RAM_WRITE_ENABLE <= RAM_CPU_WRITE_ENABLE;
END vhdl;
