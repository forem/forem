class Internal::ArticlesController < Internal::ApplicationController
  layout "internal"

  after_action only: [:update] do
    Audit::Logger.log(:moderator, current_user, params.dup)
  end

  def index
    @pending_buffer_updates = BufferUpdate.where(status: "pending").includes(:article)

    case params[:state]
    when /not\-buffered/
      days_ago = params[:state].split("-")[2].to_f
      @articles = articles_not_buffered(days_ago)
    when /top\-/
      months_ago = params[:state].split("-")[1].to_i.months.ago
      @articles = articles_top(months_ago)
    when "satellite"
      @articles = articles_satellite
    when "boosted-additional-articles"
      @articles = articles_boosted_additional
    when "chronological"
      @articles = articles_chronological
    else
      @articles = articles_mixed
      @featured_articles = articles_featured
    end
  end

  def show
    @article = Article.find(params[:id])
  end

  def update
    article = Article.find(params[:id])
    article.featured = article_params[:featured].to_s == "true"
    article.approved = article_params[:approved].to_s == "true"
    article.live_now = article_params[:live_now].to_s == "true"
    article.email_digest_eligible = article_params[:email_digest_eligible].to_s == "true"
    article.boosted_additional_articles = article_params[:boosted_additional_articles].to_s == "true"
    article.boosted_dev_digest_email = article_params[:boosted_dev_digest_email].to_s == "true"
    article.user_id = article_params[:user_id].to_i
    article.update!(article_params)
    Article.where.not(id: article.id).where(live_now: true).update_all(live_now: false) if article.live_now
    CacheBuster.bust("/live_articles")
    render body: nil
  end

  private

  def articles_not_buffered(days_ago)
    Article.published.
      where(last_buffered: nil).
      where("published_at > ? OR crossposted_at > ?", days_ago.days.ago, days_ago.days.ago).
      includes(:user).
      limited_columns_internal_select.
      order("positive_reactions_count DESC").
      page(params[:page]).
      per(50)
  end

  def articles_top(months_ago)
    Article.published.
      where("published_at > ?", months_ago).
      includes(user: [:notes]).
      limited_columns_internal_select.
      order("positive_reactions_count DESC").
      page(params[:page]).
      per(50)
  end

  def articles_satellite
    Article.published.where(last_buffered: nil).
      includes(:user, :buffer_updates).
      tagged_with(Tag.bufferized_tags, any: true).
      limited_columns_internal_select.
      order("hotness_score DESC").
      page(params[:page]).
      per(60)
  end

  def articles_boosted_additional
    Article.boosted_via_additional_articles.
      includes(:user, :buffer_updates).
      limited_columns_internal_select.
      order("published_at DESC").
      page(params[:page]).
      per(100)
  end

  def articles_chronological
    Article.published.
      includes(user: [:notes]).
      limited_columns_internal_select.
      order("published_at DESC").
      page(params[:page]).
      per(50)
  end

  def articles_mixed
    Article.published.
      includes(user: [:notes]).
      limited_columns_internal_select.
      order("hotness_score DESC").
      page(params[:page]).
      per(30)
  end

  def articles_featured
    Article.published.or(Article.where(published_from_feed: true)).
      where(featured: true).
      where("featured_number > ?", Time.current.to_i).
      includes(:user, :buffer_updates).
      limited_columns_internal_select.
      order("featured_number DESC")
  end

  def article_params
    allowed_params = %i[featured
                        social_image
                        body_markdown
                        approved
                        live_now
                        email_digest_eligible
                        boosted_additional_articles
                        boosted_dev_digest_email
                        main_image_background_hex_color
                        featured_number
                        user_id
                        last_buffered]
    params.require(:article).permit(allowed_params)
  end

  def authorize_admin
    authorize Article, :access?, policy_class: InternalPolicy
  end
end
