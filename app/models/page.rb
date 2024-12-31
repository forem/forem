class Page < ApplicationRecord
  extend UniqueAcrossModels
  TEMPLATE_OPTIONS = %w[contained full_within_layout nav_bar_included json css txt].freeze

  TERMS_SLUG = "terms".freeze
  CODE_OF_CONDUCT_SLUG = "code-of-conduct".freeze
  PRIVACY_SLUG = "privacy".freeze

  has_many :billboards, dependent: :nullify
  belongs_to :subforem, optional: true

  validates :title, presence: true
  validates :description, presence: true
  validates :template, inclusion: { in: TEMPLATE_OPTIONS }
  validate :body_present

  unique_across_models :slug

  before_validation :set_default_template
  before_save :evaluate_markdown

  after_commit :ensure_uniqueness_of_landinge_page
  after_commit :bust_cache

  mount_uploader :social_image, ProfileImageUploader
  resourcify

  scope :from_subforem, lambda { |subforem_id = nil|
    subforem_id ||= RequestStore.store[:subforem_id]
    where(subforem_id: [subforem_id, nil])
  }

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

  def as_json(...)
    super(...).slice(*%w[id title slug description is_top_level_path landing_page
                         body_html body_json body_markdown processed_html
                         social_image template ])
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
    return unless body_markdown.blank? && body_html.blank? && body_json.blank? && body_css.blank?

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
