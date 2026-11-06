module Admin
  class ArticlesController < Admin::ApplicationController
    layout "admin"

    after_action only: %i[update unpin] do
      Audit::Logger.log(:moderator, current_user, params.dup)
    end

    ARTICLE_ITEM_INCLUDES = [
      :favorited_by_user,
      { context_notes: :tag, user: [:roles, { notes: :author }] },
    ].freeze

    ARTICLES_ALLOWED_PARAMS = [
      :featured,
      :social_image,
      :body_markdown,
      :approved,
      :email_digest_eligible,
      :main_image_background_hex_color,
      :user_id,
      :max_score,
      :baseline_score,
      :co_author_ids_list,
      :published_at,
      { context_notes_attributes: %i[id body_markdown] },
    ].freeze

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
      if @pinned_article
        ActiveRecord::Associations::Preloader.new(
          records: [@pinned_article],
          associations: ARTICLE_ITEM_INCLUDES,
        ).call
        @articles = @articles.where.not(id: @pinned_article)
      end
      @articles = @articles.without_count

      article_ids = @articles.map(&:id)
      article_ids.concat(@featured_articles.map(&:id)) if @featured_articles
      article_ids << @pinned_article.id if @pinned_article
      preload_privileged_reaction_counts(article_ids.uniq)
    end

    def show
      @article = Article.includes(*ARTICLE_ITEM_INCLUDES).find(params[:id])
      @privileged_reactions = @article.reactions.privileged_category.includes(:user).to_a
      @countable_vomits = { @article.id => 0 }
      @privileged_reaction_counts = { @article.id => {} }

      @privileged_reactions.each do |reaction|
        @privileged_reaction_counts[@article.id][reaction.category] =
          @privileged_reaction_counts[@article.id].fetch(reaction.category, 0) + 1
        @countable_vomits[@article.id] += 1 if reaction.category == "vomit" && reaction.status != "invalid"
      end
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
          render partial: "admin/articles/article_item", locals: { article: article }, content_type: "text/html"
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
          render partial: "admin/articles/article_item", locals: { article: article }, content_type: "text/html"
        end
      end
    end

    def unfavorite
      article = Article.find(params[:id])

      Favorites::Remove.call(favoritable: article, admin: current_user)

      flash[:success] = I18n.t("admin.articles_controller.favorite_removed")
      redirect_to admin_article_path(article.id)
    end

    private

    def articles_top(months_ago)
      Article.published.from_subforem
        .where("published_at > ?", months_ago)
        .includes(*ARTICLE_ITEM_INCLUDES)
        .limited_columns_internal_select
        .order(public_reactions_count: :desc)
        .page(params[:page])
        .per(50)
    end

    def articles_chronological
      Article.published.from_subforem
        .includes(*ARTICLE_ITEM_INCLUDES)
        .limited_columns_internal_select
        .order(published_at: :desc)
        .page(params[:page])
        .per(50)
    end

    def articles_mixed
      Article.published.from_subforem
        .includes(*ARTICLE_ITEM_INCLUDES)
        .limited_columns_internal_select
        .order(hotness_score: :desc)
        .page(params[:page])
        .per(30)
    end

    def articles_featured
      Article.published.or(Article.where(published_from_feed: true))
        .featured.from_subforem
        .where("published_at > ?", Time.current)
        .includes(*ARTICLE_ITEM_INCLUDES)
        .limited_columns_internal_select
        .order(published_at: :desc)
    end

    def article_params
      params.require(:article).permit(ARTICLES_ALLOWED_PARAMS)
    end

    def authorize_admin
      authorize Article, :access?, policy_class: InternalPolicy
    end

    def preload_privileged_reaction_counts(article_ids)
      @countable_vomits = Hash.new(0)
      @privileged_reaction_counts = Hash.new { |h, k| h[k] = {} }
      return if article_ids.empty?

      Reaction.privileged_category
        .where(reactable_type: "Article", reactable_id: article_ids)
        .group(:reactable_id, :category, :status)
        .count
        .each do |(article_id, category, status), count|
          @privileged_reaction_counts[article_id][category] =
            @privileged_reaction_counts[article_id].fetch(category, 0) + count
          @countable_vomits[article_id] += count if category == "vomit" && status != "invalid"
        end
    end
  end
end
