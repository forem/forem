module SocialImageHelper
  def article_social_image_url(article, **options)
    Articles::SocialImage.new(article, **options).url
  end
end
