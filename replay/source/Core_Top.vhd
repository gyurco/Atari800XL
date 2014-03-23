-- WWW.FPGAArcade.COM
-- REPLAY 1.0
-- Retro Gaming Platform
-- No Emulation No Compromise
--
-- All rights reserved
-- Mike Johnson 2008/2009
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- You are responsible for any legal issues arising from your use of this code.
--
-- The latest version of this file can be found at: www.FPGAArcade.com
--
-- Email support@fpgaarcade.com
--
-- ===================================================================
--
-- This file was modified to embed Mikes VIC-20 core by W. Scherr
-- Email ws_arcade <at> pin4.at
--
-- $Id: Core_Top.vhd 357 2014-02-22 20:32:21Z wolfgang.scherr $
--
-- Latest version can be found at: www.pin4.at
--
-- ===================================================================

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

  use work.Replay_Pack.all;
  use work.Replay_VideoTiming_Pack.all;
  use work.Replay_TranslatePS2_Pack.all;

library UNISIM;
  use UNISIM.Vcomponents.all;

entity Core_Top is
  port (
    i_Clk_Vid             : in    bit1; -- ~27 MHz
    i_Ena_Vid             : in    bit1;
    i_Rst_Vid             : in    bit1;
    --
    i_ClK_Sys             : in    bit1; -- 106.4 / 4 --> 26.62 MHz
    i_Ena_Sys             : in    bit1; -- 26.62 / 3 --> 8.875 MHz
    i_Ena_Sub4            : in    bit1; -- 26.62 / 6  --> 4.43 MHz
    i_Ena_Sub1            : in    bit1; -- 26.62 / 24 --> 1.11 MHz
    i_Rst_Sys             : in    bit1;
    --
    i_Joy_A               : in    word( 5 downto 0); -- lower port
    i_Joy_B               : in    word( 5 downto 0); -- upper port
    --
    i_Ms_We               : in    bit1;
    i_Ms_PosX             : in    word(11 downto 0);
    i_Ms_PosY             : in    word(11 downto 0);
    i_Ms_Butn             : in    word( 2 downto 0);
    --
    i_Kb_osd_inhibit      : in    bit1;
    i_Kb_ps2_we           : in    bit1;
    i_Kb_ps2              : in    word( 7 downto 0);
    o_kb_led              : out   word( 2 downto 0);
    --
    core_ps2_data         : in bit1;
    core_ps2_clk          : in bit1;
    --
    i_Rst_Core            : in    bit1;
    i_Halt_Core           : in    bit1;
    i_HD_Mode             : in    bit1; -- selects between the HD and SD video mode generic
    o_act_led_n           : out   bit1;
    --
    i_Audio_lvl           : in    word(1 downto 0);
    --
    o_Audio_l             : out   word(23 downto 0);
    o_Audio_R             : out   word(23 downto 0);
    i_Audio_Taken         : in    bit1;
    -- config stuff
    I_CART_RO             : in    bit1; -- high means read-only for VIC-20 (write only via low-prio IF fram ARM)
    I_CART_EN             : in    bit1; -- at $A000(8k)
    I_RAM_EXT             : in    word(3 downto 0); -- at $6000(8k),$4000(8k),$2000(8k),$0400(3k)
    drive_address         : in    word(1 downto 0); -- 0/1/2/3 means drive address 8/9/10/11
    --
    o_Vid_RGB             : out   word(23 downto 0);
    o_Vid_Sync            : out   r_Vidsync;
    -- media access (directly mapped d64 file format)
    diskid_i              : in  std_logic_vector(15 downto 0);
    media_adr_o           : out   unsigned(17 downto 0);
    media_read_o          : out   bit1;
    media_dat_i           : in    word(7 downto 0);
    floppy_inserted       : in    bit1;
    write_prot_n          : in    bit1;
    -- sideband info
    o_Vid_Timing          : out   r_Vidtiming;
    o_Vid_Std             : out   r_Vidstd;
    -- to DRAM controller
    hp_ddr_valid          : out std_logic;
    hp_ddr_taken          : in std_logic;
    hp_ddr_addr           : out std_logic_vector(25 downto 2);
    hp_wl                 : out std_logic;
    hp_wbe                : out   std_logic_vector(3 downto 0);
    hp_wdata              : out std_logic_vector(31 downto 0);
    hp_rdata              : in std_logic_vector(31 downto 0);
    hp_ddr_wr             : in std_logic;

    -- RS232 debug port
    i_RS232_RXD           : in    bit1;
    o_RS232_TXD           : out   bit1;
    i_RS232_CTS           : in    bit1;
    o_RS232_RTS           : out   bit1;

    -- debug port for ext. DLA (4 channels with 9 bit) 
    debug                 : out   word(9*4-1 downto 0);
    debugi                : in    word(2 downto 0);
    -- setup bus (write only)
    CONF_WR               : in    bit1;
    CONF_WR_1541          : in    bit1;
    CONF_WR_KEY           : in    bit1;
    CONF_AI               : in    word(15 downto 0);
    CONF_DI               : in    word(7 downto 0);

    ram_select            : in word(2 downto 0);
    rom_select            : in word(5 downto 0)
    );
