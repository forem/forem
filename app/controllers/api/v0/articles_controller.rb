module Api
  module V0
    class ArticlesController < ApiController
      before_action :set_cache_control_headers, only: [:index]
      caches_action :show,
        :cache_path => Proc.new { |c| c.params.permit! },
        :expires_in => 5.minutes
      respond_to :json

      before_action :cors_preflight_check
      after_action :cors_set_access_control_headers

      def index
        @articles = ArticleApiIndexService.new(params).get
        set_surrogate_key_header "articles_api_#{params[:tag]}_#{params[:page]}_#{params[:userame]}_#{params[:signature]}_#{params[:state]}"
      end

      def show
        @article = Article.includes(:user).find(params[:id]).decorate
        not_found unless @article.published
      end

      def onboarding
        tag_list = if params[:tag_list].present?
          params[:tag_list].split(",")
        else
          ["career","discuss","productivity"]
        end
        @articles = []
        4.times do
          @articles << ClassicArticle.new.get(tag_list)
        end
        Article.tagged_with(tag_list, any: true).
          order("published_at DESC").
          where("positive_reactions_count > ? OR comments_count > ?", 10, 3).limit(15).each do |article|
            @articles << article
          end
        @articles = @articles.uniq.sample(6)
      end
    end
  end
end
