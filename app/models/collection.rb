class Collection < ApplicationRecord
  has_many :articles
  belongs_to :user, optional: true
  belongs_to :organization, optional: true
end
