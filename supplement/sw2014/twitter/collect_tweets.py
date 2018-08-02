# -*- coding: utf-8 -*-

import urllib2
from bs4 import BeautifulSoup #pip install beautifulsoup4
import optparse
import codecs


TWITTER_URL = "https://twitter.com/"


def get_tweet(user_id, tweet_id):
    """fetch the tweet from given user_id and tweet_id
        returns tweet text  if found, otherwise returns Not Found
    """
    url = TWITTER_URL + user_id + "/status/" + tweet_id
    tweet = 'Not Found'
    try:
        response = urllib2.urlopen(url)
        html = response.read()
        soup = BeautifulSoup(html)
        #extrat the paragraph that contains the tweet
        tweet_paragrapgh = soup.find("div", 'js-original-tweet',
                                     {"data-user-id": user_id, "data-tweet-id": tweet_id}).findNext('p',
                                                                                                    'js-tweet-text')
        #strip off the html tag and get the tweet text
        tweet = tweet_paragrapgh.text
    except urllib2.HTTPError as e:
        print
        print "HTTP ERROR response code ", e.code, " for user id: ", user_id, " tweet id: ", tweet_id
        return tweet
    except urllib2.URLError as e:
        print
        print'Error reaching to server for ', "user id: ", user_id, " tweet id: ", tweet_id
        print 'Reason: ', e.reason
        return tweet
    return tweet


if __name__ == "__main__":
    #configuraion for parsing command line arguments
    parser = optparse.OptionParser("usage: %prog [options] ")
    parser.add_option("-i", "--input", dest="input_file", type="string", help="specify input filename")
    parser.add_option("-o", "--output", dest="output_file", type="string", help="specify output filename")
    (opts, args) = parser.parse_args()
    if opts.input_file is None or opts.output_file is None:
        parser.print_help()
        parser.error(" ")
    else:
        input_file = opts.input_file
        output_file = opts.output_file

        print "Fetching tweets "
        #open input file to read the tweet id and user id
        with open(input_file) as f:
            # fetch tweet from user id and tweet id and write it to output file
                out = codecs.open(output_file, 'w', 'utf-8') # for handling unicodes
                old_tweet_id, old_user_id = '', ''
                for line in f:
                    if line.strip(): #if empty line skip
                        try:
                            tweet_id, user_id, start, end, label = line.split('\t')
                            if not (old_tweet_id == tweet_id and old_user_id == user_id):
                                tweet = get_tweet(user_id, tweet_id)
                                out.write(tweet_id + '\t' + user_id + '\t' + tweet + "\n")
                                out.flush()
                                print "+",
                            old_tweet_id, old_user_id = tweet_id, user_id
                        except ValueError as e:
                            print "Value Error for: "+line+"  :"+e.message
                out.close()
        print
        print "Done"


