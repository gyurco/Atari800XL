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

LIBRARY work;

ENTITY atari800core_mcc IS 
	PORT
	(
		FPGA_CLK :  IN  STD_LOGIC;

		PS2K_CLK :  IN  STD_LOGIC;
		PS2K_DAT :  IN  STD_LOGIC;
		PS2M_CLK :  IN  STD_LOGIC;
		PS2M_DAT :  IN  STD_LOGIC;		

		VGA_VS :  OUT  STD_LOGIC;
		VGA_HS :  OUT  STD_LOGIC;
		VGA_B :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_G :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0);
		VGA_R :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0);
		
		JOY1_n :  IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
		JOY2_n :  IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
		
		AUDIO_L : OUT std_logic;
		AUDIO_R : OUT std_logic;

		SDRAM_BA :  OUT  STD_LOGIC_VECTOR(1 downto 0);
		SDRAM_CS_N :  OUT  STD_LOGIC;
		SDRAM_RAS_N :  OUT  STD_LOGIC;
		SDRAM_CAS_N :  OUT  STD_LOGIC;
		SDRAM_WE_N :  OUT  STD_LOGIC;
		SDRAM_DQM_n :  OUT  STD_LOGIC_vector(1 downto 0);
		SDRAM_CLK :  OUT  STD_LOGIC;
		--SDRAM_CKE :  OUT  STD_LOGIC;
		SDRAM_A :  OUT  STD_LOGIC_VECTOR(12 DOWNTO 0);
		SDRAM_DQ :  INOUT  STD_LOGIC_VECTOR(15 DOWNTO 0);

		SD_DAT0 :  IN  STD_LOGIC;
		SD_CLK :  OUT  STD_LOGIC;
		SD_CMD :  OUT  STD_LOGIC;
		SD_DAT3 :  OUT  STD_LOGIC
	);
END atari800core_mcc;

ARCHITECTURE vhdl OF atari800core_mcc IS 

component hq_dac
port (
  reset :in std_logic;
  clk :in std_logic;
  clk_ena : in std_logic;
  pcm_in : in std_logic_vector(19 downto 0);
  dac_out : out std_logic
);
end component;

