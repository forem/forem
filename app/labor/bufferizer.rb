class Bufferizer
  attr_accessor :post_type, :post, :text

  include ApplicationHelper

  def initialize(post_type, post, text, admin_id = nil)
    if post_type == "article"
      @article = post
    else
      @listing = post
    end
    @text = text
    @admin_id = admin_id
  end

  def satellite_tweet!
    @article.tags.find_each do |tag|
      next if tag.buffer_profile_id_code.blank?

      text = twitter_buffer_text
      if text.length < 250 && SiteConfig.twitter_hashtag
        text = text.gsub(" #{SiteConfig.twitter_hashtag}", " #{SiteConfig.twitter_hashtag} ##{tag.name}")
      end
      BufferUpdate.buff!(@article.id, text, buffer_profile_id_code: tag.buffer_profile_id_code, tag_id: tag.id,
                                            admin_id: @admin_id)
    end
    @article.update(last_buffered: Time.current)
  end

  def main_tweet!
    BufferUpdate.buff!(@article.id, twitter_buffer_text, admin_id: @admin_id)
    @article.update(last_buffered: Time.current)
  end

  def facebook_post!
    BufferUpdate.buff!(@article.id, fb_buffer_text, social_service_name: "facebook", admin_id: @admin_id)
    BufferUpdate.buff!(@article.id, fb_buffer_text + social_tags, social_service_name: "linkedin", admin_id: @admin_id)

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
    tags = @article.tag_list.map { |tag| "##{tag}" }.join(" ")
    " #programming #softwareengineering #{tags}"
  end

  def listings_twitter_text
    "#{text} #{app_url(@listing.path)}" if text.size <= 255
  end
end
