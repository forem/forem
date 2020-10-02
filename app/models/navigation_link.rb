class NavigationLink < ApplicationRecord
  SVG_REGEXP = /\A<svg .*>/i.freeze

  validates :name, :url, :icon, presence: true
  validates :url, url: { schemes: %w[https http] }
  validates :icon, format: SVG_REGEXP
  validates :requires_auth, inclusion: { in: [true, false] }
end