end;

architecture RTL of Core_Top is

  -- selects core related debugging signals for internal debug
  constant int_dla_core_debug : boolean := false;

  signal PLL_LOCKED : std_logic;

  signal res_s                     : bit1;
  signal core_en_s                 : bit1;

  signal atn_i                     : bit1;
  signal clk_i                     : bit1;
  signal data_i                    : bit1;

  signal fatn_o                    : bit1;
  signal fclk_o                    : bit1;
  signal fdata_o                   : bit1;
  signal catn_o                    : bit1;
  signal cclk_o                    : bit1;
  signal cdata_o                   : bit1;

  signal lsound_s                   : std_logic_vector(15 downto 0);
  signal rsound_s                   : std_logic_vector(15 downto 0);
  signal lsample_s                  : word(23 downto 0);
  signal rsample_s                  : word(23 downto 0);

  signal core_blankn_s             : bit1;
  signal core_blankn_ds            : bit1;
  signal core_hsyncn_s             : bit1;
  signal core_vsyncn_s             : bit1;
  signal core_hsync                : bit1;
  signal core_vsync                : bit1;
  signal core_blank                : bit1;
  signal core_r_s                  : std_logic_vector(7 downto 0);
  signal core_g_s                  : std_logic_vector(7 downto 0);
  signal core_b_s                  : std_logic_vector(7 downto 0);

  signal matrix_in                 : word(7 downto 0);
  signal matrix_out                : word(15 downto 0);
  signal matrix_out_mix            : word(7 downto 0);
  signal static_keys               : word(6 downto 0);
  signal pause_key                 : bit1;
  signal sh_lock_key               : bit1;
  signal stat6_del                 : bit1;

  signal joy_mix                   : word(4 downto 0);

  signal SDRAM_REQUEST : std_logic;
  signal SDRAM_REQUEST_COMPLETE : std_logic;
  signal SDRAM_READ_ENABLE :  STD_LOGIC;
  signal SDRAM_WRITE_ENABLE : std_logic;
  signal SDRAM_ADDR : STD_LOGIC_VECTOR(22 DOWNTO 0);
  signal SDRAM_DO : STD_LOGIC_VECTOR(31 DOWNTO 0);
  signal SDRAM_DI : STD_LOGIC_VECTOR(31 DOWNTO 0);
  signal SDRAM_WIDTH_8bit_ACCESS : std_logic;
  signal SDRAM_WIDTH_16bit_ACCESS : std_logic;
  signal SDRAM_WIDTH_32bit_ACCESS : std_logic;

  signal ddr_response_pending_next : std_logic;
  signal ddr_response_pending_reg : std_logic;

  signal ddr_request_pending_next : std_logic;
  signal ddr_request_pending_reg : std_logic;

  signal core_blank_count_next : std_logic_vector(23 downto 0);
  signal core_blank_count_reg : std_logic_vector(23 downto 0);

begin
  -- core control
  res_s <= i_Rst_Core;
  core_en_s <= i_Ena_Sys and not i_Halt_Core and not pause_key;

