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
--USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

LIBRARY work;

ENTITY atari5200core_mcc IS 
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
END atari5200core_mcc;

ARCHITECTURE vhdl OF atari5200core_mcc IS 

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
	
	signal VIDEO_CS : std_logic;
	signal VIDEO_VS : std_logic;
	signal VIDEO_R : std_logic_vector(7 downto 0);
	signal VIDEO_G : std_logic_vector(7 downto 0);
	signal VIDEO_B : std_logic_vector(7 downto 0);

	signal VIDEO_BLANK : std_logic;
	signal VIDEO_BURST : std_logic;
	signal VIDEO_START_OF_FIELD : std_logic;
	signal VIDEO_ODD_LINE : std_logic;

	signal JOY1 : std_logic_vector(5 downto 0);
	signal JOY2 : std_logic_vector(5 downto 0);
	signal JOY1_n : std_logic_vector(4 downto 0);
	signal JOY2_n : std_logic_vector(4 downto 0);

	signal PLL1_LOCKED : std_logic;
	signal CLK_PLL1 : std_logic;
	
	signal RESET_n : std_logic;
	signal PLL_LOCKED : std_logic;
	signal CLK : std_logic;
	signal CLK_SDRAM : std_logic;

	-- SDRAM
	signal PREREG_SDRAM_REQUEST : std_logic;
	signal PREREG_SDRAM_READ_ENABLE :  STD_LOGIC;
	signal PREREG_SDRAM_WRITE_ENABLE : std_logic;
	signal PREREG_SDRAM_ADDR : STD_LOGIC_VECTOR(22 DOWNTO 0);
	SIGNAL PREREG_SDRAM_DI : std_logic_vector(31 downto 0);
	SIGNAL PREREG_SDRAM_WIDTH_32BIT_ACCESS : std_logic;
	SIGNAL PREREG_SDRAM_WIDTH_16BIT_ACCESS : std_logic;
	SIGNAL PREREG_SDRAM_WIDTH_8BIT_ACCESS : std_logic;
	signal SDRAM_REQUEST : std_logic;
	signal SDRAM_READ_ENABLE :  STD_LOGIC;
	signal SDRAM_WRITE_ENABLE : std_logic;
	signal SDRAM_ADDR : STD_LOGIC_VECTOR(22 DOWNTO 0);
	SIGNAL SDRAM_DI : std_logic_vector(31 downto 0);
	SIGNAL SDRAM_WIDTH_32BIT_ACCESS : std_logic;
	SIGNAL SDRAM_WIDTH_16BIT_ACCESS : std_logic;
	SIGNAL SDRAM_WIDTH_8BIT_ACCESS : std_logic;

	signal SDRAM_REQUEST_COMPLETE : std_logic;
	
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
	signal controller_select : std_logic_vector(1 downto 0);
	
	-- gtia consol keys
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
	signal ZPU_OUT5 : std_logic_vector(31 downto 0);

	signal zpu_pokey_enable : std_logic;
	signal zpu_sio_txd : std_logic;
	signal zpu_sio_rxd : std_logic;
	signal zpu_sio_command : std_logic;

	-- system control from zpu
	signal ram_select : std_logic_vector(2 downto 0);
	signal reset_atari : std_logic;
	signal pause_atari : std_logic;
	SIGNAL speed_6502 : std_logic_vector(5 downto 0);
	signal emulated_cartridge_select: std_logic_vector(5 downto 0);

	-- usb
	signal CLK_USB : std_logic;

	signal USBWireVPin : std_logic_vector(1 downto 0);
	signal USBWireVMin : std_logic_vector(1 downto 0);
	signal USBWireVPout : std_logic_vector(1 downto 0);
	signal USBWireVMout : std_logic_vector(1 downto 0);
	signal USBWireOE_n : std_logic_vector(1 downto 0);

	signal PS2_KEYS : STD_LOGIC_VECTOR(511 downto 0);
	signal PS2_KEYS_NEXT : STD_LOGIC_VECTOR(511 downto 0);

	-- paddles
	signal		JOY1X : std_logic_vector(7 downto 0);
	signal		JOY1Y : std_logic_vector(7 downto 0);
	signal		JOY2X : std_logic_vector(7 downto 0);
	signal		JOY2Y : std_logic_vector(7 downto 0);

BEGIN 

-- disable flash (not used)
CFG_CLK <= 'Z';
CFG_CS_n <= '1';
CFG_DOUT <= 'Z';

-- usb
--dplus1 <= USBWireVPout(0) when USBWireOE_n(0)='0' else 'Z';
--dminus1 <= USBWireVMout(0) when USBWireOE_n(0)='0' else 'Z';
--USBWireVPin(0) <= dplus1;
--USBWireVMin(0) <= dminus1;
--
--dplus2 <= USBWireVPout(1) when USBWireOE_n(1)='0' else 'Z';
--dminus2 <= USBWireVMout(1) when USBWireOE_n(1)='0' else 'Z';
--USBWireVPin(1) <= dplus2;
--USBWireVMin(1) <= dminus2;


