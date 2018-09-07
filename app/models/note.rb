class Note < ApplicationRecord
  belongs_to :noteable, polymorphic: true
  belongs_to :author, class_name: "User", optional: true
  validates :reason, :content, presence: true
end
