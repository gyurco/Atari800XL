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
-- $Id: Replay_Top.vhd 387 2014-03-01 21:30:37Z wolfgang.scherr $
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

library UNISIM;
  use UNISIM.Vcomponents.all;

entity Replay_Top is
  port (
    -- RS232 debug port
    i_RS232_RXD           : in    bit1;
    o_RS232_TXD           : out   bit1;
    i_RS232_CTS           : in    bit1;
    o_RS232_RTS           : out   bit1;
    -- Joysticks
    i_Joy_A               : in    word( 5 downto 0);
    i_Joy_B               : in    word( 5 downto 0);
    -- IO
    b_IO                  : inout word(54 downto 0);
    b_Aux_IO              : inout word(39 downto 0);

    i_Aux_IP              : in    word(22 downto 0);
    -- DRAM
    o_Mem_Addr            : out   word(14 downto 0);
    b_Mem_DQ              : inout word(15 downto 0);
    b_Mem_UDQS            : inout bit1; -- Ctrl8
    b_Mem_LDQS            : inout bit1; -- Ctrl7
    o_Mem_UDM             : out   bit1; -- Ctrl6
    o_Mem_LDM             : out   bit1; -- Ctrl5
    o_Mem_CS              : out   bit1; -- Ctrl4
    o_Mem_RAS             : out   bit1; -- Ctrl3
    o_Mem_CAS             : out   bit1; -- Ctrl2
    o_Mem_WE              : out   bit1; -- Ctrl1
    o_Mem_CKE             : out   bit1; -- Ctrl0
    o_Mem_Clk_P           : out   bit1;
    o_Mem_Clk_N           : out   bit1;
    --
    o_Disk_Led            : out   bit1;
    o_Pwr_Led             : out   bit1;
    --
    i_Ext_Rst_L           : in    bit1; -- pullup
    b_2V5_IO_1            : inout bit1;
    b_2V5_IO_0            : inout bit1;
    -- Video
    o_Video_Clk_P         : out   bit1;
    o_Video_Clk_N         : out   bit1;
    o_Video_Rst_L         : out   bit1; -- Video16
    i_Video_Int           : in    bit1; -- Video15
    o_Video_DE            : out   bit1; -- Video14
    o_Video_V             : out   bit1; -- Video13
    o_Video_H             : out   bit1; -- Video12
    o_Video_Data          : out   word(11 downto 0);  --Video11..0
    b_Video_DDC_Clk       : out   bit1;
    b_Video_DDC_Data      : out   bit1;
    o_Video_HSync         : out   bit1;
    o_Video_VSync         : out   bit1;
    b_Video_SPC           : inout bit1;
    b_Video_SPD           : inout bit1;
    -- Audio
    o_Audio_LRCIN         : out   bit1; -- Audio3
    o_Audio_MCLK          : out   bit1; -- Audio2
    o_Audio_BCKIN         : out   bit1; -- Audio1
    o_Audio_DIN           : out   bit1; -- Audio0
    --
    b_PS2A_Clk            : inout bit1;
    b_PS2A_Data           : inout bit1;
    b_PS2B_Clk            : inout bit1;
    b_PS2B_Data           : inout bit1;

    b_SCL                 : inout bit1;
    b_SDA                 : inout bit1;

    -- System control
    i_FPGA_Ctrl0          : in    bit1;
    i_FPGA_Ctrl1          : in    bit1;
    i_FPGA_SPI_Clk        : in    bit1;
    b_FPGA_SPI_MOSI       : inout bit1;
    b_FPGA_SPI_MISO       : inout bit1;

    -- SSC & config pins
    --i_SSC_TF              : in    bit1; --io_init input during config
    --i_SSC_TD              : in    bit1; --io_din  input during config
    --i_SSC_RK              : in    bit1; --io_cclk input during config
    o_SSC_RD              : out   bit1; --io_dout output during config -- vertical sync for MCU (sync OSD update)
    --
    -- Clocks
    --
    o_Clk_68K             : out   bit1; -- source terminated to connector
    b_Clk_Aux             : inout bit1; -- direct to connector
    ClK_A                 : in    bit1;
    ClK_B                 : in    bit1;
    ClK_C                 : in    bit1

    );
end;

