class EventSignup < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :user_id, presence: true
  validates :event_id, presence: true
  validates :user_id, uniqueness: { scope: :event_id, message: "has already signed up for this event" }

  before_validation :initialize_notification_flags, on: :create

  private

  def initialize_notification_flags
    return unless event

    if event.start_time <= Time.current + 24.hours
      self.notified_1_day_before = true
    end

    if event.start_time <= Time.current + 1.hour
      self.notified_1_hour_before = true
    end
  end
end
