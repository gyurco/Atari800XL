#!/usr/bin/perl -w
use strict;

my $wanted_variant = shift @ARGV;

my $name="eclaireXL";

#Added like this to the generated qsf
#set_parameter -name TV 1

my %variants = 
(
	"A2EBAv3rom" =>
	{
		"internal_ram" => 65536,
		"internal_rom" => 1,
		"fpga" => "5CEBA2F23C8",
		"postfix" => "v3",
		"convert" => "v3a"
	},
	"A4EBAv3rom" =>
	{
		"internal_ram" => 131072,
		"internal_rom" => 1,
		"fpga" => "5CEBA4F23C8",
		"postfix" => "v3",
		"convert" => "v3b"
	},
	"A2EBArom" =>
	{
		"internal_ram" => 65536,
		"internal_rom" => 1,
		"fpga" => "5CEBA2F23C8",
		"postfix" => "v1"
	},
	"A4EBArom" =>
	{
		"internal_ram" => 131072,
		"internal_rom" => 1,
		"fpga" => "5CEBA4F23C8",
		"postfix" => "v2"
	},
#	"A2EBAproto" =>
#	{
#		"internal_ram" => 0,
#		"internal_rom" => 0,
#		"fpga" => "5CEBA2F23C8",
#		"postfix" => "proto"
#	},
#	"A2EBAproto_hdmiOnGPIO" =>
#	{
#		"internal_ram" => 0,
#		"internal_rom" => 0,
#		"fpga" => "5CEBA2F23C8",
#		"postfix" => "proto",
#		"hdmiOnGPIO" => 1
#	},
#	"A2EBA" =>
#	{
#		"internal_ram" => 65536,
#		"internal_rom" => 0,
#		"fpga" => "5CEBA2F23C8",
#		"postfix" => "v1"
#	},
#	"A4EBA" =>
#	{
#		"internal_ram" => 131072,
#		"internal_rom" => 0,
#		"fpga" => "5CEBA4F23C8",
#		"postfix" => "v2"
#	},
#	"A4EBAB" =>
#	{
#		"internal_ram" => 131072,
#		"internal_rom" => 0,
#		"fpga" => "5CEBA4F23C8",
#		"postfix" => "v2"
#	}
);

if (not defined $wanted_variant or (not exists $variants{$wanted_variant} and $wanted_variant ne "ALL"))
{
	die "Provide variant of ALL or ".join ",",sort keys %variants;
}

foreach my $variant (sort keys %variants)
{
	next if ($wanted_variant ne $variant and $wanted_variant ne "ALL");
	print "Building $variant of $name\n";

	my $postfix = $variants{$variant}->{"postfix"};
	delete $variants{$variant}->{"postfix"};

	my $convertpostfix = $postfix;
	if (exists $variants{$variant}->{"convert"})
	{
		$convertpostfix = $variants{$variant}->{"convert"};
		delete $variants{$variant}->{"convert"};
	}

	print `./makemif$postfix BUILD`;

	my $dir = "build_$variant";
	`rm -rf $dir`;
	mkdir $dir;
	`cp -a *pll* $dir`;
	`cp -a *fifo* $dir`;
	`cp -a *zpu_rom* $dir`;
	`cp -a *altddio* $dir`;
 	`cp *.hex ./$dir/`;
	#`cp -a *serial_loader* $dir`;
	`cp *.v $dir`;
	`cp clkctrl* -r $dir`;
	`cp ddioclkctrl* -r $dir`;
	`cp *.vhd* $dir`;
	`cp atari800core*.sdc $dir`;
	`mkdir $dir/common`;
	`mkdir $dir/common/a8core`;
	`mkdir $dir/common/components`;
	`mkdir $dir/common/zpu`;
	`mkdir $dir/svideo`;
 	`mkdir $dir/hdmi`;
	mkdir "./$dir/common/components/usbhostslave";
	`cp ../common/components/usbhostslave/trunk/RTL/*/*.v ./$dir/common/components/usbhostslave`;
	`cp ../common/a8core/* ./$dir/common/a8core`;
	`cp -r ../common/components/* ./$dir/common/components`;
	`mv ./$dir/common/components/*cycloneV/* ./$dir/common/components/`;
	`cp ../common/zpu/* ./$dir/common/zpu`;
	`cp ./svideo/* ./$dir/svideo`;
 	`cp ./hdmi/* ./$dir/hdmi`;
 	`cp -r ./sfl/synthesis/* ./$dir/`;
	`cp zpu_rom$postfix.mif build_$variant/zpu_rom.mif`;

	chdir $dir;

	my $fpga = $variants{$variant}->{"fpga"};
	
 	`../makeqsf ../atari800core_eclaireXL$postfix.qsf ./hdmi ./svideo ./common/a8core ./common/components ./common/zpu ./common/components/usbhostslave`;

	`echo set_global_assignment -name DEVICE $fpga >> atari800core_eclaireXL$postfix.qsf`;

	foreach my $key (sort keys %{$variants{$variant}})
	{
		my $val = $variants{$variant}->{$key};
		`echo set_parameter -name $key $val >> atari800core_eclaireXL$postfix.qsf`;
	}

	`quartus_sh --flow compile atari800core_eclaireXL$postfix > build.log 2> build.err`;

	`quartus_cpf --convert ../convert$convertpostfix.cof`;
	
	chdir "..";
}

