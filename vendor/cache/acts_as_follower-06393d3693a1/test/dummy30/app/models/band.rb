class Band < ApplicationRecord
  validates_presence_of :name
  acts_as_followable
end
