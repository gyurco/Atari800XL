library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_textio.all;

library std_developerskit ; -- used for to_string
--  use std_developerskit.std_iopak.all;

  use work.Replay_Pack.all;

entity Replay_tb is
end;

architecture rtl of Replay_tb is

  -- SYSCLK=4436250Hz, Nsys=1183, Msys=300, Psys=1 ... VIDCLK=27035651Hz, Nvid=2275, Mvid=284, Pvid=8
  constant CLK_A_PERIOD : time := 1 us / (4*4*7.11631);
  constant CLK_B_PERIOD : time := 1 us / 49.152 ;
  constant CLK_C_PERIOD : time := 1 us / 27.010289;

  constant PS2BITTIME : time := 60 uS;
  constant SPIBITTIME : time := 40.00 ns;
  --constant PS2BITTIME : time := 10 uS;

  signal rs232_rxd            : bit1;
  signal rs232_txd            : bit1;
  signal rs232_cts            : bit1;
  signal rs232_rts            : bit1;

  signal joy_a                : word( 5 downto 0);
  signal joy_b                : word( 5 downto 0);
  signal io                   : word(54 downto 0);
  signal aux_io               : word(39 downto 0);
  signal aux_ip               : word(22 downto 0);

  signal mem_addr             : word(14 downto 0);
  signal mem_dq               : word(15 downto 0);
  signal mem_dqs              : word(1 downto 0);
  signal mem_dm               : word(1 downto 0);
--  signal mem_udqs             : bit1; -- Ctrl8
--  signal mem_ldqs             : bit1; -- Ctrl7
--  signal mem_udm              : bit1; -- Ctrl6
--  signal mem_ldm              : bit1; -- Ctrl5
  signal mem_cs               : bit1; -- Ctrl4
  signal mem_ras              : bit1; -- Ctrl3
  signal mem_cas              : bit1; -- Ctrl2
  signal mem_we               : bit1; -- Ctrl1
  signal mem_cke              : bit1; -- Ctrl0
  signal mem_clk_p            : bit1;
  signal mem_clk_n            : bit1;

  signal disk_led             : bit1;
  signal pwr_led              : bit1;

  signal Ext_Rst_L            : bit1;
  signal b2v5_io_1            : bit1;
  signal b2v5_io_0            : bit1;

  signal video_clk_p          : bit1;
  signal video_clk_n          : bit1;
  signal video_rst_l          : bit1;
  signal video_int            : bit1;
  signal video_de             : bit1;
  signal video_v              : bit1;
  signal video_h              : bit1;
  signal video_data           : word(11 downto 0);  --Video11..0
  signal video_ddc_clk        : bit1;
  signal video_ddc_data       : bit1;
  signal video_hsync          : bit1;
  signal video_vsync          : bit1;
  signal video_spc            : bit1;
  signal video_spd            : bit1;

  signal audio_lrcin          : bit1;
  signal audio_mclk           : bit1;
  signal audio_bckin          : bit1;
  signal audio_din            : bit1;

  signal ps2_clk              : word(1 downto 0);
  signal ps2_data             : word(1 downto 0);

  signal scl                  : bit1;
  signal sda                  : bit1;

  signal fpga_ctrl            : word(1 downto 0);
  signal fpga_spi_clk         : bit1;
  signal fpga_spi_mosi        : bit1;
  signal fpga_spi_miso        : bit1;

  --signal ssc_tf               : bit1;
  --signal ssc_td               : bit1;
  --signal ssc_rk               : bit1;
  --signal ssc_rd               : bit1;

  signal clk_68k              : bit1;
  signal clk_aux              : bit1;

  signal clk_a                : bit1;
  signal clk_b                : bit1;
  signal clk_c                : bit1;
  --
  signal por                  : bit1;
  signal por_l                : bit1;

  signal ps2_clk_drive_tx     : word(1 downto 0) := "11";
  signal ps2_data_drive_tx    : word(1 downto 0) := "11";
  signal ps2_clk_drive_rx     : word(1 downto 0) := "11";
  signal ps2_data_drive_rx    : word(1 downto 0) := "11";
  signal ps2_send_active      : word(1 downto 0) := "00";
  signal ps2_slave_rx         : bit1;
  signal ps2_slave_data       : word(8 downto 0);
  --{{{
  component ddr
  port (
    DQ    : inout std_logic_vector(15 downto 0);
    DQS   : inout std_logic_vector( 1 downto 0);
    ADDR  : in    std_logic_vector(12 downto 0);
    BA    : in    std_logic_vector( 1 downto 0);
    CLK   : in    std_logic;
    CLK_N : in    std_logic;
    CKE   : in    std_logic;
    CS_N  : in    std_logic;
    RAS_N : in    std_logic;
    CAS_N : in    std_logic;
    WE_N  : in    std_logic;
    DM    : in    std_logic_vector( 1 downto 0)
  );
  end component;
  --}}}

