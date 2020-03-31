class FeedbackMessage < ApplicationRecord
  belongs_to :offender, foreign_key: "offender_id", class_name: "User", optional: true, inverse_of: :offender_feedback_messages
  belongs_to :reporter, foreign_key: "reporter_id", class_name: "User", optional: true, inverse_of: :reporter_feedback_messages
  belongs_to :affected, foreign_key: "affected_id", class_name: "User", optional: true, inverse_of: :affected_feedback_messages
  has_many :notes, as: :noteable, inverse_of: :noteable, dependent: :destroy

  validates :feedback_type, :message, presence: true
  validates :reported_url, :category, presence: { if: :abuse_report? }
  validates :category,
            inclusion: {
              in: ["spam", "other", "rude or vulgar", "harassment", "bug", "listings"]
            }
  validates :status,
            inclusion: {
              in: %w[Open Invalid Resolved]
            }

  def abuse_report?
    feedback_type == "abuse-reports"
  end

  def capitalize_status
    self.status = status.capitalize if status.present?
  end
end
