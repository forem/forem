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
  validates :primary_stream_url, format: { with: /\Ahttps:\/\/(www\.)?(youtube\.com|youtu\.be|twitch\.tv|player\.twitch\.tv)\/.*\z/, message: "must be a valid HTTPS YouTube or Twitch URL" }, allow_blank: true

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
    end
  end

  def ensure_broadcast_billboards_and_workers
    return if no_broadcast?

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
      body_markdown: generated_takeover_feed_html,
      organization_id: organization_id,
      creator_id: user_id,
      color: "#18181A",
      render_mode: "raw",
      template: "plain",
      approved: home_feed_bb.new_record? ? false : home_feed_bb.approved,
      published: true
    )

    post_bottom_bb = billboards.find_or_initialize_by(placement_area: "post_fixed_bottom")
    post_bottom_bb.update!(
      name: "#{base_name}_post",
      dismissal_sku: base_name,
      custom_display_label: custom_display_label,
      body_markdown: generated_takeover_post_html,
      organization_id: organization_id,
      creator_id: user_id,
      color: "#18181A",
      render_mode: "raw",
      template: "plain",
      approved: post_bottom_bb.new_record? ? false : post_bottom_bb.approved,
      published: true
    )
  end

  def generated_takeover_post_html
    image_url = data["image_url"] || organization&.profile_image_url || user&.profile_image_url
    link = "/events/#{event_name_slug}/#{event_variation_slug}"
    
    <<~HTML
      <style>
        .bb-grid-container {
          display: grid;
          gap: 25px;
          grid-template-columns: 1fr;
          width: 100%;
        }
        .bb-grid-item--first {
          display: none;
        }
        @media (min-width: 1280px) {
          .popover-billboard .crayons-bb__header,
          .popover-billboard .text-styles {
          }
          .popover-billboard .text-styles {
            font-size: 1.22em;
          }
        }
        .crayons-bb__title {
          color: var(--label-secondary);
          font-size: var(--fs-s);
          line-height: var(--lh-base);
          margin-left: var(--su-1);
          align-self: center;
        }
        .crayons-bb__header {
          width: 100%;
          display: flex;
          align-items: center;
        }
        #event-takeover-image {
          width: 100%;
          height: 70%;
          object-fit: cover;
        }
        @media (min-width: 768px) {
          #event-takeover-image {
            height: 340px;
          }
          .bb-grid-container {
            grid-template-columns: 1fr 1fr;
          }
          .bb-grid-item--first {
            display: block;
          }
        }
        @media (min-width: 1000px) {
          .crayons-card[data-id="93431"] {
            padding-left: 8px !important;
          }
        }
      </style>
  
      <div class="bb-grid-container">
        <div class="bb-grid-item bb-grid-item--first">
          <img
            id="event-takeover-image"
            src="#{image_url}"
            alt="#{title}"
            style="border-radius:12px;margin-bottom:20px!important"
          />
        </div>
        <div class="bb-grid-item">
          <h1 style="font-size:calc(18px + 0.75vw);margin:25px auto;margin-top:0px!important">
            #{title}
          </h1>
          <p style="opacity:0.9;margin-bottom:30px;font-size:calc(1em - 0.15vw);">
            #{description}
          </p>
          <p style="margin-bottom:20px">
            <a
              href="#{link}"
              class="ltag_cta ltag_cta--branded"
              role="button"
              style="font-weight:bold;border-width:2px;width:100%;padding:15px 2px;text-align:center!important;font-size:calc(16px + 0.6vw);display:block"
            >
              Tune in to the full event
            </a>
          </p>
          <p style="font-size:0.7em;opacity:0.8;margin-bottom:8px;font-style:italic">
            #{Settings::Community.community_name} is partnering to bring live events to the community. Join us or dismiss this billboard if you're not interested. ❤️
          </p>
        </div>
      </div>
    HTML
  end
  
  def generated_takeover_feed_html
    image_url = data["image_url"] || organization&.profile_image_url || user&.profile_image_url
    link = "/events/#{event_name_slug}/#{event_variation_slug}"
    
    <<~HTML
      <style>
        #event-takeover-image-feed {
          width: 100%;
          height: 51vw;
          object-fit: cover;
        }
        @media (min-width: 768px) {
          #event-takeover-image-feed {
            height: 340px;
          }
        }
      </style>
  
      <h1 style="font-size:calc(18px + 0.75vw);margin: 25px auto;margin-top:15px !important">
        #{title}
      </h1>
  
      <img
        id="event-takeover-image-feed"
        src="#{image_url}"
        alt="#{title}"
        style="border-radius:12px;margin-bottom:20px !important"
      />
  
      <p style="opacity:0.9;margin-bottom:12px;font-size:calc(1em + 0.1vw);">
        #{description}
      </p>
  
      <p style="margin-bottom:15px">
        <a
          href="#{link}"
          class="ltag_cta ltag_cta--branded"
          role="button"
          style="font-weight:bold;border-width:2px;width:100%;padding:15px 2px;text-align:center !important;font-size:calc(16px + 0.6vw);display:block"
        >
          Tune in to the full event
        </a>
      </p>
  
      <p style="font-size:0.9em;opacity:0.8;margin-bottom:8px;font-style:italic">
        #{Settings::Community.community_name} is partnering to bring live events to the community. Join us or dismiss this billboard if you're not interested. ❤️
      </p>
    HTML
  end
end
