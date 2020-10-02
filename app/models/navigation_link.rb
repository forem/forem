class NavigationLink < ApplicationRecord
  SVG_REGEXP = /<svg .*>/i.freeze

  validates :name, :url, :icon, presence: true
  validates :url, url: { schemes: %w[https http] }
  validates :icon, format: SVG_REGEXP
  validates :display_when_signed_in, inclusion: { in: [true, false] }
end
