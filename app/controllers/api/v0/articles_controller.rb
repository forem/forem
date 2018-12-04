module Api
  module V0
    class ArticlesController < ApiController
      before_action :set_cache_control_headers, only: [:index]
      caches_action :show,
        cache_path: Proc.new { |c| c.params.permit! },
        expires_in: 5.minutes
      respond_to :json

      before_action :cors_preflight_check
      after_action :cors_set_access_control_headers

      def index
        @articles = ArticleApiIndexService.new(params).get
        key_headers = [
          "articles_api",
          params[:tag],
          params[:page],
          params[:userame],
          params[:signature],
          params[:state],
        ]
        set_surrogate_key_header key_headers.join('_')
      end

      def show
        @article = if params[:id] == "by_path"
                     Article.includes(:user).find_by_path(params[:url])&.decorate
                   else
                     Article.includes(:user).find(params[:id])&.decorate
                   end
        not_found unless @article&.published
      end

      def onboarding
        tag_list = if params[:tag_list].present?
                     params[:tag_list].split(",")
                   else
                     ["career", "discuss", "productivity"]
                   end
        @articles = []
        4.times do
          @articles << Suggester::Articles::Classic.new.get(tag_list)
        end
        Article.tagged_with(tag_list, any: true).
          order("published_at DESC").
          where("positive_reactions_count > ? OR comments_count > ? AND published = ?", 10, 3, true).
          limit(15).each do |article|
            @articles << article
          end
        @articles = @articles.uniq.sample(6)
      end

      def create
        @article = ArticleCreationService.new(current_user, article_params, {}).create!
        render json:  if @article.persisted?
                        @article.to_json(only: [:id], methods: [:current_state_path])
                      else
                        @article.errors.to_json
                      end
      end

      def update
        @article = Article.find(params[:id])
        render json: if @article.update(article_params)
                       @article.to_json(only: [:id], methods: [:current_state_path])
                     else
                       @article.errors.to_json
                     end
      end

      def article_params
        params["article"].transform_keys!(&:underscore)
        if params["article"]["post_under_org"]
          params["article"]["organization_id"] = current_user.organization_id
        else
          params["article"]["organization_id"] = nil
        end
        if params["article"]["series"].present?
          params["article"]["collection_id"] = Collection.find_series(params["article"]["series"], current_user)&.id
        elsif params["article"]["series"] == ""
          params["article"]["collection_id"] = nil
        end
        params.require(:article).permit(
          :title, :body_markdown, :user_id, :main_image, :published, :description,
          :tag_list, :organization_id, :canonical_url, :series, :collection_id
        )
      end
    end
  end
end
