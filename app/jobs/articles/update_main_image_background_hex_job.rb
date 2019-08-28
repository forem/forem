module Articles
  class UpdateMainImageBackgroundHexJob < ApplicationJob
    queue_as :articles_update_main_image_background_hex

    def perform(article_id)
      article = Article.find_by(id: article_id)

      article&.update_column(:main_image_background_hex_color, ColorFromImage.new(article.main_image).main)
    end
  end
end
