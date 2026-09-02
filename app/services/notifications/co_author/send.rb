# Notifies co-authors that a post they are credited on is live.
module Notifications
  module CoAuthor
    class Send
      ACTION = "CoAuthor".freeze

      def self.call(...)
        new(...).call
      end

      # @param article [Article]
      def initialize(article)
        @article = article
      end

      delegate :user_data, :article_data, :organization_data, to: Notifications

      def call
        return unless article.is_a?(Article)
        return unless article.published? && article.type_of == "full_post"

        recipient_ids = article.co_author_ids.map(&:to_i) - [article.user_id]
        return if recipient_ids.empty?

        # Skip anyone already notified so re-publishing or an unrelated edit
        # does not notify the same co-author twice.
        already_notified = Notification.where(
          user_id: recipient_ids,
          notifiable_id: article.id,
          notifiable_type: "Article",
          action: ACTION,
        ).pluck(:user_id)

        pending_ids = recipient_ids - already_notified
        return if pending_ids.empty?

        now = Time.current
        attributes = User.where(id: pending_ids).ids.map do |user_id|
          {
            user_id: user_id,
            notifiable_id: article.id,
            notifiable_type: "Article",
            subforem_id: article.subforem_id,
            action: ACTION,
            json_data: json_data,
            created_at: now,
            updated_at: now
          }
        end
        return if attributes.empty?

        # upsert rather than insert: a unique index covers
        # (user_id, notifiable_id, notifiable_type, action), and two publishes
        # racing would otherwise raise instead of no-opping.
        Notification.upsert_all(
          attributes,
          unique_by: :index_notifications_on_user_notifiable_and_action_not_null,
        )
      end

      private

      attr_reader :article

      def json_data
        data = {
          user: user_data(article.user),
          article: article_data(article)
        }
        data[:organization] = organization_data(article.organization) if article.organization_id
        data
      end
    end
  end
end
