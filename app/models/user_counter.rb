class UserCounter < ApplicationRecord
  belongs_to :user

  serialize :data, HashSerializer
  store_accessor :data, :comments_7_days

  validates :user, presence: true, uniqueness: true
  validates :comments_7_days, numericality: { only_integer: true }
end
