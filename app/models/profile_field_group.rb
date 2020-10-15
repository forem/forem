class ProfileFieldGroup < ApplicationRecord
  has_many :profile_fields, dependent: :nullify

  validates :name, presence: true, uniqueness: true

  scope :onboarding, lambda {
    includes(:profile_fields).where(profile_fields: { show_in_onboarding: true })
  }
end
