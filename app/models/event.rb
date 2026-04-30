class Event < ApplicationRecord
  include Taggable
  acts_as_taggable_on :tags

  belongs_to :user, optional: true
  belongs_to :organization, optional: true

  has_many :billboards, foreign_key: :event_id, dependent: :destroy

  enum type_of: { live_stream: 0, takeover: 1, other: 2 }
  enum broadcast_config: { no_broadcast: 0, tagged_broadcast: 1, global_broadcast: 2 }

  validates :title, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :event_name_slug, presence: true, format: { with: /\A[a-z0-9-]+\z/, message: "can only contain lowercase letters, numbers, and dashes" }
  validates :event_variation_slug, presence: true, format: { with: /\A[a-z0-9-]+\z/, message: "can only contain lowercase letters, numbers, and dashes" }, uniqueness: { scope: :event_name_slug, case_sensitive: false }
  validate :end_time_after_start_time
  validates :primary_stream_url, format: { with: /\Ahttps:\/\/(www\.)?(youtube\.com|youtu\.be|twitch\.tv|player\.twitch\.tv|streamyard\.com)\/.*\z/, message: "must be a valid HTTPS YouTube, Twitch, or Streamyard URL" }, allow_blank: true

  before_save :format_stream_urls
  after_commit :ensure_broadcast_billboards_and_workers, on: [:create, :update]

  scope :published, -> { where(published: true) }

  def self.active_broadcast_events
    Rails.cache.fetch("active_broadcast_events", expires_in: 30.seconds) do
      published
        .where.not(broadcast_config: "no_broadcast")
        .where("start_time <= ? AND end_time >= ?", Time.current + 15.minutes, Time.current - 5.minutes)
        .select(:id, :broadcast_config, :start_time, :end_time, :tags_array)
        .to_a
    end
  end

  private

  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?

    if end_time < start_time
      errors.add(:end_time, "must be after the start time")
    end
  end

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
      self.data["chat_url"] = "https://www.youtube.com/live_chat?v=#{video_id}&embed_domain=#{app_domain}"
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
        self.data["chat_url"] = "https://www.twitch.tv/embed/#{channel_name}/chat?parent=#{app_domain}"
      end
    elsif primary_stream_url.match?(%r{streamyard\.com}i)
      begin
        uri = URI.parse(primary_stream_url)
        path_segments = uri.path.split('/').reject(&:blank?)
        if path_segments.any?
          streamyard_id = path_segments.last
          self.primary_stream_url = "https://streamyard.com/e/#{streamyard_id}"
        end
      rescue URI::InvalidURIError
        # ignore, allow the url to pass through as is if unparseable
      end
    end
  end

  def ensure_broadcast_billboards_and_workers
    return if no_broadcast?

    generator = case type_of
                when "live_stream"
                  Events::Billboards::LiveStream.new(self)
                when "takeover"
                  Events::Billboards::Takeover.new(self)
                else
                  return
                end

    prefix = takeover? ? "takeover" : "live_now"
    stream_hour = start_time.strftime("%H")
    base_name = "#{prefix}_#{Time.now.strftime('%B').downcase}_#{Time.now.strftime('%d')}_#{stream_hour}_#{Time.now.strftime('%Y')}"
    
    custom_display_label = takeover? ? "#{Settings::Community.community_name} Takeovers" : "#{Settings::Community.community_name} Live Events"

    # Only process if it has a published state linking (though we generate them regardless)
    # Billboard templates
    home_feed_bb = billboards.find_or_initialize_by(placement_area: "feed_first")
    home_feed_bb.update!(
      name: "#{base_name}_feed",
      dismissal_sku: base_name,
      custom_display_label: custom_display_label,
      body_markdown: generator.feed_html,
      organization_id: organization_id,
      creator_id: user_id,
      color: "#18181A",
      render_mode: "raw",
      template: "authorship_box",
      approved: home_feed_bb.new_record? ? false : home_feed_bb.approved,
      published: true
    )

    post_bottom_bb = billboards.find_or_initialize_by(placement_area: "post_fixed_bottom")
    post_bottom_bb.update!(
      name: "#{base_name}_post",
      dismissal_sku: base_name,
      custom_display_label: custom_display_label,
      body_markdown: generator.post_html,
      organization_id: organization_id,
      creator_id: user_id,
      color: "#18181A",
      render_mode: "raw",
      template: "authorship_box",
      approved: post_bottom_bb.new_record? ? false : post_bottom_bb.approved,
      published: true
    )
  end
end
