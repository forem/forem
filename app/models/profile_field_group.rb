class ProfileFieldGroup < ApplicationRecord
  has_many :profile_fields, dependent: :nullify

  validates :name, presence: true, uniqueness: true
end
