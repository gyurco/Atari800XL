#!/usr/bin/perl -w
use strict;

my $wanted_variant = shift @ARGV;

my $name="eclaireXL";

#Added like this to the generated qsf
#set_parameter -name TV 1

my $version = "119";

my %variants = 
(
#		enable_auto_stereo : integer := 0;   -- 1=auto detect a4 => not toggling => mono
#
#		fancy_switch_bit : integer := 10; -- 0=ext is low => mono
#		gtia_audio_bit : integer := 0;    -- 0=no gtia on l/r,1=gtia mixed on l/r
#		a4_bit : integer := 0;
#		a5_bit : integer := 0;
#		a6_bit : integer := 0;
#		a7_bit : integer := 0;
#
#		ext_bits : integer := 3; 
#
#		enable_config : integer := 1;
#		enable_sid : integer := 0;
#		enable_ym : integer := 0;
#		enable_covox : integer := 0;
#		enable_sample : integer := 0;
#
#   		version : STRING  := "DEVELOPR" -- 8 char string atascii



	"10M02_mono" =>
	{
		"pokeys" => 1,
		"fpga" => "10M02SCU169C8G",
		"enable_auto_stereo" => 1,
		"gtia_audio_bit" => 3,
		"a4_bit" => 1, #to access config!
		"version" => $version . "M02MO"
	},
	"v1_10M02_stereo_auto" =>
	{
		"pokeys" => 2,
		"enable_auto_stereo" => 1,
		"a4_bit" => 1,
		"fpga" => "10M02SCU169C8G",
		"board" => "v1",
		"ext_bits"=> 1,
		"cs0_bit" => 0, #force low
		"version" => $version . "M02SA"
	},
	"10M02_stereo_auto" =>
	{
		"pokeys" => 2,
		"enable_auto_stereo" => 1,
		"a4_bit" => 1,
		"gtia_audio_bit" => 3,
		"fpga" => "10M02SCU169C8G",
		"version" => $version . "M02SA"
	},
	"10M02_stereo_xel_auto" =>
	{
		"pokeys" => 2,
		"enable_auto_stereo" => 1,
		"a4_bit" => 1,
		"cs1_bit" => 20,
		"gtia_audio_bit" => 3,
		"fpga" => "10M02SCU169C8G",
		"version" => $version . "M02SX"
	},
	"10M02_stereo_u1mb_auto" =>
	{
		"pokeys" => 2,
		"enable_auto_stereo" => 1,
		"a4_bit" => 1,
		"fancy_switch_bit" => 2,
		"gtia_audio_bit" => 3,
		"fpga" => "10M02SCU169C8G",
		"version" => $version . "M02SU"
	},
#	"10M02_mark" =>
#	{
#		"pokeys" => 1,
#		"enable_auto_stereo" => 1,
#		"enable_covox" => 0,
#		"a4_bit" => 1,
#		"a7_bit" => 2,
#		"gtia_audio_bit" => 3, 
#		"fpga" => "10M02SCU169C8G",
#		"version" =>  $version."M02SC"
#	},
	"10M02_stereo_covox_auto" =>
	{
		"pokeys" => 2,
		"enable_auto_stereo" => 1,
		"enable_covox" => 1,
		"a4_bit" => 1,
		"a7_bit" => 2,
		"gtia_audio_bit" => 3, 
		"fpga" => "10M02SCU169C8G",
		"version" =>  $version."M02SC"
	},
	"10M02_stereo_covox_no_right_detect" =>
	{
		"pokeys" => 2,
		"enable_auto_stereo" => 0,
		"enable_covox" => 1,
		"detect_right_on_by_default" => 0,
		"a4_bit" => 1,
		"a7_bit" => 2,
		"gtia_audio_bit" => 3, 
		"fpga" => "10M02SCU169C8G",
		"version" =>  $version."M02SC"
	},
	"10M08_stereo_covox_sample_auto" =>
	{
		"pokeys" => 2,
		"enable_auto_stereo" => 1,
		"enable_covox" => 1,
		"enable_sample" => 1,
		"enable_flash" => 1,
		"a4_bit" => 1,
		"a7_bit" => 2,
		"gtia_audio_bit" => 3, 
		"fpga" => "10M08SCU169C8G",
		"version" =>  $version."M08SC"
	},
	"sid_10M08_sid_mono" =>
	{
		"pokeys" => 1,
		"enable_sid" => 1,
		"enable_auto_stereo" => 1,
		"enable_flash" => 1,
		"ext_bits"=> 4,
		"bus" => "c64",
		"a4_bit" => 4,
		"a5_bit" => 0,  #force low for now (will be stereo)
		"a6_bit" => 20, #force high
		"a7_bit" => 0, #force low
		"board" => "sid",
		"cs1_bit" => 20, #force high
		"fpga" => "10M08SCU169C8G",
		"version" => $version . "M08SI"
	},
	"sid_10M08_sid_stereo" =>
	{
		"pokeys" => 1,
		"enable_sid" => 1,
		"enable_auto_stereo" => 1,
		"enable_flash" => 1,
		"ext_bits"=> 4,
		"bus" => "c64",
		"a4_bit" => 4,
		"a5_bit" => 1,  #STEREO
		"a6_bit" => 20, #force high
		"a7_bit" => 0, #force low
		"board" => "sid",
		"cs1_bit" => 20, #force high
		"fpga" => "10M08SCU169C8G",
		"version" => $version . "M08SI"
	},
	"10M04_stereo_u1mb_auto" =>
	{
		"pokeys" => 2,
		"enable_auto_stereo" => 1,
		"enable_flash" => 1,
		"a4_bit" => 1,
		"fancy_switch_bit" => 2,
		"gtia_audio_bit" => 3,
		"fpga" => "10M04SCU169C8G",
		"version" => $version . "M04SU"
	},
	"10M04_stereo_covox_auto" =>
	{
		"pokeys" => 2,
		"enable_auto_stereo" => 1,
		"enable_covox" => 1,
		"enable_flash" => 1,
		"a4_bit" => 1,
		"a7_bit" => 2,
		"gtia_audio_bit" => 3, 
		"fpga" => "10M04SCU169C8G",
		"version" =>  $version."M04SC"
	},
	"10M04_quad_auto" =>
	{
		"pokeys" => 4,
		"enable_auto_stereo" => 1,
		"enable_flash" => 1,
		"a4_bit" => 1,
		"a5_bit" => 2,
		"gtia_audio_bit" => 3, 
		"fpga" => "10M04SCU169C8G",
		"version" => $version . "M04QA"
	},
	"10M04_quad_covox_auto" =>
	{
		"pokeys" => 4,
		"enable_auto_stereo" => 1,
		"enable_flash" => 1,
		"a4_bit" => 1,
		"a5_bit" => 2,
		"a7_bit" => 3, 
		"enable_covox" => 1,
		"fpga" => "10M04SCU169C8G",
		"version" => $version . "M04QC"
	},
	"10M08_stereo_u1mb_auto" =>
	{
		"pokeys" => 2,
		"enable_auto_stereo" => 1,
		"enable_flash" => 1,
		"a4_bit" => 1,
		"fancy_switch_bit" => 2,
		"gtia_audio_bit" => 3,
		"fpga" => "10M08SCU169C8G",
		"version" => $version . "M08SU"
	},
	"10M08_quad_auto" =>
	{
		"pokeys" => 4,
		"enable_auto_stereo" => 1,
		"enable_flash" => 1,
		"a4_bit" => 1,
		"a5_bit" => 2,
		"gtia_audio_bit" => 3, 
		"fpga" => "10M08SCU169C8G",
		"version" => $version . "M08QA"
	},
	"10M08_quad_covox_sample_auto" =>
	{
		"pokeys" => 4,
		"enable_auto_stereo" => 1,
		"a4_bit" => 1,
		"a5_bit" => 2,
		"a7_bit" => 3, 
		"enable_covox" => 1,
		"enable_sample" => 1,
		"enable_flash" => 1,
		"fpga" => "10M08SCU169C8G",
		"version" => $version . "M08QC"
	},
	"10M08_quad_sid" =>
	{
		"pokeys" => 4,
		"enable_auto_stereo" => 1,
		"enable_sid" => 1,
		"enable_flash" => 1,
		"a4_bit" => 1,
		"a5_bit" => 2,
		"a6_bit" => 3,
		"fpga" => "10M08SCU169C8G",
		"version" => $version . "M08QS"
	},
	"10M08_quad_psg_covox_sample" =>
	{
		"pokeys" => 4,
		"enable_auto_stereo" => 1,
		"enable_psg" => 1,
		"enable_covox" => 1,
		"enable_sample" => 1,
		"enable_flash" => 1,
		"a4_bit" => 1,
		"a5_bit" => 2,
		"a7_bit" => 3,
		"fpga" => "10M08SCU169C8G",
		"version" => $version . "M08QP"
	},
	"10M08_fullv2" =>
	{
		"pokeys" => 4,
		"enable_auto_stereo" => 1,
		"enable_sid" => 1,
		"enable_psg" => 1,
		"enable_covox" => 1,
		"enable_sample" => 1,
		"enable_flash" => 1,
		"a4_bit" => 1,
		"a5_bit" => 2,
		"a6_bit" => 3,
		"a7_bit" => 19,  #use CS1
		"cs1_bit" => 20, #force high
		"fpga" => "10M08SCU169C8G",
		"version" => $version . "M08HK"
	},
	"10M16_fullv3" =>
	{
		"pokeys" => 4,
		"enable_auto_stereo" => 1,
		"enable_sid" => 1,
		"enable_psg" => 1,
		"enable_covox" => 1,
		"enable_sample" => 1,
		"enable_flash" => 1,
		"flash_addr_bits" => 17,
		"board" => "v3",
		"a4_bit" => 1,
		"a5_bit" => 2,
		"a6_bit" => 3,
		"a7_bit" => 4,
		"gtia_audio_bit" => 5, 
		#"fancy_switch_bit" => 6,
		#"a7_bit" => 19,  #use CS1
		"ext_bits"=> 11,
		#"cs1_bit" => 20, #force high
		"fpga" => "10M16SCU169C8G",
		"sid_wave_base" => 79872, #"to_integer(unsigned(x\"13800\"))",
		"version" => $version . "M16HK"
	},
#	"10M08_light" =>
#	{
#		"pokeys" => 2,
#		"enable_auto_stereo" => 1,
#		"enable_sid" => 0,
#		"enable_psg" => 0,
#		"enable_covox" => 1,
#		"enable_sample" => 1,
#		"enable_flash" => 1,
#		"a4_bit" => 1,
#		"a5_bit" => 2,
#		"a6_bit" => 3,
#		"a7_bit" => 19,  #use CS1
#		"cs1_bit" => 20, #force high
#		"fpga" => "10M08SCU169C8G",
#		"version" => $version . "M08LI"
#	},
#	"10M08_audiotest" =>
#	{
#		"pokeys" => 4,
#		"enable_auto_stereo" => 1,
#		"enable_sid" => 1,
#		"enable_psg" => 1,
#		"enable_covox" => 1,
#		"enable_sample" => 1,
#		"enable_flash" => 1,
#		"a4_bit" => 1,
#		"a5_bit" => 2,
#		"a6_bit" => 3,
#		"a7_bit" => 19,  #use CS1
#		"cs1_bit" => 20, #force high
#		"ext_clk_enable" => 1,
#		"fpga" => "10M08SCU169C8G",
#		"version" => $version . "M08HK"
#	},
#	"10M08_sample" =>
#	{
#		"pokeys" => 4,
#		"enable_auto_stereo" => 1,
#		"enable_sid" => 0,
#		"enable_psg" => 0,
#		"enable_covox" => 1,
#		"enable_sample" => 1,
#		"enable_flash" => 1,
#		"a4_bit" => 1,
#		"a5_bit" => 2,
#		"a6_bit" => 3,
#		"a7_bit" => 19,  #use CS1
#		"cs1_bit" => 20, #force high
#		"fpga" => "10M08SCU169C8G",
#		"version" => $version . "M08HK"
#	}
#	"10M08_full" => 
#	{
#		"board" => 3,
#		"ext_bits"=> 11,
#		"pokeys" => 4,
#		"enable_auto_stereo" => 1,
#		"fancy_switch_bit" => 1,
#		"gtia_audio_bit" => 2,
#		"a4_bit" => 3,
#		"a5_bit" => 4,
#		"a6_bit" => 5,
#		"a7_bit" => 6,
#		"enable_sid" => 1,
#		"enable_psg" => 1,
#		"enable_covox" => 1,
#		"enable_sample" => 1,
#		"enable_flash" => 1,
#		"fpga" => "10M08SCU169C8G"
#	}
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

	my $versioncode = $variants{$variant}->{"version"};
	if (not defined $versioncode)
	{
		$versioncode = "DEVELOPR";
	}
	my $fpga = $variants{$variant}->{"fpga"};
	my $flashver = $fpga;
	$flashver =~ s/..M(..).*/$1/;
	my $board = $variants{$variant}->{"board"};
	my $bus = $variants{$variant}->{"bus"};

	my $dir = "build_$variant";
	`rm -rf $dir`;
	mkdir $dir;
	`cp *.vhd* $dir`;
	`cp iox_glue.vhdl $dir/iox_glue.vhdl`;
	`cp pokeymax.vhd $dir/pokeymax.vhd`;
	`cp iox_glue$board.vhdl $dir/iox_glue.vhdl`;
	`cp pokeymax$board.vhd $dir/pokeymax.vhd`;
	`cp slave_timing_6502$bus.vhd $dir/slave_timing_6502.vhd`;
	`cp swapbits $dir`;
	`cp pokeymax*.sdc $dir`;
	`cp pokeymax*.qpf $dir`;
	`cp pokeymax$board.qsf $dir/pokeymax.qsf`;
	`cp -r int_osc* $dir`;
	`cp -r pll* $dir`;
	`cp -r flash_$flashver/flash* $dir`;
	`cp -r PSG $dir`;
	`cp -r SID $dir`;
	`cp -r sample $dir`;
	`cp -r covox $dir`;
	`cp -r *.bin $dir`;

	chdir $dir;

	
	`echo set_global_assignment -name DEVICE $fpga >> pokeymax.qsf`;

	foreach my $key (sort keys %{$variants{$variant}})
	{
		my $val = $variants{$variant}->{$key};
		`echo 'set_parameter -name $key $val' >> pokeymax.qsf`;
	}

	`quartus_sh --flow compile pokeymax > build.log 2> build.err`;
	`quartus_cpf --convert ../convert_secure.cof`;
	`../modifypof_$flashver ./output_files/pokeymax.pof`;
	`quartus_cpf -c -q 10MHz -g 3.3 -n p output_files/pokeymax.pof output_files/pokeymax.svf`;
	`../makeflash_$flashver ./output_files/pokeymax.pof $versioncode output_files/core.bin`;
	`touch UFM1 UFM0 CFM1 CFM0`;
	`../openocd_flash/extractbinfromsvf.pl output_files/pokeymax.svf`;
	`cat UFM1.bin UFM0.bin > UFMboth.bin`;
	`cat CFM1.bin CFM0.bin > CFMboth.bin`;

	chdir "..";
}

