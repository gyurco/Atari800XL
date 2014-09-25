
--===============================================================================
---USB_DRVR Entity (Drives and Reads D+ and D- lines to send and receive packets)
--===============================================================================
-- USB Driver - Copywrite Hakim Haddadi arcade retro gaming.
--------------------------------------------------
--==============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.USBF_Declares.all;

--------------------------------------------------
entity USB_DRVR1 is
  port(                                 
    clk_usb       : in    std_logic;    -- 5MHz clock
	 pll_lock		: in    std_logic;
    reset         : in    std_logic;    -- fpga reset
    dminus        : inout std_logic;    -- USB differential D+ line
    dplus         : inout std_logic;    -- USB differential D+ line
	 joyright_out 	: out   std_logic_vector(7 downto 0);
	 joyleft_out 	: out   std_logic_vector(7 downto 0);
	 mousex_out		: out   std_logic_vector(11 downto 0);
	 mousey_out		: out   std_logic_vector(11 downto 0)
    );
end USB_DRVR1;
---------------------------------------------------

architecture arch of USB_DRVR1 is
------------------------

component sub_pll IS
	PORT
	(
		areset		: IN STD_LOGIC  := '0';
		inclk0		: IN STD_LOGIC  := '0';
		c0				: OUT STD_LOGIC ;
		locked		: OUT STD_LOGIC 
	);
END component sub_pll;

component rom_com1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		clock			: IN STD_LOGIC  := '1';
		rden			: IN STD_LOGIC  := '1';
		q				: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END component rom_com1;
 
  signal dp_last, dp_prev, dp1_last,dm1_last    : std_logic;
  signal nb_bits                 : std_logic_vector(3 downto 0);  --bit counter for receive bits
  signal stuffin1        			: integer range 0 to 7;  --counters for stuff-bits out and in
  signal usb_lock				 		: std_logic := '0';
  --signal clk_usb						: std_logic;
  signal reg_10bits					: std_logic_vector(9 downto 0);
  signal reg_10bits_receive		: std_logic_vector(9 downto 0);
  signal dp2_prev						: std_logic;
  signal CLOCK12MHz					: std_logic;
  signal CLOCK12MHz_receive		: std_logic;
  signal token_pid2					: std_logic_vector(3 downto 0);
  signal data_pkt1					: std_logic_vector(7 downto 0);
  signal data_temp					: std_logic_vector(7 downto 0);
  signal data_rom						: std_logic_vector(7 downto 0);
  -- ROM signals
  signal address_rom					: std_logic_vector(8 downto 0);
  signal rom_out						: std_logic_vector(7 downto 0);
  signal rden_sig						: std_logic;
  
  signal data_tosend					: std_logic_vector(7 downto 0);
  signal nb_byte_tosend				: std_logic_vector(7 downto 0);
  signal address_start				: std_logic_vector(8 downto 0);
  signal dm_previous					: std_logic;
  signal dp_previous					: std_logic;
  signal dplus_buf1					: std_logic;
  signal dplus_buf2					: std_logic;
  signal dminus_buf1					: std_logic;
  signal dminus_buf2					: std_logic;
  signal start_sendcom				: std_logic;
  signal send_frame					: std_logic;
  signal usb_reset					: std_logic;
  signal synch							: std_logic;
  signal read_byte_valid			: std_logic;
  signal read_byte_valid_c			: std_logic;
  signal data_available				: std_logic;
  signal data_valid					: std_logic; 
  signal data_valid_temp			: std_logic;
  signal gamepad_basic				: std_logic;  
  signal detach_ack					: std_logic;
  signal detach						: std_logic;
  signal joystick_type						: std_logic;
  signal joystick_updown						: std_logic;
  signal set_command						: std_logic_vector(1 downto 0);
  signal counter1						: std_logic_vector(7 downto 0);
  signal counterdetach					: std_logic_vector(3 downto 0);
  signal counter2							: std_logic_vector(3 downto 0); 
  signal counter30ms						: std_logic_vector(18 downto 0);
  signal counter1_3ms					: std_logic_vector(14 downto 0);
  signal joyright_temp					: std_logic_vector(7 downto 0);  
  signal joyleft_temp					: std_logic_vector(7 downto 0);
  signal data_byte2						: std_logic_vector(7 downto 0);
  
  signal nb_reset							: std_logic_vector(7 downto 0);
  signal val								: std_logic;
  signal mouse_valid						: std_logic;	
  signal mouse_counter1					: std_logic_vector(8 downto 0);  
  
  signal mousex_temp						: std_logic_vector(7 downto 0);  
  signal mousey_temp						: std_logic_vector(7 downto 0);
  signal mousex_ctr						: std_logic_vector(11 downto 0);  
  signal mousey_ctr						: std_logic_vector(11 downto 0); 
 
  type usb1_sm_type is (                 -- receive state machine
    state1, state2, state3,              --,
    state4);
	 
  type usb_com_type is (                 	--send state machine #1 to read D+/D- lines
    Idle, 
	 send1, send2,send3, reset_start,             			--
	 send4, send5,send6, reset_released,            			--
	 send_bit0, send_bit1,send_bit2,             			--
	 send_bit3, send_bit4,send_bit5,             		--
	 send_bit6, send_bit7,send15,             		--
	 end_send1, end_send2, send_complete             		--
 );

  type usb_manage_type is (                 	--Tranceiver state machine #1 to read D+/D- lines
    Idle, 
	 usb_manage1, usb_manage2,             			-- 
	 usb_reset_state, crc_complete, usb_waitdetachrelease, wait_for_deviceconnect,
	 usb_wait30ms, end_set_address, end_set_configuration, end_set_idle,
	 read_pktin2, read_pktin3, read_pktin4, wait_pktin4,
	 setaddress_sendpkt1, setaddress_sendpkt1_end,
	 setaddress_sendpkt2, setaddress_sendpkt2_end,
	 setaddress_sendpkt3, setaddress_sendpkt3_end,	 
	 send_ack, send_ack_start, send_ack_end,
	 getreport_sendpkt1, getreport_sendpkt1_start, getreport_sendpkt1_end,
	 wait_pktin1, wait_pktin2, wait_pktin3,
	 wait_report_start, start_get_report,
	 send_getreport_ack, send_getreport_ack_start, send_getreport_ack_end,
	 start_get_data, 
	 wait_read_byte2, wait_read_byte3, wait_read_byte4, wait_read_byte5, wait_read_byte6,
	 wait_read_byte7, wait_read_byte8, wait_read_byte9, wait_read_byte10, wait_read_byte11,
	 read_byte1, read_byte2, read_byte3, read_byte4, read_byte5, read_byte6,
	 read_byte7, read_byte8, read_byte9, read_byte10, read_byte11,
	 wait1, wait2, wait4, wait6,  
	 wait20, wait21, wait30, wait40, 
	 wait_ack2,
	 usb_reset_1ms_start, usb_reset_1ms_wait1, usb_reset_1ms_wait2, usb_reset_1ms_release
 ); 
 
 type usb_detach_type is (                 	--Tranceiver state machine #1 to read D+/D- lines
    Idle, 
	 detach_start, detach_wait,detach_valid             			--            		--
 );
 
 type mouse_state_type is (                 	--Tranceiver state machine #1 to read D+/D- lines
    Idle, 
	 state1             			--            		--
 );
	 
  signal                                usb_detach             : usb_detach_type;
  signal                                usb1_state             : usb1_sm_type;
  signal                                usb_send_com    			: usb_com_type;
  signal                                usb_manage    			: usb_manage_type;
  signal                                mouse_state    			: mouse_state_type; 
  ------------------------------------------------------------

  ATTRIBUTE keep : boolean;
  ATTRIBUTE keep OF dminus  : SIGNAL IS TRUE;
  ATTRIBUTE keep OF dplus  : SIGNAL IS TRUE;
  ATTRIBUTE keep OF clk_usb  : SIGNAL IS TRUE;
  ATTRIBUTE keep OF CLOCK12MHz  : SIGNAL IS TRUE;
  ATTRIBUTE keep OF rom_out  : SIGNAL IS TRUE;
  ATTRIBUTE keep OF joyright_out  : SIGNAL IS TRUE;  
  ATTRIBUTE keep OF joyleft_out  : SIGNAL IS TRUE;
  ATTRIBUTE keep OF joyright_temp  : SIGNAL IS TRUE;  
  ATTRIBUTE keep OF joyleft_temp  : SIGNAL IS TRUE;
 
