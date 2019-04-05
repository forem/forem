module Api
  module V0
    class VideosController < ApiController
      caches_action :index,
        cache_path: proc { |c| c.params.permit! },
        expires_in: 10.minutes
      respond_to :json

      caches_action :show,
        cache_path: proc { |c| c.params.permit! },
        expires_in: 10.minutes
      respond_to :json

      before_action :cors_preflight_check
      after_action :cors_set_access_control_headers

      def index
        @page = params[:page]
        @video_articles = Article.where.not(video: nil, video_thumbnail_url: nil).where(published: true).order("published_at DESC").page(params[:page].to_i).per(24)
      end
    end
  end
end
