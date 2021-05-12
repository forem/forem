module Articles
  class Updater
    Result = Struct.new(:success, :article, keyword_init: true)

    def initialize(user, article, article_params, event_dispatcher = Webhook::DispatchEvent)
      @user = user
      @article = article
      @article_params = article_params
      @event_dispatcher = event_dispatcher
    end

    def self.call(...)
      new(...).call
    end

    def call
      user.rate_limiter.check_limit!(:article_update)

      # Grab the state of the article's "publish" status before making any further updates to it.
      was_previously_published = article.published

      # updated edited time only if already published and not edited by an admin
      update_edited_at = article.user == user && article.published
      attrs = Articles::Attributes.new(article_params, article.user).for_update(update_edited_at: update_edited_at)

      success = article.update(attrs)

      if success
        user.rate_limiter.track_limit_by_action(:article_update)

        if article.published && article.saved_change_to_published_at.present?
          # The first time that an article is published, we want to send notifications to any mentioned users first,
          # and then send notifications to any users who follow the article's author so as to avoid double mentions.
          Notification.send_to_mentioned_users_and_followers(article)
        elsif article.published
          # If the article has already been published and is only being updated, then we need to create
          # mentions and send notifications to mentioned users inline via the Mentions::CreateAll service.
          Mentions::CreateAll.call(article)
        end

        # Remove any associated notifications if Article is unpublished
        if article.saved_changes["published"] == [true, false]
          Notification.remove_all_by_action_without_delay(notifiable_ids: article.id, notifiable_type: "Article",
                                                          action: "Published")

          if article.comments.exists?
            Notification.remove_all(notifiable_ids: article.comments.ids,
                                    notifiable_type: "Comment")
          end
          if article.mentions.exists?
            Notification.remove_all(notifiable_ids: article.comments.ids,
                                    notifiable_type: "Article")
          end
        end

        # Do not notify if the article was previously already in a published state or is continually unpublished.
        dispatch_event(article) if article.published || was_previously_published
      end
      Result.new(success: success, article: article.decorate)
    end

    private

    attr_reader :user, :article, :article_params, :event_dispatcher

    def dispatch_event(article)
      event_dispatcher.call("article_updated", article)
    end
  end
end