architecture RTL of Replay_Top is

  constant dla_mem_enable : boolean := false;

  signal clk_spi                : bit1;

  signal clk_vid                : bit1;
  signal clk_vid_90             : bit1;
  signal ena_vid                : bit1;
  signal rst_vid                : bit1;
  signal rst_vid_hard           : bit1;

  signal clk_sys                : bit1; -- note, same at clk_ctl
  signal ena_sys                : bit1;
  signal ena_sub1               : bit1;
  signal ena_sub4               : bit1;
  signal rst_sys                : bit1;

  signal clk_ctl                : bit1;
  signal rst_ctl                : bit1;
  signal rst_ctl_hard           : bit1;
  signal tick_ctl_1us           : bit1;
  signal tick_ctl_100us         : bit1;

  signal rst_aud                : bit1;
  signal clk_aud                : bit1;

  signal clk_ram                : bit1;
  signal clk_ram_90             : bit1;
  signal clk_capture            : bit1;
  signal rst_ram                : bit1;
  signal rst_capture            : bit1;
  signal rst_soft               : bit1;
  signal halt_soft              : bit1;
  --
  signal drive_scl_low          : bit1;
  signal drive_sda_low          : bit1;
  signal drive_spc_low          : bit1;
  signal drive_spd_low          : bit1;

  signal cfg_phase              : word(7 downto 0);
  signal cfg_cal_sel            : word(1 downto 0);

  signal core_ps2_clk           : bit1;
  signal core_ps2_data          : bit1;

  signal ps2a_drive_clk_low     : bit1;
  signal ps2a_drive_data_low    : bit1;
  signal ps2b_drive_clk_low     : bit1;
  signal ps2b_drive_data_low    : bit1;

  signal led : bit1;
  signal tick_pre1 : bit1;
  signal tick : bit1;

  signal ram_addr             :   word(24 downto 2);
  signal ram_data             :    word(63 downto 0);
  signal ram_r_w_l            :    bit1;
  signal ram_valid            :   bit1;

  signal core_audio_l : word(23 downto 0);
  signal core_audio_r : word(23 downto 0);
  signal phy_audio_taken : bit1;

  signal core_vid_rgb             : word(23 downto 0);
  signal core_vid_sync            : r_Vidsync;
  signal core_vid_timing          : r_Vidtiming;
  signal core_vid_std             : r_Vidstd;

  signal cfg_static : word(31 downto 0);
  signal cfg_dynamic : word(31 downto 0);
  signal cfg_ctrl : word(15 downto 0);
  signal cfg_fileio_i : word(7 downto 0);
  signal cfg_fileio : word(7 downto 0);

  signal mode_1541  : bit1;
  signal mode_key   : bit1;

  signal conf_valid : bit1;
  signal conf_taken : bit1;
  signal conf_write : bit1;
  signal conf_wr_core              : bit1 := '0';
  signal conf_wr_1541              : bit1 := '0';
  signal conf_wr_key               : bit1 := '0';

  --
  -- MCH
  --
  signal mch_addr : word(31 downto 0);
  signal mch_read : bit1;
  signal mch_data : word(7 downto 0);
  signal mch_valid : bit1;
  signal mch_taken : bit1;
  signal mch_rd_data : word(7 downto 0);
  signal mch_rd_we : bit1;

  signal mch_ram_taken : word(0 downto 0);
  signal mch_ram_rd_data : array8(0 downto 0);
  signal mch_ram_rd_we : word(0 downto 0);

  signal mch_ddr_taken : bit1;
  signal mch_ddr_rd_data : word(7 downto 0);
  signal mch_ddr_rd_we : bit1;

  signal hp_ddr_taken : bit1;
  signal hp_ddr_valid : bit1;
  signal hp_ddr_we : bit1;
  signal hp_wl : bit1;
  signal hp_ddr_addr : word(25 downto 0);
  signal hp_rdata : word(31 downto 0);
  signal hp_wdata : word(31 downto 0);
  signal hp_wbe   : word(3 downto 0);

  signal media_adr : unsigned(17 downto 0);
  signal media_read : bit1;
  signal media_dat : word(7 downto 0);
  signal diskid_s : word(15 downto 0);
  signal inscnt_s : unsigned(18 downto 0);

  signal init_diskinsert_s : bit1;
  signal writeprotn_s : bit1;

  --
  --
  --
  signal syscon_vid_rgb           : word(23 downto 0);
  signal syscon_vid_sync          : r_Vidsync;
  signal spi_syscon_cs_l : bit1;
  signal spi_fileio_cs_l : bit1;
  signal spi_syscon_miso : bit1;
  signal spi_fileio_miso : bit1;

  signal kb_inhibit : bit1;
  signal kb_we : bit1;
  signal kb_ps2 : word(7 downto 0);
  signal kb_led : word(2 downto 0);

  signal ms_we               : bit1;
  signal ms_posx             : word(11 downto 0);
  signal ms_posy             : word(11 downto 0);
  signal ms_butn             : word( 2 downto 0);

  signal ena_sys_c1 : bit1;
  signal ena_sys_ddr : bit1;

