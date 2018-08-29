class MentorRelationship < ApplicationRecord
  belongs_to :mentor, class_name: "User"
  belongs_to :mentee, class_name: "User"
  validates :mentor, presence: true
  validates :mentee, presence: true
end
