class Organization < ApplicationRecord
  include CloudinaryHelper
  include PgSearch::Model
  include AlgoliaSearchable

  include Images::Profile.for(:profile_image_url)

  extend UniqueAcrossModels
  COLOR_HEX_REGEXP = /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/
  INTEGER_REGEXP = /\A\d+\z/

  acts_as_followable

  before_validation :downcase_slug
  before_validation :check_for_slug_change
  before_validation :evaluate_markdown

  before_save :remove_at_from_usernames
  before_save :generate_secret

  after_save :bust_cache
  after_save :generate_social_images

  after_update_commit :conditionally_update_articles
  after_destroy_commit :bust_cache

  pg_search_scope :search_organizations, against: :name

  has_many :articles, dependent: :nullify
  has_many :collections, dependent: :nullify
  has_many :credits, dependent: :restrict_with_error
  has_many :billboards, class_name: "Billboard", dependent: :destroy
  has_many :listings, dependent: :destroy
  has_many :notifications, dependent: :delete_all
  has_many :organization_memberships, dependent: :delete_all
  has_many :profile_pins, as: :profile, inverse_of: :profile, dependent: :destroy
  has_many :unspent_credits, -> { where spent: false }, class_name: "Credit", inverse_of: :organization
  has_many :users, through: :organization_memberships

  validates :articles_count, presence: true
  validates :bg_color_hex, format: COLOR_HEX_REGEXP, allow_blank: true
  validates :company_size, format: { with: INTEGER_REGEXP, message: :integer_only, allow_blank: true }
  validates :company_size, length: { maximum: 7 }, allow_nil: true
  validates :credits_count, presence: true
  validates :cta_body_markdown, length: { maximum: 256 }
  validates :cta_button_text, length: { maximum: 20 }
  validates :cta_button_url, length: { maximum: 150 }, url: { allow_blank: true, no_local: true }
  validates :github_username, length: { maximum: 50 }
  validates :location, :email, length: { maximum: 64 }
  validates :name, :profile_image, presence: true
  validates :name, length: { maximum: 50 }
  validates :proof, length: { maximum: 1500 }
  validates :secret, length: { is: 100 }, allow_nil: true
  validates :secret, uniqueness: true
  validates :spent_credits_count, presence: true
  validates :summary, length: { maximum: 250 }
  validates :tag_line, length: { maximum: 60 }
  validates :tech_stack, :story, length: { maximum: 640 }
  validates :text_color_hex, format: COLOR_HEX_REGEXP, allow_blank: true
  validates :twitter_username, length: { maximum: 15 }
  validates :unspent_credits_count, presence: true
  validates :url, length: { maximum: 200 }, url: { allow_blank: true, no_local: true }

  unique_across_models :slug, length: { in: 2..30 }

  mount_uploader :profile_image, ProfileImageUploader

  alias_attribute :username, :slug
  alias_attribute :old_username, :old_slug
  alias_attribute :old_old_username, :old_old_slug
  alias_attribute :website_url, :url

  def self.simple_name_match(query)
    scope = order(:name)
    query&.strip!
    return scope if query.blank?

    scope.where("name ILIKE ?", "%#{query}%")
  end

  def self.integer_only
    I18n.t("models.organization.integer_only")
  end

  def self.reserved_word
    I18n.t("models.organization.reserved_word")
  end

  def check_for_slug_change
    return unless slug_changed?

    self.old_old_slug = old_slug
    self.old_slug = slug_was
    Organizations::UpdateOrganizationArticlesPathsWorker.perform_async(id, slug_was, slug)
  end

  def path
    "/#{slug}"
  end

  def generate_secret
    self.secret = generated_random_secret if secret.blank?
  end

  def generated_random_secret
    SecureRandom.hex(50)
  end

  def approved_and_filled_out_cta?
    cta_processed_html?
  end

  def profile_image_90
    profile_image_url_for(length: 90)
  end

  def enough_credits?(num_credits_needed)
    credits.unspent.size >= num_credits_needed
  end

  def destroyable?
    organization_memberships.count == 1 && articles.count.zero? && credits.count.zero?
  end

  def public_articles_count
    articles.published.count
  end

  # NOTE: We use Organization and User objects interchangeably. Since the former
  # don't have profiles we return self instead.
  def profile
    self
  end

  def cached_base_subscriber?
    false
  end

  private

  def generate_social_images
    change = saved_change_to_attribute?(:name) || saved_change_to_attribute?(:profile_image)
    return unless change && articles.published.from_subforem.size.positive?

    Images::SocialImageWorker.perform_async(id, self.class.name)
  end

  def evaluate_markdown
    self.cta_processed_html = MarkdownProcessor::Parser.new(cta_body_markdown).evaluate_limited_markdown
  end

  def remove_at_from_usernames
    self.twitter_username = twitter_username.delete("@") if twitter_username
    self.github_username = github_username.delete("@") if github_username
  end

  def downcase_slug
    self.slug = slug&.downcase
  end

  def conditionally_update_articles
    return unless Article::ATTRIBUTES_CACHED_FOR_RELATED_ENTITY.detect { |attr| saved_change_to_attribute?(attr) }

    article_ids = articles.ids.map { |id| [id] }
    Organizations::SaveArticleWorker.perform_bulk(article_ids)
  end

  def bust_cache
    Organizations::BustCacheWorker.perform_async(id, slug)
  end
end
