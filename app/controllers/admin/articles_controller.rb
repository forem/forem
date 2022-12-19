module Admin
  class ArticlesController < Admin::ApplicationController
    layout "admin"

    after_action only: %i[update unpin] do
      Audit::Logger.log(:moderator, current_user, params.dup)
    end

    ARTICLES_ALLOWED_PARAMS = %i[featured
                                 social_image
                                 body_markdown
                                 approved
                                 email_digest_eligible
                                 main_image_background_hex_color
                                 user_id
                                 co_author_ids_list
                                 published_at].freeze

    def index
      case params[:state]
      when /top-/
        months_ago = params[:state].split("-")[1].to_i.months.ago
        @articles = articles_top(months_ago)
      when "chronological"
        @articles = articles_chronological
      else
        @articles = articles_mixed
        @featured_articles = articles_featured
      end

      @pinned_article = PinnedArticle.get
      @articles = @articles.where.not(id: @pinned_article) if @pinned_article
    end

    def show
      @article = Article.find(params[:id])
    end

    def update
      article = Article.find(params[:id])

      if article.update(article_params.merge(admin_update: true))
        flash[:success] = I18n.t("admin.articles_controller.saved")
      else
        flash[:danger] = article.errors_as_sentence
      end

      redirect_to admin_article_path(article.id)
    end

    def unpin
      article = Article.find(params[:id])

      PinnedArticle.remove

      respond_to do |format|
        format.html do
          flash[:danger] = I18n.t("admin.articles_controller.unpinned")
          redirect_to admin_article_path(article.id)
        end
        format.js do
          render partial: "admin/articles/individual_article", locals: { article: article }, content_type: "text/html"
        end
      end
    end

    def pin
      article = Article.find(params[:id])

      PinnedArticle.set(article)

      respond_to do |format|
        format.html do
          flash[:success] = I18n.t("admin.articles_controller.pinned")
          redirect_to admin_article_path(article.id)
        end
        format.js do
          render partial: "admin/articles/individual_article", locals: { article: article }, content_type: "text/html"
        end
      end
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
        .featured
        .where("published_at > ?", Time.current)
        .includes(:user)
        .limited_columns_internal_select
        .order(published_at: :desc)
    end

    def article_params
      params.require(:article).permit(ARTICLES_ALLOWED_PARAMS)
    end

    def authorize_admin
      authorize Article, :access?, policy_class: InternalPolicy
    end
  end
end
