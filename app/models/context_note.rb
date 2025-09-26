class ContextNote < ApplicationRecord
  belongs_to :article
  belongs_to :tag, optional: true

  validates :body_markdown, presence: true, length: { in: 10..75 }
  validates :processed_html, presence: true
  validates :article, uniqueness: { scope: :tag, message: "already has a context note for this tag" }

  before_validation :process_body_markdown

  private

  def process_body_markdown
    return if body_markdown.blank?

    parsed_markdown = MarkdownProcessor::Parser.new(body_markdown)
    self.processed_html = parsed_markdown.finalize
  end
end
