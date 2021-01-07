module Bufferizer
  class SatelliteTweet
    def self.call(article, text, admin_id = nil)
      return unless article && text

      article.tags.find_each do |tag|
        next if tag.buffer_profile_id_code.blank?

        text = twitter_buffer_text(text, article)

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

    def self.twitter_buffer_text(text, article)
      "#{text} #{URL.article(article)}" if text.size <= 255
    end

    private_class_method :twitter_buffer_text
  end
end
