#!/usr/bin/perl -w
use strict;

my $wanted_variant = shift @ARGV;

my $name="eclaireXL";

#Added like this to the generated qsf
#set_parameter -name TV 1

my $version = "128";

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
	"pokeymax_v1" =>
	{
		"10M02SCU169C8G" =>
		{
			"stereo_auto" =>
			{
				"pokeys" => 2,
				"enable_auto_stereo" => 1,
				"a4_bit" => 1,
				"ext_bits"=> 1,
				"cs0_bit" => 0, #force low
			},
		}
	},
	"pokeymax_v2" =>
	{
		"10M02SCU169C8G" =>
		{
			"mono_linear" =>
			{
				"saturate_on_by_default" => 0,
				"pokeys" => 1,
				"enable_auto_stereo" => 1,
				"gtia_audio_bit" => 3,
				"a4_bit" => 1, #to access config!
			},
			"stereo_xel_auto_linear" =>
			{
				"saturate_on_by_default" => 0,
				"pokeys" => 2,
				"enable_auto_stereo" => 1,
				"a4_bit" => 1,
				"cs1_bit" => 20,
				"gtia_audio_bit" => 3,
			},
			"stereo_covox_no_right_detect_linear" =>
			{
				"saturate_on_by_default" => 0,
				"pokeys" => 2,
				"enable_auto_stereo" => 0,
				"enable_covox" => 1,
				"detect_right_on_by_default" => 0,
				"a4_bit" => 1,
				"a7_bit" => 2,
				"gtia_audio_bit" => 3, 
			},
			"stereo_auto_linear" =>
			{
				"saturate_on_by_default" => 0,
				"pokeys" => 2,
				"enable_auto_stereo" => 1,
				"a4_bit" => 1,
				"gtia_audio_bit" => 3,
			},
			"stereo_u1mb_auto_linear" =>
			{
				"saturate_on_by_default" => 0,
				"pokeys" => 2,
				"enable_auto_stereo" => 1,
				"a4_bit" => 1,
				"fancy_switch_bit" => 2,
				"gtia_audio_bit" => 3,
			},
			"stereo_covox_auto_linear" =>
			{
				"saturate_on_by_default" => 0,
				"pokeys" => 2,
				"enable_auto_stereo" => 1,
				"enable_covox" => 1,
				"a4_bit" => 1,
				"a7_bit" => 2,
				"gtia_audio_bit" => 3, 
			},
			"mono" =>
			{
				"pokeys" => 1,
				"enable_auto_stereo" => 1,
				"gtia_audio_bit" => 3,
				"a4_bit" => 1, #to access config!
			},
			"stereo_xel_auto" =>
			{
				"pokeys" => 2,
				"enable_auto_stereo" => 1,
				"a4_bit" => 1,
				"cs1_bit" => 20,
				"gtia_audio_bit" => 3,
			},
			"stereo_covox_no_right_detect" =>
			{
				"pokeys" => 2,
				"enable_auto_stereo" => 0,
				"enable_covox" => 1,
				"detect_right_on_by_default" => 0,
				"a4_bit" => 1,
				"a7_bit" => 2,
				"gtia_audio_bit" => 3, 
			},
			"stereo_auto" =>
			{
				"pokeys" => 2,
				"enable_auto_stereo" => 1,
				"a4_bit" => 1,
				"gtia_audio_bit" => 3,
			},
			"stereo_u1mb_auto" =>
			{
				"pokeys" => 2,
				"enable_auto_stereo" => 1,
				"a4_bit" => 1,
				"fancy_switch_bit" => 2,
				"gtia_audio_bit" => 3,
			},
			"stereo_covox_auto" =>
			{
				"pokeys" => 2,
				"enable_auto_stereo" => 1,
				"enable_covox" => 1,
				"a4_bit" => 1,
				"a7_bit" => 2,
				"gtia_audio_bit" => 3, 
			},
		},
		"10M04SCU169C8G" => 
		{
			"quad_covox_xel_auto" =>
			{
				"pokeys" => 4,
				"enable_auto_stereo" => 1,
				"enable_flash" => 1,
				"a4_bit" => 1,
				"a5_bit" => 2,
				"a7_bit" => 3, 
				"cs1_bit" => 20,
				"enable_covox" => 1,
			},
			"mono" =>
			{
				"pokeys" => 1,
				"enable_auto_stereo" => 1,
				"gtia_audio_bit" => 3,
				"enable_flash" => 1,
				"a4_bit" => 1, #to access config!
			},
			"stereo_xel_auto" =>
			{
				"pokeys" => 2,
				"enable_auto_stereo" => 1,
				"enable_flash" => 1,
				"a4_bit" => 1,
				"cs1_bit" => 20,
				"gtia_audio_bit" => 3,
			},
			"stereo_covox_no_right_detect" =>
			{
				"pokeys" => 2,
				"enable_auto_stereo" => 0,
				"enable_covox" => 1,
				"enable_flash" => 1,
				"detect_right_on_by_default" => 0,
				"a4_bit" => 1,
				"a7_bit" => 2,
				"gtia_audio_bit" => 3, 
			},
			"stereo_auto" =>
			{
				"pokeys" => 2,
				"enable_auto_stereo" => 1,
				"enable_flash" => 1,
				"a4_bit" => 1,
				"gtia_audio_bit" => 3,
			},
			"stereo_u1mb_auto" =>
			{
				"pokeys" => 2,
				"enable_auto_stereo" => 1,
				"enable_flash" => 1,
				"a4_bit" => 1,
				"fancy_switch_bit" => 2,
				"gtia_audio_bit" => 3,
			},
			"stereo_covox_auto" =>
			{
				"pokeys" => 2,
				"enable_auto_stereo" => 1,
				"enable_covox" => 1,
				"enable_flash" => 1,
				"a4_bit" => 1,
				"a7_bit" => 2,
				"gtia_audio_bit" => 3, 
			},
			"quad_auto" =>
			{
				"pokeys" => 4,
				"enable_auto_stereo" => 1,
				"enable_flash" => 1,
				"a4_bit" => 1,
				"a5_bit" => 2,
				"gtia_audio_bit" => 3, 
			},
			"quad_covox_auto" =>
			{
				"pokeys" => 4,
				"enable_auto_stereo" => 1,
				"enable_flash" => 1,
				"a4_bit" => 1,
				"a5_bit" => 2,
				"a7_bit" => 3, 
				"enable_covox" => 1,
			},
		},
		"10M08SCU169C8G" =>
		{
			"mono" =>
			{
				"pokeys" => 1,
				"enable_auto_stereo" => 1,
				"gtia_audio_bit" => 3,
				"cs1_bit" => 20, #force high
				"a4_bit" => 1, #to access config!
			},
			"stereo_covox_sample_auto" =>
			{
				"pokeys" => 2,
				"enable_auto_stereo" => 1,
				"enable_covox" => 1,
				"enable_sample" => 1,
				"enable_flash" => 1,
				"a4_bit" => 1,
				"a7_bit" => 2,
				"gtia_audio_bit" => 3, 
			},
			"stereo_u1mb_auto" =>
			{
				"pokeys" => 2,
				"enable_auto_stereo" => 1,
				"enable_flash" => 1,
				"a4_bit" => 1,
				"fancy_switch_bit" => 2,
				"gtia_audio_bit" => 3,
			},
			"quad_auto" =>
			{
				"pokeys" => 4,
				"enable_auto_stereo" => 1,
				"enable_flash" => 1,
				"a4_bit" => 1,
				"a5_bit" => 2,
				"gtia_audio_bit" => 3, 
			},
			"quad_covox_sample_auto" =>
			{
				"pokeys" => 4,
				"enable_auto_stereo" => 1,
				"a4_bit" => 1,
				"a5_bit" => 2,
				"a7_bit" => 3, 
				"enable_covox" => 1,
				"enable_sample" => 1,
				"enable_flash" => 1,
			},
			"quad_sid" =>
			{
				"pokeys" => 4,
				"enable_auto_stereo" => 1,
				"enable_sid" => 1,
				"enable_flash" => 1,
				"a4_bit" => 1,
				"a5_bit" => 2,
				"a6_bit" => 3,
			},
			"quad_psg_covox_sample" =>
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
			},
#			"basic" =>
#			{
#				"enable_audout2" => 0,
#				"pokeys" => 2,
#				"enable_auto_stereo" => 1,
#				"enable_sid" => 0,
#				"enable_psg" => 0,
#				"enable_covox" => 0,
#				"enable_sample" => 0,
#				"enable_flash" => 1,
#				"a4_bit" => 1,
#				"a5_bit" => 2,
#				"a6_bit" => 3,
#				"a7_bit" => 19,  #use CS1
#				"cs1_bit" => 20, #force high
#				"optimisearea" => 1
#			},
			#No longer fits
			#"full" =>
			#{
			#	"enable_audout2" => 0,
			#	"pokeys" => 4,
			#	"enable_auto_stereo" => 1,
			#	"enable_sid" => 1,
			#	"enable_psg" => 1,
			#	"enable_covox" => 1,
			#	"enable_sample" => 1,
			#	"enable_flash" => 1,
			#	"a4_bit" => 1,
			#	"a5_bit" => 2,
			#	"a6_bit" => 3,
			#	"a7_bit" => 19,  #use CS1
			#	"cs1_bit" => 20, #force high
			#	"optimisearea" => 1
			#},
			"full_stereo" =>
			{
				"enable_audout2" => 0,
				"pokeys" => 2,
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
				"optimisearea" => 1
			},
		},
		"10M16SCU169C8G" =>
		{
			"mono" =>
			{
				"pokeys" => 1,
				"enable_auto_stereo" => 1,
				"gtia_audio_bit" => 3,
				"flash_addr_bits" => 17,
				"cs1_bit" => 20, #force high
				"a4_bit" => 1, #to access config!
				"sid_wave_base" => 79872, #"to_integer(unsigned(x\"13800\"))",
			},
			"full" =>
			{
				"flash_addr_bits" => 17,
				"sid_wave_base" => 79872, #"to_integer(unsigned(x\"13800\"))",
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
			},
		}
	},
	"pokeymax_v3" =>
	{
		"10M04SCU169C8G" =>
		{
			"quad_auto" =>
			{
				"pokeys" => 4,
				"enable_auto_stereo" => 1,
				"enable_sid" => 0,
				"enable_psg" => 0,
				"enable_covox" => 0,
				"enable_sample" => 0,
				"enable_flash" => 1,
				"enable_spdif" => 1,
				"enable_ps2" => 1,
				"pll_v2" => 0,
				"a4_bit" => 1,
				"a5_bit" => 2,
				"gtia_audio_bit" => 5, 
				"spdif_bit" => 6,
				"ps2clk_bit" => 7,
				"ps2dat_bit" => 8,
				"ext_bits"=> 11,
			},
			"stereo_psg_covox_auto" =>
			{
				"pokeys" => 2,
				"enable_auto_stereo" => 1,
				"enable_sid" => 0,
				"enable_psg" => 1,
				"enable_covox" => 1,
				"enable_sample" => 0,
				"enable_flash" => 1,
				"enable_spdif" => 1,
				"enable_ps2" => 1,
				"pll_v2" => 0,
				"a4_bit" => 1,
				"a5_bit" => 2,
				"a6_bit" => 3,
				"a7_bit" => 4,
				"gtia_audio_bit" => 5, 
				"spdif_bit" => 6,
				"ps2clk_bit" => 7,
				"ps2dat_bit" => 8,
				#"fancy_switch_bit" => 6,
				#"a7_bit" => 19,  #use CS1
				"ext_bits"=> 11,
				#"cs1_bit" => 20, #force high
			},
		},
		"10M16SCU169C8G" =>
		{
			"mono" =>
			{
				"pokeys" => 4,
				"enable_auto_stereo" => 1,
				"enable_sid" => 0,
				"enable_psg" => 0,
				"enable_covox" => 0,
				"enable_sample" => 0,
				"enable_flash" => 1,
				"enable_spdif" => 0,
				"enable_ps2" => 0,
				"flash_addr_bits" => 17,
				"pll_v2" => 0,
				"a4_bit" => 1,
				"a5_bit" => 2,
				"a6_bit" => 3,
				"a7_bit" => 4,
				"gtia_audio_bit" => 5, 
				"spdif_bit" => 6,
				"ps2clk_bit" => 7,
				"ps2dat_bit" => 8,
				#"fancy_switch_bit" => 6,
				#"a7_bit" => 19,  #use CS1
				"ext_bits"=> 11,
				#"cs1_bit" => 20, #force high
				"sid_wave_base" => 79872, #"to_integer(unsigned(x\"13800\"))",
			},
			"full" =>
			{
				"pokeys" => 4,
				"enable_auto_stereo" => 1,
				"enable_sid" => 1,
				"enable_psg" => 1,
				"enable_covox" => 1,
				"enable_sample" => 1,
				"enable_flash" => 1,
				"enable_spdif" => 1,
				"enable_ps2" => 1,
				"flash_addr_bits" => 17,
				"pll_v2" => 0,
				"a4_bit" => 1,
				"a5_bit" => 2,
				"a6_bit" => 3,
				"a7_bit" => 4,
				"gtia_audio_bit" => 5, 
				"spdif_bit" => 6,
				"ps2clk_bit" => 7,
				"ps2dat_bit" => 8,
				#"fancy_switch_bit" => 6,
				#"a7_bit" => 19,  #use CS1
				"ext_bits"=> 11,
				#"cs1_bit" => 20, #force high
				"sid_wave_base" => 79872, #"to_integer(unsigned(x\"13800\"))",
			},
			"full_xel" =>
			{
				"pokeys" => 4,
				"enable_auto_stereo" => 1,
				"enable_sid" => 1,
				"enable_psg" => 1,
				"enable_covox" => 1,
				"enable_sample" => 1,
				"enable_flash" => 1,
				"enable_spdif" => 1,
				"enable_ps2" => 1,
				"flash_addr_bits" => 17,
				"pll_v2" => 0,
				"a4_bit" => 1,
				"a5_bit" => 2,
				"a6_bit" => 3,
				"a7_bit" => 4,
				"gtia_audio_bit" => 5, 
				"spdif_bit" => 6,
				"ps2clk_bit" => 7,
				"ps2dat_bit" => 8,
				#"fancy_switch_bit" => 6,
				#"a7_bit" => 19,  #use CS1
				"ext_bits"=> 11,
				"cs1_bit" => 20,
				#"cs1_bit" => 20, #force high
				"sid_wave_base" => 79872, #"to_integer(unsigned(x\"13800\"))",
			},
		}
	},
	"pokeymax_v4" =>
	{
		"10M02SCU169C8G" =>
		{
			"stereo" =>
			{
				"enable_audout2" => 0,
				"pokeys" => 2,
				"enable_auto_stereo" => 1,
				"enable_sid" => 0,
				"enable_psg" => 0,
				"enable_covox" => 0,
				"enable_sample" => 0,
				"enable_flash" => 0,
				"enable_spdif" => 1,
				"enable_ps2" => 0,
				"a4_bit" => 1,
				"ps2clk_bit" => 5,
				"ps2dat_bit" => 6,
				"gtia_audio_bit" => 7, 
				"fancy_switch_bit" => 8,
				"spdif_bit" => 10,
				"ext_bits"=> 10,
				"paddle_lvds"=>1,
				"paddle_comp"=>0,
				"enable_iox"=>0,
				"enable_adc"=>0,
				"pll_v2" => 0, 
				"optimisearea" => 1,
			},
		},
		"10M08SCU169C8G" =>
		{
			"full_stereo_sample" =>
			{
				"enable_audout2" => 0,
				"pokeys" => 2,
				"enable_auto_stereo" => 1,
				"enable_sid" => 1,
				"enable_psg" => 1,
				"enable_covox" => 1,
				"enable_sample" => 1,
				"enable_flash" => 1,
				"enable_spdif" => 0,
				"enable_ps2" => 0,
				"a4_bit" => 1,
				"a5_bit" => 2,
				"a6_bit" => 3,
				"a7_bit" => 4,
				"ps2clk_bit" => 5,
				"ps2dat_bit" => 6,
				"gtia_audio_bit" => 7, 
				"fancy_switch_bit" => 8,
				"spdif_bit" => 10,
				"ext_bits"=> 10,
				"paddle_lvds"=>1,
				"paddle_comp"=>0,
				"enable_iox"=>0,
				"enable_adc"=>0,
				"pll_v2" => 0, 
				"optimisearea" => 1,
			},
			"full_stereo_spdif" =>
			{
				"enable_audout2" => 0,
				"pokeys" => 2,
				"enable_auto_stereo" => 1,
				"enable_sid" => 1,
				"enable_psg" => 1,
				"enable_covox" => 1,
				"enable_sample" => 0,
				"enable_flash" => 1,
				"enable_spdif" => 1,
				"enable_ps2" => 0,
				"a4_bit" => 1,
				"a5_bit" => 2,
				"a6_bit" => 3,
				"a7_bit" => 4,
				"ps2clk_bit" => 5,
				"ps2dat_bit" => 6,
				"gtia_audio_bit" => 7, 
				"fancy_switch_bit" => 8,
				"spdif_bit" => 10,
				"ext_bits"=> 10,
				"paddle_lvds"=>1,
				"paddle_comp"=>0,
				"enable_iox"=>0,
				"enable_adc"=>1,
				"pll_v2" => 0, 
				"optimisearea" => 1,
			},
			"mono" =>
			{
				"enable_audout2" => 0,
				"pokeys" => 1,
				"enable_auto_stereo" => 1,
				"enable_sid" => 0,
				"enable_psg" => 0,
				"enable_covox" => 0,
				"enable_sample" => 0,
				"enable_flash" => 1,
				"a4_bit" => 1,
				"a5_bit" => 2,
				"a6_bit" => 3,
				"a7_bit" => 4,
				"ps2clk_bit" => 5,
				"ps2dat_bit" => 6,
				"gtia_audio_bit" => 7, 
				"fancy_switch_bit" => 8,
				"spdif_bit" => 10,
				"ext_bits"=> 10,
				"paddle_lvds"=>1,
				"paddle_comp"=>0,
				"enable_iox"=>0,
				"enable_adc"=>1,
				"pll_v2" => 0,
				"optimisearea" => 1,
			},
		},
		"10M16SCU169C8G" =>
		{
			"full_quad" =>
			{
				"enable_audout2" => 0,
				"pokeys" => 4,
				"enable_auto_stereo" => 1,
				"enable_sid" => 1,
				"enable_psg" => 1,
				"enable_covox" => 1,
				"enable_sample" => 1,
				"enable_flash" => 1,
				"enable_spdif" => 1,
				"enable_ps2" => 1,
				"flash_addr_bits" => 17,
				"sid_wave_base" => 79872, #"to_integer(unsigned(x\"13800\"))",
				"a4_bit" => 1,
				"a5_bit" => 2,
				"a6_bit" => 3,
				"a7_bit" => 4,
				"ps2clk_bit" => 5,
				"ps2dat_bit" => 6,
				"gtia_audio_bit" => 7, 
				"fancy_switch_bit" => 8,
				"spdif_bit" => 10,
				"ext_bits"=> 10,
				"paddle_lvds"=>1,
				"paddle_comp"=>0,
				"enable_iox"=>0,
				"enable_adc"=>1,
				"pll_v2" => 0,
				"optimisearea" => 1,
			},
			"mono" =>
			{
				"enable_audout2" => 0,
				"pokeys" => 1,
				"enable_auto_stereo" => 1,
				"enable_sid" => 0,
				"enable_psg" => 0,
				"enable_covox" => 0,
				"enable_sample" => 0,
				"enable_flash" => 1,
				"flash_addr_bits" => 17,
				"sid_wave_base" => 79872, #"to_integer(unsigned(x\"13800\"))",
				"a4_bit" => 1,
				"a5_bit" => 2,
				"a6_bit" => 3,
				"a7_bit" => 4,
				"ps2clk_bit" => 5,
				"ps2dat_bit" => 6,
				"gtia_audio_bit" => 7, 
				"spdif_bit" => 10,
				"ext_bits"=> 10,
				"paddle_lvds"=>1,
				"paddle_comp"=>0,
				"enable_iox"=>0,
				"enable_adc"=>1,
				"pll_v2" => 0,
				"optimisearea" => 1,
			},
		}
	},
	#
	#sid adaptor board I think...
	#"sid_10M08_sid_mono" =>
	#{
	#	"pokeys" => 1,
	#	"enable_sid" => 1,
	#	"enable_auto_stereo" => 1,
	#	"enable_flash" => 1,
	#	"ext_bits"=> 4,
	#	"bus" => "c64",
	#	"a4_bit" => 4,
	#	"a5_bit" => 0,  #force low for now (will be stereo)
	#	"a6_bit" => 20, #force high
	#	"a7_bit" => 0, #force low
	#	"cs1_bit" => 20, #force high
	#	"fpga" => "10M08SCU169C8G",
	#	"version" => $version . "M08SI"
	#},
	#"sid_10M08_sid_stereo" =>
	#{
	#	"pokeys" => 1,
	#	"enable_sid" => 1,
	#	"enable_auto_stereo" => 1,
	#	"enable_flash" => 1,
	#	"ext_bits"=> 4,
	#	"bus" => "c64",
	#	"a4_bit" => 4,
	#	"a5_bit" => 1,  #STEREO
	#	"a6_bit" => 20, #force high
	#	"a7_bit" => 0, #force low
	#	"cs1_bit" => 20, #force high
	#	"fpga" => "10M08SCU169C8G",
	#},
	"sidmax_v1" =>
	{
		"10M08SCU169C8G" =>
		{
			"full" =>
			{
				"sids" => 2, #Not generic yet...
				"pokeys" => 2,
				"enable_auto_stereo" => 1,
				"enable_flash" => 1,
				"enable_psg" => 1,
				"enable_covox" => 1,
				"enable_sample" => 1,
				"ext_bits"=> 4,
				"bus" => "c64",
				"a5_bit" => 1,  #STEREO
				"a6_bit" => 2,
				"a7_bit" => 3,
				"irq_bit" => 4,
				#"a6_bit" => 20, #force high
				#"a7_bit" => 0, #force low
				#"cs1_bit" => 20, #force high
			},
		}
	}
);

