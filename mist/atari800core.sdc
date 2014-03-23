create_clock -period 27MHz [get_ports CLOCK_27[0]]
derive_pll_clocks
derive_clock_uncertainty