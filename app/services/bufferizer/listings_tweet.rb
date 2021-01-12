module Bufferizer
  class ListingsTweet
    TWEET_SIZE_LIMIT = 255

    def self.call(listing, tweet)
      return unless listing && tweet

      buffer_listings_id = ApplicationConfig["BUFFER_LISTINGS_PROFILE"]

      BufferUpdate.send_to_buffer(
        listings_twitter_text(tweet, listing),
        buffer_listings_id,
      )

      listing.update(last_buffered: Time.current)
    end

    def self.listings_twitter_text(tweet, listing)
      "#{tweet} #{URL.url(listing.path)}" if tweet.size <= TWEET_SIZE_LIMIT
    end

    private_class_method :listings_twitter_text
  end
end
