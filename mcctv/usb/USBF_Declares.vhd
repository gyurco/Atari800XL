--==============================================================================
--  USB Interface Declares
------------------------------------------------------------------
--Copywrite Johns Hopkins University ECE department
--This software may be freely used and modified as long as this header is retained. 
------------------------------------------------------------------
--Description: Defines constants and components used to make the FPGA act as a 
--  HID USB peripheral, and communicate over the D+/D- lines with the host.
--   
-- Authors: Brian Duddie, Brian Miller, R.E. Jenkins
-- Last Modification: Jan 3, 2009
--==============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--==================================================================
package USBF_Declares is
--==================================================================

--====================================================
--USB_DRVR COMPONENT Declaration        ----------------------
--====================================================
  component USB_DRVR1 is
                       port(
                         clk_usb       : in    std_logic;  --12MHz clock
								 pll_lock		: in    std_logic;
                         reset         : in    std_logic;  --fpga reset
                         dminus        : inout std_logic;  -- USB differential D+ line
                         dplus         : inout std_logic;  -- USB differential D+ line
								 joyright_out 	: out   std_logic_vector(7 downto 0);
								 joyleft_out 	: out   std_logic_vector(7 downto 0);
								 mousex_out		: out   std_logic_vector(11 downto 0);
								 mousey_out		: out   std_logic_vector(11 downto 0)
                         );
  end component;
-------------------------------------------------------
  component USBF_IFC1 is
                       port(
                         clk_usb       : in    std_logic;  --12MHz clock
								 pll_lock		: in    std_logic;
                         reset         : in    std_logic;  -- XST reset push button
                         ----USB CONNECTIONS  ---------
                         dplus         : inout std_logic;
                         dminus        : inout std_logic;
                         ----------------------------------
								 joyright_out 	: out   std_logic_vector(7 downto 0);
								 joyleft_out 	: out   std_logic_vector(7 downto 0);
								 mousex_out		: out   std_logic_vector(11 downto 0);
								 mousey_out		: out   std_logic_vector(11 downto 0)
                         );
  end component;
  
--====================================================
--USB_DRVR COMPONENT Declaration        ----------------------
--====================================================
  component USB_DRVR2 is
                       port(
                         clk_usb       : in    std_logic;  --12MHz clock
								 pll_lock		: in    std_logic;
                         reset         : in    std_logic;  --fpga reset
                         dminus        : inout std_logic;  -- USB differential D+ line
                         dplus         : inout std_logic;  -- USB differential D+ line
								 joyright_out 	: out   std_logic_vector(7 downto 0);
								 joyleft_out 	: out   std_logic_vector(7 downto 0);
								 mousex_out		: out   std_logic_vector(11 downto 0);
								 mousey_out		: out   std_logic_vector(11 downto 0)
                         );
  end component;
-------------------------------------------------------
  component USBF_IFC2 is
                       port(
                         clk_usb       : in    std_logic;  --12MHz clock
								 pll_lock		: in    std_logic;
                         reset         : in    std_logic;  -- XST reset push button
                         ----USB CONNECTIONS  ---------
                         dplus         : inout std_logic;
                         dminus        : inout std_logic;
                         ----------------------------------
								 joyright_out 	: out   std_logic_vector(7 downto 0);
								 joyleft_out 	: out   std_logic_vector(7 downto 0);
								 mousex_out		: out   std_logic_vector(11 downto 0);
								 mousey_out		: out   std_logic_vector(11 downto 0)
                         );
  end component;

--==============================================================================
END PACKAGE USBF_Declares;
--==============================================================================

--==============================================================================
