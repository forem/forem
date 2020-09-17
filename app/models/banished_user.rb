class BanishedUser < ApplicationRecord
  belongs_to :banished_by, class_name: "User", optional: true

  before_validation ->(user) { user.username = user.username&.downcase }

  validates :username, uniqueness: true, on: :create
end
