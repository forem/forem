class Notification < ApplicationRecord
  belongs_to :notifiable, polymorphic: true
  belongs_to :user, optional: true
  belongs_to :organization, optional: true

  validates :user_id, presence: true, if: proc { |n| n.organization_id.nil? }
  validates :organization_id, presence: true, if: proc { |n| n.user_id.nil? }

  before_create :mark_notified_at_time

  validates :user_id, uniqueness: { scope: %i[organization_id notifiable_id notifiable_type action] }

  class << self
    def send_new_follower_notification(follow, is_read = false)
      return unless Follow.need_new_follower_notification_for?(follow.followable_type)

      follow_data = follow.attributes.slice("follower_id", "followable_id", "followable_type").symbolize_keys
      Notifications::NewFollowerJob.perform_later(follow_data, is_read)
    end

    def send_new_follower_notification_without_delay(follow, is_read = false)
      return unless Follow.need_new_follower_notification_for?(follow.followable_type)

      follow_data = follow.attributes.slice("follower_id", "followable_id", "followable_type").symbolize_keys
      Notifications::NewFollowerJob.perform_now(follow_data, is_read)
    end

    def send_to_followers(notifiable, action = nil)
      Notifications::NotifiableActionJob.perform_later(notifiable.id, notifiable.class.name, action)
    end

    def send_to_followers_without_delay(notifiable, action = nil)
      Notifications::NotifiableActionJob.perform_now(notifiable.id, notifiable.class.name, action)
    end

    def send_new_comment_notifications(comment)
      return if comment.commentable_type == "PodcastEpisode"

      Notifications::NewCommentJob.perform_later(comment.id)
    end

    def send_new_comment_notifications_without_delay(comment)
      return if comment.commentable_type == "PodcastEpisode"

      Notifications::NewCommentJob.perform_now(comment.id)
    end

    def send_new_badge_achievement_notification(badge_achievement)
      Notifications::NewBadgeAchievementJob.perform_later(badge_achievement.id)
    end
    # NOTE: this alias is temporary until the transition to ActiveJob is completed
    # and all old DelayedJob jobs are processed by the queue workers.
    # It can be removed after pre-existing jobs are done
    alias send_new_badge_notification send_new_badge_achievement_notification

    # NOTE: this method is temporary until the transition to ActiveJob is completed
    # and all old DelayedJob jobs are processed by the queue workers.
    # It can be removed after pre-existing jobs are done
    def send_new_badge_notification_without_delay(badge_achievement)
      Notifications::NewBadgeAchievementJob.perform_now(badge_achievement.id)
    end

    def send_reaction_notification(reaction, receiver)
      return if reaction.skip_notification_for?(receiver)

      Notifications::NewReactionJob.perform_later(*reaction_notification_attributes(reaction, receiver))
    end

    def send_reaction_notification_without_delay(reaction, receiver)
      return if reaction.skip_notification_for?(receiver)

      Notifications::NewReactionJob.perform_now(*reaction_notification_attributes(reaction, receiver))
    end

    def send_mention_notification(mention)
      Notifications::MentionJob.perform_later(mention.id)
    end

    def send_mention_notification_without_delay(mention)
      Notifications::MentionJob.perform_now(mention.id)
    end

    def send_welcome_notification(receiver_id)
      Notifications::WelcomeNotificationJob.perform_later(receiver_id)
    end

    def send_welcome_notification_without_delay(receiver_id)
      Notifications::WelcomeNotificationJob.perform_now(receiver_id)
    end

    def send_moderation_notification(notifiable)
      Notifications::ModerationNotificationJob.perform_later(notifiable.id)
    end

    def send_moderation_notification_without_delay(notifiable)
      Notifications::ModerationNotificationJob.perform_now(notifiable.id)
    end

    def send_tag_adjustment_notification(tag_adjustment)
      Notifications::TagAdjustmentNotificationJob.perform_later(tag_adjustment.id)
    end

    def send_tag_adjustment_notification_without_delay(tag_adjustment)
      Notifications::TagAdjustmentNotificationJob.perform_now(tag_adjustment.id)
    end

    def send_milestone_notification(type:, article_id:)
      Notifications::MilestoneJob.perform_later(type, article_id)
    end

    def send_milestone_notification_without_delay(type:, article_id:)
      Notifications::MilestoneJob.perform_now(type, article_id)
    end

    def remove_all(notifiable_id:, notifiable_type:, action: nil)
      Notifications::RemoveAllJob.perform_later(notifiable_id, notifiable_type, action)
    end

    def remove_all_without_delay(notifiable_id:, notifiable_type:, action: nil)
      Notifications::RemoveAllJob.perform_now(notifiable_id, notifiable_type, action)
    end

    def remove_each(notifiable_collection)
      Notifications::RemoveEachJob.perform_later(notifiable_collection.pluck(:id))
    end

    def remove_each_without_delay(notifiable_collection)
      Notifications::RemoveEachJob.perform_now(notifiable_collection.pluck(:id))
    end

    def update_notifications(notifiable, action = nil)
      Notifications::UpdateJob.perform_later(notifiable.id, notifiable.class.name, action)
    end

    def update_notifications_without_delay(notifiable, action = nil)
      Notifications::UpdateJob.perform_now(notifiable.id, notifiable.class.name, action)
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

  # instance methods

  def aggregated?
    action == "Reaction" || action == "Follow"
  end

  def mark_notified_at_time
    self.notified_at = Time.current
  end
end
