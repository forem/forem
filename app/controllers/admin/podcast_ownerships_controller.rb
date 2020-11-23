module Admin
  class PodcastOwnershipsController < Admin::ApplicationController
    layout "admin"

    private

    def podcast_ownership_params
      allowed_params = %i[
        podcast_id
        user_id
      ]
      params.require(:podcast_ownership).permit(allowed_params)
    end
  end
end
