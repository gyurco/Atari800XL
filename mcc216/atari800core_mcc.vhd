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
		TV : integer;  -- 1 = PAL, 0=NTSC
		VIDEO : integer; -- 1 = SVIDEO, 2 = VGA
		SCANDOUBLE : integer; -- 1 = YES, 0=NO, (+ later scanlines etc)
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

component usbHostCyc2Wrap_usb1t11
port (
  clk_i :in std_logic;
  rst_i :in std_logic;
  address_i : in std_logic_vector(7 downto 0);
  data_i : in std_logic_vector(7 downto 0);
  data_o : out std_logic_vector(7 downto 0);
  we_i :in std_logic;
  strobe_i :in std_logic;
  ack_o :out std_logic;
  irq :out std_logic;
  usbClk :in std_logic;

  USBWireVPin :in std_logic;
  USBWireVMin :in std_logic;
  USBWireVPout :out std_logic;
  USBWireVMout :out std_logic;
  USBWireOE_n :out std_logic;
  USBFullSpeed :out std_logic
);
end component;

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

	-- scandoubler
	signal scandouble_clk : std_logic;

	signal half_scandouble_enable_reg : std_logic;
	signal half_scandouble_enable_next : std_logic;

	function palette_from_scandouble( scandouble : integer ) return integer is
	begin
		if (scandouble = 1) then
			return 0;
		else
			return 1;
		end if;
	end palette_from_scandouble;
	
	-- svideo
	signal svideo_dac_clk : std_logic;

	signal svideo_y : std_logic_vector(7 downto 0);
	signal svideo_c : std_logic_vector(5 downto 0);

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
	signal emulated_cartridge_select: std_logic_vector(5 downto 0);

	-- turbo freezer!
	signal freezer_enable : std_logic;
	signal freezer_activate: std_logic;

	-- usb
	signal CLK_USB : std_logic;

	signal USBWireVPin : std_logic;
	signal USBWireVMin : std_logic;
	signal USBWireVPout : std_logic;
	signal USBWireVMout : std_logic;
	signal USBWireOE_n : std_logic;

BEGIN 

usbcon : usbHostCyc2Wrap_usb1t11
port map 
(
  clk_i => clk,
  rst_i => not(reset_n),
  address_i => (others=>'0'),
  data_i => (others=>'0'),
  data_o =>open,
  we_i => '0',
  strobe_i => '0',
  ack_o => open,
  irq => open,
  usbClk => CLK_USB,

  USBWireVPin => USBWireVPin,
  USBWireVMin => USBWireVMin,
  USBWireVPout => USBWireVPout,
  USBWireVMout => USBWireVMout,
  USBWireOE_n => USBWireOE_n,
  USBFullSpeed => open
);

USB2_P <= USBWireVPout when USBWireOE_n='0' else 'Z';
USB2_N <= USBWireVMout when USBWireOE_n='0' else 'Z';
USBWireVPin <= USB2_P;
USBWireVMin <= USB2_N;

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
	 locked => open);

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
				 c4 => SCANDOUBLE_CLK,      
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
				 c4 => SCANDOUBLE_CLK,      
				 areset => not(PLL1_LOCKED),
				 locked => PLL_LOCKED);
	end generate;
end generate;

reset_n <= PLL_LOCKED;
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
		CONSOL_OPTION => CONSOL_OPTION,
		
		FKEYS => FKEYS,
		FREEZER_ACTIVATE => freezer_activate
	);

PAL <= '1' when TV=1 else '0';

atarixl_simple_sdram1 : entity work.atari800core_simple_sdram
	GENERIC MAP
	(
		cycle_length => 16,
		internal_rom => internal_rom,
		internal_ram => internal_ram,
		video_bits => 8,
		palette => palette_from_scandouble(scandouble)
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
		THROTTLE_COUNT_6502 => speed_6502,
		emulated_cartridge_select => emulated_cartridge_select,
		freezer_enable => freezer_enable,
		freezer_activate => freezer_activate
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
	gen_scandouble_off: if scandouble=0 generate
		VGA_HS <= not(VIDEO_HS xor VIDEO_VS);
		VGA_VS <= not(VIDEO_VS);
		VGA_B <= VIDEO_B(7 downto 4);
		VGA_G <= VIDEO_G(7 downto 4);
		VGA_R <= VIDEO_R(7 downto 4);
	end generate;

	gen_scandouble_on: if scandouble=1 generate
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
			
			VGA => '1',
			COMPOSITE_ON_HSYNC => '0', -- TODO

			colour_enable => half_scandouble_enable_reg,
			doubled_enable => '1',
			
			-- GTIA interface
			pal => PAL,
			colour_in => VIDEO_B,
			vsync_in => VIDEO_VS,
			hsync_in => VIDEO_HS,
			
			-- TO TV...
			R => VGA_R,
			G => VGA_G,
			B => VGA_B,
			
			VSYNC => VGA_VS,
			HSYNC => VGA_HS
		);
	end generate;

end generate;

gen_video_svideo: if video=1 generate

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
		
		y_out => svideo_y,
		c_out => svideo_c,
		
		pal_ntsc => not(pal)
	);
	VGA_B <= svideo_y(7 downto 4);
	VGA_G <= svideo_y(3 downto 0);
	VGA_R <= svideo_c(5 downto 2);
	VGA_HS <= svideo_c(1);
	VGA_VS <= svideo_c(0);

end generate;

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
	emulated_cartridge_select <= zpu_out1(22 downto 17);
	freezer_enable <= zpu_out1(25);

zpu_rom1: entity work.zpu_rom
	port map(
	        clock => clk,
	        address => zpu_addr_rom(13 downto 2),
	        q => zpu_rom_data
	);

enable_179_clock_div_zpu_pokey : entity work.enable_divider
	generic map (COUNT=>16) -- cycle_length
	port map(clk=>clk,reset_n=>reset_n,enable_in=>'1',enable_out=>zpu_pokey_enable);

END vhdl;
