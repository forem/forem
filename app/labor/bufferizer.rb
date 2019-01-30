class Bufferizer
  attr_accessor :article, :text
  def initialize(article, text)
    @article = article
    @text = text
  end

  def satellite_tweet!
    article.tags.find_each do |tag|
      if tag.buffer_profile_id_code.present?
        BufferUpdate.buff!(article.id, twitter_buffer_text, tag.buffer_profile_id_code, "twitter", tag.id)
      end
    end
    article.update(last_buffered: Time.current)
  end

  def main_teet!
    BufferUpdate.buff!(article.id, twitter_buffer_text, ApplicationConfig["BUFFER_TWITTER_ID"], "twitter", nil)
    article.update(last_buffered: Time.current)
  end

  def facebook_post!
    BufferUpdate.buff!(article.id, fb_buffer_text, ApplicationConfig["BUFFER_FACEBOOK_ID"], "facebook")
    BufferUpdate.buff!(article.id, fb_buffer_text, ApplicationConfig["BUFFER_LINKEDIN_ID"], "linkedin")
    article.update(facebook_last_buffered: Time.current)
  end

  private

  def twitter_buffer_text
    if text.size <= 255
      "#{text} https://dev.to#{article.path}"
    end
  end

  def fb_buffer_text
    "#{text} https://dev.to#{article.path}"
  end
end