begin
  u_spi_bufg  : BUFG  port map (I => i_FPGA_SPI_Clk, O => clk_spi);

  u_ClockGen : entity work.Replay_ClockGen
  generic map (
    G_DIVIDER             => 11
    )
  port map (
    i_ClK_A               => Clk_A,
    i_ClK_B               => Clk_B,
    i_ClK_C               => Clk_C,
    --
    i_Rst_L               => i_Ext_Rst_L, -- hard reset
    i_Rst_Soft            => rst_soft,    -- NOT DRAM!
    --
    i_Ctl_Phase           => cfg_phase,
    i_Clk_Ctl             => clk_ctl,
    --
    o_Clk_Vid             => clk_vid,
    o_Clk_Vid_90          => clk_vid_90,
    o_Rst_Vid             => rst_vid,
    o_Rst_Vid_Hard        => rst_vid_hard,
    --
    o_Clk_Ctl             => clk_ctl,
    o_Rst_Ctl             => rst_ctl,
    o_Rst_Ctl_Hard        => rst_ctl_hard,
    --
    o_Tick_Ctl_1us        => tick_ctl_1us,
    o_Tick_Ctl_100us      => tick_ctl_100us,
    --
    o_Clk_Aux             => clk_aud,
    o_Rst_Aux             => rst_aud,
    --
    o_Clk_Ram             => clk_ram,
    o_Clk_Ram_90          => clk_ram_90,
    o_Clk_Ram_Capture     => clk_capture,
    o_Rst_Ram             => rst_ram,
    o_Rst_Ram_Capture     => rst_capture
    );

  enas : block
    signal sys_cnt : word(1 downto 0) := (others => '0');
    signal sub_cnt : word(4 downto 0) := (others => '0');
  begin
    -- clk_ram and clk_sys are edge aligned.
    p_sys_cnt : process
    begin
      wait until rising_edge(clk_sys);
      sys_cnt <= sys_cnt + "1";
      sub_cnt <= sub_cnt + "1";

      ena_sys  <= '0';
      if (sys_cnt = "11" ) then -- 0...3 --> divdes by 4 
        ena_sys <= '1';
        sys_cnt <= "00";
      end if;
      ena_sub1 <= '0';
      ena_sub4 <= '0';
      if (sub_cnt = "00101" ) then -- 0...5 --> divdes by 6
        ena_sub4 <= '1';
      end if;
      if (sub_cnt = "01011" ) then -- 6...11 --> divdes by 6
        ena_sub4 <= '1';
      end if;
      if (sub_cnt = "10001" ) then -- 12...17 --> divdes by 6
        ena_sub4 <= '1';
      end if;
      if (sub_cnt = "10111" ) then -- 0...23 --> divdes by 24, -- 18...23 --> divdes by 6 
        ena_sub1 <= '1';
        ena_sub4 <= '1';
        sub_cnt <= "00000";
      end if;
      -- DDR needs divison by 4
      if sub_cnt(1 downto 0)="10" then
        ena_sys_ddr <= '1';
      else
        ena_sys_ddr <= '0';
      end if;
    end process;
    --ena_sys_c1 <= not ena_sub4; --sys_cnt(1);
    ena_sys_c1 <= not sub_cnt(1);

    ena_vid <= '1';
  end block;
  --
  -- clk_ctl is the same as clk_sys, but used with no clock enable
  -- names are to keep domains apart
  --
  clk_sys <= clk_ctl;
  rst_sys <= rst_ctl;
  --
  --
  --

  b_2V5_IO_1   <= 'Z';
  b_2V5_IO_0   <= 'Z';

  o_Clk_68K  <= 'Z';
  b_Clk_Aux  <= 'Z';

  b_tick : block
    signal PreCounter1 : word(15 downto 0);
    signal PreCounter2 : word(11 downto 0);
  begin
    p_count : process
    begin
      wait until rising_edge(clk_vid);
      if (ena_vid = '1') then
        PreCounter1 <= PreCounter1 - "1";

        tick_pre1 <= '0';
        if (PreCounter1 = x"0000") then
          tick_pre1 <= '1';
        end if;
        -- synopsys translate_off
        tick_pre1 <= '1';
        -- synopsys translate_on

        tick <= '0';
        if (tick_pre1 = '1') then
          if (PreCounter2 = x"000") then
            PreCounter2 <= x"19B";
            tick <= '1';
          else
            PreCounter2 <= PreCounter2 - "1";
          end if;
        end if;
      end if;
    end process;
  end block;

  o_Pwr_Led <= not init_diskinsert_s;

  b_IO(22 downto  0) <= (others => 'Z');
  b_IO(28 downto 23) <= (others => 'Z');
  b_IO(34 downto 29) <= (others => 'Z');
  b_IO(54 downto 35) <= (others => 'Z');

  b_Aux_IO(39 downto 36)  <=  (others => 'Z');

  -- prevent forwarding PS/2 to core when OSD is activated
  core_ps2_clk <= b_PS2B_Clk when kb_inhibit='0' else '1';
  core_ps2_data <= b_PS2B_Data when kb_inhibit='0' else '1';

  --
  -- CORE
  --
  u_Core : entity work.Core_Top
  port map (
    i_Clk_Vid             => clk_vid,
    i_Ena_Vid             => ena_vid,
    i_Rst_Vid             => rst_vid,
    --
    i_ClK_Sys             => clk_sys,
    i_Ena_Sys             => ena_sys,
    i_Ena_Sub1            => ena_sub1,
    i_Ena_Sub4            => ena_sub4,
    i_Rst_Sys             => rst_sys,
    --
    i_Joy_A               => i_Joy_A,
    i_Joy_B               => i_Joy_B,
    --
    i_Ms_We               => ms_we,
    i_Ms_PosX             => ms_posx,
    i_Ms_PosY             => ms_posy,
    i_Ms_Butn             => ms_butn,
    --
    i_kb_osd_inhibit      => kb_inhibit,
    i_kb_ps2_we           => kb_we,
    i_kb_ps2              => kb_ps2,
    o_kb_led              => kb_led,
    --
    core_ps2_data => core_ps2_data,
    core_ps2_clk => core_ps2_clk,
    --
    i_Rst_Core            => rst_soft,
    i_Halt_Core           => halt_soft,
    i_HD_Mode             => cfg_dynamic(16),
    i_scn_lvl             => cfg_dynamic(20 downto 19), -- sets scanline strength: "00": off ... "11": maximum
    o_act_led_n           => o_Disk_Led,
    --
    i_Audio_lvl           => cfg_dynamic(18 downto 17),
    o_Audio_l             => core_audio_l,
    o_Audio_R             => core_audio_r,
    i_Audio_Taken         => phy_audio_taken,
    --
    i_cart_ro             => cfg_static(5),          -- readonly-enable
    i_cart_en             => cfg_static(0),          -- at $A000(8k)     '1', --
    i_ram_ext             => cfg_static(4 downto 1), -- at $6000(8k),$4000(8k),$2000(8k),$0400(3k)  "1111", --
    drive_address         => "00",
    --
    o_Vid_RGB             => core_vid_rgb,
    o_Vid_Sync            => core_vid_sync,
    -- sideband info
    o_Vid_Timing          => core_vid_timing,
    o_Vid_Std             => core_Vid_Std,
    -- d64 reader
    diskid_i              => diskid_s,
    media_adr_o           => media_adr,
    media_read_o          => media_read,
    media_dat_i           => media_dat,
    write_prot_n          => writeprotn_s,
    floppy_inserted       => init_diskinsert_s,
    --
    hp_ddr_valid        => hp_ddr_valid,
    hp_ddr_taken        => hp_ddr_taken,
    hp_ddr_addr         => hp_ddr_addr(25 downto 2),
    hp_wl               => hp_wl,
    hp_wbe              => hp_wbe,
    hp_wdata            => hp_wdata,
    hp_rdata            => hp_rdata,
    hp_ddr_wr           => hp_ddr_we,
    --
    i_RS232_RXD         => i_RS232_RXD,
    o_RS232_TXD         => o_RS232_TXD,
    i_RS232_CTS         => i_RS232_CTS,
    o_RS232_RTS         => o_RS232_RTS,
    --debug                 => b_Aux_IO(35 downto 0), -- from 1541 core:   addr(16), di(8), do(8), wrn, ph2, motor, led
                                                      -- from 1541 stream: track(7), sector(8), region(2), bdata(8), byteready, sync, gdata(8), led
    --debug                 => b_Aux_IO(35 downto 0), -- from VIC20:       addr(16), dio(8), hs, vs, atn, clk, dat, <mode(3)>, r_wn, nmi, irq, res
    debug                 => open,
    debugi                => b_IO(2 downto 0),
    -- ROM config
    CONF_WR_KEY           => conf_wr_key,
    CONF_WR_1541          => conf_wr_1541,
    CONF_WR               => conf_wr_core,
    CONF_AI               => mch_addr(15 downto 0),
    CONF_DI               => mch_data,
    -- 
    ram_select            => cfg_dynamic(2 downto 0),
    rom_select            => cfg_dynamic(8 downto 3),
    speed_select          => cfg_dynamic(13 downto 9)
    );

  --                            8                16              1             1           1            1           1           1            1        1          1           1                 2
  b_Aux_IO(35 downto 0) <= mch_data & mch_addr(15 downto 0) & conf_wr_1541 & conf_wr_core & conf_valid & conf_write & '0' & mode_1541 & mch_taken & mch_valid & mch_read & mch_read & mch_addr(1 downto 0);

  -- I/O

  u_JoyPS2 : entity work.Replay_JoyPS2
  port map (
    i_Clk                 => clk_ctl,
    i_Tick_1us            => tick_ctl_1us,
    i_Tick_100us          => tick_ctl_100us,
    i_Rst                 => rst_ctl,
    --
    -- IO Joysticks
    --
    i_Joy_A               => i_Joy_A,
    i_Joy_B               => i_Joy_B,

    -- IO PS2
    i_PS2A_Clk            => b_PS2A_Clk,
    i_PS2A_Data           => b_PS2A_Data,
-- TODO
    o_PS2A_Drive_Clk_Low  => ps2a_drive_clk_low,
    o_PS2A_Drive_Data_Low => ps2a_drive_data_low,
--
    i_PS2B_Clk            => b_PS2B_Clk,
    i_PS2B_Data           => b_PS2B_Data,
    o_PS2B_Drive_Clk_Low  => ps2b_drive_clk_low,
    o_PS2B_Drive_Data_Low => ps2b_drive_data_low,
    --
    -- to core
    --
    i_Kb_PS2_Leds         => kb_led,
    o_Kb_PS2_We           => kb_we,
    o_Kb_PS2_Data         => kb_ps2,
    --
    o_Ms_We               => ms_we,
    o_Ms_PosX             => ms_posx,
    o_Ms_PosY             => ms_posy,
    o_Ms_Butn             => ms_butn
    );

  b_PS2A_Clk  <= '0' when (ps2a_drive_clk_low  = '1') else 'Z';
  b_PS2A_Data <= '0' when (ps2a_drive_data_low = '1') else 'Z';
  b_PS2B_Clk  <= '0' when (ps2b_drive_clk_low  = '1') else 'Z';
  b_PS2B_Data <= '0' when (ps2b_drive_data_low = '1') else 'Z';

  b_PULLUP : block
  begin
    -- input's have pulls in UCF file
    ps2a_pu_clk  : PULLUP port map (o => b_PS2A_Clk);
    ps2a_pu_data : PULLUP port map (o => b_PS2A_Data);
    ps2b_pu_clk  : PULLUP port map (o => b_PS2B_Clk);
    ps2b_pu_data : PULLUP port map (o => b_PS2B_Data);

    io : for i in 0 to 54 generate
      io_pu  : PULLUP port map (o   => b_IO(i));
    end generate;

    aux : for i in 12 to 39 generate
      auxio_pu  : PULLUP port map (o   => b_Aux_IO(i));
    end generate;

    aux2 : for i in 0 to 3 generate
      auxio_pu  : PULLUP port map (o   => b_Aux_IO(i));
    end generate;

    aux_pu  : PULLUP port map (o => b_Clk_Aux);
    io_1_pu : PULLUP port map (o => b_2V5_IO_1);
    io_0_pu : PULLUP port map (o => b_2V5_IO_0);

  end block;

  --
  -- DRAM is 64MB x 8bit or 16MB x 32bit
  --
  -- (byte) address is 0x03FF FFFF downto 0x0000 0000
  --
  -- we use the first 32MB (x8) for memory on the VIC-20          --> 0x01FF FFFF downto 0x0000 0000
  -- we use the second 32MB (x8) as memory for the 1541 d64 files --> 0x03FF FFFF downto 0x0200 0000

