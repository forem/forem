module DataUpdateScripts
  class ReindexArticlesWithVideos
    def run
      # articles = Article.where.not(video: nil).or(Article.where.not(video: ""))
      # articles.find_each(&:index_to_elasticsearch_inline)
    end
  end
end
