class PinnedArticle
  class << self
    def exists?
      pinned_article_id.present? && setting.valid?
    end

    def id
      return unless setting.valid?

      pinned_article_id
    end

    def updated_at
      return unless setting.valid?

      setting.updated_at
    end

    def get
      return unless setting.valid?

      Article.published.find_by(id: pinned_article_id)
    end

    def set(article)
      self.pinned_article_id = article.id
    end

    def remove
      self.pinned_article_id = nil
    end

    private

    def pinned_article_id
      Settings::General.feed_pinned_article_id
    end

    def pinned_article_id=(article_id)
      Settings::General.feed_pinned_article_id = article_id
    end

    def setting
      Settings::General.find_by(var: :feed_pinned_article_id)
    end
  end
end
