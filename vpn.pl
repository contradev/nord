#!/usr/bin/perl

# loader for openvpn
#
# Author:  simon britton

use strict;
use warnings;
use 5.010;

#die "Need root\n" unless $> == 0;

my $vpnDir = '/etc/openvpn/';

# location
my $countrycode = '';
# endpoints to skip if connection failed
my %skips = ();
# info lines
my @info = ();
# chosen node
my $node = '';


# anything on commandline args?
if (scalar @ARGV) {
	if ($ARGV[0] =~ /^[a-zA-Z]{2}$/) {
		$countrycode = $ARGV[0];
		push @info, "You have selected a " . uc($countrycode) . " endpoint.\n";
	}
}

foreach my $line (@info) {
	say "INFO: " . $line;
}

#main
while ($node eq '') {
	my @matchingLocationNodes = ();
	while ($countrycode eq '') {
		print "Country code: ";
		chomp ($countrycode = <STDIN>);
		if ($countrycode !~ /^[a-zA-Z]{2}$/) {
			say "'" . $countrycode . "' appears invalid.";
			$countrycode = '';
		}
	}
	my $re = "^" . qr($vpnDir) . lc($countrycode) . '\d+\..+tcp';
	foreach my $fp (glob($vpnDir . "*.ovpn")) {
		if ($fp =~ /$re/) {
			push @matchingLocationNodes, $fp;
		}
	}
	my $locationscount = scalar @matchingLocationNodes;
	if ($locationscount == 0) {
		print "No endpoints for '" . uc($countrycode) . "'!\n";
		$countrycode = '';
	} elsif (scalar(keys %skips) == $locationscount) {
		print "No more " . uc($countrycode) . " endpoints left to try!\n";
		$countrycode = '';
	} else {
		my $ttloc = $matchingLocationNodes[rand @matchingLocationNodes];
		if (!exists($skips{$ttloc})) {
			print "Fire up " . substr($ttloc, 13) . "? (y|n|q): ";
			chomp(my $r = lc(<STDIN>));
			if ($r eq 'q') {
				print "Bye.\n" and exit;
			} elsif ($r eq "n") {
				$skips{$ttloc} = 1;
			} elsif ($r eq "y") {
				$node = $ttloc;
			}
			if ($node ne '') {
				chdir $vpnDir;
				system("sudo openvpn $node");
				print "\nReconnect to another? (y|n): ";
				chomp(my $r = <STDIN>);
				if (lc($r) ne 'y') {
					print "Bye.\n" and exit;
				}
				# Still here? Try a new node next time
				$skips{$node} = 1;
				$node = '';
				system('clear') if $^O =~ /bsd|linux|darwin/i;
			}
		}
	}
}
