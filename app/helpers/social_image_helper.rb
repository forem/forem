module SocialImageHelper
  # After this date we use SocialPreview controller directly rather than passing to URL2PNG.
  # Keeping old URLs around since they are already generated.
  SOCIAL_PREVIEW_MIGRATION_DATETIME = Time.zone.parse("2019-04-22T00:00:00Z")

  def user_social_image_url(user)
    return Images::GenerateSocialImage.call(user) unless use_new_social_url?(user)

    if user.is_a?(Organization)
      organization_social_preview_url(user, format: :png)
    else
      user_social_preview_url(user, format: :png)
    end
  end

  def listing_social_image_url(listing)
    listing_social_preview_url(listing, format: :png)
  end

  def article_social_image_url(article, **options)
    Articles::SocialImage.new(article, **options).url
  end

  def comment_social_image_url(comment)
    comment_social_preview_url(comment, format: :png)
  end

  def use_new_social_url?(resource)
    resource.updated_at > SOCIAL_PREVIEW_MIGRATION_DATETIME
  end
end
