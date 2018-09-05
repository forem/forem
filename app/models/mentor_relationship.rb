class MentorRelationship < ApplicationRecord
  belongs_to :mentor, class_name: "User"
  belongs_to :mentee, class_name: "User"
  validates :mentor, presence: true
  validates :mentee, presence: true
  validate :check_for_same_user
  validates_uniqueness_of :mentor_id, scope: :mentee_id

  def check_for_same_user
    if mentor_id == mentee_id
      errors.add(:mentor_relationship, "Mentor and Mentee cannot be the same person")
    end
  end
end
