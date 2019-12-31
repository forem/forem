class Notification < ApplicationRecord
  belongs_to :notifiable, polymorphic: true
  belongs_to :user, optional: true
  belongs_to :organization, optional: true

  validates :user_id, presence: true, if: proc { |notification| notification.organization_id.nil? }
  validates :organization_id, presence: true, if: proc { |notification| notification.user_id.nil? }
  validates :user_id, uniqueness: { scope: %i[organization_id notifiable_id notifiable_type action] }

  before_create :mark_notified_at_time

  scope :for_published_articles, -> { where(notifiable_type: "Article", action: "Published") }
  scope :for_comments, -> { where(notifiable_type: "Comment", action: nil) } # nil action means "not a reaction"
  scope :for_mentions, -> { where(notifiable_type: "Mention") }

  scope :for_organization, ->(org_id) { where(organization_id: org_id, user_id: nil) }
  scope :for_organization_comments, lambda { |org_id|
    # nil action means "not a reaction"
    where(organization_id: org_id, notifiable_type: "Comment", action: nil, user_id: nil)
  }
  scope :for_organization_mentions, lambda { |org_id|
    where(organization_id: org_id, notifiable_type: "Mention", user_id: nil)
  }

  scope :without_past_aggregations, lambda {
    where.not("notified_at < ? AND action IN ('Reaction', 'Follow')", 24.hours.ago)
  }

  class << self
    def send_new_follower_notification(follow, is_read = false)
      return unless Follow.need_new_follower_notification_for?(follow.followable_type)
      return if follow.followable_type == "User" && UserBlock.blocking?(follow.followable_id, follow.follower_id)

      follow_data = follow.attributes.slice("follower_id", "followable_id", "followable_type").symbolize_keys
      Notifications::NewFollowerJob.perform_later(follow_data, is_read)
    end

    def send_new_follower_notification_without_delay(follow, is_read = false)
      return unless Follow.need_new_follower_notification_for?(follow.followable_type)
      return if follow.followable_type == "User" && UserBlock.blocking?(follow.followable_id, follow.follower_id)

      follow_data = follow.attributes.slice("follower_id", "followable_id", "followable_type").symbolize_keys
      Notifications::NewFollowerJob.perform_now(follow_data, is_read)
    end

    def send_to_followers(notifiable, action = nil)
      Notifications::NotifiableActionJob.perform_later(notifiable.id, notifiable.class.name, action)
    end

    def send_new_comment_notifications(comment)
      return if comment.commentable_type == "PodcastEpisode"
      return if UserBlock.blocking?(comment.commentable.user_id, comment.user_id)

      Notifications::NewCommentJob.perform_later(comment.id)
    end

    def send_new_comment_notifications_without_delay(comment)
      return if comment.commentable_type == "PodcastEpisode"
      return if UserBlock.blocking?(comment.commentable.user_id, comment.user_id)

      Notifications::NewCommentJob.perform_now(comment.id)
    end

    def send_new_badge_achievement_notification(badge_achievement)
      Notifications::NewBadgeAchievementJob.perform_later(badge_achievement.id)
    end
    # NOTE: this alias is temporary until the transition to ActiveJob is completed
    # and all old DelayedJob jobs are processed by the queue workers.
    # It can be removed after pre-existing jobs are done
    alias send_new_badge_notification send_new_badge_achievement_notification

    def send_reaction_notification(reaction, receiver)
      return if reaction.skip_notification_for?(receiver)
      return if UserBlock.blocking?(receiver, reaction.user_id)

      Notifications::NewReactionJob.perform_later(*reaction_notification_attributes(reaction, receiver))
    end

    def send_reaction_notification_without_delay(reaction, receiver)
      return if reaction.skip_notification_for?(receiver)
      return if UserBlock.blocking?(receiver, reaction.user_id)

      Notifications::NewReactionJob.perform_now(*reaction_notification_attributes(reaction, receiver))
    end

    def send_mention_notification(mention)
      return if mention.mentionable_type == "User" && UserBlock.blocking?(mention.mentionable_id, mention.user_id)

      Notifications::MentionJob.perform_later(mention.id)
    end

    def send_welcome_notification(receiver_id)
      Notifications::WelcomeNotificationJob.perform_later(receiver_id)
    end

    def send_moderation_notification(notifiable)
      # TODO: make this work for articles in the future. only works for comments right now
      return if UserBlock.blocking?(notifiable.commentable.user_id, notifiable.user_id)

      Notifications::ModerationNotificationJob.perform_later(notifiable.id)
    end

    def send_tag_adjustment_notification(tag_adjustment)
      Notifications::TagAdjustmentNotificationJob.perform_later(tag_adjustment.id)
    end

    def send_milestone_notification(type:, article_id:)
      Notifications::MilestoneJob.perform_later(type, article_id)
    end

    def remove_all_by_action(notifiable_ids:, notifiable_type:, action: nil)
      return unless %w[Article Comment Mention].include?(notifiable_type) && notifiable_ids.present?

      Notifications::RemoveAllByActionJob.perform_later(notifiable_ids, notifiable_type, action)
    end

    def remove_all_by_action_without_delay(notifiable_ids:, notifiable_type:, action: nil)
      return unless %w[Article Comment Mention].include?(notifiable_type) && notifiable_ids.present?

      Notifications::RemoveAllByActionJob.perform_now(notifiable_ids, notifiable_type, action)
    end

    def remove_all(notifiable_ids:, notifiable_type:)
      return unless %w[Article Comment Mention].include?(notifiable_type) && notifiable_ids.present?

      Notifications::RemoveAllJob.perform_later(notifiable_ids, notifiable_type)
    end

    def remove_all_without_delay(notifiable_ids:, notifiable_type:)
      return unless %w[Article Comment Mention].include?(notifiable_type) && notifiable_ids.present?

      Notifications::RemoveAllJob.perform_now(notifiable_ids, notifiable_type)
    end

    def update_notifications(notifiable, action = nil)
      Notifications::UpdateJob.perform_later(notifiable.id, notifiable.class.name, action)
    end

    def fast_destroy_old_notifications(destroy_before_timestamp = 4.months.ago)
      sql = <<-SQL
        DELETE FROM notifications
        WHERE notifications.id IN (
          SELECT notifications.id
          FROM notifications
          WHERE created_at < ?
          LIMIT 50000
        )
      SQL

      notification_sql = Notification.sanitize_sql([sql, destroy_before_timestamp])

      BulkSqlDelete.delete_in_batches(notification_sql)
    end

    private

    def user_data(user)
      Notifications.user_data(user)
    end

    def comment_data(comment)
      Notifications.comment_data(comment)
    end

    def article_data(article)
      Notifications.article_data(article)
    end

    def reaction_notification_attributes(reaction, receiver)
      reactable_data = {
        reactable_id: reaction.reactable_id,
        reactable_type: reaction.reactable_type,
        reactable_user_id: reaction.reactable.user_id
      }
      receiver_data = { klass: receiver.class.name, id: receiver.id }
      [reactable_data, receiver_data]
    end

    def organization_data(organization)
      Notifications.organization_data(organization)
    end
  end

  def aggregated?
    action == "Reaction" || action == "Follow"
  end

  private

  def mark_notified_at_time
    self.notified_at = Time.current
  end
end
