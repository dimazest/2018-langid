#!/usr/bin/perl

use strict;
use warnings;
use v5.10;

use FindBin;
use lib "$FindBin::Bin/../Libraries";
use TweetTokenizer;

# Elizabeth Blair
# Last Edited: 4/7/14
# 2/12/14:	Created
# 3/3/14:	Updated to use TweetTokenizer library instead of system calls
#		Added option to use one file instead of a full directory
# 3/5/14:	Fixed some bugs based on spacing escapes in location names
# 3/10/14:	Added ( and ) to file name escapes
# 4/7/14:	Changed some comments

# This script takes a raw tweet collection and produces both a one-line and a tokenized version of the
# tweets. It can take either three files or three directories (first in, last two out). If directories are
# given, all files in the input directory will be run through the oneline and tokenization processes and
# versions of the same name (and extension) will be created in the oneline and tokenized directories.
# If a metadata line is provided (which it should be) it will be preserved on the first line and the tweet
# will appear on the second line. Tokens in the tokenized version are space-delimited.

# Usage: ./processTweets.pl <in file|dir> <oneline file|dir> <tokenized file|dir>

my ($in,$one,$tok) = @ARGV;
if (-f $in)
{
	# Create oneline version of file
	open(my $inFileHan,'<:encoding(utf8)',"$in") or die "Couldn't open input file $in";
	open(my $oneFileHan,'>:encoding(utf8)',"$one") or die "Couldn't open output file $one";
	my @tweets = @{TweetTokenizer::onelineFile($inFileHan)};
	foreach(@tweets) { say $oneFileHan $_; }
	close($inFileHan) or die "Couldn't close input file $in";
	close($oneFileHan) or die "Couldn't close output file $one";

	$one =~ s/( |\(|\))/\\$1/g;
	$tok =~ s/( |\(|\))/\\$1/g;
	# Create tokenized version of file
	TweetTokenizer::tokenizeFile("$one","$tok");
}
elsif (-d $in)
{
	opendir(my $inDirHandle,$in) or die "Couldn't open directory $in";

	foreach(readdir($inDirHandle))
	{
		if ($_ =~ /^\.|^~|~$/) { next; }
		say "Processing file $_...";
		$one =~ s/\\//g;
		$tok =~ s/\\//g;
		# Create oneline version of file
		open(my $inFileHan,'<:encoding(utf8)',"$in/$_") or die "Couldn't open input file $in/$_";
		open(my $oneFileHan,'>:encoding(utf8)',"$one/$_") or die "Couldn't open output file $one/$_";
		my @tweets = @{TweetTokenizer::onelineFile($inFileHan)};
		foreach(@tweets) { say $oneFileHan $_; }
		close($inFileHan) or die "Couldn't close input file $in/$_";
		close($oneFileHan) or die "Couldn't close output file $one/$_";

		$one =~ s/( |\(|\))/\\$1/g;
		$tok =~ s/( |\(|\))/\\$1/g;
		# Create tokenized version of file
		TweetTokenizer::tokenizeFile("$one/$_","$tok/$_");
	}

	closedir($inDirHandle) or die "Couldn't close directory $in";
}
else { die "Input location must be file or directory"; }
