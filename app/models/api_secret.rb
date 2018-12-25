class ApiSecret < ApplicationRecord
  DESCRIPTION_MAX_LENGTH = 30

  has_secure_token :secret
  belongs_to :user
  validates :description, presence: true, length: { in: 1..DESCRIPTION_MAX_LENGTH }
end
