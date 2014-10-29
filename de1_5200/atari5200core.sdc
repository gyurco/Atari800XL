create_clock -period 50MHz [get_ports CLOCK_50]
derive_pll_clocks

set_input_delay -max -clock CLOCK_50 -1.5 [get_ports SRAM_DQ*]
set_input_delay -min -clock CLOCK_50 -1.5 [get_ports SRAM_DQ*]

