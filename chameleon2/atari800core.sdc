create_clock -period 50MHz [get_ports CLK50M]
derive_pll_clocks
derive_clock_uncertainty

set_clock_groups -asynchronous \
  -group { clk50m } \
  -group { \
	\gen_pal_pll:chameleon_pll2|altpll_component|auto_generated|pll1|clk[0]
	\gen_pal_pll:chameleon_pll2|altpll_component|auto_generated|pll1|clk[1]
	\gen_pal_pll:chameleon_pll2|altpll_component|auto_generated|pll1|clk[2]
  } 

