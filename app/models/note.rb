#  @note When we destroy the related user, it's using dependent:
#        :delete for the relationship.  That means no before/after
#        destroy callbacks will be called on this object.
class Note < ApplicationRecord
  belongs_to :author, class_name: "User", optional: true
  belongs_to :noteable, polymorphic: true, touch: true

  validates :content, :reason, presence: true
end
