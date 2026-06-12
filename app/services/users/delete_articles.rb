module Users
  module DeleteArticles
    module_function

    def call(user)
      return if user.articles.blank?

      virtual_articles = user.articles.map { |article| Article.new(article.attributes) }
      user.articles.find_each do |article|
        article.reactions.delete_all
        article.comments.includes(:user).find_each do |comment|
          comment.reactions.delete_all
          EdgeCache::BustComment.call(comment)
          EdgeCache::BustUser.call(comment.user)
          comment.delete
        end
        article.discussion_lock&.delete
        article.context_notes.delete_all
        article.article_activity&.delete
        article.trend_memberships.delete_all
        article.profile_pins.delete_all
        article.delete
        article.purge
      end
      virtual_articles.each do |article|
        EdgeCache::BustArticle.call(article)
      end
    end
  end
end
