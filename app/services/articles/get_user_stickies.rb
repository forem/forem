module Articles
  class GetUserStickies
    def self.call(article, author)
      article_tags = article.cached_tag_list_array - ["discuss"]

      author
        .articles
        .published
        .limited_column_select
        .tagged_with(article_tags, any: true)
        .where.not(id: article.id)
        .order(published_at: :desc)
        .limit(3)
    end
  end
end
