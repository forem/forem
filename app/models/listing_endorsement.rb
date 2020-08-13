class ListingEndorsement < ApplicationRecord
  before_save :default_approved

  belongs_to :listing, foreign_key: :classified_listing_id, inverse_of: :listing_endorsements
  belongs_to :user

  validates :user_id, presence: true
  validates :classified_listing_id, presence: true

  validates :content, presence: true, length: { maximum: 255 }

  def author_profile_image_90
    ProfileImage.new(user).get(width: 90)
  end

  private

  def default_approved
    self.approved ||= false
  end
end
