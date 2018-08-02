Introduction:
--------------
Due to copyrights restrictions, we can not provide the text of the tweets, hence the annotation files contain the following 5 columns:
TweetID	UserID	Character-start	Character-end	Label

You need to retrieve the text of the tweets, tokenize it and synchronize it to the annotation files.
To help in this process, we provide this package which is tailored to the English-Spanish tweets.

Note that for large files this will take a long time to complete (possibly days). Twitter’s API will only allow you to crawl so many tweets before you have to take a fifteen minute break. As inconvenient as this is, it is the best way to crawl Twitter, so please be patient.

For questions and problems, send all inquiries to brianh15@uab.edu

Contents:
----------
This package contains the following files/directories:
-README.txt  —> You are here :)
-runEsScripts.sh  —> Shell script. This is all that you need to run.
-Scripts  —> This is a directory containing all the scripts run by the shell script. Feel free to have a look at these, but it is not necessary.
-Libraries  —> This is a directory containing library files used by the scripts. 
-samplein.tsv  —> A sample input file.
-sampleout.tsv  —> The expected output from running the shell script on the sample input file. 
-Files  —> An initially empty directory that will be filled with files created and used by the scripts. 
-access_token.txt  —> An initially blank file that will contain the twitter access token.

Prerequisites:
-------------- 
	Launchy gem for Ruby (install using 'gem install launchy’)
	Twitter account
		The Twitter API requires an account for authentication before it will crawl the tweets.
	Modify the location of the package at line 80 of Libraries/TweetTokenizer.pm
		The pipeline will not work correctly unless you do this

How to use:
------------
From the Unix shell run the following:
sh runEsScripts.sh <Spanish-English-training-file>

When you first run this script, Twitter will open up on your browser and ask for you to authenticate your app before you can crawl the tweets. All you need to do is have a Twitter account. It will then give you a number to enter in command line; enter the number and the script will handle the rest. 

In order to test your working environment setup, you can run the following test:
sh runEsScripts.sh sample.tsv

This will produce the file final.tsv. Compare this with sampleout.tsv to see if everything ran correctly. 
