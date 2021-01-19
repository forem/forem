module DataUpdateScripts
  class ResyncUnpublishedArticlesCommentsElasticsearchDocument
    def run
      Article.unpublished.where.not(comments_count: 0).each do |article|
        article.comments.each(&:index_to_elasticsearch)
      end
    end
  end
end
