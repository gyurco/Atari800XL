set_global_assignment -entity "pll_hdmi2" -library "lib_pll_hdmi2" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pll_hdmi2" -library "lib_pll_hdmi2" -name IP_TOOL_VERSION "18.0"
set_global_assignment -entity "pll_hdmi2" -library "lib_pll_hdmi2" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pll_hdmi2" -name SPD_FILE [file join $::quartus(sip_path) "pll_hdmi2.spd"]

set_global_assignment -library "lib_pll_hdmi2" -name MISC_FILE [file join $::quartus(sip_path) "pll_hdmi2_sim/pll_hdmi2.vho"]