COMPONENT sdram_ctrl
port
(
  --//--------------------
  --// Clocks and reset --
  --//--------------------
  --// Global reset
  rst : in std_logic;
  --// Controller clock
  clk : in std_logic;
  --// Sequencer cycles
  seq_cyc : in std_logic_vector(11 downto 0);
  --// Sequencer phase
  seq_ph : in std_logic;
  --// Refresh cycle
  refr_cyc : in std_logic;
  --//------------------------
  --// Access port #1 (CPU) --
  --//------------------------
  --// RAM select
  ap1_ram_sel : in std_logic;
  --// Address bus
  ap1_address : in std_logic_vector(23 downto 1);
  --// Read enable
  ap1_rden : in std_logic;
  --// Write enable
  ap1_wren : in std_logic;
  --// Byte enable
  ap1_bena : in std_logic_vector(1 downto 0);
  --// Data bus (read)
  ap1_rddata : out std_logic_vector(15 downto 0);
  --// Data bus (write)
  ap1_wrdata : in std_logic_vector(15 downto 0);
  --// Burst size
  ap1_bst_siz : in std_logic_vector(2 downto 0);
  --// Read burst active
  ap1_rd_bst_act : out std_logic;
  --// Write burst active
  ap1_wr_bst_act : out std_logic;
  --//------------------------
  --// Access port #2 (GPU) --
  --//------------------------
  --// RAM select
  ap2_ram_sel : in std_logic;
  --// Address bus
  ap2_address : in std_logic_vector(23 downto 1);
  --// Read enable
  ap2_rden : in std_logic;
  --// Write enable
  ap2_wren : in std_logic;
  --// Byte enable
  ap2_bena : in std_logic_vector(1 downto 0);
  --// Data bus (read)
  ap2_rddata : out std_logic_vector(15 downto 0);
  --// Data bus (write)
  ap2_wrdata : in std_logic_vector(15 downto 0);
  --// Burst size
  ap2_bst_siz : in std_logic_vector(2 downto 0);
  --// Read burst active
  ap2_rd_bst_act : out std_logic;
  --// Write burst active
  ap2_wr_bst_act : out std_logic;
  --//------------------------
  --// Access port #3 (CTL) --
  --//------------------------
  --// RAM select
  ap3_ram_sel : in std_logic;
  --// Address bus
  ap3_address : in std_logic_vector(23 downto 1);
  --// Read enable
  ap3_rden : in std_logic;
  --// Write enable
  ap3_wren : in std_logic;
  --// Byte enable
  ap3_bena : in std_logic_vector(1 downto 0);
  --// Data bus (read)
  ap3_rddata : out std_logic_vector(15 downto 0);
  --// Data bus (write)
  ap3_wrdata : in std_logic_vector(15 downto 0);
  --// Burst size
  ap3_bst_siz : in std_logic_vector(2 downto 0);
  --// Read burst active
  ap3_rd_bst_act : out std_logic;
  --// Write burst active
  ap3_wr_bst_act : out std_logic;
  --//------------------------
  --// SDRAM memory signals --
  --//------------------------
  --// SDRAM controller ready
  sdram_rdy : out std_logic;
  --// SDRAM chip select
  sdram_cs_n : out std_logic;
  --// SDRAM row address strobe
  sdram_ras_n : out std_logic;
  --// SDRAM column address strobe
  sdram_cas_n : out std_logic;
  --// SDRAM write enable
  sdram_we_n : out std_logic;
  --// SDRAM DQ masks
  sdram_dqm_n : out std_logic_vector(1 downto 0);
  --// SDRAM bank address
  sdram_ba : out std_logic_vector(1 downto 0);
  --// SDRAM address
  sdram_addr : out std_logic_vector(11 downto 0);
  --// SDRAM data
  sdram_dq_oe : out std_logic;
  sdram_dq_o : out std_logic_vector(15 downto 0);
  sdram_dq_i : in std_logic_vector(15 downto 0)
);
END COMPONENT;

COMPONENT pll
	PORT(inclk0 : IN STD_LOGIC;
		 c0 : OUT STD_LOGIC;
		 c1 : OUT STD_LOGIC;
		 c2 : OUT STD_LOGIC;
		 locked : OUT STD_LOGIC
	);
