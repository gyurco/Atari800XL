set_global_assignment -entity "osc_out" -library "lib_osc_out" -name IP_TOOL_NAME "altera_gpio_lite"
set_global_assignment -entity "osc_out" -library "lib_osc_out" -name IP_TOOL_VERSION "18.0"
set_global_assignment -entity "osc_out" -library "lib_osc_out" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_osc_out" -name SPD_FILE [file join $::quartus(sip_path) "osc_out.spd"]

set_global_assignment -library "lib_osc_out" -name MISC_FILE [file join $::quartus(sip_path) "osc_out_sim/osc_out.vhd"]
set_global_assignment -library "lib_osc_out" -name MISC_FILE [file join $::quartus(sip_path) "osc_out_sim/altera_gpio_lite/altera_gpio_lite.sv"]
set_global_assignment -library "lib_osc_out" -name MISC_FILE [file join $::quartus(sip_path) "osc_out_sim/altera_gpio_lite/mentor/altera_gpio_lite.sv"]
