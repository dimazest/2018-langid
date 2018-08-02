require "rubygems"
require_relative "../Libraries/TweetTrawler"
require "date"

# Elizabeth Blair
# Last Edited: 3/14/14
# 3/10/14:	Created
# 3/12/14:	Added some error handling, fixed timer, added access info generation
# 3/14/14:	Added code for search and user modes, moved parsing to individual subs
# 3/31/14:	Fixed transition bug in getTweet

# This script contains a set of methods to gather Twitter data from various sections of the
# Twitter API. The currently availble modes are 'tweet', 'user', and 'search'. Each mode has
# different required arguments and output style, but tweets are always stored in the format
# {{ID=###}}{{USER=###}}\n(tweet text)\n<ENDOFTWEET>. During execution, if the connection times
# out or API rate limits are hit the script will wait. To leave, type exit and hit enter; within
# 15 seconds the script will terminate.
# - Tweet: Given tweet IDs (one per line), pull those tweets using the statuses/show call. If a 
#	tweet is not available, the tweet ID will still be given but the user will not and the text area
#	will be filled with <Tweet not available>. Output is stored in one given file, with each
#	tweet on the line following the last.
# - User: Given user IDs, pull the users' timelines, up to (depth*200) tweets. This call
#	pulls a maximum of ~3000 tweets, minus retweets and those containing URLs. Users
#	who set their profile to private will have one line in their file: <Not authorized>.
#	The ID file should have one user ID per line, and anything following a tab is removed.
#	Each user's tweets will be stored in a .txt file named after them in the output directory.
# - Search: Given files containing search queries in certain categories, run the terms
#	infinitely through the search call, grabbing up to 200 recent tweets per search sans those
#	with explicit retweets or URLs. The search also filters for the given language and
#	location, which must be set up in the geocodes variable. The query files should have the
#	category name on the first line, and each following line should be one query. Anything
#	following a tab will be removed. Output is stored in a file named 'category_term # in file'.txt
#	inside of a directory named with the timestamp 'year-month-day_hour-minute' when the search
#	was done which is created in the output directory.

# USAGE:
# ruby tweetPull.rb tweet <out file> <ID file> 
# ruby tweetPull.rb user <out dir> <user file> <user depth multiple>
# ruby tweetPull.rb search <out dir> <language> <location> <query file> [more query files...]

# Application API key and secret for my CoRAL account application 
# [Probably shouldn't be published without a password or something]
apikey="NPFARLw6YOl2d1DxTgu5lfbMG"
apisecret="i36ED68Hmyx9pIJy7mUxf7czBNDyQ2VcNvU4mctYZNQtvUPnYK"

# Geocodes for areas covering certain state locations (ATM, Texas and California)
@geocodes = {
	'TX' => "31.37,-98.899,600km",			# 600km radius from center of Texas
	'CA' => "35.936802,-121.350174,900km"		# 900km radius from around the mid-left edge of CA
}

# Error/Exception class that should only be used if a trawl call needs to be repeated
# because it was skipped. It behaves no differently than a normal exception.
class NilTextError < StandardError
end

# getTimeline(user,maxID,trawler)
# Inputs: user ID, tweet ID to start at, TweetTrawler
# Outputs: string of formatted tweets, lowest tweet ID the trawler reached, 
#		# queries remaining, time to rate limit reset
# Description: Use the trawler to gather the most recent 200 tweets from the user's timeline, 
#	starting from the given maximium tweet ID. Filter out retweets and tweets containing URLs.
#	Return all of the tweets in one string, along with the earliest tweet's ID (or nil if no tweets
#	were processed), the number of timeline queries left, and the time when the rate limit will reset.
#	9^35 is used as a very large number to compare tweet IDs to when finding the lowest one. No existing
#	tweet should have an ID near this, nor should one for a very long time.
def getTimeline(user,maxID,trawler)
	criteria = nil
	if maxID.nil? then
		criteria = URI.encode_www_form(
			"user_id" => user,
			"count" => 200,
			"include_rts" => false)
	else
		criteria = URI.encode_www_form(
			"user_id" => user,
			"count" => 200,
			"max_id" => maxID,
			"include_rts" => false)
	end
	puts "Running user #{user} on max ID #{maxID}"

	results,limitLeft,timeReset = trawler.trawl(criteria)	
	newMax = nil
	tweets = ""
	if results == '<Not authorized>' then
		tweets = results
	elsif !results.nil? then
		lowestid = 9 ** 35
		data.each do |tweet|
			text = tweet["text"]
			if tweet["id"] < lowestid then lowestid = tweet["id"] end
			if text =~ /^RT(.{1,5})@|http:|https:|pic\.twitter/
				# Discard the tweet
			else
				tweets = "#{tweets}\{\{ID=#{tweet["id"]}\}\}\{\{USER=#{tweet["user"]["id"]}\}\}\n#{tweet["text"]}\n<ENDOFTWEET>\n" 
			end
		end
		if lowestid == 9 ** 35 then lowestid = nil end
	end

	return tweets,newMax,limitLeft,timeReset
