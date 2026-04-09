class Event < ApplicationRecord
  include Taggable
  acts_as_taggable_on :tags

  belongs_to :user, optional: true
  belongs_to :organization, optional: true

  enum type_of: { live_stream: 0, takeover: 1, other: 2 }

  validates :title, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :event_name_slug, presence: true, format: { with: /\A[a-z0-9-]+\z/, message: "can only contain lowercase letters, numbers, and dashes" }
  validates :event_variation_slug, presence: true, format: { with: /\A[a-z0-9-]+\z/, message: "can only contain lowercase letters, numbers, and dashes" }, uniqueness: { scope: :event_name_slug, case_sensitive: false }

  before_save :format_stream_urls

  scope :published, -> { where(published: true) }

  private

  def format_stream_urls
    return if primary_stream_url.blank?

    app_domain = Settings::General.app_domain.split(":")[0]
    self.data ||= {}

    youtube_match = primary_stream_url.match(%r{(?:youtu\.be/|youtube\.com/(?:watch\?v=|embed/|live/|v/|shorts/))([a-zA-Z0-9_-]{11})}i) ||
                    primary_stream_url.match(%r{[?&]v=([a-zA-Z0-9_-]{11})}i) ||
                    primary_stream_url.match(/\A([a-zA-Z0-9_-]{11})\z/)

    if youtube_match
      video_id = youtube_match[1]
      self.primary_stream_url = "https://www.youtube.com/embed/#{video_id}?autoplay=1"
      self.data["chat_url"] = "https://www.youtube.com/live_chat?v=#{video_id}&embed_domain=#{app_domain}" if self.data["chat_url"].blank?
    elsif primary_stream_url.match?(%r{twitch\.tv}i)
      channel_name = nil
      if primary_stream_url.include?("channel=")
        match = primary_stream_url.match(/channel=([a-zA-Z0-9_]+)/i)
        channel_name = match[1] if match
      else
        match = primary_stream_url.match(%r{twitch\.tv/([a-zA-Z0-9_]+)}i)
        channel_name = match[1] if match
      end

      if channel_name && !%w[videos clip clips directory].include?(channel_name.downcase)
        self.primary_stream_url = "https://player.twitch.tv/?channel=#{channel_name}&parent=#{app_domain}"
        self.data["chat_url"] = "https://www.twitch.tv/embed/#{channel_name}/chat?parent=#{app_domain}" if self.data["chat_url"].blank?
      end
    end
  end
end
