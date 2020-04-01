class PollOption < ApplicationRecord
  self.ignored_columns = %w[
    counts_in_tabulation
  ]

  belongs_to :poll
  has_many :poll_votes

  validates :markdown, presence: true,
                       length: { maximum: 128 }

  before_save :evaluate_markdown

  counter_culture :poll

  private

  def evaluate_markdown
    self.processed_html = MarkdownParser.new(markdown).evaluate_inline_limited_markdown
  end
end
