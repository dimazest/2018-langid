package TweetTokenizer;

# Elizabeth Blair
# Last Edited: 3/3/14
# 2/26/14:	Created
# 2/26/14:	Fixed shift inside deref bug, added comments
# 3/3/14:	Added file tokenization and contraction split/join; moved detok contraction code to joinContractions()
#		Moved the oneline code into onelineFile() here
# 3/5/14:	Changed out to outFileHan in tokenize; added second apostrophe type
# 3/10/14:	Changed oneline to keep the IDs associated with the tweet
# 4/4/14:	No longer replace all whitespaces with one space in oneline

use strict;
use warnings;
use v5.10;

use utf8;

# A set of operations related to the tokenization and detokenization of tweets.
# Tweets in text form are one line of text with correct spacing around words and punctuation.
# Tweets in token form are arrays of tokens.

# This is a char class of all the weird symbols I could find in the tweets (All Unicode Other_Symbol, plus some extras)
my $oddSymbols = '[ツ•😕😟😑😛😬😴😮😯😀😗😧😙😦\p{Other_Symbol}]';

# splitContractions()
# Input: string with tweet text
# Output: string with tweet text
# Description: Split contractions into two tokens (space delimited), coming in three flavors:
#		- Special case: can't -> can n't
#		- N't cases: don't -> do n't | haven't -> have n't
#		- Normal cases: [not n]'[not t] -> [not n] '[not t]
sub splitContractions
{
	my $tweet = shift;
	
	$tweet =~ s/([Cc][Aa])([Nn])[’']([Tt])/$1$2 $2'$3/g;
	$tweet =~ s/([A-Za-z])([Nn][’'][Tt])/$1 $2/g;
	$tweet =~ s/([A-MO-Za-mo-z])([’'][A-SU-Za-su-z])/$1 $2/g;

	return $tweet;
}


# joinContractions()
# Input: string with tweet text
# Output: string with tweet text
# Description: Fix additional spacing issues with contractions, coming in three flavors:
#		- "can n't" becomes "can't"
#		- "[letter] n't" becomes "[letter]n't"
#		- "[letter] '[letter]" becomes "[letter]'[letter]"
sub joinContractions
{
	my $tweet = shift;

	$tweet =~ s/([Cc][Aa])([Nn]) ([Nn][’'][Tt])/$1$3/g;
	$tweet =~ s/([A-Za-z]) ([Nn][’'][Tt])/$1$2/g;
	$tweet =~ s/([A-MO-Za-mo-z]) ([’'][A-SU-Za-su-z])/$1$2/g;

	return $tweet;
}

# tokenizeFile()
# Input: Input file, output file
# Output: none
# Description: Tokenize the tweets (one per line) in the input file, based primarily on the tokenization
#		provided by the ArkTweet tokenizer v.0.3.2, with some augmentations. Tokens are space-delimited.
#		The ArkTweet tokenizer folder should be in the same directory as this module.
#		The output file path should be surrounded by single-quotes (preserving space escapes).
#		Additional tokenization done:
#		- Contractions are split (apostrophe endings and n't in own token, with can't becoming can n't)
#		- Extra spacing around some odd symbols to separate them from the text
#		- All odd (mostly Unicode) symbols are replaced with {symbol}
#		- Unicode character FE0F (spacing) is removed to prevent unicode errors when reading the data
sub tokenizeFile
{
	my ($inFile,$outFile) = @_;

	# Run the ArkTweet tokenizer v.0.3.2 on the input file, feed tokenized results to output file
	system("../EnEsPackage/Libraries/ark-tweet-nlp-0.3.2/twokenize.sh $inFile > $outFile");

	# Remove escape chars from out location name
	$outFile =~ s/\\//g;

	# Open input handle to tokenized file, read all contents into @tweets
	open(my $inFileHan,'<:encoding(utf8)',$outFile) or die "Couldn't open input file $outFile";
	my @tweets = <$inFileHan>;
	chomp @tweets;
	close($inFileHan) or die "Couldn't close input file $outFile";

	# Apply extra processing to each tokenized tweet
	open(my $outFileHan,'>:encoding(utf8)',$outFile) or die "Couldn't open output file $outFile";
	foreach(@tweets)
	{
#		if ($_ =~ /^\{.?\{.?ID/) { next; }	# Skip any remaining metadata lines
		$_ =~ s/^(.+)\t.+$/$1/;			# Remove extra tokenizer syntax
		$_ =~ s/([A-Za-z]|[^\p{Z}\p{N}])((?:¿|¡|$oddSymbols)+)/$1 $2/g;	# Get correct spacing around special chars
		$_ =~ s/((?:¿|¡|$oddSymbols)+)([A-Za-z]|[^\p{Z}\p{N}])/$1 $2/g; # Get correct spacing around special chars
		$_ =~ s/$oddSymbols/{symbol}/g;		# Replace symbols with {symbol}
		$_ =~ s/\x{fe0f}//g;			# Remove this one weird spacing-type unicode character

		say $outFileHan splitContractions($_);
	}
	close($outFileHan) or die "Couldn't close output file $outFile";
}

# onelineFile()
# Input: Input file handle
# Output: Reference to array of tweets
# Description: Assemble each multi-line tweet in the input file handle into a one-line tweet
#		by replacing newlines with a single space. Append
#		the <ENDOFTWEET> markers or the {{ID}} metadata as a line before the tweet text.
sub onelineFile
{
	my $inFileHan = shift;
	my @tweets;

	while(1)
	{	
		if (eof($inFileHan)) { last; }
		# Read in one tweet: read lines and push them on the array until hitting <ENDOFTWEET> line
		my $meta = <$inFileHan>;
		chomp $meta;	
		my @tweetPieces;
		while (!eof($inFileHan))
		{
			my $line = <$inFileHan>;
			chomp $line;
			if ($line eq '<ENDOFTWEET>') 	{ last; }
			else				{ push(@tweetPieces,$line); }
		}
		my $tweet = join(" ",@tweetPieces);
		$tweet =~ s/\n/ /g;

		if ($tweet eq '') { next; }	# Ignore empty tweets

		push(@tweets,"$meta\n$tweet");	# Print one-line tweet to output
	}

	return \@tweets;
}

# detokenize()
# Input: reference to array of tokens
# Output: string of tweet text
# Description: Put the provided array of tokens back together into a one-line tweet.
# 		This uses the tokenization format above (related primarily to contraction
#		handling, where n't is in a separate token and can't becomes can n't).
#		Spaces are removed before a number of punctuation marks, and certain paired
#		punctuation marks have trailing and leading spaces removed only if the partner is present.
sub detokenize
{
	my $tokenRef = shift;
	my @tokens = @{$tokenRef};

	# Adjust and assemble tweet's text
	my $text = join(' ',@tokens);
	$text = joinContractions($text);
	$text =~ s/([A-Za-z\d]) ([.?!'‘’,…]+)/$1$2/g;
	my %endpuncs = ('\''=>'\'','"'=>'"','«'=>'»','“'=>'”','‘'=>'’','{'=>'}','\('=>'\)','\['=>'\]','\*'=>'\*','&'=>'&');
	foreach(keys(%endpuncs))
	{ 
		my ($p1,$p2) = ($_,$endpuncs{$_});
		$text =~ s/($p1)+ ((?:[A-Za-z,-_\d.?! \p{L}\p{M}])+) ($p2)+/$1$2$3/g; 
	}

	return $text;
}



1;
