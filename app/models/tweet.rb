class Tweet < ApplicationRecord
  mount_uploader :profile_image, ProfileImageUploader

  belongs_to :user, optional: true

  serialize :extended_entities_serialized
  serialize :full_fetched_object_serialized
  serialize :hashtags_serialized
  serialize :media_serialized
  serialize :mentioned_usernames_serialized
  serialize :urls_serialized

  validates :full_fetched_object_serialized, presence: true
  validates :twitter_id_code, presence: true

  def processed_text
    urls_serialized.each do |url|
      text.gsub!(url[:url], "<a href='#{url[:url]}'>#{url[:display_url]}</a>")
    end
    mentioned_usernames_serialized.each do |username|
      uname = username["screen_name"]
      text.gsub!("@#{uname}", "<a href='https://twitter.com/#{uname}'>#{"@#{uname}"}</a>")
    end
    hashtags_serialized.each do |tag|
      tag_text = tag.text
      text.gsub!("##{tag_text}",
                 "<a href='https://twitter.com/hashtag/#{tag_text}'>#{"##{tag_text}"}</a>")
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
    def find_or_fetch(status_id)
      find_by(twitter_id_code: status_id) || fetch(status_id)
    end

    private

    def fetch(status_id)
      retrieve_and_save_tweet(status_id)
    rescue TwitterClient::Errors::NotFound => e
      raise e, "Tweet not found"
    end

    def retrieve_and_save_tweet(status_id)
      status = TwitterClient::Client.status(status_id, tweet_mode: "extended")
      create_tweet_from_api_status(status)
    end

    def create_tweet_from_api_status(status)
      status = if status.retweeted_status.present?
                 TwitterClient::Client.status(status.retweeted_status.id.to_s)
               else
                 status # rubocop:disable Style/RedundantSelfAssignmentBranch
               end

      params = { twitter_id_code: status.id.to_s }
      tweet = Tweet.find_by(params) || new(params)

      tweet.text = status.full_text

      # matching the retrieved tweet to the DB user if there is one
      tweet.user_id = User.find_by(twitter_username: status.user.screen_name)&.id

      tweet = extract_metadata_attributes(tweet, status)
      tweet = extract_serializable_attributes(tweet, status)
      tweet = extract_user_attributes(tweet, status)

      tweet.last_fetched_at = Time.current
      tweet.save!

      tweet
    end

    def extract_metadata_attributes(tweet, status)
      tweet.favorite_count = status.favorite_count
      tweet.in_reply_to_status_id_code = status.in_reply_to_status_id.to_s
      tweet.in_reply_to_user_id_code = status.in_reply_to_user_id.to_s
      tweet.in_reply_to_username = status.in_reply_to_screen_name.to_s
      tweet.is_quote_status = status.attrs[:is_quote_status]
      tweet.quoted_tweet_id_code = status.attrs[:quoted_status_id_str]
      tweet.retweet_count = status.retweet_count
      tweet.source = status.source
      tweet.tweeted_at = status.created_at

      tweet
    end

    def extract_serializable_attributes(tweet, status)
      tweet.extended_entities_serialized = status.attrs[:extended_entities]
      tweet.full_fetched_object_serialized = status.attrs
      tweet.hashtags_serialized = status.hashtags
      tweet.media_serialized = status.attrs.dig(:entities, :media)
      tweet.mentioned_usernames_serialized = status.user_mentions.as_json
      tweet.urls_serialized = status.urls

      tweet
    end

    def extract_user_attributes(tweet, status)
      tweet.remote_profile_image_url = status.user.profile_image_url
      tweet.twitter_name = status.user.name
      tweet.twitter_uid = status.user.id.to_s
      tweet.twitter_user_followers_count = status.user.followers_count
      tweet.twitter_user_following_count = status.user.friends_count
      tweet.twitter_username = status.user.screen_name.downcase
      tweet.user_is_verified = status.user.verified?

      tweet
    end
  end
end