PLL_LOCKED <= not(i_rst_sys or i_Rst_Core);
atari800core : entity work.atari800core
	PORT map
	(
		CLK => i_clk_sys,
		PLL_LOCKED => PLL_LOCKED,

		VGA_VS => core_vsync,
		VGA_HS => core_hsync,
		VGA_B => core_b_s,
		VGA_G => core_g_s,
		VGA_R => core_r_s,

		matrix_out => matrix_out,
		matrix_in => matrix_in,
		static_keys => static_keys,
		pause_key => pause_key,

		JOY1_n => i_Joy_A,
		JOY2_n => i_Joy_B,
		
		AUDIO_L => lsound_s,
		AUDIO_R => rsound_s,

		SDRAM_REQUEST => SDRAM_REQUEST,
		SDRAM_REQUEST_COMPLETE => SDRAM_REQUEST_COMPLETE,
		SDRAM_READ_ENABLE => SDRAM_READ_ENABLE,
		SDRAM_WRITE_ENABLE => SDRAM_WRITE_ENABLE,
		SDRAM_ADDR => SDRAM_ADDR,
		SDRAM_DO => SDRAM_DO,
		SDRAM_DI => SDRAM_DI,
		SDRAM_WIDTH_8bit_ACCESS => SDRAM_WIDTH_8bit_ACCESS,
		SDRAM_WIDTH_16bit_ACCESS => SDRAM_WIDTH_16bit_ACCESS,
		SDRAM_WIDTH_32bit_ACCESS => SDRAM_WIDTH_32bit_ACCESS,

		SIO_RXD => i_RS232_RXD,
		SIO_TXD => o_RS232_TXD,
		SIO_COMMAND_TX => o_RS232_RTS,

		ram_select => ram_select,
		rom_select => rom_select,

		halt => i_Halt_Core
	);

  ----------------------------------------------------------
  -- KEYBOARD MAPPER
  ----------------------------------------------------------

  u_Kbd : entity work.Replay_TranslatePS2
  generic map (
    g_kb_map              => c_vic20_kb_map -- TODO make atari version rather than putting it all in the ini file!
  )
  port map (
    i_ClK_Sys               => i_ClK_Sys,
    i_ena_sys             => core_en_s,
    i_rst_sys             => res_s,
    i_kb_osd_inhibit      => i_kb_osd_inhibit,
    i_kb_ps2_we           => i_kb_ps2_we,
    i_kb_ps2              => i_kb_ps2,
    i_matrix_in           => matrix_in,
    o_matrix_out          => matrix_out,
    o_static_keys         => static_keys,
    o_pause_key           => pause_key,
    i_conf_wr             => CONF_WR_KEY,
    i_conf_adr            => CONF_AI(8 downto 0),
    i_conf_dat            => CONF_DI
  );

  -- mix joystick / keyboard (num-pad)
  joy_mix <= i_Joy_A(4 downto 0) and not( static_keys(4 downto 0) );

  -- handling shift-lock key (on/off switch on CBM keyboard)
  shiftlock : process (i_ClK_Sys, i_Rst_Sys) is
  begin
    if i_Rst_Sys='1' then
      sh_lock_key <= '0';
    elsif rising_edge(i_ClK_Sys) then
      stat6_del <= static_keys(6);
      if static_keys(6)='1' and stat6_del='0' then
        -- shift-lock pressed, toggle it
        sh_lock_key <= not sh_lock_key;
      end if;
    end if;
  end process shiftlock;
  o_kb_led(0) <= pause_key;     -- SCROLL LOCK LED
  o_kb_led(1) <= '0';           -- NUM LOCK LED (take care, enables overlayed NUM keys on compact keyboards as well!)
  o_kb_led(2) <= sh_lock_key;   -- CAPS LOCK LED

  -- mix keyboard matrix with shift-lock key
  matrix_out_mix <= matrix_out(7 downto 0) OR X"02" when sh_lock_key='1' and matrix_in=X"08" else
                    matrix_out(7 downto 0);

  ----------------------------------------------------------
  -- AUDIO
  ----------------------------------------------------------

  -- we have some simple gain setup (a little logarithmic) as well before passing to replay
  lsample_s <= lsound_s(15) & lsound_s & "0000000" when i_Audio_lvl="11" else
              lsound_s(15) & lsound_s(15) & lsound_s & "000000" when i_Audio_lvl="10" else
              lsound_s(15) & lsound_s(15) & lsound_s(15) & lsound_s(15) & lsound_s & "0000" when i_Audio_lvl="01" else
              lsound_s(15) & lsound_s(15) & lsound_s(15) & lsound_s(15) & lsound_s(15) & lsound_s(15) & lsound_s(15) & lsound_s & "0";

  rsample_s <= rsound_s(15) & rsound_s & "0000000" when i_Audio_lvl="11" else
              rsound_s(15) & rsound_s(15) & rsound_s & "000000" when i_Audio_lvl="10" else
              rsound_s(15) & rsound_s(15) & rsound_s(15) & rsound_s(15) & rsound_s & "0000" when i_Audio_lvl="01" else
              rsound_s(15) & rsound_s(15) & rsound_s(15) & rsound_s(15) & rsound_s(15) & rsound_s(15) & rsound_s(15) & rsound_s & "0";
  o_Audio_l <= lsample_s;
  o_Audio_R <= rsample_s;

  ----------------------------------------------------------
  -- VIDEO CONVERTER
  ----------------------------------------------------------

  process(i_ena_sys, core_hsync, core_blank_count_reg)
  begin
    core_blank_count_next <= core_blank_count_reg;
    core_blankn_s <= '1';

    if (i_ena_sys = '1') then
      core_blank_count_next <= std_logic_vector(unsigned(core_blank_count_reg)+1);
    end if;

    if (core_hsync = '1') then
      core_blank_count_next <= (others=>'0');
    end if;

    if (core_blank_count_reg < X"33") then
      core_blankn_s <= '0';
    end if;

  end process;

  process(i_Clk_sys,i_rst_sys)
  begin
  	if (i_rst_sys = '1') then
  		core_blank_count_reg <= (others=>'0');
  	elsif (i_clk_sys'event and i_clk_sys='1') then
  		core_blank_count_reg <= core_blank_count_next;
  	end if;
  end process;

  core_hsyncn_s <= not(core_hsync);
  core_vsyncn_s <= not(core_vsync);

  vconv : entity work.Replay_VideoConverter
    generic map (
      -- output format
      g_Vid_Param_HD  => c_Vidparam_720x576p_50,
      g_Vid_Param_SD  => c_Vidparam_720x576i_50,
      -- input parameters
      g_R_Bitwidth    => 8,  -- color bitwidths
      g_G_Bitwidth    => 8,  -- color bitwidths
      g_B_Bitwidth    => 8,  -- color bitwidths
      -- conversion parameters
      g_Vsize         => 248,-- visible vertical frame size
      g_Hsize         => 900,-- visible horizontal frame size
      g_Match_Line    => 0,  -- input line used for frame sync  (up to 311)
      g_Vadr_Width    => 2,  -- buffer vertical address width
      g_Hadr_Width    => 9,  -- buffer horizontal address width
      g_Hscale        => "010000000", -- scales horizontally (256*360/720) NON INTEGRAL FRACTIONS LOOK TERRIBLE
      g_Vres_half     => 1,  -- half output lines vertically (=double-scan)
      g_Loffset       => 0,  -- buffer line offset on output
      g_Voffset       => 21,  -- vertical buffer offset on output
      g_Hoffset       => 0 -- horizontal buffer offset on output
      )
    port map (
      i_Clk_Vid       => i_Clk_Vid,
      i_Ena_Vid       => i_Ena_Vid,
      i_Rst_Vid       => i_Rst_Vid,
      --
      i_ClK_Sys         => i_ClK_Sys,
      i_Ena_Sys       => i_Ena_Sys,
      i_Rst_Sys       => i_Rst_Sys,
      --
      i_HD_Mode       => i_HD_Mode,
      --
      i_Vid_r         => std_logic_vector(core_r_s),
      i_Vid_g         => std_logic_vector(core_g_s),
      i_Vid_b         => std_logic_vector(core_b_s),
      i_Vid_hsyncn    => core_hsyncn_s,
      i_Vid_vsyncn    => core_vsyncn_s,
      i_Vid_blankn    => core_blankn_s,
      --
      o_Vid_RGB       => o_Vid_RGB,
      o_Vid_Sync      => o_Vid_Sync,
      o_Vid_Timing    => o_Vid_Timing,
      o_Vid_Std       => o_Vid_Std
    );

-----------------------------------
-- DRAM ADAPTOR for atari
-----------------------------------
-- Atari signals
--  SDRAM_REQUEST : std_logic;
--  SDRAM_REQUEST_COMPLETE : std_logic;
--  SDRAM_READ_ENABLE :  STD_LOGIC;
--  SDRAM_WRITE_ENABLE : std_logic;
--  SDRAM_ADDR : STD_LOGIC_VECTOR(22 DOWNTO 0);
--  SDRAM_DO : STD_LOGIC_VECTOR(31 DOWNTO 0);
--  SDRAM_DI : STD_LOGIC_VECTOR(31 DOWNTO 0);
--  SDRAM_WIDTH_8bit_ACCESS : std_logic;
--  SDRAM_WIDTH_16bit_ACCESS : std_logic;
--  SDRAM_WIDTH_32bit_ACCESS : std_logic.
--
-- Replay signals
--    hp_ddr_valid          : out std_logic;
--    hp_ddr_taken          : in std_logic;
--    hp_ddr_addr           : out std_logic_vector(25 downto 2);
--    hp_wl                 : out std_logic;
--    hp_wbe                : out   std_logic_vector(1 downto 0);
--    hp_wdata              : out std_logic_vector(31 downto 0);
--    hp_rdata              : in std_logic_vector(31 downto 0);
--    hp_ddr_wr             : in std_logic;
--
-- Every ena_sys cycle I can do a single 32 bit read/write access
-- For the Atari I'm going to do an access every other ena_sys...
process(i_ena_sys, SDRAM_REQUEST, SDRAM_READ_ENABLE, SDRAM_WRITE_ENABLE, SDRAM_ADDR, SDRAM_DI, SDRAM_WIDTH_8bit_access, SDRAM_WIDTH_16bit_ACCESS, SDRAM_WIDTH_32bit_ACCESS, ddr_request_pending_reg, ddr_response_pending_reg, hp_ddr_wr, hp_ddr_taken)
begin
	ddr_request_pending_next <= ddr_request_pending_reg or sdram_request;
	dDR_REsponse_pending_next <= ddr_response_pending_reg;

	sdram_request_complete <= '0';
	hp_ddr_valid <= '0';

	if (i_ena_sys='1') then
		if (((ddr_request_pending_reg or sdram_request) and not (ddr_response_pending_reg)) = '1') then
			hp_ddr_valid <= '1';
			ddr_request_pending_next <= '0';
			ddr_response_pending_next <= '1';
		end if;

		-- Is there an issue with hp_ddr_wr - it gets cleared before the enable??
		if (ddr_response_pending_reg = '1') then
			-- previous request completed
			sdram_request_complete <= '1';
			ddr_response_pending_next <= '0';
		end if;
	end if;

	hp_ddr_addr <= "000"&sdram_addr(22 downto 2);
	hp_wl <= not(sdram_write_enable);
	hp_wbe <= (others=>SDRAM_WIDTH_32bit_ACCESS);
	-- TODO 16-bit (not used anyway by a800 yet)

	SDRAM_DO <= hp_rdata;
	hp_wdata <= SDRAM_DI;

	if (SDRAM_WIDTH_8bit_access = '1') then
		hp_wdata <= (others=>'0');
		SDRAM_DO <= (others=>'0');

		case (sdram_addr(1 downto 0)) is
		when "11" =>
			hp_wbe(0) <= '1';
			SDRAM_DO(7 downto 0) <= hp_rdata(7 downto 0);
			hp_wdata(7 downto 0) <= SDRAM_DI(7 downto 0);
		when "10" =>
			hp_wbe(1) <= '1';
			SDRAM_DO(7 downto 0) <= hp_rdata(15 downto 8);
			hp_wdata(15 downto 8) <= SDRAM_DI(7 downto 0);
		when "01" =>
			hp_wbe(2) <= '1';
			SDRAM_DO(7 downto 0) <= hp_rdata(23 downto 16);
			hp_wdata(23 downto 16) <= SDRAM_DI(7 downto 0);
		when "00" =>
			hp_wbe(3) <= '1';
			SDRAM_DO(7 downto 0) <= hp_rdata(31 downto 24);
			hp_wdata(31 downto 24) <= SDRAM_DI(7 downto 0);
		when others =>
			-- nop
		end case;
	end if;

end process;

process(i_Clk_sys,i_rst_sys)
begin
	if (i_rst_sys = '1') then
		ddr_request_pending_reg <= '0';
		ddr_response_pending_reg <= '0';
	elsif (i_clk_sys'event and i_clk_sys='1') then
		ddr_request_pending_reg <= ddr_request_pending_next;
		ddr_response_pending_reg <= ddr_response_pending_next;
	end if;
end process;

end RTL;
