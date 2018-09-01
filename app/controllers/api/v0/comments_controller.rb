module Api
  module V0
    class CommentsController < ApplicationController
      # before_action :set_cache_control_headers, only: [:index, :show]
      caches_action :index,
        cache_path: Proc.new { |c| c.params.permit! },
        expires_in: 10.minutes
      respond_to :json

      caches_action :show,
        cache_path: Proc.new { |c| c.params.permit! },
        expires_in: 10.minutes
      respond_to :json

      def index
        @commentable = Article.find(session[:a_id]) # or not_found
        @commentable_type = "Article"
      end

      def show
        (@comment = Comment.find(session[:id].to_i(26))) || not_found
      end
    end
  end
end
