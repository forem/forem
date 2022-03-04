module DataUpdateScripts
  class TouchArticlesWithCapitalizedPaths
    def run
      offending_articles = Article.where("path != lower(path)")

      # Some log visibility for troubleshooting/monitoring
      Rails.logger.info("Updating #{offending_articles.count} articles with capitalized paths...")

      # touch won't trigger the callbacks so a manual update will do the trick
      offending_articles.update(updated_at: Time.current)
    end
  end
end
