# @note When we destroy the related article (via pinnable), it's using
#       dependent: :delete for the relationship.  That means no
#       before/after destroy callbacks will be called on this object.
class ProfilePin < ApplicationRecord
  belongs_to :pinnable, polymorphic: true
  belongs_to :profile, polymorphic: true

  validates :profile_id, presence: true
  validates :profile_type, inclusion: { in: %w[User] } # Future could be organization, tag, etc.
  validates :pinnable_id, presence: true, uniqueness: { scope: %i[profile_id profile_type pinnable_type] }
  validates :pinnable_type, inclusion: { in: %w[Article] } # Future could be comments, etc.
  validate :only_five_pins_per_profile, on: :create
  validate :pinnable_belongs_to_profile

  private

  def only_five_pins_per_profile
    errors.add(:base, "cannot have more than five total pinned posts") if profile.profile_pins.size > 4
  end

  def pinnable_belongs_to_profile
    errors.add(:pinnable_id, "must have proper permissions for pin") if pinnable.user_id != profile_id
  end
end