begin

----------------------------------
-- instantiate the rom commands --
----------------------------------
rom_com_inst : rom_com1 
PORT MAP (
			address	 	=> address_rom,
			clock	 		=> clk_usb,
			rden	 		=> rden_sig AND CLOCK12MHz,
			q	 			=> rom_out
			);
		
   usb_lock <= pll_lock;
  
-----------------------------
-- update of joystick data	--
-----------------------------
  PROCESS
  (
    usb_lock, 		-- External asynchronous reset
    clk_usb    	-- 15 MHz clock (usb over sampling)

  )
  BEGIN
    -- 
   IF (usb_lock = '0') THEN
		joyright_out 			<= "11111111";
		joyleft_out 			<= "11111111";
   ELSIF (rising_edge(clk_usb)) THEN
		IF (data_available = '1') THEN
			IF (data_valid = '1') THEN
				-- bit 0 : 2
				-- bit 1 : 4
				-- bit 2 : 3
				-- bit 3 : 1
				-- bit 4 : fire button / start
				-- bit 5 : fire button / start
				-- bit 6 : button front right "2"  
				-- bit 7 : button front right "1"
				joyright_out <= joyright_temp;
				-- bit 0 : right
				-- bit 1 : left
				-- bit 2 : down
				-- bit 3 : up
				-- bit 4 : fire button / select
				-- bit 5 : fire button / select
				-- bit 6 : button front left "2"  
				-- bit 7 : button front left "1"							
				joyleft_out <= joyleft_temp;
			ELSE
				-- bit 0 : 2
				-- bit 1 : 4
				-- bit 2 : 3
				-- bit 3 : 1
				-- bit 4 : fire button / start
				-- bit 5 : fire button / start
				-- bit 6 : button front right "2"  
				-- bit 7 : button front right "1"
				joyright_out <= joyright_temp;
				-- bit 0 : Not active
				-- bit 1 : Not active
				-- bit 2 : Not active
				-- bit 3 : Not active
				-- bit 4 : fire button / select
				-- bit 5 : fire button / select
				-- bit 6 : button front left "2"  
				-- bit 7 : button front left "1"							
				joyleft_out(7 downto 4) <= joyleft_temp(7 downto 4);	
				joyleft_out(3 downto 0) <= "1111";
			END IF;
      END IF;
   END IF;			
  END PROCESS;
	
 ----------------------------------------------
 --  usb clock enable generation for sending --
 ----------------------------------------------
  PROCESS
  (
    usb_lock, -- reset_process, 	-- External asynchronous reset
    clk_usb    		-- over sampling clk 15MHz
  )
  BEGIN
    -- 
   IF (usb_lock = '0') THEN
		reg_10bits <= "0000000001";
   ELSIF (rising_edge(clk_usb)) THEN
		reg_10bits 		<= reg_10bits(8 downto 0) & reg_10bits(9); -- 
   END IF;			
  END PROCESS;
  
 -- update clock enable USB
 CLOCK12MHz 		<= reg_10bits(4);
 
 ------------------------------------------------
 --  usb clock enable generation for receiving --
 ------------------------------------------------
 -- process generating a 15 MHz clk enable signal in phase with the incoming data from the device
 -- the process is using an oversampling clk of 15 MHz
  PROCESS
  (
    usb_lock, --reset_process, 		-- External asynchronous reset
    clk_usb    -- over sampling clk 48MHz
  )
  BEGIN
    -- 
   IF (usb_lock = '0') THEN
		reg_10bits_receive 	<= "0000000001";
		dp2_prev     		 	<= dplus_buf2;
   ELSIF (rising_edge(clk_usb)) THEN
		dp2_prev     			<= dplus_buf2;           -- sample the input D+ line
		IF (dp2_prev /= dplus_buf2) THEN
			reg_10bits_receive <= "0000000001";				-- reset the phase of the USB clk
		ELSE
			reg_10bits_receive 				<= reg_10bits_receive(8 downto 0) & reg_10bits_receive(9); -- 
      END IF;
   END IF;			
  END PROCESS;
  
  -- update clock USB
 CLOCK12MHz_receive 		<= reg_10bits_receive(4); 
  
  --------------------------------------------------------------------------------------
  ---------------------  buffering of Dplus - Dminus to avoid metastability ------------
  --------------------------------------------------------------------------------------
  process (clk_usb, usb_lock) is
  begin
    if usb_lock = '0' then
		dplus_buf1      	<= '0';
		dplus_buf2      	<= '0';
		dminus_buf1      	<= '0';
		dminus_buf2      	<= '0';
    elsif rising_edge(clk_usb) then     	--
		dplus_buf1     	<= dplus;  
		dplus_buf2     	<= dplus_buf1;
		dminus_buf1      	<= dminus;
		dminus_buf2      	<= dminus_buf1;
    end if;
  end process;
  
  ---------------------------------------------------------------------
  ------------------  state machine for acquiring usb data
  ---------------------------------------------------------------------
  process (reset, clk_usb, CLOCK12MHz_receive) is
  begin
    if (reset = '0') then    
		dp1_last				<= dplus_buf2;
		dm1_last				<= dminus_buf2;
      data_pkt1			<= "00000000";
      data_temp   		<= "00000000";
		read_byte_valid	<= '0';
		usb1_state       	<= state1;   
		nb_bits				<= "0000";
		stuffin1          <= 0;
		synch       		<= '0';
    elsif (rising_edge(clk_usb) AND CLOCK12MHz_receive = '1') then     
      case usb1_state is
        -------------- state1 ----------------
			when state1		=>   
				read_byte_valid	<= '1';
				data_pkt1   <= "00000000";
				data_temp   <= "00000000";
				if dplus_buf2 = '0' and dminus_buf2 = '0' then
					usb1_state	<= state1;				-- reset state
				elsif dplus_buf2 = '1' and dminus_buf2 = '0' then
					dp1_last		<= dplus_buf2;
					dm1_last		<= dminus_buf2;
					usb1_state	<= state2;				-- go to state2 and wait for synch
				end if;
				nb_bits				<= "0000"; 
		  -------------- state2 ----------------
        when state2     =>
				dp1_last		<= dplus_buf2;
				dm1_last		<= dminus_buf2;
				if dp1_last /= dplus_buf2 and dm1_last /= dminus_buf2 then               
					nb_bits     	<= nb_bits + 1;			-- start of synch
				elsif dplus_buf2 = '0' and dminus_buf2 = '0' then  
					usb1_state	<= state1;				-- reset state
					nb_bits		<= "0000";
				end if;
  
          if nb_bits = "0110" then               
				usb1_state	<= state3;				-- go to state 3 and wait for final synch
          end if; 
		  -------------- state3 ----------------
        when state3     =>
				dp1_last		<= dplus_buf2;
				dm1_last		<= dminus_buf2;
          if dplus_buf2 = '0' and dminus_buf2 = '1' then               
            nb_bits     <= nb_bits + 1;			-- start of synch
          elsif dplus_buf2 = '0' and dminus_buf2 = '0' then  
            usb1_state	<= state1;				-- reset state
				data_pkt1   <= "00000000";
				data_temp   <= "00000000";
				nb_bits		<= "0000";
          end if;

			 if nb_bits = "0111" then               
				usb1_state	<= state4;				-- synch byte complete start aquiring packets
				data_pkt1   <= "10000000";
				data_temp	<= "10000000";
				read_byte_valid	<= Not read_byte_valid;
				nb_bits		<= "0000";
				synch       <= '1';
          end if; 
		  -------------- state4 ----------------
        when state4     =>
		if detach = '1' then
			usb1_state   	<= state1;
		else
          if dplus_buf2 = '0' and dminus_buf2 = '0' then  
            usb1_state	<= state1;				-- reset state
				data_pkt1   <= data_temp;
				data_temp   <= "00000000";
				nb_bits		<= "0000";
			 else
				dp1_last        <= dplus_buf2;
				
				if (stuffin1 = 6 and nb_bits = "0000") then
					stuffin1           <= 0;
					val					 <= '1';	
				elsif stuffin1 = 6 then           				--	after 6 '1's in a row = This is a stuff bit.
					stuffin1           <= 0;     				--	ignore it and reset the stuff count.
					val					 <= '0';
				else                          				--	no stuff bit, get the real bit based on D+/D- lines. 
					val					 <= '0';
					nb_bits         <= nb_bits + 1;  	--	Count the real bits. Current 'bitin' is always coming in.
					if dp1_last = dplus_buf2 then     				--	NRZI test. no change -> 1
						stuffin1           <= stuffin1 + 1;  	--	count the consecutive 1's
						if(nb_bits = "0000") then
							data_temp(0) <= '1';
						elsif(nb_bits = "0001") then
							data_temp(1) <= '1';
						elsif(nb_bits = "0010") then
							data_temp(2) <= '1';
						elsif(nb_bits = "0011") then
							data_temp(3) <= '1';
						elsif(nb_bits = "0100") then
							data_temp(4) <= '1';
						elsif(nb_bits = "0101") then
							data_temp(5) <= '1';
						elsif(nb_bits = "0110") then
							data_temp(6) <= '1';
						else
							data_temp(7) <= '1';
						end if;
					else
						if(nb_bits = "0000") then
							data_temp(0) <= '0';
						elsif(nb_bits = "0001") then
							data_temp(1) <= '0';
						elsif(nb_bits = "0010") then
							data_temp(2) <= '0';
						elsif(nb_bits = "0011") then
							data_temp(3) <= '0';
						elsif(nb_bits = "0100") then
							data_temp(4) <= '0';
						elsif(nb_bits = "0101") then
							data_temp(5) <= '0';
						elsif(nb_bits = "0110") then
							data_temp(6) <= '0';
						else
							data_temp(7) <= '0';
						end if;
						stuffin1         	<= 0;     --reset the stuff-bit count when a 0
					end if;
				end if;
			end if;
			
			if (nb_bits = "0111") AND (stuffin1 /= 6) then  
				usb1_state	<= state4;
				nb_bits		<= "0000"; 
         end if; 
			
			if nb_bits = "0000" AND synch = '1' then  
				synch       <= '0';
			elsif nb_bits = "0000" AND val = '1' then
				data_pkt1   <= data_temp;
			elsif nb_bits = "0000" then
				data_pkt1   <= data_temp;			
				read_byte_valid	<= Not read_byte_valid;
         end if; 
		end if;
		when others  => 
			 usb1_state <= state1;
			 nb_bits		<= "0000";
	   end case;
    end if;
  end process; 		 
  
  ------------------------------------------------------
  ------  state machine for sending usb data
  ------------------------------------------------------
  process (usb_lock, clk_usb, CLOCK12MHz) is
  begin
    if (usb_lock = '0') then                                 
      data_tosend			<= "00000000";
		nb_byte_tosend		<= "00000000";
		dp_previous			<= '1';
		dm_previous			<= '0';
		dplus					<= '1';
		dminus				<= '0';
		usb_send_com		<= idle;
    elsif (rising_edge(clk_usb) AND CLOCK12MHz = '1') then     
      case usb_send_com is
        -------------- wait for the reset start trigger ----------------
			when idle		=>   
				data_tosend   <= "00000000";
				send_frame		<= '0';
				if (usb_reset = '1') then				-- the start of sending data is initiated by the usb manage state machine
					usb_send_com	<= reset_start;	-- reset start state
					dplus			<= '0';
					dminus		<= '0';
				else 
					usb_send_com	<= idle;					-- go to idle state
				end if;
        -------------- wait for the start trigger ----------------
			when reset_start		=>   
				if (usb_reset = '0') then					-- The reset is released
					usb_send_com	<= reset_released;	-- end of reset state
					dplus				<= 'Z';
					dminus			<= 'Z';
				else 
					usb_send_com	<= reset_start;			
				end if;				
        -------------- wait for the start trigger ----------------
			when reset_released		=>   
				data_tosend   <= "00000000";
				send_frame		<= '0';
				if (usb_reset = '1') then
					dplus				<= '0';
					dminus			<= '0';
					usb_send_com	<= reset_start;
				elsif (start_sendcom = '1') then				-- the start of sending data is initiated by the usb manage state machine
					usb_send_com	<= send1;				-- next state
					rden_sig			<= '1';					
					address_rom		<= address_start;		-- inialise the address_com with the address set by the usb state machine
				else 
					dplus				<= 'Z';
					dminus			<= 'Z';
					usb_send_com	<= reset_released;	-- wait for send com trigger
				end if;
		  -------------- prepare for the next read ----------------
        when send1     =>              
				address_rom			<= address_rom + "000000001";	-- prepare for the next read
				rden_sig				<= '1';					-- read the first byte
				usb_send_com		<= send2;		  
		  -------------- read the rom first byte ----------------
        when send2     =>  
				nb_byte_tosend		<= rom_out;				-- read the first byte
				usb_send_com		<= send3;
		  -------------- read the next bytes to send ----------------
        when send3     =>    
				data_tosend			<= rom_out;				-- read the next byte
				rden_sig				<= '0';
				usb_send_com		<= send_bit0;
		  -------------- send_bit0 ----------------
        when send_bit0 =>
		  	 nb_byte_tosend   <= nb_byte_tosend - "00000001";
			 rden_sig			<= '0';					-- disable the rom read
          if data_tosend(0) = '0' then               
				dplus			<= NOT dp_previous;
				dminus		<= NOT dm_previous;
				dp_previous <= NOT dp_previous;
				dm_previous <= NOT dm_previous;
          else 
				dplus			<= dp_previous;
				dminus		<= dm_previous;
          end if;
			 usb_send_com	<= send_bit1;
		  -------------- send_bit1 ----------------			 
		  when send_bit1 =>
          if data_tosend(1) = '0' then               
				dplus			<= NOT dp_previous;
				dminus		<= NOT dm_previous;
				dp_previous <= NOT dp_previous;
				dm_previous <= NOT dm_previous;
				else 
				dplus			<= dp_previous;
				dminus		<= dm_previous;
          end if;
			 usb_send_com	<= send_bit2;
		  -------------- send_bit2 ----------------
        when send_bit2 =>
          if data_tosend(2) = '0' then               
				dplus			<= NOT dp_previous;
				dminus		<= NOT dm_previous;
				dp_previous <= NOT dp_previous;
				dm_previous <= NOT dm_previous;
          else 
				dplus			<= dp_previous;
				dminus		<= dm_previous;
          end if;
			 usb_send_com	<= send_bit3;
		  -------------- send_bit3 ----------------			 
		  when send_bit3 =>
          if data_tosend(3) = '0' then               
				dplus			<= NOT dp_previous;
				dminus		<= NOT dm_previous;
				dp_previous <= NOT dp_previous;
				dm_previous <= NOT dm_previous;
          else 
				dplus			<= dp_previous;
				dminus		<= dm_previous;
          end if;
			 usb_send_com	<= send_bit4;
		  -------------- send_bit4 ----------------
        when send_bit4 =>
          if data_tosend(4) = '0' then               
				dplus			<= NOT dp_previous;
				dminus		<= NOT dm_previous;
				dp_previous <= NOT dp_previous;
				dm_previous <= NOT dm_previous;
          else 
				dplus			<= dp_previous;
				dminus		<= dm_previous;
          end if;
			 usb_send_com	<= send_bit5;
		  -------------- send_bit5 ----------------			 
		  when send_bit5 =>
          if data_tosend(5) = '0' then               
				dplus			<= NOT dp_previous;
				dminus		<= NOT dm_previous;
				dp_previous <= NOT dp_previous;
				dm_previous <= NOT dm_previous;
          else 
				dplus			<= dp_previous;
				dminus		<= dm_previous;
          end if;
			 address_rom	<= address_rom + "000000001";	-- prepare for the next read
			 rden_sig		<= '1';								
			 usb_send_com	<= send_bit6;
		  -------------- send_bit6 ----------------
        when send_bit6 =>
          if data_tosend(6) = '0' then               
				dplus			<= NOT dp_previous;
				dminus		<= NOT dm_previous;
				dp_previous <= NOT dp_previous;
				dm_previous <= NOT dm_previous;
          else 
				dplus			<= dp_previous;
				dminus		<= dm_previous;
          end if;
			 rden_sig		<= '0';
			 usb_send_com	<= send_bit7;
		  -------------- send_bit7 ----------------			 
		  when send_bit7 =>
          if data_tosend(7) = '0' then               
				dplus			<= NOT dp_previous;
				dminus		<= NOT dm_previous;
				dp_previous <= NOT dp_previous;
				dm_previous <= NOT dm_previous;
          else 
				dplus			<= dp_previous;
				dminus		<= dm_previous;
          end if;
			 data_tosend 	<= rom_out;
			 rden_sig		<= '0';								
			 if nb_byte_tosend = "00000000" then
				usb_send_com	<= end_send1;
			 else
				usb_send_com	<= send_bit0; -- send next byte
			 end if;
		  -------------- send_end of frame ----------------			 
		  when end_send1 =>              
			 dplus		<= '0';
			 dminus		<= '0';
			 usb_send_com	<= end_send2; 
		  -------------- send_end of frame ----------------			 
		  when end_send2 =>              
			 dplus			<= '0';
			 dminus			<= '0';
			 usb_send_com	<= send_complete; 
		  -------------- send_complete ----------------			 
		  when send_complete =>              
			 send_frame		<= '1';
			 dplus			<= 'Z';
			 dminus			<= 'Z';
			 dp_previous	<= '1';
			 dm_previous	<= '0';
			 usb_send_com	<= reset_released; 	
		  when others  => 
			 usb_send_com <= idle;		 
	   end case;
    end if;
  end process; 		 
  
  
  --------------------------------------------------------------------------
  ------  state machine for managing sending and receiving usb data
  --------------------------------------------------------------------------
  process (usb_lock, clk_usb) is
  begin
    if (usb_lock = '0') then 
		joystick_type 		<= '0';
		usb_reset			<= '0';
		data_available		<= '0';
		data_valid			<= '0';
		data_valid_temp	<= '0';
      start_sendcom		<= '0';
		counter1				<= "11111111";
		counter2				<= "1000";
		counter30ms			<= "0101100110000100101";
		counter1_3ms		<= "100000100011011";
		detach_ack			<= '0';
		usb_manage			<= idle;
		
    elsif (falling_edge(clk_usb)) then     
      case usb_manage is
        -------------- idle state ----------------
			when idle		=>   
				set_command				<= "00";
				start_sendcom			<= '0';
				joystick_type 			<= '0';
				mouse_valid				<= '0';
				if dplus = '1' then	
					usb_manage			<= wait_for_deviceconnect;	
				else 
					usb_manage			<= idle;
				end if; -- 
		  -------------- confirm device connected ----------------
        when wait_for_deviceconnect     =>              
				counter1					<= counter1 - 1;
				if counter1	= "00000000" then
					usb_reset			<= '1';
					usb_manage			<= usb_reset_state;	
				else
					usb_manage			<= wait_for_deviceconnect;
				end if;		
		  -------------- reset device state ----------------
        when usb_reset_state     =>              
				counter30ms				<= counter30ms - 1;
				if counter30ms	 = "0000000000000000000" then
				   counter30ms			<= "1111111111111111111";
					counter1_3ms		<= "100000100011011";
					counter2				<= "1011";
					usb_reset			<= '0';
					detach_ack			<= '1';
					nb_reset	 			<= "00011101"; -- 29 keep alive
					usb_manage			<= usb_reset_1ms_start;	
				else
					usb_manage			<= usb_reset_state;
				end if;
		  -------------- usb_reset_1ms_start ----------------
        when usb_reset_1ms_start     =>              
				counter1_3ms				<= counter1_3ms - 1;
				if counter1_3ms	 = "0000000000000000" then
					counter1_3ms		<= "100000100011011";
					counter2				<= "1011";
					counter1_3ms		<= counter1_3ms - 1;
					detach_ack			<= '0';
					usb_reset			<= '1';
					usb_manage			<= usb_reset_1ms_wait1;	
				else
					usb_manage			<= usb_reset_1ms_start;
				end if;			
		  -------------- usb_reset_1ms_start ----------------
        when usb_reset_1ms_wait1     =>  
				usb_reset				<= '1';
				counter2					<= counter2 - '1';
				if counter2 = "0000" then
					usb_reset			<= '0';
					usb_manage			<= usb_reset_1ms_release;	
				else
					usb_manage			<= usb_reset_1ms_wait1;
				end if;
		
		  -------------- usb_reset_1ms_start ----------------
        when usb_reset_1ms_release     =>          
				usb_reset				<= '0';		  
				nb_reset					<= nb_reset - 1;
				if nb_reset	 = "00000000" then
					usb_manage			<= usb_manage2;	
				else
					counter1_3ms		<= "100000100011011";
					counter2				<= "1011";
					usb_manage			<= usb_reset_1ms_start;
				end if;				
	
		  -------------- reset release state ----------------
        when usb_wait30ms     =>              
				counter1			<= counter1 - 1;
				if counter1	= "00000000" then
					detach_ack		<= '0';
					counter1			<= "11111111";
					usb_manage			<= usb_waitdetachrelease;	
				else
					usb_manage			<= usb_wait30ms;
				end if;	
		  -------------- confirm device attached ----------------
        when usb_waitdetachrelease     =>              
				counter2				<= counter2 - 1;
				if counter2	= "0000" then
					usb_manage			<= usb_manage2;	
				else
					usb_manage			<= usb_waitdetachrelease;
				end if;
		  -------------- end of reset state ----------------
        when usb_manage2     =>  
				if detach = '1' then
					usb_manage   		<= idle;
				else
					start_sendcom	<= '0';
					address_start	<= "000010010";
					usb_manage		<= wait1;	-- start set address	
				end if;	
		  ------------------------------------------------
		  -------------- SET ADDRESS 0x01 ----------------
		  ------------------------------------------------
		  
		  -------------- waiting state -------------------
        when wait1 =>
				counter2					<= counter2 - 1;
				if counter2	= "0000" then
					counter2				<= "1111";
					usb_manage			<= setaddress_sendpkt1;		  
				else
					usb_manage			<= wait1;
				end if;			 
		  -------------- send first packet "SETUP" packet ----------------
        when setaddress_sendpkt1     =>  
				start_sendcom			<= '1';
				if set_command = "00" then
					-- set address
					address_start		<= "000010010"; -- 0x12  - 0x2D 0x00 0x10  - 3 bytes
				elsif set_command = "01" then
					-- set configuration
					address_start		<= "001010000"; -- 0x50  - 0x2D 0x01 0xE8  - 3 bytes
				else
					-- set idle
					address_start		<= "001110000"; -- 0x70  - 0x2D 0x01 0xE8  - 3 bytes
				end if;
				usb_manage				<= setaddress_sendpkt1_end; -- 
		  -------------- wait for completion of sending frame ----------------			 
		  when setaddress_sendpkt1_end =>
				if detach = '1' then
					usb_manage   	<= idle;
				else
					if send_frame = '1' then  
						start_sendcom	<= '0';
						counter1			<= "01010011";
						usb_manage		<= wait2;
					else 
						usb_manage		<= setaddress_sendpkt1_end;
					end if;
				end if;
			---------------------  waiting state ----------------------
			when wait2 =>
				counter1					<= counter1 - 1;
				if counter1	= "00000000" then
					counter1				<= "01010011";
					usb_manage			<= setaddress_sendpkt2;		  
				else
					usb_manage			<= wait2;
				end if;			 
		  -------------- send the data packet for set address ---------
        when setaddress_sendpkt2     =>  
				start_sendcom		<= '1';
				if set_command = "00" then
					-- set address
					address_start		<= "000010111"; -- 0x17  -   - 11 bytes
				elsif set_command = "01" then
					-- set configuration
					address_start		<= "001010101"; -- 0x55  -   - 11 bytes
				else
					-- set idle
					address_start		<= "001110101"; -- 0x75  -   - 11 bytes
				end if;
				usb_manage			<= setaddress_sendpkt2_end; -- 	
		  -------------- wait for completion of sending frame ----------------			 
		  when setaddress_sendpkt2_end =>
			 if detach = '1' then
					usb_manage   	<= idle;
			 else
				if send_frame = '1' then  
					start_sendcom			<= '0';
					counter1_3ms			<= "100000100011011";
					usb_manage				<= wait_ack2;
				else 
					usb_manage				<= setaddress_sendpkt2_end;
				end if;
			end if;
		  -------------- waiting ACK ----------------
        when wait_ack2 =>
				if detach = '1' then
					usb_manage   	<= idle;
				else
					counter1_3ms			<= counter1_3ms - 1;
					if data_pkt1 = "11010010" then
						counter1_3ms		<= "100000100011011";
						usb_manage			<= wait4;		-- ack go top the next stage
					elsif counter1_3ms	= "000000000000000" then
						counter1_3ms		<= "100000100011011"; -- no ack, retry sending the command
						usb_manage			<= setaddress_sendpkt1;
					else
						usb_manage			<= wait_ack2;
					end if;
				end if;
		  ---------------- waiting state  ---------------------
		  when wait4 =>
				counter2			<= counter2 - 1;
				if counter2	= "0000" then
					counter2		<= "1111";
					usb_manage			<= setaddress_sendpkt3;		  
				else
					usb_manage					<= wait4;
				end if;			 
		  -------------- prepare for sending the second packet ----------------
        when setaddress_sendpkt3     =>  
				start_sendcom		<= '1';
				if set_command = "00" then
					-- set address
					address_start		<= "000100100"; -- 0x24  -   - 4 bytes
				elsif set_command = "01" then
					-- set configuration
					address_start		<= "001100010"; -- 0x62  -   - 4 bytes
				else
					-- set idle
					address_start		<= "010000010"; -- 0x82  -   - 4 bytes
				end if;
				usb_manage			<= setaddress_sendpkt3_end; -- 
		  -------------- wait for completion of sending frame ----------------			 
		  when setaddress_sendpkt3_end =>
				if detach = '1' then
					usb_manage   	<= idle;
				else
					if send_frame = '1' then  
						start_sendcom			<= '0';
						counter1_3ms			<= "100000100011011";
						usb_manage				<= wait_pktin1;
					else 
						usb_manage				<= setaddress_sendpkt3_end;
					end if;
				end if;
		  -------------- waiting for 1st byte ----------------
        when wait_pktin1 =>
				if detach = '1' then
					usb_manage   	<= idle;
				else
					counter1_3ms			<= counter1_3ms - 1;
					if data_pkt1 = "10000000" then -- 0x80 wait for synch
						usb_manage			<= wait_pktin2;		-- ack go to the next stage
					elsif counter1_3ms	= "000000000000000" then
						counter1_3ms		<= "100000100011011";    -- no ack, retry sending the command
						usb_manage			<= setaddress_sendpkt3;
					else
						usb_manage			<= wait_pktin1;
					end if;
				end if;
		  --------------  pktin2 "0x4B"  -------------------------
		  when wait_pktin2 =>
				if detach = '1' then
					usb_manage   		<= idle;
				else
					if read_byte_valid = '0' then
						usb_manage		<= wait_pktin2;	  
					else
						usb_manage		<= read_pktin2;
					end if;	
				end if;
		  ------------------ read_pktin2 "0x4B" ---------------------
		  when read_pktin2 =>
				if detach = '1' then
					usb_manage   	<= idle;
				else
					if data_pkt1 = "01001011" then -- 0x4B
						usb_manage			<= wait_pktin3;					-- ack go top the next stage
					else 
						usb_manage			<= setaddress_sendpkt3; -- no ack, retry sending the command
					end if;
				end if;	
		  --------------  pktin3 "0x00"  -------------------------
		  when wait_pktin3 =>
				if detach = '1' then
					usb_manage   		<= idle;
				else
					if read_byte_valid = '1'  then
						usb_manage		<= wait_pktin3;	  
					else
						usb_manage		<= read_pktin3;
					end if;	
				end if;
		  ------------------ read_pktin3 "0x00" ---------------------
		  when read_pktin3 =>
				if detach = '1' then
					usb_manage   	<= idle;
				else
					if data_pkt1 = "00000000" then -- 0x00
						usb_manage			<= wait_pktin4;					-- ack go top the next stage
					else 
						usb_manage			<= setaddress_sendpkt3; -- no ack, retry sending the command
					end if;
				end if;	
		  --------------  pktin4 "0x00"  -------------------------
		  when wait_pktin4 =>
				if detach = '1' then
					usb_manage   		<= idle;
				else
					if read_byte_valid = '0' then
						usb_manage		<= wait_pktin4;	  
					else
						usb_manage		<= read_pktin4;
					end if;	
				end if;
		  ------------------ read_pktin4 "0x00" ---------------------
		  when read_pktin4 =>
				if detach = '1' then
					usb_manage   	<= idle;
				else
					if data_pkt1 = "00000000" then -- 0x00
						counter1				<= "00001111"; 
						usb_manage			<= wait6;					-- go to "send ack" state
					else 
						usb_manage			<= setaddress_sendpkt3; -- no ack, retry sending the command
					end if;
				end if;	
		  --------------------   waiting state before sending ack  --------------------------
        when wait6 =>
				counter1					<= counter1 - 1;
				if counter1	= "00000000" then
					counter1				<= "11111111";
					usb_manage			<= send_ack;		  
				else
					usb_manage			<= wait6;
				end if;	
		  -------------- inialise ROM address for send ack ----------------
        when send_ack     =>  
				start_sendcom		<= '1';
				address_start		<= "001000000"; -- 0x40  -   - 2 bytes
				usb_manage			<= send_ack_end; -- send_ack_start;	-- 	
		  -------------- wait for completion of sending frame ----------------			 
		  when send_ack_end =>
				if detach = '1' then
					usb_manage   	<= idle;
				else
					if send_frame = '1' then  
						start_sendcom			<= '0';
						counter1_3ms			<= "000000000000001";
						if set_command = "00" then
							usb_manage				<= end_set_address;
						elsif set_command = "01" then
							usb_manage				<= end_set_configuration;
						else
							usb_manage				<= end_set_idle;
						end if;
					else 
						usb_manage				<= send_ack_end;
					end if;	
				end if;
		  ------------------------------  End of Set Address   -----------------------------
		  
        when end_set_address =>
				counter1_3ms					<= counter1_3ms - 1;
				if counter1_3ms	= "000000000000000" then
					counter1_3ms				<= "100000100011011";
					set_command					<= "01"; -- set_command set to SetConfiguration
					nb_reset	 					<= "00000000"; -- 1 keep alive
					usb_manage					<= usb_reset_1ms_start;		  
				else
					usb_manage					<= end_set_address;
				end if; 
				
        when end_set_configuration =>
				counter1_3ms					<= counter1_3ms - 1;
				if counter1_3ms	= "000000000000000" then
					counter1_3ms				<= "100000100011011";
					set_command					<= "10"; -- set_command set to SetConfiguration
					nb_reset	 					<= "00000000"; -- 1 keep alive
					usb_manage					<= usb_reset_1ms_start;		  
				else
					usb_manage					<= end_set_configuration;
				end if; 

		  when end_set_idle =>
				counter1_3ms					<= counter1_3ms - 1;
				if counter1_3ms	= "000000000000000" then
					counter1_3ms				<= "100000100011011";
					counter1						<= "00011001";
					set_command					<= "00"; -- set_command set to Setaddress in case of a detach/attach
					usb_manage					<= wait21; -- wait20; -- go to get report	  
				else
					usb_manage					<= end_set_idle;
				end if; 


			---------------------------------------------------------------
			---------------------------------------------------------------
			---------------------------------------------------------------
			-------------- GET REPORT ----------------
        when wait20 =>    -- wait 1.3ms * 9
				counter1_3ms				<= counter1_3ms - 1;
				if counter1_3ms	= "000000000000000" then
					counter1_3ms			<= "100000100011011";
					usb_manage				<= wait21;		  
				else
					usb_manage				<= wait20;
				end if;		
		  ---------------------   wait  -------------
        when wait21 =>    -- 
				counter1						<= counter1 - 1;
				if counter1	= "00000000" then
					data_available			<=	'0';
					data_valid				<= '0';
					counter1_3ms			<= "100000100011011";
					usb_manage				<= getreport_sendpkt1;		  
				else
					counter1_3ms			<= "100000100011011";
					usb_manage				<= wait21;
				end if;		
		  -------------- read the next bytes to send ----------------
        when getreport_sendpkt1     =>  
				start_sendcom		<= '1';
				address_start		<= "010010000"; -- 0x90  - 0x69 0x81 0x58  - 3 bytes
				usb_manage			<= getreport_sendpkt1_end; 
		  -------------- wait for completion of sending frame ----------------			 
		  when getreport_sendpkt1_end =>
				if detach = '1' then
					usb_manage   	<= idle;
				else
					if send_frame = '1' then  
						start_sendcom		<= '0';
						counter1				<= "00000111";
						usb_manage			<= wait30;
					else 
						usb_manage			<= getreport_sendpkt1_end;
					end if;
				end if;
			-------------   waiting state  ------------------------
		   when wait30 =>
				counter1						<= counter1 - 1;
				if counter1	= "00000000" then
					counter1					<= "11111111";
					counter1_3ms			<= "100000100011011";
					usb_manage				<= wait_report_start;		  
				else
					usb_manage				<= wait30;
				end if;			 
		  -------------- waiting ACK ----------------
        when wait_report_start =>
				if detach = '1' then
					usb_manage   	<= idle;
				else
					counter1_3ms			<= counter1_3ms - 1;
					if data_pkt1 = "10000000" then  -- wait for synch
						counter1_3ms		<= "100000100011011";
						counter1				<= "01111000";
						read_byte_valid_c <= read_byte_valid;
						usb_manage			<= start_get_data;	-- ack go top the next stage
					elsif counter1_3ms	= "000000000000000" then
						counter1_3ms		<= "100000100011011"; 	-- no ack, retry sending the command
						usb_manage			<= getreport_sendpkt1;
					else
						usb_manage			<= wait_report_start;
					end if;
				end if;
		  --------------  byte1  -------------------------
		  when start_get_data =>
				counter1				<= counter1 - 1;
				if detach = '1' OR counter1 = "00000000" then
					usb_manage   	<= idle;
				else
					if read_byte_valid = read_byte_valid_c then
						usb_manage			<= start_get_data;	  
					else
						read_byte_valid_c <= read_byte_valid;
						usb_manage			<= read_byte1;
					end if;	
				end if;
		  ------------------ read_byte1 ---------------------
		  when read_byte1 =>
				if (data_pkt1 = "01001011" or data_pkt1 = "11000011") then
					data_valid_temp 	<= '1';
					read_byte_valid_c <= read_byte_valid;
					usb_manage			<= wait_read_byte2;
					counter1				<= "11111111";
				else
					counter1				<= "11111111";
					usb_manage			<= wait21;
				end if;
		  --------------  byte2  -------------------------
		  when wait_read_byte2 =>
				counter1				<= counter1 - 1;
				if detach = '1' OR counter1 = "00000000" then
					usb_manage   	<= idle;
				else
					if read_byte_valid = read_byte_valid_c  then
						usb_manage		<= wait_read_byte2;	  
					else
						usb_manage		<= read_byte2;
					end if;	
				end if;
		  ------------------ read_byte2 ---------------------
		  when read_byte2 =>
				if joystick_type = '0' then
					--joyleft_temp ( 1 downto 0) <= NOT ((NOT data_pkt1(6)) & data_pkt1(7)); -- game pad joystick
					data_byte2  		<= data_pkt1;
					---
					if (data_pkt1 = "01111111" OR data_pkt1 = "11111111" OR data_pkt1 = "00000000") then
						data_valid_temp 			<= '1';
					else
						data_valid_temp 			<= '0';
					end if;
				else 
					-- data_valid_temp 			<= '1';
					if (data_pkt1 = "10000000") then
						joystick_updown 	<= '1'; -- either up or down
					elsif (data_pkt1 = "00000000") then
						joystick_updown 	<= '0'; -- left
						joyright_temp(1 downto 0) 	<= "10";
					elsif (data_pkt1 = "11111111") then
						joystick_updown 	<= '0'; -- left
						joyright_temp(1 downto 0) 	<= "01";					
					end if;
				end if;

				---
				read_byte_valid_c <= read_byte_valid;
				counter1 			<= "11111111";
				usb_manage			<= wait_read_byte3;		
		  --------------  byte3  -------------------------
		  when wait_read_byte3 =>
				counter1				<= counter1 - 1;
				if detach = '1' OR counter1 = "00000000" then
					usb_manage   	<= idle;
				else
					if read_byte_valid = read_byte_valid_c  then
						usb_manage		<= wait_read_byte3;	  
					else
						usb_manage		<= read_byte3;
					end if;	
				end if;
		  ------------------ read_byte3 ---------------------
		  when read_byte3 =>
				if joystick_type = '1' then
					joyright_temp(3 downto 2) 	<= NOT (data_pkt1(0) &  NOT data_pkt1(0));
				else
					--- not actif
					if (data_byte2 = "01111111" AND data_pkt1 = "01111111") then 
						joyleft_temp(3 downto 0) <= "1111";
					--- up right
					elsif (data_byte2 = "11111111" AND data_pkt1 = "00000000") then 
						joyleft_temp(3 downto 0) <= "0110";		
					--- up left
					elsif (data_byte2 = "00000000" AND data_pkt1 = "00000000") then 
						joyleft_temp(3 downto 0) <= "0101";
					--- down right
					elsif (data_byte2 = "11111111" AND data_pkt1 = "11111111") then 
						joyleft_temp(3 downto 0) <= "1010";
					--- down left
					elsif (data_byte2 = "00000000" AND data_pkt1 = "11111111") then 
						joyleft_temp(3 downto 0) <= "1001";		
					--- up
					elsif (data_byte2 = "01111111" AND data_pkt1 = "00000000") then 
						joyleft_temp(3 downto 0) <= "0111";
					--- down
					elsif (data_byte2 = "01111111" AND data_pkt1 = "11111111") then
						joyleft_temp(3 downto 0) <= "1011";
					--- right
					elsif (data_byte2 = "11111111" AND data_pkt1 = "01111111") then
						joyleft_temp(3 downto 0) <= "1110";
					--- left
					elsif (data_byte2 = "00000000" AND data_pkt1 = "01111111") then
						joyleft_temp(3 downto 0) <= "1101";
					else
						-- mouse detected, 
						mousex_temp 				 <= data_byte2;
						mousey_temp 				 <= data_pkt1;
						joyleft_temp(3 downto 0) <= "1111";
						mouse_valid					 <= '1';
					end if;		
				end if;
				read_byte_valid_c <= read_byte_valid;
				counter1 			<= "11111111";
				usb_manage			<= wait_read_byte4;		
		  --------------  byte4  -------------------------
		  when wait_read_byte4 =>
				counter1				<= counter1 - 1;
				if detach = '1' OR counter1 = "00000000" then
					usb_manage   	<= idle;
				else
					if read_byte_valid = read_byte_valid_c  then
						usb_manage		<= wait_read_byte4;	  
					else
						usb_manage		<= read_byte4;
					end if;
				end if;
		  ------------------ read_byte4 ---------------------
		  when read_byte4 =>
				mouse_valid				<= '0';
				read_byte_valid_c 	<= read_byte_valid;
				counter1 				<= "11111111";
				usb_manage				<= wait_read_byte5;		
		  --------------  byte5  -------------------------
		  when wait_read_byte5 =>
				counter1				<= counter1 - 1;
				if detach = '1' OR counter1 = "00000000" then
					usb_manage   	<= idle;
				else
					if read_byte_valid = read_byte_valid_c  then
						usb_manage		<= wait_read_byte5;	  
					else
						usb_manage		<= read_byte5;
					end if;	
				end if;
		  ------------------ read_byte11 ---------------------
		  when read_byte5 =>
				read_byte_valid_c 	<= read_byte_valid;
				counter1 				<= "11111111";
				usb_manage				<= wait_read_byte6;		
		  --------------  byte6  -------------------------
		  when wait_read_byte6 =>
				counter1				<= counter1 - 1;
				if detach = '1' OR counter1 = "00000000" then
					usb_manage   	<= idle;
				else
					if read_byte_valid = read_byte_valid_c  then
						usb_manage		<= wait_read_byte6;	  
					else
						usb_manage		<= read_byte6;
					end if;		
				end if;
		  ------------------ read_byte6 ---------------------	
		  when read_byte6 =>
				read_byte_valid_c 	<= read_byte_valid;
				counter1 				<= "11111111";
				usb_manage				<= wait_read_byte7; -- joystick type = gamepad
		  --------------  byte7  -------------------------
		  when wait_read_byte7 =>
				counter1				<= counter1 - 1;
				if detach = '1' OR counter1 = "00000000" then
					usb_manage   	<= idle;
				else
					if read_byte_valid = read_byte_valid_c  then
						usb_manage		<= wait_read_byte7;	  
					else
						usb_manage		<= read_byte7;
					end if;	
				end if;
		  ------------------ read_byte7 ---------------------
		  when read_byte7 =>
				if data_pkt1(3 downto 0) = "1111" then  -- checking if data valid
					joyright_temp(3 downto 0) 	<= NOT (data_pkt1(4) &  data_pkt1(6) & data_pkt1(7) &  data_pkt1(5));
				else
					data_valid_temp	<= '0';
				end if;
				read_byte_valid_c 	<= read_byte_valid;
				counter1 				<= "11111111";
				usb_manage				<= wait_read_byte8;		
		  --------------  byte8  -------------------------
		  when wait_read_byte8 =>
				counter1				<= counter1 - 1;
				if detach = '1' OR counter1 = "00000000" then
					usb_manage   	<= idle;
				else
					if read_byte_valid = read_byte_valid_c  then
						usb_manage		<= wait_read_byte8;	  
					else
						usb_manage		<= read_byte8;
					end if;
				end if;
		  ------------------ read_byte8 ---------------------
		  when read_byte8 =>
				joyright_temp(7 downto 4) 	<= NOT (data_pkt1(1) &  data_pkt1(3) & data_pkt1(5) &  data_pkt1(5));
				joyleft_temp(7 downto 4) 	<= NOT (data_pkt1(0) &  data_pkt1(2) & data_pkt1(4) &  data_pkt1(4)); 
				read_byte_valid_c 	<= read_byte_valid;
				counter1 				<= "11111111";
				usb_manage				<= wait_read_byte9;		
		  --------------  byte9  -------------------------
		  when wait_read_byte9 =>
				counter1				<= counter1 - 1;
				if detach = '1' OR counter1 = "00000000" then
					usb_manage   	<= idle;
				else
					if read_byte_valid = read_byte_valid_c  then
						usb_manage		<= wait_read_byte9;	  
					else
						usb_manage		<= read_byte9;
					end if;	
				end if;
		  ------------------ read_byte9 ---------------------
		  when read_byte9 =>
				--- test if analogue ON/OFF
				if (data_pkt1 = "01000000") then 
					-- analogue ON 
					data_valid		<= '0';
				elsif (data_pkt1 = "00000000" OR data_pkt1 = "11000000") then
					data_valid		<= data_valid_temp;
				else
					data_valid		<= '0';
				end if;
				read_byte_valid_c <= read_byte_valid;
				counter1 			<= "11111111";
				usb_manage			<= wait_read_byte10;		
		  --------------  byte10  -------------------------
		  when wait_read_byte10 =>
				counter1				<= counter1 - 1;
				if detach = '1' OR counter1 = "00000000" then
					usb_manage   	<= idle;
				else
					if read_byte_valid = read_byte_valid_c  then
						usb_manage		<= wait_read_byte10;	  
					else
						usb_manage		<= read_byte10;
					end if;	
				end if;	
		  ------------------ read_byte10 ---------------------
		  when read_byte10 =>
				read_byte_valid_c <= read_byte_valid;
				counter1 			<= "11111111";
				usb_manage			<= wait_read_byte11;		
		  --------------  byte11  -------------------------
		  when wait_read_byte11 =>
				counter1				<= counter1 - 1;
				if detach = '1' OR counter1 = "00000000" then
					usb_manage   	<= idle;
				else
					if read_byte_valid = read_byte_valid_c  then
						usb_manage		<= wait_read_byte11;	  
					else
						usb_manage		<= read_byte11;
					end if;	
				end if;
		  ------------------ read_byte11 ---------------------
		  when read_byte11 =>
				counter1				<= "00001111";
				usb_manage			<= wait40;				
	
		  ----------------------------------------------------
		  ------------  check CRC  ---------------------------
		  ----------------------------------------------------
		  ------------- if valid data then issue an ack   ----
        when wait40 =>
				counter1					<= counter1 - 1;
				if counter1	= "00000000" then
					counter1				<= "11111111";
					usb_manage			<= send_getreport_ack;		  
				else
					usb_manage			<=wait40;
				end if;	
		  -------------- read the next bytes to send ----------
        when send_getreport_ack     =>  
				counter2				<= "1111";
				start_sendcom		<= '1';
				address_start		<= "001000000"; -- 0x40  -   - 2 bytes
				counter1 				<= "11111111";
				usb_manage			<= send_getreport_ack_end; 
		  -------------- wait for completion of sending frame ----------------			 
		  when send_getreport_ack_end =>
				counter1				<= counter1 - 1;
				if detach = '1' OR counter1 = "00000000" then
					usb_manage   	<= idle;
				else
					if send_frame = '1' then  
						start_sendcom			<= '0';
						counter1_3ms			<= "100000100011011";
						counter2					<= "1111";
						usb_manage				<= crc_complete;  -- 
					else 
						usb_manage				<= send_getreport_ack_end;
					end if;	
				end if;
		  ------------------------------  CRC check   -----------------------------
		  when crc_complete	=>
				if detach = '1' then
					usb_manage   	<= idle;
				else
					data_available		<=	'1';
					usb_manage			<= wait20;
				end if;
		  when others  => 
			 usb_manage 		<= idle;		 
	   end case;
    end if;
  end process; 

  --------------------------------------------------------------------------
  ------  detach detection process
  --------------------------------------------------------------------------
  process (
  usb_lock, 
  CLOCK12MHz,
  detach_ack,
  counterdetach,
  dplus_buf2,
  dminus_buf2
  ) is
  begin
    if (usb_lock = '0') then  
		counterdetach		<= "1111";
		detach 				<= '0';
		usb_detach			<= idle;
    elsif (falling_edge(CLOCK12MHz)) then     
      case usb_detach is
        -------------- wait for the start trigger ----------------
			when idle		=>   
				if dplus_buf2 = '0' AND dminus_buf2 = '0' then	
					counterdetach		<= "1111";
					usb_detach			<= detach_start;	
				else 
					usb_detach			<= idle;
				end if; -- 
				
		  -------------- read the rom first byte ----------------
        when detach_start     =>              
				if dplus_buf2 = '0' AND dminus_buf2 = '0' then
					if counterdetach = "0000" then
						usb_detach		<= detach_valid;	
					else
						usb_detach		<= detach_start;
						counterdetach	<= counterdetach - 1;
					end if;
				else
					counterdetach		<= "1111";
					usb_detach			<= idle;
				end if;
		  -------------- wait for 30ms ----------------
        when detach_valid     =>              
				detach				<= '1';
				usb_detach			<= detach_wait;	

		  -------------- wait for 30ms ----------------
        when detach_wait     =>              
				if detach_ack	= '1' then
					detach			<= '0';
					counterdetach	<= "1111";
					usb_detach		<= idle;				
				else
					usb_detach		<= detach_wait;
				end if;
		  when others  => 
				counterdetach		<= "1111";
				usb_detach 			<= idle;		 
	   end case;
    end if;
  end process;	  
  
  ------------------------------------------------------
  ------  state machine for the mouse
  ------------------------------------------------------
  process (usb_lock, clk_usb, CLOCK12MHz) is
  begin
    if (usb_lock = '0') then                                 
      mouse_counter1			<= "000000000";
		mousex_ctr				<= "000000000000";
		mousey_ctr				<= "000000000000";
		mouse_state				<= idle;
    elsif (rising_edge(CLOCK12MHz) AND mouse_valid = '1') then     
      case mouse_state is
        -------------- xxxxxxxxxxxxxxxxxxxxxxxxxxx ----------------
			when idle		=>   
				if (mouse_counter1 = "000000000") then					-- 
					mouse_state		<= state1;				-- 
				else 
					mouse_counter1	<= mouse_counter1 - 1;
					mouse_state		<= idle;					-- 
				end if;
        -------------- xxxxxxxxxxxxxxxxxxxxxxxxxxx ----------------
			when state1	=>   
				-- 
				IF ((mousex_temp /= "10000000")) THEN
					IF ((mousex_temp(7) = '1') OR (mousex_temp = "01111110")) THEN
					-- move right
					mousex_ctr		<= mousex_ctr + ("00000000" & mousex_temp(7 downto 4));
					ELSE
					-- move left
					mousex_ctr		<= mousex_ctr - ("00000000" & NOT(mousex_temp(7 downto 4)));
					END IF;
				END IF;
				IF (mousey_temp /= "10000000") THEN
					IF ((mousey_temp(7) = '0')) THEN
						--IF ((mousex_temp /= "01111110") AND (mousex_temp /= "11111110")) THEN
							-- move up
							mousey_ctr		<= mousey_ctr + ("00000000" & NOT (mousey_temp(7 downto 4)));
						--END IF;
					ELSE
					-- move down
					mousey_ctr		<= mousey_ctr - ("00000000" & mousey_temp(7 downto 4));
					END IF;
				END IF;
				mousex_out		<= mousex_ctr;
				mousey_out		<= mousey_ctr;
				mouse_counter1	<= "000000111";
				mouse_state		<= idle;			
			when others => 
				mouse_state 	<= idle;		 
	   end case;
    end if;
  end process; 		 
  
  
  
------------------------------------------------------------
end arch;