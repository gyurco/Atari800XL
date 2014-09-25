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
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.USBF_Declares.all;

LIBRARY work;

ENTITY atari800core_mcc IS 
	GENERIC
	(
		TV : integer;  -- 1 = PAL, 0=NTSC
		internal_rom : integer;
		internal_ram : integer;
		ext_clock : integer
	);
	PORT
	(
		FPGA_CLK :  IN  STD_LOGIC; -- crystal appears to be still 5MHz despite comment in file I was sent...

		-- For test bench
		EXT_CLK_SDRAM : in std_logic_vector(ext_clock downto 1);
		EXT_CLK : in std_logic_vector(ext_clock downto 1);
		EXT_SDRAM_CLK : in std_logic_vector(ext_clock downto 1);
                EXT_SVIDEO_DAC_CLK : in std_logic_vector(ext_clock downto 1);
                EXT_PLL_LOCKED : in std_logic_vector(ext_clock downto 1);

		--PS2K_CLK :  IN  STD_LOGIC;
		--PS2K_DAT :  IN  STD_LOGIC;
		--PS2M_CLK :  IN  STD_LOGIC;
		--PS2M_DAT :  IN  STD_LOGIC;		

		-- VGA/cough cough... (composite...)
		--VGA_VS :  OUT  STD_LOGIC;
		--VGA_HS :  OUT  STD_LOGIC;
		VGA_B :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0); -- high bits composite
		VGA_G :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0); -- low bits composite
		--VGA_R :  OUT  STD_LOGIC_VECTOR(3 DOWNTO 0);
		
		--JOY1_n :  IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
		--JOY2_n :  IN  STD_LOGIC_VECTOR(5 DOWNTO 0);

		----USB CONNECTIONS (with one 1.5K pull up to 3.3v)  ---------------
		dplus1  			: inout std_logic;           --D+ data line , pin D16   
		dminus1 			: inout std_logic;           --D- data line, pin E14
		----USB CONNECTIONS (with one 1.5K pull up to 3.3v)  ---------------
		dplus2  			: inout std_logic;           --D+ data line , pin D16   
		dminus2 			: inout std_logic;           --D- data line, pin E14
		
		AUDIO_L : OUT std_logic;
		AUDIO_R : OUT std_logic;

		SDRAM_BA :  OUT  STD_LOGIC_VECTOR(1 downto 0);
		SDRAM_CS_N :  OUT  STD_LOGIC;
		SDRAM_RAS_N :  OUT  STD_LOGIC;
		SDRAM_CAS_N :  OUT  STD_LOGIC;
		SDRAM_WE_N :  OUT  STD_LOGIC;
		SDRAM_DQMH_n :  OUT  STD_LOGIC;
		SDRAM_DQML_n :  OUT  STD_LOGIC;
		SDRAM_CLK :  OUT  STD_LOGIC;
		SDRAM_CKE :  OUT  STD_LOGIC;
		SDRAM_A :  OUT  STD_LOGIC_VECTOR(12 DOWNTO 0);
		SDRAM_DQ :  INOUT  STD_LOGIC_VECTOR(15 DOWNTO 0);

		SD_DAT0 :  IN  STD_LOGIC;
		SD_CLK :  OUT  STD_LOGIC;
		SD_CMD :  OUT  STD_LOGIC;
		SD_DAT3 :  OUT  STD_LOGIC;

		-- SPI flash clock
		CFG_CLK       : OUT   STD_LOGIC;
		CFG_CS_n      : OUT   STD_LOGIC;
		CFG_DOUT      : OUT   STD_LOGIC;
		CFG_DIN       : IN    STD_LOGIC
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

	signal AUDIO_L_PCM : std_logic_vector(15 downto 0);
	signal AUDIO_R_PCM : std_logic_vector(15 downto 0);
	
	signal VIDEO_VS : std_logic;
	signal VIDEO_HS : std_logic;
	signal VIDEO_R : std_logic_vector(7 downto 0);
	signal VIDEO_G : std_logic_vector(7 downto 0);
	signal VIDEO_B : std_logic_vector(7 downto 0);

	signal VIDEO_BLANK : std_logic;
	signal VIDEO_BURST : std_logic;
	signal VIDEO_START_OF_FIELD : std_logic;
	signal VIDEO_ODD_LINE : std_logic;

	signal PAL : std_logic;
	
	signal JOY1_IN_n : std_logic_vector(4 downto 0);
	signal JOY2_IN_n : std_logic_vector(4 downto 0);

	signal PLL1_LOCKED : std_logic;
	signal CLK_PLL1 : std_logic;
	
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
	signal sdram_dqm_n_temp : std_logic_vector(1 downto 0);
	
	signal sdram_rdy : std_logic;
	signal sdram_reset_ctrl_n_next : std_logic;
	signal sdram_reset_ctrl_n_reg : std_logic;
	signal sdram_reset_n_next : std_logic;
	signal sdram_reset_n_reg : std_logic;

	-- pokey keyboard
	SIGNAL KEYBOARD_SCAN : std_logic_vector(5 downto 0);
	SIGNAL KEYBOARD_RESPONSE : std_logic_vector(1 downto 0);
	
	-- gtia consol keys
	SIGNAL CONSOL_START : std_logic;
	SIGNAL CONSOL_SELECT : std_logic;
	SIGNAL CONSOL_OPTION : std_logic;
	SIGNAL FKEYS : std_logic_vector(11 downto 0);

	-- svideo
	signal svideo_dac_clk : std_logic;

	signal svideo_y : std_logic_vector(7 downto 0);
	signal svideo_c : std_logic_vector(5 downto 0);

	-- composite
	SIGNAL svideo_yout : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL svideo_yout_dly1 : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL svideo_yout_dly2 : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL svideo_yout_dly3 : STD_LOGIC_VECTOR(7 DOWNTO 0);
	--SIGNAL svideo_cout : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL cvbs1_out : STD_LOGIC_VECTOR(9 DOWNTO 0);
	SIGNAL cvbs2_out : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL luma : STD_LOGIC_VECTOR(9 DOWNTO 0);
	SIGNAL chroma : STD_LOGIC_VECTOR(8 DOWNTO 0);
	SIGNAL luma_saturated : STD_LOGIC_VECTOR(9 DOWNTO 0);

	-- dma/virtual drive
	signal DMA_ADDR_FETCH : std_logic_vector(23 downto 0);
	signal DMA_WRITE_DATA : std_logic_vector(31 downto 0);
	signal DMA_FETCH : std_logic;
	signal DMA_32BIT_WRITE_ENABLE : std_logic;
	signal DMA_16BIT_WRITE_ENABLE : std_logic;
	signal DMA_8BIT_WRITE_ENABLE : std_logic;
	signal DMA_READ_ENABLE : std_logic;
	signal DMA_MEMORY_READY : std_logic;
	signal DMA_MEMORY_DATA : std_logic_vector(31 downto 0);

	signal ZPU_ADDR_ROM : std_logic_vector(15 downto 0);
	signal ZPU_ROM_DATA :  std_logic_vector(31 downto 0);

	signal ZPU_OUT1 : std_logic_vector(31 downto 0);
	signal ZPU_OUT2 : std_logic_vector(31 downto 0);
	signal ZPU_OUT3 : std_logic_vector(31 downto 0);
	signal ZPU_OUT4 : std_logic_vector(31 downto 0);

	signal zpu_pokey_enable : std_logic;
	signal zpu_sio_txd : std_logic;
	signal zpu_sio_rxd : std_logic;
	signal zpu_sio_command : std_logic;

	-- system control from zpu
	signal ram_select : std_logic_vector(2 downto 0);
	signal rom_select : std_logic_vector(5 downto 0);
	signal reset_atari : std_logic;
	signal pause_atari : std_logic;
	SIGNAL speed_6502 : std_logic_vector(5 downto 0);

	-- USB joystick
	SIGNAL joyright1_2  			: STD_LOGIC := '1';
	SIGNAL joyright1_4  			: STD_LOGIC := '1';
	SIGNAL joyright1_3  			: STD_LOGIC := '1';
	SIGNAL joyright1_1			: STD_LOGIC := '1';
	SIGNAL joy1_start_fire  	: STD_LOGIC := '1';
	SIGNAL joyright1_r2  		: STD_LOGIC := '1';
	SIGNAL joyright1_r1  		: STD_LOGIC := '1';
	-- joystick 1 left side
	SIGNAL joyleft1_arrow_right  	: STD_LOGIC := '1';
	SIGNAL joyleft1_arrow_left  	: STD_LOGIC := '1';
	SIGNAL joyleft1_arrow_down  	: STD_LOGIC := '1';
	SIGNAL joyleft1_arrow_up  	: STD_LOGIC := '1';
	SIGNAL joy1_select_fire  	: STD_LOGIC := '1';
	SIGNAL joyleft1_l2  		: STD_LOGIC := '1';
	SIGNAL joyleft1_l1  		: STD_LOGIC := '1';
	
	SIGNAL joyright2_2  			: STD_LOGIC := '1';
	SIGNAL joyright2_4  			: STD_LOGIC := '1';
	SIGNAL joyright2_3  			: STD_LOGIC := '1';
	SIGNAL joyright2_1			: STD_LOGIC := '1';
	SIGNAL joy2_start_fire  	: STD_LOGIC := '1';
	SIGNAL joyright2_r2  		: STD_LOGIC := '1';
	SIGNAL joyright2_r1  		: STD_LOGIC := '1';
	-- joystick 1 left side
	SIGNAL joyleft2_arrow_right  	: STD_LOGIC := '1';
	SIGNAL joyleft2_arrow_left  	: STD_LOGIC := '1';
	SIGNAL joyleft2_arrow_down  	: STD_LOGIC := '1';
	SIGNAL joyleft2_arrow_up  	: STD_LOGIC := '1';
	SIGNAL joy2_select_fire  	: STD_LOGIC := '1';
	SIGNAL joyleft2_l2  		: STD_LOGIC := '1';
	SIGNAL joyleft2_l1  		: STD_LOGIC := '1';
	
	signal joyleft1_dummy : std_logic;
	signal joyright1_dummy : std_logic;
	signal joyleft2_dummy : std_logic;
	signal joyright2_dummy : std_logic;
	
  SIGNAL reset_usbdrv  	: STD_LOGIC := '0';  
  SIGNAL cntr_reset  : STD_LOGIC_VECTOR(7 DOWNTO 0) := "11111111";

  signal usb_clk : std_logic;
  signal usb_reset_n : std_logic;