begin
  p_clk_gen_a : process
  begin
  clk_a <= '1';
  wait for CLK_A_PERIOD/2;
  clk_a <= '0';
  wait for CLK_A_PERIOD - (CLK_A_PERIOD/2 );
  end process;

  p_clk_gen_b : process
  begin
  clk_b <= '1';
  wait for CLK_B_PERIOD/2;
  clk_b <= '0';
  wait for CLK_B_PERIOD - (CLK_B_PERIOD/2 );
  end process;

  p_clk_gen_c : process
  begin
  clk_c <= '1';
  wait for CLK_C_PERIOD/2;
  clk_c <= '0';
  wait for CLK_C_PERIOD - (CLK_C_PERIOD/2 );
  end process;

  p_rst                  : process
  begin
  por <= '1'; por_l <= '0';
  wait until rising_edge(clk_c);
  wait until rising_edge(clk_c);
  wait until rising_edge(clk_c);
  wait until rising_edge(clk_c);
  por <= '0'; por_l <= '1';
  wait;
  end process;

  Ext_Rst_L  <= por_l;

  -- core
  u_Replay : entity work.Replay_Top
  port map (
    -- RS232 debug port
    i_RS232_RXD           => rs232_rxd,
    o_RS232_TXD           => rs232_txd,
    i_RS232_CTS           => rs232_cts,
    o_RS232_RTS           => rs232_rts,
    -- Joysticks
    i_Joy_A               => joy_a,
    i_Joy_B               => joy_b,
    -- IO
    b_IO                  => io,
    b_Aux_IO              => aux_io,
    i_Aux_IP              => aux_ip,
    -- DRAM
    o_Mem_Addr            => mem_addr,
    b_Mem_DQ              => mem_dq,
    b_Mem_UDQS            => mem_dqs(1), --mem_udqs,
    b_Mem_LDQS            => mem_dqs(0), --mem_ldqs,
    o_Mem_UDM             => mem_dm(1), --mem_udm,
    o_Mem_LDM             => mem_dm(0), --mem_ldm,
    o_Mem_CS              => mem_cs,
    o_Mem_RAS             => mem_ras,
    o_Mem_CAS             => mem_cas,
    o_Mem_WE              => mem_we,
    o_Mem_CKE             => mem_cke,
    o_Mem_Clk_P           => mem_clk_p,
    o_Mem_Clk_N           => mem_clk_n,
    --
    o_Disk_Led            => disk_led,
    o_Pwr_Led             => pwr_led,
    --
    i_Ext_Rst_L           => Ext_Rst_L,
    b_2V5_IO_1            => b2v5_io_1,
    b_2V5_IO_0            => b2v5_io_0,
    -- Video
    o_Video_Clk_P         => video_clk_p,
    o_Video_Clk_N         => video_clk_n,
    o_Video_Rst_L         => video_rst_l,
    i_Video_Int           => video_int,
    o_Video_DE            => video_de,
    o_Video_V             => video_v,
    o_Video_H             => video_h,
    o_Video_Data          => video_data,
    b_Video_DDC_Clk       => video_ddc_clk,
    b_Video_DDC_Data      => video_ddc_data,
    o_Video_HSync         => video_hsync,
    o_Video_VSync         => video_vsync,
    b_Video_SPC           => video_spc,
    b_Video_SPD           => video_spd,
    -- Audio
    o_Audio_LRCIN         => audio_lrcin,
    o_Audio_MCLK          => audio_mclk,
    o_Audio_BCKIN         => audio_bckin,
    o_Audio_DIN           => audio_din,
    --
    b_PS2A_Clk            => ps2_clk(0),
    b_PS2A_Data           => ps2_data(0),
    b_PS2B_Clk            => ps2_clk(1),
    b_PS2B_Data           => ps2_data(1),

    b_SCL                 => scl,
    b_SDA                 => sda,

    -- System control
    i_FPGA_Ctrl0          => fpga_ctrl(0),
    i_FPGA_Ctrl1          => fpga_ctrl(1),
    i_FPGA_SPI_Clk        => fpga_spi_clk,
    b_FPGA_SPI_MOSI       => fpga_spi_mosi,
    b_FPGA_SPI_MISO       => fpga_spi_miso,

    -- SSC & config pins
    --i_SSC_TF              => ssc_tf,
    --i_SSC_TD              => ssc_td,
    --o_SSC_RK              => ssc_rk,
    --o_SSC_RD              => ssc_rd,
    o_SSC_RD              => open,

    -- Clocks
    o_Clk_68K             => clk_68k,
    b_Clk_Aux             => clk_aux,
    ClK_A                 => clk_a,
    ClK_B                 => clk_b,
    ClK_C                 => clk_c
    );

  rs232_rxd <= '0';
  rs232_cts <= '0';

  joy_a <= "000000";
  joy_b <= "000000";
  io    <= (others => 'Z');

  aux_io <= (others => 'Z');
  aux_ip <= (others => '0');
  mem_dq <= (others => 'Z');

  mem_dqs <= "ZZ";
