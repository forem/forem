class NavigationLink < ApplicationRecord
  SVG_REGEXP = /<svg .*>/i.freeze

  validates :name, :url, :icon, presence: true
  validates :url, url: { schemes: %w[https http] }, uniqueness: { scope: :name }
  validates :icon, format: SVG_REGEXP
  validates :display_only_when_signed_in, inclusion: { in: [true, false] }

  scope :ordered, -> { order(position: :asc, name: :asc) }
end
