module Api
  module PodcastEpisodesController
    extend ActiveSupport::Concern

    def index
      page = params[:page]
      per_page = (params[:per_page] || 30).to_i
      per_page_max = (ApplicationConfig["API_PER_PAGE_MAX"] || 1000).to_i
      num = [per_page, per_page_max].min

      if params[:username]
        podcast = Podcast.available.find_by!(slug: params[:username])
        relation = podcast.podcast_episodes.reachable
      else
        relation = PodcastEpisode.includes(:podcast).reachable
      end

      @podcast_episodes = relation
        .select(:id, :slug, :title, :podcast_id)
        .order(published_at: :desc)
        .page(page).per(num)

      set_surrogate_key_header PodcastEpisode.table_key, @podcast_episodes.map(&:record_key)
    end
  end
end
