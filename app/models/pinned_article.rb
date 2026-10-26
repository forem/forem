class PinnedArticle
  class << self
    def exists?
      pinned_article_id.present? && valid?
    end

    # The request-cached setting value is checked first: when nothing is pinned the answer is nil
    # regardless of validity, so we skip the site_configs lookup on every article page and feed item.
    def id
      return if pinned_article_id.nil?
      return unless valid?

      pinned_article_id
    end

    def updated_at
      return unless valid?

      setting.updated_at
    end

    def get
      return if pinned_article_id.nil?
      return unless valid?

      Article.published.from_subforem.find_by(id: pinned_article_id)
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
      Settings::General.set_feed_pinned_article_id(article_id)
    end

    def setting
      Settings::General.find_by(var: :feed_pinned_article_id)
    end

    def valid?
      setting&.valid?
    end
  end
end
