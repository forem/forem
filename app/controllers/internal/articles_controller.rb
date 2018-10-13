class Internal::ArticlesController < Internal::ApplicationController
  layout "internal"

  def index
    case params[:state]

    when /not\-buffered/
      days_ago = params[:state].split("-")[2].to_f
      @articles = Article.
        where(last_buffered: nil).
        includes(:user).
        includes(:buffer_updates).
        order("positive_reactions_count DESC").
        page(params[:page]).
        where("published_at > ? OR crossposted_at > ?", days_ago.days.ago, days_ago.days.ago).
        limited_columns_internal_select.
        per(50)
    when /top\-/
      @articles = Article.
        where("published_at > ?", params[:state].split("-")[1].to_f.months.ago).
        includes(:user).
        includes(:buffer_updates).
        order("positive_reactions_count DESC").
        page(params[:page]).
        limited_columns_internal_select.
        per(50)
    when "boosted-additional-articles"
      @articles = Article.
        includes(:user).
        order("published_at DESC").
        includes(:buffer_updates).
        boosted_via_additional_articles.
        page(params[:page]).
        per(100).
        limited_columns_internal_select
    when "chronological"
      @articles = Article.
        where(published: true).
        order("published_at DESC").
        page(params[:page]).
        limited_columns_internal_select.
        per(50)
    else # MIX
      @articles = Article.
        where(published: true).
        order("hotness_score DESC").
        page(params[:page]).
        limited_columns_internal_select.
        per(50)

      @featured_articles = Article.
        where(published: true).
        or(Article.where(published_from_feed: true)).
        where(featured: true).
        where("featured_number > ?", Time.now.to_i).
        includes(:user).
        includes(:buffer_updates).
        limited_columns_internal_select.
        order("featured_number DESC")
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
    article.update!(article_params)
    if article.live_now
      Article.where.not(id: article.id).where(live_now: true).update_all(live_now: false)
    end
    CacheBuster.new.bust "/live_articles"
    # raise
    render body: nil
    # redirect_to "/internal/articles"
  end

  private

  def article_params
    params.require(:article).permit(:featured,
                                    :social_image,
                                    :body_markdown,
                                    :approved,
                                    :live_now,
                                    :email_digest_eligible,
                                    :boosted_additional_articles,
                                    :boosted_dev_digest_email,
                                    :main_image_background_hex_color,
                                    :featured_number)
  end
end
