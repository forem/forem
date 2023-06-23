module Articles
  class Updater
    Result = Struct.new(:success, :article, keyword_init: true)

    def self.call(...)
      new(...).call
    end

    def initialize(user, article, article_params)
      @user = user
      @article = article
      @article_params = normalize_params(article_params)
    end

    def call
      user.rate_limiter.check_limit!(:article_update)
      success = article.update(article_params)

      if success
        user.rate_limiter.track_limit_by_action(:article_update)

        remove_all_notifications if became_unpublished?
        send_to_mentioned_users_and_followers if remains_published?
        refresh_auto_audience_segments if became_published?
      end

      Result.new(success: success, article: article.decorate)
    end

    private

    attr_reader :user, :article, :article_params

    def normalize_params(original_params)
      article_params = original_params.dup

      # updated edited time only if already published and not edited by an admin
      update_edited_at = article.user == user && article.published

      # remove published_at values received from a user if an articles was published before (has past published_at)
      # published_at will remain as it was in this case
      article_params.delete :published_at if article.published_at && !article.scheduled?

      # NOTE: It's surprising that this is article.user and not @user
      Articles::Attributes.new(article_params, article.user)
        .for_update(update_edited_at: update_edited_at)
    end

    def refresh_auto_audience_segments
      user.refresh_auto_audience_segments
    end

    def became_published?
      article.published? && !article.published_previously_was
    end

    def remains_published?
      article.published && article.saved_change_to_published.blank?
    end

    def became_unpublished?
      article.saved_changes["published"] == [true, false]
    end

    # If the article has already been published and is only being updated, then we need to create
    # mentions and send notifications to mentioned users inline via the Mentions::CreateAll service.
    def send_to_mentioned_users_and_followers
      Mentions::CreateAll.call(article)
    end

    # Remove any associated notifications if Article is unpublished
    def remove_all_notifications
      Notification.remove_all_by_action_without_delay(notifiable_ids: article.id, notifiable_type: "Article",
                                                      action: "Published")
      ContextNotification.delete_by(context_id: article.id, context_type: "Article",
                                    action: "Published")

      if article.comments.exists?
        Notification.remove_all(notifiable_ids: article.comments.ids,
                                notifiable_type: "Comment")
      end
      return unless article.mentions.exists?

      Notification.remove_all(notifiable_ids: article.mentions.ids,
                              notifiable_type: "Mention")
    end
  end
end
