class TweetTag < LiquidTagBase
  include ActionView::Helpers::AssetTagHelper
  PARTIAL = "liquids/tweet".freeze
  REGISTRY_REGEXP = %r{https://twitter\.com/\w{1,15}/status/(?<id>\d{10,20})}
  VALID_ID_REGEXP = /\A(?<id>\d{10,20})\Z/
  REGEXP_OPTIONS = [REGISTRY_REGEXP, VALID_ID_REGEXP].freeze

  SCRIPT = <<~JAVASCRIPT.freeze
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
    @id = parse_id_or_url(strip_tags(id))
    @tweet = Tweet.find_or_fetch(@id)
    @twitter_logo = ActionController::Base.helpers.asset_path("twitter.svg")
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        tweet: @tweet,
        id: @id,
        twitter_logo: @twitter_logo
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
