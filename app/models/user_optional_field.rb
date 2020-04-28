class UserOptionalField < ApplicationRecord
  belongs_to :user

  validates :label, presence: true, length: { maximum: 30 }, uniqueness: { scope: :user_id }
  validates :value, presence: true, length: { maximum: 128 }
  validate :validate_quota

  def validate_quota
    return unless user

    errors.add(:user_id, "already has the maximum allowable optional fields") unless user.user_optional_fields.count < 3
  end
end
