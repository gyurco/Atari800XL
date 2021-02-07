set_global_assignment -entity "osc_in" -library "lib_osc_in" -name IP_TOOL_NAME "altera_gpio_lite"
set_global_assignment -entity "osc_in" -library "lib_osc_in" -name IP_TOOL_VERSION "18.0"
set_global_assignment -entity "osc_in" -library "lib_osc_in" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_osc_in" -name SPD_FILE [file join $::quartus(sip_path) "osc_in.spd"]

set_global_assignment -library "lib_osc_in" -name MISC_FILE [file join $::quartus(sip_path) "osc_in_sim/osc_in.vhd"]
set_global_assignment -library "lib_osc_in" -name MISC_FILE [file join $::quartus(sip_path) "osc_in_sim/altera_gpio_lite/altera_gpio_lite.sv"]
set_global_assignment -library "lib_osc_in" -name MISC_FILE [file join $::quartus(sip_path) "osc_in_sim/altera_gpio_lite/mentor/altera_gpio_lite.sv"]
