class Page < ApplicationRecord
  attr_accessor :overwrite_landing_page

  TEMPLATE_OPTIONS = %w[contained full_within_layout json].freeze

  validates :title, presence: true
  validates :description, presence: true
  validates :slug, presence: true, format: /\A[0-9a-z\-_]*\z/
  validates :template, inclusion: { in: TEMPLATE_OPTIONS }
  validate :body_present
  validate :unique_slug_including_users_and_orgs, if: :slug_changed?
  validate :single_landing_page, if: :will_save_change_to_landing_page?

  before_validation :set_default_template
  before_save :evaluate_markdown
  after_save :bust_cache

  mount_uploader :social_image, ProfileImageUploader
  resourcify

  def path
    is_top_level_path ? "/#{slug}" : "/page/#{slug}"
  end

  def feature_flag_name
    "page_#{slug}"
  end

  def self.landing_page
    find_by(landing_page: true)
  end

  private

  def evaluate_markdown
    if body_markdown.present?
      parsed_markdown = MarkdownProcessor::Parser.new(body_markdown)
      self.processed_html = parsed_markdown.finalize
    else
      self.processed_html = body_html
    end
  end

  def set_default_template
    self.template = "contained" if template.blank?
  end

  def body_present
    return unless body_markdown.blank? && body_html.blank? && body_json.blank?

    errors.add(:body_markdown, "must exist if body_html or body_json doesn't exist.")
  end

  def unique_slug_including_users_and_orgs
    slug_exists = (
      User.exists?(username: slug) ||
      Organization.exists?(slug: slug) ||
      Podcast.exists?(slug: slug) ||
      slug.include?("sitemap-")
    )
    return unless slug_exists

    errors.add(:slug, "is taken.")
  end

  def single_landing_page
    # Only add errors if we are trying to modify a landing page
    # while another landing page is already being used to ensure
    # that only one can be set to "true" at a time.

    landing_page = Page.where.not(id: id).find_by(landing_page: true)
    return unless landing_page

    errors.add(:base, "Only one page at a time can be used as a 'locked screen.'")
  end

  def bust_cache
    Pages::BustCacheWorker.perform_async(slug)
  end
end
