class PodcastTag < LiquidTagBase
  include ApplicationHelper
  include CloudinaryHelper

  attr_reader :episode, :podcast
  PARTIAL = "podcast_episodes/liquid".freeze

  IMAGE_LINK = {
    itunes: "https://d.ibtimes.co.uk/en/full/1423047/itunes-12.png",
    overcast: "https://d2uzvmey2c90kn.cloudfront.net/img/logo.svg",
    android: "http://storage.googleapis.com/ix_choosemuse/uploads/2016/02/android-logo.png",
    rss: "https://temenos.com/globalassets/img/marketplace/temenos/rss/rss.png"
  }.freeze

  def initialize(_tag_name, link, _tokens)
    @episode = fetch_podcast(link)
    @podcast ||= Podcast.new
    @style = render_style
    @subscribe_links = render_subscribe_links
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        podcast: @podcast,
        episode: @episode,
        render_style: @style,
        subscribe_links: @subscribe_links
      },
    )
  end

  def render_style
    "background:##{@podcast.main_color_hex} " \
    "url(#{cl_image_path(@podcast.pattern_image_url || 'https://i.imgur.com/fKYKgo4.png', type: 'fetch', quality: 'auto', sign_url: true, flags: 'progressive', fetch_format: 'jpg')})"
  end

  def self.script
    <<~JAVASCRIPT
      var waitingOnPodcast = setInterval(function(){
        if (typeof initializePodcastPlayback !== 'undefined') {
          initializePodcastPlayback();
          clearInterval(waitingOnPodcast);
        }
      },1);
    JAVASCRIPT
  end

  def render_subscribe_links
    <<~HTML
      <div class="podcastliquidtag__links">
        #{render_podcast_links('iTunes', @podcast.itunes_url)}
        #{render_podcast_links('Overcast', @podcast.overcast_url)}
        #{render_podcast_links('Android', @podcast.android_url)}
        #{render_podcast_links('RSS', @podcast.feed_url)}
      </div>
    HTML
  end

  def render_podcast_links(name, source)
    return unless source

    <<~HTML
      <a href="#{source}" target="_blank" rel="noopener noreferrer">
        <img src="#{cloudinary(IMAGE_LINK[name.downcase.to_sym], 40, 90, 'png')}" />
        <span class="service-name">#{name}</span>
      </a>
    HTML
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
    raise StandardError, "Invalid podcast link"
  end
end
Liquid::Template.register_tag("podcast", PodcastTag)
