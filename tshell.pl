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
		my $reply_command 	= shift @cont_arr;
		my $reply_options 	= _handle_options($reply_command, \@cont_arr);
		$twitter->reply( $reply_options->{sh_id} , $reply_options->{source}, 
						 $reply_options->{all}, $reply_options->{tweet} )
	} elsif ( $command eq "retweet" or $command eq "rt" ) {
		my $retweet_command = shift @cont_arr;
		my $retweet_options = _handle_options($retweet_command);
		$twitter->retweet( $retweet_options->{sh_id}, $retweet_options->{source} );
	} 
}

sub _handle_options {
	my $reply_command = shift || (print "Empty command!\n" and return);
	my $cont_arr	  = shift;
			
	# Initialize options and create defaults
	my %options;
	$options{sh_id}		= -1; 
	$options{source} 	= '';
	$options{all} 		= 0;

	my @args = split( '', $reply_command );
	foreach my $arg (@args) {
		$options{sh_id} 	= $arg if $arg =~ m{^\d+$};
		$options{source} 	= 'timeline' if $arg eq 't';
		$options{source} 	= 'mentions' if $arg eq 'm';
		$options{all}		= 1 if $arg eq 'a'
	}
	
	$options{tweet} = join( ' ', @$cont_arr ) if defined $cont_arr;
	return \%options; 
}

1;
