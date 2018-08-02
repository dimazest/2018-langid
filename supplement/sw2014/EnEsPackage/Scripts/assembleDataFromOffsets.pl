#!/usr/bin/perl

# Elizabeth Blair
# Last Edited: 3/10/14
# 3/10/14:	Created
# 4/7/14:	Moved assembly to TweetProcessing; added comments

use strict;
use warnings;
use v5.10.1;

use FindBin;
use lib "$FindBin::Bin/../Libraries";
use TweetProcessing;

# Replace the offsets in a shared-task-format TSV offset file with the token they
# represent in the associated tweet. Requires a raw tweet file (in the tweetPull.rb
# format) and an offset file (for tweets in the raw file). Output is given in an
# adjusted TSV format, with columns 'id','user','token','annotation'.
# There are two modes of operation: 'reg' and 'gold'. Reg will look for a gold
# annotation in the fifth column of offsets and include it in the fourth of output.
# Reg will not do this.

# Usage: ./assembleDataFromOffsets.pl <reg|gold> <raw file> <offset file> <out file>

my ($mode,$rawFile,$offsetFile,$outFile) = (shift,shift,shift,shift);

# Read in all the tweets from the raw file and store them in a hash
# Key = tweet ID, value is hash ref with keys user = user ID, tweet = tweet text
my %tweets;
open(my $rawFileHan,'<:encoding(utf8)',$rawFile) or die;
while(!eof($rawFileHan))
{
	my ($meta,$tweet) = TweetProcessing::assembleTweet($rawFileHan);
	my ($id,$user) = ($meta =~ /\{\{ID=(\d+)\}\}\{\{USER=(\d+)/);
	$tweet =~ s/\n/ /g;
	$tweets{$id}{user} = $user;
	$tweets{$id}{tweet} = $tweet;
}
close($rawFileHan) or die;

# Read in each line of offset information, find the tweet it's associated with (in hash),
# and replace the two offset columns with one column containing the referenced token
# from the tweet. If in 'gold' mode, include the annotation data as well. Output the
# altered line to the out file. Maintains the same order as the input file.
open(my $offsetFileHan,'<',$offsetFile) or die;
open(my $outFileHan,'>:encoding(utf8)',$outFile) or die;
while(<$offsetFileHan>)
{
	chomp;
	my @parts = split(/\t/,$_);
	unless(exists($tweets{$parts[0]})) { next; }
	unless($parts[1] == $tweets{$parts[0]}{user}) { die "User mismatch on $parts[0]"; }
	my $token = substr($tweets{$parts[0]}{tweet},$parts[2],$parts[3]-$parts[2]+1);
	if ($mode eq 'gold') { say $outFileHan "$parts[0]\t$parts[1]\t$parts[2]\t$parts[3]\t$token\t$parts[4]"; }
	else		     { say $outFileHan "$parts[0]\t$parts[1]\t$parts[2]\t$parts[3]\t$token"; }
}
close($offsetFileHan) or die;
close($outFileHan) or die;
