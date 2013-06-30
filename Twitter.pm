#!/usr/bin/perl

package Twitter;

use strict;
use warnings;

use feature qw(switch);

use Data::Dumper;
use Net::Twitter;
use Time::Piece;

# Constants
use constant {
	UNINITIALIZED	=> 1,
	TWEET_EMPTY		=> 2,
	TWEET_LONG		=> 3,
	NO_REPLY_ID		=> 4,
	NO_REPLY_LIST	=> 5,
};

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

sub _print_error {
	my $code = shift || ( print "ERROR: No error code given!\n" and return );
	my %args = @_;
			
	given($code){
		when(UNINITIALIZED) { print "ERROR: No twitter account initialized\n"; }
		when(TWEET_EMPTY) { print "ERROR: Empty tweet body.\n"; }
		when(TWEET_LONG) {
			print ("ERROR: Tweet length of " . length($args{tweet}) .  " is too long. Aborted.\n");
		}
		when(NO_REPLY_ID){ print "ERROR: No Reply ID given for replying\n"; }
		when(NO_REPLY_LIST) { print "ERROR: No Reply List selected\n"; }
	}
}

sub _print_errors {
	my @errors = @_;
	
	foreach my $error (@errors){
		_print_error($error);
	}
}

sub _format_tweet_info {
	my %info = @_;
	
	my $tweet = "[$info{time}] $info{sh_id}: ";
	$tweet .= "[RT $info{retweeted_user}] " if($info{'retweeted_user'}); 
	$tweet .= "$info{username} ($info{name}): $info{text}\n---\n";
	return $tweet;
}

sub _format_time {
	my $time = shift;
	my $time_piece = Time::Piece->strptime($time, "%a %b %d %T %z %Y");
	$time_piece += $time_piece->localtime->tzoffset;
	return $time_piece->strftime("%r");;
}

sub timeline {
	my $self = shift;
	
	if(!$net_twitter){ _print_error(UNINITIALIZED); return; }
	
	@timeline_tweets = ();
	my $count = 0;
	my @timeline = $net_twitter->home_timeline();
	foreach my $tweet_arr (@timeline){
		foreach my $tweet (@{$tweet_arr}){
			my $created_at = $tweet->{'created_at'};
			my %info = ( "username" , $tweet->{'user'}->{'screen_name'},
						 "t_id"		, $tweet->{'user'}->{'id'},
						 "name"		, $tweet->{'user'}->{'name'},
						 "text"		, $tweet->{'text'},
						 "time"		, _format_time($created_at),
						 "sh_id"	, $count
			);
			if($tweet->{'retweeted_status'}){
				$info{"retweeted_user"} = $tweet->{'retweeted_status'}->{'user'}->{'screen_name'};
			}
			$count += 1;
			push @timeline_tweets, \%info;
		}
	}
	
	foreach my $info(@timeline_tweets){
		print _format_tweet_info(%{$info});
	}
}

sub _validate_tweet {
	my $tweet = shift || ( print "ERROR: No tweet given\n" and return 0 );
	
	if (length($tweet) > 140) {
		_print_error( TWEET_LONG, 'tweet' => $tweet );
		return 0;
	}
	
	return 1;
}

sub reply {
	my $self = shift;
	
	my @errors;
	push @errors, UNINITIALIZED unless $net_twitter;
	push @errors, NO_REPLY_ID unless ($_[0]);
	push @errors, NO_REPLY_LIST unless ($_[1]);
	push @errors, TWEET_EMPTY unless ($_[2]);
	if(@errors){ _print_errors(@errors); return; }
	
	my $reply_id = shift;
	my $reply_list = shift;
	my $tweet = shift;
	
	my %reply_info;
	foreach my $info (@timeline_tweets){
		if ($$info{'sh_id'} == $reply_id){
			%reply_info = %$info;
		}
	}
	print Dumper(\%reply_info);
}

sub tweet {
    my $self = shift;
	
	my @errors;
	push @errors, UNINITIALIZED unless $net_twitter;
	push @errors, TWEET_EMPTY unless ($_[0]);
    if(@errors){ _print_errors(@errors); return; }
    
    my $tweet = shift;
    return if !_validate_tweet($tweet);
    
    my $result = eval { $net_twitter->update($tweet) };
    
	warn "$@\n" if $@;
}

1;
