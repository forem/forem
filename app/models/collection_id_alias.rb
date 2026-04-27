class CollectionIdAlias < ApplicationRecord
  belongs_to :collection

  validates :legacy_collection_id, presence: true, uniqueness: true
  validates :collection, presence: true
end