//altlvds_tx CBX_DECLARE_ALL_CONNECTED_PORTS="OFF" CBX_SINGLE_OUTPUT_FILE="ON" COMMON_RX_TX_PLL="OFF" CORECLOCK_DIVIDE_BY=2 DATA_RATE="720.0 Mbps" DESERIALIZATION_FACTOR=1 DEVICE_FAMILY="MAX 10" DIFFERENTIAL_DRIVE=0 ENABLE_CLK_LATENCY="OFF" IMPLEMENT_IN_LES="ON" INCLOCK_BOOST=0 INCLOCK_DATA_ALIGNMENT="EDGE_ALIGNED" INCLOCK_PERIOD=5000 INCLOCK_PHASE_SHIFT=0 MULTI_CLOCK="OFF" NUMBER_OF_CHANNELS=1 OUTCLOCK_ALIGNMENT="EDGE_ALIGNED" OUTCLOCK_DIVIDE_BY=1 OUTCLOCK_DUTY_CYCLE=50 OUTCLOCK_MULTIPLY_BY=1 OUTCLOCK_PHASE_SHIFT=0 OUTCLOCK_RESOURCE="AUTO" OUTPUT_DATA_RATE=720 PLL_COMPENSATION_MODE="AUTO" PLL_SELF_RESET_ON_LOSS_LOCK="OFF" PREEMPHASIS_SETTING=0 REGISTERED_INPUT="OFF" USE_EXTERNAL_PLL="OFF" USE_NO_PHASE_SHIFT="ON" VOD_SETTING=0 tx_in tx_inclock tx_out CARRY_CHAIN="MANUAL" CARRY_CHAIN_LENGTH=48
//VERSION_BEGIN 20.1 cbx_altaccumulate 2020:11:11:17:03:37:SJ cbx_altclkbuf 2020:11:11:17:03:37:SJ cbx_altddio_in 2020:11:11:17:03:37:SJ cbx_altddio_out 2020:11:11:17:03:37:SJ cbx_altera_syncram_nd_impl 2020:11:11:17:03:37:SJ cbx_altiobuf_bidir 2020:11:11:17:03:37:SJ cbx_altiobuf_in 2020:11:11:17:03:37:SJ cbx_altiobuf_out 2020:11:11:17:03:37:SJ cbx_altlvds_tx 2020:11:11:17:03:37:SJ cbx_altpll 2020:11:11:17:03:37:SJ cbx_altsyncram 2020:11:11:17:03:37:SJ cbx_arriav 2020:11:11:17:03:36:SJ cbx_cyclone 2020:11:11:17:03:37:SJ cbx_cycloneii 2020:11:11:17:03:37:SJ cbx_lpm_add_sub 2020:11:11:17:03:37:SJ cbx_lpm_compare 2020:11:11:17:03:37:SJ cbx_lpm_counter 2020:11:11:17:03:37:SJ cbx_lpm_decode 2020:11:11:17:03:37:SJ cbx_lpm_mux 2020:11:11:17:03:37:SJ cbx_lpm_shiftreg 2020:11:11:17:03:37:SJ cbx_maxii 2020:11:11:17:03:37:SJ cbx_mgl 2020:11:11:17:50:46:SJ cbx_nadder 2020:11:11:17:03:37:SJ cbx_stratix 2020:11:11:17:03:37:SJ cbx_stratixii 2020:11:11:17:03:37:SJ cbx_stratixiii 2020:11:11:17:03:37:SJ cbx_stratixv 2020:11:11:17:03:37:SJ cbx_util_mgl 2020:11:11:17:03:37:SJ  VERSION_END
// synthesis VERILOG_INPUT_VERSION VERILOG_2001
// altera message_off 10463



// Copyright (C) 2020  Intel Corporation. All rights reserved.
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



//synthesis_resources = 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
module  altera_soft_lvds_tx_twD5CSXW
	( 
	tx_in,
	tx_inclock,
	tx_out) /* synthesis synthesis_clearbox=1 */;
	input   [0:0]  tx_in;
	input   tx_inclock;
	output   [0:0]  tx_out;

	wire  [0:0]  tx_out_wire;

	assign
		tx_out = tx_out_wire,
		tx_out_wire = tx_in;
endmodule //altera_soft_lvds_tx_twD5CSXW
//VALID FILE
