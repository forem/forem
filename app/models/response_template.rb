class ResponseTemplate < ApplicationRecord
  belongs_to :user, optional: true
  validates :type_of, :content_type, :content, :title, presence: true
  validates :content, uniqueness: { scope: %i[user_id type_of content_type] }
  validates :type_of, inclusion: { in: %w[personal_comment mod_comment abuse_report_reply email_reply] }
  validates :content_type, inclusion: { in: %w[plain_text html body_markdown] }
  validates :content_type,
            inclusion: { in: %w[body_markdown], message: "Comment templates must use Markdown as its content type." },
            if: -> { type_of&.include?("comment") }
end
