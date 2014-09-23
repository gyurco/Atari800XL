---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
ENTITY sync_switches IS
PORT ( 
	CLK : IN STD_LOGIC;

	SW : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
	KEY : IN STD_LOGIC_VECTOR(3 downto 0);
	
	SYNC_KEYS : out std_logic_vector(3 downto 0);
	SYNC_SWITCHES : out std_logic_vector(9 downto 0)
); 
END sync_switches;

ARCHITECTURE Behavior OF sync_switches IS
	component synchronizer IS
	PORT 
	( 
		CLK : IN STD_LOGIC;
		RAW : IN STD_LOGIC;
		SYNC : OUT STD_LOGIC
	);
	END component;
		
	signal sw_reg : std_logic_vector(9 downto 0);
	signal key_reg : std_logic_vector(3 downto 0);
	
BEGIN
	sw9_synchronizer : synchronizer
		port map (clk=>clk, raw=>sw(9), sync=>sw_reg(9));	
	sw8_synchronizer : synchronizer
		port map (clk=>clk, raw=>sw(8), sync=>sw_reg(8));	
	sw7_synchronizer : synchronizer
		port map (clk=>clk, raw=>sw(7), sync=>sw_reg(7));	
	sw6_synchronizer : synchronizer
		port map (clk=>clk, raw=>sw(6), sync=>sw_reg(6));	
	sw5_synchronizer : synchronizer
		port map (clk=>clk, raw=>sw(5), sync=>sw_reg(5));			
	sw4_synchronizer : synchronizer
		port map (clk=>clk, raw=>sw(4), sync=>sw_reg(4));	
	sw3_synchronizer : synchronizer
		port map (clk=>clk, raw=>sw(3), sync=>sw_reg(3));	
	sw2_synchronizer : synchronizer
		port map (clk=>clk, raw=>sw(2), sync=>sw_reg(2));	
	sw1_synchronizer : synchronizer
		port map (clk=>clk, raw=>sw(1), sync=>sw_reg(1));	
	sw0_synchronizer : synchronizer
		port map (clk=>clk, raw=>sw(0), sync=>sw_reg(0));			

	key3_synchronizer : synchronizer
		port map (clk=>clk, raw=>not(key(3)), sync=>key_reg(3));	
	key2_synchronizer : synchronizer
		port map (clk=>clk, raw=>not(key(2)), sync=>key_reg(2));	
	key1_synchronizer : synchronizer
		port map (clk=>clk, raw=>not(key(1)), sync=>key_reg(1));	
	key0_synchronizer : synchronizer
		port map (clk=>clk, raw=>not(key(0)), sync=>key_reg(0));			
	
	-- outputs
	SYNC_KEYS <= key_reg(3)&key_reg(2)&key_reg(1)&key_reg(0);
	SYNC_SWITCHES <= sw_reg(9)&sw_reg(8)&sw_reg(7)&sw_reg(6)&sw_reg(5)&sw_reg(4)&sw_reg(3)&sw_reg(2)&sw_reg(1)&sw_reg(0);
END Behavior;
