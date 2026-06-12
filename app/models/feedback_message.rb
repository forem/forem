class FeedbackMessage < ApplicationRecord
  resourcify

  belongs_to :offender, class_name: "User", optional: true, inverse_of: :offender_feedback_messages
  belongs_to :reporter, class_name: "User", optional: true, inverse_of: :reporter_feedback_messages
  belongs_to :affected, class_name: "User", optional: true, inverse_of: :affected_feedback_messages
  belongs_to :reported, polymorphic: true, optional: true

  has_one :email_message, dependent: :nullify
  has_many :notes, as: :noteable, inverse_of: :noteable, dependent: :destroy

  REPORTER_UNIQUENESS_SCOPE = %i[reported_url feedback_type].freeze
  CATEGORIES = ["spam", "other", "rude or vulgar", "harassment", "bug", "listings"].freeze
  STATUSES = %w[Open Invalid Resolved].freeze

  before_save :determine_reported_from_url

  def self.reporter_uniqueness_msg
    I18n.t("models.feedback_message.reported")
  end

  scope :open_abuse_reports, -> { where(status: "Open", feedback_type: "abuse-reports") }
  scope :all_user_reports, lambda { |user|
    user.reporter_feedback_messages
      .or(user.affected_feedback_messages)
      .or(user.offender_feedback_messages)
  }
  scope :with_valid_reported_score, lambda { |score_min|
    joins(<<~SQL)
      LEFT OUTER JOIN users AS reported_users 
        ON feedback_messages.reported_type = 'User' 
        AND reported_users.id = feedback_messages.reported_id
      LEFT OUTER JOIN articles AS reported_articles 
        ON feedback_messages.reported_type = 'Article' 
        AND reported_articles.id = feedback_messages.reported_id
      LEFT OUTER JOIN comments AS reported_comments 
        ON feedback_messages.reported_type = 'Comment' 
        AND reported_comments.id = feedback_messages.reported_id
    SQL
    .where(<<~SQL, score_min: score_min)
      feedback_messages.reported_id IS NULL OR
      feedback_messages.reported_type IS NULL OR
      (feedback_messages.reported_type = 'User' AND (reported_users.score IS NULL OR reported_users.score > :score_min)) OR
      (feedback_messages.reported_type = 'Article' AND (reported_articles.score IS NULL OR reported_articles.score > :score_min)) OR
      (feedback_messages.reported_type = 'Comment' AND (reported_comments.score IS NULL OR reported_comments.score > :score_min)) OR
      (feedback_messages.reported_type NOT IN ('User', 'Article', 'Comment'))
    SQL
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
  validates :reporter_id, uniqueness: { scope: REPORTER_UNIQUENESS_SCOPE, message: reporter_uniqueness_msg },
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

  def determine_reported_from_url
    return unless abuse_report?
    return unless reported_url.present?
    return unless reported_url.start_with?(URL.url("/")) || reported_url.start_with?("/")
    return if reported

    reported_entity = matched_to_entity(reported_url)

    self.reported = reported_entity if reported_entity
  rescue StandardError
    nil
  end

  def matched_to_entity(url)
    return unless url.present?

    path = URI.parse(url).path
    case path
    when %r{\/admin\/customization\/billboards\/\d+}
      # Billboard: /admin/customization/billboards/124822
      billboard_id = path.split("/").last
      Billboard.find_by(id: billboard_id)
    when %r{\/[a-zA-Z0-9_]+\/comment\/[a-zA-Z0-9_]+}
      # Comment: /username/comment/id_code
      username, id_code = path.split("/")[1], path.split("/").last
      user = User.find_by(username: username)
      user&.comments&.find_by(id_code: id_code)
    when %r{\/[a-zA-Z0-9_]+\/[a-zA-Z0-9_-]+}
      # Article: /username/slug
      username, slug = path.split("/")[1], path.split("/").last
      user = User.find_by(username: username)
      user&.articles&.find_by(slug: slug)
    when %r{\/[a-zA-Z0-9_]+}
      # User: /username
      username = path.split("/").last
      User.find_by(username: username)
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    ["affected_id", "category", "created_at", "feedback_type", "id", "message", "offender_id", "reported_id", "reported_type", "reported_url", "reporter_id", "status", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["offender", "reporter", "affected", "reported"]
  end
end
