module Articles
  class UpdateMainImageBackgroundHexWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(article_id)
      article = Article.find_by(id: article_id)

      return unless article

      article.update_column(:main_image_background_hex_color, ColorFromImage.new(article.main_image).main)
    end
  end
end
