module DataUpdateScripts
  class ReIndexExistingArticlesWithApproved
    def run
      Article.published.find_each { |article| Article.trigger_index(article, false) }
    end
  end
end