--  mch_ddr_valid <= mch_valid when (mch_addr(31) = '0') else '0';  -- first addresses from 0x00000000 on are DRAM, from 0x80000000 on is for other memory

  u_DDRCtrl : entity work.Replay_DDRCtrl_top
  port map (
    i_Clk_Ram         => clk_ram,
    i_Clk_Ram_90      => clk_ram_90,
    i_Rst_Ram         => rst_ram,
    --
    i_Clk_Capture     => clk_capture,
    i_Rst_Capture     => rst_capture,
    --
    i_Clk_Sys         => clk_sys,
    i_Ena_Sys         => ena_sys_ddr,
    i_Ena_Sys_C1      => ena_sys_C1,
    i_Rst_Sys         => rst_sys,

    -- DDR Signals
    o_RAM_BA          => o_Mem_Addr(14 downto 13),
    o_RAM_Addr        => o_Mem_Addr(12 downto  0),
    --
    o_RAM_CS_L        => o_Mem_CS,
    o_RAM_WE_L        => o_Mem_WE,
    o_RAM_RAS_L       => o_Mem_RAS,
    o_RAM_CAS_L       => o_Mem_CAS,
    --
    o_RAM_DM_L(1)     => o_Mem_UDM,
    o_RAM_DM_L(0)     => o_Mem_LDM,
    b_RAM_DQS(1)      => b_Mem_UDQS,
    b_RAM_DQS(0)      => b_Mem_LDQS,
    b_RAM_DQ          => b_Mem_DQ,
    --
    o_RAM_CKE         => o_Mem_CKE,
    o_RAM_CK_P        => o_Mem_Clk_P,
    o_RAM_CK_N        => o_Mem_Clk_N,
    --
    i_Cfg_Cal_Sel     => cfg_cal_sel,

    -- High Priority - 32 bit i/f
    i_HP_Valid        => hp_ddr_valid,
    o_HP_Taken        => hp_ddr_taken,
    i_HP_Addr         => hp_ddr_addr(25 downto 2),
    i_HP_RW_l         => hp_wl,
    i_HP_W_BE         => hp_wbe,
    i_HP_W_Data       => hp_wdata,
    --
    o_HP_R_Data       => hp_rdata,
    o_HP_R_We         => hp_ddr_we,

    -- Low Priority - 8 bit i/f
    i_LP_Valid        => mch_valid,
    o_LP_Taken        => mch_ddr_taken,
    i_LP_Addr         => mch_addr(25 downto 0),
    i_LP_RW_l         => mch_read,
    i_LP_W_Data       => mch_data,
    --
    o_LP_R_Data       => mch_ddr_rd_data,
    o_LP_R_We         => mch_ddr_rd_we
    );

  -- handling media access when d64 is load via
  -- ARM to DDR (on low-prio channel) 
  media_access : process (clk_sys, rst_sys) is
  begin
    if rst_sys='1' then
      init_diskinsert_s <= '0';
      diskid_s <= x"0000";
      inscnt_s <= (others => '0');
      writeprotn_s <= '0';
    elsif rising_edge(clk_sys) then
      -- handle disk change and fetch disk id
      if mch_read='0' and mch_valid='1' and mch_ddr_taken='0' then
        if mch_addr=x"02000000" then
          init_diskinsert_s <= '0';
          writeprotn_s <= '1';
        elsif mch_addr=x"020165A2" then
          diskid_s(15 downto 8) <= mch_data;
        elsif mch_addr=x"020165A3" then
          diskid_s(7 downto 0)  <= mch_data;
        elsif mch_addr=x"0202AAFF" then
          inscnt_s <= (others => '1');
        end if;
      end if;
      if ena_sub1='1' then
        if inscnt_s/=0 then
          inscnt_s<=inscnt_s-1;
          if inscnt_s=1 then
            init_diskinsert_s <= '1';
            writeprotn_s <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

  ----------------------------------------------------------
  -- RAM/ROM load process
  ----------------------------------------------------------

  conf_valid <= mch_valid when (mch_addr(31 downto 20) = x"000") else '0';
  conf_write <= conf_valid and ena_sys and not mch_read;   -- 0x000?xxxx --> configuration upload (ROM or PRG)
  mode_1541 <= mch_addr(18);                   -- 0x0004xxxx --> 1541 configuration upload
  mode_key  <= mch_addr(17);                   -- 0x0002xxxx --> keymapping configuration upload

  -- we pass all input also to the core memories in parallel to the DDR ram
  conf_wr_core <= conf_write and mch_valid and (not mode_1541) and (not mode_key);
  conf_wr_1541 <= conf_write and mch_valid and mode_1541;
  conf_wr_key  <= conf_write and mch_valid and mode_key;

  --
  -- System control / On Screen Display
  --
  u_Syscon : entity work.Replay_Syscon
  generic map (
    -- defaults
    g_Cfg_Static          => x"00000000",
    g_Cfg_Dynamic         => x"00000000",
    g_cfg_fileio_hd_ena   => "0000",
    g_cfg_fileio_fd_ena   => "0000",
    g_Cfg_Ctrl            => x"0080",
    --
    g_Version             => x"1001" -- top bit DRAM disabled
    )
  port map (
    i_Clk_Vid             => clk_vid,
    i_Ena_Vid             => ena_vid,
    i_Rst_Vid             => rst_vid,
    --
    i_Clk_Ctl             => clk_ctl,
    i_Rst_Ctl             => rst_ctl,
    i_Rst_Ctl_Hard        => rst_ctl_hard,
    --
    o_Rst_Soft            => rst_soft,
    o_Halt                => halt_soft,
    --
    i_SPI_CS_l            => spi_syscon_cs_l,
    i_SPI_Clk             => clk_spi,
    i_SPI_D               => b_FPGA_SPI_MOSI,
    o_SPI_D               => spi_syscon_miso,
    --
    o_VBL                 => o_SSC_RD,
     -- Config
    i_cfg_status          => x"0000",
    --
    o_cfg_Static          => cfg_static,
    o_cfg_Dynamic         => cfg_dynamic,
    o_Cfg_FileIO          => open,
    o_Cfg_Ctrl            => cfg_ctrl,
    --
    i_Kb_PS2_We           => kb_we,
    i_Kb_PS2_Data         => kb_ps2,
    o_Kb_Inhibit          => kb_inhibit, -- core should use to ignore keypresses when OSD active
    --
    i_Vid_RGB             => core_vid_rgb,
    i_Vid_Sync            => core_vid_sync,
    --
    o_Vid_RGB             => syscon_vid_rgb,
    o_Vid_Sync            => syscon_vid_sync
    --
    );

  cfg_fileio  <= cfg_fileio_i and "00000000"; -- 0 HD, 0 FD
  cfg_phase   <= cfg_ctrl(7 downto 0);  -- 25 ps per tick
  cfg_cal_sel <= cfg_ctrl(9 downto 8);
