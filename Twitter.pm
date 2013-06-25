#!/usr/bin/perl

package Twitter;

use strict;
use warnings;

use feature qw(switch);

use Data::Dumper;
use Net::Twitter;
use Time::Piece;

# Constants
my $UNINITIALIZED = 1;

# Global Variables
my $net_twitter;
my @timeline_tweets;

sub new {
    my $self = shift;
    my $username = shift || die "No username given\n";
    my $cred_file = "credentials/$username-Credentials1.txt";
    
    my %creds = ();
    open my $info, $cred_file or die "Could not open $cred_file: $!\n";
    while( my $line = <$info>)  {
        chomp $line;
        my @chars = split(":", $line);
        $creds{$chars[0]} = $chars[1];
    }
    close $info;
    
    $net_twitter = Net::Twitter->new(
        traits 			  => [qw(OAuth API::RESTv1_1)],
        consumer_key        => $creds{'consumer_key'},
        consumer_secret     => $creds{'consumer_secret'},
        access_token        => $creds{'access_token'},
        access_token_secret => $creds{'access_token_secret'},
	);
    
    return $self;
}

sub print_error {
	my $code = shift || ( print "WARN: No error code given!\n" and return );
			
	given($code){
		when($Twitter::UNITIALIZED) { print "ERROR: No twitter account initialized\n"; }
	}
}

sub format_tweet_info {
	my %info = @_;
	
	my $tweet = "[$info{time}] $info{count}: ";
	if($info{'retweeted_user'}){
		$tweet .= "[RT $info{retweeted_user}] ";
	}
	$tweet .= "$info{username} ($info{name}): $info{text}\n---\n";
	return $tweet;
}

sub format_time {
	my $time = shift;
	my $time_piece = Time::Piece->strptime($time, "%a %b %d %T %z %Y");
	$time_piece += $time_piece->localtime->tzoffset;
	return $time_piece->strftime("%r");;
}

sub timeline {
	my $self = shift;
	print_error($Twitter::UNINITIALIZED) and return unless $net_twitter;
	
	@timeline_tweets = ();
	my $count = 0;
	my @timeline = $net_twitter->home_timeline();
	foreach my $tweet_arr (@timeline){
		foreach my $tweet (@{$tweet_arr}){
			my $created_at = $tweet->{'created_at'};
			my %info = ( "username" , $tweet->{'user'}->{'screen_name'},
						 "id"		, $tweet->{'user'}->{'id'},
						 "name"		, $tweet->{'user'}->{'name'},
						 "text"		, $tweet->{'text'},
						 "time"		, format_time($created_at),
						 "count"	, $count
			);
			if($tweet->{'retweeted_status'}){
				$info{"retweeted_user"} = $tweet->{'retweeted_status'}->{'user'}->{'screen_name'};
			}
			$count += 1;
			push @timeline_tweets, \%info;
		}
	}
	
	foreach my $info(@timeline_tweets){
		print format_tweet_info(%{$info});
	}
}

sub tweet {
    my $self = shift;
    print_error($Twitter::UNINITIALIZED) and return unless $net_twitter;
    print "ERROR: Empty tweet body\n" and return unless ($_[0]);
    
    my $tweet = shift;
    print ("ERROR: Tweet length of " . length($tweet) .  " is too long. Aborted.\n") and return if (length($tweet) > 140);
    
    my $result = eval { $net_twitter->update($tweet) };
    
	warn "$@\n" if $@;
}

1;
