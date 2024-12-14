class Subforem < ApplicationRecord
  has_many :articles, dependent: :nullify

  validates :domain, presence: true, uniqueness: true

  def self.cached_id_by_domain(passed_domain)
    Rails.cache.fetch("subforem_id_by_domain_#{passed_domain}", expires_in: 12.hours) do
      Subforem.find_by(domain: passed_domain)&.id
    end
  end

  def self.cached_default_id
    Rails.cache.fetch('subforem_default_id', expires_in: 12.hours) do
      Subforem.first&.id.to_i
    end
  end
end
