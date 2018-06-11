class PodcastTag < LiquidTagBase
  include ApplicationHelper

  attr_reader :episode, :podcast

  IMAGE_LINK = {
    itunes: 'https://d.ibtimes.co.uk/en/full/1423047/itunes-12.png',
    overcast: 'https://d2uzvmey2c90kn.cloudfront.net/img/logo.svg',
    android: 'http://storage.googleapis.com/ix_choosemuse/uploads/2016/02/android-logo.png',
    rss: 'https://temenos.com/globalassets/img/marketplace/temenos/rss/rss.png',
  }.freeze

  def initialize(tag_name, link, tokens)
    @episode = fetch_podcast(link)
    @podcast
  end

  def render(context)
    html = <<-HTML
      <div class="podcastliquidtag" style="#{renderStyle}">
        <div class="podcastliquidtag__info">
          <a href="/#{@podcast.slug}/#{@episode.slug}">
            <h1 class="podcastliquidtag__info__episodetitle">#{@episode.title}</h1>
          </a>
          <a href="/#{@podcast.slug}">
              #{cl_image_tag(@podcast.image_url,
               :type=>"fetch",
               :crop => "fill",
               :quality => "auto",
               :sign_url => true,
               :flags => "progressive",
               :fetch_format => "auto",
               :class => "tinyimage")}
            <h1 class="podcastliquidtag__info__podcasttitle">#{@podcast.title}</h1>
          </a>

          #{render_subscribe_links}
        </div>

        <div id="record-#{episode.slug}" data-podcast="#{podcast.slug}" data-episode="#{episode.slug}" class="podcastliquidtag__record">
          <img class="button play-butt" id="play-butt-#{episode.slug}" src="/assets/playbutt.png"/>
          <img class="button pause-butt" id="pause-butt-#{episode.slug}" src="/assets/pausebutt.png"/>
          #{cl_image_tag(@podcast.image_url,
           :type=>"fetch",
           :crop => "fill",
           :quality => "auto",
           :sign_url => true,
           :flags => "progressive",
           :fetch_format => "auto",
           :class => "podcastliquidtag__podcastimage",
           :id => "podcastimage-#{episode.slug}")}
        </div>
        #{render_hidden_audio}
      </div>
    HTML
    finalize_html(html)
  end

  def renderStyle
    "background:##{@podcast.main_color_hex} " \
    "url(#{cl_image_path(@podcast.pattern_image_url || 'https://i.imgur.com/fKYKgo4.png', :type=>'fetch', :quality => 'auto', :sign_url => true, :flags => 'progressive', :fetch_format => 'jpg')})"
  end

  def render_hidden_audio
    <<~HTML
      <div class="hidden-audio" id="hidden-audio-#{@episode.slug}" style="display:none" data-episode="#{@episode.slug}" data-podcast="#{@podcast.slug}">
        <audio id="audio" data-episode="#{@episode.slug}" data-podcast="#{@podcast.slug}">
          <source src="#{@episode.media_url}" type="audio/mpeg">
            Your browser does not support the audio element.
        </audio>
        <div id="progressBar" class="audio-player-display">
          <a href="/#{@podcast.slug}/#{@episode.slug}">
            #{cl_image_tag(@episode.image_url || @podcast.image_url,
             :type=>"fetch",
             :crop => "fill",
             :width => 420,
             :height => 420,
             :quality => "auto",
             :sign_url => true,
             :flags => "progressive",
             :fetch_format => "auto",
             :id => "episode-profile-image")
            }
            <img id="animated-bars" src="/assets/animated-bars.gif" />
          </a>
          <span id="barPlayPause">
            <img class="butt play-butt" src="/assets/playbutt.png"/>
            <img class="butt pause-butt" src="/assets/pausebutt.png"/>
          </span>
          <span id="volume">
            <span id="volumeindicator" class="volume-icon-wrapper showing">
              <span id="volbutt">
                #{image_tag("/assets/volume.png", alt: name, class:"icon-img", height: 16, width: 16)}
              </span>
              <span class="range-wrapper">
                <input type="range" name="points" id="volumeslider" value="50" min="0" max="100" data-show-value="true">
              </span>
            </span>
            <span id="mutebutt" class="volume-icon-wrapper hidden">
              #{image_tag("/assets/volume-mute.png", alt: name, class:"icon-img", height: 16, width: 16)}
            </span>
            <span class="speed" id="speed" data-speed=1 >1x</span>
          </span>
          <span class="buffer-wrapper" id="bufferwrapper">
            <span id="buffer"></span>
            <span id="progress"></span>
            <span id="time"></span>
            <span id="closebutt">[ x ]</span>
          </span>
        </div>
      </div>
    HTML
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
    if source
      <<~HTML
        <a href="#{source}" target="_blank" rel="noopener noreferrer">
          <img src="#{cloudinary(IMAGE_LINK[name.downcase.to_sym], 40, 90, 'png')}" />
          <span class="service-name">#{name}</span>
        </a>
      HTML
    end
  end

  private

  def fetch_podcast(link)
    cleaned_link = parse_link(link)
    podcast_slug, episode_slug = cleaned_link.split('/').last(2)
    target_podcast = Podcast.find_by_slug(podcast_slug)
    target_episode = PodcastEpisode.find_by_slug(episode_slug)
    raise_error unless target_podcast && target_episode
    raise_error unless target_episode.podcast_id == target_podcast.id
    @podcast = target_podcast
    target_episode
  end

  def parse_link(link)
    new_link = ActionController::Base.helpers.strip_tags(link).delete(' ').gsub(/\?.*/, '')
    component_count = new_link.split('/').count
    raise_error if component_count < 2 || component_count > 5
    new_link
  end

  def raise_error
    raise StandardError, 'Invalid podcast link'
  end
end
Liquid::Template.register_tag("podcast", PodcastTag)
