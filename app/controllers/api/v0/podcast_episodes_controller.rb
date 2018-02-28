module Api
  module V0
    class PodcastEpisodesController < ApiController

      # before_action :set_cache_control_headers, only: [:index, :show]
      caches_action :index,
        :cache_path => Proc.new { |c| c.params.permit! },
        :expires_in => 10.minutes
      respond_to :json

      caches_action :show,
        :cache_path => Proc.new { |c| c.params.permit! },
        :expires_in => 10.minutes
      respond_to :json

      before_action :cors_preflight_check
      after_action :cors_set_access_control_headers

      def index
        @page = params[:page]
        if params[:username]
          @podcast = Podcast.find_by_slug(params[:username]) || not_found
          @podcast_episodes = @podcast.
            podcast_episodes.order("published_at desc").
            page(@page).
            per(30)
        else
          @podcast_episodes = PodcastEpisode.order("published_at desc").page(@page).per(30)
        end
      end
    end
  end
end
