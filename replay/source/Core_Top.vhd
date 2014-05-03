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
  use IEEE.STD_LOGIC_MISC.all;

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
    i_scn_lvl             : in  word(1 downto 0); -- sets scanline strength: "00": off ... "11": maximum
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
    rom_select            : in word(5 downto 0);
    speed_select          : in word(4 downto 0)
    );
end;

architecture RTL of Core_Top is

  -- selects core related debugging signals for internal debug
  constant int_dla_core_debug : boolean := false;

  signal PLL_LOCKED : std_logic;
  signal PLL_LOCKED_NEXT : std_logic_vector(2 downto 0);
  signal PLL_LOCKED_REG : std_logic_vector(2 downto 0);

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

  SIGNAL	THROTTLE_COUNT_6502 :  STD_LOGIC_VECTOR(5 DOWNTO 0);

  SIGNAL	CONSOL_OPTION :  STD_LOGIC;
  SIGNAL	CONSOL_SELECT :  STD_LOGIC;
  SIGNAL	CONSOL_START :  STD_LOGIC;

  SIGNAL	KEYBOARD_RESPONSE :  STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL	KEYBOARD_SCAN :  STD_LOGIC_VECTOR(5 DOWNTO 0);

  signal keyboard_scan_inv : std_logic_vector(5 downto 0);
  signal matrix_out_match : std_logic_vector(7 downto 0);

  constant c_800xl_kb_map : keylut_type := (
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"88",X"ff",
X"a0",X"ff",
X"00",X"ff",
X"c0",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"90",X"ff",
X"54",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"81",X"ff",
X"ff",X"ff",
X"82",X"ff",
X"57",X"ff",
X"37",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"27",X"ff",
X"76",X"ff",
X"77",X"ff",
X"56",X"ff",
X"36",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"22",X"ff",
X"26",X"ff",
X"72",X"ff",
X"52",X"ff",
X"30",X"ff",
X"32",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"41",X"ff",
X"20",X"ff",
X"70",X"ff",
X"55",X"ff",
X"50",X"ff",
X"35",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"43",X"ff",
X"25",X"ff",
X"71",X"ff",
X"75",X"ff",
X"53",X"ff",
X"33",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"45",X"ff",
X"01",X"ff",
X"13",X"ff",
X"63",X"ff",
X"65",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"40",X"ff",
X"05",X"ff",
X"15",X"ff",
X"10",X"ff",
X"62",X"ff",
X"60",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"42",X"ff",
X"46",X"ff",
X"00",X"ff",
X"02",X"ff",
X"12",X"ff",
X"66",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"06",X"ff",
X"ff",X"ff",
X"16",X"ff",
X"67",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"74",X"ff",
X"81",X"ff",
X"14",X"ff",
X"17",X"ff",
X"ff",X"ff",
X"07",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"64",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"34",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"47",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"82",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"21",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff",
X"ff",X"ff"

--    --    x0          x1          x2          x3          x4          x5          x6          x7          x8          x9          xA          xB          xC          xD          xE          xF               
--    --    --    --    F9    F9    --    --    F5    F5    F3    F3    F1    F1    F2    F2    F12   F12   --    --    F10   F10   F8    F8    F6    F6    F4    F4    STOP  STOP  POUND POUND --    --         
--        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"71",X"FF",X"72",X"FF",X"73",X"FF",X"60",X"73",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"60",X"74",X"60",X"71",X"60",X"72",X"00",X"FF",X"17",X"FF",X"FF",X"FF",  -- 0x
--    --    --    --   lALT  lALT  lSHI  lSHI   --    --    +     +     Q     Q     1     1     --    --    --    --    --    --    Z     Z     S     S     A     A     W     W     2     2     --    --         
--        X"FF",X"FF",X"FF",X"FF",X"60",X"FF",X"FF",X"FF",X"27",X"FF",X"01",X"FF",X"07",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"63",X"FF",X"62",X"FF",X"65",X"FF",X"66",X"FF",X"04",X"FF",X"FF",X"FF",  -- 1x
--    --    --    --    C     C     X     X     D     D     E     E     4     4     3     3     --    --    --    --   SPAC  SPAC   V     V     F     F     T     T     R     R     5     5     --    --         
--        X"FF",X"FF",X"53",X"FF",X"50",X"FF",X"55",X"FF",X"61",X"FF",x"64",X"FF",X"67",X"FF",X"FF",X"FF",X"FF",X"FF",X"03",X"FF",X"40",X"FF",X"52",X"FF",X"51",X"FF",X"56",X"FF",X"57",X"FF",X"FF",X"FF",  -- 2x
--    --    --    --    N     N     B     B     H     H     G     G     Y     Y     6     6     --    --    --    --    --    --    M     M     J     J     U     U     7     7     8     8     --    --         
--        X"FF",X"FF",X"30",X"FF",X"43",X"FF",X"42",X"FF",X"45",X"FF",X"46",X"FF",X"54",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"33",X"FF",X"35",X"FF",X"41",X"FF",X"47",X"FF",X"44",X"FF",X"FF",X"FF",  -- 3x
--    --    --    --    ,     ,     K     K     I     I     O     O     0     0     9     9     --    --    --    --    .     .     /     /     L     L     ;     ;     P     P     +     +     --    --         
--        X"FF",X"FF",X"20",X"FF",X"32",X"FF",X"36",X"FF",X"31",X"FF",X"34",X"FF",X"37",X"FF",X"FF",X"FF",X"FF",X"FF",X"23",X"FF",X"10",X"FF",X"25",X"FF",X"15",X"FF",X"26",X"FF",X"27",X"FF",X"FF",X"FF",  -- 4x
--    --    --    --    --    --    :     :     --    --    @     @     -     -     --    --    --    --   CAPS  CAPS  rSHI  rSHI  ENTE  ENTE   *     *     --    --    UP    UP    --    --    --    --         
--        X"FF",X"FF",X"FF",X"FF",X"22",X"FF",X"FF",X"FF",X"21",X"FF",X"24",X"FF",X"FF",X"FF",X"FF",X"FF",X"C0",X"FF",X"13",X"FF",X"76",X"FF",X"16",X"FF",X"FF",X"FF",X"11",X"FF",X"FF",X"FF",X"FF",X"FF",  -- 5x
--    --    --    --    --    --    --    --    --    --    --    --    --    --   BKSP  BKSP   --    --    --    --    KP1   KP1   --    --    KP4   KP4   KP7   KP7   --    --    --    --    --    --         
--        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"77",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",x"84",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",  -- 6x
--    --    KP0   KP0   KP.   KP.   KP2   KP2   KP5   KP5   KP6   KP6   KP8   KP8   ESC   ESC   NUM   NUM   F11   F11   KP+   KP+   KP3   KP3   KP-   KP-   KP*   KP*   KP9   KP9  SCRL  SCRL   --    --         
--        X"FF",X"FF",X"FF",X"FF",X"82",X"FF",X"90",X"FF",X"88",X"FF",X"81",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",  -- 7x
--    --
--    -- "0xE0-based" PS/2 SET 2
--    --
--    --    x0          x1          x2          x3          x4          x5          x6          x7          x8          x9          xA          xB          xC          xD          xE          xF               
--    --    --    --    --    --    --    --    F7    F7    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --         
--        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"74",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",  -- 0x
--    --    --    --   rALT  rALT *PRNT *PRNT   --    --   rCTL  rCTL   --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --   lGUI  lGUI        
--        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"06",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"02",X"FF",  -- 1x
--    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --   rGUI  rGUI   --    --    --    --    --    --    --    --    --    --    --    --    --    --   APPS  APPS        
--        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"02",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",  -- 2x
--    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    PWR   PWR   --    --    --    --    --    --    --    --    --    --    --    --    --    --   SLEE  SLEE        
--        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",  -- 3x
--    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    KP/   KP/   --    --    --    --    --    --    --    --    --    --         
--        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",  -- 4x
--    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --   KPen  KPen   --    --    --    --    --    --   WAKE  WAKE   --    --         
--        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",  -- 5x
--    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    --    END   END   --    --   lARR  lARR  HOME  HOME   --    --    --    --    --    --         
--        X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"77",X"FF",X"FF",X"FF",X"60",X"75",X"14",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",  -- 6x
--    --    INS   INS   DEL   DEL  dARR  dARR   --    --   rARR  rARR  uARR  uARR   --    --    --    --    --    --    --    --    =     =     --    --  *SCRN *SCRN  PGUP  PGUP   --    --    --    --         
--        X"FF",X"FF",X"FF",X"FF",X"70",X"FF",X"FF",X"FF",X"75",X"FF",X"60",X"70",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"12",X"FF",X"FF",X"FF",X"FF",X"FF",X"A0",X"FF",X"FF",X"FF",X"FF",X"FF"   -- 7x
       );


