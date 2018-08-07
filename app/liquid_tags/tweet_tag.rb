class TweetTag < LiquidTagBase
  attr_reader :tweet

  def initialize(tag_name, id, tokens)
    super
    @id = parse_id(id)
    @tweet = Tweet.find_or_fetch(@id)
  end

  def render(_context)
    media_div = ""
    video_div = ""
    play_butt = ""
    quote_div = ""
    if @tweet.extended_entities_serialized.present? && @tweet.extended_entities_serialized[:media] && @tweet.extended_entities_serialized[:media].size == 1
      media_item = @tweet.extended_entities_serialized[:media].first
      if media_item[:type] == "animated_gif" || media_item[:type] == "video"
        play_butt = image_tag("/assets/play-butt.svg", class: "ltag__twitter-tweet__play-butt")
        preview_div = "<div class='ltag__twitter-tweet__media--video-preview'><img src='#{media_item[:media_url_https]}'/>#{play_butt}</div>"
        video_div = "<div class='ltag__twitter-tweet__video'><video loop><source src='#{media_item[:video_info][:variants].last[:url]}' type='#{media_item[:video_info][:variants].last[:content_type]}' /></video></div>"
        media_div = "<div class='ltag__twitter-tweet__media ltag__twitter-tweet__media__video-wrapper'>#{preview_div}#{video_div}</div>"
      else
        media_div = "<div class='ltag__twitter-tweet__media'><img src='#{media_item[:media_url_https]}' /></div>"
      end
    elsif @tweet.extended_entities_serialized.present? && @tweet.extended_entities_serialized[:media] && @tweet.extended_entities_serialized[:media].size > 1
      # Currently only showing first pic. TODO: show 2-4 pics. But lots of work.
      media_item = @tweet.extended_entities_serialized[:media].first
      media_div = "<div class='ltag__twitter-tweet__media ltag__twitter-tweet__media__two-pics'><img src='#{media_item[:media_url_https]}' /></div>"
    end

    if @tweet.is_quote_status && @tweet.full_fetched_object_serialized[:quoted_status]
      quoted_status = @tweet.full_fetched_object_serialized[:quoted_status]
      quote_div = "<div class='ltag__twitter-tweet__quote'><div class='ltag__twitter-tweet__quote__header'><span class='ltag__twitter-tweet__quote__header__name'>#{quoted_status[:user][:name]}</span> @#{quoted_status[:user][:screen_name]}</div>#{quoted_status[:text]}</div>"
    end
    "<blockquote "\
      'class="ltag__twitter-tweet" data-url="https://twitter.com/' + @tweet.twitter_username + "/status/" + @id + '">'\
      +media_div + \
      '<div class="ltag__twitter-tweet__main" data-url="https://twitter.com/' + @tweet.twitter_username + "/status/" + @id + '">'\
      '<div class="ltag__twitter-tweet__header">'\
      '<img class="ltag__twitter-tweet__profile-image" src="' + @tweet.full_fetched_object_serialized[:user][:profile_image_url_https] + '"/>'\
      '<div class="ltag__twitter-tweet__full-name">' + @tweet.twitter_name + "</div>"\
      '<div class="ltag__twitter-tweet__username">@' + @tweet.twitter_username + "</div>"\
      '<div class="ltag__twitter-tweet__twitter-logo">'\
      '<img src="' + ActionController::Base.helpers.asset_path("twitter.svg") + '" />'\
      "</div>"\
      "</div>"\
      '<div class="ltag__twitter-tweet__body">' + @tweet.processed_text.html_safe + "</div>"\
      '<div class="ltag__twitter-tweet__date">' + @tweet.tweeted_at.strftime("%H:%M %p - %d %b %Y") + "</div>"\
      +quote_div + \
      '<div class="ltag__twitter-tweet__actions">'\
        '<a href= "https://twitter.com/intent/tweet?in_reply_to=' + @id + '" class="ltag__twitter-tweet__actions__button">' + image_tag("/assets/twitter-reply-action.svg") + "</a>"\
        '<a href= "https://twitter.com/intent/retweet?tweet_id=' + @id + '" class="ltag__twitter-tweet__actions__button">' + image_tag("/assets/twitter-retweet-action.svg") + "</a>" + @tweet.retweet_count.to_s + \
      '<a href= "https://twitter.com/intent/like?tweet_id=' + @id + '" class="ltag__twitter-tweet__actions__button">' + image_tag("/assets/twitter-like-action.svg") + "</a>" + @tweet.favorite_count.to_s + \
      "</div>"\
      "</div>"\
    "</blockquote>"
  end

  def self.script
    'var videoPreviews = document.getElementsByClassName("ltag__twitter-tweet__media__video-wrapper");
      [].forEach.call(videoPreviews, function(el){
        el.onclick= function(e){
          var divHeight = el.offsetHeight;
          el.style.maxHeight = divHeight + "px";
          el.getElementsByClassName("ltag__twitter-tweet__media--video-preview")[0].style.display = "none";
          el.getElementsByClassName("ltag__twitter-tweet__video")[0].style.display = "block";
          el.getElementsByTagName("video")[0].play();
        }
      })
      var tweets = document.getElementsByClassName("ltag__twitter-tweet__main");
      [].forEach.call(tweets, function(tweet){
        tweet.onclick= function(e){
          if (e.target.nodeName == "A" || e.target.parentElement.nodeName == "A"){
            return;
          }
          window.open(tweet.dataset.url,"_blank");
        }
      });
      '
  end

  private

  def parse_id(input)
    input_no_space = input.delete(" ")
    if valid_id?(input_no_space)
      input_no_space
    else
      raise StandardError, "Invalid Twitter Id"
    end
  end

  def valid_id?(id)
    # id must be all numbers under 20 characters
    /^\d{10,20}$/ === id
  end
end

Liquid::Template.register_tag("tweet", TweetTag)
Liquid::Template.register_tag("twitter", TweetTag)
