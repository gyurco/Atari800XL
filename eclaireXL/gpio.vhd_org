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

entity gpio is
generic
(
	cartridge_cycle_length : in integer := 32
);
port
(
	clk : in std_logic;
	reset_n : in std_logic;
	
	gpio_enable : in std_logic;

	-- pia
	porta_in : out std_logic_vector(7 downto 0);
	porta_out : in std_logic_vector(7 downto 0);
	porta_output : in std_logic_vector(7 downto 0);
	CA2_DIR_OUT : IN std_logic;
	CA2_OUT : IN std_logic;
	CA2_IN : OUT STD_LOGIC;
	CB2_DIR_OUT : IN std_logic;
	CB2_OUT : IN std_logic;
	CB2_IN : OUT STD_LOGIC;
	
	-- gtia
	trig_in : out std_logic_vector(3 downto 0);
	
	-- antic
	lightpen : out std_logic;
	
	-- pokey
	pot_reset : in std_logic;
	pot_in : out std_logic_vector(7 downto 0);
	keyboard_scan : in std_logic_vector(5 downto 0);
	keyboard_response : out std_logic_vector(1 downto 0);
	SIO_IN : OUT STD_LOGIC;
	SIO_OUT : IN STD_LOGIC;
	
	-- cartridge
	enable_179_early : in std_logic;
	pbi_addr_out : in std_logic_vector(15 downto 0);
	pbi_write_enable : in std_logic;
	cart_data_read : out std_logic_vector(7 downto 0);
	cart_request : in std_logic;
	cart_complete : out std_logic;
	cart_data_write : in std_logic_vector(7 downto 0);
	rd4 : out std_logic;
	rd5 : out std_logic;
	s4_n : in std_logic;
	s5_n : in std_logic;
	cctl_n : in std_logic;
	
	-- gpio connections
	GPIO_0_IN : in std_logic_vector(35 downto 0);
	GPIO_0_OUT : out std_logic_vector(35 downto 0);
	GPIO_0_DIR_OUT : out std_logic_vector(35 downto 0);
	GPIO_1_IN : in std_logic_vector(35 downto 0);
	GPIO_1_OUT : out std_logic_vector(35 downto 0);
	GPIO_1_DIR_OUT : out std_logic_vector(35 downto 0)
);
end gpio;

architecture vhdl of gpio is
	component synchronizer IS
	PORT 
	( 
		CLK : IN STD_LOGIC;
		RAW : IN STD_LOGIC;
		SYNC : OUT STD_LOGIC
	);
	END component;
	
	signal pot_in_async : std_logic_vector(7 downto 0);
	signal porta_in_async : std_logic_vector(7 downto 0);
	signal trig_in_async : std_logic_vector(3 downto 0);
	signal trig_in_sync : std_logic_vector(3 downto 0);
	
	signal bus_data_in : std_logic_vector(7 downto 0);
	signal bus_data_out : std_logic_vector(7 downto 0);
	signal bus_data_oe : std_logic;
	signal bus_addr_out : std_logic_vector(15 downto 0);
	signal bus_addr_oe : std_logic;
	signal bus_write_n : std_logic;
	signal bus_s4_n : std_logic;
	signal bus_s5_n : std_logic;
	signal bus_cctl_n : std_logic;
	signal bus_control_oe : std_logic;
	signal phi2 : std_logic;

	signal rd4_async : std_logic;
	signal rd5_async : std_logic;	

	signal keyboard_response_async : std_logic_vector(1 downto 0);
	signal keyboard_response_gpio : std_logic_vector(1 downto 0);
	
	signal porta_in_gpio : std_logic_vector(7 downto 0);
