class Tweet < ApplicationRecord
  include AlgoliaSearch

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
    find_by_twitter_id_code(twitter_id_code) || fetch(twitter_id_code)
  end

  def self.fetch(twitter_id_code)
    tries = 0
    tweet = nil
    until (tries > 4 || tweet) do
      begin
        return tweet = try_to_get_tweet(twitter_id_code)
      rescue => e
        puts e
        tries += 1
      end
    end
  end

  def processed_text
    urls_serialized.each do |url|
      text.gsub!(url[:url],"<a href='#{url[:url]}'>#{url[:display_url]}</a>")
    end
    mentioned_usernames_serialized.each do |username|
      uname = username["screen_name"]
      text.gsub!("@"+uname,"<a href='https://twitter.com/#{uname}'>#{"@"+uname}</a>")
    end
    hashtags_serialized.each do |tag|
      tag_text = tag[:text]
      text.gsub!("#"+tag_text,"<a href='https://twitter.com/hashtag/#{tag_text}'>#{"#"+tag_text}</a>")
    end

    if extended_entities_serialized && extended_entities_serialized[:media]
      extended_entities_serialized[:media].each do |media|
        text.gsub!(media[:url],"")
      end
    end

    text.gsub!("\n","<br/>")
    text
  end

  private

  def self.try_to_get_tweet(twitter_id_code)
    c = TwitterBot.new(random_identity).client
    t = c.status(twitter_id_code, tweet_mode: "extended")
    make_tweet_from_api_object(t)
  end

  def self.make_tweet_from_api_object(t)
    t = TwitterBot.new(random_identity).client.status(t.attrs[:retweeted_status][:id_str]) if t.attrs[:retweeted_status]
    tweet = Tweet.where(twitter_id_code: t.attrs[:id_str]).first_or_initialize
    tweet.twitter_uid = t.user.id.to_s
    tweet.twitter_username = t.user.screen_name.downcase
    tweet.user_id = User.find_by_twitter_username(t.user.screen_name).try(:id)
    tweet.favorite_count = t.favorite_count
    tweet.retweet_count = t.retweet_count
    tweet.in_reply_to_user_id_code = t.attrs[:in_reply_to_user_id_str]
    tweet.in_reply_to_user_id_code = t.attrs[:in_reply_to_status_id_str]
    tweet.twitter_user_following_count = t.user.friends_count
    tweet.twitter_user_followers_count = t.user.followers_count
    tweet.twitter_id_code = t.attrs[:id_str]
    tweet.quoted_tweet_id_code = t.attrs[:quoted_status_id_str]
    tweet.in_reply_to_username = t.in_reply_to_screen_name
    tweet.source = t.source
    tweet.text = t.attrs[:full_text]
    tweet.twitter_name = t.user.name
    tweet.mentioned_usernames_serialized = t.user_mentions.as_json
    tweet.hashtags_serialized = t.attrs[:entities][:hashtags]
    tweet.remote_profile_image_url = t.user.profile_image_url
    tweet.urls_serialized = t.attrs[:entities][:urls]
    tweet.media_serialized = t.attrs[:media]
    tweet.extended_entities_serialized = t.attrs[:extended_entities]
    tweet.full_fetched_object_serialized = t.attrs
    tweet.tweeted_at = t.attrs[:created_at]
    tweet.last_fetched_at = Time.now
    tweet.user_is_verified = t.user.verified?
    tweet.is_quote_status = t.attrs[:is_quote_status]
    tweet.save!
    tweet
  end

  def self.random_identity
    if Rails.env.production?
      Identity.where(provider:"twitter").last(250).sample
    else
      Identity.where(provider:"twitter").last
    end
  end

end
