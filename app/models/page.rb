class Page < ApplicationRecord
  TEMPLATE_OPTIONS = %w[contained full_within_layout nav_bar_included json].freeze

  TERMS_SLUG = "terms".freeze
  CODE_OF_CONDUCT_SLUG = "code-of-conduct".freeze
  PRIVACY_SLUG = "privacy".freeze

  validates :title, presence: true
  validates :description, presence: true
  validates :slug, presence: true, format: /\A[0-9a-z\-_]*\z/
  validates :template, inclusion: { in: TEMPLATE_OPTIONS }
  validate :body_present
  validates :slug, unique_cross_model_slug: true, if: :slug_changed?

  before_validation :set_default_template
  before_save :evaluate_markdown

  after_commit :ensure_uniqueness_of_landinge_page
  after_commit :bust_cache

  mount_uploader :social_image, ProfileImageUploader
  resourcify

  # @param slug [String]
  #
  # @return An HTML safe String.
  #
  # @yield Yield to the calling context if there's no Page match for slug.
  #
  # @raise LocalJumpError when no matching slug nor block given.
  #
  # @note Yes, treating this value as HTML safe is risky.  But we already opened that vector by
  #       letting the administrator of pages write HTML.
  #
  # @todo Do we want to only allow certain slugs?
  #
  # rubocop:disable Rails/OutputSafety
  def self.render_safe_html_for(slug:)
    page = find_by(slug: slug)
    if page
      page.processed_html.html_safe
    else
      yield
    end
  end
  # rubocop:enable Rails/OutputSafety

  def self.landing_page
    find_by(landing_page: true)
  end

  def path
    is_top_level_path ? "/#{slug}" : "/page/#{slug}"
  end

  def feature_flag_name
    "page_#{slug}"
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

    errors.add(:body_markdown, I18n.t("models.page.body_must_exist"))
  end

  # As there can only be one global landing page, we want to ensure that
  # data integrity is preserved by setting `landing_page` to `false` for all
  # other pages if the current one was transformed into a landing page
  def ensure_uniqueness_of_landinge_page
    return unless previous_changes["landing_page"] == [false, true]

    Page.where.not(id: id).update_all(landing_page: false)
  end

  def bust_cache
    Pages::BustCacheWorker.perform_async(slug)
  end
end