begin
  -- core control
  res_s <= i_Rst_Core;
  core_en_s <= i_Ena_Sys and not i_Halt_Core and not pause_key;

  -- atari keyboard
	keyboard_scan_inv <= not(keyboard_scan);

a4051: entity work.complete_address_decoder
	generic map (width => 3)
	PORT map ( addr_in => keyboard_scan_inv(5 downto 3), addr_decoded => matrix_in ); 

b4051: entity work.complete_address_decoder
	generic map (width => 3)
	PORT map ( addr_in => keyboard_scan_inv(2 downto 0), addr_decoded => matrix_out_match ); 

	process(matrix_out, matrix_out_match)
	begin
		keyboard_response(0) <= '1';

		if (or_reduce(matrix_out(7 downto 0) and matrix_out_match(7 downto 0)) = '1') then
			keyboard_response(0) <= '0';
		end if;
	end process;

	process(static_keys, pause_key)
	begin
		keyboard_response(1) <= '1';

		if (keyboard_scan(5 downto 4)="00" and pause_key = '1') then
			keyboard_response(1) <= '0';
		end if;
		
		if (keyboard_scan(5 downto 4)="10" and static_keys(0) = '1') then
			keyboard_response(1) <= '0';
		end if;

		if (keyboard_scan(5 downto 4)="11" and static_keys(1) = '1') then
			keyboard_response(1) <= '0';
		end if;
	end process;

	CONSOL_START <= static_keys(6);
	CONSOL_SELECT <= static_keys(5);
	CONSOL_OPTION <= static_keys(4);
