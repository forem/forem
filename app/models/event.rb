class Event < ApplicationRecord
  resourcify
  include Taggable
  acts_as_taggable_on :tags

  belongs_to :user, optional: true
  belongs_to :organization, optional: true
  belongs_to :page, optional: true

  has_many :billboards, dependent: :destroy
  has_many :event_signups, dependent: :destroy
  has_many :signed_up_users, through: :event_signups, source: :user
  has_many :emails, dependent: :nullify

  enum :type_of, { live_stream: 0, takeover: 1, other: 2, challenge: 3 }
  enum :broadcast_config, { no_broadcast: 0, tagged_broadcast: 1, global_broadcast: 2 }

  validates :title, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :event_name_slug, presence: true,
                              format: { with: /\A[a-z0-9-]+\z/, message: "can only contain lowercase letters, numbers, and dashes" }
  validates :event_variation_slug, presence: true,
                                   format: { with: /\A[a-z0-9-]+\z/, message: "can only contain lowercase letters, numbers, and dashes" }, uniqueness: { scope: :event_name_slug, case_sensitive: false }
  validate :end_time_after_start_time
  validates :primary_stream_url,
            format: { with: %r{\Ahttps://(www\.)?(youtube\.com|youtu\.be|twitch\.tv|player\.twitch\.tv|streamyard\.com)/.*\z}, message: "must be a valid HTTPS YouTube, Twitch, or Streamyard URL" }, allow_blank: true
  validates :page, presence: true, if: :delegate_to_page?
  validates :bg_color_hex,
            format: { with: /\A#[0-9a-fA-F]{6}\z/, message: "must be a valid 6-digit hex color (e.g. #3B49DF)" },
            allow_blank: true

  before_validation :set_default_bg_color_hex
  before_save :format_stream_urls
  after_commit :ensure_broadcast_billboards_and_workers, on: %i[create update]
  after_commit :bust_upcoming_events_cache, on: %i[create update destroy]

  scope :published, -> { where(published: true) }
  scope :elevated, -> { where(elevated: true) }

  DEFAULT_HEX_COLORS = ["#3B49DF", "#0D9488", "#7C3AED", "#DB2777", "#D97706"].freeze
  def self.active_broadcast_events
    Rails.cache.fetch("active_broadcast_events", expires_in: 30.seconds) do
      published
        .where.not(broadcast_config: "no_broadcast")
        .where("start_time <= ? AND end_time >= ?", 15.minutes.from_now, 5.minutes.ago)
        .select(:id, :broadcast_config, :start_time, :end_time, :tags_array)
        .to_a
    end
  end

  mount_uploader :cover_image, EventCoverImageUploader

  def set_default_bg_color_hex
    return if bg_color_hex.present?

    first_supported = tags.detect { |t| t.supported? && t.bg_color_hex.present? }
    self.bg_color_hex = first_supported.bg_color_hex if first_supported.present?
  end

  def background_hex_color
    return bg_color_hex if bg_color_hex.present?

    color_index = (id || title.to_s.bytes.sum) % DEFAULT_HEX_COLORS.size
    DEFAULT_HEX_COLORS[color_index]
  end

  def gradient_background_css
    base_hex = background_hex_color
    dark_hex = adjust_hex_brightness(base_hex, 0.65)
    "linear-gradient(135deg, #{base_hex} 0%, #{dark_hex} 100%)"
  end

  def adjust_hex_brightness(hex, factor)
    clean_hex = hex.to_s.delete("#")
    return "#18181A" unless clean_hex.match?(/\A[0-9a-fA-F]{6}\z/)

    r = (clean_hex[0..1].to_i(16) * factor).round.clamp(0, 255)
    g = (clean_hex[2..3].to_i(16) * factor).round.clamp(0, 255)
    b = (clean_hex[4..5].to_i(16) * factor).round.clamp(0, 255)

    format("#%<r>02x%<g>02x%<b>02x", r: r, g: g, b: b)
  end

  def social_image_url
    if cover_image.present?
      if cover_image.respond_to?(:social) && cover_image.social.present? && cover_image.social.url.present?
        cover_image.social.url
      else
        cover_image.url
      end
    else
      Settings::General.main_social_image.to_s
    end
  end

  def formatted_date_range
    return "" if start_time.blank?

    start_date = start_time.to_date
    end_date = (end_time || start_time).to_date

    if start_date == end_date
      start_date.strftime("%b %-d").upcase
    elsif start_date.month == end_date.month && start_date.year == end_date.year
      "#{start_date.strftime('%b %-d').upcase} - #{end_date.strftime('%-d')}"
    else
      "#{start_date.strftime('%b %-d').upcase} - #{end_date.strftime('%b %-d').upcase}"
    end
  end

  def location_display
    data&.dig("location") || data&.dig(:location) || "Everywhere, Worldwide"
  end

  def format_pill_label
    custom_format = data&.dig("format") || data&.dig(:format)
    return custom_format.to_s.upcase if custom_format.present?

    case type_of
    when "live_stream"
      "DIGITAL"
    when "challenge"
      "CHALLENGE"
    when "takeover"
      "TAKEOVER"
    else
      "EVENT"
    end
  end

  def as_json(options = nil)
    super(options).merge(
      "background_hex_color" => background_hex_color,
      "cover_image_url" => cover_image&.url,
      "social_image_url" => social_image_url,
      "formatted_date_range" => formatted_date_range,
      "location" => location_display,
      "format" => format_pill_label,
      "tag_list" => tag_list,
    )
  end

  def signup_button_text(signed_up: false)
    if challenge?
      signed_up ? "Signed Up" : "Sign Up"
    else
      signed_up ? "Interested" : "I'm Interested"
    end
  end

  def signup_confirm_message
    if challenge?
      "Are you sure you want to cancel your sign up?"
    else
      "Are you sure you want to cancel your interest?"
    end
  end

  private

  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?

    return unless end_time < start_time

    errors.add(:end_time, "must be after the start time")
  end

  def format_stream_urls
    return if primary_stream_url.blank?

    app_domain = Settings::General.app_domain.split(":")[0]
    self.data ||= {}

    youtube_match = primary_stream_url.match(%r{(?:youtu\.be/|youtube\.com/(?:watch\?v=|embed/|live/|v/|shorts/))([a-zA-Z0-9_-]{11})}i) ||
      primary_stream_url.match(/[?&]v=([a-zA-Z0-9_-]{11})/i) ||
      primary_stream_url.match(/\A([a-zA-Z0-9_-]{11})\z/)

    if youtube_match
      video_id = youtube_match[1]
      self.primary_stream_url = "https://www.youtube.com/embed/#{video_id}?autoplay=1"
      self.data["chat_url"] = "https://www.youtube.com/live_chat?v=#{video_id}&embed_domain=#{app_domain}"
    elsif primary_stream_url.match?(/twitch\.tv/i)
      channel_name = nil
      match = if primary_stream_url.include?("channel=")
                primary_stream_url.match(/channel=([a-zA-Z0-9_]+)/i)
              else
                primary_stream_url.match(%r{twitch\.tv/([a-zA-Z0-9_]+)}i)
              end
      channel_name = match[1] if match

      if channel_name && %w[videos clip clips directory].exclude?(channel_name.downcase)
        self.primary_stream_url = "https://player.twitch.tv/?channel=#{channel_name}&parent=#{app_domain}"
        self.data["chat_url"] = "https://www.twitch.tv/embed/#{channel_name}/chat?parent=#{app_domain}"
      end
    elsif primary_stream_url.match?(/streamyard\.com/i)
      begin
        uri = URI.parse(primary_stream_url)
        path_segments = uri.path.split("/").compact_blank
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
    base_name = "#{prefix}_#{Time.zone.now.strftime('%B').downcase}_#{Time.zone.now.strftime('%d')}_#{stream_hour}_#{Time.zone.now.strftime('%Y')}"

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
      published: true,
    )

    post_bottom_bb = billboards.find_or_initialize_by(placement_area: "post_fixed_bottom")
    post_bottom_attributes = {
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
    }

    if live_stream?
      post_bottom_attributes[:special_behavior] = "persistent"
      post_bottom_attributes[:minimized_body_markdown] = generator.minimized_post_html
    end

    post_bottom_bb.update!(post_bottom_attributes)
  end

  def bust_upcoming_events_cache
    Rails.cache.delete("upcoming_elevated_events")
  end
end