begin	
-- OUTPUTS TO GPIO
	-- unused
	GPIO_1_DIR_OUT(18 downto 8) <= (others=>'0');
	GPIO_1_OUT(18 downto 8) <= (others=>'0');
	
	-- sio
	GPIO_0_DIR_OUT(0) <= CA2_dir_out;
	GPIO_0_OUT(0) <= CA2_out;
	GPIO_0_DIR_OUT(1) <= CB2_dir_out;
	GPIO_0_OUT(1) <= CB2_out;
	GPIO_0_DIR_OUT(2) <= '1';
	GPIO_0_OUT(2) <= SIO_OUT;
	GPIO_0_DIR_OUT(3) <= '0';
	GPIO_0_OUT(3) <= '0';
	
	GPIO_0_DIR_OUT(4) <= 'Z';
	GPIO_0_OUT(4) <= '0'; -- zpu output for logic analyzer
	
	CA2_in <= GPIO_0_IN(0);
	CB2_in <= GPIO_0_IN(1);
	SIO_IN <= GPIO_0_IN(3);
	
	-- sticks
	GPIO_1_OUT(35 downto 19) <= (others=>'0');
	GPIO_1_DIR_OUT(35) <= '0'; -- trig 0
	GPIO_1_DIR_OUT(34) <= gpio_enable and porta_output(0) and not(porta_out(0)); -- stick 0
	GPIO_1_DIR_OUT(33) <= '0';
	GPIO_1_DIR_OUT(32) <= gpio_enable and porta_output(1) and not(porta_out(1)); -- stick 0
	GPIO_1_DIR_OUT(31) <= '0';
	GPIO_1_DIR_OUT(30) <= gpio_enable and porta_output(2) and not(porta_out(2)); -- stick 0
	GPIO_1_DIR_OUT(29) <= gpio_enable and pot_reset;
	GPIO_1_DIR_OUT(28) <= gpio_enable and porta_output(3) and not(porta_out(3)); -- stick 0
	GPIO_1_DIR_OUT(27) <= gpio_enable and pot_reset;
	GPIO_1_DIR_OUT(26) <= gpio_enable and pot_reset;
	GPIO_1_DIR_OUT(25) <= '0'; -- trig 1
	GPIO_1_DIR_OUT(24) <= gpio_enable and porta_output(4) and not(porta_out(4)); -- stick 1
	GPIO_1_DIR_OUT(23) <= gpio_enable and porta_output(7) and not(porta_out(7)); -- stick 1
	GPIO_1_DIR_OUT(22) <= gpio_enable and porta_output(5) and not(porta_out(5)); -- stick 1
	GPIO_1_DIR_OUT(21) <= gpio_enable and pot_reset;
	GPIO_1_DIR_OUT(20) <= gpio_enable and porta_output(6) and not(porta_out(6)); -- stick 1
	GPIO_1_DIR_OUT(19 downto 8) <= (others=>'0');
	
	-- keyboard
	GPIO_1_OUT(7 downto 0) <= (others=>'0');
	GPIO_1_DIR_OUT(7) <= '0'; -- keyboard response 2
	GPIO_1_DIR_OUT(6) <= '0'; -- keyboard response 1
	GPIO_1_DIR_OUT(5) <= gpio_enable and not(keyboard_scan(5)); -- keyboard scan 5
	GPIO_1_DIR_OUT(4) <= gpio_enable and not(keyboard_scan(4)); -- keyboard scan 4
	GPIO_1_DIR_OUT(3) <= gpio_enable and not(keyboard_scan(3)); -- keyboard scan 3
	GPIO_1_DIR_OUT(2) <= gpio_enable and not(keyboard_scan(2)); -- keyboard scan 2
	GPIO_1_DIR_OUT(1) <= gpio_enable and not(keyboard_scan(1)); -- keyboard scan 1
	GPIO_1_DIR_OUT(0) <= gpio_enable and not(keyboard_scan(0)); -- keyboard scan 0
	
	-- cart
	GPIO_0_DIR_OUT(35) <= '1';
	GPIO_0_OUT(35) <= phi2;
	GPIO_0_DIR_OUT(34) <= gpio_enable; 
	GPIO_0_OUT(34) <= bus_write_n; 
	GPIO_0_DIR_OUT(33) <= gpio_enable and bus_addr_oe;
	GPIO_0_OUT(33) <= bus_addr_out(10);
	GPIO_0_DIR_OUT(32) <= gpio_enable and bus_addr_oe;
	GPIO_0_OUT(32) <= bus_addr_out(11);
	GPIO_0_DIR_OUT(31) <= gpio_enable and bus_data_oe; -- d7
	GPIO_0_OUT(31) <= bus_data_out(7); -- d7
	GPIO_0_DIR_OUT(30) <= gpio_enable and bus_data_oe; -- d3
	GPIO_0_OUT(30) <= bus_data_out(3); -- d3
	GPIO_0_DIR_OUT(29) <= gpio_enable and bus_addr_oe;
	GPIO_0_OUT(29) <= bus_addr_out(12);
	GPIO_0_DIR_OUT(28) <= gpio_enable and bus_addr_oe;
	GPIO_0_OUT(28) <= bus_addr_out(9);
	GPIO_0_DIR_OUT(27) <= gpio_enable and bus_addr_oe;
	GPIO_0_OUT(27) <= bus_addr_out(8);
	GPIO_0_DIR_OUT(26) <= gpio_enable and bus_addr_oe;
	GPIO_0_OUT(26) <= bus_addr_out(7);
	GPIO_0_DIR_OUT(25) <= gpio_enable and bus_addr_oe;
	GPIO_0_OUT(25) <= bus_addr_out(6);
	GPIO_0_DIR_OUT(24) <= gpio_enable and bus_addr_oe;
	GPIO_0_OUT(24) <= bus_addr_out(5);
	GPIO_0_DIR_OUT(23) <= gpio_enable and bus_addr_oe;
	GPIO_0_OUT(23) <= bus_addr_out(4);
	GPIO_0_DIR_OUT(22) <= '0'; -- RD4 rom present
	GPIO_0_OUT(22) <= '0'; -- RD4 rom present
	GPIO_0_DIR_OUT(21) <= gpio_enable and bus_control_oe;
	GPIO_0_OUT(21) <= bus_s4_n;
	GPIO_0_DIR_OUT(20) <= gpio_enable and bus_addr_oe;
	GPIO_0_OUT(20) <= bus_addr_out(3);
	GPIO_0_DIR_OUT(19) <= gpio_enable and bus_addr_oe;
	GPIO_0_OUT(19) <= bus_addr_out(2);
	GPIO_0_DIR_OUT(18) <= gpio_enable and bus_addr_oe;
	GPIO_0_OUT(18) <= bus_addr_out(1);
	GPIO_0_DIR_OUT(17) <= gpio_enable and bus_addr_oe;
	GPIO_0_OUT(17) <= bus_addr_out(0);
	GPIO_0_DIR_OUT(16) <= gpio_enable and bus_data_oe; -- d4
	GPIO_0_OUT(16) <= bus_data_out(4); -- d4
	GPIO_0_DIR_OUT(15) <= gpio_enable and bus_data_oe; -- d5
	GPIO_0_OUT(15) <= bus_data_out(5); -- d5
	GPIO_0_DIR_OUT(14) <= gpio_enable and bus_data_oe; -- d2
	GPIO_0_OUT(14) <= bus_data_out(2); -- d2
	GPIO_0_DIR_OUT(13) <= gpio_enable and bus_data_oe; -- d1
	GPIO_0_OUT(13) <= bus_data_out(1); -- d1
	GPIO_0_DIR_OUT(12) <= gpio_enable and bus_data_oe; -- d0
	GPIO_0_OUT(12) <= bus_data_out(0); -- d0
	GPIO_0_DIR_OUT(11) <= gpio_enable and bus_data_oe; -- d6
	GPIO_0_OUT(11) <= bus_data_out(6); -- d6
	GPIO_0_DIR_OUT(10) <= gpio_enable and bus_control_oe;
	GPIO_0_OUT(10) <= bus_s5_n;
	GPIO_0_DIR_OUT(9) <= '0'; -- RD5 rom present
	GPIO_0_OUT(9) <= '0'; -- RD5 rom present
	GPIO_0_DIR_OUT(8) <= gpio_enable and bus_control_oe; -- cart control
	GPIO_0_OUT(8) <= bus_cctl_n; -- cart control

