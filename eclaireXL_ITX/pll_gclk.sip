set_global_assignment -entity "pll_gclk" -library "lib_pll_gclk" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pll_gclk" -library "lib_pll_gclk" -name IP_TOOL_VERSION "16.1"
set_global_assignment -entity "pll_gclk" -library "lib_pll_gclk" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pll_gclk" -name SPD_FILE [file join $::quartus(sip_path) "pll_gclk.spd"]

set_global_assignment -library "lib_pll_gclk" -name MISC_FILE [file join $::quartus(sip_path) "pll_gclk_sim/pll_gclk.vho"]
