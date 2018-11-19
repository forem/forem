class Notification < ApplicationRecord
  belongs_to :notifiable, polymorphic: true
  belongs_to :user

  validates :user_id, uniqueness: { scope: %i[notifiable_id notifiable_type action] }

  class << self
    def send_new_follower_notification(follow)
      json_data = { user: user_data(follow.follower) }
      Notification.create(
        user_id: follow.followable.id,
        notifiable_id: follow.id,
        notifiable_type: follow.class.name,
        action: nil,
        json_data: json_data,
      )
    end
    handle_asynchronously :send_new_follower_notification

    def send_to_followers(notifiable, followers, action = nil)
      # followers is an array and not an activerecord object
      followers.sort_by(&:updated_at).reverse[0..2500].each do |follower|
        json_data = {
          user: user_data(notifiable.user),
          article: article_data(notifiable)
        }
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

    def send_new_comment_notifications(notifiable)
      user_ids = notifiable.ancestors.map(&:user_id).to_set
      user_ids.add(notifiable.commentable.user.id) if user_ids.empty?
      user_ids.delete(notifiable.user_id).each do |user_id|
        json_data = {
          user: user_data(notifiable.user),
          comment: comment_data(notifiable)
        }
        Notification.create(
          user_id: user_id,
          notifiable_id: notifiable.id,
          notifiable_type: notifiable.class.name,
          action: nil,
          json_data: json_data,
        )
      end
    end
    handle_asynchronously :send_new_comment_notifications

    def send_new_badge_notification(notifiable)
      json_data = {
        user: user_data(notifiable.user),
        badge_achievement: {
          badge_id: notifiable.badge_id,
          rewarding_context_message: notifiable.rewarding_context_message,
          badge: {
            title: notifiable.badge.title,
            description: notifiable.badge.description,
            badge_image_url: notifiable.badge.badge_image_url
          }
        }
      }
      Notification.create(
        user_id: notifiable.user.id,
        notifiable_id: notifiable.id,
        notifiable_type: "BadgeAchievement",
        action: nil,
        json_data: json_data,
      )
    end
    handle_asynchronously :send_new_badge_notification

    def send_reaction_notification(notifiable)
      json_data = {
        user: user_data(notifiable.user),
        reaction: {
          category: notifiable.category,
          reactable_type: notifiable.reactable_type,
          reactable_id: notifiable.reactable_id,
          reactable: {
            path: notifiable.reactable.path,
            title: notifiable.reactable.title
          },
          updated_at: notifiable.updated_at
        }
      }
      Notification.create(
        user_id: notifiable.reactable.user.id,
        notifiable_id: notifiable.id,
        notifiable_type: "Reaction",
        action: notifiable.category,
        json_data: json_data,
      )
    end
    handle_asynchronously :send_reaction_notification

    def send_mention_notification(notifiable)
      mentioner = notifiable.mentionable.user
      json_data = {
        user: user_data(mentioner)
      }
      json_data[:comment] = comment_data(notifiable.mentionable) if notifiable.mentionable_type == "Comment"
      Notification.create(
        user_id: notifiable.user_id,
        notifiable_id: notifiable.id,
        notifiable_type: "Mention",
        action: nil,
        json_data: json_data,
      )
    end
    handle_asynchronously :send_mention_notification

    def send_welcome_notification(receiver_id)
      welcome_broadcast = Broadcast.find_by(title: "Welcome Notification")
      return if welcome_broadcast == nil
      dev_account = User.find_by_id(ENV["DEVTO_USER_ID"])
      json_data = {
        user: user_data(dev_account),
        broadcast: {
          processed_html: welcome_broadcast.processed_html
        }
      }
      Notification.create(
        user_id: receiver_id,
        notifiable_id: welcome_broadcast.id,
        notifiable_type: "Broadcast",
        action: welcome_broadcast.type_of,
        json_data: json_data,
      )
    end
    handle_asynchronously :send_welcome_notification

    def send_moderation_notification(notifiable)
      available_moderators = User.with_role(:trusted).where("last_moderation_notification < ?", 28.hours.ago)
      return if available_moderators.empty?
      moderator = available_moderators.sample
      dev_account = User.find_by_id(ENV["DEVTO_USER_ID"])
      json_data = {
        user: user_data(dev_account)
      }
      json_data[notifiable.class.name.downcase] = send "#{notifiable.class.name.downcase}_data", notifiable
      Notification.create(
        user_id: moderator.id,
        notifiable_id: notifiable.id,
        notifiable_type: notifiable.class.name,
        action: "Moderation",
        json_data: json_data,
      )
      moderator.update_column(:last_moderation_notification, Time.current)
    end
    handle_asynchronously :send_moderation_notification

    def remove_all(notifiable_hash)
      Notification.where(
        notifiable_id: notifiable_hash[:id],
        notifiable_type: notifiable_hash[:class_name],
        action: notifiable_hash[:action],
      ).destroy_all
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
      notifications.update_all(json_data: new_json_data)
    end
    handle_asynchronously :update_notifications

    private

    def user_data(user)
      {
        id: user.id,
        class: { name: "User" },
        name: user.name,
        username: user.username,
        path: user.path,
        profile_image_90: user.profile_image_90
      }
    end

    def comment_data(comment)
      {
        id: comment.id,
        class: { name: "Comment" },
        path: comment.path,
        processed_html: comment.processed_html,
        updated_at: comment.updated_at,
        commentable: {
          id: comment.commentable.id,
          title: comment.commentable.title,
          path: comment.commentable.path,
          class: {
            name: comment.commentable.class.name
          }
        }
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
  end

  # instance methods

  def aggregation_format
    if notifiable_type == "Reaction"
      "#{created_at.beginning_of_day}-#{created_at.end_of_day}_#{json_data['reaction']['reactable_id']}_#{json_data['reaction']['reactable_type']}"
    elsif notifiable_type == "Follow"
      "#{created_at.beginning_of_day}-#{created_at.end_of_day}"
    end
  end
end
