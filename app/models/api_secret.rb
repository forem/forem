class ApiSecret < ApplicationRecord
  has_secure_token :secret
  belongs_to :user
end
