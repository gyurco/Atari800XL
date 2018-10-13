
module ddioclkctrl (
	inclk3x,
	inclk2x,
	inclk1x,
	inclk0x,
	clkselect,
	ena,
	outclk);	

	input		inclk3x;
	input		inclk2x;
	input		inclk1x;
	input		inclk0x;
	input	[1:0]	clkselect;
	input		ena;
	output		outclk;
endmodule
