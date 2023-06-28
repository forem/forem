module NotificationSubscriptions
  class Subscribe
    attr_reader :current_user, :comment_id, :article_id

    def self.call(...)
      new(...).call
    end

    def initialize(current_user, comment_id: nil, article_id: nil)
      @current_user = current_user
      @article_id = article_id
      @comment_id = comment_id
    end

    def call
      subscribe_subscription
    end

    def subscribe_subscription
      create_subscription
    end

    private

    def comment
      @comment ||= Comment.find(comment_id) if comment_id.present?
    end

    def article
      @article ||= Article.find(article_id) if article_id.present?
    end

    def comment_article
      @comment_article ||= comment && comment.ancestry.nil? ? comment.commentable : nil
    end

    def notifiable
      @notifiable ||= determine_notifiable
    end

    def create_subscription
      subscription = NotificationSubscription.new(
        user: current_user,
        config: subscription_config,
        notifiable: notifiable,
      )

      if subscription.save
        { updated: true, subscription: subscription }
      else
        { errors: subscription.errors_as_sentence }
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
