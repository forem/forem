module Articles
  class BustCacheWorker < BustCacheBaseWorker
    def perform(article_id)
      article = Article.find_by(id: article_id)

      return unless article

      EdgeCache::BustArticle.call(article)
    end
  end
end