END COMPONENT;

	signal AUDIO_L_PCM : std_logic_vector(15 downto 0);
	signal AUDIO_R_PCM : std_logic_vector(15 downto 0);
	
	signal VGA_VS_RAW : std_logic;
	signal VGA_HS_RAW : std_logic;
	
	signal JOY1_IN_n : std_logic_vector(4 downto 0);
	signal JOY2_IN_n : std_logic_vector(4 downto 0);
	
	signal RESET_n : std_logic;
	signal PLL_LOCKED : std_logic;
	signal CLK : std_logic;
	signal CLK_SDRAM : std_logic;

	-- SDRAM
	signal SDRAM_REQUEST : std_logic;
	signal SDRAM_REQUEST_COMPLETE : std_logic;
	signal SDRAM_READ_ENABLE :  STD_LOGIC;
	signal SDRAM_WRITE_ENABLE : std_logic;
	signal SDRAM_ADDR : STD_LOGIC_VECTOR(22 DOWNTO 0);
	SIGNAL SDRAM_DI : std_logic_vector(31 downto 0);
	SIGNAL SDRAM_WIDTH_32BIT_ACCESS : std_logic;
	SIGNAL SDRAM_WIDTH_16BIT_ACCESS : std_logic;
	SIGNAL SDRAM_WIDTH_8BIT_ACCESS : std_logic;
	
	signal SDRAM_REFRESH : std_logic;

	signal SYSTEM_RESET_REQUEST: std_logic;

	signal seq_reg : std_logic_vector(11 downto 0);
	signal seq_next : std_logic_vector(11 downto 0);
	
	signal seq_ph_reg : std_logic;
	signal seq_ph_next : std_logic;
	
	signal ref_reg : std_logic;
	signal ref_next : std_logic;

	signal sdram_request_complete_next : std_logic;
	signal sdram_request_complete_reg : std_logic;

	signal sdram_request_next : std_logic;
	signal sdram_request_reg : std_logic;

	signal ram_di_next : std_logic_vector(15 downto 0);
	signal ram_di_reg : std_logic_vector(15 downto 0);

	signal ram_do_next : std_logic_vector(31 downto 0);
	signal ram_do_reg : std_logic_vector(31 downto 0);

	signal ram_do : std_logic_vector(15 downto 0);

	signal ram_bena_next : std_logic_vector(1 downto 0);
	signal ram_bena_reg : std_logic_vector(1 downto 0);

	signal ram_rd_active : std_logic;
	signal ram_wr_active : std_logic;

	signal sdram_dq_oe : std_logic;
	signal sdram_dq_o : std_logic_vector(15 downto 0);
	signal sdram_dq_i : std_logic_vector(15 downto 0);
	
	signal sdram_rdy : std_logic;

	-- pokey keyboard
	SIGNAL KEYBOARD_SCAN : std_logic_vector(5 downto 0);
	SIGNAL KEYBOARD_RESPONSE : std_logic_vector(1 downto 0);
	
	-- gtia consol keys
	SIGNAL CONSOL_START : std_logic;
	SIGNAL CONSOL_SELECT : std_logic;
	SIGNAL CONSOL_OPTION : std_logic;

	-- 6502 throttling
	SIGNAL THROTTLE_COUNT_6502 : std_logic_vector(5 downto 0);

BEGIN 

dac_left : hq_dac
port map
(
  reset => not(reset_n),
  clk => clk,
  clk_ena => '1',
  pcm_in => AUDIO_L_PCM&"0000",
  dac_out => audio_l
);

dac_right : hq_dac
port map
(
  reset => not(reset_n),
  clk => clk,
  clk_ena => '1',
  pcm_in => AUDIO_R_PCM&"0000",
  dac_out => audio_r
);

mcc_pll : pll
PORT MAP(inclk0 => FPGA_CLK,
		 c0 => CLK_SDRAM,
		 c1 => CLK,
		 c2 => SDRAM_CLK,
		 locked => PLL_LOCKED);

reset_n <= PLL_LOCKED;
JOY1_IN_N <= JOY1_n(4)&JOY1_n(0)&JOY1_n(1)&JOY1_n(2)&JOY1_n(3);
JOY2_IN_N <= JOY2_n(4)&JOY2_n(0)&JOY2_n(1)&JOY2_n(2)&JOY2_n(3);

-- THROTTLE
THROTTLE_COUNT_6502 <= std_logic_vector(to_unsigned(32-1,6));

-- VIDEO
VGA_HS <= not(VGA_HS_RAW xor VGA_VS_RAW);
VGA_VS <= not(VGA_VS_RAW);

--atari800xl : entity work.atari800core_helloworld
--	GENERIC MAP
--	(
--		cycle_length => 32,
--		video_bits => 4,
--		internal_ram => 16384
--	)
--	PORT MAP
--	(
--		CLK => clk,
--		RESET_N => reset_n,
--
--		VGA_VS => vga_vs_raw,
--		VGA_HS => vga_hs_raw,
--		VGA_B => vga_b,
--		VGA_G => vga_g,
--		VGA_R => vga_r,
--
--		AUDIO_L => AUDIO_L_PCM,
--		AUDIO_R => AUDIO_R_PCM,
--
--		JOY1_n => JOY1_IN_n,
--		JOY2_n => JOY2_IN_n,
--
--		PS2_CLK => ps2k_clk,
--		PS2_DAT => ps2k_dat,
--
--		PAL => '1'
--	);

