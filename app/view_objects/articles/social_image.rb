module Articles
  class SocialImage
    include Rails.application.routes.url_helpers
    include CloudinaryHelper

    def initialize(article)
      @article = article
    end

    SOCIAL_PREVIEW_MIGRATION_DATETIME = Time.zone.parse("2019-04-22T00:00:00Z")

    def url
      image = user_defined_image
      if image.present?
        return cl_image_path(image,
                             type: "fetch",
                             width: "1000",
                             height: "500",
                             crop: "imagga_scale",
                             quality: "auto",
                             flags: "progressive",
                             fetch_format: "auto",
                             sign_url: true)
      end
      return legacy_article_social_image unless use_new_social_url?

      article_social_preview_url(article, format: :png)
    end

    private

    attr_reader :article

    def legacy_article_social_image
      cache_key = "article-social-img-#{article}-#{article.updated_at.rfc3339}-#{article.comments_count}"

      Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        src = GeneratedImage.new(article).social_image
        return src if src.start_with? "https://res.cloudinary.com/"

        cl_image_path(src,
                      type: "fetch",
                      width: "1000",
                      height: "500",
                      crop: "imagga_scale",
                      quality: "auto",
                      flags: "progressive",
                      fetch_format: "auto",
                      sign_url: true)
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
