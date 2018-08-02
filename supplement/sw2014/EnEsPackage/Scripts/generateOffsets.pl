#!/usr/bin/perl

# Elizabeth Blair
# Last Edited: 4/7/14
# 4/4/14:	Created
# 4/7/14:	Moved majority of content to TweetProcessing; added comments

use strict;
use warnings;
use v5.10.1;

use Cwd;
use FindBin;
use lib "$FindBin::Bin/../Libraries";
use FileOps;
use TweetProcessing;

# This script uses raw and tokenized versions of tweets to generate the character offsets of all of
# the tokens for all tweets in a file, and write them to a given output location. This can be done for
# either singular files or directories of identical structure. If directoreis are used, all files must
# have the same name. The two input files are .txt and the output file is .tsv.
# See runFile() for specifics, but it reads in all of the tokenized tweets (meta on first line, tweet
# on second with tokens space-delimited), then one-by-one finds the offsets of those tokens in the raw
# tweet text from the raw file. Offsets start at 0. See TweetProcessing::genOffsets() for details.

# Usage: ./generateOffsets.pl <raw tweet file|dir> <tokenized tweet file|dir> <out file|dir>

my $basedir = cwd();	# Base directory of the script (used for FileOps)

# runFile()
# Input: raw tweet in file handle, tokenized tweet in file handle, out file handle
# Output: none
# Description: Read in all the tweets in the raw tokenized file into storage, then use the corresponding
#		raw tweet text to generate offsets for each token. Write out the tokens in the shared-
#		task TSV format (ID, user, start, end) to the output file handle. Offsets are written out
#		in the order of the raw tweet file.
#		Raw tweets should be in the format given by tweetPull and tokenized tweets should have
#		the first line as metadata and the second as the tweet text, with tokens space-delimited.
sub runFile
{
	my ($rawFileHan,$tokenFileHan,$outFileHan) = @_;

	# Key = tweet ID, value is hash with keys 'user' = user ID, 'tokens' = ref to array of tokens
	my %tweets;
	while(!eof($tokenFileHan))
	{
		my $meta = <$tokenFileHan>;
		chomp $meta;
		my ($id,$user) = ($meta =~ /\{\{\s*ID\s*=\s*(\d+)\}\}\{\{\s*USER\s*=\s*(\d+)\s*\}\}/);
		my $tweet = <$tokenFileHan>;
		chomp $tweet;
		my @tokens = split(' ',$tweet);
		$tweets{$id}{'user'} = $user;
		$tweets{$id}{'tokens'} = \@tokens;
	}

	while(!eof($rawFileHan))
	{
		my ($meta,$tweet) = TweetProcessing::assembleTweet($rawFileHan);
		my ($id,$user) = ($meta =~ /^\{\{\s*ID\s*=\s*(\d+)\}\}\{\{\s*USER\s*=\s*(\d+)\s*\}\}$/);
		if (exists($tweets{$id}))
		{
			unless ($user == $tweets{$id}{'user'}) { die "User mismatch: raw $user vs tok $id"; }
			my @tokens = @{$tweets{$id}{'tokens'}};
			my @offsets = TweetProcessing::genOffsets($tweet,\@tokens);
			foreach(@offsets) { say $outFileHan "$id\t$user\t$$_[0]\t$$_[1]"; }
		}
	}
}

# ------------------------------------------------------------------

# Main code: take in the file locations, pass to FileOps to do runFile() on each (extensions: txt, txt => tsv)
my ($raw,$token,$out) = @ARGV;
FileOps::runFiles([$raw,$token],[$out],\&runFile,$basedir,['.txt::utf8','.txt::utf8','.tsv::utf8']);
