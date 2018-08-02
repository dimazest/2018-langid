
Data Release


http://emnlp2014.org/workshops/CodeSwitch/call.html


The script to crawl Twitter data is this one: twitter. You will need to have Beautiful Soup installed for this python script to work.

A second method to crawl Twitter data using the Twitter API is also available: Twitter via API. You will need to have the Launchy gem for Ruby installed, which can be done via 'gem install launchy' in the command line. You will also need a Twitter account to authenticate with the application.

For the Arabic and English-Spanish tweets, there are packages available that retrieves, tokenizes and synchronizes the tags for the training data: Arabic Tweets Token Assigner and English-Spanish Tweets Token Assigner. Instructions on how to use the packages are included.

The Spanish-English tweets were tokenized using the CMU ARK Twitter Part-of-Speech Tagger v0.3 (ignoring the parts of speech) with some later adjustments. These adjustments were made using the TweetTokenizer Perl module. The ARK Twitter tokenizer takes an entire tweet on one line, so initially run the onelineFile() subroutine on your file. Feed the output into the tokenizeFile() subroutine, which runs the tokenizer and makes adjustments. You will need to change the tokenizer location global variable in the module to your file location.

    Nepalese-English Trial data (20 tweets)
    Spanish-English Trial data (20 tweets)
    Mandarin-English Trial data (20 tweets)
    Modern Standard Arabic-Arabic dialects (20 tweets)

    Spanish-English Training data (11,400 tweets)
    Nepali-English Training data (9993 tweets, updated 16th July, 2014)
    Modern Standard Arabic-Arabic dialects Training data (5,838 tweets)
    Mandarin-English Training data (1,000 tweets)

The task will be evaluated using the script and calculation library given here. The script is run using the produced offset file and the test offset file and produces a variety of evaluation metrics at the tweet and token level. See the documentation inside of the script for more details. Keep the directory structure within the Evaluation file the same for the evaluateOffsets.pl script to work properly.

The training and test data have been run through two benchmark systems to give a better idea of performance goals. The systems are a simple lexical ID approach using the training data and an off-the-shelf system, LangID, using mass amounts of monolingual tweet data.
(Ben King and Steven Abney. Labeling the languages of words in mixed-language documnts. In Proceedings of the North American Association for Computational Linguistics 2013, Atlanta.)
The results for these benchmark systems (obtained using the evaluation script) are provided below.

    Spanish-English Results
    Nepali-English Results

The shared task has now begun. The test data may be found below. Remember that the task window closes on July 27th.

    Spanish-English Test data (3,060 tweets)
    Nepali-English Test data (3,018 tweets )
    Modern Standard Arabic-Arabic dialects Test data (2,363 tweets)
    Mandarin-English Test data (316 tweets)
    Modern Standard Arabic-Arabic Dialects Second Test data (1,777 tweets)

For Spanish-English, Nepali-English, and Modern Standard Arabic-Arabic dialects, "suprise genre" datasets have been provided. The "suprise genre" datasets are comprised of data from Facebook, blogs, and Arabic commentaries. Because the data comes from different social media sources, the ID format varies from file to file. Unlike Twitter, you will not be given a way to crawl the data for the raw posts. Instead, each file contains the token referenced by the offsets.

    Spanish-English "Suprise Genre" Test data (1,103 tokens)
    Nepali-English "Suprise Genre" Test data (1,087 tokens)
    Modern Standard Arabic-Arabic dialects "Suprise Genre" Test data (12,018 tokens)

Additional "surprise genre" data has been added for Spanish-English and Nepali-English as of 8/10/14.
**UPDATED 8/10/14**

    Spanish-English "Suprise Genre" Extra data
    Nepali-English "Suprise Genre" Extra data

To submit your results, please add the label, separated by a tab, at the end of each row of the provided test data file and submit it to coral.at.uab@gmail.com. Please do not change the order of the rows and do not add extra newlines.

