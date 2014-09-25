--This file contains 2 Entities making up an HID USB interface
--===========================================================================
--  USB Interface module - Copywrite Johns Hopkins University ECE Dept.
--This code may be used and freely distributed as long as the JHU credit is retained.
--============================================================================
--Implements an HID USB enumeration and communication through a tranceiver implemented
--in the FPGA to directly drive the USB diferential pair data lines.
--On an XESS xst-2 or -3 board this requires a connection of the usb cable wires with a 1.5K 
--pullup to 3.3V on the D+ or D- line, and the data lines connecting to 2 FPGA pins.
--The bit rate is determined by which line has the pullup. This code is currently set up
--for usb full speed (12 Mhz) operation, but can be easily changed for 1.5Mhz low speed.

--The inputs and outputs are arrays(1 to 8) of std_logic_vector(7 downto 0).
--These arrays are the data packets sent and received via USB reports. The I/O
--buffers for USB transactions in the tranceiver are also 8 byte arrays.

-- The interface acts as an HID class, thus only control and interrupt xfers are possible.
-- Any commented page references are to "USB Complete", 3rd Edition, by Jan Axelson
--
-- Author: Robert Jenkins
-- Last Modification: Jan 30, 2009
--==============================================================================
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.USBF_Declares.all;             --Package containing declarations needed by the USB interface        

--------------------------------------------------------------------------------
entity USBF_IFC1 is
  port(
    clk_usb     	 	: in    std_logic;      --100MHz project clock
	 pll_lock			: in std_logic;
    reset       	: in    std_logic;      -- usually tied to the XST reset button.
    ----USB CONNECTIONS                 -----------------------------------------
    dplus       	: inout std_logic;      --differential + line to/from usb hub(pulled up to 3.3)
    dminus      	: inout std_logic;      --differential minus line to/from usb hub
    ------------------------------------------------------------
	 joyright_out 	: out   std_logic_vector(7 downto 0);
	 joyleft_out 	: out   std_logic_vector(7 downto 0);
	 mousex_out		: out   std_logic_vector(11 downto 0);
	 mousey_out		: out   std_logic_vector(11 downto 0)
    );
end USBF_IFC1;
----------------------------------------------------------------------

architecture arch of USBF_IFC1 is

begin

  UDRVR : USB_DRVR1                   
    port map(
		clk_usb       	=> clk_usb, 
		pll_lock			=> pll_lock,
		reset 			=> reset, 
		dplus 			=> dplus, 
		dminus 			=> dminus,
		joyright_out	=> joyright_out,
		joyleft_out		=> joyleft_out,
		mousex_out		=> mousex_out,
		mousey_out		=> mousey_out
		);

---=============================
end arch;  --END of USBF_IFC
---=============================





