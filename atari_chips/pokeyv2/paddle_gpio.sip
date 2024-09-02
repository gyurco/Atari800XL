set_global_assignment -entity "paddle_gpio" -library "lib_paddle_gpio" -name IP_TOOL_NAME "altera_gpio_lite"
set_global_assignment -entity "paddle_gpio" -library "lib_paddle_gpio" -name IP_TOOL_VERSION "23.1"
set_global_assignment -entity "paddle_gpio" -library "lib_paddle_gpio" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_paddle_gpio" -name SPD_FILE [file join $::quartus(sip_path) "paddle_gpio.spd"]

set_global_assignment -library "lib_paddle_gpio" -name MISC_FILE [file join $::quartus(sip_path) "paddle_gpio_sim/paddle_gpio.vhd"]
set_global_assignment -library "lib_paddle_gpio" -name MISC_FILE [file join $::quartus(sip_path) "paddle_gpio_sim/altera_gpio_lite/altera_gpio_lite.sv"]
set_global_assignment -library "lib_paddle_gpio" -name MISC_FILE [file join $::quartus(sip_path) "paddle_gpio_sim/altera_gpio_lite/mentor/altera_gpio_lite.sv"]
