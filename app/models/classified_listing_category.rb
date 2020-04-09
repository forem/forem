class ClassifiedListingCategory < ApplicationRecord
  has_many :classified_listings

  validates :name, :cost, :rules, presence: true
  validates :name, uniqueness: true
end
