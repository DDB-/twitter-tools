#!/usr/bin/perl

use strict;
use warnings;
use Twitter;

my $username = $ENV{USER};
my $psi = $username . "\@twitter> ";

if(!defined $ARGV[0]){
    print "No username provided. Exiting.\n" and exit;
}

my $twitter_name = shift @ARGV;
my $twitter = Twitter->new($twitter_name);

for(;;){
	print $psi; # Print the prompt
	my $content = <>; # Get the command
	chomp $content;
	
	print $content . "\n";
	
	last if $content eq "exit"; #Exit on exit command
}

sub delegate {
    
}
