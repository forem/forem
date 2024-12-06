require 'twitter/creatable'
require 'twitter/entities'
require 'twitter/identity'

module Twitter
  class Tweet < Twitter::Identity
    include Twitter::Creatable
    include Twitter::Entities
    # @return [String]
    attr_reader :filter_level, :in_reply_to_screen_name, :lang, :source, :text
    # @return [Integer]
    attr_reader :favorite_count, :in_reply_to_status_id, :in_reply_to_user_id,
                :quote_count, :reply_count, :retweet_count
    alias in_reply_to_tweet_id in_reply_to_status_id
    alias reply? in_reply_to_user_id?
    object_attr_reader :GeoFactory, :geo
    object_attr_reader :Metadata, :metadata
    object_attr_reader :Place, :place
    object_attr_reader :Tweet, :retweeted_status
    object_attr_reader :Tweet, :quoted_status
    object_attr_reader :Tweet, :current_user_retweet
    alias retweeted_tweet retweeted_status
    alias retweet? retweeted_status?
    alias retweeted_tweet? retweeted_status?
    alias quoted_tweet quoted_status
    alias quote? quoted_status?
    alias quoted_tweet? quoted_status?
    object_attr_reader :User, :user, :status
    predicate_attr_reader :favorited, :possibly_sensitive, :retweeted,
                          :truncated

    # Initializes a new object
    #
    # @param attrs [Hash]
    # @return [Twitter::Tweet]
    def initialize(attrs = {})
      attrs[:text] = attrs[:full_text] if attrs[:text].nil? && !attrs[:full_text].nil?
      super
    end

    # @note May be > 280 characters.
    # @return [String]
    def full_text
      if retweet?
        prefix = text[/\A(RT @[a-z0-9_]{1,20}: )/i, 1]
        [prefix, retweeted_status.text].compact.join
      else
        text
      end
    end
    memoize :full_text

    # @return [Addressable::URI] The URL to the tweet.
    def uri
      Addressable::URI.parse("https://twitter.com/#{user.screen_name}/status/#{id}") if user?
    end
    memoize :uri
    alias url uri
  end
end
