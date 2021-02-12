class PodcastEpisodesController < ApplicationController
  # No authorization required for entirely public controller
  before_action :set_cache_control_headers, only: [:index]

  def index
    @podcast_index = true

    @podcasts = Podcast.available.order(title: :asc)
    @podcast_episodes = PodcastEpisodeDecorator.decorate_collection(PodcastEpisode
      .available
      .includes(:podcast).order(published_at: :desc).first(20))

    if params[:q].blank?
      surrogate_keys = ["podcast_episodes_all"] + @podcast_episodes.map(&:record_key)
      set_surrogate_key_header(surrogate_keys)
    end

    @featured_story = Article.new
    @article_index = true
    @list_of = "podcast-episodes"

    render template: "podcast_episodes/index"
  end
end
