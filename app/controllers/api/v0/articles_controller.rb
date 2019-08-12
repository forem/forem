module Api
  module V0
    class ArticlesController < ApiController
      respond_to :json

      before_action :authenticate!, only: %i[create update me]

      before_action :set_cache_control_headers, only: [:index]
      caches_action :show,
                    cache_path: proc { |c| c.params.permit! },
                    expires_in: 5.minutes

      before_action :cors_preflight_check
      after_action :cors_set_access_control_headers

      # skip CSRF checks for create and update
      skip_before_action :verify_authenticity_token, only: %i[create update]

      def index
        @articles = ArticleApiIndexService.new(params).get

        key_headers = [
          "articles_api",
          params[:tag],
          params[:page],
          params[:username],
          params[:signature],
          params[:state],
        ]
        set_surrogate_key_header key_headers.join("_")
      end

      def show
        @article = Article.published.includes(:user).find(params[:id]).decorate
      end

      def onboarding
        tag_list = if params[:tag_list].present?
                     params[:tag_list].split(",")
                   else
                     %w[career discuss productivity]
                   end
        @articles = Array.new(4) { Suggester::Articles::Classic.new.get(tag_list) }
        Article.tagged_with(tag_list, any: true).
          order("published_at DESC").
          where("positive_reactions_count > ? OR comments_count > ? AND published = ?", 10, 3, true).
          limit(15).each do |article|
            @articles << article
          end
        @articles = @articles.uniq.sample(6)
      end

      def create
        @article = ArticleCreationService.new(@user, article_params).create!
        render "show", status: :created, location: @article.url
      end

      def update
        @article = Articles::Updater.call(@user, params[:id], article_params)
        render "show", status: :ok
      end

      def me
        per_page = (params[:per_page] || 30).to_i
        num = [per_page, 1000].min
        @articles = @user.articles.order("published_at DESC").
          page(params[:page]).
          per(num).
          decorate
      end

      private

      def article_params
        allowed_params = [
          :title, :body_markdown, :published, :series,
          :main_image, :canonical_url, :description, tags: []
        ]
        allowed_params << :organization_id if params["article"]["organization_id"] && allowed_to_change_org_id?
        params.require(:article).permit(allowed_params)
      end

      def allowed_to_change_org_id?
        potential_user = @article&.user || @user
        if @article.nil? || OrganizationMembership.exists?(user: potential_user, organization_id: params["article"]["organization_id"])
          OrganizationMembership.exists?(user: potential_user, organization_id: params["article"]["organization_id"])
        elsif potential_user == @user
          potential_user.org_admin?(params["article"]["organization_id"]) ||
            @user.any_admin?
        end
      end
    end
  end
end
