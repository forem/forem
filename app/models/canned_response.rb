class CannedResponse < ApplicationRecord
  belongs_to :user, optional: true
  validates :type_of, :content_type, :content, :title, presence: true
  validates :content, uniqueness: { scope: %i[user_id type_of content_type] }
  validates :content_type, inclusion: { in: %w[plain_text html body_markdown] }
  validates :content_type, inclusion: { in: %w[body_markdown] }, if: -> { type_of.include?("comment") }
end
