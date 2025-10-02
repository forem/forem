# @note When we destroy the related poll, it's using dependent:
#       :delete for the relationship.  That means no before/after
#       destroy callbacks will be called on this object.
class PollOption < ApplicationRecord
  belongs_to :poll
  has_many :poll_votes, dependent: :destroy

  validates :markdown, presence: true, length: { maximum: 256 }
  validates :poll_votes_count, presence: true

  before_save :evaluate_markdown

  counter_culture :poll

  private

  def evaluate_markdown
    self.processed_html = MarkdownProcessor::Parser.new(markdown).evaluate_inline_limited_markdown
  end
end
