class LinkedDomain < ApplicationRecord
  has_many :webpage_references, dependent: :destroy

  validates :host, presence: true, uniqueness: true

  def self.find_or_create_by_url(url)
    uri = URI.parse(url)
    host = uri.host&.downcase
    return nil unless host

    find_or_create_by(host: host)
  rescue URI::InvalidURIError
    nil
  rescue ActiveRecord::RecordNotUnique
    find_by(host: host)
  end
end
