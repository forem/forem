module Articles
  class AsyncBustJob < ApplicationJob
    queue_as :articles_async_bust

    def perform(article_id, cache_buster = CacheBuster.new)
      article = Article.find_by(id: article_id)

      cache_buster.bust_article(article) if article
    end
  end
end