end

# getSearchTweets(query,lang,loc,trawler)
# Inputs: search query (text), language, location (must be a key in geocodes), TweetTrawler
# Outputs: string of formatted tweets, # queries remaining, time to rate limit reset
# Description: Use the trawler to gather up to 200 of the most recent tweets containing the
#		given query, flagged by Twitter as being in the given language, and posted from
#		within the given location. Discard explicit retweets and those containing URLs.
#		Return a string of all the formatted tweets, along with the number of remaining
#		queries and the time when the rate limit will reset.
def getSearchTweets(query,lang,loc,trawler)
	criteria = URI.encode_www_form(
		"q" => "#{query} -http -https -pic.twitter",
		"count" => 200,	
		"geocode" => @geocodes[loc],
		"result_type" => "recent",
		"lang" => lang)

	results,limitLeft,timeReset = trawler.trawl(criteria)
	tweets = ''
	if !results.nil? then 
		results["statuses"].each do |tweet|
			text = tweet["text"]
			if text =~ /^RT(.{1,5})@|http:|https:|pic\.twitter/
				# Discard the tweet
			else
				tweets = "#{tweets}\{\{ID=#{tweet["id"]}\}\}\{\{USER=#{tweet["user"]["id"]}\}\}\n#{tweet["text"]}\n<ENDOFTWEET>\n" 
			end
		end
	else tweets = nil
	end

	return tweets,limitLeft,timeReset
end

# getTweet(id,trawler)
# Inputs: tweet ID, TweetTrawler
# Outputs: formatted tweet (string), # queries remaining, time to rate limit reset
# Description: Use the trawler to get the given tweet and return the text in the script's
#		format. If the tweet isn't accessible, excludes the user and replaces the
#		text field with <Tweet not available>. Also returns the number of remaining
#		queries and the time when the rate limit will reset.
def getTweet(id,trawler)
	criteria = URI.encode_www_form("id" => id)
	#puts "Running tweet #{id}"

	results,limitLeft,timeReset = trawler.trawl(criteria)
	if (results == '<Tweet not available>' or results == '<Not authorized>') then results = "\{\{ID=#{id}\}\}\n<Tweet not available>\n<ENDOFTWEET>\n"
	elsif (!results.nil?) then results = "\{\{ID=#{results["id"]}\}\}\{\{USER=#{results["user"]["id"]}\}\}\n#{results["text"]}\n<ENDOFTWEET>\n" end
	return results,limitLeft,timeReset
end

# getAccessData(file)
# Inputs: access data storage file
# Outputs: array of access data
# Description: If the access file exists, pull the access data from it. The first line of
#		the file is the access token and the second is the access secret. The array's
#		elements are in the same order. If the file does not exist, use TweetTrawler to
#		generate the access data for the hardcoded application. (This will open a web
#		browser and requires a Twitter account.) Write the access data to the file before
#		returning it.
def getAccessData(data_file)
	accessData = Array.new
	if !File.exists?(data_file) then
		puts "Generating your access token..."
		accessData[0],accessData[1] = TweetTrawler.genAccessToken("NPFARLw6YOl2d1DxTgu5lfbMG","i36ED68Hmyx9pIJy7mUxf7czBNDyQ2VcNvU4mctYZNQtvUPnYK","https://api.twitter.com")
		# also write out to file
		accessOut = File.open(data_file,"w")
		accessOut << "#{accessData[0]}\n#{accessData[1]}"
		accessOut.close
	else
		File.readlines(data_file).each do |line|
			line.chomp!
			accessData.push(line)
		end
	end
	return accessData
end

# MAIN CODE
mode = ARGV.shift
out = ARGV.shift

# Generate or pull authentication data for the user from hard-coded access_token.txt
accessData = getAccessData('access_token.txt')

limitLeft = nil
timeReset = nil

