class Tweet < ApplicationRecord
  self.ignored_columns = %w[
    primary_external_url
  ]
  mount_uploader :profile_image, ProfileImageUploader

  belongs_to :user, optional: true

  serialize :mentioned_usernames_serialized
  serialize :hashtags_serialized
  serialize :urls_serialized
  serialize :media_serialized
  serialize :extended_entities_serialized
  serialize :full_fetched_object_serialized

  validates :twitter_id_code, presence: true
  validates :full_fetched_object_serialized, presence: true

  def self.find_or_fetch(twitter_id_code)
    find_by(twitter_id_code: twitter_id_code) || fetch(twitter_id_code)
  end

  def self.fetch(twitter_id_code)
    tries = 0
    tweet = nil
    until tries > 4 || tweet
      begin
        return tweet = try_to_get_tweet(twitter_id_code)
      rescue StandardError => e
        Rails.logger.error(e)
        tries += 1
      end
    end
  end

  def processed_text
    urls_serialized.each do |url|
      text.gsub!(url[:url], "<a href='#{url[:url]}'>#{url[:display_url]}</a>")
    end
    mentioned_usernames_serialized.each do |username|
      uname = username["screen_name"]
      text.gsub!("@" + uname, "<a href='https://twitter.com/#{uname}'>#{'@' + uname}</a>")
    end
    hashtags_serialized.each do |tag|
      tag_text = tag[:text]
      text.gsub!("#" + tag_text,
                 "<a href='https://twitter.com/hashtag/#{tag_text}'>#{'#' + tag_text}</a>")
    end

    if extended_entities_serialized && extended_entities_serialized[:media]
      extended_entities_serialized[:media].each do |media|
        text.gsub!(media[:url], "")
      end
    end

    text.gsub!("\n", "<br/>")
    text
  end

  class << self
    def try_to_get_tweet(twitter_id_code)
      client = TwitterBot.client(random_identity)
      tweet = client.status(twitter_id_code, tweet_mode: "extended")
      make_tweet_from_api_object(tweet)
    end

    private

    def make_tweet_from_api_object(tweeted)
      tweeted = if tweeted.attrs[:retweeted_status]
                  TwitterBot.client(random_identity).status(tweeted.attrs[:retweeted_status][:id_str])
                else
                  tweeted
                end

      tweet = Tweet.where(twitter_id_code: tweeted.attrs[:id_str]).first_or_initialize

      tweet.twitter_uid = tweeted.user.id.to_s
      tweet.twitter_username = tweeted.user.screen_name.downcase
      tweet.user_id = User.find_by(twitter_username: tweeted.user.screen_name)&.id
      tweet.favorite_count = tweeted.favorite_count
      tweet.retweet_count = tweeted.retweet_count
      tweet.twitter_user_following_count = tweeted.user.friends_count
      tweet.twitter_user_followers_count = tweeted.user.followers_count
      tweet.in_reply_to_username = tweeted.in_reply_to_screen_name
      tweet.source = tweeted.source
      tweet.twitter_name = tweeted.user.name
      tweet.mentioned_usernames_serialized = tweeted.user_mentions.as_json
      tweet.remote_profile_image_url = tweeted.user.profile_image_url
      tweet.last_fetched_at = Time.current
      tweet.user_is_verified = tweeted.user.verified?
      tweet = handle_tweeted_attrs(tweet, tweeted)

      tweet.save!

      tweet
    end

    def handle_tweeted_attrs(tweet, tweeted)
      tweet.in_reply_to_user_id_code = tweeted.attrs[:in_reply_to_user_id_str]
      tweet.in_reply_to_status_id_code = tweeted.attrs[:in_reply_to_status_id_str]
      tweet.twitter_id_code = tweeted.attrs[:id_str]
      tweet.quoted_tweet_id_code = tweeted.attrs[:quoted_status_id_str]
      tweet.text = tweeted.attrs[:full_text]
      tweet.hashtags_serialized = tweeted.attrs[:entities][:hashtags]
      tweet.urls_serialized = tweeted.attrs[:entities][:urls]
      tweet.media_serialized = tweeted.attrs[:media]
      tweet.extended_entities_serialized = tweeted.attrs[:extended_entities]
      tweet.full_fetched_object_serialized = tweeted.attrs
      tweet.tweeted_at = tweeted.attrs[:created_at]
      tweet.is_quote_status = tweeted.attrs[:is_quote_status]
      tweet
    end

    def random_identity
      iden = Identity.where(provider: "twitter").last(250).sample
      {
        token: iden&.token || ApplicationConfig["TWITTER_KEY"],
        secret: iden&.secret || ApplicationConfig["TWITTER_SECRET"]
      }
    end
  end
end
