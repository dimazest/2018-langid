perl Scripts/grabIDsFromOffsets.pl $1 Files/IDs.txt
ruby Scripts/tweetPull.rb tweet Files/raw.txt Files/IDs.txt
perl Scripts/processTweets.pl Files/raw.txt Files/oneline.txt Files/tokenized.txt
perl Scripts/generateOffsets.pl Files/raw.txt Files/tokenized.txt Files/offsets.tsv
perl Scripts/assembleDataFromOffsets.pl reg Files/raw.txt Files/offsets.tsv Files/tokens.tsv
perl Scripts/getTokensWithLabels.pl $1 Files/tokens.tsv final.tsv