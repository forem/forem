module Articles
  class Updater
    def initialize(user, article_id, article_params, event_dispatcher = Webhook::DispatchEvent)
      @user = user
      @article_id = article_id
      @article_params = article_params
      @event_dispatcher = event_dispatcher
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      rate_limiter.check_limit!(:article_update)

      article = load_article
      was_published = article.published

      # the client can change the series the article belongs to
      if article_params.key?(:series)
        series = article_params[:series]
        article.collection = Collection.find_series(series, article.user) if series.present?
        article.collection = nil if series.nil?
      end

      # convert tags from array to a string
      tags = article_params[:tags]
      if tags.present?
        article_params[:tag_list] = tags.join(", ")
        article_params.delete(:tags)
      end

      # updated edited time only if already published and not edited by an admin
      update_edited_at = article.user == user && article.published
      article_params[:edited_at] = Time.current if update_edited_at

      article.update!(article_params)
      rate_limiter.track_article_updates

      # send notification only the first time an article is published
      send_notification = article.published && article.saved_change_to_published_at.present?
      Notification.send_to_followers(article, "Published") if send_notification

      # remove related notifications if unpublished
      if article.saved_changes["published"] == [true, false]
        Notification.remove_all_by_action_without_delay(notifiable_ids: article.id, notifiable_type: "Article", action: "Published")
        Notification.remove_all(notifiable_ids: article.comments.pluck(:id), notifiable_type: "Comment") if article.comments.exists?
      end
      # don't send only if article keeps being unpublished
      dispatch_event(article) if article.published || was_published

      article.decorate
    end

    private

    attr_reader :user, :article_id, :article_params, :event_dispatcher

    def rate_limiter
      RateLimitChecker.new(user)
    end

    def dispatch_event(article)
      event_dispatcher.call("article_updated", article)
    end

    def load_article
      relation = user.has_role?(:super_admin) ? Article.includes(:user) : user.articles
      relation.find(article_id)
    end
  end
end