-- PBI: A13-A15
	GPIO_0_DIR_OUT(7) <= gpio_enable and bus_addr_oe;
	GPIO_0_OUT(7) <= bus_addr_out(15);
	GPIO_0_DIR_OUT(6) <= gpio_enable and bus_addr_oe;
	GPIO_0_OUT(6) <= bus_addr_out(14);
	GPIO_0_DIR_OUT(5) <= gpio_enable and bus_addr_oe;
	GPIO_0_OUT(5) <= bus_addr_out(13);
	
-- INPUTS FROM GPIO	
	-- sticks
	pot_in_async <= 
					gpio_enable&gpio_enable&gpio_enable&gpio_enable&gpio_enable&gpio_enable&gpio_enable&gpio_enable and 
					("0000"&
					GPIO_1_IN(27)&GPIO_1_IN(21)& -- 32/24
					GPIO_1_IN(26)&GPIO_1_IN(29)); -- 31/34
	pot_in0_synchronizer : synchronizer
		port map (clk=>clk, raw=>pot_in_async(0), sync=>pot_in(0));						
	pot_in1_synchronizer : synchronizer
		port map (clk=>clk, raw=>pot_in_async(1), sync=>pot_in(1));						
	pot_in2_synchronizer : synchronizer
		port map (clk=>clk, raw=>pot_in_async(2), sync=>pot_in(2));						
	pot_in3_synchronizer : synchronizer
		port map (clk=>clk, raw=>pot_in_async(3), sync=>pot_in(3));							
	pot_in4_synchronizer : synchronizer
		port map (clk=>clk, raw=>pot_in_async(4), sync=>pot_in(4));						
	pot_in5_synchronizer : synchronizer
		port map (clk=>clk, raw=>pot_in_async(5), sync=>pot_in(5));						
	pot_in6_synchronizer : synchronizer
		port map (clk=>clk, raw=>pot_in_async(6), sync=>pot_in(6));						
	pot_in7_synchronizer : synchronizer
		port map (clk=>clk, raw=>pot_in_async(7), sync=>pot_in(7));								
		
