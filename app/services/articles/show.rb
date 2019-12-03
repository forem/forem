module Articles
  class Show
    def self.execute(article, moderate:, variant_version:, previewing:, user_signed_in:)
      article_presenter = ArticleShowPresenter.new(article, variant_version: variant_version, user_signed_in: user_signed_in)

      raise ActiveRecord::RecordNotFound unless article_presenter.user # user existance check

      raise ActiveRecord::RecordNotFound if !article.published && previewing != article.password # previewing check

      moderate_url = "/internal/articles/#{article_presenter.id}" if moderate

      OpenStruct.new(article_presenter: article_presenter, moderate_url: moderate_url)
    end
  end
end
