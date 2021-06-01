class PinnedArticle
  class << self
    def exists?
      Settings::General.feed_pinned_article_id.present?
    end

    def id
      Settings::General.feed_pinned_article_id
    end

    def updated_at
      return if Settings::General.feed_pinned_article_id.blank?

      setting = Settings::General.find_by(var: :feed_pinned_article_id)
      setting.updated_at
    end

    def get
      return if Settings::General.feed_pinned_article_id.blank?

      Article.published.find_by(id: Settings::General.feed_pinned_article_id)
    end

    def set(article)
      Settings::General.feed_pinned_article_id = article.id
    end

    def remove
      Settings::General.feed_pinned_article_id = nil
    end
  end
end
