#!/usr/bin/perl -w
use POSIX qw(strftime);

my @files;

push @files, glob("mcc216/build*/output_files/*.arg");
push @files, glob("mcc216/build*/output_files/*.sof");
push @files, glob("mcc216/build*/output_files/*.rbf");
push @files, glob("mcc216/build*/output_files/*.summary");
push @files, glob("mcc216/build*/output_files/*.rpt");

push @files, glob("mist/build*/out/*.sof");
push @files, glob("mist/build*/out/*.rbf");
push @files, glob("mist/build*/out/*.summary");
push @files, glob("mist/build*/out/*.rpt");

push @files, glob("chameleon/build*/output_files/*.sof");
push @files, glob("chameleon/build*/output_files/*.rbf");
push @files, glob("chameleon/build*/output_files/*.summary");
push @files, glob("chameleon/build*/output_files/*.rpt");

push @files, glob("de1/build*/output_files/*.sof");
push @files, glob("de1/build*/output_files/*.summary");
push @files, glob("de1/build*/output_files/*.rpt");

push @files, glob("replay/sdcard/*.bin");
push @files, glob("replay/sdcard/*.ini");

mkdir "/var/www/html/autobuild/";
my $date = strftime("%Y%m%d",gmtime);
my $dir = "/var/www/html/autobuild/$date";
mkdir $dir;
open (LOG,">".$dir."/log") or die "Failed to open log";
foreach (@files)
{
	my $creationtime = (stat($_))[9];
	my $creation = strftime("%Y%m%dT%T",gmtime($creationtime));
	print LOG "File:$_ Date:$creation\n";

	/(.*)\/(.*)/;
	my ($dir2,$file) = ($1,$2);
	#print "DIR:$dir2 FILE:$file\n";
	`mkdir -p $dir/$dir2`;

	`cp -f $_ $dir/$dir2`;
}
close(LOG);
`cp -f instructions.txt $dir/`;


