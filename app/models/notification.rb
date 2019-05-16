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
      # for now, arguments are always: notifiable = article, action = "Published"
      json_data = {
        user: user_data(notifiable.user),
        article: Notifications.article_data(notifiable)
      }
      followers = if notifiable.organization_id
                    json_data[:organization] = organization_data(notifiable.organization)
                    (notifiable.user.followers + notifiable.organization.followers).uniq
                  else
                    notifiable.user.followers
                  end
      # followers is an array and not an activerecord object
      followers.sort_by(&:updated_at).reverse[0..10_000].each do |follower|
        Notification.create(
          user_id: follower.id,
          notifiable_id: notifiable.id,
          notifiable_type: notifiable.class.name,
          action: action,
          json_data: json_data,
        )
      end
    end
    handle_asynchronously :send_to_followers

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
      mentioner = mention.mentionable.user
      json_data = {
        user: user_data(mentioner)
      }
      json_data[:comment] = comment_data(mention.mentionable) if mention.mentionable_type == "Comment"
      Notification.create(
        user_id: mention.user_id,
        notifiable_id: mention.id,
        notifiable_type: "Mention",
        action: nil,
        json_data: json_data,
      )
    end
    handle_asynchronously :send_mention_notification

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

    def send_milestone_notification(milestone_hash)
      Notifications::MilestoneJob.perform_later(milestone_hash)
    end

    def send_milestone_notification_without_delay(milestone_hash)
      Notifications::MilestoneJob.perform_now(milestone_hash)
    end

    def remove_all(notifiable_hash)
      Notification.where(
        notifiable_id: notifiable_hash[:notifiable_id],
        notifiable_type: notifiable_hash[:notifiable_type],
        action: notifiable_hash[:action],
      ).delete_all
    end
    handle_asynchronously :remove_all

    def remove_each(notifiable_collection, action = nil)
      # only used for mentions since it's an array
      notifiable_collection.each do |notifiable|
        Notification.where(
          notifiable_id: notifiable.id,
          notifiable_type: notifiable.class.name,
          action: action,
        ).destroy_all
      end
    end
    handle_asynchronously :remove_each

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
