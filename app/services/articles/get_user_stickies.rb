module Articles
  class GetUserStickies
    def self.call(article, author)
      article_tags = article.cached_tag_list.to_s.split(", ") - ["discuss"]

      author
        .articles
        .published.from_subforem
        .cached_tagged_with_any(article_tags)
        .unscope(:select)
        .select(:id, :path, :title, :cached_tag_list, :organization_id, :user_id) # Columns needed for _sticky_nav and path generation
        .where.not(id: article.id)
        .order(published_at: :desc)
        .limit(3)
    end
  end
end
