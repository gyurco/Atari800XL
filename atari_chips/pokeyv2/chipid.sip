set_global_assignment -entity "chipid" -library "lib_chipid" -name IP_TOOL_NAME "altchip_id"
set_global_assignment -entity "chipid" -library "lib_chipid" -name IP_TOOL_VERSION "19.1"
set_global_assignment -entity "chipid" -library "lib_chipid" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_chipid" -name SPD_FILE [file join $::quartus(sip_path) "chipid.spd"]

set_global_assignment -library "lib_chipid" -name MISC_FILE [file join $::quartus(sip_path) "chipid_sim/chipid.vhd"]
set_global_assignment -library "lib_chipid" -name MISC_FILE [file join $::quartus(sip_path) "chipid_sim/altchip_id/mentor/altchip_id.v"]
set_global_assignment -library "lib_chipid" -name MISC_FILE [file join $::quartus(sip_path) "chipid_sim/altchip_id/cadence/altchip_id.v"]
set_global_assignment -library "lib_chipid" -name MISC_FILE [file join $::quartus(sip_path) "chipid_sim/altchip_id/synopsys/altchip_id.v"]
set_global_assignment -library "lib_chipid" -name MISC_FILE [file join $::quartus(sip_path) "chipid_sim/altchip_id/aldec/altchip_id.v"]
