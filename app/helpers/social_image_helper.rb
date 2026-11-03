module SocialImageHelper
  def article_social_image_url(article, **options)
    Articles::SocialImage.new(article, **options).url
  end

  def user_social_image_url(user, width: 1200, height: 627)
    return Settings::General.main_social_image.to_s if user&.social_image.blank?

    Images::Optimizer.call(user.social_image, width: width, height: height, crop: "crop")
  end
end
