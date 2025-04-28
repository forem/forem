class TagSubforemRelationship < ApplicationRecord
  belongs_to :tag
  belongs_to :subforem

  validates :tag_id, presence: true
  validates :subforem_id, presence: true
end
