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
	} elsif ($command eq "mentions") {
		$twitter->mentions();
	} elsif ($command eq "reply") {
		my $reply_id 	= shift @cont_arr;
		my $include_others = 0;
		if( $cont_arr[0] eq '--all' or $cont_arr[0] eq '-a' ) {
			$include_others = 1;
			shift @cont_arr;
		}
		my $tweet 		= join (' ', @cont_arr);
		$twitter->reply( $reply_id, 'timeline', $include_others, $tweet );
	} elsif ($command eq 'test'){
		_handle_reply(\@cont_arr);
	}
}

sub _handle_reply {
	my $content_arr = shift || (print "Empty command!\n" and return);
	
	# Initialize options and create defaults
	my %options;
	$options{source} 	= 'timeline';
	$options{all} 		= 0;

	my $index = 0;
	my $option_index = 0;
	my $end = scalar @{$content_arr};
	while ( $index < $end and $index == $option_index ){
		my $current = $$content_arr[$index];
		if ( $current eq '-s' or $current eq '--source' ) {
			my $value = $$content_arr[$index+1];
			if ( $value eq 'm' or $value eq 'mentions' ){
				$options{source} = 'mentions';
				$option_index += 2;
			} elsif ( $value eq 't' or $value eq 'timeline' ) {
				$options{source} = 'timeline';
				$option_index += 2
			}
			$index++;
		} elsif ( $current eq '-a' or $current eq '--all' ) {
			$options{all} = 1;
			$option_index++;
		}
		$index++;
	}
	
	foreach my $index (1..$option_index){
		shift @$content_arr;
	}
	my $tweet = join( ' ', @$content_arr );
	print $tweet;
	
}

1;