BEGIN 

-- disable flash (not used)
CFG_CLK <= 'Z';
CFG_CS_n <= '1';
CFG_DOUT <= 'Z';

-- disable usb
--dplus1 <= 'Z';
--dminus1 <= 'Z';
--dplus2 <= 'Z';
--dminus2 <= 'Z';

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

gen_fake_pll : if ext_clock=1 generate
	CLK_SDRAM <= EXT_CLK_SDRAM(1);
	CLK <= EXT_CLK(1);
	SDRAM_CLK <= EXT_CLK_SDRAM(1);
	SVIDEO_DAC_CLK <= EXT_SVIDEO_DAC_CLK(1);
	--SCANDOUBLE_CLK <= EXT_SCANDOUBLE_CLK(1);
	PLL_LOCKED <= EXT_PLL_LOCKED(1);
end generate;

gen_real_pll : if ext_clock=0 generate
	gen_tv_pal : if tv=1 generate
		mcc_pll : entity work.pal_pll
		PORT MAP(inclk0 => FPGA_CLK,
				 c0 => CLK_PLL1,
				 locked => PLL1_LOCKED);
		mcc_pll2 : entity work.pll_downstream_pal
		PORT MAP(inclk0 => CLK_PLL1,
				 c0 => CLK_SDRAM,
				 c1 => CLK,
				 c2 => SDRAM_CLK,
				 c3 => SVIDEO_DAC_CLK,
				 c4 => open, --SCANDOUBLE_CLK,      
				 areset => not(PLL1_LOCKED),
				 locked => PLL_LOCKED);
	end generate;

	gen_tv_ntsc : if tv=0 generate
		mcc_pll : entity work.ntsc_pll
		PORT MAP(inclk0 => FPGA_CLK,
				 c0 => CLK_PLL1,
				 locked => PLL1_LOCKED);
		mcc_pll2 : entity work.pll_downstream_ntsc
		PORT MAP(inclk0 => CLK_PLL1,
				 c0 => CLK_SDRAM,
				 c1 => CLK,
				 c2 => SDRAM_CLK,
				 c3 => SVIDEO_DAC_CLK,
				 c4 => open, --SCANDOUBLE_CLK,      
				 areset => not(PLL1_LOCKED),
				 locked => PLL_LOCKED);
	end generate;
