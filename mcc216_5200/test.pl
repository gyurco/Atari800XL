       my $version = `svn info  | grep Revision: | cut -c11`;
	chomp $version;
        $version.=".0";
	print $version;
