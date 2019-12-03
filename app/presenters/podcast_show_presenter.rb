class PodcastShowPresenter
  attr_reader :podcast, :episode, :podcast_episode_show, :comment, :comments_to_show_count
  def initialize(podcast, episode)
    @podcast = podcast
    @episode = episode
    @podcast_episode_show = true
    @comments_to_show_count = 25
    @comment = Comment.new
  end
end
