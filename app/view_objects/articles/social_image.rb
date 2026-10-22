module Articles
  class SocialImage
    include Rails.application.routes.url_helpers

    # twitter: true prefers the X-specific generated image, which keeps the
    # bottom of the card clear for the title bar X overlays on link cards.
    def initialize(article, height: nil, width: nil, twitter: false)
      @article = article
      @twitter = twitter

      default_width, default_height = if article.published_at.present? && article.published_at > Time.zone.local(2026, 3, 1)
                                        [1200, 627]
                                      else
                                        [1000, 500]
                                      end

      @height = height || default_height
      @width = width || default_width
    end

    def url
      image = user_defined_image
      if image.present?
        image = image.split("w_1000/").last if image.include?("w_1000/https://")
        return Images::Optimizer.call(image, width: width, height: height, crop: "crop")
      else
        return Settings::General.main_social_image.to_s
      end
    end

    private

    attr_reader :article, :height, :width, :twitter

    def user_defined_image
      return article.main_image if article.main_image.present?
      return article.twitter_social_image if twitter && article.twitter_social_image.present?
      return article.social_image if article.social_image.present?
      return article.video_thumbnail_url if article.video_thumbnail_url.present?
    end
  end
end
