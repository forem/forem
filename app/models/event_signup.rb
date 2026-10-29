class EventSignup < ApplicationRecord
  include ActivityTrackable

  belongs_to :user
  belongs_to :event

  validates :user_id, presence: true
  validates :event_id, presence: true
  validates :user_id, uniqueness: { scope: :event_id, message: "has already signed up for this event" }

  before_validation :initialize_notification_flags, on: :create
  after_create_commit :auto_follow_challenge_tags, if: -> { event&.challenge? }

  # === ActivityTrackable (Customer.io CDP activity events) ===
  # Challenges only; the :updated phase is reminder-flag bookkeeping.

  def trackable_activity_payload
    event.challenge_trackable_properties
  end

  def trackable_activity_event(phase)
    return unless event&.challenge?

    case phase
    when :created then "challenge_signed_up"
    when :destroyed then "challenge_unregistered"
    end
  end
  private :trackable_activity_payload, :trackable_activity_event

  private

  def auto_follow_challenge_tags
    return unless event&.challenge?

    tag_names = event.data&.dig("auto_follow_tag_names")
    tags = if tag_names.present?
             names = tag_names.split(",").map(&:strip).reject(&:blank?).uniq
             Tag.where(name: names)
           else
             [event.tags.first].compact
           end

    tags.each do |tag|
      user.follow(tag) unless user.following?(tag)
    end
  end

  def initialize_notification_flags
    return unless event&.start_time

    # Skip the "1 day" reminder if we're already inside the last 23 hours.
    self.notified_1_day_before = event.start_time < 23.hours.from_now

    # Skip the "1 hour" reminder only once the event has started.
    self.notified_1_hour_before = event.start_time <= Time.current
  end
end
