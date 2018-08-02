python collect-tweets-gwu-modified.py -i $1 -o $1.gwu-format.tweets
java -jar Tokenizer.jar $1.gwu-format.tweets $1.gwu-format.tweets.tokenized
cut -f5 $1 | paste $1.gwu-format.tweets.tokenized - > $1.TaggedTokens
