class TagSubforemRelationship < ApplicationRecord
  belongs_to :tag
  belongs_to :subforem

  validates :tag_id, presence: true, uniqueness: { scope: :subforem_id }
  validates :subforem_id, presence: true, uniqueness: { scope: :tag_id }
end
