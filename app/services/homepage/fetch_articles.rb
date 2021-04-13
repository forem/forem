module Homepage
  class FetchArticles
    DEFAULT_PER_PAGE = 60

    def self.call(published_at: nil, sort_by: nil, sort_direction: nil, page: 0, per_page: DEFAULT_PER_PAGE)
      articles = Homepage::ArticlesQuery.call(
        published_at: published_at,
        sort_by: sort_by,
        sort_direction: sort_direction,
        page: page,
        per_page: per_page,
      )

      # Unfortunately the FlareTag class sends one SQL query per each article,
      # as we want to optimize by loading them in one query, we're using a different class
      tag_flares = Homepage::FetchTagFlares.call(articles)

      # including user and organization as the last step as they are not needed
      # by the query that fetches tag flares, they are only needed by the serializer
      # NOTE: wish there was a way to specify which columns to fetch for `User` and `Organization`...
      articles = articles.includes(:user, :organization)

      Homepage::ArticleSerializer
        .new(articles, params: { tag_flares: tag_flares }, is_collection: true)
        .serializable_hash[:data]
        .pluck(:attributes)
    end
  end
end
