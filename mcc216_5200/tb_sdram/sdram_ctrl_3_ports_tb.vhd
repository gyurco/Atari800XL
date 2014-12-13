library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_textio.all;

library std_developerskit ; -- used for to_string
--  use std_developerskit.std_iopak.all;

entity sdram_ctrl_3_ports_tb is
end;

architecture rtl of sdram_ctrl_3_ports_tb is

  constant CLK_A_PERIOD : time := 1 us / (1.79*32);

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

  signal CLK_A : std_logic;

  signal reset_n : std_logic;
  signal reset : std_logic;

  signal sdram_rdy : std_logic;
  signal sdram_cs_n : std_logic;
  signal sdram_ras_n : std_logic;
  signal sdram_cas_n : std_logic;
  signal sdram_we_n : std_logic;
  signal sdram_dqm_n : std_logic_vector(1 downto 0);
  signal sdram_ba : std_logic_vector(1 downto 0);
  signal sdram_addr : std_logic_vector(11 downto 0);
  signal sdram_dq_oe : std_logic;
  signal sdram_dq_o : std_logic_vector(15 downto 0);
  signal sdram_dq_i : std_logic_vector(15 downto 0);
	
  signal ram_address : std_logic_vector(23 downto 0);
  signal ram_read : std_logic_vector(2 downto 0);
  signal ram_write : std_logic_vector(2 downto 0);
  signal ram_do : std_logic_vector(15 downto 0);
  signal ram_do2 : std_logic_vector(15 downto 0);
  signal ram_di : std_logic_vector(15 downto 0);
  signal ram_di2 : std_logic_vector(15 downto 0);
  signal ram_rd_active : std_logic_vector(2 downto 0);
  signal ram_wr_active : std_logic_vector(2 downto 0);

  signal seq_reg : std_logic_vector(11 downto 0);
  signal seq_next : std_logic_vector(11 downto 0);

  signal seq_ph_reg : std_logic;
  signal seq_ph_next : std_logic;

  signal ref_reg : std_logic;
  signal ref_next : std_logic;

begin
	p_clk_gen_a : process
	begin
	clk_a <= '1';
	wait for CLK_A_PERIOD/2;
	clk_a <= '0';
	wait for CLK_A_PERIOD - (CLK_A_PERIOD/2 );
	end process;

	reset_n <= '0', '1' after 1000ns;

	reset <= not(reset_n);

	ram_address <= X"123456";
	ram_read <= "010";
	ram_write <= "001";
	ram_di <= X"f00"&seq_reg(3 downto 0);
	ram_di2 <= X"abc"&seq_reg(3 downto 0);

	process(clk_a,reset_n)
	begin
		if (reset_n='0') then
			seq_reg <= "000000000001";
			seq_ph_reg <= '0';
			ref_reg <= '0';
		elsif (clk_a'event and clk_a = '1') then
			seq_reg <= seq_next;
			seq_ph_reg <= seq_ph_next;
			ref_reg <= ref_next;
		end if;
	end process;

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

sdram_controller : sdram_ctrl
	PORT MAP
	(
		CLK => clk_a,
		rst => reset,
		seq_cyc => seq_reg(11 downto 0),
		seq_ph => seq_ph_reg,
		refr_cyc => '0', -- TODO - try toggling refresh...

		ap1_ram_sel => '1',
		ap1_address => ram_address(23 downto 1),
		ap1_rden => ram_read(0),
		ap1_wren => ram_write(0),
		ap1_bena => "01",
		ap1_rddata => ram_do,
		ap1_wrdata => ram_di,
		ap1_bst_siz => "010",
		ap1_rd_bst_act => ram_rd_active(0),
		ap1_wr_bst_act => ram_wr_active(0),

		ap2_ram_sel => '1',
		ap2_address => ram_address(23 downto 1),
		ap2_rden => ram_read(1),
		ap2_wren => ram_write(1),
		ap2_bena => "11",
		ap2_rddata => ram_do2,
		ap2_wrdata => ram_di2,
		ap2_bst_siz => "111",
		ap2_rd_bst_act => ram_rd_active(1),
		ap2_wr_bst_act => ram_wr_active(1),

		ap3_ram_sel => '0',
		ap3_address => ram_address(23 downto 1),
		ap3_rden => '0',
		ap3_wren => '0',
		ap3_bena => "11",
		ap3_rddata => open,
		ap3_wrdata => X"0000",
		ap3_bst_siz => "111",
		ap3_rd_bst_act => ram_rd_active(2),
		ap3_wr_bst_act => ram_wr_active(2),

		sdram_rdy => sdram_rdy,
		sdram_cs_n => sdram_cs_n,
		sdram_ras_n => sdram_ras_n,
		sdram_cas_n => sdram_cas_n,
		sdram_we_n => sdram_we_n,
		sdram_dqm_n => sdram_dqm_n,
		sdram_ba => sdram_ba,
		sdram_addr => sdram_addr,
		sdram_dq_oe => sdram_dq_oe,
		sdram_dq_o => sdram_dq_o,
		sdram_dq_i => sdram_dq_i
	);

sdram_dq_i <= X"d"&seq_reg(11 downto 0);

end rtl;

