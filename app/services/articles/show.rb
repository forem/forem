module Articles
  class Show
    def self.execute(article, variant_version:, preview_value:, user_signed_in:)
      article_presenter = ArticleShowPresenter.new(article, variant_version: variant_version, user_signed_in: user_signed_in)

      check_article_must_have_a_user(article)
      check_user_cannot_preview_published(article, preview_value)

      article_presenter
    end

    def self.check_article_must_have_a_user(article)
      raise ActiveRecord::RecordNotFound unless article.user
    end

    def self.check_user_cannot_preview_published(article, preview_value)
      raise ActiveRecord::RecordNotFound if !article.published && preview_value != article.password
    end

    private_class_method :check_user_cannot_preview_published, :check_article_must_have_a_user
  end
end