end generate;

reset_n <= PLL_LOCKED;

-- Keyboard (will be USB I hope, though component does not appear to support it...)
--CONSOL_START <= '0';
--CONSOL_SELECT <= '0';
--CONSOL_OPTION <= '0';
--FKEYS <= (others=>'0');
KEYBOARD_RESPONSE <= (others=>'1');

PAL <= '1' when TV=1 else '0';

atarixl_simple_sdram1 : entity work.atari800core_simple_sdram
	GENERIC MAP
	(
		cycle_length => 16,
		internal_rom => 0, --internal_rom,
		internal_ram => 0, --internal_ram,
		video_bits => 8,
		palette => 1
	)
	PORT MAP
	(
		CLK => CLK,
		--RESET_N => RESET_N and SDRAM_RESET_N and not(SYSTEM_RESET_REQUEST),
		RESET_N => RESET_N and SDRAM_RESET_N_REG,

		VIDEO_VS => VIDEO_VS,
		VIDEO_HS => VIDEO_HS,
		VIDEO_B => VIDEO_B,
		VIDEO_G => VIDEO_G,
		VIDEO_R => VIDEO_R,
		VIDEO_BLANK =>VIDEO_BLANK,
		VIDEO_BURST =>VIDEO_BURST,
		VIDEO_START_OF_FIELD =>VIDEO_START_OF_FIELD,
		VIDEO_ODD_LINE =>VIDEO_ODD_LINE,

		AUDIO_L => AUDIO_L_PCM,
		AUDIO_R => AUDIO_R_PCM,

		JOY1_n => JOY1_IN_n,
		JOY2_n => JOY2_IN_n,

		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,
		KEYBOARD_SCAN => KEYBOARD_SCAN,

		SIO_COMMAND => zpu_sio_command,
		SIO_RXD => zpu_sio_txd,
		SIO_TXD => zpu_sio_rxd,

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
		SDRAM_REFRESH => SDRAM_REFRESH,

		DMA_FETCH => dma_fetch,
		DMA_READ_ENABLE => dma_read_enable,
		DMA_32BIT_WRITE_ENABLE => dma_32bit_write_enable,
		DMA_16BIT_WRITE_ENABLE => dma_16bit_write_enable,
		DMA_8BIT_WRITE_ENABLE => dma_8bit_write_enable,
		DMA_ADDR => dma_addr_fetch,
		DMA_WRITE_DATA => dma_write_data,
		MEMORY_READY_DMA => dma_memory_ready,
		DMA_MEMORY_DATA => dma_memory_data, 

   		RAM_SELECT => ram_select,
    		ROM_SELECT => rom_select,
		PAL => PAL,
		HALT => pause_atari,
		THROTTLE_COUNT_6502 => speed_6502
	);

	process(clk_sdram,sdram_reset_ctrl_n_reg)
	begin
		if (sdram_reset_ctrl_n_reg='0') then
			seq_reg <= "100000000000";
			seq_ph_reg <= '1';
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

	process(clk,reset_n)
	begin
		if (reset_n='0') then
			sdram_reset_n_reg <= '0';
			sdram_reset_ctrl_n_reg <= '0';
		elsif (clk'event and clk = '1') then
			sdram_reset_n_reg <= sdram_reset_n_next;
			sdram_reset_ctrl_n_reg <= reset_n;
		end if;
	end process;

	-- Generate sdram sequence
	process(seq_reg, seq_ph_reg, ref_reg)
	begin
		seq_next <= seq_reg(10 downto 0)&seq_reg(11);
		seq_ph_next <= seq_ph_reg;
		ref_next <= ref_reg;
		if (seq_reg(11) = '1') then
			seq_ph_next <= not(seq_ph_reg);
			ref_next <= not(ref_reg);
		end if;
	end process;

	process(seq_reg, seq_next, sdram_rdy, sdram_reset_n_reg, reset_atari)
	begin
		sdram_reset_n_next <= sdram_reset_n_reg;
		if (sdram_rdy = '1' and seq_next(8)='1' and seq_reg(8)='0') then
			sdram_reset_n_next <= '1';
		end if;
		if (reset_atari = '1') then
			sdram_reset_n_next <= '0';
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
					ram_di_next <= SDRAM_DI(31 downto 16);
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
			sdram_request_complete_next <= '0';
			-- nop
		when "000000100000" =>
			-- nop
		when "000001000000" =>
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
			sdram_request_complete_next <= '0';
			-- nop
		when "100000000000" =>
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
		rst => not(sdram_reset_ctrl_n_reg),
		seq_cyc => seq_reg(11 downto 0),
		seq_ph => seq_ph_reg,
		--refr_cyc => ref_reg,
		refr_cyc => SDRAM_REFRESH,

		ap1_ram_sel => SDRAM_REQUEST_NEXT,
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
		sdram_dqm_n => sdram_dqm_n_temp,
		sdram_ba => sdram_ba,
		sdram_addr => sdram_a(11 downto 0),
		sdram_dq_oe => sdram_dq_oe,
		sdram_dq_o => sdram_dq_o,
		sdram_dq_i => sdram_dq_i
	);

