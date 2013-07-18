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
	BAD_REPLY_ID	=> 6,
	BAD_REPLY_LIST	=> 7,
};

# Global Variables
my $net_twitter;
my @timeline_tweets;
my @mention_tweets;

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
		when(BAD_REPLY_ID) { print "No tweet with reply id of " . $args{reply_id} . "\n";  }
		when(BAD_REPLY_LIST) { print "Unsupported or invalid list to reply to.\n"; }
	}
}

sub _print_errors {
	foreach my $error (@_){
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
	return $time_piece->strftime("%x %r");;
}

sub _create_timeline_array {
	my $timeline = shift;
	
	my $count = 1;
	my @timeline_array;
	foreach my $tweet_arr (@$timeline){
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
			push @timeline_array, \%info;
		}
	}
	
	return @timeline_array;
}

sub timeline {
	my $self = shift;
	
	if(!$net_twitter){ _print_error(UNINITIALIZED); return; }
	
	my @timeline = $net_twitter->home_timeline();
	@timeline_tweets = _create_timeline_array(\@timeline);
	
	foreach my $info(@timeline_tweets){
		print _format_tweet_info(%{$info});
	}
}

sub mentions {
	my $self = shift;

	if(!$net_twitter){ _print_error(UNINITIALIZED); return; }

	my @timeline = $net_twitter->mentions();
	@mention_tweets = _create_timeline_array(\@timeline);
	
	foreach my $info(@mention_tweets){
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
	push @errors, TWEET_EMPTY unless ($_[3]);
	if(@errors){ _print_errors(@errors); return; }
	
	my $reply_id 		= shift;
	my $reply_list 		= shift;
	my $include_others	= shift;
	my $tweet 			= shift;
	
	my $tweet_arr;
	if ( $reply_list eq 'timeline' ) {
		$tweet_arr = \@timeline_tweets;
	} elsif ( $reply_list eq 'mentions' ) {
		$tweet_arr = \@mention_tweets;
	} else {
		_print_error(BAD_REPLY_LIST); return;		
	}
	my %reply_info;
	foreach my $info (@$tweet_arr) {
		if ($$info{'sh_id'} == $reply_id){
			%reply_info = %$info;
		}
	}
	
	if(!%reply_info){
		_print_error( BAD_REPLY_ID, reply_id => $reply_id );
		return 0;
	}
	
	my @other_users;
	my @reply_tweet_parts = split( ' ', $reply_info{'text'} );
	if($include_others){
		foreach my $part (@reply_tweet_parts) {
			if ( $part =~ m/^@.+/ ){
				push @other_users, $part;
			}
		}
	}
	
	my $t_reply_id 		= $reply_info{'t_id'};
	my $reply_to_user 	= '@' . $reply_info{'username'}; 
	
	my $prefix = $reply_to_user . ' ';
	foreach my $user (@other_users) { $prefix .= $user . ' '; }
	$tweet = $prefix . $tweet;
	return if !_validate_tweet($tweet);

	my %reply_hash = ( status => $tweet, in_reply_to_status_id => $t_reply_id  );
	my $result = eval { $net_twitter->update( \%reply_hash ) }; 
	
	warn "$@\n" if $@;
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
