class LinkedDomain < ApplicationRecord
  has_many :webpage_references, dependent: :destroy

  validates :host, presence: true, uniqueness: true

  def self.find_or_create_by_url(url)
    uri = URI.parse(url)
    return nil unless uri.host

    find_or_create_by(host: uri.host.downcase)
  rescue URI::InvalidURIError
    nil
  end
end
