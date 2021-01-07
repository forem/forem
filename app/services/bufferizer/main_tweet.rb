module Bufferizer
  class MainTweet
    def self.call(article, tweet, admin_id = nil)
      return unless article && tweet

      BufferUpdate.buff!(
        article.id,
        twitter_buffer_text(tweet, article),
        admin_id: admin_id,
      )

      article.update(last_buffered: Time.current)
    end

    def self.twitter_buffer_text(tweet, article)
      "#{tweet} #{URL.article(article)}" if tweet.size <= 255
    end

    private_class_method :twitter_buffer_text
  end
end
