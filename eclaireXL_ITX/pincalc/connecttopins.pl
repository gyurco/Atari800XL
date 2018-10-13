#!/usr/bin/perl -w
use strict;

my %pinusage;
open (PINS,"pinusage");
	my $pincount = 1;
	while (<PINS>)
	{
		chomp;
		my @entry = split /,/;
		if (1==scalar @entry)
		{
			$pinusage{$pincount} = $entry[0];
			$pincount = $pincount+1;
		}
		if (3==scalar @entry)
		{
			my $base = $entry[0];
			my $start = $entry[1];
			my $end = $entry[2];
			if ($end>=$start) {$end=$end+1};
			if ($end<=$start) {$end=$end-1};
			while ($start != $end)
			{
				$pinusage{$pincount} = "${base}[$start]";
				if ($end>$start)
				{
					$start = $start+1;
				}
				else
				{
					$start = $start-1;
				}
				$pincount = $pincount+1;
			}
		}
		if (4==scalar @entry)
		{
			my $base = $entry[0];
			my $base2 = $entry[1];
			my $start = $entry[2];
			my $end = $entry[3];
			if ($end>=$start) {$end=$end+1};
			if ($end<=$start) {$end=$end-1};
			while ($start != $end)
			{
				$pinusage{$pincount} = "${base}[$start]";
				$pincount = $pincount+1;
				$pinusage{$pincount} = "${base2}[$start]";
				$pincount = $pincount+1;
				if ($end>$start)
				{
					$start = $start+1;
				}
				else
				{
					$start = $start-1;
				}
			}
		}
	}
close (PINS);

#foreach my $pin (sort {$a<=>$b} keys %pinusage)
#{
#	my $func = $pinusage{$pin};
#	print "$pin,$func\n";
#}

#<connect gate="G$1" pin="P$20" pad="A10"/>
my %pintopad;
while (<>)
{
	/connect.*pin=\"P\$(.*?)\" pad=\"(.*?)\"/;
	my $pin=$1;
	my $pad=$2;
	$pintopad{$pin}=$pad;
}


#From,To,Assignment Name,Value,Enabled
#,GPIO_0[0],Location,PIN_A13,Yes

#print "From,To,Assignment Name,Value,Enabled\n";
foreach my $pin (sort {$a<=>$b} keys %pintopad)
{
	my $pad = $pintopad{$pin};
	my $func = $pinusage{$pin};
#	print ",$func,P\$$pin,PIN_$pad,Yes\n";
	print "set_location_assignment PIN_$pad -to $func\n";
}


