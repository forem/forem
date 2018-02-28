class Internal::ArticlesController < Internal::ApplicationController
  layout "internal"

  def index
    case params[:state]

    when "by-featured-number"
      @articles = Article.
        where(published: true).
        includes(:user).
        order("featured_number DESC").
        page(params[:page]).
        limited_columns_internal_select.
        per(50)
    when "unfeatured-by-published"
      @articles = Article.
        where(featured: false, published: true).
        includes(:user).
        order("published_at DESC").
        page(params[:page]).
        limited_columns_internal_select.
        per(50)
    when "rss"
      @articles = Article.
        where(published_from_feed: true).
        includes(:user).
        order("created_at DESC").
        page(params[:page]).
        limited_columns_internal_select.
        per(50)
    when "rss-recent"
      @articles = Article.
        where(published_from_feed: true).
        includes(:user).
        order("published_at DESC").
        page(params[:page]).
        limited_columns_internal_select.
        per(50)
    when "spam"
      @articles = Article.
        where(published: true).
        where("spaminess_rating > ?", 10).
        includes(:user).
        order("published_at DESC").
        page(params[:page]).
        limited_columns_internal_select.
        per(50)
    when /top\-/
      @articles = Article.
        where("published_at > ?", params[:state].split("-")[1].to_i.months.ago).
        includes(:user).
        order("positive_reactions_count DESC").
        page(params[:page]).
        limited_columns_internal_select.
        per(50)
    else #MIX
      @articles = Article.
        where(published: true).
        order("published_at DESC").
        page(params[:page]).
        limited_columns_internal_select.
        per(50)

      @featured_articles = Article.
        where(published: true).
        or(Article.where(published_from_feed: true)).
        where(featured: true).
        where("featured_number > ?", Time.now.to_i).
        includes(:user).
        limited_columns_internal_select.
        order("featured_number DESC")
    end

  end

  def update
    article = Article.find(params[:id])
    article.featured = article_params[:featured].to_s == "true"
    article.approved = article_params[:approved].to_s == "true"
    article.live_now = article_params[:live_now].to_s == "true"
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
                                    :approved,
                                    :live_now,
                                    :main_image_background_hex_color,
                                    :featured_number)
  end
end
