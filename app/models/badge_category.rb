class BadgeCategory < ApplicationRecord
  DEFAULT_CATEGORY_NAME = "Badges".freeze

  has_many :badges, dependent: :restrict_with_error

  validates :name, :description, presence: true
  validates :name, uniqueness: true
end
