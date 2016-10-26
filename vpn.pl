#!/usr/bin/perl

# loader for openvpn

use strict;
use warnings;

my $vpnDir = '/etc/openvpn/';

die "Need root\n" unless $> == 0;

my $path = `which openvpn`;
chomp($path);
if ($path eq '') {
	print "Can't find openvpn. Bye.\n" and exit;
}

my $loc = '';
while ($loc eq '') {
	my $tloc = '';
	my @locs = ();
	print "Country code: ";
	chomp ($tloc = <STDIN>);
	my $re = "^" . $vpnDir . lc($tloc) . ".+tcp";
	foreach my $fp (glob($vpnDir . "*.ovpn")) {
		if ($fp =~ /$re/) {
			push @locs, $fp;
		}
	}
	if (scalar @locs == 0) {
		print "No endpoints for ".$tloc.".\n";
	} else {
		my $ttloc = $locs[rand @locs];
		print "Fire up " . substr($ttloc, 13) . "? (y|n|q): ";
		chomp(my $r = <STDIN>);
		if (lc($r) eq 'q') {
			print "Bye.\n" and exit;
		}
		if (lc($r) eq "y") {
			$loc = $ttloc;
		}
	}
}
exec("$path $loc");
