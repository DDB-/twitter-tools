#!/usr/bin/perl

package Twitter;

use strict;
use warnings;

use Net::Twitter;

my $net_twitter;

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
        traits 			  => [qw(OAuth API::REST)],
        consumer_key        => $creds{'consumer_key'},
        consumer_secret     => $creds{'consumer_secret'},
        access_token        => $creds{'access_token'},
        access_token_secret => $creds{'access_token_secret'},
	);
    
    return $self;
}

sub tweet {
    my $self = shift;
    print "ERROR: Using function uninitilized\n" and return unless $net_twitter;
    print "ERROR: Empty tweet body\n" and return unless ($_[0]);
    
    my $tweet = shift;
    print ("ERROR: Tweet length of " . length($tweet) .  " is too long. Aborted.\n") and return if (length($tweet) > 140);
    
    my $result = eval { $net_twitter->update($tweet) };
    
	warn "$@\n" if $@;
}

1;