module Api
  module ArticlesController
    extend ActiveSupport::Concern

    INDEX_ATTRIBUTES_FOR_SERIALIZATION = %i[
      id user_id organization_id collection_id
      title description main_image published_at crossposted_at social_image
      cached_tag_list slug path canonical_url comments_count
      public_reactions_count created_at edited_at last_comment_at published
      updated_at video_thumbnail_url reading_time
    ].freeze

    SHOW_ATTRIBUTES_FOR_SERIALIZATION = [
      *INDEX_ATTRIBUTES_FOR_SERIALIZATION, :body_markdown, :processed_html
    ].freeze
    private_constant :SHOW_ATTRIBUTES_FOR_SERIALIZATION

    ME_ATTRIBUTES_FOR_SERIALIZATION = %i[
      id user_id organization_id
      title description main_image published published_at cached_tag_list
      slug path canonical_url comments_count public_reactions_count
      page_views_count crossposted_at body_markdown updated_at reading_time
    ].freeze
    private_constant :ME_ATTRIBUTES_FOR_SERIALIZATION

    def index
      @articles = ArticleApiIndexService.new(params).get
      @articles = @articles.select(INDEX_ATTRIBUTES_FOR_SERIALIZATION).decorate

      set_surrogate_key_header Article.table_key, @articles.map(&:record_key)
    end

    def show
      @article = Article.published
        .includes(user: :profile)
        .select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)
        .find(params[:id])
        .decorate

      set_surrogate_key_header @article.record_key
    end

    def show_by_slug
      @article = Article.published
        .select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)
        .find_by!(path: "/#{params[:username]}/#{params[:slug]}")
        .decorate

      set_surrogate_key_header @article.record_key
      render "show"
    end

    def create
      authorize(Article)

      @article = Articles::Creator.call(@user, article_params).decorate

      if @article.persisted?
        render "show", status: :created, location: @article.url
      else
        message = @article.errors_as_sentence
        render json: { error: message, status: 422 }, status: :unprocessable_entity
      end
    end

    def update
      articles_relation = @user.super_admin? ? Article.includes(:user) : @user.articles
      article = articles_relation.find(params[:id])

      result = Articles::Updater.call(@user, article, article_params)

      @article = result.article

      if result.success
        render "show", status: :ok
      else
        message = @article.errors_as_sentence
        render json: { error: message, status: 422 }, status: :unprocessable_entity
      end
    end

    def me
      per_page = (params[:per_page] || 30).to_i
      num = [per_page, per_page_max].min

      @articles = case params[:status]
                  when "published"
                    @user.articles.published
                  when "unpublished"
                    @user.articles.unpublished
                  when "all"
                    @user.articles
                  else
                    @user.articles.published
                  end

      @articles = @articles
        .includes(:organization)
        .select(ME_ATTRIBUTES_FOR_SERIALIZATION)
        .order(published_at: :desc, created_at: :desc)
        .page(params[:page])
        .per(num)
        .decorate
    end

    def unpublish
      @article = Article.find(params[:id])

      authorize @article, :revoke_publication?

      if Articles::Unpublish.call(@user, @article)
        payload = { action: "api_article_unpublish", article_id: @article.id }
        Audit::Logger.log(:admin_api, @user, payload)

        render status: :no_content
      else
        render json: { message: @article.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def per_page_max
      (ApplicationConfig["API_PER_PAGE_MAX"] || 1000).to_i
    end

    def article_params
      allowed_params = [
        :title, :body_markdown, :published, :series,
        :main_image, :canonical_url, :description, { tags: [] }
      ]
      allowed_params << :organization_id if params.dig("article", "organization_id") && allowed_to_change_org_id?
      params.require(:article).permit(allowed_params)
    end

    def allowed_to_change_org_id?
      potential_user = @article&.user || @user
      if @article.nil? || OrganizationMembership.exists?(user: potential_user,
                                                         organization_id: params.dig("article", "organization_id"))
        OrganizationMembership.exists?(user: potential_user,
                                       organization_id: params.dig("article", "organization_id"))
      elsif potential_user == @user
        potential_user.org_admin?(params.dig("article", "organization_id")) ||
          @user.any_admin?
      end
    end

    def validate_article_param_is_hash
      return if params.to_unsafe_h[:article].is_a?(Hash)

      message = I18n.t("api.v0.articles_controller.must_be_json", type: params[:article].class.name)
      render json: { error: message, status: 422 }, status: :unprocessable_entity
    end
  end
end
