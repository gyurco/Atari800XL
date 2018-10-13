set_global_assignment -entity "pll_acore_reconfig" -library "lib_pll_acore_reconfig" -name IP_TOOL_NAME "altera_pll_reconfig"
set_global_assignment -entity "pll_acore_reconfig" -library "lib_pll_acore_reconfig" -name IP_TOOL_VERSION "16.1"
set_global_assignment -entity "pll_acore_reconfig" -library "lib_pll_acore_reconfig" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pll_acore_reconfig" -name SPD_FILE [file join $::quartus(sip_path) "pll_acore_reconfig.spd"]

set_global_assignment -library "lib_pll_acore_reconfig" -name MISC_FILE [file join $::quartus(sip_path) "pll_acore_reconfig_sim/pll_acore_reconfig.vhd"]
set_global_assignment -library "lib_pll_acore_reconfig" -name MISC_FILE [file join $::quartus(sip_path) "pll_acore_reconfig_sim/altera_pll_reconfig/altera_pll_reconfig_top.v"]
set_global_assignment -library "lib_pll_acore_reconfig" -name MISC_FILE [file join $::quartus(sip_path) "pll_acore_reconfig_sim/altera_pll_reconfig/altera_pll_reconfig_core.v"]
set_global_assignment -library "lib_pll_acore_reconfig" -name MISC_FILE [file join $::quartus(sip_path) "pll_acore_reconfig_sim/altera_pll_reconfig/altera_std_synchronizer.v"]
