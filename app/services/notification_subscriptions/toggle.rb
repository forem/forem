module NotificationSubscriptions
  class Toggle
    attr_reader :current_user, :permitted_params, :action

    def self.call(...)
      new(...).call
    end

    def initialize(current_user, permitted_params)
      @current_user = current_user
      @permitted_params = permitted_params
    end

    def call
      toggle_subscription
    end

    def toggle_subscription
      action = permitted_params[:action]

      if action == "unsubscribe"
        notification_id = permitted_params[:notification_id]
        notification = NotificationSubscription&.find(notification_id) unless notification_id.nil?
        destroy_notification(notification)
      else
        comment_id = permitted_params[:comment_id]
        article_id = permitted_params[:article_id]
        comment = Comment.find(comment_id) if comment_id.present?
        article = Article.find(article_id) if article_id.present?

        create_subscription(comment, article)
      end
    end

    private

    def destroy_notification(notification)
      notification.destroy

      if notification.destroyed?
        { destroyed: true }
      else
        { errors: notification.errors_as_sentence }
      end
    end

    def create_subscription(comment, article)
      comment_article = comment && comment.ancestry.nil? ? comment.commentable : nil
      notifiable = subscription_notifiable(comment, article, comment_article)
      notifiable_type = if comment && article.nil? && comment_article.nil?
                          "Comment"
                        elsif article.nil?
                          "Article"
                        else
                          "Article"
                        end

      subscription = NotificationSubscription.new(
        user: current_user,
        config: subscription_config(comment, article, comment_article),
        notifiable: notifiable,
        notifiable_type: notifiable_type,
      )

      if subscription.save
        { updated: true, notification: subscription.to_json }
      else
        { errors: subscription.errors_as_sentence }
      end
    end

    def subscription_notifiable(comment, article, comment_article)
      if comment && article.nil? && comment_article.nil?
        comment
      elsif article.nil?
        comment_article
      else
        article
      end
    end

    def subscription_config(comment, article)
      if article.nil?
        if comment && comment.ancestry.nil?
          "all_comments"
        else
          "top_level_comments"
        end
      else
        "all_comments"
      end
    end
  end
end