case mode
	when 'tweet'
		inFile = ARGV.shift
		# Make the single-tweet trawler
		path = "/1.1/statuses/show.json"
		trawler = TweetTrawler.new(path,apikey,apisecret,accessData[0],accessData[1])

		# Pull tweet for each ID in the input file, print formatted tweet to out file
		outFileHan = File.open(out,"w")
        puts "Getting tweets (this may take a while)"
		File.readlines(inFile).each do |id|
			id.chomp!	
			begin
				# Wait if needed
				if !limitLeft.nil? and limitLeft.to_i < 1 then
					waitTime = (timeReset.to_i-Time.now.to_i)+30;	# Add 30 seconds to wait time to be sure there's a new query window
					trawler.wait(waitTime)
				end

				results,limitLeft,timeReset = getTweet(id,trawler)
				if (!results.nil?) then outFileHan << results
				else raise NilTextError.new()
				end
			rescue NilTextError => e
				retry
			end
		end
		outFileHan.close
	when 'user'
		inFile = ARGV.shift
		# Make the user trawler
		path = "/1.1/statuses/user_timeline.json"
		trawler = TweetTrawler.new(path,apikey,apisecret,accessData[0],accessData[1])

		depth = ARGV.shift.to_i
		File.readlines(inFile).each do |line|
			line.chomp!
			id, *rest = line.split(/\t/)
			maxID = nil
			allTweets = ""
			depth.times do
				begin
					# Wait if needed
					if !limitLeft.nil? and limitLeft.to_i < 1 then
						waitTime = (timeReset.to_i-Time.now.to_i)+30;	# Add 30 seconds to wait time to be sure there's a new query window
						trawler.wait(waitTime)
					end

					# Get tweets from the user at current ID depth
					tweets,newID,limitLeft,timeReset = getTimeline(id,maxID,trawler)
					if tweets.nil? then raise NilTextError.new() end
					unless newID.nil? then newID = newID.to_i - 1 end

					allTweets = "#{allTweets}#{tweets}"

					if newID.nil? or newID == maxID then break end
					maxID = newID
				rescue NilTextError => e
					retry
				end
			end

			# Only make a file for the user if they had non-discarded tweets (or weren't accessible)
			if allTweets != "" then
				outFileHan = File.open("#{out}/#{id}.txt","w")
				outFileHan << allTweets
				outFileHan.close
			end
		end
	when 'search'
		lang = ARGV.shift
		location = ARGV.shift

		path = "/1.1/search/tweets.json"
		trawler = TweetTrawler.new(path,apikey,apisecret,accessData[0],accessData[1])

		termCats = Hash.new
		ARGV.each do |file|
			key = nil
			File.readlines(file).each_with_index do |line,ind|
				line = line.chomp
				if ind == 0 then 
					key = line
					termCats[key] = Array.new
				else
					term, *rest = line.split(/\t/)
					termCats[key].push(term)
				end
			end
		end

		# Infinitely looping search - exit during the wait periods
		loop do
			termCats.each_key do |cat|
				puts "Running terms of category #{cat}..."
				termCats[cat].each_with_index do |query,ind|
					begin
						# Wait if needed
						if !limitLeft.nil? and limitLeft.to_i < 1 then
							waitTime = (timeReset.to_i-Time.now.to_i)+30;	# Add 30 seconds to wait time to be sure there's a new query window
							trawler.wait(waitTime)
						end

						# Get tweets from the user at current ID depth
						time = Time.new
						tweets,limitLeft,timeReset = getSearchTweets(query,lang,location,trawler)
						if tweets.nil? then raise NilTextError.new() end

						# Output the data to the correct location
						timestamp = "#{time.year}-#{time.month}-#{time.day}_#{time.hour}-#{time.min}"
						Dir.mkdir("#{out}/#{timestamp}") unless File.exists?("#{out}/#{timestamp}")
						outFileHan = File.open("#{out}/#{timestamp}/#{cat}_#{ind}.txt","w")
						outFileHan << tweets
						outFileHan.close
					rescue NilTextError => e
						retry
					end
				end
			end
		end
	else abort "Unsupported mode #{mode} - use tweet, user, or search"
end

# Set up the limit data properly and print out remaining limit information
if limitLeft.nil? then limitLeft = 'unknown' end
if timeReset.nil? then timeReset = 'unknown'
else timeReset = Time.at(timeReset.to_i).to_datetime
end

puts "Remaining queries: #{limitLeft}"
puts "Time until reset: #{timeReset}"

nil
