class Device < ApplicationRecord
  belongs_to :user

  validates :token, uniqueness: { scope: %i[user_id platform] }
end
