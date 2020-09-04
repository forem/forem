class CustomProfileField < ApplicationRecord
  include ActsAsProfileField

  belongs_to :profile

  validate :validate_maximum_count

  private

  # We allow a maximum of 3 custom profile fields per user
  def validate_maximum_count
    return if profile.custom_profile_fields.count < 3

    errors.add(:profile_id, "maximum number of custom profile fields exceeded")
  end
end
