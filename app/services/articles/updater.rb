module Articles
  class Updater
    def initialize(user, article_id, article_params)
      @user = user
      @article_id = article_id
      @article_params = article_params
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      article = load_article

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

      # send notification only the first time an article is published
      send_notification = article.published && article.saved_change_to_published_at.present?
      Notification.send_to_followers(article, "Published") if send_notification

      article.decorate
    end

    private

    attr_reader :user, :article_id
    attr_accessor :article_params

    def load_article
      relation = user.has_role?(:super_admin) ? Article.includes(:user) : user.articles
      relation.find(article_id)
    end
  end
end
