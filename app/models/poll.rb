class Poll < ApplicationRecord
  validates :prompt_markdown, presence: true

  belongs_to :article
  has_many :poll_options
  has_many :poll_votes, through: :poll_options

  before_save :evaluate_markdown

  private

  def evaluate_markdown
    self.prompt_html = MarkdownParser.new(prompt_markdown).evaluate_inline_limited_markdown
  end
end
