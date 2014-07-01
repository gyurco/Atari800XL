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
		"internal_ram" => 16384,
		"internal_rom" => 1,
		"ext_clock" => 0
	},
	"PAL_SVIDEO" => 
	{
		"TV" => $PAL,
		"SCANDOUBLE" => 0,
		"VIDEO" => $SVIDEO,
		"internal_ram" => 0,
		"internal_rom" => 0,
		"ext_clock" => 0
	},
	"PAL_RGB" =>
	{
		"TV" => $PAL,
		"SCANDOUBLE" => 0,
		"VIDEO" => $VGA,
		"internal_ram" => 0,
		"internal_rom" => 0,
		"ext_clock" => 0
	},
	"PAL_VGA" =>
	{
		"TV" => $PAL,
		"SCANDOUBLE" => 1,
		"VIDEO" => $VGA,
		"internal_ram" => 0,
		"internal_rom" => 0,
		"ext_clock" => 0
	},
	"NTSC_SVIDEO" =>
	{
		"TV" => $NTSC,
		"SCANDOUBLE" => 0,
		"VIDEO" => $SVIDEO,
		"internal_ram" => 0,
		"internal_rom" => 0,
		"ext_clock" => 0
	},
	"NTSC_RGB" => 
	{
		"TV" => $NTSC,
		"SCANDOUBLE" => 0,
		"VIDEO" => $VGA,
		"internal_ram" => 0,
		"internal_rom" => 0,
		"ext_clock" => 0
	},
	"NTSC_VGA" => 
	{
		"TV" => $NTSC,
		"SCANDOUBLE" => 1,
		"VIDEO" => $VGA,
		"internal_ram" => 0,
		"internal_rom" => 0,
		"ext_clock" => 0
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
	`cp zpu_rom.vhdl $dir`;
	`cp atari800core.sdc $dir`;
	`mkdir $dir/common`;
	`mkdir $dir/common/a8core`;
	`mkdir $dir/common/components`;
	`mkdir $dir/common/zpu`;
	`mkdir $dir/svideo`;
	`cp ../common/a8core/* ./$dir/common/a8core`;
	`cp ../common/components/* ./$dir/common/components`;
	`cp ../common/zpu/* ./$dir/common/zpu`;
	`cp ./svideo/* ./$dir/svideo`;

	chdir $dir;
	`../makeqsf ../atari800core.qsf ./svideo ./common/a8core ./common/components ./common/zpu`;

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
	my $version = `svn info  | grep Revision: | cut -d' ' -f 2`;
	chomp $version;
	$version = `date +%Y%m%d`;
	chomp $version;
	my $cmd = "wine ../rbf2arg/rbf2arg.exe $vga A 0.$version \"Atari 800XL $variant\" output_files/atari800core.rbf output_files/atari800core_$variant.arg";
	print "Running $cmd\n";
	`$cmd`;
	
	chdir "..";
}


#--for the MCC216 S-Video
#--rbf2arg 0 A <version.revison> "description" <filename.rbf> <filename.arg>
#--for the MCC216 VGA
#--rbf2arg 1 A <version.revison> "description" <filename.rbf> <filename.arg>