--  mem_udqs <= 'Z';
--  mem_ldqs <= 'Z';

  b2v5_io_1 <= 'Z';
  b2v5_io_0 <= 'Z';

  video_int <= '0';
  video_ddc_clk <= '0';
  video_ddc_data <= '0';

  clk_aux <= 'Z';

  p_i2c_test : process
  -- chrontel
  -- EC write  1110110x
  -- ED read
  constant I2CBITTIME : time := 2.5 uS;

  procedure I2CStart is
  begin
    scl <= 'H';
    sda <= 'H';
    -- start bit
    wait for I2CBITTIME/4;
    sda <= '0';
    wait for I2CBITTIME/4;
  end procedure;

  procedure I2CReStart is
  begin
    scl <= '0';
    sda <= 'H';
    wait for I2CBITTIME/2;
    scl <= 'H';
    wait for I2CBITTIME/4;
    sda <= '0';
    wait for I2CBITTIME/4;
    scl <= '0';
  end procedure;

  procedure I2CStop is
  begin
    sda <= '0';
    scl <= '0';
    wait for I2CBITTIME/2;
    scl <= 'H';
    wait for I2CBITTIME/2;
    sda <= 'H';
    wait for I2CBITTIME/2;

  end procedure;

  procedure I2CWaitAck is
  begin
    sda <= 'H';
    scl <= '0';
    wait for I2CBITTIME/2;
    scl <= 'H';
    wait for I2CBITTIME/2;
  end procedure;

  procedure I2CNAck is
  begin
    sda <= 'H';
    scl <= '0';
    wait for I2CBITTIME/2;
    scl <= 'H';
    wait for I2CBITTIME/2;
  end procedure;

  procedure I2CWrite (data:word(7 downto 0)) is
  begin
    for i in 7 downto 0 loop
    scl <= '0';
    wait for I2CBITTIME/4;
    if (data(i) = '1') then sda <= 'H'; else sda <= '0'; end if;
    wait for I2CBITTIME/4;
    scl <= 'H';
    wait for I2CBITTIME/2;
    end loop;
  end procedure;

  procedure I2CRead is
    variable read_data : word(7 downto 0);
  begin
    for i in 7 downto 0 loop
    scl <= '0';
    wait for I2CBITTIME/4;
    read_data(i) := sda;
    sda <= 'H';
    wait for I2CBITTIME/4;
    scl <= 'H';
    wait for I2CBITTIME/2;
    end loop;

    assert false report
    "I2C Read : " ; --& to_string(to_bitvector(read_data), "%2x");

  end procedure;

  begin
  scl       <= 'H';
  sda       <= 'H';

  video_spc <= 'H';
  video_spd <= 'H';
  wait for 5 us;
  -- write
  I2CStart;
  I2CWrite(x"EC"); -- addr
  I2CWaitAck;
  I2CWrite(x"81"); -- sub addr
  I2CWaitAck;
  I2CWrite(x"12"); -- data
  I2CWaitAck;
  I2CStop;
  wait for 5 us;
  -- read
  I2CStart;
  I2CWrite(x"EC"); -- addr
  I2CWaitAck;
  I2CWrite(x"81"); -- sub addr
  I2CWaitAck;
  I2CReStart; -- restart
  I2CWrite(x"ED"); -- addr
  I2CWaitAck;
  I2CRead;
  I2CNAck;
  I2CStop;

  wait;
  end process;
  --
  -- dummy i2c slave
  u_slave : entity work.Replay_I2C_CH7301
  port map (
    i_Rst    => por,
    b_SPC    => video_spc,
    b_SPD    => video_spd
    );
  --
  --
  p_spi_test : process
  procedure SPI (data:word(7 downto 0)) is
    variable read_data : word(7 downto 0);
  begin
    wait for SPIBITTIME/4;

    for i in 7 downto 0 loop
    fpga_spi_clk <= '1';
    wait for SPIBITTIME/4;
    if (data(i) = '1') then fpga_spi_mosi <= '1'; else fpga_spi_mosi <= '0'; end if;
    wait for SPIBITTIME/4;
    fpga_spi_clk <= '0';
    wait for SPIBITTIME/2;
    fpga_spi_clk <= '1';
    read_data(i) := fpga_spi_miso;
    end loop;
    fpga_spi_clk <= '1';
    wait for SPIBITTIME;

    assert false report
    "SPI Read : "; -- & to_string(to_bitvector(read_data), "%2x");
    --wait for 1 us;
  end procedure;

  procedure Ena(sel:integer) is
  begin
    case sel is
    --when 0 => fpga_ctrl <= "00";

    when 1 => fpga_ctrl <= "10";
    when 2 => fpga_ctrl <= "01";

    when others => null;
    end case;
  end procedure;

  procedure Dis is
  begin
    fpga_ctrl <= "11";
  end procedure;

  begin
  -- SAM7S CPOL = 1, NCPHA = 0
  -- clock normally high, data change on leading edge of clock, captured on following
  fpga_spi_clk  <= '1';
  fpga_spi_mosi <= '0';

  Dis;

  wait for 1 us;
  Ena(2);
  SPI(x"23"); -- set phase
  SPI(x"68");
  SPI(x"02");
  Dis;
  wait for 5 us;

  -- RESET ----------------------------------------------------------

  Ena(2);
  SPI(x"11"); -- soft reset
  Dis;
  wait for 5 us;

  Ena(1);
  SPI(x"80"); -- command set addr
  SPI(x"10");
  SPI(x"00");
  SPI(x"01");
  SPI(x"00");
  Dis;
  wait for 1 us;

  Ena(1);
  SPI(x"81"); -- command
  SPI(x"00"); -- do write
  Dis;
  wait for 1 us;

  Ena(1);
  SPI(x"B0"); -- command
  SPI(x"01"); -- data
  SPI(x"02"); -- data
  SPI(x"03"); -- data
  SPI(x"04"); -- data
  SPI(x"05"); -- data
  SPI(x"06"); -- data
  SPI(x"07"); -- data
  SPI(x"08"); -- data
  SPI(x"09"); -- data
  SPI(x"0A"); -- data
  SPI(x"0B"); -- data
  SPI(x"0C"); -- data
  SPI(x"0D"); -- data
  SPI(x"0E"); -- data
  SPI(x"0F"); -- data
  SPI(x"10"); -- data
  Dis;
  wait for 10 us;

  Ena(1);
  SPI(x"81"); -- command
  SPI(x"80"); -- set up for read
  Dis;
  wait for 1 us;

  Ena(1);
  SPI(x"80"); -- command
  SPI(x"10"); -- command
  SPI(x"00"); -- command
  SPI(x"01"); -- command
  SPI(x"00"); -- command
  Dis;

  wait for 1 us;
  Ena(1);
  SPI(x"84"); -- command
  SPI(x"0F"); -- do read (word len -1)
  SPI(x"00"); -- do read (word len -1)
  Dis;
  wait for 5 us;

  Ena(1);
  SPI(x"A0"); -- command
  for i in 0 to 15 loop
    SPI(x"00"); -- command
  end loop;
  Dis;

  -- RESET ----------------------------------------------------------

  wait for 10 us;
  Ena(2);
  SPI(x"11"); -- command: soft reset active
  Dis;
  wait for 20 us;
  Ena(2);
  SPI(x"10"); -- command: soft reset off
  Dis;

  -- we check how loading a PRG file works out...

  Ena(1);
  SPI(x"80"); -- command set addr
  SPI(x"00");
  SPI(x"00");
  SPI(x"08");
  SPI(x"00");
  Dis;
  wait for 1 us;

  Ena(1);
  SPI(x"81"); -- command
  SPI(x"00"); -- do write
  Dis;
  wait for 1 us;

  Ena(1);
  SPI(x"B0"); -- command
  SPI(x"00"); -- ADDR L
  SPI(x"A0"); -- ADDR H
  SPI(x"09"); -- data 00
  SPI(x"A0"); -- data 01
  SPI(x"77"); -- data 02
  SPI(x"A0"); -- data 03
  SPI(x"41"); -- data 04
  SPI(x"30"); -- data 05
  SPI(x"C3"); -- data 06
  SPI(x"C2"); -- data 07
  SPI(x"CD"); -- data 08
  SPI(x"A0"); -- data LDY #$80
  SPI(x"80"); -- data
  SPI(x"99"); -- data STA $4000,Y
  SPI(x"00"); -- data
  SPI(x"40"); -- data
  SPI(x"C8"); -- data INY
  SPI(x"D0"); -- data BNE to STA
  SPI(x"FA"); -- data
  SPI(x"A0"); -- data LDY #$80
  SPI(x"80"); -- data
  SPI(x"B9"); -- data LDA $4000,Y
  SPI(x"00"); -- data
  SPI(x"40"); -- data
  SPI(x"C8"); -- data INY
  SPI(x"D0"); -- data BNE to LDA
  SPI(x"FA"); -- data
  SPI(x"4C"); -- data
  SPI(x"2F"); -- data
  SPI(x"FD"); -- data
  Dis;
  wait for 30 us;

  Ena(1);
  SPI(x"81"); -- command
  SPI(x"80"); -- set up for read
  Dis;
  wait for 1 us;

  Ena(1);
  SPI(x"80"); -- addr
  SPI(x"00"); --
  SPI(x"A0"); --
  SPI(x"00"); --
  SPI(x"00"); --
  Dis;

  wait for 1 us;
  Ena(1);
  SPI(x"84"); -- command
  SPI(x"0F"); -- do read (word len -1)
  SPI(x"00"); -- do read (word len -1)
  Dis;
  wait for 5 us;

  Ena(1);
  SPI(x"A0"); -- command
  for i in 0 to 15 loop
    SPI(x"00"); -- command
  end loop;
  Dis;

  -- RESET ----------------------------------------------------------

  wait for 10 us;
  Ena(2);
  SPI(x"11"); -- command: soft reset active
  Dis;
  wait for 20 us;
  Ena(2);
  SPI(x"10"); -- command: soft reset off
  Dis;

  -- we check how loading a BIN file works out... (1541)

  Ena(1);
  SPI(x"80"); -- command set addr
  SPI(x"00");
  SPI(x"80");
  SPI(x"04");
  SPI(x"00");
  Dis;
  wait for 1 us;

  Ena(1);
  SPI(x"81"); -- command
  SPI(x"00"); -- do write
  Dis;
  wait for 1 us;

  Ena(1);
  SPI(x"B0"); -- command
  SPI(x"00"); -- data
  SPI(x"01"); -- data
  SPI(x"02"); -- data
  SPI(x"03"); -- data
  SPI(x"04"); -- data
  SPI(x"05"); -- data
  SPI(x"06"); -- data
  SPI(x"07"); -- data
  SPI(x"08"); -- data
  SPI(x"09"); -- data
  SPI(x"0A"); -- data
  SPI(x"0B"); -- data
  SPI(x"0C"); -- data
  SPI(x"0D"); -- data
  SPI(x"0E"); -- data
  SPI(x"0F"); -- data
  SPI(x"10"); -- data
  Dis;
  wait for 10 us;

  -- we check how loading a BIN file works out... (VIC-20)

  Ena(1);
  SPI(x"80"); -- command set addr
  SPI(x"00");
  SPI(x"80");
  SPI(x"00");
  SPI(x"00");
  Dis;
  wait for 1 us;

  Ena(1);
  SPI(x"81"); -- command
  SPI(x"00"); -- do write
  Dis;
  wait for 1 us;

  Ena(1);
  SPI(x"B0"); -- command
  SPI(x"00"); -- data
  SPI(x"01"); -- data
  SPI(x"02"); -- data
  SPI(x"03"); -- data
  SPI(x"04"); -- data
  SPI(x"05"); -- data
  SPI(x"06"); -- data
  SPI(x"07"); -- data
  SPI(x"08"); -- data
  SPI(x"09"); -- data
  SPI(x"0A"); -- data
  SPI(x"0B"); -- data
  SPI(x"0C"); -- data
  SPI(x"0D"); -- data
  SPI(x"0E"); -- data
  SPI(x"0F"); -- data
  SPI(x"10"); -- data
  Dis;
  wait for 30 us;

  -- RESET ----------------------------------------------------------

  wait for 10 us;
  Ena(2);
  SPI(x"11"); -- command: soft reset active
  Dis;
  wait for 20 us;
  Ena(2);
  SPI(x"10"); -- command: soft reset off
  Dis;

  -- we check how loading a d64 file works out...

  Ena(1);
  SPI(x"80"); -- command set addr
  SPI(x"00");
  SPI(x"00");
  SPI(x"00");
  SPI(x"00");
  Dis;
  wait for 1 us;

  Ena(1);
  SPI(x"81"); -- command
  SPI(x"00"); -- do write
  Dis;
  wait for 1 us;

  Ena(1);
  SPI(x"B0"); -- command
  SPI(x"01"); -- data
  SPI(x"02"); -- data
  SPI(x"03"); -- data
  SPI(x"04"); -- data
  SPI(x"05"); -- data
  SPI(x"06"); -- data
  SPI(x"07"); -- data
  SPI(x"08"); -- data
  SPI(x"09"); -- data
  SPI(x"0A"); -- data
  SPI(x"0B"); -- data
  SPI(x"0C"); -- data
  SPI(x"0D"); -- data
  SPI(x"0E"); -- data
  SPI(x"0F"); -- data
  SPI(x"10"); -- data
  Dis;
  wait for 10 us;

  Ena(1);
  SPI(x"80"); -- command set addr
  SPI(x"A0");
  SPI(x"65");
  SPI(x"01");
  SPI(x"00");
  Dis;
  wait for 1 us;

  Ena(1);
  SPI(x"81"); -- command
  SPI(x"00"); -- do write
  Dis;
  wait for 1 us;

  Ena(1);
  SPI(x"B0"); -- command
  SPI(x"01"); -- data
  SPI(x"02"); -- data
  SPI(x"03"); -- data
  SPI(x"04"); -- data
  SPI(x"05"); -- data
  SPI(x"06"); -- data
  SPI(x"07"); -- data
  SPI(x"08"); -- data
  SPI(x"09"); -- data
  SPI(x"0A"); -- data
  SPI(x"0B"); -- data
  SPI(x"0C"); -- data
  SPI(x"0D"); -- data
  SPI(x"0E"); -- data
  SPI(x"0F"); -- data
  SPI(x"10"); -- data
  Dis;
  wait for 10 us;

  Ena(1);
  SPI(x"80"); -- command set addr
  SPI(x"f0");
  SPI(x"AA");
  SPI(x"02");
  SPI(x"00");
  Dis;
  wait for 1 us;

  Ena(1);
  SPI(x"81"); -- command
  SPI(x"00"); -- do write
  Dis;
  wait for 1 us;

  Ena(1);
  SPI(x"B0"); -- command
  SPI(x"01"); -- data
  SPI(x"02"); -- data
  SPI(x"03"); -- data
  SPI(x"04"); -- data
  SPI(x"05"); -- data
  SPI(x"06"); -- data
  SPI(x"07"); -- data
  SPI(x"08"); -- data
  SPI(x"09"); -- data
  SPI(x"0A"); -- data
  SPI(x"0B"); -- data
  SPI(x"0C"); -- data
  SPI(x"0D"); -- data
  SPI(x"0E"); -- data
  SPI(x"0F"); -- data
  SPI(x"10"); -- data
  Dis;
  wait for 10 us;

  -- do again, check how reload works

  Ena(1);
  SPI(x"80"); -- command set addr
  SPI(x"00");
  SPI(x"00");
  SPI(x"00");
  SPI(x"00");
  Dis;
  wait for 1 us;

  Ena(1);
  SPI(x"81"); -- command
  SPI(x"00"); -- do write
  Dis;
  wait for 1 us;

  Ena(1);
  SPI(x"B0"); -- command
  SPI(x"01"); -- data
  SPI(x"02"); -- data
  SPI(x"03"); -- data
  SPI(x"04"); -- data
  SPI(x"05"); -- data
  SPI(x"06"); -- data
  SPI(x"07"); -- data
  SPI(x"08"); -- data
  SPI(x"09"); -- data
  SPI(x"0A"); -- data
  SPI(x"0B"); -- data
  SPI(x"0C"); -- data
  SPI(x"0D"); -- data
  SPI(x"0E"); -- data
  SPI(x"0F"); -- data
  SPI(x"10"); -- data
  Dis;
  wait for 10 us;

  Ena(1);
  SPI(x"80"); -- command set addr
  SPI(x"A0");
  SPI(x"65");
  SPI(x"01");
  SPI(x"00");
  Dis;
  wait for 1 us;

  Ena(1);
  SPI(x"81"); -- command
  SPI(x"00"); -- do write
  Dis;
  wait for 1 us;

  Ena(1);
  SPI(x"B0"); -- command
  SPI(x"01"); -- data
  SPI(x"02"); -- data
  SPI(x"03"); -- data
  SPI(x"04"); -- data
  SPI(x"05"); -- data
  SPI(x"06"); -- data
  SPI(x"07"); -- data
  SPI(x"08"); -- data
  SPI(x"09"); -- data
  SPI(x"0A"); -- data
  SPI(x"0B"); -- data
  SPI(x"0C"); -- data
  SPI(x"0D"); -- data
  SPI(x"0E"); -- data
  SPI(x"0F"); -- data
  SPI(x"10"); -- data
  Dis;
  wait for 10 us;

  Ena(1);
  SPI(x"80"); -- command set addr
  SPI(x"00");
  SPI(x"26");
  SPI(x"01");
  SPI(x"00");
  Dis;
  wait for 1 us;

  Ena(1);
  SPI(x"81"); -- command
  SPI(x"00"); -- do write
  Dis;
  wait for 1 us;

  Ena(1);
  SPI(x"B0"); -- command
  SPI(x"A1"); -- data
  SPI(x"A2"); -- data
  SPI(x"A3"); -- data
  SPI(x"A4"); -- data
  SPI(x"A5"); -- data
  SPI(x"A6"); -- data
  SPI(x"A7"); -- data
  SPI(x"A8"); -- data
  SPI(x"A9"); -- data
  SPI(x"AA"); -- data
  SPI(x"AB"); -- data
  SPI(x"AC"); -- data
  SPI(x"AD"); -- data
  SPI(x"AE"); -- data
  SPI(x"AF"); -- data
  SPI(x"B0"); -- data
  Dis;
  wait for 10 us;

  wait;
  end process;

  p_ps2 : process

  procedure PS2Write (dst : integer; data:word(7 downto 0)) is
    variable parity : bit1;
  begin
    -- wait for high clock
    while (ps2_clk(dst) = '0') loop
    wait for PS2BITTIME;
    end loop;
    ps2_send_active(dst) <= '1';
    -- start
    ps2_data_drive_tx(dst) <= '0';
    wait for PS2BITTIME/4;
    ps2_clk_drive_tx(dst) <= '0';
    wait for PS2BITTIME/2;
    ps2_clk_drive_tx(dst) <= '1';

    parity := '0';
    for i in 0 to 7 loop
    wait for PS2BITTIME/4;
    if (data(i) = '1') then ps2_data_drive_tx(dst) <= '1'; else ps2_data_drive_tx(dst) <= '0'; end if;
    parity := parity xor data(i);
    wait for PS2BITTIME/4;
    ps2_clk_drive_tx(dst) <= '0';
    wait for PS2BITTIME/2;
    ps2_clk_drive_tx(dst) <= '1';

    if (i=3) then
      wait;
    end if;
    end loop;
    -- parity
    --parity := not parity;
    wait for PS2BITTIME/4;
    if (parity = '0') then ps2_data_drive_tx(dst) <= '1'; else ps2_data_drive_tx(dst) <= '0'; end if;
    wait for PS2BITTIME/4;
    ps2_clk_drive_tx(dst) <= '0';
    wait for PS2BITTIME/2;
    ps2_clk_drive_tx(dst) <= '1';
    -- stop
    wait for PS2BITTIME/4;
    ps2_clk_drive_tx(dst) <= '1';
    wait for PS2BITTIME/4;
    ps2_clk_drive_tx(dst) <= '0';
    wait for PS2BITTIME/2;
    ps2_clk_drive_tx(dst) <= '1';
    ps2_send_active(dst)  <= '0';

  end procedure;

  begin
  ps2_clk_drive_tx(0)  <= '1';
  ps2_data_drive_tx(0) <= '1';
  ps2_clk_drive_tx(1)  <= '1';
  ps2_data_drive_tx(1) <= '1';

  wait for 300 us;

  wait until ps2_slave_rx = '1';

  wait for 100 us;
  PS2Write(0, x"FA");
  wait for 100 us;
  PS2Write(0, x"AA");
  wait for 100 us;
  PS2Write(0, x"00");
  wait for 100 us;
  --PS2Write(0, x"27");

  wait for 1 ms;
  PS2Write(0, x"23");
  wait for 300 us;
  PS2Write(0, x"F0");
  wait for 100 us;
  PS2Write(0, x"23");
  wait for 100 us;
  wait;
  end process;

  ps2_clk_drive_rx(1)  <= '1';
  ps2_data_drive_rx(1) <= '1';

  p_ps2_slave : process
  begin
  wait until falling_edge(ps2_data(0)) and (ps2_send_active(0) = '0');

  ps2_slave_rx <= '0';
