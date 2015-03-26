#!/usr/bin/perl -w
use strict;

my $wanted_variant = shift @ARGV;

my $name="papilioduo";

#variants...
my $PAL = 1;
my $NTSC = 0;

my $RGB = 1; # i.e. not scandoubled
my $VGA = 2;

#Added like this to the generated qsf
#set_parameter -name TV 1

my %variants = 
(
	"PAL_RGB" => 
	{
		"TV" => $PAL,
		"SCANDOUBLE" => 0,
		"VIDEO" => $RGB,
		"COMPOSITE_SYNC" => 1
	},
	"PAL_RGBHV" => 
	{
		"TV" => $PAL,
		"SCANDOUBLE" => 0,
		"VIDEO" => $RGB,
		"COMPOSITE_SYNC" => 0
	},
	"PAL_VGA" =>
	{
		"TV" => $PAL,
		"SCANDOUBLE" => 1,
		"VIDEO" => $VGA,
		"COMPOSITE_SYNC" => 0
	},
	"PAL_VGA_CS" =>
	{
		"TV" => $PAL,
		"SCANDOUBLE" => 1,
		"VIDEO" => $VGA,
		"COMPOSITE_SYNC" => 1
	},
	"NTSC_RGB" =>
	{
		"TV" => $NTSC,
		"SCANDOUBLE" => 0,
		"VIDEO" => $RGB, 
		"COMPOSITE_SYNC" => 1
	},
	"NTSC_RGBHV" =>
	{
		"TV" => $NTSC,
		"SCANDOUBLE" => 0,
		"VIDEO" => $RGB, 
		"COMPOSITE_SYNC" => 0
	},
	"NTSC_VGA" => 
	{
		"TV" => $NTSC,
		"SCANDOUBLE" => 1,
		"VIDEO" => $VGA,
		"COMPOSITE_SYNC" => 0
	},
	"NTSC_VGA_CS" => 
	{
		"TV" => $NTSC,
		"SCANDOUBLE" => 1,
		"VIDEO" => $VGA,
		"COMPOSITE_SYNC" => 1
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
	chdir $dir;

	`cp -p ../pll/* .`;
	`cp -p ../../common/a8core/*.vhd .`;
	`cp -p ../../common/a8core/*.vhdl .`;
	`cp -p ../../common/components/*.vhd .`;
	`cp -p ../../common/components/*.vhdl .`;
	`cp -p ../../common/components/*.v .`;
	`cp -p ../../common/zpu/*.vhd .`;
	`cp -p ../../common/zpu/*.vhdl .`;
	`cp -p ../*.vhd .`;
	`cp -p ../*.vhdl .`;

	`cp -p ../$name.ucf .`;
	`cp -p ../$name.ut .`;
	`cp -p ../$name.prj .`;

	`mkdir -p xst/projnav.tmp/`;

	`cp -p ../*.xst .`;
	# TODO make project file `../makexst ../atari800core.qsf ./common/a8core ./common/components ./common/zpu`;
	my $generics = "-generics {";
	foreach my $key (sort keys %{$variants{$variant}})
	{
		my $val = $variants{$variant}->{$key};
		$generics.="$key=$val ";
	}
	$generics .= "}\n";
	`echo '$generics' >> $name.xst`;

	`echo "Starting Synthesis" >> build.log 2>>build.err`;
	`xst -intstyle ise -ifn $name.xst -ofn $name.syr >> build.log 2>>build.err`;
	
	`echo "Starting NGD" >> build.log 2>>build.err`;
	`ngdbuild -intstyle ise -uc $name.ucf -dd _ngo -nt timestamp  -p xc6slx9-tqg144-3 $name.ngc $name.ngd >> build.log 2>>build.err`;
	
	`echo "Starting Map..." >> build.log 2>>build.err`;
	`map -intstyle ise -p xc6slx9-tqg144-3 -w -logic_opt off -ol high -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -mt off -detail -ir off -pr off -lc off -power off -o ${name}_map.ncd $name.ngd $name.pcf >> build.log 2>>build.err`;
	
	`echo "Starting Place & Route..." >> build.log 2>>build.err`;
	`par -w -intstyle ise -ol high -mt off ${name}_map.ncd $name.ncd $name.pcf >> build.log 2>>build.err`;
	
	`echo "Starting Timing Analysis..." >> build.log 2>>build.err`;
	`trce -intstyle ise -v 3 -s 3 -n 3 -fastpaths -xml $name.twx $name.ncd -o $name.twr $name.pcf >> build.log 2>>build.err`;
	
	`echo "Starting Bitgen..." >> build.log 2>>build.err`;
	`bitgen -intstyle ise -f $name.ut $name.ncd >> build.log 2>>build.err`;

	
	chdir "..";
}

