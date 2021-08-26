class NavigationLink < ApplicationRecord
  SVG_REGEXP = /<svg .*>/im

  before_validation :allow_relative_url, if: :url?
  before_save :strip_local_hostname, if: :url?

  enum section: { default: 0, other: 1 }, _suffix: true

  validates :name, :url, :icon, presence: true
  validates :url, url: { schemes: %w[https http] }, uniqueness: { scope: :name }
  validates :icon, format: SVG_REGEXP
  validates :display_only_when_signed_in, inclusion: { in: [true, false] }

  scope :ordered, -> { order(position: :asc, name: :asc) }

  private

  # We want to allow relative URLs (e.g. /contact) for navigation links while
  # still going through the normal validation process.
  def allow_relative_url
    parsed_url = URI.parse(url)
    return unless parsed_url.relative? && url.starts_with?("/")

    self.url = URI.parse(URL.url).merge(parsed_url).to_s
  end

  # When persisting to the database we store local links as relative URLs which
  # makes it easier to switch from a forem.cloud subdomain to the live domain.
  def strip_local_hostname
    parsed_url = URI.parse(url)
    return unless url.match?(/^#{URL.url}/i)

    self.url = parsed_url.path
  end
end
