require 'cgi'
require 'twitter/enumerable'
require 'twitter/rest/request'
require 'twitter/utils'
require 'uri'

module Twitter
  class PremiumSearchResults
    include Twitter::Enumerable
    include Twitter::Utils
    # @return [Hash]
    attr_reader :attrs
    alias to_h attrs
    alias to_hash to_h

    # Initializes a new SearchResults object
    #
    # @param request [Twitter::REST::Request]
    # @return [Twitter::PremiumSearchResults]
    def initialize(request, request_config = {})
      @client = request.client
      @request_method = request.verb
      @path = request.path
      @options = request.options
      @request_config = request_config
      @collection = []
      self.attrs = request.perform
    end

  private

    # @return [Boolean]
    def last?
      !next_page?
    end

    # @return [Boolean]
    def next_page?
      !!@attrs[:next]
    end

    # Returns a Hash of query parameters for the next result in the search
    #
    # @note Returned Hash can be merged into the previous search options list to easily access the next page.
    # @return [Hash] The parameters needed to fetch the next page.
    def next_page
      {next: @attrs[:next]} if next_page?
    end

    # @return [Hash]
    def fetch_next_page
      request = @client.premium_search(@options[:query], (@options.reject { |k| k == :query } || {}).merge(next_page), @request_config)

      self.attrs = request.attrs
    end

    # @param attrs [Hash]
    # @return [Hash]
    def attrs=(attrs)
      @attrs = attrs
      @attrs.fetch(:results, []).collect do |tweet|
        @collection << Tweet.new(tweet)
      end
      @attrs
    end
  end
end