#if (not defined $wanted_variant or (not exists $variants{$wanted_variant} and $wanted_variant ne "ALL"))
#{
#	die "Provide variant of ALL or ".join ",",sort keys %variants;
#}

foreach my $typeboard (sort keys %variants)
{
	$typeboard =~ /(.*)_(.*)/;
	my $type = $1;
	my $board = $2;

	my $fpgas = $variants{$typeboard};
	foreach my $fpga (sort keys %$fpgas)
	{
		my $names = $fpgas->{$fpga};
		foreach my $name (sort keys %$names)
		{
			my $spec = $names->{$name};
			$spec->{"fpga"} = $fpga;
	
			$fpga =~ /M(..)/;
			my $fpgasize = $1;
	
			my $code1;
			my $code2;
			my $sample = 0;
			if (exists $spec->{"enable_sample"} and $spec->{"enable_sample"}==1)
			{
				$sample = 1;
			}
			my $covox = 0;
			if (exists $spec->{"enable_covox"} and $spec->{"enable_covox"}==1)
			{
				$covox = 1;
			}
			my $sids = 0;
			if (exists $spec->{"enable_sid"} and $spec->{"enable_sid"}) {$sids = 2;}
			my $pokeys = $spec->{"pokeys"};
			my $psgs = 0;
			if (exists $spec->{"enable_psg"} and $spec->{"enable_psg"}) {$psgs = 2;}
	
			my $primary = $pokeys;
			if ($type eq "pokeymax")
			{
				if ($pokeys==1)
				{
					$code1 = "M";
				}
				elsif ($pokeys==2)
				{
					$code1 = "S";
				}
				elsif ($pokeys==4)
				{
					$code1 = "Q";
				}
				else
				{
					$code1 = "O";
				}
	
				if ($psgs==2 and $sample==1 and $sids==2)
				{
					$code2 = "F";
				}	
				elsif ($psgs==2 and $sample==0 and $sids==2)
				{
					$code2 = "f";
				}	
				elsif ($psgs==2 and $sids==0)
				{
					$code2 = "P";
				}	
				elsif ($psgs==0 and $sids==2)
				{
					$code2 = "S";
				}	
				elsif ($covox==1)
				{
					$code2 = "C";
				}	
				elsif ($psgs==0 and $sample==0 and $covox==0 and $sids==0)
				{
					$code2 = "A";
				}
				else
				{
					$code2 = "O"; #Other
					print ("MISSING: PSG:$psgs SID:$sids sample:$sample covox:$covox\n");
				}
			}
			elsif ($type eq "sidmax")
			{
				$sids = $spec->{"sids"};
				if ($sids==1)
				{
					$code1 = "M";
				}
				elsif ($sids==2)
				{
					$code1 = "S";
				}
				elsif ($sids==4)
				{
					$code1 = "Q";
				}
				else
				{
					$code1 = "O"; #Other
				}
	
				if ($psgs==2 and $sample=1 and $pokeys==2)
				{
					$code2 = "F";
				}	
			}
			else
			{
				die "Unknown type";
			}
		
			my $versioncode = "${version}M$fpgasize$code1$code2";
			$spec->{"version"} = $versioncode;
	
			my $bus = "";
			if (exists $spec->{"bus"})
			{
				$bus = $spec->{"bus"};
			}
			my $flash = $spec->{"enable_flash"};
			my $noflash = "";
			if (not defined $flash or $flash eq "0") {$noflash = "_noflash"};
		
			my $needs_sid_waves = 0;
			if ($sids>0)
			{
				$needs_sid_waves = 1;
			}
		
		        my $dir = "build_${typeboard}_M${fpgasize}_${versioncode}_${name}";
	
			#next if ($wanted_variant ne $variant and $wanted_variant ne "ALL");
			if (defined $wanted_variant)
			{
				next unless ($dir =~ /$wanted_variant/);
			}
			print "Building $versioncode $name of $typeboard into $dir\n";
	
			`rm -rf $dir`;
			mkdir $dir;
			`cp *.vhd* $dir`;
			`cp iox_glue$board.vhdl $dir/iox_glue.vhdl 2> /dev/null`;
	
			`cp $type$board.vhd $dir/$type.vhd`;
			`cp $type$board.qsf $dir/$type.qsf`;
		
			`cp slave_timing_6502$bus.vhd $dir/slave_timing_6502.vhd`;
			`cp swapbits $dir`;
			`cp $type$board$noflash.sdc $dir/$type.sdc`;
			`cp $type*.qpf $dir`;
			`cp -r int_osc* $dir`;
			`cp -r pll* $dir`;
			`cp -r lvds* $dir`;
			`cp -r paddle* $dir`;
			`cp -r flash_$fpgasize/flash* $dir 2> /dev/null`;
			`cp -r PSG $dir`;
			`cp -r SID $dir`;
			`cp -r pokey $dir`;
			`cp -r sample $dir`;
			`cp -r covox $dir`;
			`cp -r sigma_delta $dir`;
			`cp -r *.bin $dir`;
			`cp -r fir_*vhdl $dir`;
			`cp -r fir_sample_buffer* $dir`;
			`cp -r fir_buffer* $dir`;
		
			chdir $dir;
		
			
			`echo set_global_assignment -name DEVICE $fpga >> $type.qsf`;
		
			foreach my $key (sort keys %$spec)
			{
				my $val = $spec->{$key};
				`echo 'set_parameter -name $key $val' >> $type.qsf`;
			}
			if (exists $spec->{"optimisearea"})
			{
				`echo 'set_global_assignment -name CYCLONEII_OPTIMIZATION_TECHNIQUE AREA' >>$type.qsf`;
			}
		
			#Synthesize
			`quartus_sh --flow compile $type > build.log 2> build.err`;
		
			#Create a plain old pof file
			#The sof file is compressed
			#Reason being that we have a user flash area (UFM) and a config flash area (CFM)
			#We steal some of the CFM space for sid wave tables but it needs to be empty
			`quartus_cpf --convert ../convert_secure_${type}_${needs_sid_waves}.cof`;
		
			if (int($fpgasize)>=8 and $needs_sid_waves) #We only patch the larger ones, the others do not have space...
			{
			        #Find the offsets in order to patch the pof file
				#This is done by extracting the data from an svf (a standard format for flashing, unlike pof)
				`quartus_cpf -c -q 10MHz -g 3.3 -n p output_files/$type.pof output_files/${type}_pre.svf`;
				`../openocd_flash/extractbinfromsvf.pl output_files/${type}_pre.svf`;
				`cat UFM1.bin UFM0.bin > UFMboth_pre.bin`;
				`cat CFM1.bin CFM0.bin > CFMboth_pre.bin`;
			
				#Now that we have our data files, we can find their offsets
				#Complication, the bits are swapped (and the word order)
			        `../swapbits ./UFMboth_pre.bin ./UFMboth_pre.bin.swap`;
			        `../swapbits ./CFMboth_pre.bin ./CFMboth_pre.bin.swap`;
				
				#Find the offset in the pof file
				my $UFMbothlen = -s "./UFMboth_pre.bin.swap";
				my $CFMbothlen = -s "./CFMboth_pre.bin.swap";
			        my $UFMoffset = `../find_offset ./UFMboth_pre.bin.swap 0 $UFMbothlen output_files/$type.pof`;
			        my $CFMoffset = `../find_offset ./CFMboth_pre.bin.swap 0 $CFMbothlen output_files/$type.pof`;
			
				print  "CFM:$CFMbothlen $CFMoffset UFM:$UFMbothlen $UFMoffset\n";
				$UFMoffset = hex($UFMoffset);
				$CFMoffset = hex($CFMoffset);
			
				my $sidoffset = hex("21800"); #Give some space for the core, then write sid data
				if ($fpgasize eq "16")
				{
					$sidoffset = hex("46000");
				}
				my $sidwavelocation = $sidoffset + $CFMoffset;
				print "Write wave offset at $sidwavelocation in the pof\n";
		
				`../modifypof $type ./output_files/$type.pof $sidwavelocation`;
			}
		
			#Now we patched the pof file, create the svf normally for use if flashing using openocd
			`quartus_cpf -c -q 10MHz -g 3.3 -n p output_files/$type.pof output_files/$type.svf`;
		
			#Make a core.bin for flashing the the config tool on the xl/xe or c64
			if (int($fpgasize)>=4)
			{
				#Legacy way of creating the core.bin
				#`../makeflash_$fpgasize $type ./output_files/$type.pof $versioncode output_files/core.bin`;
				#In fact this no longer works since swapbits is not identical for different byte offsets...
		
				#New way of creating the core.bin , which is basically catting the data from the UFM/CFM from the svf and then adding a header
				`../openocd_flash/extractbinfromsvf.pl output_files/$type.svf`;
				`cat UFM1.bin UFM0.bin > UFMboth_post.bin`;
				`cat CFM1.bin CFM0.bin > CFMboth_post.bin`;
			        `../swapbits ./UFMboth_post.bin ./UFMboth_post.bin.swap`;
			        `../swapbits ./CFMboth_post.bin ./CFMboth_post.bin.swap`;
				my $fpgasizenum = $fpgasize+0;
				`../makeflash $fpgasizenum $versioncode output_files/core.bin`;
			}
		
			chdir "..";
		}
	}
}


