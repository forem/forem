module Api
  module V0
    class CommentsController < ApiController
      respond_to :json

      caches_action :index,
                    cache_path: proc { |c| c.params.permit! },
                    expires_in: 10.minutes

      caches_action :show,
                    cache_path: proc { |c| c.params.permit! },
                    expires_in: 10.minutes

      def index
        article = Article.find(params[:a_id])
        @comments = article.comments.roots.includes(:user).select(%i[id processed_html user_id ancestry])
      end

      def show
        @comment = Comment.find(params[:id].to_i(26))
      end
    end
  end
end
