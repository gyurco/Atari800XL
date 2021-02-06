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
	GENERIC
	(
		VIDEO : integer; -- 1 = SVIDEO, 2 = VGA
		internal_rom : integer;
		internal_ram : integer;
		ext_clock : integer
	);
	PORT
	(
		FPGA_CLK :  IN  STD_LOGIC;

		-- For test bench
		EXT_CLK_SDRAM : in std_logic_vector(ext_clock downto 1);
		EXT_CLK : in std_logic_vector(ext_clock downto 1);
		EXT_SDRAM_CLK : in std_logic_vector(ext_clock downto 1);
                EXT_SVIDEO_DAC_CLK : in std_logic_vector(ext_clock downto 1);
                EXT_SCANDOUBLE_CLK : in std_logic_vector(ext_clock downto 1);
                EXT_PLL_LOCKED : in std_logic_vector(ext_clock downto 1);

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
		SD_DAT3 :  OUT  STD_LOGIC;

		USB2_P :  INOUT  STD_LOGIC;
		USB2_N :  INOUT  STD_LOGIC
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
  Ap2_bena : in std_logic_vector(1 downto 0);
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
	signal VIDEO_CS : std_logic;
	signal ATARI_COLOUR : std_logic_vector(7 downto 0);

	signal VIDEO_BLANK : std_logic;
	signal VIDEO_BURST : std_logic;
	signal VIDEO_START_OF_FIELD : std_logic;
	signal VIDEO_ODD_LINE : std_logic;

	signal JOY1_IN_n : std_logic_vector(4 downto 0);
	signal JOY2_IN_n : std_logic_vector(4 downto 0);

	signal JOY1_USB : std_logic_vector(5 downto 0);
	signal JOY2_USB : std_logic_vector(5 downto 0);
	signal JOY1_USB_n : std_logic_vector(4 downto 0);
	signal JOY2_USB_n : std_logic_vector(4 downto 0);

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
	
	signal sdram_rdy : std_logic;
	signal sdram_reset_ctrl_n_next : std_logic;
	signal sdram_reset_ctrl_n_reg : std_logic;
	signal sdram_reset_n_next : std_logic;
	signal sdram_reset_n_reg : std_logic;

	-- pokey keyboard
	SIGNAL KEYBOARD_SCAN : std_logic_vector(5 downto 0);
	SIGNAL KEYBOARD_RESPONSE : std_logic_vector(1 downto 0);
	signal atari_keyboard : std_logic_vector(63 downto 0);
	
	-- gtia consol keys
	SIGNAL CONSOL_START : std_logic;
	SIGNAL CONSOL_SELECT : std_logic;
	SIGNAL CONSOL_OPTION : std_logic;
	SIGNAL FKEYS : std_logic_vector(11 downto 0);

	-- scandoubler
	signal scandouble_clk : std_logic;

	signal half_scandouble_enable_reg : std_logic;
	signal half_scandouble_enable_next : std_logic;

	-- svideo
	signal svideo_dac_clk : std_logic;

	signal chroma : std_logic_vector(7 downto 0);
	signal luma : std_logic_vector(7 downto 0);
	signal luma_sync_n : std_logic;

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
	signal ZPU_OUT6 : std_logic_vector(31 downto 0);

	signal zpu_pokey_enable : std_logic;
	signal zpu_sio_txd : std_logic;
	signal zpu_sio_rxd : std_logic;
	signal zpu_sio_command : std_logic;
	SIGNAL ASIO_CLOCKOUT : std_logic;

	-- system control from zpu
	signal ram_select : std_logic_vector(2 downto 0);
	signal reset_atari : std_logic;
	signal pause_atari : std_logic;
	SIGNAL speed_6502 : std_logic_vector(5 downto 0);
	signal turbo_vblank_only : std_logic;
	signal emulated_cartridge_select: std_logic_vector(5 downto 0);
	signal key_type : std_logic;
	signal atari800mode : std_logic;

	-- turbo freezer!
	signal freezer_enable : std_logic;
	signal freezer_activate: std_logic;

	-- usb
	signal CLK_USB : std_logic;
	signal USB_PLL_LOCKED : std_logic;

	signal USBWireVPin : std_logic;
	signal USBWireVMin : std_logic;
	signal USBWireVPout : std_logic;
	signal USBWireVMout : std_logic;
	signal USBWireOE_n : std_logic;

	signal PS2_KEYS : STD_LOGIC_VECTOR(511 downto 0);
	signal PS2_KEYS_NEXT : STD_LOGIC_VECTOR(511 downto 0);

	-- paddles
	signal paddle_mode_next : std_logic;
	signal paddle_mode_reg : std_logic;
	signal		JOY1X : std_logic_vector(7 downto 0);
	signal		JOY1Y : std_logic_vector(7 downto 0);
	signal		JOY2X : std_logic_vector(7 downto 0);
	signal		JOY2Y : std_logic_vector(7 downto 0);

	-- video settings
	signal pal : std_logic;
	signal scandouble : std_logic;
	signal scanlines : std_logic;
	signal csync : std_logic;
	signal video_mode : std_logic_vector(2 downto 0);

	-- pll switch
	signal pll_reconfig_done : std_logic;

BEGIN 

USB2_N <= USBWireVPout when USBWireOE_n='0' else 'Z';
USB2_P <= USBWireVMout when USBWireOE_n='0' else 'Z';
USBWireVPin <= USB2_N;
USBWireVMin <= USB2_P;

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
	SCANDOUBLE_CLK <= EXT_SCANDOUBLE_CLK(1);
	PLL_LOCKED <= EXT_PLL_LOCKED(1);
end generate;

usb_pll : entity work.usbpll
PORT MAP(inclk0 => FPGA_CLK,
	 c0 => CLK_USB,
	 locked => USB_PLL_LOCKED);

gen_real_pll : if ext_clock=0 generate

	pll_switcher : work.switch_pal_ntsc
	    GENERIC MAP
	    (
	        CLOCKS => 5,
		SYNC_ON => 1
	    )
	    PORT MAP
	    (
	        RECONFIG_CLK => CLK_USB,
	        RESET_N => USB_PLL_LOCKED,
	
	        PAL => PAL,
	
	        INPUT_CLK => FPGA_CLK,
	        PLL_CLKS(0) => CLK_SDRAM,
	        PLL_CLKS(1) => CLK,
	        PLL_CLKS(2) => SDRAM_CLK,
		PLL_CLKS(3) => open,
	        PLL_CLKS(4) => SCANDOUBLE_CLK,
	
		RESET_N_OUT => RESET_N,
		PLL_RECONFIG_DONE => PLL_RECONFIG_DONE
	    );
	    SVIDEO_DAC_CLK <= SCANDOUBLE_CLK;
end generate;

JOY1_IN_N <= JOY1_n(4)&JOY1_n(0)&JOY1_n(1)&JOY1_n(2)&JOY1_n(3);
JOY2_IN_N <= JOY2_n(4)&JOY2_n(0)&JOY2_n(1)&JOY2_n(2)&JOY2_n(3);


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
	GENERIC MAP
	(
		ps2_enable => 1,
		direct_enable => 1
	)
	PORT MAP
	( 
		CLK => clk,
		RESET_N => reset_n and not(PLL_RECONFIG_DONE),
		PS2_CLK => ps2k_clk,
		PS2_DAT => ps2k_dat,

		INPUT => zpu_out4,

 		ATARI_KEYBOARD_OUT => atari_keyboard,

		KEY_TYPE => key_type,
		
		KEYBOARD_SCAN => KEYBOARD_SCAN,
		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,

		CONSOL_START => CONSOL_START,
		CONSOL_SELECT => CONSOL_SELECT,
		CONSOL_OPTION => CONSOL_OPTION,
		
		FKEYS => FKEYS,
		FREEZER_ACTIVATE => freezer_activate,

		PS2_KEYS_NEXT_OUT => ps2_keys_next,
		PS2_KEYS => ps2_keys
	);

-- hack for paddles
	process(clk,RESET_N)
	begin
		if (RESET_N = '0') then
			paddle_mode_reg <= '0';
		elsif (clk'event and clk='1') then
			paddle_mode_reg <= paddle_mode_next;
		end if;
	end process;

JOY1_USB <= zpu_out2(5 downto 4)&zpu_out2(0)&zpu_out2(1)&zpu_out2(2)&zpu_out2(3);
JOY2_USB <= zpu_out3(5 downto 4)&zpu_out3(0)&zpu_out3(1)&zpu_out3(2)&zpu_out3(3);

JOY1X <= zpu_out5(7 downto 0);
JOY1Y <= zpu_out5(15 downto 8);
JOY2X <= zpu_out5(23 downto 16);
JOY2Y <= zpu_out5(31 downto 24);

	process(paddle_mode_reg, joy1_usb, joy2_usb)
	begin
		joy1_usb_n <= (others=>'1');
		joy2_usb_n <= (others=>'1');

		if (paddle_mode_reg = '1') then
			joy1_usb_n <= "111"&not(joy1_usb(4)&joy1_usb(5)); --FLRDU
			joy2_usb_n <= "111"&not(joy2_usb(4)&joy2_usb(5));
		else
			joy1_usb_n <= not(joy1_usb(4 downto 0));
			joy2_usb_n <= not(joy2_usb(4 downto 0));
		end if;
	end process;

	paddle_mode_next <= paddle_mode_reg xor (not(ps2_keys(16#11F#)) and ps2_keys_next(16#11F#)); -- left windows key

return_to_boot_menu : entity work.delayed_reconfig
	PORT MAP
	(
		CLK_5MHZ => FPGA_CLK,
		RESET_N => RESET_N,
		RECONFIG_BUTTON => FKEYS(6)
	);

atarixl_simple_sdram1 : entity work.atari800core_simple_sdram
	GENERIC MAP
	(
		cycle_length => 16,
		internal_rom => internal_rom,
		internal_ram => internal_ram,
		video_bits => 8,
		palette => 0
	)
	PORT MAP
	(
		CLK => CLK,
		--RESET_N => RESET_N and SDRAM_RESET_N and not(SYSTEM_RESET_REQUEST),
		RESET_N => RESET_N and SDRAM_RESET_N_REG,

		VIDEO_VS => VIDEO_VS,
		VIDEO_HS => VIDEO_HS,
		VIDEO_CS => VIDEO_CS,
		VIDEO_B => ATARI_COLOUR,
		VIDEO_G => open,
		VIDEO_R => open,
		VIDEO_BLANK =>VIDEO_BLANK,
		VIDEO_BURST =>VIDEO_BURST,
		VIDEO_START_OF_FIELD =>VIDEO_START_OF_FIELD,
		VIDEO_ODD_LINE =>VIDEO_ODD_LINE,

		AUDIO_L => AUDIO_L_PCM,
		AUDIO_R => AUDIO_R_PCM,

		JOY1_n => JOY1_IN_n and JOY1_USB_n,
		JOY2_n => JOY2_IN_n and JOY2_USB_n,

		PADDLE0 => signed(joy1x),
		PADDLE1 => signed(joy1y),
		PADDLE2 => signed(joy2x),
		PADDLE3 => signed(joy2y),


		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,
		KEYBOARD_SCAN => KEYBOARD_SCAN,

		SIO_COMMAND => zpu_sio_command,
		SIO_RXD => zpu_sio_txd,
		SIO_TXD => zpu_sio_rxd,
		SIO_CLOCKOUT => ASIO_CLOCKOUT,

		CONSOL_OPTION => CONSOL_OPTION,
		CONSOL_SELECT => CONSOL_SELECT,
		CONSOL_START => CONSOL_START,

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

   		RAM_SELECT => ram_select,
		PAL => PAL,
		HALT => pause_atari,
		ATARI800MODE => atari800mode,
		THROTTLE_COUNT_6502 => speed_6502,
		TURBO_VBLANK_ONLY => turbo_vblank_only,
		emulated_cartridge_select => emulated_cartridge_select,
		freezer_enable => freezer_enable,
		freezer_activate => freezer_activate
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

-- Video options
gen_video_vga : if video=2 generate
	process(scandouble_clk,sdram_reset_n_reg)
	begin
		if (sdram_reset_n_reg='0') then
			half_scandouble_enable_reg <= '0';
		elsif (scandouble_clk'event and scandouble_clk='1') then
			half_scandouble_enable_reg <= half_scandouble_enable_next;
		end if;
	end process;

	half_scandouble_enable_next <= not(half_scandouble_enable_reg);

	scandoubler1: entity work.scandoubler
	PORT MAP
	( 
		CLK => SCANDOUBLE_CLK,
	        RESET_N => sdram_reset_n_reg,
		
		VGA => scandouble,
		COMPOSITE_ON_HSYNC => csync,

		colour_enable => half_scandouble_enable_reg,
		doubled_enable => '1',
		scanlines_on => scanlines,
		
		-- GTIA interface
		pal => PAL,
		colour_in => ATARI_COLOUR,
		vsync_in => VIDEO_VS,
		hsync_in => VIDEO_HS,
		csync_in => VIDEO_CS,
		
		-- TO TV...
		R => VGA_R,
		G => VGA_G,
		B => VGA_B,
		
		VSYNC => VGA_VS,
		HSYNC => VGA_HS
	);

end generate;

gen_video_svideo: if video=1 generate

	svideo : entity work.svideo_gtia
	PORT MAP
	( 
		CLK => SVIDEO_DAC_CLK, -- 56.75MHz PAL, 57.272727... NTSC
		RESET_N => RESET_N,
	
		brightness => ATARI_COLOUR(3 downto 0),
		hue => ATARI_COLOUR(7 downto 4),
		burst => VIDEO_BURST,
		blank => VIDEO_BLANK,
		sof => VIDEO_VS,
		csync_n => not(VIDEO_CS),
		vpos_lsb => VIDEO_ODD_LINE,
		pal => PAL,
	
		composite => '1',
		
		chroma => chroma,
		luma => luma,
		luma_sync_n => luma_sync_n -- TODO, need to adjust svideo_gtia to work without this!
	);
	
	process(luma, luma_sync_n)
	begin
	  if (luma_sync_n='0') then
	    VGA_B <= (others=>'0');
	    VGA_G <= (others=>'0');
	  else
	    VGA_B <= luma(7 downto 4);
	    VGA_G <= luma(3 downto 0);
	  end if;
	end process;

	VGA_R <= chroma(7 downto 4);
	VGA_HS <= chroma(3);
	VGA_VS <= chroma(2);

end generate;

zpu: entity work.zpucore
	GENERIC MAP
	(
		platform => 1,
		spi_clock_div => 1, -- 28MHz/2. Max for SD cards is 25MHz...
		memory => 8192,
		usb => 1,
		nMHz_clock_div => 48
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
		ZPU_SPI_DI => sd_dat0,
		ZPU_SPI_CLK => sd_clk,
		ZPU_SPI_DO => sd_cmd,
		ZPU_SPI_SELECT0 => sd_dat3,
		ZPU_SPI_SELECT1 => open,

		-- SIO
		-- Ditto for speaking to Atari, we have a built in Pokey
		ZPU_POKEY_ENABLE => zpu_pokey_enable,
		ZPU_SIO_TXD => zpu_sio_txd,
		ZPU_SIO_RXD => zpu_sio_rxd,
		ZPU_SIO_COMMAND => zpu_sio_command,
		ZPU_SIO_CLK => ASIO_CLOCKOUT,

		-- external control
		-- switches etc. sector DMA blah blah.
		ZPU_IN1 => X"000"&
			"00"&
			(atari_keyboard(28))&ps2_keys(16#5A#)&ps2_keys(16#174#)&ps2_keys(16#16B#)&ps2_keys(16#172#)&ps2_keys(16#175#)& -- (esc)FLRDU
			FKEYS,
		ZPU_IN2 => X"00000000",
		ZPU_IN3 => atari_keyboard(31 downto 0),
		ZPU_IN4 => atari_keyboard(63 downto 32),

		-- ouputs - e.g. Atari system control, halt, throttle, rom select
		ZPU_OUT1 => zpu_out1,
		ZPU_OUT2 => zpu_out2, --joy0
		ZPU_OUT3 => zpu_out3, --joy1
		ZPU_OUT4 => zpu_out4, --keyboard
		ZPU_OUT5 => zpu_out5, --analog stick
		ZPU_OUT6 => zpu_out6, --video mode

		-- USB host
		CLK_nMHz => CLK_USB,
		CLK_USB => CLK_USB,
	
		USBWireVPin(0) => USBWireVPin,
		USBWireVMin(0) => USBWireVMin,
		USBWireVPout(0) => USBWireVPout,
		USBWireVMout(0) => USBWireVMout,
		USBWireOE_n(0) => USBWireOE_n
	);

	pause_atari <= zpu_out1(0);
	reset_atari <= zpu_out1(1);
	speed_6502 <= zpu_out1(7 downto 2);
	ram_select <= zpu_out1(10 downto 8);
	atari800mode <= zpu_out1(11);
	emulated_cartridge_select <= zpu_out1(22 downto 17);
	freezer_enable <= zpu_out1(25);
	key_type <= zpu_out1(26);

	turbo_vblank_only <= zpu_out1(31);

	video_mode <= zpu_out6(2 downto 0);
	PAL <= zpu_out6(4);
	scanlines <= zpu_out6(5);
	csync <= zpu_out6(6);

process(video_mode)
begin
	SCANDOUBLE <= '0';

	-- original RGB
	-- scandoubled RGB (works on some vga devices...)
	-- svideo
	-- hdmi with audio  (and vga exact mode...)
	-- dvi (i.e. no preamble or audio) (and vga exact mode...)
	-- vga exact mode (hdmi off)
	-- composite (todo firmware...)

	case video_mode is
		when "000" =>
		when "001" =>
			SCANDOUBLE <= '1';
		when "010" => -- svideo
			      -- not supported -- TODO: need to provide a bitmask to firmware on what modes we support I think? Then can handle this in a better way!
		when "011" =>
			-- not supported
		when "100" =>
			-- not supported
		when "101" =>
			-- not supported
		when "110" => -- composite
			-- not supported

		when others =>
	end case;
end process;

	zpu_rom1: entity work.zpu_rom
	port map(
	        clock => clk,
	        address => zpu_addr_rom(15 downto 2),
	        q => zpu_rom_data
	);

enable_179_clock_div_zpu_pokey : entity work.enable_divider
	generic map (COUNT=>16) -- cycle_length
	port map(clk=>clk,reset_n=>reset_n,enable_in=>'1',enable_out=>zpu_pokey_enable);

END vhdl;