-- When the transfer is in direct mode from SD card, we need
-- to swap over the in and out pins on the SPI interface (we are now a slave).
-- We cannot drive the output in this case unless the ARM is not.

  spi_fileio_cs_l <= i_FPGA_Ctrl0;
  spi_syscon_cs_l <= i_FPGA_Ctrl1;

  b_FPGA_SPI_MOSI <= 'Z';
  b_FPGA_SPI_MISO <= spi_fileio_miso when (spi_fileio_cs_l = '0') else 'Z';
  b_FPGA_SPI_MISO <= spi_syscon_miso when (spi_syscon_cs_l = '0') else 'Z';

  u_FileIO : entity work.Replay_FileIO
  port map (
  -- handles all disk/tape/HDD/ROM transfers to the SD card/ARM
    i_Clk_Ctl             => clk_ctl,
    i_Rst_Ctl             => rst_ctl,
    --
    i_Ena_Sys             => ena_sys_ddr,
    --
    i_SPI_CS_l            => spi_fileio_cs_l,
    i_SPI_Clk             => clk_spi,
    i_SPI_D               => b_FPGA_SPI_MOSI,
    o_SPI_D               => spi_fileio_miso,
    --
    -- FD
    --
    o_fch_to_core         => open,
    i_fch_fm_core         => z_FCh_fm_core, -- tie off
    --
    -- HD
    --
    o_hch_to_core         => open,
    i_hch_fm_core         => z_HCh_fm_core, -- tie off
    --
    -- Memory interface
    --
    o_MCh_Addr            => mch_addr,
    o_Mch_Read            => mch_read,
    o_MCh_Data            => mch_data,
    o_MCh_Flush           => open,
    o_MCh_Valid           => mch_valid,
    i_MCh_Taken           => mch_taken,
    --
    i_MCh_Data            => mch_rd_data,
    i_MCh_We              => mch_rd_we
  );

  -- mch read combine
  mch_taken   <= --conf_taken or
                 mch_ddr_taken;

  mch_rd_data <= mch_ddr_rd_data(7 downto 0);

  mch_rd_we   <= mch_ddr_rd_we;

  --
  -- VIDEO
  --
  u_Video : entity work.Replay_Video
  port map (
    i_Clk_Vid             => clk_vid,
    i_Clk_Vid_90          => clk_vid_90,
    i_Ena_Vid             => ena_vid,
    i_Rst_Vid_Hard        => rst_vid_hard,
    --
    i_Clk_Ctl             => clk_ctl, -- used for i2c bridge
    i_Rst_Ctl             => rst_ctl,
    --
    -- Input video must come from a register clocked with Clk_Video
    i_Vid_RGB             => syscon_vid_rgb,
    i_Vid_Sync            => syscon_vid_sync,
    -- cpu i2c pins
    i_SCL                 => b_SCL,
    i_SDA                 => b_SDA,
    o_Drive_SCL_Low       => drive_scl_low,
    o_Drive_SDA_Low       => drive_sda_low,
    -- video i2c pins
    i_SPC                 => b_Video_SPC,
    i_SPD                 => b_Video_SPD,
    o_Drive_SPC_Low       => drive_spc_low,
    o_Drive_SPD_Low       => drive_spd_low,
    --
    o_Video_Clk_P         => o_Video_Clk_P,
    o_Video_Clk_N         => o_Video_Clk_N,
    o_Video_Rst_L         => o_Video_Rst_L,
    i_Video_Int           => i_Video_Int,
    o_Video_DE            => o_Video_DE,
    o_Video_V             => o_Video_V,
    o_Video_H             => o_Video_H,
    o_Video_Data          => o_Video_Data,
    b_Video_DDC_Clk       => b_Video_DDC_Clk,
    b_Video_DDC_Data      => b_Video_DDC_Data,
    --
    o_Video_HSync         => o_Video_HSync,
    o_Video_VSync         => o_Video_VSync
    );
  --
  b_SCL       <= '0' when (drive_scl_low = '1') else 'Z';
  b_SDA       <= '0' when (drive_sda_low = '1') else 'Z';
  b_Video_SPC <= '0' when (drive_spc_low = '1') else 'Z';
  b_Video_SPD <= '0' when (drive_spd_low = '1') else 'Z';
  --
  -- AUDIO PHY
  --
  u_Audio : entity work.Replay_Audio
  port map (
    i_Clk                 => clk_aud, --sys,
    i_Ena                 => '1',     --ena_sys,
    i_Rst                 => rst_aud, --rst_sys,
    --
    i_Sample_L            => core_audio_l,
    i_Sample_R            => core_audio_r,
    o_Sample_Taken        => phy_audio_taken,
    --
    o_Audio_LRCIN         => o_Audio_LRCIN,
    o_Audio_MCLK          => o_Audio_MCLK,
    o_Audio_BCKIN         => o_Audio_BCKIN,
    o_Audio_DIN           => o_Audio_DIN
    );
  --

  -- memory debugging

  dbg : block is
    --{{{  cs
    component icon
      PORT (
        CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0)
        );
    end component;

    component ila_1024_63
      PORT (
        CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
        CLK     : IN STD_LOGIC;
        TRIG0   : IN STD_LOGIC_VECTOR(62 DOWNTO 0)
        );
    end component;

    signal cs_control0   : std_logic_vector(35 downto 0);
    signal cs_clk        : std_logic;
    signal cs_trig       : std_logic_vector(62 downto 0);
    --}}}
  begin
    local_mem_dla : if dla_mem_enable=true generate
      i_icon : icon
        port map (
          CONTROL0 => cs_control0
      );

      i_ila : ila_1024_63
        port map (
          CONTROL => cs_control0,
          CLK     => cs_clk,
          TRIG0   => cs_trig);

      cs_clk       <= clk_ctl;

      cs_trig(62) <= '0';
      cs_trig(61 downto 52) <= "0000000000";

      cs_trig(51 downto 20) <= mch_addr;
      cs_trig(19 downto 12) <= mch_data;

      cs_trig(11) <= hp_ddr_taken;
      cs_trig(10) <= mch_ddr_rd_we;
      cs_trig(9)  <= mch_valid;
      cs_trig(8)  <= mch_ddr_taken;

      cs_trig(7)  <= ena_sys;
      cs_trig(6)  <= conf_valid;
      cs_trig(5)  <= conf_write;
      cs_trig(4)  <= conf_taken;

      cs_trig(3)  <= mch_valid;
      cs_trig(2)  <= mch_read;
      cs_trig(1)  <= mch_rd_we;
      cs_trig(0)  <= mch_taken;

    end generate local_mem_dla;
  end block dbg;
end RTL;
