class ArticleCreationService
  attr_accessor :user, :article_params, :job_opportunity_params

  def initialize(user, article_params, job_opportunity_params)
    @user = user
    @article_params = article_params
    @job_opportunity_params = job_opportunity_params
  end

  def create!
    raise if RateLimitChecker.new(user).limit_by_situation("published_article_creation")

    article = Article.new(article_params)
    article.user_id = user.id
    article.show_comments = true
    if user.organization_id.present? && article_params[:publish_under_org].to_i == 1
      article.organization_id = user.organization_id
    end
    article.collection_id = Collection.find_series(article_params[:series], user).id if article_params[:series].present?
    create_job_opportunity(article)
    if article.save
      if article.published
        Notification.send_to_followers(article, "Published")
      end
    end
    article.decorate
  end

  def create_job_opportunity(article)
    if job_opportunity_params.present?
      job_opportunity = JobOpportunity.create(job_opportunity_params)
      article.job_opportunity = job_opportunity
      raise unless article.tag_list.include? "hiring"
    end
  end
end
