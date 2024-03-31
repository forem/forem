class UserLanguage < ApplicationRecord
  belongs_to :user, inverse_of: :languages

  validates :language, inclusion: { in: Languages::Detection.codes }, presence: true
end
