module Api
  module V0
    class VideosController < ApiController
      before_action :cors_preflight_check
      after_action :cors_set_access_control_headers

      before_action :set_cache_control_headers, only: %i[index]

      def index
        page = params[:page]
        per_page = (params[:per_page] || 24).to_i
        num = [per_page, 1000].min

        @video_articles = Article.with_video.
          includes([:user]).
          select(:id, :video, :path, :title, :video_thumbnail_url, :user_id, :video_duration_in_seconds).
          order("hotness_score DESC").
          page(page).per(num)

        set_surrogate_key_header "videos", Article.table_key, @video_articles.map(&:record_key)
      end
    end
  end
end
