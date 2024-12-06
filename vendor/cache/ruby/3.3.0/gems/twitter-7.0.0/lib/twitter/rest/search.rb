require 'twitter/rest/request'
require 'twitter/search_results'

module Twitter
  module REST
    module Search
      MAX_TWEETS_PER_REQUEST = 100

      # Returns tweets that match a specified query.
      #
      # @see https://dev.twitter.com/rest/reference/get/search/tweets
      # @see https://dev.twitter.com/rest/public/search
      # @note Please note that Twitter's search service and, by extension, the Search API is not meant to be an exhaustive source of Tweets. Not all Tweets will be indexed or made available via the search interface.
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @param query [String] A search term.
      # @param options [Hash] A customizable set of options.
      # @option options [String] :geocode Returns tweets by users located within a given radius of the given latitude/longitude. The location is preferentially taking from the Geotagging API, but will fall back to their Twitter profile. The parameter value is specified by "latitude,longitude,radius", where radius units must be specified as either "mi" (miles) or "km" (kilometers). Note that you cannot use the near operator via the API to geocode arbitrary locations; however you can use this geocode parameter to search near geocodes directly.
      # @option options [String] :lang Restricts tweets to the given language, given by an ISO 639-1 code.
      # @option options [String] :locale Specify the language of the query you are sending (only ja is currently effective). This is intended for language-specific clients and the default should work in the majority of cases.
      # @option options [String] :result_type Specifies what type of search results you would prefer to receive. Options are "mixed", "recent", and "popular". The current default is "mixed."
      # @option options [Integer] :count The number of tweets to return per page, up to a maximum of 100.
      # @option options [String] :until Optional. Returns tweets generated before the given date. Date should be formatted as YYYY-MM-DD.
      # @option options [Integer] :since_id Returns results with an ID greater than (that is, more recent than) the specified ID. There are limits to the number of Tweets which can be accessed through the API. If the limit of Tweets has occured since the since_id, the since_id will be forced to the oldest ID available.
      # @option options [Integer] :max_id Returns results with an ID less than (that is, older than) or equal to the specified ID.
      # @option options [Boolean] :include_entities The entities node will be disincluded when set to false.
      # @option options [String] :tweet_mode The entities node will truncate or not tweet text. Options are "compat" and "extended". The current default is "compat" (truncate).
      # @return [Twitter::SearchResults] Return tweets that match a specified query with search metadata
      def search(query, options = {})
        options = options.dup
        options[:count] ||= MAX_TWEETS_PER_REQUEST
        request = Twitter::REST::Request.new(self, :get, '/1.1/search/tweets.json', options.merge(q: query))
        Twitter::SearchResults.new(request)
      end
    end
  end
end
