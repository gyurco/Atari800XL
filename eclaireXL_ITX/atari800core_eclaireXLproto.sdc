create_clock -period 5MHz [get_ports CLOCK_5]
derive_pll_clocks
derive_clock_uncertainty

set_clock_groups -asynchronous \
  -group { CLOCK_5 } \
  -group { \
    newboard|pll_acore_inst|pll_acore_inst|altera_pll_i|cyclonev_pll|counter[0].output_counter|divclk \
    newboard|pll_acore_inst|pll_acore_inst|altera_pll_i|cyclonev_pll|counter[1].output_counter|divclk \
    newboard|pll_acore_inst|pll_acore_inst|altera_pll_i|cyclonev_pll|counter[2].output_counter|divclk \
    newboard|pll_acore_inst|pll_acore_inst|altera_pll_i|cyclonev_pll|counter[3].output_counter|divclk \
    newboard|pll_acore_inst|pll_acore_inst|altera_pll_i|cyclonev_pll|fpll_0|fpll|vcoph[0]  \
  } \
  -group { \
    pll_gclk_inst|pll_gclk_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0] \
    pll_gclk_inst|pll_gclk_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk \
  } \
  -group { \
    newboard|pll_hdmi_inst|pll_hdmi_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0] \
    newboard|pll_hdmi_inst|pll_hdmi_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk \
    newboard|pll_hdmi_inst|pll_hdmi_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk \
  } \
  -group { \
    newboard|pllusbinstance|pll_usb_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0] \
    newboard|pllusbinstance|pll_usb_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk \
  } \
  -group { \
    newboard|pllusbinstance|pll_usb_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk \
  }

#create_generated_clock -name sdram_clk -source pll_acore_inst|pll_acore_inst|altera_pll_i|cyclonev_pll|counter[1].output_counter|divclk
#set_output_delay -clock sdram_clk -max 6.0 [get_ports DRAM_DQ[*]]
#set_output_delay -clock sdram_clk -min -1.0 [get_ports DRAM_DQ[*]] 
#
#set_input_delay -clock sdram_clk -max 6.0 [get_ports DRAM_DQ[*]]
#set_input_delay -clock sdram_clk -min 0.0 [get_ports DRAM_DQ[*]] 
#
#set_output_delay -clock sdram_clk -max 6.0 [get_ports DRAM_ADDR[*]]
#set_output_delay -clock sdram_clk -min -1.0 [get_ports DRAM_ADDR[*]] 
#
#set_output_delay -clock sdram_clk -max 6.0 [get_ports DRAM_BA_0]
#set_output_delay -clock sdram_clk -min -1.0 [get_ports DRAM_BA_0] 
#
#set_output_delay -clock sdram_clk -max 6.0 [get_ports DRAM_BA_1]
#set_output_delay -clock sdram_clk -min -1.0 [get_ports DRAM_BA_1] 
#
#set_output_delay -clock sdram_clk -max 6.0 [get_ports DRAM_RAS_N]
#set_output_delay -clock sdram_clk -min -1.0 [get_ports DRAM_RAS_N]
#
#set_output_delay -clock sdram_clk -max 6.0 [get_ports DRAM_CAS_N]
#set_output_delay -clock sdram_clk -min -1.0 [get_ports DRAM_CAS_N]
#
#set_output_delay -clock sdram_clk -max 6.0 [get_ports DRAM_WE_N]
#set_output_delay -clock sdram_clk -min -1.0 [get_ports DRAM_WE_N]
#
#set_output_delay -clock sdram_clk -max 6.0 [get_ports DRAM_LDQM]
#set_output_delay -clock sdram_clk -min -1.0 [get_ports DRAM_LDQM]
#
#set_output_delay -clock sdram_clk -max 6.0 [get_ports DRAM_UDQM]
#set_output_delay -clock sdram_clk -min -1.0 [get_ports DRAM_UDQM]
#
#set_output_delay -clock sdram_clk -max 6.0 [get_ports DRAM_CKE]
#set_output_delay -clock sdram_clk -min -1.0 [get_ports DRAM_CKE]
#
