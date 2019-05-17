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
      article = if user.has_role?(:super_admin)
                  Article.includes(:user).find(article_id)
                else
                  user.articles.find(article_id)
                end

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

      article.update!(article_params)

      article.decorate
    end

    private

    attr_reader :user, :article_id
    attr_accessor :article_params
  end
end