----
----  wait;
----
  ps2_clk_drive_rx(0)  <= '1';
  ps2_data_drive_rx(0) <= '1';

  if (ps2_clk(0) = '0') then
    wait for 1 us;
    -- wait for clock to go high
    while (ps2_clk(0) = '0') loop
    wait for PS2BITTIME/2;
    end loop;
    wait for PS2BITTIME/2;

    ps2_clk_drive_rx(0)  <= '0';
    wait for PS2BITTIME/2;

    for i in 0 to 8 loop
    ps2_clk_drive_rx(0)  <= '1';
    wait for PS2BITTIME/2;
    if (ps2_data(0) = '0') then
      ps2_slave_data <= '0' & ps2_slave_data(7 downto 0);
    else
      ps2_slave_data <= '1' & ps2_slave_data(7 downto 0);
    end if;

    ps2_clk_drive_rx(0)  <= '0';
    wait for PS2BITTIME/2;
    end loop;
    ps2_clk_drive_rx(0)  <= '1';
    ps2_data_drive_rx(0) <= '0';
    wait for PS2BITTIME/2;
    ps2_clk_drive_rx(0)  <= '0';

    wait for PS2BITTIME/2;
    ps2_data_drive_rx(0) <= '1';
    ps2_clk_drive_rx(0)  <= '1';
    ps2_slave_rx <= '1';
  end if;
  end process;


  ps2_clk(0)   <= '0' when (ps2_clk_drive_rx(0) = '0')  or (ps2_clk_drive_tx(0)  = '0') else 'H';
  ps2_data(0)  <= '0' when (ps2_data_drive_rx(0) = '0') or (ps2_data_drive_tx(0) = '0') else 'H';
  ps2_clk(1)   <= '0' when (ps2_clk_drive_rx(1) = '0')  or (ps2_clk_drive_tx(1)  = '0') else 'H';
  ps2_data(1)  <= '0' when (ps2_data_drive_rx(1) = '0') or (ps2_data_drive_tx(1) = '0') else 'H';

  u_ram : ddr
  port map (
    DQ     => mem_dq,
    DQS    => mem_dqs,
--    DQS(1) => mem_udqs,
--    DQS(0) => mem_ldqs,
    ADDR   => mem_addr(12 downto  0),
    BA     => mem_addr(14 downto 13),
    CLK    => mem_clk_p,
    CLK_N  => mem_clk_n,
    CKE    => mem_cke,
    CS_N   => mem_cs,
    RAS_N  => mem_ras,
    CAS_N  => mem_cas,
    WE_N   => mem_we,
    DM     => mem_dm
--    DM(1)  => mem_udm,
--    DM(0)  => mem_ldm
  );

end;
