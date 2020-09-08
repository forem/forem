class PollOption < ApplicationRecord
  belongs_to :poll
  has_many :poll_votes, dependent: :destroy

  validates :markdown, presence: true, length: { maximum: 128 }

  before_save :evaluate_markdown

  counter_culture :poll

  private

  def evaluate_markdown
    self.processed_html = MarkdownParser.new(markdown).evaluate_inline_limited_markdown
  end
end
