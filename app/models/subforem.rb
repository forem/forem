class Subforem < ApplicationRecord
  acts_as_followable
  resourcify

  has_many :articles, dependent: :nullify
  has_many :navigation_links, dependent: :nullify
  has_many :pages, dependent: :nullify
  has_many :tag_relationships, class_name: "TagSubforemRelationship", dependent: :destroy

  validates :domain, presence: true, uniqueness: true

  # Only one total subforem can be the root
  validates :root, uniqueness: { message: "Only one subforem can be the root" }, if: :root

  # Virtual attributes for form
  attr_accessor :name, :brain_dump, :logo_url, :bg_image_url, :default_locale

  before_validation :downcase_domain
  after_destroy :bust_caches
  after_save :bust_caches

  def self.create_from_scratch!(domain:, brain_dump:, name:, logo_url:, bg_image_url: nil, default_locale: "en")
    subforem = Subforem.create!(domain: domain)

    # Queue background job for AI services
    Subforems::CreateFromScratchWorker.perform_async(
      subforem.id,
      brain_dump,
      name,
      logo_url,
      bg_image_url,
      default_locale,
    )

    subforem
  end

  def self.cached_id_by_domain(passed_domain)
    # A domain containing a null byte can never match a subforem, and Postgres rejects it.
    return if passed_domain.to_s.include?("\0")
    return if cached_default_id.nil?

    # Unknown domains cache "" (read back as nil by return_type: :integer) because
    # MemoryFirstCache treats a cached nil as a miss and would hit the DB every request.
    MemoryFirstCache.fetch("subforem_id_by_domain_#{passed_domain}",
                           redis_expires_in: 12.hours,
                           return_type: :integer) do
      Subforem.find_by(domain: passed_domain)&.id || ""
    end
  end

  def self.cached_default_id
    MemoryFirstCache.fetch("subforem_default_id", redis_expires_in: 12.hours, return_type: :integer) do
      Subforem.first&.id || ""
    end
  end

  def self.cached_root_id
    return if cached_default_id.nil?

    MemoryFirstCache.fetch("subforem_root_id", redis_expires_in: 12.hours, return_type: :integer) do
      Subforem.find_by(root: true)&.id || ""
    end
  end

  def self.cached_domains
    return [] if cached_default_id.nil?
    return [cached_default_domain].compact if disabled_by_env?

    result = MemoryFirstCache.fetch("subforem_domains", redis_expires_in: 12.hours) do
      Subforem.pluck(:domain)
    end
    # Ensure we always return an array (cache may serialize to string in some environments)
    result.is_a?(Array) ? result : []
  end

  def self.cached_id_to_domain_hash
    default_id = cached_default_id
    return {} if default_id.nil?

    if disabled_by_env?
      default_domain = cached_default_domain
      return default_domain ? { default_id => default_domain } : {}
    end

    result = MemoryFirstCache.fetch("subforem_id_to_domain_hash", redis_expires_in: 12.hours) do
      Subforem.all.each_with_object({}) do |subforem, hash|
        hash[subforem.id] = subforem.domain
      end
    end
    # Ensure we always return a hash (cache may serialize to string in some environments)
    result.is_a?(Hash) ? result : {}
  end

  def self.cached_default_domain
    return if cached_default_id.nil?

    MemoryFirstCache.fetch("subforem_default_domain", redis_expires_in: 12.hours, return_type: :string) do
      Subforem.first&.domain || ""
    end.presence
  end

  def self.cached_root_domain
    return if cached_default_id.nil?

    MemoryFirstCache.fetch("subforem_root_domain", redis_expires_in: 12.hours, return_type: :string) do
      domain = Subforem.find_by(root: true)&.domain
      if domain
        domain += ":#{URL.dev_port}" if Rails.env.development? && domain.exclude?(":#{URL.dev_port}")
        domain
      else
        ""
      end
    end.presence
  end

  def self.cached_all_domains
    return [] if cached_default_id.nil?
    return [cached_default_domain].compact if disabled_by_env?

    result = MemoryFirstCache.fetch("subforem_all_domains", redis_expires_in: 12.hours) do
      Subforem.pluck(:domain)
    end
    # Ensure we always return an array (cache may serialize to string in some environments)
    result.is_a?(Array) ? result : []
  end

  def self.disabled_by_env?
    ENV["SKIP_SUBFOREM_REASSIGNMENT"] == "yes" ||
      ENV["REDIRECT_ALL_SUBFOREMS_TO_DEFAULT"] == "true" ||
      ENV["NO_SUBFOREM_FILTER"] == "true"
  end

  def self.multiple_subforems_enabled?
    !disabled_by_env? && cached_discoverable_ids.size > 1
  end

  def self.cached_discoverable_ids
    default_id = cached_default_id
    return [] if default_id.nil?
    return [default_id] if disabled_by_env?

    result = MemoryFirstCache.fetch("subforem_discoverable_ids", redis_expires_in: 12.hours) do
      Subforem.where(discoverable: true).order("hotness_score desc").ids
    end
    # Ensure we always return an array (cache may serialize to string in some environments)
    result.is_a?(Array) ? result : []
  end

  def self.cached_postable_array
    default_id = cached_default_id
    return [] if default_id.nil?
    return [[default_id, Settings::Community.community_name(subforem_id: default_id)]] if disabled_by_env?

    result = MemoryFirstCache.fetch("subforem_postable_array", redis_expires_in: 12.hours) do
      Subforem.where(discoverable: true).order("hotness_score desc").ids.map do |id|
        [id, Settings::Community.community_name(subforem_id: id)]
      end
    end
    # Ensure we always return an array (cache may serialize to string in some environments)
    result.is_a?(Array) ? result : []
  end

  def self.cached_misc_subforem_id
    return if disabled_by_env? || cached_default_id.nil?

    MemoryFirstCache.fetch("subforem_misc_id", redis_expires_in: 12.hours, return_type: :integer) do
      Subforem.find_by(misc: true)&.id || ""
    end
  end

  def self.misc_subforem
    return if disabled_by_env? || cached_misc_subforem_id.nil?

    Rails.cache.fetch("subforem_misc_object", expires_in: 12.hours) do
      Subforem.find_by(misc: true)
    end
  end

  def data_info_to_json
    DataInfo.to_json(object: self, class_name: "Subforem", id: id, style: "full")
  end

  def name
    Settings::Community.community_name(subforem_id: id)
  end

  def subforem_moderator_ids
    User.with_role(:subforem_moderator, self).order(id: :asc).ids
  end

  def update_scores!
    super_duper_recent = articles.published.where("published_at > ?", 3.days.ago).where("score > 0").sum(:score)
    super_recent = articles.published.where("published_at > ?", 2.weeks.ago).where("score > 0").sum(:score)
    somewhat_recent = articles.published.where("published_at > ?", 6.months.ago).where("score > 0").sum(:score)
    self.score = somewhat_recent + (super_recent * 0.1)
    self.hotness_score = super_duper_recent + super_recent + (somewhat_recent * 0.1)
    save
  end

  private

  def bust_caches
    Rails.cache.delete("cached_domains")
    MemoryFirstCache.delete("subforem_domains")
    MemoryFirstCache.delete("subforem_id_to_domain_hash")
    MemoryFirstCache.delete("subforem_postable_array")
    MemoryFirstCache.delete("subforem_discoverable_ids")
    MemoryFirstCache.delete("subforem_root_id")
    MemoryFirstCache.delete("subforem_default_domain")
    MemoryFirstCache.delete("subforem_root_domain")
    MemoryFirstCache.delete("subforem_all_domains")
    MemoryFirstCache.delete("subforem_default_id")
    MemoryFirstCache.delete("subforem_id_by_domain_#{domain}")
    MemoryFirstCache.delete("subforem_id_by_domain_#{domain_before_last_save}") if domain_before_last_save.present?
    MemoryFirstCache.delete("subforem_misc_id")
    Rails.cache.delete("subforem_misc_object")
  end

  def downcase_domain
    self.domain = domain.downcase if domain
  end
end
