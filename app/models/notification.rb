class Notification < ApplicationRecord
  belongs_to :notifiable, polymorphic: true
  belongs_to :user

  before_create :mark_notified_at_time

  validates :user_id, uniqueness: { scope: %i[notifiable_id notifiable_type action] }

  class << self
    def send_new_follower_notification(follow, is_read = false)
      user = follow.followable
      recent_follows = Follow.where(followable_type: "User", followable_id: user.id).where("created_at > ?", 24.hours.ago).order("created_at DESC")
      aggregated_siblings = recent_follows.map { |f| user_data(f.follower) }
      if aggregated_siblings.size.zero?
        Notification.find_or_create_by(user_id: user.id, action: "Follow").destroy
      else
        json_data = { user: user_data(follow.follower), aggregated_siblings: aggregated_siblings }
        notification = Notification.find_or_create_by(user_id: user.id, action: "Follow")
        notification.notifiable_id = recent_follows.first.id
        notification.notifiable_type = "Follow"
        notification.json_data = json_data
        notification.notified_at = Time.current
        notification.read = is_read
        notification.save!
      end
    end
    handle_asynchronously :send_new_follower_notification

    def send_to_followers(notifiable, action = nil)
      # followers is an array and not an activerecord object
      notifiable.user.followers.sort_by(&:updated_at).reverse[0..10000].each do |follower|
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
      user_ids = notifiable.ancestors.select(:receive_notifications, :user_id).select(&:receive_notifications).pluck(:user_id).to_set
      user_ids.add(notifiable.commentable.user_id) if user_ids.empty? && notifiable.commentable.receive_notifications
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
        # Be careful with this basic first implementation of push notification. Has dependency of Pusher/iPhone sort of tough to test reliably.
        if User.find_by(id: user_id)&.mobile_comment_notifications
          send_push_notifications(user_id, "@#{notifiable.user.username} replied to you:", notifiable.title, "/notifications/comments")
        end
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
      return if notifiable.user_id == notifiable.reactable.user_id
      return if notifiable.points.negative?

      aggregated_reaction_siblings = notifiable.reactable.reactions.
        reject { |r| r.user_id == notifiable.reactable.user_id }.
        map { |r| { category: r.category, created_at: r.created_at, user: user_data(r.user) } }
      json_data = {
        user: user_data(notifiable.user),
        reaction: {
          category: notifiable.category,
          reactable_type: notifiable.reactable_type,
          reactable_id: notifiable.reactable_id,
          reactable: {
            path: notifiable.reactable.path,
            title: notifiable.reactable.title,
            class: {
              name: notifiable.reactable.class.name
            }
          },
          aggregated_siblings: aggregated_reaction_siblings,
          updated_at: notifiable.updated_at
        }
      }
      if aggregated_reaction_siblings.size.zero?
        notification = Notification.where(notifiable_type: notifiable.reactable.class.name, notifiable_id: notifiable.reactable.id, action: "Reaction").destroy_all
      else
        previous_siblings_size = 0
        notification = Notification.find_or_create_by(notifiable_type: notifiable.reactable.class.name, notifiable_id: notifiable.reactable.id, action: "Reaction")
        previous_siblings_size = notification.json_data["reaction"]["aggregated_siblings"].size if notification.json_data
        notification.user_id = notifiable.reactable.user.id
        notification.json_data = json_data
        notification.notified_at = Time.current
        if json_data[:reaction][:aggregated_siblings].size > previous_siblings_size
          notification.read = false
        end
        notification.save!
      end
      notification
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

      dev_account = User.dev_account
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
      dev_account = User.dev_account
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

    def send_tag_adjustment_notification(notifiable)
      article = notifiable.article
      json_data = {
        article: { title: article.title, path: article.path },
        adjustment_type: notifiable.adjustment_type,
        status: notifiable.status,
        reason_for_adjustment: notifiable.reason_for_adjustment,
        tag_name: notifiable.tag_name
      }
      Notification.create(
        user_id: article.user_id,
        notifiable_id: notifiable.id,
        notifiable_type: notifiable.class.name,
        json_data: json_data,
      )
      article.user.update_column(:last_moderation_notification, Time.current)
    end
    handle_asynchronously :send_tag_adjustment_notification

    def remove_all(notifiable_hash)
      Notification.where(
        notifiable_id: notifiable_hash[:id],
        notifiable_type: notifiable_hash[:class_name],
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
        profile_image_90: user.profile_image_90,
        comments_count: user.comments_count,
        created_at: user.created_at
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

    def send_push_notifications(user_id, title, body, path)
      return unless ApplicationConfig["PUSHER_BEAMS_KEY"] && ApplicationConfig["PUSHER_BEAMS_KEY"].size == 64

      payload = {
        apns: {
          aps: {
            alert: {
              title: title,
              body: CGI.unescapeHTML(body.strip!)
            }
          },
          data: {
            url: "https://dev.to" + path
          }
        }
      }
      Pusher::PushNotifications.publish(interests: ["user-notifications-#{user_id}"], payload: payload)
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
