module NotificationSubscriptions
  class Subscribe
    attr_reader :current_user, :permitted_params

    def self.call(...)
      new(...).call
    end

    def initialize(current_user, permitted_params)
      @current_user = current_user
      @permitted_params = permitted_params
    end

    def call
      subscribe_subscription
    end

    def subscribe_subscription
      create_subscription
    end

    private

    def comment
      @comment ||= Comment.find(permitted_params[:comment_id]) if permitted_params[:comment_id].present?
    end

    def article
      @article ||= Article.find(permitted_params[:article_id]) if permitted_params[:article_id].present?
    end

    def comment_article
      @comment_article ||= comment && comment.ancestry.nil? ? comment.commentable : nil
    end

    def notifiable_type
      @notifiable_type ||= determine_notifiable_type
    end

    def notifiable
      @notifiable ||= determine_notifiable
    end

    def create_subscription
      subscription = NotificationSubscription.new(
        user: current_user,
        config: subscription_config,
        notifiable: notifiable,
        notifiable_type: notifiable_type,
      )

      if subscription.save
        { updated: true, notification: subscription.to_json }
      else
        { errors: subscription.errors_as_sentence }
      end
    end

    def determine_notifiable_type
      if comment && article.nil? && comment_article.nil?
        "Comment"
      elsif article.nil?
        "Article"
      else
        "Article"
      end
    end

    def determine_notifiable
      if comment && article.nil? && comment_article.nil?
        comment
      elsif article.nil?
        comment_article
      else
        article
      end
    end

    def subscribing_to_comment?
      article.nil? && comment.present?
    end

    def subscribing_to_top_comment?
      subscribing_to_comment? && comment.ancestry.present?
    end

    def subscription_config
      subscribing_to_top_comment? ? "top_level_comments" : "all_comments"
    end
  end
end
