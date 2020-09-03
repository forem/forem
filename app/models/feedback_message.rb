class FeedbackMessage < ApplicationRecord
  resourcify

  belongs_to :offender, class_name: "User", optional: true, inverse_of: :offender_feedback_messages
  belongs_to :reporter, class_name: "User", optional: true, inverse_of: :reporter_feedback_messages
  belongs_to :affected, class_name: "User", optional: true, inverse_of: :affected_feedback_messages
  has_many :notes, as: :noteable, inverse_of: :noteable, dependent: :destroy

  validates :feedback_type, :message, presence: true
  validates :reported_url, :category, presence: { if: :abuse_report? }, length: { maximum: 250 }
  validates :message, length: { maximum: 2500 }
  validates :category,
            inclusion: {
              in: ["spam", "other", "rude or vulgar", "harassment", "bug", "listings"]
            }
  validates :status,
            inclusion: {
              in: %w[Open Invalid Resolved]
            }
  validates :reporter_id, uniqueness: { scope: %i[reported_url feedback_type] }, if: :abuse_report? && :reporter_id

  def abuse_report?
    feedback_type == "abuse-reports"
  end

  def capitalize_status
    self.status = status.capitalize if status.present?
  end

  def user_types(user_id)
    types = []
    types << "Affected" if user_id == affected_id
    types << "Offender" if user_id == offender_id
    types << "Reporter" if user_id == reporter_id
    types
  end
end
