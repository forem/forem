module Articles
  class SocialImage
    include Rails.application.routes.url_helpers

    SOCIAL_PREVIEW_MIGRATION_DATETIME = Time.zone.parse("2019-04-22T00:00:00Z")

    def initialize(article, **options)
      @article = article
      @height = options[:height] || 500
      @width = options[:width] || 1000
    end

    def url
      image = user_defined_image
      if image.present?
        image = image.split("w_1000/").last if image.include?("w_1000/https://")
        return Images::Optimizer.call(image, width: width, height: height, crop: "imagga_scale")
      end
      return legacy_article_social_image unless use_new_social_url?

      article_social_preview_url(article, format: :png, host: SiteConfig.app_domain)
    end

    private

    attr_reader :article, :height, :width

    def legacy_article_social_image
      cache_key = "article-social-img-#{article}-#{article.updated_at.rfc3339}-#{article.comments_count}"

      Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        src = Images::GenerateSocialImage.call(article)
        return src if src.start_with? "https://res.cloudinary.com/"

        Images::Optimizer.call(src, width: "1000", height: "500", crop: "imagga_scale")
      end
    end

    def use_new_social_url?
      article.updated_at > SOCIAL_PREVIEW_MIGRATION_DATETIME
    end

    def user_defined_image
      return article.social_image if article.social_image.present?
      return article.main_image if article.main_image.present?
      return article.video_thumbnail_url if article.video_thumbnail_url.present?
    end
  end
end
