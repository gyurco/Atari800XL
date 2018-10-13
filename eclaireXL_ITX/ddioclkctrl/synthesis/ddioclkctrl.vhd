-- ddioclkctrl.vhd

-- Generated using ACDS version 16.1 196

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ddioclkctrl is
	port (
		inclk3x   : in  std_logic                    := '0';             --  altclkctrl_input.inclk3x
		inclk2x   : in  std_logic                    := '0';             --                  .inclk2x
		inclk1x   : in  std_logic                    := '0';             --                  .inclk1x
		inclk0x   : in  std_logic                    := '0';             --                  .inclk0x
		clkselect : in  std_logic_vector(1 downto 0) := (others => '0'); --                  .clkselect
		ena       : in  std_logic                    := '0';             --                  .ena
		outclk    : out std_logic                                        -- altclkctrl_output.outclk
	);
end entity ddioclkctrl;

architecture rtl of ddioclkctrl is
	component ddioclkctrl_altclkctrl_0 is
		port (
			inclk3x   : in  std_logic                    := 'X';             -- inclk3x
			inclk2x   : in  std_logic                    := 'X';             -- inclk2x
			inclk1x   : in  std_logic                    := 'X';             -- inclk1x
			inclk0x   : in  std_logic                    := 'X';             -- inclk0x
			clkselect : in  std_logic_vector(1 downto 0) := (others => 'X'); -- clkselect
			ena       : in  std_logic                    := 'X';             -- ena
			outclk    : out std_logic                                        -- outclk
		);
	end component ddioclkctrl_altclkctrl_0;

begin

	altclkctrl_0 : component ddioclkctrl_altclkctrl_0
		port map (
			inclk3x   => inclk3x,   --  altclkctrl_input.inclk3x
			inclk2x   => inclk2x,   --                  .inclk2x
			inclk1x   => inclk1x,   --                  .inclk1x
			inclk0x   => inclk0x,   --                  .inclk0x
			clkselect => clkselect, --                  .clkselect
			ena       => ena,       --                  .ena
			outclk    => outclk     -- altclkctrl_output.outclk
		);

end architecture rtl; -- of ddioclkctrl