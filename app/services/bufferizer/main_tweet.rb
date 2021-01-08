module Bufferizer
  class MainTweet
    TWEET_SIZE_LIMIT = 255

    def self.call(article, tweet, admin_id)
      return unless article && tweet && admin_id

      BufferUpdate.buff!(
        article.id,
        twitter_buffer_text(tweet, article),
        admin_id: admin_id,
      )

      article.update(last_buffered: Time.current)
    end

    def self.twitter_buffer_text(tweet, article)
      "#{tweet} #{URL.article(article)}" if tweet.size <= TWEET_SIZE_LIMIT
    end

    private_class_method :twitter_buffer_text
  end
end
