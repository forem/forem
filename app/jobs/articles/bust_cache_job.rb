module Articles
  class BustCacheJob < ApplicationJob
    queue_as :articles_bust_cache

    def perform(article_id, cache_buster = CacheBuster)
      article = Article.find_by(id: article_id)

      cache_buster.bust_article(article) if article
    end
  end
end