--	porta_in_async <= 
--					not(gpio_enable&gpio_enable&gpio_enable&gpio_enable&gpio_enable&gpio_enable&gpio_enable&gpio_enable) or 
--					GPIO_1_IN(23)&GPIO_1_IN(20)&GPIO_1_IN(22)&GPIO_1_IN(24)& -- 27/25/23/26
--					GPIO_1_IN(28)&GPIO_1_IN(30)&GPIO_1_IN(32)&GPIO_1_IN(34); -- 39/37/35/33
	porta_in_async <= 
					GPIO_1_IN(23)&GPIO_1_IN(20)&GPIO_1_IN(22)&GPIO_1_IN(24)& -- 27/25/23/26
					GPIO_1_IN(28)&GPIO_1_IN(30)&GPIO_1_IN(32)&GPIO_1_IN(34); -- 39/37/35/33					
	porta_in0_synchronizer : synchronizer
		port map (clk=>clk, raw=>porta_in_async(0), sync=>porta_in_gpio(0));						
	porta_in1_synchronizer : synchronizer
		port map (clk=>clk, raw=>porta_in_async(1), sync=>porta_in_gpio(1));						
	porta_in2_synchronizer : synchronizer
		port map (clk=>clk, raw=>porta_in_async(2), sync=>porta_in_gpio(2));						
	porta_in3_synchronizer : synchronizer
		port map (clk=>clk, raw=>porta_in_async(3), sync=>porta_in_gpio(3));						
	porta_in4_synchronizer : synchronizer
		port map (clk=>clk, raw=>porta_in_async(4), sync=>porta_in_gpio(4));						
	porta_in5_synchronizer : synchronizer
		port map (clk=>clk, raw=>porta_in_async(5), sync=>porta_in_gpio(5));						
	porta_in6_synchronizer : synchronizer
		port map (clk=>clk, raw=>porta_in_async(6), sync=>porta_in_gpio(6));						
	porta_in7_synchronizer : synchronizer
		port map (clk=>clk, raw=>porta_in_async(7), sync=>porta_in_gpio(7));
		
	porta_in(7 downto 4) <= porta_in_gpio(7 downto 4);
	porta_in(3 downto 0) <= porta_in_gpio(3 downto 0);
		
	trig_in_async <= (not(gpio_enable&gpio_enable&"11") or (rd5_async&"1"&GPIO_1_IN(25)&GPIO_1_IN(35)));	-- 28/40
	trig_in0_synchronizer : synchronizer
		port map (clk=>clk, raw=>trig_in_async(0), sync=>trig_in_sync(0));							
	trig_in1_synchronizer : synchronizer
		port map (clk=>clk, raw=>trig_in_async(1), sync=>trig_in_sync(1));							
	trig_in2_synchronizer : synchronizer
		port map (clk=>clk, raw=>trig_in_async(2), sync=>trig_in_sync(2));							
	trig_in3_synchronizer : synchronizer
		port map (clk=>clk, raw=>trig_in_async(3), sync=>trig_in_sync(3));		

	trig_in <= trig_in_sync;
		
	lightpen <= trig_in_sync(0) and trig_in_sync(1); -- either joystick button				
	
	-- keyboard
	keyboard_response_async <= not(gpio_enable&gpio_enable) or (GPIO_1_IN(7)& GPIO_1_IN(6));
	keyboard_response1_synchronizer : synchronizer
		port map (clk=>clk, raw=>keyboard_response_async(0), sync=>keyboard_response_gpio(0));						
	keyboard_response2_synchronizer : synchronizer
		port map (clk=>clk, raw=>keyboard_response_async(1), sync=>keyboard_response_gpio(1));			
		
	keyboard_response <= keyboard_response_gpio;
	
	-- cartridge
