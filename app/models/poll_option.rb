class PollOption < ApplicationRecord
  belongs_to :poll
  has_many :poll_votes

  before_save :evaluate_markdown

  private

  def evaluate_markdown
    self.processed_html = MarkdownParser.new(markdown).evaluate_inline_limited_markdown
  end
end
