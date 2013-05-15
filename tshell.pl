#!/usr/bin/perl

use strict;
use warnings;

my $username = $ENV{USER};
my $psi = $username . "\@twitter> ";

for(;;){
	print $psi; # Print the prompt
	my $command = <>; # Get the command
	chomp $command;	
	
	print $command . "\n";
	
	last if $command eq "exit"; #Exit on exit command	
}
