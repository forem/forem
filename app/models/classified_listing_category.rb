class ClassifiedListingCategory < ApplicationRecord
  has_many :listings, class_name: "ClassifiedListing", inverse_of: :category

  validates :name, :cost, :rules, :slug, presence: true
  validates :name, :slug, uniqueness: true
end
