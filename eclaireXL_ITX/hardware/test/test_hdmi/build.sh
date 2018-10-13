#!/usr/bin/perl -w
use strict;

my $wanted_variant = shift @ARGV;

my $name="eclaireXL";

#variants...
my $PAL = 1;
my $NTSC = 0;

my $RGB = 1; # i.e. not scandoubled
my $VGA = 2;

#Added like this to the generated qsf
#set_parameter -name TV 1

my %variants = 
(
#	"PAL" => 
#	{
#		"TV" => $PAL
#	},
#	"NTSC" =>
#	{
#		"TV" => $NTSC
#	},
	"A2EBA_HDMI" =>
	{
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
	`cp -a hdmi $dir`;
	`cp -a pll2* $dir`;
	`cp *.v $dir`;
	`cp *.vhd* $dir`;
	`cp atari800core*.sdc $dir`;
	`mkdir $dir/common`;

	chdir $dir;
	`../../../../makeqsf ../atari800core_eclaireXL.qsf ./hdmi`;

	foreach my $key (sort keys %{$variants{$variant}})
	{
		my $val = $variants{$variant}->{$key};
		`echo set_parameter -name $key $val >> atari800core_eclaireXL.qsf`;
	}

	`quartus_sh --flow compile atari800core_eclaireXL > build.log 2> build.err`;

#	`quartus_cpf --convert ../output_file.cof`;
	
	chdir "..";
}

