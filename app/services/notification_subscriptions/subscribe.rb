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
      raise ArgumentError.new("missing notifiable") if notifiable.blank?
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

    private

    def comment
      @comment ||= Comment.find(comment_id) if comment_id.present?
    end

    def article
      @article ||= Article.find(article_id) if article_id.present?
    end

    def notifiable
      @notifiable ||= determine_notifiable
    end

    def determine_notifiable
      comment || article
    end

    def subscription_config
      "all_comments"
    end
  end
end
