module Articles
  class Creator
    def initialize(user, article_params, event_dispatcher = Webhook::DispatchEvent)
      @user = user
      @article_params = article_params
      @event_dispatcher = event_dispatcher
    end

    def self.call(...)
      new(...).call
    end

    def call
      rate_limit!

      article = save_article

      if article.persisted?
        # Subscribe author to notifications for all comments on their article.
        NotificationSubscription.create(user: user, notifiable_id: article.id, notifiable_type: "Article",
                                        config: "all_comments")

        # Send notifications to any mentioned users, followed by any users who follow the article's author.
        Notification.send_to_mentioned_users_and_followers(article) if article.published?
        dispatch_event(article)
      end

      article
    end

    private

    attr_reader :user, :article_params, :event_dispatcher

    def rate_limit!
      rate_limit_to_use = if user.decorate.considered_new?
                            :published_article_antispam_creation
                          else
                            :published_article_creation
                          end

      user.rate_limiter.check_limit!(rate_limit_to_use)
    end

    def dispatch_event(article)
      return unless article.published?

      event_dispatcher.call("article_created", article)
    end

    def save_article
      series = article_params[:series]
      tags = article_params[:tags]

      # convert tags from array to a string
      if tags.present?
        article_params.delete(:tags)
        article_params[:tag_list] = tags.join(", ")
      end

      article = Article.new(article_params)
      article.user_id = user.id
      article.show_comments = true
      article.collection = Collection.find_series(series, user) if series.present?
      article.save
      article
    end
  end
end
