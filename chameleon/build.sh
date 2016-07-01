#!/usr/bin/perl -w
use strict;

my $wanted_variant = shift @ARGV;

my $name="chameleon";

#variants...
my $PAL = 1;
my $NTSC = 0;

my $RGB = 1; # i.e. not scandoubled
my $VGA = 2;

my $XL = 0;
my $A800 = 1;

#Added like this to the generated qsf
#set_parameter -name TV 1

my %variants = 
(
	"PAL_RGB_800" => 
	{
		"TV" => $PAL,
		"SCANDOUBLE" => 0,
		"VIDEO" => $RGB,
		"COMPOSITE_SYNC" => 1,
		"SYSTEM" => $A800
	},
	"PAL_RGB_XL" => 
	{
		"TV" => $PAL,
		"SCANDOUBLE" => 0,
		"VIDEO" => $RGB,
		"COMPOSITE_SYNC" => 1,
		"SYSTEM" => $XL
	},
	"PAL_RGBHV" => 
	{
		"TV" => $PAL,
		"SCANDOUBLE" => 0,
		"VIDEO" => $RGB,
		"COMPOSITE_SYNC" => 0,
		"SYSTEM" => $XL
	},
	"PAL_VGA" =>
	{
		"TV" => $PAL,
		"SCANDOUBLE" => 1,
		"VIDEO" => $VGA,
		"COMPOSITE_SYNC" => 0,
		"SYSTEM" => $XL
	},
	"PAL_VGA_CS" =>
	{
		"TV" => $PAL,
		"SCANDOUBLE" => 1,
		"VIDEO" => $VGA,
		"COMPOSITE_SYNC" => 1,
		"SYSTEM" => $XL
	},
	"NTSC_RGB" =>
	{
		"TV" => $NTSC,
		"SCANDOUBLE" => 0,
		"VIDEO" => $RGB, 
		"COMPOSITE_SYNC" => 1,
		"SYSTEM" => $XL
	},
	"NTSC_RGBHV" =>
	{
		"TV" => $NTSC,
		"SCANDOUBLE" => 0,
		"VIDEO" => $RGB, 
		"COMPOSITE_SYNC" => 0,
		"SYSTEM" => $XL
	},
	"NTSC_VGA" => 
	{
		"TV" => $NTSC,
		"SCANDOUBLE" => 1,
		"VIDEO" => $VGA,
		"COMPOSITE_SYNC" => 0,
		"SYSTEM" => $XL
	},
	"NTSC_VGA_CS" => 
	{
		"TV" => $NTSC,
		"SCANDOUBLE" => 1,
		"VIDEO" => $VGA,
		"COMPOSITE_SYNC" => 1,
		"SYSTEM" => $XL
	}
);

if (not defined $wanted_variant or (not exists $variants{$wanted_variant} and $wanted_variant ne "ALL"))
{
	die "Provide variant of ALL or ".join ",",sort keys %variants;
}

foreach my $variant (sort keys %variants)
{
	next if ($wanted_variant ne $variant and $wanted_variant ne "ALL");
	print "Building $variant of $name\n";

	my $dir = "build_$variant";
	`rm -rf $dir`;
	mkdir $dir;
	`cp atari800core_chameleon.vhd $dir`;
	`cp *pll*.* $dir`;
	`cp *.vhdl $dir`;
	`cp chameleon_*.* $dir`;
	`cp gen_*.* $dir`;
	`cp zpu_rom.vhdl $dir`;
	`cp atari800core.sdc $dir`;
	`mkdir $dir/common`;
	`mkdir $dir/common/a8core`;
	`mkdir $dir/common/components`;
	`mkdir $dir/common/zpu`;
	`cp ../common/a8core/* ./$dir/common/a8core`;
	`cp ../common/components/* ./$dir/common/components`;
	`cp ../common/zpu/* ./$dir/common/zpu`;

	chdir $dir;
	`../makeqsf ../atari800core.qsf ./common/a8core ./common/components ./common/zpu`;

	foreach my $key (sort keys %{$variants{$variant}})
	{
		my $val = $variants{$variant}->{$key};
		`echo set_parameter -name $key $val >> atari800core.qsf`;
	}

	`quartus_sh --flow compile atari800core > build.log 2> build.err`;

	`quartus_cpf --convert ../output_file.cof`;
	
	chdir "..";
}

