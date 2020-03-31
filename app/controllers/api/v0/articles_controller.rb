module Api
  module V0
    class ArticlesController < ApiController
      before_action :authenticate_with_api_key_or_current_user!, only: %i[create update]
      before_action :authenticate!, only: :me
      before_action -> { doorkeeper_authorize! :public }, only: %w[index show], if: -> { doorkeeper_token }

      before_action :validate_article_param_is_hash, only: %w[create update]

      before_action :set_cache_control_headers, only: %i[index show]

      skip_before_action :verify_authenticity_token, only: %i[create update]

      def index
        @articles = ArticleApiIndexService.new(params).get
        @articles = @articles.select(INDEX_ATTRIBUTES_FOR_SERIALIZATION).decorate

        set_surrogate_key_header Article.table_key, @articles.map(&:record_key)
      end

      def show
        @article = Article.published.
          includes(:user).
          select(SHOW_ATTRIBUTES_FOR_SERIALIZATION).
          find(params[:id]).
          decorate

        set_surrogate_key_header @article.record_key
      end

      def create
        @article = Articles::Creator.call(@user, article_params).decorate

        if @article.persisted?
          render "show", status: :created, location: @article.url
        else
          message = @article.errors.full_messages.join(", ")
          render json: { error: message, status: 422 }, status: :unprocessable_entity
        end
      end

      def update
        @article = Articles::Updater.call(@user, params[:id], article_params)
        render "show", status: :ok
      end

      def me
        doorkeeper_scope = %w[unpublished all].include?(params[:status]) ? :read_articles : :public
        doorkeeper_authorize! doorkeeper_scope if doorkeeper_token

        per_page = (params[:per_page] || 30).to_i
        num = [per_page, 1000].min

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

        @articles = @articles.
          includes(:organization).
          select(ME_ATTRIBUTES_FOR_SERIALIZATION).
          order(published_at: :desc, created_at: :desc).
          page(params[:page]).
          per(num).
          decorate
      end

      INDEX_ATTRIBUTES_FOR_SERIALIZATION = %i[
        id user_id organization_id collection_id
        title description main_image published_at crossposted_at social_image
        cached_tag_list slug path canonical_url comments_count
        positive_reactions_count created_at edited_at last_comment_at published
        updated_at video_thumbnail_url
      ].freeze
      private_constant :INDEX_ATTRIBUTES_FOR_SERIALIZATION

      SHOW_ATTRIBUTES_FOR_SERIALIZATION = [
        *INDEX_ATTRIBUTES_FOR_SERIALIZATION, :body_markdown, :processed_html
      ].freeze
      private_constant :SHOW_ATTRIBUTES_FOR_SERIALIZATION

      ME_ATTRIBUTES_FOR_SERIALIZATION = %i[
        id user_id organization_id
        title description main_image published published_at cached_tag_list
        slug path canonical_url comments_count positive_reactions_count
        page_views_count crossposted_at body_markdown updated_at
      ].freeze
      private_constant :ME_ATTRIBUTES_FOR_SERIALIZATION

      private

      def article_params
        allowed_params = [
          :title, :body_markdown, :published, :series,
          :main_image, :canonical_url, :description, tags: []
        ]
        allowed_params << :organization_id if params.dig("article", "organization_id") && allowed_to_change_org_id?
        params.require(:article).permit(allowed_params)
      end

      def allowed_to_change_org_id?
        potential_user = @article&.user || @user
        if @article.nil? || OrganizationMembership.exists?(user: potential_user, organization_id: params.dig("article", "organization_id"))
          OrganizationMembership.exists?(user: potential_user, organization_id: params.dig("article", "organization_id"))
        elsif potential_user == @user
          potential_user.org_admin?(params.dig("article", "organization_id")) ||
            @user.any_admin?
        end
      end

      def validate_article_param_is_hash
        return if params.to_unsafe_h.dig(:article).is_a?(Hash)

        message = "article param must be a JSON object. You provided article as a #{params[:article].class.name}"
        render json: { error: message, status: 422 }, status: :unprocessable_entity
      end
    end
  end
end
