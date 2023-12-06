#!/usr/bin/perl -w
use strict;

my $wanted_variant = shift @ARGV;

my $name="mist 5200";

#variants...
my $NTSC = 0;

#Added like this to the generated qsf
#set_parameter -name TV 1

my %variants =
(
        "mist" =>
        {
        },
        "SiDi128" =>
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
	`cp build_id.tcl $dir`;
	`cp atari5200core_mist.vhd atari5200_mist_top.sv $dir`;
	`cp *pll*.* $dir`;
	`cp *.v $dir`;
	`cp *.vhdl $dir`;
	`cp zpu_rom.vhdl $dir`;
	`cp atari5200core.sdc $dir`;
	`mkdir $dir/common`;
	`mkdir $dir/common/a8core`;
	`mkdir $dir/common/components`;
	`mkdir $dir/common/zpu`;
	`cp ../common/a8core/* ./$dir/common/a8core`;
	`cp -r ../common/components/* ./$dir/common/components`;
	`mv ./$dir/common/components/*cyclone3/* ./$dir/common/components/`;
	`cp ../common/zpu/* ./$dir/common/zpu`;
	`rm ./$dir/common/a8core/atari800core_helloworld.vhd`;
	`rm ./$dir/common/a8core/atari800nx_core_simple_sdram.vhd`;
	`rm ./$dir/common/a8core/atari800xl.vhd`;
	`rm ./$dir/common/a8core/internalromram_fast.vhd`;
	`rm ./$dir/common/a8core/internalromram_simple.vhd`;

	chdir $dir;
	`../makeqsf ../atari5200_$variant.qsf ./common/a8core ./common/components ./common/zpu`;

	foreach my $key (sort keys %{$variants{$variant}})
	{
		my $val = $variants{$variant}->{$key};
		`echo set_parameter -name $key $val >> atari5200core.qsf`;
	}

	`quartus_sh --flow compile atari5200_$variant > build.log 2> build.err`;

	`quartus_cpf --convert ../output_file.cof`;
	
	chdir "..";
}