sdram_dqmh_n <= sdram_dqm_n_temp(1);
sdram_dqml_n <= sdram_dqm_n_temp(0);

sdram_dq <= sdram_dq_o when sdram_dq_oe='1' else (others=>'Z');
sdram_dq_i <= sdram_dq;
sdram_a(12) <= '1';
sdram_cke <= '1';

-- Video options
	-- SVIDEO COMPONENT
	svideo : entity work.svideo
	PORT MAP
	(
		areset_n => RESET_N,
		ecs_clk => CLK,
		dac_clk => SVIDEO_DAC_CLK,
		r_in => VIDEO_R,
		g_in => VIDEO_G,
		b_in => VIDEO_B,
		sof => VIDEO_VS, -- base on vsync?
		vpos_lsb => VIDEO_ODD_LINE,
		blank => VIDEO_BLANK,
		burst => VIDEO_BURST,
		csync_n => not(VIDEO_HS xor VIDEO_VS),
		
		y_out => svideo_yout,
		c_out => open,

 		luma_out => luma,
		chroma_out => chroma,
		
		pal_ntsc => not(pal)
	);

zpu: entity work.zpucore
	GENERIC MAP
	(
		platform => 1,
		spi_clock_div => 1 -- 28MHz/2. Max for SD cards is 25MHz...
	)
	PORT MAP
	(
		-- standard...
		CLK => CLK,
		RESET_N => RESET_N and sdram_rdy,

		-- dma bus master (with many waitstates...)
		ZPU_ADDR_FETCH => dma_addr_fetch,
		ZPU_DATA_OUT => dma_write_data,
		ZPU_FETCH => dma_fetch,
		ZPU_32BIT_WRITE_ENABLE => dma_32bit_write_enable,
		ZPU_16BIT_WRITE_ENABLE => dma_16bit_write_enable,
		ZPU_8BIT_WRITE_ENABLE => dma_8bit_write_enable,
		ZPU_READ_ENABLE => dma_read_enable,
		ZPU_MEMORY_READY => dma_memory_ready,
		ZPU_MEMORY_DATA => dma_memory_data, 

		-- rom bus master
		-- data on next cycle after addr
		ZPU_ADDR_ROM => zpu_addr_rom,
		ZPU_ROM_DATA => zpu_rom_data,

		-- spi master
		-- Too painful to bit bang spi from zpu, so we have a hardware master in here
		ZPU_SD_DAT0 => sd_dat0,
		ZPU_SD_CLK => sd_clk,
		ZPU_SD_CMD => sd_cmd,
		ZPU_SD_DAT3 => sd_dat3,

		-- SIO
		-- Ditto for speaking to Atari, we have a built in Pokey
		ZPU_POKEY_ENABLE => zpu_pokey_enable,
		ZPU_SIO_TXD => zpu_sio_txd,
		ZPU_SIO_RXD => zpu_sio_rxd,
		ZPU_SIO_COMMAND => zpu_sio_command,

		-- external control
		-- switches etc. sector DMA blah blah.
		ZPU_IN1 => X"00000"&FKEYS,
		ZPU_IN2 => X"00000000",
		ZPU_IN3 => X"00000000",
		ZPU_IN4 => X"00000000",

		-- ouputs - e.g. Atari system control, halt, throttle, rom select
		ZPU_OUT1 => zpu_out1,
		ZPU_OUT2 => zpu_out2,
		ZPU_OUT3 => zpu_out3,
		ZPU_OUT4 => zpu_out4
	);

	pause_atari <= zpu_out1(0);
	reset_atari <= zpu_out1(1);
	speed_6502 <= zpu_out1(7 downto 2);
	ram_select <= zpu_out1(10 downto 8);
	rom_select <= zpu_out1(16 downto 11);

