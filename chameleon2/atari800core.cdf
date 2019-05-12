/* Quartus II 64-Bit Version 12.1 Build 243 01/31/2013 Service Pack 1.33 SJ Web Edition */
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Ign)
		Device PartName(CPLD) MfrSpec(OpMask(0));
	P ActionCode(Cfg)
		Device PartName(EP3C25E144) Path("C:/Users/Mark/Desktop/FPGA/build/output_files/") File("atari800core.sof") MfrSpec(OpMask(1));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
