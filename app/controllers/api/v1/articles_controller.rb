module Api
  module V1
    # @note This controller partially authorizes with the ArticlePolicy, in an ideal world, it would
    #       fully authorize.  However, that refactor would require significantly more work.
    class ArticlesController < ApiController
      include Api::ArticlesController

      before_action :authenticate!
      before_action :validate_article_param_is_hash, only: %i[create update]
      before_action :set_cache_control_headers, only: %i[index show show_by_slug]
      after_action :verify_authorized, only: %i[create]

      def unpublish
        @article = Article.includes(user: :profile)
          .select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)
          .find(params[:id])

        authorize @article, :revoke_publication?

        if Articles::Unpublish.call(@article)
          @article.decorate
          render show
        else
          render json: { message: @article.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
