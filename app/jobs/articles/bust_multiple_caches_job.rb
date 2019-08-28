module Articles
  class BustMultipleCachesJob < ApplicationJob
    queue_as :articles_bust_multiple_caches

    def perform(article_ids, cache_buster = CacheBuster.new)
      Article.select(:id, :path).where(id: article_ids).find_each do |article|
        cache_buster.bust(article.path)
        cache_buster.bust(article.path + "?i=i")
      end
    end
  end
end
