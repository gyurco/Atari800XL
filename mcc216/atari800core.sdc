create_clock -period 5MHz [get_ports FPGA_CLK]
derive_pll_clocks
derive_clock_uncertainty

set_clock_groups -asynchronous \
  -group { FPGA_CLK } \
  -group { \
    \gen_real_pll:gen_tv_pal:mcc_pll2|altpll_component|auto_generated|pll1|clk[0]
    \gen_real_pll:gen_tv_pal:mcc_pll2|altpll_component|auto_generated|pll1|clk[1]
    \gen_real_pll:gen_tv_pal:mcc_pll2|altpll_component|auto_generated|pll1|clk[2]
  } \
  -group { \
    usb_pll|altpll_component|auto_generated|pll1|clk[0]
  } 

