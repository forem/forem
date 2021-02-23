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
      user.rate_limiter.check_limit!(:article_update)

      article = load_article
      was_published = article.published

      # updated edited time only if already published and not edited by an admin
      update_edited_at = article.user == user && article.published
      article_params[:edited_at] = Time.current if update_edited_at

      attrs = Articles::Attributes.new(article_params, user).for_update

      article.update!(attrs)

      user.rate_limiter.track_limit_by_action(:article_update)

      # send notification only the first time an article is published
      send_notification = article.published && article.saved_change_to_published_at.present?
      Notification.send_to_followers(article, "Published") if send_notification

      # remove related notifications if unpublished
      if article.saved_changes["published"] == [true, false]
        Notification.remove_all_by_action_without_delay(notifiable_ids: article.id, notifiable_type: "Article",
                                                        action: "Published")
        if article.comments.exists?
          Notification.remove_all(notifiable_ids: article.comments.ids,
                                  notifiable_type: "Comment")
        end
      end
      # don't send only if article keeps being unpublished
      dispatch_event(article) if article.published || was_published

      article.decorate
    end

    private

    attr_reader :user, :article_id, :article_params, :event_dispatcher

    def dispatch_event(article)
      event_dispatcher.call("article_updated", article)
    end

    def load_article
      relation = user.has_role?(:super_admin) ? Article.includes(:user) : user.articles
      relation.find(article_id)
    end
  end
end
