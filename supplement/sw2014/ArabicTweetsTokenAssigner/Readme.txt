Introduction:
--------------
Due to copyrights restrictions, we can not provide the text of the tweets, hence the annotation files contain the following 5 columns:
TweetID	UserID	Character-start	Character-end	Label

You need to retrieve the text of the tweets, tokenize it and synchronize it to the annotation files.
To help in this process, we provide this package which is tailored to the Arabic tweets.

Contents:
----------
This package contains the following files:
- Readme.txt   --> This file
- collect-tweets-gwu-modified.py  --> modified version of the collect-tweets.py script 
- Tokenizer.jar  --> the tokenizer used to tokenize the Arabic tweets.
- AssignTokenz.sh  --> the pipeline shell script
- sample.tsv --> sample input file
- sample.out --> the expected output if you run the pipeline on the "sample.tsv" 

How to use:
------------
from the Linux shell run the following:
sh AssignTokenz.sh <Arabic-tweets-annotation-file> 

to test your working environment setup, you can run the following test:
sh AssignTokenz.sh sample.tsv

When the script ends, you can compare the final output file "sample.tsv.TaggedTokens" with the file correct output "sample.out" to assure everything is working fine.

Prerequisites:
-------------- 
	python 2.7
	beautifulsoup4 
		To install beautifulsoup4 refer to  https://pypi.python.org/pypi/beautifulsoup4 or 
		if you have pip installed then use 'pip install beautifulsoup4'
	Java Runtime version 1.7+
