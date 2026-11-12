class Page < ApplicationRecord
  include LiquidEmbeddable
  extend UniqueAcrossModels
  EMBED_HTML_TEMPLATE = "embed_html".freeze
  TEMPLATE_OPTIONS = %w[contained full_within_layout nav_bar_included json css txt embed_html].freeze
  MAX_EMBED_HTML_BYTES = 256.kilobytes
  MAX_USER_EMBED_PAGES = 50

  TERMS_SLUG = "terms".freeze
  CODE_OF_CONDUCT_SLUG = "code-of-conduct".freeze
  PRIVACY_SLUG = "privacy".freeze
  PAGE_DIRECTORY_LIMIT = 6

  has_many :billboards, dependent: :nullify
  belongs_to :subforem, optional: true
  belongs_to :page_template, optional: true
  belongs_to :organization, optional: true
  belongs_to :user, optional: true

  validates :title, presence: true
  validates :description, presence: true
  validates :template, inclusion: { in: TEMPLATE_OPTIONS }
  validate :validate_owner_constraints
  validate :validate_embed_html_constraints
  validate :body_present
  validate :validate_template_data
  validate :validate_redirect_to_url

  validate :validate_slug_uniqueness

  before_validation :set_default_template
  before_validation :normalize_embed_html_attributes
  before_validation :evaluate_markdown
  before_save :render_from_page_template, if: :uses_page_template?
  before_create :enforce_user_embed_page_limit_with_lock, if: -> { user_id.present? && embed_html? }

  after_commit :ensure_uniqueness_of_landinge_page
  after_commit :bust_cache

  mount_uploader :social_image, ProfileImageUploader
  resourcify

  scope :embed_html, -> { where(template: EMBED_HTML_TEMPLATE) }
  scope :non_embed_html, -> { where.not(template: EMBED_HTML_TEMPLATE) }

  scope :from_subforem, lambda { |subforem_id = nil|
    return where(nil) if Subforem.disabled_by_env?

    subforem_id ||= RequestStore.store[:subforem_id]
    where(subforem_id: subforem_id ? [subforem_id, nil] : nil)
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
    page = non_embed_html.find_by(slug: slug)
    if page
      page.processed_html.html_safe
    else
      yield
    end
  end
  # rubocop:enable Rails/OutputSafety

  def self.landing_page
    non_embed_html.find_by(landing_page: true)
  end

  def embed_html?
    template == EMBED_HTML_TEMPLATE
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
                         social_image template subforem_id page_template_id template_data redirect_to_url
                         organization_id position])
  end

  def uses_page_template?
    page_template_id.present?
  end

  # Re-render the page from its template (called when template changes)
  def re_render_from_template!
    return unless uses_page_template?

    mark_liquid_embed_template_rerender!
    render_from_page_template
    save!
  end

  # Force evaluation of markdown (via before_save) and persist any resulting changes
  def recompile!
    save!
  end

  private

  def normalize_embed_html_attributes
    return unless embed_html?

    self.is_top_level_path = false
    self.landing_page = false
    self.redirect_to_url = nil
    self.page_template_id = nil
  end

  def evaluate_markdown
    if embed_html?
      self.body_markdown = nil
      self.processed_html = body_html
    elsif body_markdown.present?
      renderer = ContentRenderer.new(body_markdown, source: organization)
      self.processed_html = renderer.process(link_attributes: link_attributes_for_org).processed_html
    else
      self.processed_html = body_html
    end
  rescue ContentRenderer::ContentParsingError => e
    errors.add(:base, ErrorMessages::Clean.call(e.message))
  end

  def link_attributes_for_org
    return {} unless organization
    return {} if FeatureFlag.enabled?(:org_dofollow_links, FeatureFlag::Actor[organization])

    { rel: "nofollow ugc" }
  end

  def set_default_template
    self.template = "contained" if template.blank?
  end

  def validate_owner_constraints
    if organization_id.present? && user_id.present?
      errors.add(:base, I18n.t("models.page.multiple_owners_not_allowed"))
      return
    end

    return if user.blank?

    unless embed_html?
      errors.add(:template, I18n.t("models.page.user_page_must_be_embed_html"))
      return
    end

    return unless new_record? && user.pages.embed_html.count >= MAX_USER_EMBED_PAGES

    errors.add(:base, I18n.t("models.page.user_embed_pages_limit_reached", max: MAX_USER_EMBED_PAGES))
  end

  def enforce_user_embed_page_limit_with_lock
    User.where(id: user_id).lock.pick(:id)
    return unless Page.embed_html.where(user_id: user_id).count >= MAX_USER_EMBED_PAGES

    errors.add(:base, I18n.t("models.page.user_embed_pages_limit_reached", max: MAX_USER_EMBED_PAGES))
    throw(:abort)
  end

  def validate_embed_html_constraints
    if persisted? && template_changed? && (embed_html? || template_was == EMBED_HTML_TEMPLATE)
      errors.add(:template, I18n.t("models.page.embed_html_template_immutable"))
      return
    end

    return unless embed_html?

    if organization.blank? && user.blank?
      errors.add(:organization, I18n.t("models.page.embed_html_requires_organization"))
      return
    end

    if body_html.present? && body_html.bytesize > MAX_EMBED_HTML_BYTES
      errors.add(:body_html, I18n.t("models.page.embed_html_too_large", max_kb: MAX_EMBED_HTML_BYTES / 1.kilobyte))
    end

    validate_embed_html_slug
  end

  def validate_embed_html_slug
    if slug.blank?
      errors.add(:slug, I18n.t("models.page.embed_html_invalid_slug"))
      return
    end

    owner_slug = organization&.slug || user&.username
    valid_format = slug.match?(%r{\A[a-z0-9_\-]+/embed/[a-z0-9\-]+\z})
    expected_prefix = "#{owner_slug}/embed/"
    prefix_matches = !new_record? && !slug_changed? ? true : slug.start_with?(expected_prefix)
    return if valid_format && prefix_matches

    errors.add(:slug, I18n.t("models.page.embed_html_invalid_slug"))
  end

  def body_present
    if embed_html?
      errors.add(:body_html, I18n.t("models.page.body_must_exist")) if body_html.blank?
      return
    end

    # Skip body validation if using a page template
    return if uses_page_template?
    # Skip body validation if a redirect URL is set
    return if redirect_to_url.present?
    return unless body_markdown.blank? && body_html.blank? && body_json.blank? && body_css.blank?

    errors.add(:body_markdown, I18n.t("models.page.body_must_exist"))
  end

  def validate_template_data
    return unless uses_page_template? && page_template.present?

    validation_errors = page_template.validate_data(template_data || {})
    validation_errors.each do |error|
      errors.add(:template_data, error)
    end
  end

  def render_from_page_template
    return unless page_template.present?

    rendered_html = page_template.render_with_data(template_data || {})
    self.processed_html = rendered_html
    self.template = page_template.template_type
  end

  # As there can only be one global landing page, we want to ensure that
  # data integrity is preserved by setting `landing_page` to `false` for all
  # other pages if the current one was transformed into a landing page
  def ensure_uniqueness_of_landinge_page
    return unless previous_changes["landing_page"] == [false, true]

    Page.where.not(id: id).update_all(landing_page: false)
  end

  def bust_cache
    enqueue_page_cache_bust(slug, organization_id, user_id)

    previous_slug = saved_change_to_slug&.first
    return if previous_slug.blank? || previous_slug == slug

    previous_org_id = saved_change_to_organization_id ? saved_change_to_organization_id.first : organization_id
    previous_user_id = saved_change_to_user_id ? saved_change_to_user_id.first : user_id
    enqueue_page_cache_bust(previous_slug, previous_org_id, previous_user_id)
  end

  def enqueue_page_cache_bust(target_slug, target_organization_id, target_user_id = nil)
    # Keep the historical single-arg and two-arg forms so the
    # until_executing unique-job lock digest stays stable and jobs coalesce.
    if target_user_id
      Pages::BustCacheWorker.perform_async(target_slug, target_organization_id, target_user_id)
    elsif target_organization_id
      Pages::BustCacheWorker.perform_async(target_slug, target_organization_id)
    else
      Pages::BustCacheWorker.perform_async(target_slug)
    end
  end

  def validate_redirect_to_url
    return if redirect_to_url.blank?

    if redirect_to_url.start_with?("http://", "https://")
      begin
        uri = URI.parse(redirect_to_url)
        unless uri.host.present?
          errors.add(:redirect_to_url, I18n.t("models.page.redirect_to_url_invalid"))
        end
      rescue URI::InvalidURIError
        errors.add(:redirect_to_url, I18n.t("models.page.redirect_to_url_invalid"))
      end
    elsif redirect_to_url.start_with?("/")
      # Path: validate it corresponds to a recognized route in the app
      begin
        Rails.application.routes.recognize_path(redirect_to_url)
      rescue ActionController::RoutingError
        errors.add(:redirect_to_url, I18n.t("models.page.redirect_to_url_invalid_path"))
      end
    else
      errors.add(:redirect_to_url, I18n.t("models.page.redirect_to_url_invalid"))
    end
  end

  def validate_slug_uniqueness
    return if slug.blank?
    # Custom cross-model validation to allow for the same slug in different subforems for pages
    return if Page.where(slug: slug).exists? && Page.where(slug: slug, subforem_id: subforem_id).where.not(id: id).none?

    if Page.where(slug: slug, subforem_id: subforem_id).where.not(id: id).exists?
      errors.add(:slug, "has already been taken")
      return
    end

    if User.where(username: slug).exists? || Organization.where(slug: slug).exists? || Podcast.where(slug: slug).exists?
      errors.add(:slug, "is already taken by another entity")
      return
    end

    if slug.include?("sitemap-")
      errors.add(:slug, "is taken by sitemap directory")
      return
    end

    if slug.split("/").count > PAGE_DIRECTORY_LIMIT
      errors.add(:slug, "has too many subdirectories")
      return
    end
  end
end
