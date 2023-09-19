class PodcastEpisodesController < ApplicationController
  # No authorization required for entirely public controller
  before_action :set_cache_control_headers, only: %i[index show]
  before_action :set_user_limit, only: %i[show]

  rescue_from ArgumentError, with: :bad_request

  def index
    @podcast_index = true

    @featured_podcasts = Podcast.available.featured.order(title: :asc).limit(4)
    @more_podcasts = Podcast.available.order(title: :asc)
    @podcast_episodes = PodcastEpisodeDecorator.decorate_collection(PodcastEpisode
      .available
      .includes(:podcast).order(published_at: :desc).limit(6))

    if params[:q].blank?
      surrogate_keys = ["podcast_episodes_all"] + @podcast_episodes.map(&:record_key)
      set_surrogate_key_header(surrogate_keys)
    end
    render template: "podcast_episodes/index"
  end

  def show
    @podcast = Podcast.available.find_by(slug: params[:handle])
    @episode = @podcast.podcast_episodes.available.find_by!(slug: params[:slug])
    @episode = @episode.decorate
    set_surrogate_key_header @episode.record_key
    @podcast_episode_show = true
    @comments_to_show_count = 25
    @comment = Comment.new
  end
end
