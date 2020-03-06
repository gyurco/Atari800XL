#!/usr/bin/perl -w
use strict;

my $wanted_variant = shift @ARGV;

my $name="eclaireXL";

#Added like this to the generated qsf
#set_parameter -name TV 1

my %variants = 
(
	"10M02_mono" =>
	{
		"stereo" => 0,
		"fpga" => "10M02SCU169C8G"
	},
	"10M02_stereo_auto" =>
	{
		"stereo" => 1,
		"enable_auto_stereo" => 1,
		"enable_stereo_switch" => 0,
		"fpga" => "10M02SCU169C8G"
	},
	"10M02_stereo_u1mb" =>
	{
		"stereo" => 1,
		"enable_auto_stereo" => 0,
		"enable_stereo_switch" => 1,
		"fpga" => "10M02SCU169C8G"
	},
	"10M02_stereo_u1mb_auto" =>
	{
		"stereo" => 1,
		"enable_auto_stereo" => 1,
		"enable_stereo_switch" => 1,
		"fpga" => "10M02SCU169C8G"
	},
	"10M02_quad_auto" =>
	{
		"stereo" => 2,
		"lowpass" => 0,
		"enable_auto_stereo" => 1,
		"fpga" => "10M02SCU169C8G"
	},
	"10M04_mono" =>
	{
		"stereo" => 0,
		"fpga" => "10M04SCU169C8G"
	},
	"10M04_stereo_auto" =>
	{
		"stereo" => 1,
		"enable_auto_stereo" => 1,
		"enable_stereo_switch" => 0,
		"fpga" => "10M04SCU169C8G"
	},
	"10M04_stereo_u1mb" =>
	{
		"stereo" => 1,
		"enable_auto_stereo" => 0,
		"enable_stereo_switch" => 1,
		"fpga" => "10M04SCU169C8G"
	},
	"10M04_stereo_u1mb_auto" =>
	{
		"stereo" => 1,
		"enable_auto_stereo" => 1,
		"enable_stereo_switch" => 1,
		"fpga" => "10M04SCU169C8G"
	},
	"10M04_quad_auto" =>
	{
		"stereo" => 2,
		"enable_auto_stereo" => 1,
		"fpga" => "10M04SCU169C8G"
	},
	"10M08_mono" =>
	{
		"stereo" => 0,
		"fpga" => "10M08SCU169C8G"
	},
	"10M08_stereo_auto" =>
	{
		"stereo" => 1,
		"enable_auto_stereo" => 1,
		"enable_stereo_switch" => 0,
		"fpga" => "10M08SCU169C8G"
	},
	"10M08_stereo_u1mb" =>
	{
		"stereo" => 1,
		"enable_auto_stereo" => 0,
		"enable_stereo_switch" => 1,
		"fpga" => "10M08SCU169C8G"
	},
	"10M08_stereo_u1mb_auto" =>
	{
		"stereo" => 1,
		"enable_auto_stereo" => 1,
		"enable_stereo_switch" => 1,
		"fpga" => "10M08SCU169C8G"
	},
	"10M08_quad_auto" =>
	{
		"stereo" => 2,
		"enable_auto_stereo" => 1,
		"fpga" => "10M08SCU169C8G"
	}
);

#if (not defined $wanted_variant or (not exists $variants{$wanted_variant} and $wanted_variant ne "ALL"))
#{
#	die "Provide variant of ALL or ".join ",",sort keys %variants;
#}

foreach my $variant (sort keys %variants)
{
	#next if ($wanted_variant ne $variant and $wanted_variant ne "ALL");
	next unless ($variant =~ /$wanted_variant/);
	print "Building $variant of $name\n";

	my $dir = "build_$variant";
	`rm -rf $dir`;
	mkdir $dir;
	`cp *.vhd* $dir`;
	`cp pokeymax*.sdc $dir`;
	`cp pokeymax*.qpf $dir`;
	`cp pokeymax*.qsf $dir`;
	`cp -r int_osc* $dir`;
	`cp -r pll* $dir`;

	chdir $dir;

	my $fpga = $variants{$variant}->{"fpga"};
	
	`echo set_global_assignment -name DEVICE $fpga >> pokeymax.qsf`;

	foreach my $key (sort keys %{$variants{$variant}})
	{
		my $val = $variants{$variant}->{$key};
		`echo set_parameter -name $key $val >> pokeymax.qsf`;
	}

	`quartus_sh --flow compile pokeymax > build.log 2> build.err`;

	chdir "..";
}

