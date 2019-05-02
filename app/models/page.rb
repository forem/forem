class Page < ApplicationRecord
  validates :title, presence: true
  validates :description, presence: true
  validates :slug, presence: true, format: /\A[0-9a-z\-_]*\z/
  validates :template, inclusion: { in: %w[contained full_within_layout full_page] }
  validate :body_present

  before_save :evaluate_markdown
  before_save :bust_cache
  before_validation :set_default_template

  mount_uploader :social_image, ProfileImageUploader

  private

  def evaluate_markdown
    if body_markdown.present?
      parsed_markdown = MarkdownParser.new(body_markdown)
      self.processed_html = parsed_markdown.finalize
    else
      self.processed_html = body_html
    end
  end

  def set_default_template
    self.template = "contained" if template.blank?
  end

  def body_present
    errors.add(:body_markdown, "must exist if body_html doesn't exist.") if body_markdown.blank? && body_html.blank?
  end

  def bust_cache
    CacheBuster.new.bust "/page/"
    CacheBuster.new.bust "/page/#{slug}?i=i"
  end
end
