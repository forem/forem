class PodcastEpisodesController < ApplicationController
  # No authorization required for entirely public controller
  before_action :set_cache_control_headers, only: [:index]

  def index
    @podcast_index = true

    @podcasts = Podcast.available.order("title asc")
    @podcast_episodes = PodcastEpisodeDecorator.decorate_collection(PodcastEpisode.
      available.
      includes(:podcast).order("published_at desc").first(20))

    if params[:q].blank?
      surrogate_keys = ["podcast_episodes_all"] + @podcast_episodes.map(&:record_key)
      set_surrogate_key_header(surrogate_keys)
    end

    @featured_story = Article.new
    @article_index = true
    @list_of = "podcast-episodes"

    render template: "podcast_episodes/index"
  end

  def show
    @podcast = Podcast.available.find_by!(slug: params[:username])
    @episode = PodcastEpisode.available.find_by!(slug: params[:slug])

    set_surrogate_key_header @episode.record_key

    @episode = @episode.decorate
    @podcast_episode_show = true
    @comments_to_show_count = 25
    @comment = Comment.new

    render template: "podcast_episodes/show"
  end

  private

  def podcast_episode_params
    params.require(:podcast_episode).permit(:title,
                                            :body,
                                            :image,
                                            :social_image,
                                            :remote_social_image_url,
                                            :quote)
  end
end
