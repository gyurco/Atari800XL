set_global_assignment -entity "lvds_tx" -library "lib_lvds_tx" -name IP_TOOL_NAME "altera_soft_lvds"
set_global_assignment -entity "lvds_tx" -library "lib_lvds_tx" -name IP_TOOL_VERSION "20.1"
set_global_assignment -entity "lvds_tx" -library "lib_lvds_tx" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_lvds_tx" -name SPD_FILE [file join $::quartus(sip_path) "lvds_tx.spd"]

set_global_assignment -library "lib_lvds_tx" -name MISC_FILE [file join $::quartus(sip_path) "lvds_tx_sim/lvds_tx.vhd"]
set_global_assignment -library "lib_lvds_tx" -name MISC_FILE [file join $::quartus(sip_path) "lvds_tx_sim/altera_soft_lvds/altera_soft_lvds_tx_twD5CSXW.v"]
