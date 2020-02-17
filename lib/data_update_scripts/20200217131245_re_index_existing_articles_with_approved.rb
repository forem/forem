module DataUpdateScripts
  class ReIndexExistingArticlesWithApproved
    def run
      Article.find_each { |article| Article.trigger_index(article, false) }
    end
  end
end
