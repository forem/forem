# Unpublish posts and delete comments w/ boolean attr (setting deleted: true) to allow revert
# Create a corresponding audit_log record
module Moderator
  class UnpublishAllArticles
    # @param target_user_id [Integer] the id of the user whose posts are being unpublished
    # @param action_user_id [Integer] the id of the user who unpublishes
    # @param listener [String] listener for the audit logger
    def initialize(target_user_id:, action_user_id:, listener: :admin_api)
      @target_user_id = target_user_id
      @action_user_id = action_user_id
      @listener = listener
    end

    delegate :user_data, to: Notifications

    def self.call(...)
      new(...).call
    end

    def call
      user = User.find_by(id: target_user_id)
      return unless user

      target_comments = user.comments.where(deleted: false)
      target_articles = user.articles.published

      # cache for logging
      target_comments_ids = target_comments.ids
      target_articles_ids = target_articles.ids

      target_comments.update(deleted: true)

      target_articles.find_each do |article|
        if article.has_frontmatter?
          article.body_markdown.sub!(/^published:\s*true\s*$/, "published: false")
        end
        article.published = false
        article.save(validate: false)
        clean_up_notifications(article)
      end

      payload = {
        target_user_id: target_user_id,
        target_article_ids: target_articles_ids,
        target_comment_ids: target_comments_ids
      }

      audit_log(payload)
    end

    private

    attr_reader :target_user_id, :action_user_id, :listener

    def clean_up_notifications(article)
      Notification.remove_all_by_action_without_delay(notifiable_ids: article.id,
                                                      notifiable_type: "Article",
                                                      action: "Published")

      ContextNotification.delete_by(context_id: article.id, context_type: "Article", action: "Published")

      return unless article.comments.exists?

      Notification.remove_all(notifiable_ids: article.comments.ids, notifiable_type: "Comment")
    end

    def audit_log(payload = {})
      payload["action"] = listener == :moderator ? "unpublish_all_articles" : "api_user_unpublish"
      action_user = User.find_by(id: action_user_id)
      Audit::Logger.log(listener, action_user, payload)
    end
  end
end
