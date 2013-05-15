#!/usr/bin/perl

use strict;
use warnings;
use Net::Twitter;
use File::Basename qw();

#Get File directory info
my ($name, $path, $suffix) = File::Basename::fileparse($0);
my $credentials = $path . "TieDomiFan-Credentials1.txt";

# Read My Credentials and Write them to a Hash
my %creds = ();
open my $info, $credentials or die "Could not open $credentials: $!";
while( my $line = <$info>)  { 
	chomp $line;  
	my @chars = split(":", $line);
	$creds{$chars[0]} = $chars[1];  
}
close $info;

my $tweet_string = join(" ", @ARGV);
tweet($tweet_string, %creds);

sub tweet {
	#Return if nothing is to be tweeted
	return unless ($_[0]);
	my %cred = @_[1..8];
	
	#Return if the tweet is too long
	my $tweet_string = $_[0];
	print ("Tweet length of " . length($tweet_string) .  " is too long. Aborted.\n") and exit if (length($tweet_string) > 140);
	
	#The actual stuff needed for the tweet
	my $nt = Net::Twitter->new(
	  traits 			  => [qw(OAuth API::REST)],
	  consumer_key        => $cred{'consumer_key'},
	  consumer_secret     => $cred{'consumer_secret'},
	  access_token        => $cred{'access_token'},
	  access_token_secret => $cred{'access_token_secret'},
	);

	my $result = eval { $nt->update($tweet_string) };	

	warn "$@\n" if $@;
}