--	system_reset_request <= static_keys(3);

	PLL_LOCKED <= pll_locked_reg(2);

	process(i_rst_sys, i_rst_core, pll_locked_reg, i_ena_sys)
	begin
		pll_locked_next <= pll_locked_reg;
		if (i_ena_sys = '1') then
			pll_locked_next(0) <= not(i_rst_sys or i_Rst_Core);
		end if;
		pll_locked_next(2 downto 1) <= pll_locked_reg(1 downto 0);
	end process;
	
	
	THROTTLE_COUNT_6502 <= '0'&speed_select;
	--THROTTLE_COUNT_6502 <= "000100";

atarixl_simple_sdram1 : entity work.atari800core_simple_sdram
	GENERIC MAP
	(
		cycle_length => 16,
		internal_rom => 0,
		internal_ram => 0
	)
	PORT MAP
	(
		CLK => i_clk_sys,
		RESET_N => PLL_LOCKED,

		VIDEO_VS => core_vsync,
		VIDEO_HS => core_hsync,
		VIDEO_B => core_b_s,
		VIDEO_G => core_g_s,
		VIDEO_R => core_r_s,

		AUDIO_L => lsound_s,
		AUDIO_R => rsound_s,

		JOY1_n => i_Joy_B(4 downto 0),
		JOY2_n => i_Joy_A(4 downto 0),

		KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,
		KEYBOARD_SCAN => KEYBOARD_SCAN,

		SIO_COMMAND => o_RS232_RTS,
		SIO_RXD => i_RS232_RXD,
		SIO_TXD => o_RS232_TXD,

		CONSOL_OPTION => CONSOL_OPTION,
		CONSOL_SELECT => CONSOL_SELECT,
		CONSOL_START => CONSOL_START,

		SDRAM_REQUEST => SDRAM_REQUEST,
		SDRAM_REQUEST_COMPLETE => SDRAM_REQUEST_COMPLETE,
		SDRAM_READ_ENABLE => SDRAM_READ_ENABLE,
		SDRAM_WRITE_ENABLE => SDRAM_WRITE_ENABLE,
		SDRAM_ADDR => SDRAM_ADDR,
		SDRAM_DO => SDRAM_DO,
		SDRAM_DI => SDRAM_DI,
		SDRAM_32BIT_WRITE_ENABLE => SDRAM_WIDTH_32bit_ACCESS,
		SDRAM_16BIT_WRITE_ENABLE => SDRAM_WIDTH_16bit_ACCESS,
		SDRAM_8BIT_WRITE_ENABLE => SDRAM_WIDTH_8bit_ACCESS,

		-- TODO, these sdram signals should come from PBI, not from DMA...
		-- TODO, review what I can share form PBI/DMA...
		DMA_FETCH => '0',
		DMA_READ_ENABLE => '0',
		DMA_32BIT_WRITE_ENABLE => '0',
		DMA_16BIT_WRITE_ENABLE => '0',
		DMA_8BIT_WRITE_ENABLE => '0',
		DMA_ADDR => (others=>'1'),
		DMA_WRITE_DATA => (others=>'0'),
		MEMORY_READY_DMA => open,

   		RAM_SELECT => ram_select,
    		ROM_SELECT => rom_select,
		PAL => '1',
		HALT => i_Halt_Core,
		THROTTLE_COUNT_6502 => THROTTLE_COUNT_6502
	);

