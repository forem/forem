# send notification about the action ("Published") that happened on a notifiable (Article)
module Notifications
  module NotifiableAction
    FOLLOWER_SEND_LIMIT = 10_000
    DAILY_UNTHROTTLED_ARTICLE_LIMIT = 2

    class Send
      def self.call(...)
        new(...).call
      end

      # @param notifiable [Article]
      # @param action [String] for now only "Published"
      def initialize(notifiable, action = nil)
        @notifiable = notifiable
        @action = action
      end

      delegate :user_data, :article_data, :organization_data, to: Notifications

      # Sends notifications to followers for a notifiable action and records the ContextNotification.
      def call
        return unless notifiable.is_a?(Article)

        send_limit = follower_send_limit
        if send_limit <= 0
          upsert_context_notification
          return
        end

        json_data = {
          user: user_data(notifiable.user),
          article: article_data(notifiable)
        }
        json_data[:organization] = organization_data(notifiable.organization) if notifiable.organization_id

        notifications_attributes = []

        # Mentioned followers intentionally still receive the "new post" notification in addition to
        # their Mention notification, so they know the author both published and mentioned them.

        # Co-authors receive their own notification, so exclude them here:
        # one "new post" style notification per person per post.
        co_author_ids = Array.wrap(notifiable.co_author_ids).map(&:to_i)

        # Only follower ids are used below, so skip hydrating (and DISTINCT-sorting) full user rows.
        # Order by expression so PostgreSQL drives the join from fk_followables on follows instead of
        # scanning tmp_index_users_on_updated_at backwards across all users when send_limit is small.
        article_followers = User.select(:id, Arel.sql("(users.updated_at + INTERVAL '0 seconds') AS updated_at"))
          .joins("INNER JOIN follows ON follows.follower_id = users.id")
          .where("(follows.followable_id = ? AND follows.followable_type = ?)
                 OR (follows.followable_id = ? AND follows.followable_type = ?)",
                 notifiable&.user&.id, "User", notifiable&.organization&.id, "Organization")
          .where(follows: { subscription_status: "all_articles" })
          .where.not(id: (co_author_ids + [notifiable.user]))
          .recently_active(send_limit)
          .reorder(Arel.sql("(users.updated_at + INTERVAL '0 seconds') DESC"))
          .distinct

        article_followers.each do |follower|
          now = Time.current
          notifications_attributes.push(
            user_id: follower.id,
            notifiable_id: notifiable.id,
            notifiable_type: notifiable.class.name,
            subforem_id: notifiable.subforem_id,
            action: action,
            json_data: json_data,
            created_at: now,
            notified_at: now,
            updated_at: now,
          )
        end

        return if notifications_attributes.blank?

        upsert_index = choose_upsert_index(action)

        ActiveRecord::Base.transaction do
          Notification.upsert_all(
            notifications_attributes,
            unique_by: upsert_index,
            returning: %i[id],
          )

          upsert_context_notification
        end
      end

      private

      attr_reader :notifiable, :action

      # Computes the maximum number of followers to notify for this article.
      # For the 3rd+ non-status article published by the author within 24 hours,
      # caps notifications at the author's past-week article page views (unless published
      # under an organization with a positive baseline_score).
      #
      # @return [Integer]
      def follower_send_limit
        return FOLLOWER_SEND_LIMIT if notifiable.organization&.baseline_score.to_i.positive?

        author = notifiable.user
        return FOLLOWER_SEND_LIMIT unless author

        reference_time = notifiable.published_at || Time.current

        published_non_status_articles_past_day = author.articles
          .published
          .where.not(type_of: "status")
          .where(published_at: (reference_time - 1.day)..reference_time)
          .count

        return FOLLOWER_SEND_LIMIT if published_non_status_articles_past_day <= DAILY_UNTHROTTLED_ARTICLE_LIMIT

        past_week_views = author.articles
          .published
          .where("published_at >= ?", 1.week.ago)
          .sum(:page_views_count)

        [past_week_views, FOLLOWER_SEND_LIMIT].min
      end

      # Upserts a ContextNotification record marking the notifiable action as processed.
      def upsert_context_notification
        ContextNotification.upsert(
          {
            context_id: notifiable.id,
            context_type: notifiable.class.name,
            action: action
          },
          unique_by: :index_context_notification_on_context_and_action,
        )
      end

      # Selects the unique index name used for upserting Notification rows.
      #
      # @param action [String, nil]
      # @return [Symbol]
      def choose_upsert_index(action)
        return :index_notifications_on_user_notifiable_and_action_not_null if action.present?

        :index_notifications_on_user_notifiable_action_is_null
      end
    end
  end
end
