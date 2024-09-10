class TweetTag < LiquidTagBase
  PARTIAL = "liquids/tweet".freeze
  REGISTRY_REGEXP = %r{https://(?:twitter\.com|x\.com)/\w{1,15}/status/(?<id>\d{10,20})}
  VALID_ID_REGEXP = /\A(?<id>\d{10,20})\Z/
  REGEXP_OPTIONS = [REGISTRY_REGEXP, VALID_ID_REGEXP].freeze

  SCRIPT = <<~JAVASCRIPT.freeze
      // Listen for resize events and match them to the iframe
      window.addEventListener('message', function(event) {
        if (event.origin.startsWith('https://platform.twitter.com')) {
            var iframes = document.getElementsByTagName('iframe');
            for (var i = 0; i < iframes.length; i++) {
              if (event.source === iframes[i].contentWindow) { // iframes which match the event
                var iframe = iframes[i];
                var data = event.data['twttr.embed'];
                if (data && data['method'] === 'twttr.private.resize' && data['params'] && data['params']['0']) {
                  iframe.style.height = data['params']['0']['height'] + 0.5 + 'px';
                  iframe.style.minHeight = data['params']['0']['height'] + 0.5 + 'px';
                  iframe.style.width = data['params']['0']['width'] + 'px !important';
                }
                break;
              }
            }
        }
    }, false);

    // Legacy support: We have shifted up how we render tweets, but still need to render
    // the old way for old embed. This could eventually be removed.
    var videoPreviews = document.getElementsByClassName("ltag__twitter-tweet__media__video-wrapper");
    [].forEach.call(videoPreviews, function(el) {
      el.onclick = function(e) {
        var divHeight = el.offsetHeight;
        el.style.maxHeight = divHeight + "px";
        el.getElementsByClassName("ltag__twitter-tweet__media--video-preview")[0].style.display = "none";
        el.getElementsByClassName("ltag__twitter-tweet__video")[0].style.display = "block";
        el.getElementsByTagName("video")[0].play();
      }
    });
    var tweets = document.getElementsByClassName("ltag__twitter-tweet__main");
    [].forEach.call(tweets, function(tweet){
      tweet.onclick = function(e) {
        if (e.target.nodeName == "A" || e.target.parentElement.nodeName == "A") {
          return;
        }
        window.open(tweet.dataset.url,"_blank");
      }
    });
  JAVASCRIPT

  def self.script
    SCRIPT
  end

  def initialize(_tag_name, id, _parse_context)
    super
    input = CGI.unescape_html(strip_tags(id))
    @id = parse_id_or_url(input)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        id: @id,
      },
    )
  end

  private

  def parse_id_or_url(input)
    match = pattern_match_for(input, REGEXP_OPTIONS)
    raise StandardError, I18n.t("liquid_tags.tweet_tag.invalid_twitter_id") unless match

    match[:id]
  end
end

Liquid::Template.register_tag("tweet", TweetTag)
Liquid::Template.register_tag("twitter", TweetTag)
UnifiedEmbed.register(TweetTag, regexp: TweetTag::REGISTRY_REGEXP)