--atari800core : entity work.atari800core
--	PORT map
--	(
--		CLK => i_clk_sys,
--		PLL_LOCKED => PLL_LOCKED,
--
--		VGA_VS => core_vsync,
--		VGA_HS => core_hsync,
--		VGA_B => core_b_s,
--		VGA_G => core_g_s,
--		VGA_R => core_r_s,
--
--		matrix_out => matrix_out,
--		matrix_in => matrix_in,
--		static_keys => static_keys,
--		pause_key => pause_key,
--
--		JOY1_n => i_Joy_A,
--		JOY2_n => i_Joy_B,
--		
--		AUDIO_L => lsound_s,
--		AUDIO_R => rsound_s,
--
--		SDRAM_REQUEST => SDRAM_REQUEST,
--		SDRAM_REQUEST_COMPLETE => SDRAM_REQUEST_COMPLETE,
--		SDRAM_READ_ENABLE => SDRAM_READ_ENABLE,
--		SDRAM_WRITE_ENABLE => SDRAM_WRITE_ENABLE,
--		SDRAM_ADDR => SDRAM_ADDR,
--		SDRAM_DO => SDRAM_DO,
--		SDRAM_DI => SDRAM_DI,
--		SDRAM_WIDTH_8bit_ACCESS => SDRAM_WIDTH_8bit_ACCESS,
--		SDRAM_WIDTH_16bit_ACCESS => SDRAM_WIDTH_16bit_ACCESS,
--		SDRAM_WIDTH_32bit_ACCESS => SDRAM_WIDTH_32bit_ACCESS,
--
--		SIO_RXD => i_RS232_RXD,
--		SIO_TXD => o_RS232_TXD,
--		SIO_COMMAND_TX => o_RS232_RTS,
--
--		ram_select => ram_select,
--		rom_select => rom_select,
--
--		halt => i_Halt_Core
--	);

  ----------------------------------------------------------
  -- KEYBOARD MAPPER
  ----------------------------------------------------------

  u_Kbd : entity work.Replay_TranslatePS2
  generic map (
    g_kb_map              => c_800xl_kb_map
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
      i_scanline_lvl  => i_scn_lvl,
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
		pll_locked_reg <= (others=>'0');
	elsif (i_clk_sys'event and i_clk_sys='1') then
		ddr_request_pending_reg <= ddr_request_pending_next;
		ddr_response_pending_reg <= ddr_response_pending_next;
		pll_locked_reg <= pll_locked_next;
	end if;
end process;

end RTL;
