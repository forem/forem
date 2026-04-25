# Rebuilds json_data on notifications that contain stale paths after a username change.
#
# When a user changes their username, notification records still hold the old
# denormalized paths (e.g. "/old_username/comment/abc"). This service finds all
# affected notifications and refreshes their json_data using the canonical data
# builder methods in the Notifications module.
#
# Affected notifications fall into two categories:
#   1. Notifications whose notifiable is owned by the user (their articles and
#      comments contain the username in the path).
#   2. Notifications where the user appears as the actor stored in
#      json_data["user"] (e.g. someone commented on another user's article).
#
# For category 2 we fall back to a jsonb containment query because there is no
# indexed column linking the actor to the notification row.
module Notifications
  class UpdateJsonDataForUser
    BATCH_SIZE = 1000

    delegate :article_data, :comment_data, :user_data, :organization_data, to: Notifications

    def self.call(...)
      new(...).call
    end

    def initialize(user)
      @user = user
    end

    def call
      update_notifiable_owned_notifications
      update_comment_on_user_articles_notifications
      update_actor_notifications
    end

    private

    attr_reader :user

    # Category 1: Notifications where the user authored the notifiable.
    # We can query these efficiently via the polymorphic notifiable association.
    def update_notifiable_owned_notifications
      user.articles.find_each do |article|
        refresh_notifications_for(article)
      end

      user.comments.find_each do |comment|
        refresh_notifications_for(comment)
      end
    end

    # Category 1b: Notifications for comments left on the user's articles.
    # These comment notifications embed the article's path in json_data["comment"]["commentable"].
    # When the article author changes username, those paths become stale even though
    # the comment's author is a different user.
    def update_comment_on_user_articles_notifications
      user.articles.find_each do |article|
        comment_ids = Comment.where(commentable_type: "Article", commentable_id: article.id)
          .where.not(user_id: user.id)
          .pluck(:id)

        next if comment_ids.blank?

        Notification
          .where(notifiable_type: "Comment", notifiable_id: comment_ids)
          .find_each(batch_size: BATCH_SIZE) do |notification|
            comment = Comment.find_by(id: notification.notifiable_id)
            next unless comment

            notification.update_column(:json_data, build_comment_json_data(comment))
          end
      end
    end

    # Category 2: Notifications where the user appears as the actor in json_data.
    # This uses a jsonb path query to find notifications where the user's id
    # is stored as the actor in json_data["user"]["id"].
    #
    # Covers:
    #   - Reaction notifications (action: "Reaction") where the user reacted on
    #     someone else's content (notifiable is someone else's Article/Comment)
    #   - Follow notifications (notifiable_type: "Follow")
    #   - Mention notifications (notifiable_type: "Mention")
    #   - Any other notification type where the user appears as the actor
    #
    # Some of these notifications may have been refreshed by category 1/1b above.
    # The redundancy is harmless and simplifies the query logic.
    def update_actor_notifications
      Notification
        .where("json_data->'user'->>'id' = ?", user.id.to_s)
        .find_each(batch_size: BATCH_SIZE) do |notification|
          refresh_actor_notification(notification)
        end
    end

    def refresh_notifications_for(notifiable)
      scope = Notification.where(
        notifiable_id: notifiable.id,
        notifiable_type: notifiable.class.name,
      )

      case notifiable
      when Article
        refresh_article_notifications(scope, notifiable)
      when Comment
        refresh_comment_notifications(scope, notifiable)
      end
    end

    def refresh_article_notifications(scope, article)
      scope.find_each(batch_size: BATCH_SIZE) do |notification|
        new_json_data = build_article_json_data(article, notification.action)
        notification.update_column(:json_data, new_json_data)
      end
    end

    def refresh_comment_notifications(scope, comment)
      scope.find_each(batch_size: BATCH_SIZE) do |notification|
        new_json_data = build_comment_json_data(comment)
        notification.update_column(:json_data, new_json_data)
      end
    end

    # For actor notifications, we rebuild from the notifiable when possible.
    # When the notifiable no longer exists (e.g. deleted), we update only the
    # user portion of the existing json_data.
    def refresh_actor_notification(notification)
      new_json_data = rebuild_actor_json_data(notification)
      notification.update_column(:json_data, new_json_data)
    rescue StandardError => e
      # Gracefully handle errors without halting the batch
      Rails.logger.warn(
        "Notifications::UpdateJsonDataForUser: skipping notification #{notification.id}: #{e.message}",
      )
    end

    def rebuild_actor_json_data(notification)
      notifiable = notification.notifiable

      return update_user_in_json_data(notification) unless notifiable.present?

      case notifiable
      when Article
        build_article_json_data(notifiable, notification.action)
      when Comment
        build_comment_json_data(notifiable)
      when Mention
        build_mention_json_data(notifiable)
      else
        # For Follow, Reaction (aggregated), and other types, update the user
        # portion. Reaction notifications have aggregated_siblings that would
        # require the full Reactions::Send logic to rebuild; updating just the
        # primary user data is a pragmatic middle ground.
        update_user_in_json_data(notification)
      end
    end

    def build_article_json_data(article, action)
      article.reload
      data = {
        user: user_data(article.user),
        article: fresh_article_data(article),
      }
      data[:organization] = organization_data(article.organization) if article.organization
      data
    end

    def build_comment_json_data(comment)
      {
        user: user_data(comment.user),
        comment: fresh_comment_data(comment),
      }
    end

    # Notifications.article_data uses article.path which is a stored column
    # that goes stale after a username change until the article is resaved
    # (ResaveArticlesWorker runs asynchronously). Override with the correct
    # path computed from the current username.
    def fresh_article_data(article)
      article_data(article).tap do |data|
        data[:path] = computed_article_path(article)
      end
    end

    def fresh_comment_data(comment)
      comment_data(comment).tap do |data|
        commentable = comment.commentable
        next unless commentable.is_a?(Article)

        data[:commentable][:path] = computed_article_path(commentable)
      end
    end

    def computed_article_path(article)
      if article.organization
        "/#{article.organization.slug}/#{article.slug}"
      else
        "/#{article.user.username}/#{article.slug}"
      end
    end

    def build_mention_json_data(mention)
      data = { user: user_data(mention.mentionable.user) }

      case mention.mentionable_type
      when "Comment"
        data[:comment] = comment_data(mention.mentionable)
      when "Article"
        data[:article] = article_data(mention.mentionable)
      end

      data
    end

    def update_user_in_json_data(notification)
      new_json_data = notification.json_data.deep_dup
      new_json_data["user"] = user_data(user).deep_stringify_keys
      new_json_data
    end
  end
end
