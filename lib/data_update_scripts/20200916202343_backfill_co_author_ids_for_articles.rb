module DataUpdateScripts
  class BackfillCoAuthorIdsForArticles
    def run
      articles = Article.where.not(second_user_id: nil).or(Article.where.not(third_user_id: nil))
      articles.find_each do |article|
        article.update!(co_author_ids: [article.second_user_id, article.third_user_id])
      end
    end
  end
end
