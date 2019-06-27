class Page < ApplicationRecord
  validates :title, presence: true
  validates :description, presence: true
  validates :slug, presence: true, format: /\A[0-9a-z\-_]*\z/
  validates :template, inclusion: { in: %w[contained full_within_layout full_page] }
  validate :body_present
  validate :unique_slug_including_users_and_orgs, if: :slug_changed?

  before_save :evaluate_markdown
  after_save :bust_cache
  before_validation :set_default_template

  mount_uploader :social_image, ProfileImageUploader

  def path
    is_top_level_path ? "/#{slug}" : "/page/#{slug}"
  end

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

  def unique_slug_including_users_and_orgs
    errors.add(:slug, "is taken.") if User.find_by(username: slug) || Organization.find_by(slug: slug) || Podcast.find_by(slug: slug)
  end

  def bust_cache
    Pages::BustCacheJob.perform_later(slug)
  end
end
