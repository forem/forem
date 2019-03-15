class Notification < ApplicationRecord
  belongs_to :notifiable, polymorphic: true
  belongs_to :user, optional: true
  belongs_to :organization, optional: true

  validates :user_id, presence: true, if: proc { |n| n.organization_id.nil? }
  validates :organization_id, presence: true, if: proc { |n| n.user_id.nil? }

  before_create :mark_notified_at_time

  validates :user_id, uniqueness: { scope: %i[notifiable_id notifiable_type action] }

  class << self
    def send_new_follower_notification(follow, is_read = false)
      return unless Follow.need_new_follower_notification_for?(follow.followable_type)

      recent_follows = Follow.where(followable_type: follow.followable_type, followable_id: follow.followable_id).where("created_at > ?", 24.hours.ago).order("created_at DESC")

      notification_params = { action: "Follow" }
      if follow.followable_type == "User"
        notification_params[:user_id] = follow.followable_id
      elsif follow.followable_type == "Organization"
        notification_params[:organization_id] = follow.followable_id
      end

      followers = User.where(id: recent_follows.pluck(:follower_id))
      aggregated_siblings = followers.map { |follower| user_data(follower) }
      if aggregated_siblings.size.zero?
        Notification.find_or_create_by(notification_params).destroy
      else
        json_data = { user: user_data(follow.follower), aggregated_siblings: aggregated_siblings }
        notification = Notification.find_or_create_by(notification_params)
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

      user_ids = comment.ancestors.select(:receive_notifications, :user_id).select(&:receive_notifications).pluck(:user_id).to_set
      user_ids.add(comment.commentable.user_id) if user_ids.empty? && comment.commentable.receive_notifications
      json_data = {
        user: user_data(comment.user),
        comment: comment_data(comment)
      }
      user_ids.delete(comment.user_id).each do |user_id|
        Notification.create(
          user_id: user_id,
          notifiable_id: comment.id,
          notifiable_type: comment.class.name,
          action: nil,
          json_data: json_data,
        )
        # Be careful with this basic first implementation of push notification. Has dependency of Pusher/iPhone sort of tough to test reliably.
        send_push_notifications(user_id, "@#{comment.user.username} replied to you:", comment.title, "/notifications/comments") if User.find_by(id: user_id)&.mobile_comment_notifications
      end
      return unless comment.commentable.organization_id

      Notification.create(
        organization_id: comment.commentable.organization_id,
        notifiable_id: comment.id,
        notifiable_type: comment.class.name,
        action: nil,
        json_data: json_data,
      )
      # no push notifications for organizations yet
    end
    handle_asynchronously :send_new_comment_notifications

    def send_new_badge_notification(badge_achievement)
      json_data = {
        user: user_data(badge_achievement.user),
        badge_achievement: {
          badge_id: badge_achievement.badge_id,
          rewarding_context_message: badge_achievement.rewarding_context_message,
          badge: {
            title: badge_achievement.badge.title,
            description: badge_achievement.badge.description,
            badge_image_url: badge_achievement.badge.badge_image_url
          }
        }
      }
      Notification.create(
        user_id: badge_achievement.user.id,
        notifiable_id: badge_achievement.id,
        notifiable_type: "BadgeAchievement",
        action: nil,
        json_data: json_data,
      )
    end
    handle_asynchronously :send_new_badge_notification

    def send_reaction_notification(reaction, receiver)
      return if reaction.user_id == reaction.reactable.user_id
      return if reaction.points.negative?
      return if receiver.is_a?(User) && reaction.reactable.receive_notifications == false

      aggregated_reaction_siblings = Reaction.where(reactable_id: reaction.reactable_id, reactable_type: reaction.reactable_type).
        reject { |r| r.user_id == reaction.reactable.user_id }.
        map { |r| { category: r.category, created_at: r.created_at, user: user_data(r.user) } }
      json_data = {
        user: user_data(reaction.user),
        reaction: {
          category: reaction.category,
          reactable_type: reaction.reactable_type,
          reactable_id: reaction.reactable_id,
          reactable: {
            path: reaction.reactable.path,
            title: reaction.reactable.title,
            class: {
              name: reaction.reactable.class.name
            }
          },
          aggregated_siblings: aggregated_reaction_siblings,
          updated_at: reaction.updated_at
        }
      }

      notification_params = {
        notifiable_type: reaction.reactable.class.name,
        notifiable_id: reaction.reactable.id,
        action: "Reaction"
        # user_id or organization_id: receiver.id
      }
      if receiver.is_a?(User)
        notification_params[:user_id] = receiver.id
      elsif receiver.is_a?(Organization)
        notification_params[:organization_id] = receiver.id
      end

      if aggregated_reaction_siblings.size.zero?
        notification = Notification.where(notification_params).delete_all
      else
        previous_siblings_size = 0
        notification = Notification.find_or_create_by(notification_params)
        previous_siblings_size = notification.json_data["reaction"]["aggregated_siblings"].size if notification.json_data
        notification.json_data = json_data
        notification.notified_at = Time.current
        notification.read = false if json_data[:reaction][:aggregated_siblings].size > previous_siblings_size
        notification.save!
      end
      notification
    end
    handle_asynchronously :send_reaction_notification

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
      welcome_broadcast = Broadcast.find_by(title: "Welcome Notification")
      return if welcome_broadcast.nil?

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
      # notifiable is currently only comment
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

    def should_send_milestone?(milestone_hash)
      return if milestone_hash[:article].published_at < DateTime.new(2019, 2, 25)

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
