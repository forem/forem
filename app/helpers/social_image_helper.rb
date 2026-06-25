module SocialImageHelper
  def article_social_image_url(article, **options)
    Articles::SocialImage.new(article, **options).url
  end

  def profile_social_image_url(user_or_org)
    if user_or_org.is_a?(User)
      user_or_org.profile&.social_image.presence || Settings::General.main_social_image.to_s
    elsif user_or_org.is_a?(Organization)
      user_or_org.social_image.presence || Settings::General.main_social_image.to_s
    else
      Settings::General.main_social_image.to_s
    end
  end
end
