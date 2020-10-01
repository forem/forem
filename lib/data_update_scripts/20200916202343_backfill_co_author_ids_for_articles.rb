module DataUpdateScripts
  class BackfillCoAuthorIdsForArticles
    def run
      articles = Article.where.not(second_user_id: nil).or(Article.where.not(third_user_id: nil))
      articles.find_each do |article|
        co_author_ids = [article.second_user_id, article.third_user_id].compact
        article.update_columns(co_author_ids: co_author_ids)
      end
    end
  end
end
