class AuditLog
  class UnpublishAllsQuery
    Result = Struct.new(:exists?, :audit_log, :target_articles, :target_comments, keyword_init: true)

    def initialize(user_id)
      @user_id = user_id
      @target_articles = []
      @target_comments = []
    end

    def self.call(...)
      new(...).call
    end

    def call
      audit_log = AuditLog.where(slug: %w[api_user_unpublish unpublish_all_articles])
        .where("data @> '{\"target_user_id\": ?}'", user_id)
        .includes(:user)
        .order("created_at DESC")
        .first
      if audit_log
        target_articles = Article.where(id: audit_log.data["target_article_ids"], user_id: user_id)
        target_comments = Comment.where(id: audit_log.data["target_comment_ids"], user_id: user_id)
      end
      Result.new(
        exists?: audit_log.present?,
        audit_log: audit_log,
        target_articles: target_articles,
        target_comments: target_comments,
      )
    end

    attr_reader :user_id
    attr_accessor :target_comments, :target_articles
  end
end