--	 1(21). S4' Chip Select--$8000 to $9FFF  A(22). RD4 ROM present--$8000 to $9FFF
-- 2(20). A3 CPU Address bus line          B(GND). GND Ground
-- 3(19). A2 CPU Address bus line          C(23). A4 CPU Address bus line
-- 4(18). A1 CPU Address bus line          D(24). A5 CPU Address bus line
-- 5(17). A0 CPU Address bus line          E(25). A6 CPU Address bus line
-- 6(16). D4 CPU Data bus line             F(26). A7 CPU Address bus line
-- 7(15). D5 CPU Data bus line             H(27). A8 CPU Address bus line
-- 8(14). D2 CPU Data bus line             J(28). A9 CPU Address bus line
-- 9(13). D1 CPU Data bus line             K(29). A12 CPU Address bus line
--10(12). D0 CPU Data bus line             L(30). D3 CPU Data bus line
--11(11). D6 CPU Data bus line             M(31). D7 CPU Data bus line
--12(10). S5' Chip Select--$A000 to $BFFF  N(32). A11 CPU Address bus line
--13(5V). +5V                              P(33). A10 CPU Address bus line
--14(9). RD5 ROM present--$A000 to $BFFF  R(34). R/W' CPU read/write
--15(8). CCTL' Cartridge control select   S(35). B02,Phi2 CPU Phase 2 clock

	-- S4'/S5' - chip select
	-- CTTL' - control select
	-- R/W'
	-- clock (not needed for rom?)
	-- RD5 ROM present (in)
	-- RD4 ROM present (in)