-- PS2 to pokey
keyboard_map1 : entity work.ps2_to_atari800
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,
		PS2_CLK => ps2k_clk,
		PS2_DAT => ps2k_dat,
		
		KEYBOARD_SCAN => KEYBOARD_SCAN,
		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,

		CONSOL_START => CONSOL_START,
		CONSOL_SELECT => CONSOL_SELECT,
		CONSOL_OPTION => CONSOL_OPTION
		
		-- TODO - reset!
	);

atarixl_simple_sdram1 : entity work.atari800core_simple_sdram
	GENERIC MAP
	(
		cycle_length => 16,
		internal_rom => 1,
		internal_ram => 0,
		video_bits => 4
	)
	PORT MAP
	(
		CLK => CLK,
		--RESET_N => RESET_N and SDRAM_RESET_N and not(SYSTEM_RESET_REQUEST),
		RESET_N => RESET_N and sdram_rdy,

		VGA_VS => VGA_VS_RAW,
		VGA_HS => VGA_HS_RAW,
		VGA_B => VGA_B,
		VGA_G => VGA_G,
		VGA_R => VGA_R,

		AUDIO_L => AUDIO_L_PCM,
		AUDIO_R => AUDIO_R_PCM,

		JOY1_n => JOY1_IN_n,
		JOY2_n => JOY2_IN_n,

		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,
		KEYBOARD_SCAN => KEYBOARD_SCAN,

		SIO_COMMAND => open,
		SIO_RXD => '1',
		SIO_TXD => open,

		CONSOL_OPTION => CONSOL_OPTION,
		CONSOL_SELECT => CONSOL_SELECT,
		CONSOL_START => CONSOL_START,

		SDRAM_REQUEST => SDRAM_REQUEST,
		SDRAM_REQUEST_COMPLETE => SDRAM_REQUEST_COMPLETE,
		SDRAM_READ_ENABLE => SDRAM_READ_ENABLE,
		SDRAM_WRITE_ENABLE => SDRAM_WRITE_ENABLE,
		SDRAM_ADDR => SDRAM_ADDR,
		SDRAM_DO => ram_do_reg,
		SDRAM_DI => SDRAM_DI,
		SDRAM_32BIT_WRITE_ENABLE => SDRAM_WIDTH_32bit_ACCESS,
		SDRAM_16BIT_WRITE_ENABLE => SDRAM_WIDTH_16bit_ACCESS,
		SDRAM_8BIT_WRITE_ENABLE => SDRAM_WIDTH_8bit_ACCESS,

		DMA_FETCH => '0',
		DMA_READ_ENABLE => '0',
		DMA_32BIT_WRITE_ENABLE => '0',
		DMA_16BIT_WRITE_ENABLE => '0',
		DMA_8BIT_WRITE_ENABLE => '0',
		DMA_ADDR => (others=>'1'),
		DMA_WRITE_DATA => (others=>'1'),
		MEMORY_READY_DMA => open,

   		RAM_SELECT => (others=>'0'),
    		ROM_SELECT => "000001",
		PAL => '1',
		HALT => '0',
		THROTTLE_COUNT_6502 => THROTTLE_COUNT_6502
	);

