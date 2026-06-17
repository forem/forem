class EventSignup < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :user_id, presence: true
  validates :event_id, presence: true
  validates :user_id, uniqueness: { scope: :event_id, message: "has already signed up for this event" }

  before_validation :initialize_notification_flags, on: :create

  private

  def initialize_notification_flags
    return unless event&.start_time

    # Skip the "1 day" reminder if we're already inside the last 23 hours.
    self.notified_1_day_before = event.start_time < Time.current + 23.hours

    # Skip the "1 hour" reminder only once the event has started.
    self.notified_1_hour_before = event.start_time <= Time.current
  end
end
