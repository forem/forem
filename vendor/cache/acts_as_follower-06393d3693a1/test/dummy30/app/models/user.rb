class User < ApplicationRecord
  validates_presence_of :name
  acts_as_follower
  acts_as_followable
end