--b2v_inst20 : sdram_statemachine_mcc
--GENERIC MAP(ADDRESS_WIDTH => 22,
--			AP_BIT => 10,
--			COLUMN_WIDTH => 8,
--			ROW_WIDTH => 12
--			)
--PORT MAP(CLK_SYSTEM => CLK,
--		 CLK_SDRAM => CLK_SDRAM,
--		 RESET_N => RESET_N,
--		 READ_EN => SDRAM_READ_ENABLE,
--		 WRITE_EN => SDRAM_WRITE_ENABLE,
--		 REQUEST => SDRAM_REQUEST,
--		 BYTE_ACCESS => WIDTH_8BIT_ACCESS,
--		 WORD_ACCESS => WIDTH_16BIT_ACCESS,
--		 LONGWORD_ACCESS => WIDTH_32BIT_ACCESS,
--		 REFRESH => SDRAM_REFRESH,
--		 ADDRESS_IN => SDRAM_ADDR,
--		 DATA_IN => WRITE_DATA,
--		 SDRAM_DQ => SDRAM_DQ,
--		 REPLY => SDRAM_REQUEST_COMPLETE,
--		 SDRAM_BA0 => SDRAM_BA(0),
--		 SDRAM_BA1 => SDRAM_BA(1),
--		 --SDRAM_CKE => SDRAM_A(12), -- TODO?
--		 SDRAM_CS_N => SDRAM_CS_N,
--		 SDRAM_RAS_N => SDRAM_RAS_N,
--		 SDRAM_CAS_N => SDRAM_CAS_N,
--		 SDRAM_WE_N => SDRAM_WE_N,
--		 SDRAM_ldqm => SDRAM_DQM_n(0),
--		 SDRAM_udqm => SDRAM_DQM_n(1),
--		 DATA_OUT => SDRAM_DO,
--		 SDRAM_ADDR => SDRAM_A(12 downto 0)); -- TODO?

	process(clk_sdram,reset_n)
	begin
		if (reset_n='0') then
			seq_reg <= "000000000001";
			seq_ph_reg <= '0';
			ref_reg <= '0';

			ram_do_reg <= (others=>'0');
			ram_di_reg <= (others=>'0');
			ram_bena_reg <= (others=>'0');
			sdram_request_complete_reg <= '0';
			sdram_request_reg <= '0';
		elsif (clk_sdram'event and clk_sdram = '1') then
			seq_reg <= seq_next;
			seq_ph_reg <= seq_ph_next;
			ref_reg <= ref_next;

			ram_do_reg <= ram_do_next;
			ram_di_reg <= ram_di_next;
			ram_bena_reg <= ram_bena_next;
			sdram_request_complete_reg <= sdram_request_complete_next;
			sdram_request_reg <= sdram_request_next;
		end if;
	end process;

	-- Generate sdram sequence
	process(seq_reg, seq_ph_reg, ref_reg)
	begin
		seq_next <= seq_reg(10 downto 0)&seq_reg(11);
		seq_ph_next <= seq_ph_reg;
		ref_next <= ref_reg;
		if (seq_reg(10) = '1') then
			seq_ph_next <= not(seq_ph_reg);
			ref_next <= not(ref_reg);
		end if;
	end process;

	-- Adapt SDRAM
	process(sdram_request_reg, sdram_request, sdram_request_complete_reg, ram_do_reg, seq_reg, ram_do, ram_rd_active, ram_wr_active, SDRAM_WIDTH_8BIT_ACCESS, SDRAM_WRITE_ENABLE, SDRAM_READ_ENABLE, SDRAM_DI, SDRAM_ADDR)
	begin
		sdram_request_next <= sdram_request_reg or sdram_request;
		sdram_request_complete_next <= sdram_request_complete_reg;
		ram_bena_next <= "00";
		ram_di_next <= (others=>'0');
		ram_do_next <= ram_do_reg;

		case seq_reg is
		when "000000000001" =>
			-- nop
		when "000000000010" => -- write data from next...
			if (SDRAM_WRITE_ENABLE = '1') then
				if (SDRAM_WIDTH_8BIT_ACCESS = '1') then
					ram_di_next <= SDRAM_DI(7 downto 0)&SDRAM_DI(7 downto 0);
					ram_bena_next <= SDRAM_ADDR(0)&not(SDRAM_ADDR(0));
				else
					ram_di_next <= SDRAM_DI(15 downto 0);
					ram_bena_next <= "11";
				end if;
			end if;
		when "000000000100" =>
			if (SDRAM_WRITE_ENABLE = '1') then
				if (SDRAM_WIDTH_8BIT_ACCESS = '1') then
					ram_di_next <= (others=>'0');
				else
					ram_di_next <= SDRAM_DI(15 downto 0);
					ram_bena_next <= "11";
				end if;
			end if;
			if ((ram_wr_active)='1') then
				sdram_request_complete_next <= '1';
				sdram_request_next <= '0';
			end if;
		when "000000001000" =>
			-- nop
		when "000000010000" =>
			-- nop
		when "000000100000" =>
			-- nop
		when "000001000000" =>
			sdram_request_complete_next <= '0';
			if (SDRAM_READ_ENABLE = '1') then
				if (SDRAM_WIDTH_8BIT_ACCESS = '1') then
					if (SDRAM_ADDR(0) = '0') then
						ram_do_next(15 downto 0) <= ram_do(7 downto 0)&ram_do(7 downto 0);
					else
						ram_do_next(15 downto 0) <= ram_do(15 downto 8)&ram_do(15 downto 8);
					end if;
				else
					ram_do_next(15 downto 0) <= ram_do;
				end if;
			end if;
		when "000010000000" =>
			if (SDRAM_READ_ENABLE = '1') then
				if (SDRAM_WIDTH_8BIT_ACCESS = '1') then
					ram_do_next(31 downto 16) <= (others=>'0');
				else
					ram_do_next(31 downto 16) <= ram_do;
				end if;
			end if;
			if ((ram_rd_active)='1') then
				sdram_request_complete_next <= '1';
				sdram_request_next <= '0';
			end if;
		when "000100000000" =>
			-- nop
		when "001000000000" =>
			-- nop
		when "010000000000" =>
			-- nop
		when "100000000000" =>
			sdram_request_complete_next <= '0';
			-- nop
		when others =>
			-- never
		end case;
	end process;

	SDRAM_REQUEST_COMPLETE <= SDRAM_REQUEST_COMPLETE_REG;
sdram_controller : sdram_ctrl
	PORT MAP
	(
		CLK => CLK_SDRAM,
		rst => not(reset_n),
		seq_cyc => seq_reg(11 downto 0),
		seq_ph => seq_ph_reg,
		refr_cyc => ref_reg,

		ap1_ram_sel => SDRAM_REQUEST_REG,
		ap1_address => '0'&SDRAM_ADDR(22 downto 1),
		ap1_rden => SDRAM_READ_ENABLE,
		ap1_wren => SDRAM_WRITE_ENABLE,
		ap1_bena => ram_bena_reg,
		ap1_rddata => ram_do,
		ap1_wrdata => ram_di_reg,
		ap1_bst_siz => "001",
		ap1_rd_bst_act => ram_rd_active,
		ap1_wr_bst_act => ram_wr_active,

		ap2_ram_sel => '0',
		ap2_address => "00000000000000000000000",
		ap2_rden => '0',
		ap2_wren => '0',
		ap2_bena => "11",
		ap2_rddata => open,
		ap2_wrdata => X"0000",
		ap2_bst_siz => "111",
		ap2_rd_bst_act => open,
		ap2_wr_bst_act => open,

		ap3_ram_sel => '0',
		ap3_address => "00000000000000000000000",
		ap3_rden => '0',
		ap3_wren => '0',
		ap3_bena => "11",
		ap3_rddata => open,
		ap3_wrdata => X"0000",
		ap3_bst_siz => "111",
		ap3_rd_bst_act => open,
		ap3_wr_bst_act => open,

		sdram_rdy => sdram_rdy,
		sdram_cs_n => sdram_cs_n,
		sdram_ras_n => sdram_ras_n,
		sdram_cas_n => sdram_cas_n,
		sdram_we_n => sdram_we_n,
		sdram_dqm_n => sdram_dqm_n,
		sdram_ba => sdram_ba,
		sdram_addr => sdram_a(11 downto 0),
		sdram_dq_oe => sdram_dq_oe,
		sdram_dq_o => sdram_dq_o,
		sdram_dq_i => sdram_dq_i
	);

sdram_dq <= sdram_dq_o when sdram_dq_oe='1' else (others=>'Z');
sdram_dq_i <= sdram_dq;
sdram_a(12) <= '1';
		
END vhdl;
