#!/usr/bin/perl -w
use strict;

my $section;
my $program = 0;
my %bytype;
my $type;
while (<>)
{
	if (/Max 10 (.*)/)
	{
		$section = $1;
		$program = 0;
		if ($section=~/^Program (....)$/)
		{
			$program = 1;
			$type = $1;
			$bytype{$type} = "";
		}
	}
	if ($program and /SDR 32 TDI \(([A-F0-9]+)\);/)
	{
		$bytype{$type} = $bytype{$type}.$1;
	}
}

foreach (keys %bytype)
{
	print "$_:".length($bytype{$_})."\n";
	open OUT,">$_.bin";
	binmode(OUT);

	print OUT pack 'B*', unpack 'b*', pack("H*",$bytype{$_});
		#print OUT pack("H*",$bytype{$_});
	close(OUT);
}

