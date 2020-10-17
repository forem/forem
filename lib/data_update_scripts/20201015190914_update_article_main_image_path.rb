module DataUpdateScripts
  class UpdateArticleMainImagePath
    def run
      return unless ENV["FOREM_CONTEXT"] == "forem_cloud"

      Article.where.not(main_image: [nil, ""]).each do |article|
        next unless article.main_image&.starts_with? "https://res.cloudinary.com/"

        index = article.main_image.index(URL.url)
        article.main_image = article.main_image[index..].gsub("/images/", "/remoteimages/")
        article.save
      end
    end
  end
end
