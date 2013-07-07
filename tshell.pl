#!/usr/bin/perl

use strict;
use warnings;

use Term::ANSIColor;
use Twitter;

if(!defined $ARGV[0]){
	print "Usage: ./tshell.pl USERNAME\n";
    print "No username provided. Exiting.\n" and exit;
}

my $twitter_name = shift @ARGV;
my $twitter = Twitter->new($twitter_name);

for(;;){
    print_psi(); #Print prompt
	my $content = <>; # Get the command
	chomp $content;
	
	last if $content eq "exit"; #Exit on exit command
    
    delegate($content);
}

sub print_psi {
    local $Term::ANSIColor::AUTORESET = 1;
    use Term::ANSIColor qw(:constants);
    print RED $twitter_name;
    print WHITE '@';
    print BLUE 'Twitter>';
}

sub delegate {
    my $content = shift || (print "Empty command!\n" and return);
    
    my @cont_arr = split(' ', $content);
    my $command = shift @cont_arr;
    
    if ($command eq "tweet"){
        my $tweet = join (' ', @cont_arr);
        $twitter->tweet($tweet);
    } elsif ($command eq "timeline") {
		$twitter->timeline();
	} elsif ($command eq "reply") {
		my $reply_id 	= shift @cont_arr;
		my $include_others = 0;
		if( $cont_arr[0] eq '--all' or $cont_arr[0] eq '-a' ) {
			$include_others = 1;
			shift @cont_arr;
		}
		my $tweet 		= join (' ', @cont_arr);
		$twitter->reply( $reply_id, 'timeline', $include_others, $tweet );
	}
}
