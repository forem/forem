class TweetTag < LiquidTagBase
  include ActionView::Helpers::AssetTagHelper
  PARTIAL = "liquids/tweet".freeze
  ID_REGEXP = /\A\d{10,20}\z/ # id must be all numbers between 10 and 20 chars

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

  def initialize(_tag_name, id, _parse_context)
    super
    @id = parse_id(id)
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

  def self.script
    SCRIPT
  end

  private

  def parse_id(input)
    input_no_space = input.delete(" ")
    raise StandardError, "Invalid Twitter Id" unless valid_id?(input_no_space)

    input_no_space
  end

  def valid_id?(id)
    ID_REGEXP.match?(id)
  end
end

Liquid::Template.register_tag("tweet", TweetTag)
Liquid::Template.register_tag("twitter", TweetTag)
