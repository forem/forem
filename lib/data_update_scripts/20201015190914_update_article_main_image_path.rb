module DataUpdateScripts
  class UpdateArticleMainImagePath
    def run
      return unless ENV["FOREM_CONTEXT"] == "forem_cloud"

      Article.where.not(main_image: [nil, ""]).each do |article|
        next unless article.main_image&.starts_with? "https://res.cloudinary.com/"

        index = article.main_image.index(URL.url)
        raw_image_path = article.main_image[index..].gsub("/images/", "/remoteimages/")
        article.update_column(:main_image, raw_image_path)
      end
    end
  end
end
