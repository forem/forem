class BanishedUser < ApplicationRecord
  before_validation ->(user) { user.username = user.username.downcase }

  validates :username, uniqueness: true, on: :create
end
