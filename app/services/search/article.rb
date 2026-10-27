module Search
  class Article
    DEFAULT_SORT_BY = "hotness_score DESC, comments_count DESC".freeze

    def self.search_documents(
      term: nil,
      user_id: nil,
      sort_by: nil,
      sort_direction: nil,
      page: nil,
      per_page: nil
    )
      relation = Homepage::ArticlesQuery.call(user_id: user_id, page: page, per_page: per_page)

      relation = relation.search_articles(term) if term.present?

      relation = sort(relation, term, sort_by, sort_direction)

      Homepage::ArticleSerializer.serialized_collection_from(relation: relation)
    end

    def self.sort(relation, term, sort_by, sort_direction)
      # By skipping ordering, we rely on the custom ranking defined in the article's tsvector document
      return relation if term.present? && sort_by.blank?

      if sort_by&.to_sym == :published_at && sort_direction
        if term.present?
          direction = sort_direction.to_s.casecmp?("asc") ? "ASC" : "DESC"
          order_sql = "(articles.published_at + INTERVAL '0 seconds') #{direction}, articles.id ASC"
          return relation.reorder(Arel.sql(order_sql))
        end

        return relation.reorder(sort_by => sort_direction)
      end

      if term.present?
        return relation.reorder(Arel.sql("(articles.hotness_score + 0) DESC, articles.comments_count DESC"))
      end

      relation.reorder(DEFAULT_SORT_BY)
    end
    private_class_method :sort
  end
end
