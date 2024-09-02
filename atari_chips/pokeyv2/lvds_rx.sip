set_global_assignment -entity "lvds_rx" -library "lib_lvds_rx" -name IP_TOOL_NAME "altera_soft_lvds"
set_global_assignment -entity "lvds_rx" -library "lib_lvds_rx" -name IP_TOOL_VERSION "23.1"
set_global_assignment -entity "lvds_rx" -library "lib_lvds_rx" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_lvds_rx" -name SPD_FILE [file join $::quartus(sip_path) "lvds_rx.spd"]

set_global_assignment -library "lib_lvds_rx" -name MISC_FILE [file join $::quartus(sip_path) "lvds_rx_sim/lvds_rx.vhd"]
set_global_assignment -library "lib_lvds_rx" -name MISC_FILE [file join $::quartus(sip_path) "lvds_rx_sim/altera_soft_lvds/altera_soft_lvds_rx_uCmNW05P.v"]
