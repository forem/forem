class Bufferizer
  def initialize(article, text)
    @article = article
    @text = text
  end

  def sattelite_tweet!
    article.tags.each do |tag|
      if tag.buffer_profile_id_code.present?
        BufferUpdate.new(article.id, twitter_buffer_text, tag.buffer_profile_id_code, "twitter", tag.id).buff!
      end
    end
    @article.update(last_buffered: Time.now)
  end

  def main_teet!
    BufferUpdate.new(article.id, ApplicationConfig["BUFFER_TWITTER_ID"], tag.buffer_profile_id_code, "twitter", tag.id).buff!
    @article.update(last_buffered: Time.now)
  end

  def facebook_post!
    BufferUpdate.new(article.id, fb_buffer_text, ApplicationConfig["BUFFER_FACEBOOK_ID"], "facebook").buff!
    BufferUpdate.new(article.id, fb_buffer_text, ApplicationConfig["BUFFER_LINKEDIN_ID"], "linkedin").buff!
    @article.update(facebook_last_buffered: Time.now)
  end

  private

  def twitter_buffer_text
    twit_name = @article.user.twitter_username
    if twit_name.present? && @text.size < 245
      "#{@text}\n{ author: @#{twit_name} }\nhttps://dev.to#{@article.path}"
    else
      "#{@text} https://dev.to#{@article.path}"
    end
  end

  def fb_buffer_text
    "#{@text} https://dev.to#{@article.path}"
  end
end
