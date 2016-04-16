create_clock -period 40MHz [get_ports CLK]
derive_pll_clocks
derive_clock_uncertainty

create_clock -period 14MHz -name sram_clk
create_clock -period 98MHz -name fast_sram_clk
set_output_delay -clock sram_clk -max 60.0 [get_ports EXT_SRAM_ADDR[*]]
set_output_delay -clock sram_clk -min -1.0 [get_ports EXT_SRAM_ADDR[*]] 

set_output_delay -clock fast_sram_clk -max 1.0 [get_ports EXT_SRAM_WE]
set_output_delay -clock fast_sram_clk -min 0.0 [get_ports EXT_SRAM_WE] 

set_output_delay -clock fast_sram_clk -max 1.0 [get_ports EXT_SRAM_DATA[*]]
set_output_delay -clock fast_sram_clk -min -1.0 [get_ports EXT_SRAM_DATA[*]] 
set_input_delay -clock sram_clk -max 60.0 [get_ports EXT_SRAM_DATA[*]]
set_input_delay -clock sram_clk -min 0.0 [get_ports EXT_SRAM_DATA[*]] 

create_clock -period 14MHz -name cart_clk
set_input_delay -clock cart_clk -max 0.0 [get_ports CART_ADDR[*]]
set_input_delay -clock cart_clk -min 0.0 [get_ports CART_ADDR[*]] 

set_input_delay -clock cart_clk -max 0.0 [get_ports CART_DATA[*]]
set_input_delay -clock cart_clk -min 0.0 [get_ports CART_DATA[*]] 

set_input_delay -clock cart_clk -max 0.0 [get_ports CART_CTL]
set_input_delay -clock cart_clk -min 0.0 [get_ports CART_CTL] 

set_input_delay -clock cart_clk -max 0.0 [get_ports CART_S4]
set_input_delay -clock cart_clk -min 0.0 [get_ports CART_S4] 

set_input_delay -clock cart_clk -max 0.0 [get_ports CART_S5]
set_input_delay -clock cart_clk -min 0.0 [get_ports CART_S5] 

set_input_delay -clock cart_clk -max 0.0 [get_ports CART_RW]
set_input_delay -clock cart_clk -min 0.0 [get_ports CART_RW] 

set_input_delay -clock cart_clk -max 0.0 [get_ports CART_PHI2]
set_input_delay -clock cart_clk -min 0.0 [get_ports CART_PHI2] 

set_output_delay -clock cart_clk -max 0.0 [get_ports CART_DATA[*]]
set_output_delay -clock cart_clk -min 0.0 [get_ports CART_DATA[*]] 

set_output_delay -clock cart_clk -max 0.0 [get_ports CART_RD4]
set_output_delay -clock cart_clk -min 0.0 [get_ports CART_RD4] 

set_output_delay -clock cart_clk -max 0.0 [get_ports CART_RD5]
set_output_delay -clock cart_clk -min 0.0 [get_ports CART_RD5] 

