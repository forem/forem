class Note < ApplicationRecord
  belongs_to :noteable, polymorphic: true
  validates :reason, :content, presence: true
end