bus_adaptor : ENTITY work.timing6502
GENERIC MAP
(
	CYCLE_LENGTH => cartridge_cycle_length,
	CONTROl_BITS => 3
)
PORT MAP
( 
	CLK => clk,
	RESET_N => reset_n,

	-- FPGA side
	ENABLE_179_EARLY =>enable_179_early,

	REQUEST => cart_request,
	ADDR_IN => pbi_addr_out,
	DATA_IN => cart_data_write,
	WRITE_IN => pbi_write_enable,
	CONTROL_N_IN => s4_n&s5_n&cctl_n,

	DATA_OUT => cart_data_read,
	COMPLETE => cart_complete,

	-- 6502 side
	BUS_DATA_IN => bus_data_in,
	
	BUS_PHI1 => open,
	BUS_PHI2 => phi2,
	BUS_SUBCYCLE => open,
	BUS_ADDR_OUT => bus_addr_out,
	BUS_ADDR_OE => bus_addr_oe,
	BUS_DATA_OUT => bus_data_out,
	BUS_DATA_OE => bus_data_oe,
	BUS_WRITE_N => bus_write_n,
	BUS_CONTROL_N(2) => bus_s4_n,
	BUS_CONTROL_N(1) => bus_s5_n,
	BUS_CONTROL_N(0) => bus_cctl_n,
	BUS_CONTROL_OE => bus_control_oe
);

	rd4_async <= gpio_enable and GPIO_0_IN(22);
	cart_rd4_synchronizer : synchronizer
		port map (clk=>clk, raw=>rd4_async, sync=>rd4);							
	rd5_async <= gpio_enable and GPIO_0_IN(9);
	cart_rd5_synchronizer : synchronizer
		port map (clk=>clk, raw=>rd5_async, sync=>rd5);							
	
	bus_data_in <= GPIO_0_IN(31)&GPIO_0_IN(11)&GPIO_0_IN(15)&GPIO_0_IN(16)&GPIO_0_IN(30)&GPIO_0_IN(14)&GPIO_0_IN(13)&GPIO_0_IN(12);	
--	cart_data0_synchronizer : synchronizer
--		port map (clk=>clk, raw=>cart_data_read_async(0), sync=>cart_data_read(0));							
--	cart_data1_synchronizer : synchronizer
--		port map (clk=>clk, raw=>cart_data_read_async(1), sync=>cart_data_read(1));							
--	cart_data2_synchronizer : synchronizer
--		port map (clk=>clk, raw=>cart_data_read_async(2), sync=>cart_data_read(2));							
--	cart_data3_synchronizer : synchronizer
--		port map (clk=>clk, raw=>cart_data_read_async(3), sync=>cart_data_read(3));	
--	cart_data4_synchronizer : synchronizer
--		port map (clk=>clk, raw=>cart_data_read_async(4), sync=>cart_data_read(4));							
--	cart_data5_synchronizer : synchronizer
--		port map (clk=>clk, raw=>cart_data_read_async(5), sync=>cart_data_read(5));							
--	cart_data6_synchronizer : synchronizer
--		port map (clk=>clk, raw=>cart_data_read_async(6), sync=>cart_data_read(6));							
--	cart_data7_synchronizer : synchronizer
--		port map (clk=>clk, raw=>cart_data_read_async(7), sync=>cart_data_read(7));
		
	--GPIO_1(25) <= GPIO_1(29);
	
--40	35
--39	34
--38	33
--37	32
--36	31
--35	30
--34	29
--33	28
--32	27
--31	26
--30	GND
--29	3.3V
--28	25
--27	24
--26	23
--25	22
--24	21
--23	20
--22	19
--21	18
--20	17
--19	16
--18	15
--17	14
--16	13
--15	12
--14	11
--13	10
--12	GND
--11	5V
--10	9
--9	8
--8	7
--7	6
--6	5
--5	4
--4	3
--3	2
--2	1
--1	0

end vhdl;