zpu_rom1: entity work.zpu_rom
	port map(
	        clock => clk,
	        address => zpu_addr_rom(13 downto 2),
	        q => zpu_rom_data
	);

enable_179_clock_div_zpu_pokey : entity work.enable_divider
	generic map (COUNT=>16) -- cycle_length
	port map(clk=>clk,reset_n=>reset_n,enable_in=>'1',enable_out=>zpu_pokey_enable);

mcc_pll3 : entity work.pll_usb
	PORT MAP(inclk0 => FPGA_CLK,
		 c0 => USB_CLK,
		 locked => USB_RESET_N);

  -----------------------------------------------------------------------------------------------
  --------------------------------  reset process for USB component -----------------------------
  -----------------------------------------------------------------------------------------------
  PROCESS(usb_reset_n,usb_clk)
  BEGIN
    -- 
   IF (usb_reset_n = '0') THEN
		cntr_reset 			<= "01100111";
		reset_usbdrv 		<= '0';
   ELSIF (rising_edge(usb_clk)) THEN
		IF (cntr_reset = "00000000") THEN
			reset_usbdrv 		<= '1';				-- reset released
		ELSE
			cntr_reset 			<= cntr_reset - 1; -- 
      END IF;
   END IF;			
  END PROCESS;

  -----------------------------------------------------------------------------------------------
  ------------------------------- Main USB interface Component ----------------------------------
  -----------------------------------------------------------------------------------------------
		
