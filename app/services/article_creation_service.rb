class ArticleCreationService
  def initialize(user, article_params)
    @user = user
    @article_params = article_params
  end

  def create!
    raise if RateLimitChecker.new(user).limit_by_situation("published_article_creation")

    tags = article_params[:tags]
    series = article_params[:series]
    publish_under_org = (
      article_params[:publish_under_org] == true ||
      article_params[:publish_under_org].to_i == 1
    )

    # convert tags from array to a string
    if tags.present?
      article_params.delete(:tags)
      article_params[:tag_list] = tags.join(", ")
    end

    article = Article.new(article_params)
    article.user_id = user.id
    article.show_comments = true
    article.organization = user.organization if publish_under_org
    article.collection = Collection.find_series(series, user) if series.present?

    if article.save
      Notification.send_to_followers(article, "Published") if article.published
    end
    article.decorate
  end

  private

  attr_reader :user
  attr_accessor :article_params
end
