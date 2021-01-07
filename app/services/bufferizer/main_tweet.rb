module Bufferizer
  class MainTweet
    def self.call(article, text, admin_id = nil)
      return unless article && text

      BufferUpdate.buff!(
        article.id,
        twitter_buffer_text(text, article),
        admin_id: admin_id,
      )

      article.update(last_buffered: Time.current)
    end

    def self.twitter_buffer_text(text, article)
      "#{text} #{URL.article(article)}" if text.size <= 255
    end

    private_class_method :twitter_buffer_text
  end
end
