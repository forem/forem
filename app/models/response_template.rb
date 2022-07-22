#  @note When we destroy the related user, it's using dependent:
#        :delete for the relationship.  That means no before/after
#        destroy callbacks will be called on this object.
class ResponseTemplate < ApplicationRecord
  resourcify

  belongs_to :user, optional: true

  TYPE_OF_TYPES = %w[personal_comment mod_comment abuse_report_email_reply email_reply tag_adjustment].freeze
  USER_NIL_TYPE_OF_TYPES = %w[mod_comment abuse_report_email_reply email_reply tag_adjustment].freeze
  CONTENT_TYPES = %w[plain_text html body_markdown].freeze
  COMMENT_CONTENT_TYPE = %w[body_markdown].freeze
  EMAIL_CONTENT_TYPES = %w[plain_text html].freeze

  validates :type_of, :content_type, :content, :title, presence: true
  validates :content, uniqueness: { scope: %i[user_id type_of content_type] }
  validates :type_of, inclusion: { in: TYPE_OF_TYPES }
  validates :content_type, inclusion: { in: CONTENT_TYPES }
  validates :content_type,
            inclusion: { in: COMMENT_CONTENT_TYPE,
                         message: proc { I18n.t("models.response_template.comment_markdown") } },
            if: -> { type_of&.include?("comment") }
  validates :content_type,
            inclusion: { in: EMAIL_CONTENT_TYPES,
                         message: proc { I18n.t("models.response_template.email_text") } },
            if: -> { type_of&.include?("email") }
  validate :user_nil_only_for_user_nil_types
  validate :template_count

  attribute :user_identifier, :string

  def user_identifier
    user&.username
  end

  private

  def user_nil_only_for_user_nil_types
    return unless user_id.present? && USER_NIL_TYPE_OF_TYPES.include?(type_of)

    errors.add(:type_of, I18n.t("models.response_template.user_nil_only"))
  end

  def template_count
    return unless user
    return if user.trusted? || user.response_templates.count <= 30

    errors.add(:user, I18n.t("models.response_template.limit_reached"))
  end
end
