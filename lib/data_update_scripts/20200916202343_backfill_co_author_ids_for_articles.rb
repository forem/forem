module DataUpdateScripts
  class BackfillCoAuthorIdsForArticles
    def run
      articles = Article.where.not(second_user_id: nil).or(Article.where.not(third_user_id: nil))
      articles.update_all("co_author_ids = array[second_user_id, third_user_id]")
    end
  end
end
