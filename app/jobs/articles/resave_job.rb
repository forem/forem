module Articles
  class ResaveJob < ApplicationJob
    queue_as :articles_resave

    def perform(article_ids, cache_buster = CacheBuster.new)
      Article.where(id: article_ids).find_each do |article|
        cache_buster.bust(article.path)
        cache_buster.bust(article.path + "?i=i")
        article.save
      end
    end
  end
end
