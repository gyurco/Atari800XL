
module sfl (
	noe_in,
	dclk_in,
	ncso_in,
	data_in,
	data_oe,
	asmi_access_granted,
	data_out,
	asmi_access_request);	

	input		noe_in;
	input		dclk_in;
	input		ncso_in;
	input	[3:0]	data_in;
	input	[3:0]	data_oe;
	input		asmi_access_granted;
	output	[3:0]	data_out;
	output		asmi_access_request;
endmodule
