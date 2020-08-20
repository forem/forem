class ListingEndorsement < ApplicationRecord
  self.table_name = "classified_listing_endorsements"

  belongs_to :listing, foreign_key: :classified_listing_id, inverse_of: :endorsements
  belongs_to :user

  validates :user_id, presence: true
  validates :classified_listing_id, presence: true
  validates :content, presence: true
end
