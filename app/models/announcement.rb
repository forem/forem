class Announcement < ApplicationRecord
  VALID_BANNER_STYLES = %w[default brand success warning error].freeze
  resourcify

  has_one :broadcast, as: :broadcastable

  validates :banner_style, inclusion: { in: VALID_BANNER_STYLES }, allow_blank: true
end
