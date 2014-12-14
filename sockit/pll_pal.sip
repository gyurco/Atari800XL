set_global_assignment -entity "pll_pal" -library "lib_pll_pal" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pll_pal" -library "lib_pll_pal" -name IP_TOOL_VERSION "14.0"
set_global_assignment -entity "pll_pal" -library "lib_pll_pal" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pll_pal" -name SPD_FILE [file join $::quartus(sip_path) "pll_pal.spd"]

set_global_assignment -library "lib_pll_pal" -name MISC_FILE [file join $::quartus(sip_path) "pll_pal_sim/pll_pal.vho"]
