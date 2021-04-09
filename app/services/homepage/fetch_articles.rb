module Homepage
  class FetchArticles
    def self.call(...)
      new.call(...)
    end

    def call(...)
      articles = Homepage::ArticlesQuery.call(...)
      Homepage::ArticleSerializer
        .new(articles, is_collection: true)
        .serializable_hash[:data]
        .pluck(:attributes)
    end
  end
end
