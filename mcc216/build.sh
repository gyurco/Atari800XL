#!/usr/bin/perl -w
use strict;

my $wanted_variant = shift @ARGV;

#variants...
my $PAL = 1;
my $NTSC = 0;

my $SVIDEO = 1;
my $VGA = 2;

#Added like this to the generated qsf
#set_parameter -name TV 1

my %variants = 
(
	"SIMPLE" =>
	{
		"TV" => $PAL,
		"SCANDOUBLE" => 0,
		"VIDEO" => $VGA,
		"internal_ram" => 16384
	},
	"PAL_SVIDEO" => 
	{
		"TV" => $PAL,
		"SCANDOUBLE" => 0,
		"VIDEO" => $SVIDEO,
		"internal_ram" => 0
	},
	"PAL_VGA" =>
	{
		"TV" => $PAL,
		"SCANDOUBLE" => 1,
		"VIDEO" => $VGA,
		"internal_ram" => 0
	},
	"NTSC_SVIDEO" =>
	{
		"TV" => $NTSC,
		"SCANDOUBLE" => 0,
		"VIDEO" => $SVIDEO,
		"internal_ram" => 0
	},
	"NTSC_VGA" => 
	{
		"TV" => $NTSC,
		"SCANDOUBLE" => 1,
		"VIDEO" => $VGA,
		"internal_ram" => 0
	}
);

if (not defined $wanted_variant or (not exists $variants{$wanted_variant} and $wanted_variant ne "ALL"))
{
	die "Provide variant of ALL or ".join ",",sort keys %variants;
}

foreach my $variant (sort keys %variants)
{
	next if ($wanted_variant ne $variant and $wanted_variant ne "ALL");
	print "Building $variant\n";

	my $dir = "build_$variant";
	`rm -rf $dir`;
	mkdir $dir;
	`cp atari800core_mcc.vhd $dir`;
	`cp *pll*.* $dir`;
	`cp sdram_ctrl_3_ports.v $dir`;
	`cp atari800core.sdc $dir`;

	chdir $dir;
	`../makeqsf ../atari800core.qsf ../svideo ../../common/a8core ../../common/components`;

	foreach my $key (sort keys %{$variants{$variant}})
	{
		my $val = $variants{$variant}->{$key};
		`echo set_parameter -name $key $val >> atari800core.qsf`;
	}

	`quartus_sh --flow compile atari800core > build.log 2> build.err`;

	`quartus_cpf --convert ../output_file.cof`;
	my $vga = 1;
	if ($variant =~ /SVIDEO/)
	{
		$vga = 0;
	}
	
	#TODO - generate automated version number
	my $version = `svn info  | grep Revision: | cut -c11`;
	chomp $version;
	$version.=".0";
	`wine ../rbf2arg/rbf2arg.exe $vga A 0.3 "Atari 800XL" output_files/atari800core.rbf output_files/atari800core.arg`;
	
	chdir "..";
}


#--for the MCC216 S-Video
#--rbf2arg 0 A <version.revison> "description" <filename.rbf> <filename.arg>
#--for the MCC216 VGA
#--rbf2arg 1 A <version.revison> "description" <filename.rbf> <filename.arg>


