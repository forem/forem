class UserCounter < ApplicationRecord
  belongs_to :user

  serialize :data, HashSerializer

  store_accessor :data, :comments_7_days
end