dplus2 <= USBWireVMout(0) when USBWireOE_n(0)='0' else 'Z';
dminus2 <= USBWireVPout(0) when USBWireOE_n(0)='0' else 'Z';
USBWireVMin(0) <= dplus2;
USBWireVPin(0) <= dminus2;

dplus1 <= USBWireVMout(1) when USBWireOE_n(1)='0' else 'Z';
dminus1 <= USBWireVPout(1) when USBWireOE_n(1)='0' else 'Z';
USBWireVMin(1) <= dplus1;
USBWireVPin(1) <= dminus1;

usb_pll : entity work.usbpll
PORT MAP(inclk0 => FPGA_CLK,
	 c0 => CLK_USB,
	 locked => open);

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

-- PS2 to pokey
keyboard_map1 : entity work.ps2_to_atari5200
	GENERIC MAP
	(
		ps2_enable => 0,
		direct_enable => 1
	)
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n,
		
		INPUT => zpu_out4,

		FIRE2 => '0'&'0'&joy2(4)&joy1(4),
		CONTROLLER_SELECT => CONTROLLER_SELECT, -- selected stick keyboard/shift button
		
		KEYBOARD_SCAN => KEYBOARD_SCAN,
		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,

		FKEYS => FKEYS,
		
		PS2_KEYS_NEXT_OUT => ps2_keys_next,
		PS2_KEYS => ps2_keys
	);

JOY1 <= zpu_out2(5 downto 4)&zpu_out2(0)&zpu_out2(1)&zpu_out2(2)&zpu_out2(3);
JOY2 <= zpu_out3(5 downto 4)&zpu_out3(0)&zpu_out3(1)&zpu_out3(2)&zpu_out3(3);

JOY1X <= zpu_out5(7 downto 0);
JOY1Y <= zpu_out5(15 downto 8);
JOY2X <= zpu_out5(23 downto 16);
JOY2Y <= zpu_out5(31 downto 24);

return_to_boot_menu : entity work.delayed_reconfig
	PORT MAP
	(
		CLK_5MHZ => FPGA_CLK,
		RESET_N => RESET_N,
		RECONFIG_BUTTON => (FKEYS(1) or FKEYS(4))
	);

