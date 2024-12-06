require 'twitter/rest/request'
require 'twitter/premium_search_results'

module Twitter
  module REST
    module PremiumSearch
      MAX_TWEETS_PER_REQUEST = 100

      # Returns tweets from the 30-Day API that match a specified query.
      #
      # @see https://developer.twitter.com/en/docs/tweets/search/overview/premium
      # @see https://developer.twitter.com/en/docs/tweets/search/api-reference/premium-search.html#DataEndpoint
      # @rate_limited Yes
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @param query [String] A search term.
      # @param options [Hash] A customizable set of options.
      # @option options [String] :tag Tags can be used to segregate rules and their matching data into different logical groups.
      # @option options [Integer] :maxResults The maximum number of search results to be returned by a request. A number between 10 and the system limit (currently 500, 100 for Sandbox environments). By default, a request response will return 100 results
      # @option options [String] :fromDate The oldest UTC timestamp (from most recent 30 days) from which the Tweets will be provided. Date should be formatted as yyyymmddhhmm.
      # @option options [String] :toDate The latest, most recent UTC timestamp to which the activities will be provided. Date should be formatted as yyyymmddhhmm.
      # @option request_config [String] :product Indicates the search endpoint you are making requests to, either 30day or fullarchive. Default 30day
      # @return [Twitter::PremiumSearchResults] Return tweets that match a specified query with search metadata
      def premium_search(query, options = {}, request_config = {})
        options = options.clone
        options[:maxResults] ||= MAX_TWEETS_PER_REQUEST
        request_config[:request_method] = :json_post if request_config[:request_method].nil? || request_config[:request_method] == :post
        request_config[:product] ||= '30day'
        path = "/1.1/tweets/search/#{request_config[:product]}/#{dev_environment}.json"
        request = Twitter::REST::Request.new(self, request_config[:request_method], path, options.merge(query: query))
        Twitter::PremiumSearchResults.new(request, request_config)
      end
    end
  end
end
