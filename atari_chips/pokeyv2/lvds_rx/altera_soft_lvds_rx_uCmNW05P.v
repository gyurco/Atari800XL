//lpm_ff CBX_DECLARE_ALL_CONNECTED_PORTS="OFF" CBX_SINGLE_OUTPUT_FILE="ON" LPM_WIDTH=1 clock data q
//VERSION_BEGIN 23.1 cbx_lpm_ff 2024:05:14:17:53:42:SC cbx_mgl 2024:05:14:18:00:13:SC  VERSION_END
// synthesis VERILOG_INPUT_VERSION VERILOG_2001
// altera message_off 10463



// Copyright (C) 2024  Intel Corporation. All rights reserved.
//  Your use of Intel Corporation's design tools, logic functions 
//  and other software and tools, and any partner logic 
//  functions, and any output files from any of the foregoing 
//  (including device programming or simulation files), and any 
//  associated documentation or information are expressly subject 
//  to the terms and conditions of the Intel Program License 
//  Subscription Agreement, the Intel Quartus Prime License Agreement,
//  the Intel FPGA IP License Agreement, or other applicable license
//  agreement, including, without limitation, that your use is for
//  the sole purpose of programming logic devices manufactured by
//  Intel and sold by Intel or its authorized distributors.  Please
//  refer to the applicable agreement for further details, at
//  https://fpgasoftware.intel.com/eula.



//synthesis_resources = lut 1 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
module  altera_soft_lvds_rx_uCmNW05P
	( 
	clock,
	data,
	q) /* synthesis synthesis_clearbox=1 */;
	input   clock;
	input   [0:0]  data;
	output   [0:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri0   [0:0]  data;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	reg	[0:0]	ff_dffe;
	wire enable;

	// synopsys translate_off
	initial
		ff_dffe = 0;
	// synopsys translate_on
	always @ ( posedge clock)
		if (enable == 1'b1)   ff_dffe <= data;
	assign
		enable = 1'b1,
		q = ff_dffe;
endmodule //altera_soft_lvds_rx_uCmNW05P
//VALID FILE