atari5200_simple_sdram1 : entity work.atari5200core_simplesdram
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
		VIDEO_HS => open,
		VIDEO_CS => VIDEO_CS,
		VIDEO_B => VIDEO_B,
		VIDEO_G => VIDEO_G,
		VIDEO_R => VIDEO_R,
		VIDEO_BLANK =>VIDEO_BLANK,
		VIDEO_BURST =>VIDEO_BURST,
		VIDEO_START_OF_FIELD =>VIDEO_START_OF_FIELD,
		VIDEO_ODD_LINE =>VIDEO_ODD_LINE,

		AUDIO_L => AUDIO_L_PCM,
		AUDIO_R => AUDIO_R_PCM,

		SDRAM_REQUEST => PREREG_SDRAM_REQUEST,
		SDRAM_REQUEST_COMPLETE => SDRAM_REQUEST_COMPLETE,
		SDRAM_READ_ENABLE => PREREG_SDRAM_READ_ENABLE,
		SDRAM_WRITE_ENABLE => PREREG_SDRAM_WRITE_ENABLE,
		SDRAM_ADDR => PREREG_SDRAM_ADDR,
		SDRAM_DO => ram_do_reg,
		SDRAM_DI => PREREG_SDRAM_DI,
		SDRAM_32BIT_WRITE_ENABLE => PREREG_SDRAM_WIDTH_32bit_ACCESS,
		SDRAM_16BIT_WRITE_ENABLE => PREREG_SDRAM_WIDTH_16bit_ACCESS,
		SDRAM_8BIT_WRITE_ENABLE => PREREG_SDRAM_WIDTH_8bit_ACCESS,
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

		THROTTLE_COUNT_6502 => speed_6502,
		HALT => pause_atari,

		-- JOYSTICK
		JOY1_X => signed(joy1x),
		JOY1_Y => signed(joy1y),
		JOY1_BUTTON => not(joy1(5)),
		JOY2_X => signed(joy2x),
		JOY2_Y => signed(joy2y),
		JOY2_BUTTON => not(joy2(5)),

		-- Pokey keyboard matrix
		-- Standard component available to connect this to PS2
		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,
		KEYBOARD_SCAN => KEYBOARD_SCAN,
		CONTROLLER_SELECT => CONTROLLER_SELECT
	);

	process(clk_sdram,sdram_reset_ctrl_n_reg)
	begin
		if (sdram_reset_ctrl_n_reg='0') then
			seq_reg <= "010000000000";
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
		if (sdram_rdy = '1' and seq_next(7)='1' and seq_reg(7)='0') then
			sdram_reset_n_next <= '1';
		end if;
		if (reset_atari = '1') then
			sdram_reset_n_next <= '0';
		end if;
	end process;

	-- register sdram request on the falling edge, 1/3 timing not enough, but 1/2 timing should be... This pushes back request 1 clock cycle. Result can also be clocking on the falling edge!
	process(clk,reset_n)
	begin
		if (reset_n='0') then
			SDRAM_REQUEST <= '0';
			SDRAM_READ_ENABLE <= '0';
			SDRAM_WRITE_ENABLE <= '0';
			SDRAM_ADDR <= (others=>'0');
			SDRAM_DI <= (others=>'0');
			SDRAM_WIDTH_32BIT_ACCESS <= '0';
			SDRAM_WIDTH_16BIT_ACCESS <= '0';
			SDRAM_WIDTH_8BIT_ACCESS <= '0';
		elsif(clk'event and clk='0') then -- FALLING EDGE
			SDRAM_REQUEST <= PREREG_SDRAM_REQUEST;
			SDRAM_READ_ENABLE <= PREREG_SDRAM_READ_ENABLE;
			SDRAM_WRITE_ENABLE <= PREREG_SDRAM_WRITE_ENABLE;
			SDRAM_ADDR <= PREREG_SDRAM_ADDR;
			SDRAM_DI <= PREREG_SDRAM_DI;
			SDRAM_WIDTH_32BIT_ACCESS <= PREREG_SDRAM_WIDTH_32BIT_ACCESS;
			SDRAM_WIDTH_16BIT_ACCESS <= PREREG_SDRAM_WIDTH_16BIT_ACCESS;
			SDRAM_WIDTH_8BIT_ACCESS <= PREREG_SDRAM_WIDTH_8BIT_ACCESS;
		end if;
	end process;

	-- Adapt SDRAM
	process(sdram_request_reg, sdram_request, sdram_request_complete_reg, ram_do_reg, seq_reg, ram_do, ram_rd_active, ram_wr_active, SDRAM_WIDTH_8BIT_ACCESS, SDRAM_WRITE_ENABLE, SDRAM_READ_ENABLE, SDRAM_DI, SDRAM_ADDR)
	begin
		sdram_request_next <= (sdram_request_reg or sdram_request) and not(sdram_request_complete_reg);
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
			-- nop
		when "000000100000" =>
			sdram_request_complete_next <= '0';
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
		csync_n => not(VIDEO_CS),
		
		y_out => svideo_yout,
		c_out => open,

 		luma_out => luma,
		chroma_out => chroma,
		
		pal_ntsc => not('0')
	);

zpu: entity work.zpucore
	GENERIC MAP
	(
		platform => 1,
		spi_clock_div => 1, -- 28MHz/2. Max for SD cards is 25MHz...
		memory => 8192,
		usb => 2
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
		ZPU_IN1 => X"000"&
			"00"&ps2_keys(16#76#)&ps2_keys(16#5A#)&ps2_keys(16#174#)&ps2_keys(16#16B#)&ps2_keys(16#172#)&ps2_keys(16#175#)& -- (esc)FLRDU
			FKEYS,
		ZPU_IN2 => X"00000000",
		ZPU_IN3 => X"00000000",
		ZPU_IN4 => X"00000000",

		-- ouputs - e.g. Atari system control, halt, throttle, rom select
		ZPU_OUT1 => zpu_out1, --misc
		ZPU_OUT2 => zpu_out2, --joy0
		ZPU_OUT3 => zpu_out3, --joy1
		ZPU_OUT4 => zpu_out4, --keyboard
		ZPU_OUT5 => zpu_out5, --analog stick

		-- USB host
		CLK_USB => CLK_USB,
	
		USBWireVPin => USBWireVPin,
		USBWireVMin => USBWireVMin,
		USBWireVPout => USBWireVPout,
		USBWireVMout => USBWireVMout,
		USBWireOE_n => USBWireOE_n
	);

	pause_atari <= zpu_out1(0);
	reset_atari <= zpu_out1(1);
	speed_6502 <= zpu_out1(7 downto 2);
	ram_select <= zpu_out1(10 downto 8);

zpu_rom1: entity work.zpu_rom
	port map(
	        clock => clk,
	        address => zpu_addr_rom(14 downto 2),
	        q => zpu_rom_data
	);

enable_179_clock_div_zpu_pokey : entity work.enable_divider
	generic map (COUNT=>16) -- cycle_length
	port map(clk=>clk,reset_n=>reset_n,enable_in=>'1',enable_out=>zpu_pokey_enable);

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
