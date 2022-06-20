module Articles
  class Updater
    Result = Struct.new(:success, :article, keyword_init: true)

    def initialize(user, article, article_params)
      @user = user
      @article = article
      @article_params = article_params
    end

    def self.call(...)
      new(...).call
    end

    def call
      user.rate_limiter.check_limit!(:article_update)

      # updated edited time only if already published and not edited by an admin
      update_edited_at = article.user == user && article.published
      # TODO: move setting published_at to Articles::Attributes
      # when publishing (draft => published), and published_at is nil or is in the past, set it to Time.current
      # except for exported articles
      publishing = !article.published && article_params[:published]
      past_published_at = !article_params[:published_at] || article_params[:published_at] < Time.current
      update_published_at = publishing && !article.published_from_feed && past_published_at
      attrs = Articles::Attributes.new(article_params, article.user)
        .for_update(update_edited_at: update_edited_at,
                    update_published_at: update_published_at)

      success = article.update(attrs)
      if success
        user.rate_limiter.track_limit_by_action(:article_update)

        if article.published && article.saved_change_to_published.blank?
          # If the article has already been published and is only being updated, then we need to create
          # mentions and send notifications to mentioned users inline via the Mentions::CreateAll service.
          Mentions::CreateAll.call(article)
        end

        # Remove any associated notifications if Article is unpublished
        if article.saved_changes["published"] == [true, false]
          Notification.remove_all_by_action_without_delay(notifiable_ids: article.id, notifiable_type: "Article",
                                                          action: "Published")
          ContextNotification.delete_by(context_id: article.id, context_type: "Article",
                                        action: "Published")

          if article.comments.exists?
            Notification.remove_all(notifiable_ids: article.comments.ids,
                                    notifiable_type: "Comment")
          end
          if article.mentions.exists?
            Notification.remove_all(notifiable_ids: article.mentions.ids,
                                    notifiable_type: "Mention")
          end
        end
      end
      Result.new(success: success, article: article.decorate)
    end

    private

    attr_reader :user, :article, :article_params
  end
end
