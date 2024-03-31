class PodcastTag < LiquidTagBase
  include ApplicationHelper
  include ActionView::Helpers::AssetUrlHelper

  attr_reader :episode, :podcast

  PARTIAL = "podcast_episodes/liquid".freeze

  SCRIPT = <<~JAVASCRIPT.freeze
    var waitingOnPodcast = setInterval(function() {
      if (typeof initializePodcastPlayback !== 'undefined') {
        initializePodcastPlayback();
        clearInterval(waitingOnPodcast);
      }
    }, 1);
  JAVASCRIPT

  IMAGE_LINK = {
    itunes: "https://d.ibtimes.co.uk/en/full/1423047/itunes-12.png",
    overcast: "https://d2uzvmey2c90kn.cloudfront.net/img/logo.svg",
    android: "http://storage.googleapis.com/ix_choosemuse/uploads/2016/02/android-logo.png",
    rss: "https://temenos.com/globalassets/img/marketplace/temenos/rss/rss.png"
  }.freeze

  def self.script
    SCRIPT
  end

  def initialize(_tag_name, link, _parse_context)
    super
    @episode = fetch_podcast(link)
    @podcast ||= Podcast.new
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        episode: @episode,
        podcast: @podcast
      },
    )
  end

  private

  def fetch_podcast(link)
    cleaned_link = parse_link(link)
    podcast_slug, episode_slug = cleaned_link.split("/").last(2)
    target_podcast = Podcast.find_by(slug: podcast_slug)
    target_episode = PodcastEpisode.find_by(slug: episode_slug)
    raise_error unless target_podcast && target_episode
    raise_error unless target_episode.podcast_id == target_podcast.id
    @podcast = target_podcast
    target_episode
  end

  def parse_link(link)
    new_link = ActionController::Base.helpers.strip_tags(link).delete(" ").gsub(/\?.*/, "")
    component_count = new_link.split("/").count
    raise_error if component_count < 2 || component_count > 5
    new_link
  end

  def raise_error
    raise StandardError, I18n.t("liquid_tags.podcast_tag.invalid_podcast_link")
  end
end

Liquid::Template.register_tag("podcast", PodcastTag)
