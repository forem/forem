module SocialImageHelper
  # After this date we use SocialPreview controller directly rather than passing to URL2PNG.
  # Keeping old URLs around since they are already generated.
  SOCIAL_PREVIEW_MIGRATION_DATETIME = Time.zone.parse("2019-04-22T00:00:00Z")

  def user_social_image_url(user)
    return GeneratedImage.new(user).social_image unless use_new_social_url?(user)

    if user.is_a?(Organization)
      organization_social_preview_url(user, format: :png)
    else
      user_social_preview_url(user, format: :png)
    end
  end

  def listing_social_image_url(listing)
    listing_social_preview_url(listing, format: :png)
  end

  def article_social_image_url(article)
    image = user_defined_image(article)
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
    return legacy_article_social_image(article) unless use_new_social_url?(article)

    article_social_preview_url(article, format: :png)
  end

  def legacy_article_social_image(article)
    cache_key = "article-social-img-#{article}-#{article.updated_at}-#{article.comments_count}"

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

  def use_new_social_url?(resource)
    resource.updated_at > SOCIAL_PREVIEW_MIGRATION_DATETIME
  end

  def user_defined_image(article)
    return article.social_image if article.social_image.present?
    return article.main_image if article.main_image.present?
    return article.video_thumbnail_url if article.video_thumbnail_url.present?
  end
end
