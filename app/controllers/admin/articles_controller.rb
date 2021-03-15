module Admin
  class ArticlesController < Admin::ApplicationController
    layout "admin"

    after_action only: [:update] do
      Audit::Logger.log(:moderator, current_user, params.dup)
    end

    def index
      case params[:state]
      when /top-/
        months_ago = params[:state].split("-")[1].to_i.months.ago
        @articles = articles_top(months_ago)
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
      if article.update(article_params)
        flash[:success] = "Article saved!"
      else
        flash[:danger] = article.errors_as_sentence
      end
      redirect_to admin_article_path(article.id)
    end

    private

    def articles_top(months_ago)
      Article.published
        .where("published_at > ?", months_ago)
        .includes(user: [:notes])
        .limited_columns_internal_select
        .order(public_reactions_count: :desc)
        .page(params[:page])
        .per(50)
    end

    def articles_boosted_additional
      Article.boosted_via_additional_articles
        .includes(:user)
        .limited_columns_internal_select
        .order(published_at: :desc)
        .page(params[:page])
        .per(100)
    end

    def articles_chronological
      Article.published
        .includes(user: [:notes])
        .limited_columns_internal_select
        .order(published_at: :desc)
        .page(params[:page])
        .per(50)
    end

    def articles_mixed
      Article.published
        .includes(user: [:notes])
        .limited_columns_internal_select
        .order(hotness_score: :desc)
        .page(params[:page])
        .per(30)
    end

    def articles_featured
      Article.published.or(Article.where(published_from_feed: true))
        .where(featured: true)
        .where("featured_number > ?", Time.current.to_i)
        .includes(:user)
        .limited_columns_internal_select
        .order(featured_number: :desc)
    end

    def article_params
      allowed_params = %i[featured
                          social_image
                          body_markdown
                          approved
                          email_digest_eligible
                          boosted_additional_articles
                          boosted_dev_digest_email
                          main_image_background_hex_color
                          featured_number
                          user_id
                          co_author_ids_list
                          published_at]
      params.require(:article).permit(allowed_params)
    end

    def authorize_admin
      authorize Article, :access?, policy_class: InternalPolicy
    end
  end
end
