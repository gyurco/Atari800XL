create_clock -period 40MHz [get_ports CLK]
derive_pll_clocks
derive_clock_uncertainty

create_clock -period 14MHz -name sram_clk
set_output_delay -clock sram_clk -max 60.0 [get_ports EXT_SRAM_ADDR[*]]
set_output_delay -clock sram_clk -min 0.0 [get_ports EXT_SRAM_ADDR[*]] 

set_output_delay -clock sram_clk -max 60.0 [get_ports EXT_SRAM_DATA[*]]
set_output_delay -clock sram_clk -min 0.0 [get_ports EXT_SRAM_DATA[*]] 
set_input_delay -clock sram_clk -max 60.0 [get_ports EXT_SRAM_DATA[*]]
set_input_delay -clock sram_clk -min 0.0 [get_ports EXT_SRAM_DATA[*]] 

