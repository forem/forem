module Bufferizer
  class SatelliteTweet
    def self.call(article, tweet, admin_id)
      return unless article && tweet && admin_id

      article.tags.find_each do |tag|
        next if tag.buffer_profile_id_code.blank?

        text = twitter_buffer_text(tweet, article)

        if text.length < 250 && SiteConfig.twitter_hashtag
          text = text.gsub(
            " #{SiteConfig.twitter_hashtag}",
            " #{SiteConfig.twitter_hashtag} ##{tag.name}",
          )
        end

        BufferUpdate.buff!(
          article.id,
          text,
          buffer_profile_id_code: tag.buffer_profile_id_code,
          tag_id: tag.id,
          admin_id: admin_id,
        )
      end

      article.update(last_buffered: Time.current)
    end

    def self.twitter_buffer_text(tweet, article)
      "#{tweet} #{URL.article(article)}" if tweet.size <= 255
    end

    private_class_method :twitter_buffer_text
  end
end
