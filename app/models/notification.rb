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
        article: article_data(notifiable)
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
      article = tag_adjustment.article
      json_data = {
        article: { title: article.title, path: article.path },
        adjustment_type: tag_adjustment.adjustment_type,
        status: tag_adjustment.status,
        reason_for_adjustment: tag_adjustment.reason_for_adjustment,
        tag_name: tag_adjustment.tag_name
      }
      Notification.create(
        user_id: article.user_id,
        notifiable_id: tag_adjustment.id,
        notifiable_type: tag_adjustment.class.name,
        json_data: json_data,
      )
      article.user.update_column(:last_moderation_notification, Time.current)
    end
    handle_asynchronously :send_tag_adjustment_notification

    def send_milestone_notification(milestone_hash)
      milestone_hash[:next_milestone] = next_milestone(milestone_hash)
      return unless should_send_milestone?(milestone_hash)

      json_data = { article: article_data(milestone_hash[:article]), gif_id: RandomGif.new.random_id }

      Notification.create!(
        user_id: milestone_hash[:article].user_id,
        notifiable_id: milestone_hash[:article].id,
        notifiable_type: "Article",
        json_data: json_data,
        action: "Milestone::#{milestone_hash[:type]}::#{milestone_hash[:next_milestone]}",
      )
      return unless milestone_hash[:article].organization_id

      Notification.create!(
        organization_id: milestone_hash[:article].organization_id,
        notifiable_id: milestone_hash[:article].id,
        notifiable_type: "Article",
        json_data: json_data,
        action: "Milestone::#{milestone_hash[:type]}::#{milestone_hash[:next_milestone]}",
      )
    end
    handle_asynchronously :send_milestone_notification

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
      notifications = Notification.where(
        notifiable_id: notifiable.id,
        notifiable_type: notifiable.class.name,
        action: action,
      )
      return if notifications.blank?

      new_json_data = notifications.first.json_data
      new_json_data[notifiable.class.name.downcase] = send("#{notifiable.class.name.downcase}_data", notifiable)
      new_json_data[:user] = user_data(notifiable.user)
      new_json_data[:organization] = organization_data(notifiable.organization) if notifiable.is_a?(Article) && notifiable.organization_id
      notifications.update_all(json_data: new_json_data)
    end
    handle_asynchronously :update_notifications

    private

    def user_data(user)
      Notifications.user_data(user)
    end

    def comment_data(comment)
      Notifications.comment_data(comment)
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
      {
        id: organization.id,
        class: { name: "Organization" },
        name: organization.name,
        slug: organization.slug,
        path: organization.path,
        profile_image_90: organization.profile_image_90
      }
    end

    def article_data(article)
      {
        id: article.id,
        cached_tag_list_array: article.decorate.cached_tag_list_array,
        class: { name: "Article" },
        title: article.title,
        path: article.path,
        updated_at: article.updated_at
      }
    end

    def should_send_milestone?(milestone_hash)
      return if milestone_hash[:article].published_at < Time.zone.local(2019, 2, 25)

      last_milestone_notification = Notification.find_by(
        user_id: milestone_hash[:article].user_id,
        notifiable_type: "Article",
        notifiable_id: milestone_hash[:article].id,
        action: "Milestone::#{milestone_hash[:type]}::#{milestone_hash[:next_milestone]}",
      )

      if milestone_hash[:type] == "View"
        last_milestone_notification.blank? && milestone_hash[:article].page_views_count > milestone_hash[:next_milestone]
      elsif milestone_hash[:type] == "Reaction"
        last_milestone_notification.blank? && milestone_hash[:article].positive_reactions_count > milestone_hash[:next_milestone]
      end
    end

    def next_milestone(milestone_hash)
      case milestone_hash[:type]
      when "View"
        milestones = [1024, 2048, 4096, 8192, 16_384, 32_768, 65_536, 131_072, 262_144, 524_288, 1_048_576]
        milestone_count = milestone_hash[:article].page_views_count
      when "Reaction"
        milestones = [64, 128, 256, 512, 1024, 2048, 4096, 8192]
        milestone_count = milestone_hash[:article].positive_reactions_count
      end

      closest_number = milestones.min_by { |num| (milestone_count - num).abs }
      if milestone_count > closest_number
        closest_number
      else
        milestones[milestones.index(closest_number) - 1]
      end
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
