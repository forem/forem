class FeedbackMessage < ApplicationRecord
  resourcify

  belongs_to :offender, class_name: "User", optional: true, inverse_of: :offender_feedback_messages
  belongs_to :reporter, class_name: "User", optional: true, inverse_of: :reporter_feedback_messages
  belongs_to :affected, class_name: "User", optional: true, inverse_of: :affected_feedback_messages

  has_one :email_message, dependent: :nullify
  has_many :notes, as: :noteable, inverse_of: :noteable, dependent: :destroy

  REPORTER_UNIQUENESS_SCOPE = %i[reported_url feedback_type].freeze
  REPORTER_UNIQUENESS_MSG = "(you) previously reported this URL.".freeze
  CATEGORIES = ["spam", "other", "rude or vulgar", "harassment", "bug", "listings"].freeze
  STATUSES = %w[Open Invalid Resolved].freeze

  scope :open_abuse_reports, -> { where(status: "Open", feedback_type: "abuse-reports") }
  scope :all_user_reports, lambda { |user|
    user.reporter_feedback_messages
      .or(user.affected_feedback_messages)
      .or(user.offender_feedback_messages)
  }

  validates :feedback_type, :message, presence: true
  validates :reported_url, :category, presence: { if: :abuse_report? }, length: { maximum: 250 }
  validates :message, length: { maximum: 2500 }
  validates :category,
            inclusion: {
              in: CATEGORIES
            }
  validates :status,
            inclusion: {
              in: STATUSES
            }
  validates :reporter_id, uniqueness: { scope: REPORTER_UNIQUENESS_SCOPE, message: REPORTER_UNIQUENESS_MSG },
                          if: :abuse_report? && :reporter_id

  def abuse_report?
    feedback_type == "abuse-reports"
  end

  def user_types(user_id)
    types = []
    types << "Affected" if user_id == affected_id
    types << "Offender" if user_id == offender_id
    types << "Reporter" if user_id == reporter_id
    types
  end
end
