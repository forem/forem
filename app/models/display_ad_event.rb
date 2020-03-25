class DisplayAdEvent < ApplicationRecord
  belongs_to :display_ad
  belongs_to :user

  validates :category, inclusion: { in: %w[impression click] }
  validates :context_type, inclusion: { in: %w[home] }
end
