module Api
  module V0
    class PodcastEpisodesController < ApiController
      include Api::PodcastEpisodesController

      before_action :set_cache_control_headers, only: %i[index]
    end
  end
end
