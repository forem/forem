class Note < ApplicationRecord
  belongs_to :author, class_name: "User", optional: true
  belongs_to :noteable, polymorphic: true, touch: true

  validates :content, :reason, presence: true
end