-- USB 1 interface Component.
  UUSB_1 : USBF_IFC1 -- 
    port map(
      clk_usb     			=> usb_clk,        	-- 12MHz master clock input
		pll_lock					=> usb_reset_n,
      reset       			=> reset_usbdrv,            		-- XST reset push button
      ----USB CONNECTIONS               	---------
      dplus       			=> dplus1,             	--differential data
      dminus      			=> dminus1,
      ----------------------------
		joyright_out(0) 		=> joyright1_2,
		joyright_out(1) 		=> joyright1_4,
		joyright_out(2) 		=> joyright1_3,
		joyright_out(3) 		=> joyright1_1,
		joyright_out(4) 		=> joy1_start_fire,
		joyright_out(5)       => joyright1_dummy,
		joyright_out(6) 		=> joyright1_r2,
		joyright_out(7) 		=> joyright1_r1,
		-- joystick 1 left side
		joyleft_out(0) 		=> joyleft1_arrow_right,
		joyleft_out(1) 		=> joyleft1_arrow_left,
		joyleft_out(2) 		=> joyleft1_arrow_down,
		joyleft_out(3) 		=> joyleft1_arrow_up,
		joyleft_out(4) 		=> joy1_select_fire,
		joyleft_out(5)       => joyleft1_dummy,
		joyleft_out(6) 		=> joyleft1_l2,
		joyleft_out(7) 		=> joyleft1_l1,
		mousex_out				=> open,
		mousey_out				=> open
      );
		
