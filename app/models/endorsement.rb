class Endorsement < ApplicationRecord
  belongs_to :user
  belongs_to :classified_listing, inverse_of: :endorsements

  delegate :name, to: :user
  delegate :username, to: :user
  delegate :profile_image_35, to: :user
  validate :validate_user_self_endorsing, on: :create
  validate :validate_user_repeat_endorsing, on: :create

  private

  def validate_user_self_endorsing
    user_is_endorsing_own_listing = classified_listing.user_id == user.id
    errors.add(:user, "cannot endorse own listing") if user_is_endorsing_own_listing
  end

  def validate_user_repeat_endorsing
    user_has_already_endorsed = Endorsement.exists?(classified_listing_id: classified_listing.id, user_id: user.id, deleted: false)
    errors.add(:user, "cannot endorse listing more than once") if user_has_already_endorsed
  end
end
