---------------------------------------------------------------------------
-- (c) 2015 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_MISC.all;

LIBRARY work;

-- Return to the spi boot core
-- Could also be the basis of a boot menu...
ENTITY delayed_reconfig IS 
	PORT
	(
		CLK_5MHZ :  IN  STD_LOGIC;
		RESET_N :  IN  STD_LOGIC;

		RECONFIG_BUTTON :  IN  STD_LOGIC

	);
END delayed_reconfig;

ARCHITECTURE altera OF delayed_reconfig IS 

	-- return to menu
	signal reconfig_trigger : std_logic;
	signal reconfig_delayed : std_logic;
	signal reconfig_count_next : std_logic_vector(24 downto 0);
	signal reconfig_count_reg : std_logic_vector(24 downto 0);

BEGIN

-- Return to the boot menu
remote: entity work.remote_update_rmtupdt_51n 
	 PORT MAP
	 (
		 busy	=> open,
		 clock => CLK_5MHZ,
		 data_in	=> (others=>'0'),
		 data_out => open,
		 param => (others=>'0'),
		 reconfig => reconfig_delayed,
		 reset => not(reset_n),
		 write_param => '0'
	 ); 

reboot_synchronizer : entity work.synchronizer
	port map (clk=>CLK_5MHZ, raw=>reconfig_button, sync=>reconfig_trigger);	

process(CLK_5MHZ,reset_n)
begin
	if (reset_n='0') then
		reconfig_count_reg <= (others=>'1');
	elsif (CLK_5MHZ'event and CLK_5MHZ = '1') then
		reconfig_count_reg <= reconfig_count_next;
	end if;
end process;

process(reconfig_count_reg,reconfig_trigger)
begin
	reconfig_count_next <= std_logic_vector(unsigned(reconfig_count_reg)-1);

	if (reconfig_trigger = '0') then
		reconfig_count_next <= "1011111010111100001000000";
	end if;

	reconfig_delayed <= not(or_reduce(reconfig_count_reg));
end process;

	 -- write to param 4 -> 0x00050000 (NOT REQUIRED)
	 -- write to param 3 -> 0 (MAYBE? WORKS WITHOUT, BUT WILL I GET SPURIOUS REBOOTS?)
	 -- raise reconfig high (YIPPEE!)
	 
END altera;

