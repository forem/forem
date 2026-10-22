module Articles
  # Busts the edge cache of an article that has already been deleted from the
  # database, rebuilding an unsaved copy of it from the attributes captured
  # before deletion.
  class BustDeletedArticleCacheWorker < BustCacheBaseWorker
    ATTRIBUTES = %w[
      id user_id organization_id slug path published published_at cached_tag_list video
    ].freeze

    def self.attributes_for(article)
      article.attributes.slice(*ATTRIBUTES).as_json
    end

    def perform(article_attributes)
      article = Article.new(article_attributes.slice(*ATTRIBUTES))
      EdgeCache::BustArticle.call(article)
    end
  end
end
