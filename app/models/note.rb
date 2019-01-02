class Note < ApplicationRecord
  belongs_to :noteable, polymorphic: true, touch: true
  belongs_to :author, class_name: "User", optional: true
  validates :content, presence: true
end
