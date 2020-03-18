class UserCounter < ApplicationRecord
  belongs_to :user

  serialize :data, HashSerializer
  store_accessor :data, :comments_these_7_days, :comments_prior_7_days

  validates :user, presence: true, uniqueness: true

  validates :comments_these_7_days, numericality: { only_integer: true }
  validates :comments_prior_7_days, numericality: { only_integer: true }
end
