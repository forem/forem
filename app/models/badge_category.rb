class BadgeCategory < ApplicationRecord
  has_many :badges, dependent: :restrict_with_error

  validates :name, :description, presence: true
  validates :name, uniqueness: true
end
