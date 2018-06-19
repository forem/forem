class Note < ApplicationRecord
  belongs_to :noteable, polymorphic: true
  validates :reason, :content, presence: true
  validates :noteable_id, uniqueness:
    { scope: :reason, message: "limited to one note per noteable per reason" }
end
