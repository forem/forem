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
  after_save :bust_caches

  def self.create_from_scratch!(domain:, brain_dump:, name:, logo_url:, bg_image_url: nil, default_locale: 'en')
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
    Rails.cache.fetch("subforem_id_by_domain_#{passed_domain}", expires_in: 12.hours) do
      Subforem.find_by(domain: passed_domain)&.id
    end
  end

  def self.cached_default_id
    Rails.cache.fetch("subforem_default_id", expires_in: 12.hours) do
      Subforem.first&.id
    end
  end

  def self.cached_root_id
    Rails.cache.fetch("subforem_root_id", expires_in: 12.hours) do
      Subforem.find_by(root: true)&.id
    end
  end

  def self.cached_domains
    Rails.cache.fetch("subforem_domains", expires_in: 12.hours) do
      Subforem.pluck(:domain)
    end
  end

  def self.cached_id_to_domain_hash
    Rails.cache.fetch("subforem_id_to_domain_hash", expires_in: 12.hours) do
      Subforem.all.each_with_object({}) do |subforem, hash|
        hash[subforem.id] = subforem.domain
      end
    end
  end

  def self.cached_default_domain
    Rails.cache.fetch("subforem_default_domain", expires_in: 12.hours) do
      Subforem.first&.domain
    end
  end

  def self.cached_root_domain
    Rails.cache.fetch("subforem_root_domain", expires_in: 12.hours) do
      domain = Subforem.find_by(root: true)&.domain
      return unless domain

      domain += ":3000" if Rails.env.development? && !domain.include?(":3000")
      domain
    end
  end

  def self.cached_all_domains
    Rails.cache.fetch("subforem_all_domains", expires_in: 12.hours) do
      Subforem.pluck(:domain)
    end
  end

  def self.cached_discoverable_ids
    Rails.cache.fetch("subforem_discoverable_ids", expires_in: 12.hours) do
      Subforem.where(discoverable: true).order("hotness_score desc").pluck(:id)
    end
  end

  def self.cached_postable_array
    Rails.cache.fetch("subforem_postable_array", expires_in: 12.hours) do
      Subforem.where(discoverable: true).order("hotness_score desc").pluck(:id).map do |id|
        [id, Settings::Community.community_name(subforem_id: id)]
      end
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
    Rails.cache.delete("subforem_id_to_domain_hash")
    Rails.cache.delete("subforem_postable_array")
    Rails.cache.delete("subforem_discoverable_ids")
    Rails.cache.delete("subforem_root_id")
    Rails.cache.delete("subforem_default_domain")
    Rails.cache.delete("subforem_root_domain")
    Rails.cache.delete("subforem_all_domains")
    Rails.cache.delete("subforem_default_id")
    Rails.cache.delete("subforem_id_by_domain_#{domain}")
  end

  def downcase_domain
    self.domain = domain.downcase if domain
  end
end
