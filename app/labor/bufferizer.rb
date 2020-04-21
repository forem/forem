class Bufferizer
  attr_accessor :post_type, :post, :text
  include ApplicationHelper

  def initialize(post_type, post, text)
    if post_type == "article"
      @article = post
    else
      @listing = post
    end
    @text = text
  end

  def satellite_tweet!
    @article.tags.find_each do |tag|
      BufferUpdate.buff!(@article.id, twitter_buffer_text, tag.buffer_profile_id_code, "twitter", tag.id) if tag.buffer_profile_id_code.present?
    end
    @article.update(last_buffered: Time.current)
  end

  def main_tweet!
    BufferUpdate.buff!(@article.id, twitter_buffer_text, ApplicationConfig["BUFFER_TWITTER_ID"], "twitter", nil)
    @article.update(last_buffered: Time.current)
  end

  def facebook_post!
    BufferUpdate.buff!(@article.id, fb_buffer_text, ApplicationConfig["BUFFER_FACEBOOK_ID"], "facebook")
    BufferUpdate.buff!(@article.id, fb_buffer_text + social_tags, ApplicationConfig["BUFFER_LINKEDIN_ID"], "linkedin")
    @article.update(facebook_last_buffered: Time.current)
  end

  def listings_tweet!
    buffer_listings_id = ApplicationConfig["BUFFER_LISTINGS_PROFILE"]
    BufferUpdate.send_to_buffer(listings_twitter_text, buffer_listings_id)
    @listing.update(last_buffered: Time.current)
  end

  private

  def twitter_buffer_text
    "#{text} #{article_url(@article)}" if text.size <= 255
  end

  def fb_buffer_text
    "#{text} #{article_url(@article)}"
  end

  def social_tags
    # for linkedin's followable tags
    " #programming #softwareengineering " + (@article.tag_list.map { |tag| "#" + tag }).join(" ")
  end

  def listings_twitter_text
    "#{text} #{app_url(@listing.path)}" if text.size <= 255
  end
end
