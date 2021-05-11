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
  scope :unread, -> { where(read: false) }

  class << self
    def send_new_follower_notification(follow, is_read: false)
      return unless follow && Follow.need_new_follower_notification_for?(follow.followable_type)
      return if follow.followable_type == "User" && UserBlock.blocking?(follow.followable_id, follow.follower_id)

      follow_data = follow.attributes.slice("follower_id", "followable_id", "followable_type").symbolize_keys
      Notifications::NewFollowerWorker.perform_async(follow_data, is_read)
    end

    def send_new_follower_notification_without_delay(follow, is_read: false)
      return unless follow && Follow.need_new_follower_notification_for?(follow.followable_type)
      return if follow.followable_type == "User" && UserBlock.blocking?(follow.followable_id, follow.follower_id)

      follow_data = follow.attributes.slice("follower_id", "followable_id", "followable_type").symbolize_keys
      Notifications::NewFollowerWorker.new.perform(follow_data, is_read)
    end

    def send_to_mentioned_users_and_followers(notifiable, _action = nil)
      return unless notifiable.is_a?(Article) && notifiable.published?

      # We need to create associated mentions inline because they need to exist _before_ creating any
      # other Article-related notifications. This ensures that users will not receive a second notification for the
      # post being published if they have already received an initial notification about being @-mentioned in the post.
      Mentions::CreateAll.call(notifiable)

      # Kicks off a worker to send any notifications about the post being published, if necessary.
      Notification.send_to_followers(notifiable, "Published")
    end

    def send_to_followers(notifiable, action = nil)
      Notifications::NotifiableActionWorker.perform_async(notifiable.id, notifiable.class.name, action)
    end

    def send_new_comment_notifications_without_delay(comment)
      return if comment.commentable_type == "PodcastEpisode"
      return if UserBlock.blocking?(comment.commentable.user_id, comment.user_id)

      Notifications::NewComment::Send.call(comment)
    end

    def send_new_badge_achievement_notification(badge_achievement)
      Notifications::NewBadgeAchievementWorker.perform_async(badge_achievement.id)
    end

    def send_reaction_notification(reaction, receiver)
      return if reaction.skip_notification_for?(receiver)
      return if UserBlock.blocking?(receiver, reaction.user_id)

      Notifications::NewReactionWorker.perform_async(*reaction_notification_attributes(reaction, receiver))
    end

    def send_reaction_notification_without_delay(reaction, receiver)
      return if reaction.skip_notification_for?(receiver)
      return if UserBlock.blocking?(receiver, reaction.user_id)

      Notifications::NewReactionWorker.new.perform(*reaction_notification_attributes(reaction, receiver))
    end

    def send_mention_notification(mention)
      return if MentionDecorator.new(mention).mentioned_by_blocked_user?

      Notifications::MentionWorker.perform_async(mention.id)
    end

    def send_mention_notification_without_delay(mention)
      return if MentionDecorator.new(mention).mentioned_by_blocked_user?

      Notifications::NewMention::Send.call(mention) if mention
    end

    def send_welcome_notification(receiver_id, broadcast_id)
      Notifications::WelcomeNotificationWorker.perform_async(receiver_id, broadcast_id)
    end

    def send_moderation_notification(notifiable)
      # TODO: make this work for articles in the future. only works for comments right now
      return unless notifiable.commentable
      return if UserBlock.blocking?(notifiable.commentable.user_id, notifiable.user_id)

      Notifications::ModerationNotificationWorker.perform_async(notifiable.id)
    end

    def send_tag_adjustment_notification(tag_adjustment)
      Notifications::TagAdjustmentNotificationWorker.perform_async(tag_adjustment.id)
    end

    def send_milestone_notification(type:, article_id:)
      Notifications::MilestoneWorker.perform_async(type, article_id)
    end

    def remove_all_by_action_without_delay(notifiable_ids:, notifiable_type:, action: nil)
      return unless %w[Article Comment Mention].include?(notifiable_type) && notifiable_ids.present?

      Notifications::RemoveAllByAction.call(Array.wrap(notifiable_ids), notifiable_type, action)
    end

    def remove_all(notifiable_ids:, notifiable_type:)
      return unless %w[Article Comment Mention].include?(notifiable_type) && notifiable_ids.present?

      Notifications::RemoveAllWorker.perform_async(notifiable_ids, notifiable_type)
    end

    def remove_all_without_delay(notifiable_ids:, notifiable_type:)
      return unless %w[Article Comment Mention].include?(notifiable_type) && notifiable_ids.present?

      Notifications::RemoveAllWorker.new.perform(notifiable_ids, notifiable_type)
    end

    def update_notifications(notifiable, action = nil)
      Notifications::UpdateWorker.perform_async(notifiable.id, notifiable.class.name, action)
    end

    def fast_destroy_old_notifications(destroy_before_timestamp = 3.months.ago)
      sql = <<-SQL.squish
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

    def reaction_notification_attributes(reaction, receiver)
      reactable_data = {
        reactable_id: reaction.reactable_id,
        reactable_type: reaction.reactable_type,
        reactable_user_id: reaction.reactable.user_id
      }
      receiver_data = { klass: receiver.class.name, id: receiver.id }
      [reactable_data, receiver_data]
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
