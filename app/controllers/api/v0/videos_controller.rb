module Api
  module V0
    class VideosController < ApiController
      respond_to :json

      before_action :cors_preflight_check
      after_action :cors_set_access_control_headers

      def index
        page = params[:page]
        per_page = (params[:per_page] || 24).to_i
        num = [per_page, 1000].min

        @video_articles = Article.published.
          where.not(video: [nil, ""], video_thumbnail_url: [nil, ""]).
          where("score > ?", -4).
          order("hotness_score DESC").
          page(page).per(num)

        set_surrogate_key_header "videos", Article.table_key, @video_articles.map(&:record_key)
      end
    end
  end
end
