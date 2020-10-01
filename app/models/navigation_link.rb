class NavigationLink < ApplicationRecord
  URI_REGEXP = URI::DEFAULT_PARSER.make_regexp(%w[http https]).freeze
  SVG_REGEXP = /\A<svg .*>/i.freeze

  validates :name, :url, :icon, presence: true
  validates :url, format: URI_REGEXP
  validates :icon, format: SVG_REGEXP
end
