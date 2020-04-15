class ClassifiedListingCategory < ApplicationRecord
  has_many :classified_listings

  validates :name, :cost, :rules, :slug, presence: true
  validates :name, :slug, uniqueness: true
end
