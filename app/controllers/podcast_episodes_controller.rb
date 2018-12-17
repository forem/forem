class PodcastEpisodesController < ApplicationController
  # No authorization required for entirely public controller
  before_action :set_cache_control_headers, only: [:index]

  def index
    @podcast_index = true
    @podcasts = Podcast.order("title asc")
    @podcast_episodes = PodcastEpisode.order("published_at desc").first(20)
    unless params[:q].present?
      set_surrogate_key_header("podcast_episodes_all " + params[:q].to_s,
                               @podcast_episodes.map { |e| e["record_key"] })
    end
    @featured_story = Article.new
    @article_index = true
    @list_of = "podcast-episodes"
    render template: "podcast_episodes/index"
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
