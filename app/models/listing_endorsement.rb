class ListingEndorsement < ApplicationRecord
  belongs_to :listing
  belongs_to :user
end
