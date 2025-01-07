class Subforem < ApplicationRecord
  has_many :articles, dependent: :nullify
  has_many :navigation_links, dependent: :nullify
  has_many :pages, dependent: :nullify

  validates :domain, presence: true, uniqueness: true

  after_save :bust_caches

  def self.cached_id_by_domain(passed_domain)
    Rails.cache.fetch("subforem_id_by_domain_#{passed_domain}", expires_in: 12.hours) do
      Subforem.find_by(domain: passed_domain)&.id
    end
  end

  def self.cached_default_id
    Rails.cache.fetch('subforem_default_id', expires_in: 12.hours) do
      Subforem.first&.id
    end
  end

  def self.cached_root_id
    Rails.cache.fetch('subforem_root_id', expires_in: 12.hours) do
      Subforem.find_by(root: true)&.id
    end
  end

  def self.cached_domains
    Rails.cache.fetch('subforem_domains', expires_in: 12.hours) do
      Subforem.pluck(:domain)
    end
  end

  def self.cached_default_domain
    Rails.cache.fetch('subforem_default_domain', expires_in: 12.hours) do
      Subforem.first&.domain
    end
  end

  def self.cached_root_domain
    Rails.cache.fetch('subforem_root_domain', expires_in: 12.hours) do
      domain = Subforem.find_by(root: true)&.domain
      domain += ":3000" if Rails.env.development? && !domain.include?(":3000")
      domain
    end
  end

  def self.cached_all_domains
    Rails.cache.fetch('subforem_all_domains', expires_in: 12.hours) do
      Subforem.pluck(:domain)
    end
  end

  private

  def bust_caches
    Rails.cache.delete("cached_domains")
    Rails.cache.delete('subforem_root_id')
    Rails.cache.delete('subforem_default_domain')
    Rails.cache.delete('subforem_root_domain')
    Rails.cache.delete('subforem_all_domains')
    Rails.cache.delete('subforem_default_id')
    Rails.cache.delete("subforem_id_by_domain_#{domain}")
  end
end