-- USB 2 interface Component.
  UUSB_2 : USBF_IFC2 -- 
    port map(
      clk_usb     			=> usb_clk,        	-- 12MHz master clock input
		pll_lock					=> usb_reset_n,
      reset       			=> reset_usbdrv,            		-- XST reset push button
      --USB CONNECTIONS               	---------
      dplus       			=> dplus2,             	--differential data
      dminus      			=> dminus2,
      -- joystick 2 right side
		joyright_out(0) 		=> joyright2_2,
		joyright_out(1) 		=> joyright2_4,
		joyright_out(2) 		=> joyright2_3,
		joyright_out(3) 		=> joyright2_1,
		joyright_out(4) 		=> joy2_start_fire,
		joyright_out(5)       => joyright2_dummy,
		joyright_out(6) 		=> joyright2_r2,
		joyright_out(7) 		=> joyright2_r1,
		-- joystick 2 left side
		joyleft_out(0) 		=> joyleft2_arrow_right,
		joyleft_out(1) 		=> joyleft2_arrow_left,
		joyleft_out(2) 		=> joyleft2_arrow_down,
		joyleft_out(3) 		=> joyleft2_arrow_up,
		joyleft_out(4) 		=> joy2_select_fire,
		joyleft_out(5)       => joyleft2_dummy,
		joyleft_out(6) 		=> joyleft2_l2,
		joyleft_out(7) 		=> joyleft2_l1,
		mousex_out				=> open,
		mousey_out				=> open
      );
		
-- Joystick (will be USB)
--JOY1_IN_N <= (others=>'1');
--JOY2_IN_N <= (others=>'1');

	-- joystick player 1
	joy1_in_n 				<= --(joy1_start_fire AND joyright1_r2 AND joyleft1_l2) &
										--(joy1_start_fire AND joyright1_r1 AND joyleft1_l1) &
										joyright1_1 &
										joyleft1_arrow_right 	&
										joyleft1_arrow_left 	&
										joyleft1_arrow_down 	&
										joyleft1_arrow_up;
										
	-- joystick player 2
	joy2_in_n 				<= --(joy2_start_fire AND joyright2_r2 AND joyleft2_l2) &
										--(joy2_start_fire AND joyright2_r1 AND joyleft2_l1) &
										joyright2_1 &
										joyleft2_arrow_right 	&
										joyleft2_arrow_left 	&
										joyleft2_arrow_down 	&
										joyleft2_arrow_up;

CONSOL_START <= not(joy1_start_fire and joyright1_4);
CONSOL_SELECT <= not(joy1_select_fire and joyright1_3);
CONSOL_OPTION <= not(joyright1_2);
FKEYS(7 downto 0) <= (others=>'0');
FKEYS(8) <= not(joyleft1_l1);
FKEYS(9) <= not(joyleft1_l2);
FKEYS(10) <= not(joyright1_r1);
FKEYS(11) <= not(joyright1_r2);

  ---------------------------------
  -- process for CVBS output (TODO - merge this into the svideo.vhd component, as an option...)
  ---------------------------------
 -- cvbs_block:
 -- IF (SVIDEO_OUT = 2) GENERATE
  PROCESS
  (
    svideo_dac_clk,
    svideo_yout_dly1,
    svideo_yout_dly2,
	 svideo_yout_dly3
  )
  BEGIN
	IF (rising_edge(svideo_dac_clk)) THEN
		svideo_yout_dly1			<= 	svideo_yout;
		svideo_yout_dly2			<= 	svideo_yout_dly1;
		svideo_yout_dly3			<= 	svideo_yout_dly2;
		luma_saturated		    	<= 	luma - "0000011111";
		cvbs1_out  					<= 	luma_saturated + (chroma(8) & chroma(8 DOWNTO 0)) ;
		IF (svideo_yout_dly2 = "00000000") THEN
			cvbs2_out  				<=  "00000000";
		ELSE 
			cvbs2_out  				<=  cvbs1_out(9 DOWNTO 2);
		END IF;
     END IF;
  END PROCESS;

  VGA_B				<= cvbs2_out(7 DOWNTO 4); -- WHEN JOY1_n(2) = '1' ELSE svideo_yout(7 DOWNTO 4) ;
  VGA_G				<= cvbs2_out(3 DOWNTO 0); -- WHEN JOY1_n(2) = '1' ELSE svideo_yout(3 DOWNTO 0) ; 
 -- END GENERATE;

END vhdl;
