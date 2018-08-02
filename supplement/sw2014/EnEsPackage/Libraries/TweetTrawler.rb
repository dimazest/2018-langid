require "rubygems"
require_relative "oauth-ruby-master/lib/oauth"
require "json"
require "launchy"

# Elizabeth Blair
# Last Edited: 3/14/14
# 3/7/14:	Created
# 3/10/14:	Fixed perl translation bug in wait, class var bug in trawl
# 3/12/14:	Added error handling, changed some output, finished genAccessToken
# 3/14/14:	Fixes to response headers in errors and to the exit check code
# 3/31/14;	Add brute-force error handling for SSL errors

# This class sets up and accesses the Twitter API.

class TweetTrawler
	# initialize(path,api_key,api_secret,access_token,access_secret)
	# Inputs: path for the API call to execute, application API key and secret, user access token and secret
	# Outputs: TweetTrawler object
	# Description: Generate the TweetTrawler which holds the path and the Oauth consumer key and access
	#		token generated via the provided data.
	def initialize(path,api_key,api_secret,access_token,access_secret)
		@path = path
		@consumer_key = OAuth::Consumer.new(api_key, api_secret)
		@access_token = OAuth::Token.new(access_token, access_secret)
	end

	# genAccessToken(api_key,api_secret,site)
	# Inputs: application API key and secret and the base website to authorize with
	# Outputs: access token, access secret
	# Description: Generate Oauth access data for the user for the application on the website. This
	#		is done by opening a web browser to the site, having the user authenticate with their account
	#		to get a pin, entering the pin in the terminal, and requesting the token with the pin.
	def self.genAccessToken(api_key,api_secret,site)
		consumer_key = OAuth::Consumer.new(api_key, api_secret, {:site=>site})

		request_token = consumer_key.get_request_token
		Launchy.open(request_token.authorize_url)

		puts "Please enter the pin given after authenticating with your account."
		STDOUT.flush
		pin = $stdin.gets.chomp

		access_data = request_token.get_access_token(:oauth_verifier => pin)
		access_token = access_data.token
		access_secret = access_data.secret
		return access_token,access_secret
	end

	# Error class with the same behavior as the standard error, but with additional data stored. It is
	# intended only to occur on Twitter API errors and stores the error's code, subcode, reason, and full
	# API call response (for headers).
	class TwitterAPIError < StandardError
		attr_reader :code, :errcode, :reason, :response
		def initialize(code,errcode,reason,response)
			@code = code
			@errcode = errcode
			@reason = reason
			@response = response
		end
	end

	# trawl(criteria)
	# Inputs: URI site criteria
	# Outputs: JSON-parsed call results, # of that type of call remaining, time when the rate limit resets
	# Description: Build and authorize the URI for the Twitter API call with the given criteria, set
	#		HTTP settings properly, send the HTTP request, and return the response along with the
	#		rate limit information for the call. If the response code was something other than 200,
	#		then there was an error that needs a response. The error information is printed and
	#		the error is handled. In most cases another exception is raised, but in a few the response
	#		data is replaced with descriptive text and returned. See below for details.
	def trawl(criteria)
		begin
			address = URI("https://api.twitter.com#{@path}?#{criteria}")
			http = Net::HTTP.new address.host, address.port
			http.use_ssl = true
			http.verify_mode = OpenSSL::SSL::VERIFY_PEER
			request = Net::HTTP::Get.new address.request_uri

	
			request.oauth! http, @consumer_key, @access_token
			http.start
			response = http.request request

			code = response.code
			if code == '200' then
				results = JSON.parse(response.body)
				return results, response["x-rate-limit-remaining"], response["x-rate-limit-reset"]
			else
				body = JSON.parse(response.body)
				if body.has_key?("errors") then 
					raise TwitterAPIError.new(code,body["errors"][0]["code"],body["errors"][0]["message"],response)
				else 
					raise TwitterAPIError.new(code,nil,body["error"],response)
				end
			end
		rescue EOFError => e
			puts "SSL EOF Error"
			sleep(3)
			retry
		rescue OpenSSL::SSL::SSLError => e
			puts "SSL Error"
			sleep(3)
			retry
		rescue TwitterAPIError => e
			puts "Error code #{e.code}-#{e.errcode}: #{e.reason}"
			case e.code.to_i
			# 89: invalid access token?
			# 92: need ssl
			when 400..401	# 135: Oauth timestamp issue, 215: bad data
				if e.errcode.to_i == 135 then raise "Oauth timestamp outside of acceptable bounds" end
				return "<Not authorized>",response["x-rate-limit-remaining"], response["x-rate-limit-reset"]
			when 403
				# 64: acct suspended, 161: following too many, 179: can't see status, 185: posted too amny tweets
				case e.errcode.to_i
					when 64
						raise "Account has been suspended"
					when 161
						raise "Following too many users"
					when 179
						return "<Tweet not available>",response["x-rate-limit-remaining"], response["x-rate-limit-reset"]
					when 185
						raise "Posted too many tweets recently"
					else 	raise "Access forbidden"
				end
			when 404
				# 34: page doesn't exist
				return "<Tweet not available>",response["x-rate-limit-remaining"], response["x-rate-limit-reset"]
			when 406
				raise "Invalid search request format"
			when 410
				raise "This API resource is gone."
			when 422
				raise "Banner image can't be processed"
			when 429
				# 88: rate limit exceeded
				return nil, response["x-rate-limit-remaining"], response["x-rate-limit-reset"] 
			when 500
				raise "Internal Twitter server error"
			when 502
				#raise "Twitter is down"
				wait(15)
				retry
			when 503
				#raise "Twitter is overloaded"
				wait(15)
				retry
			when 504
				#raise "Twitter timeout"
				wait(15)
				retry
			else
				raise "Unrecoverable error"
			end	
		end	
	end

	# quit?
	# Inputs: none
	# Outputs: boolean
	# Description: If the next ten characters from STDIN is 'exit', return true. Also return
	#		true if the input stream is closed. Return false if the device is being
	#		slow or if nothing was read.
	def quit?
		begin
			while c = STDIN.read_nonblock(10).chomp
				return true if c == 'exit'
			end
			false
		rescue Errno::EINTR	# Slow device?
			false
		rescue Errno::EAGAIN	# Nothing read
			false
		rescue EOFError		# User quit the input stream
			true
		end
	end

	# wait(time)
	# Inputs: time to wait (in seconds)
	# Outputs: none
	# Description: Print that the program waits (time in minutes) and wait for the given time.
	#		Every 15 seconds, check if the quit criteria is met. If so, terminate.
	# TODO: Don't just terminate. Return so the calling thing can close its files and stuff.
	def wait(time)
		puts "Waiting... (come back in around "+(time/60).to_s+" minutes)"
		waited = 0;
		while(waited < time) do
			waited += sleep(15)

			if quit? then
				puts "Exiting the trawl..."
				exit
			end
		end
	end
end

nil
