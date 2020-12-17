module Users
  module DeleteArticles
    module_function

    def call(user, cache_buster = CacheBuster)
      return if user.articles.blank?

      virtual_articles = user.articles.map { |article| Article.new(article.attributes) }
      user.articles.find_each do |article|
        article.reactions.delete_all
        article.buffer_updates.delete_all
        article.comments.includes(:user).find_each do |comment|
          comment.reactions.delete_all
          EdgeCache::BustComment.call(comment.commentable)
          cache_buster.bust_user(comment.user)
          comment.remove_from_elasticsearch
          comment.delete
        end
        article.remove_from_elasticsearch
        article.delete
        article.purge
      end
      virtual_articles.each do |article|
        EdgeCache::BustArticle.call(article)
      end
    end
  end
end
