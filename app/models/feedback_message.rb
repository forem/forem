class FeedbackMessage < ApplicationRecord
  belongs_to :offender, foreign_key: "offender_id", class_name: "User", optional: true
  belongs_to :reviewer, foreign_key: "reviewer_id", class_name: "User", optional: true
  belongs_to :reporter, foreign_key: "reporter_id", class_name: "User", optional: true
  belongs_to :victim, foreign_key: "victim_id", class_name: "User", optional: true
  has_many :notes, as: :noteable, dependent: :destroy

  validates_presence_of :feedback_type, :message
  validates_presence_of :reported_url, :category, if: :abuse_report?
  validates :category,
            inclusion: {
              in: ["spam", "other", "rude or vulgar", "harassment", "bug"],
            }

  before_validation :generate_slug

  def abuse_report?
    feedback_type == "abuse-reports"
  end

  def generate_slug
    self.slug = SecureRandom.hex(10) unless slug?
  end

  def capitalize_status
    self.status = status.capitalize unless status.blank?
  end

  def to_eastern_strftime(time)
    return if time.nil?
    time.in_time_zone("America/New_York").strftime("%A, %b %d %Y - %I:%M %p %Z")
  end

  def path
    "/reports/#{slug}"
  end
end
