module Articles
  class GetUserStickies
    def self.call(article, author)
      article_tags = article.cached_tag_list_array - ["discuss"]

      author
        .articles
        .published
        .cached_tagged_with_any(article_tags)
        .unscope(:select)
        .limited_column_select
        .where.not(id: article.id)
        .order(published_at: :desc)
        .limit(3)
    end
  end
end
