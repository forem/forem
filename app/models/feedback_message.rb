class FeedbackMessage < ApplicationRecord
  belongs_to :offender, foreign_key: "offender_id", class_name: "User", optional: true
  belongs_to :reviewer, foreign_key: "reviewer_id", class_name: "User", optional: true
  belongs_to :reporter, foreign_key: "reporter_id", class_name: "User", optional: true
  belongs_to :affected, foreign_key: "affected_id", class_name: "User", optional: true
  has_many :notes, as: :noteable, dependent: :destroy

  validates_presence_of :feedback_type, :message
  validates_presence_of :reported_url, :category, if: :abuse_report?
  validates :category,
            inclusion: {
              in: ["spam", "other", "rude or vulgar", "harassment", "bug"]
            }
  validates :status,
            inclusion: {
              in: ["Open", "Invalid", "Resolved"]
            }

  def abuse_report?
    feedback_type == "abuse-reports"
  end

  def capitalize_status
    self.status = status.capitalize unless status.blank?
  end
end
