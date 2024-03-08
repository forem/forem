#  @note When we destroy the related user, it's using dependent:
#        :delete for the relationship.  That means no before/after
#        destroy callbacks will be called on this object.
class Note < ApplicationRecord
  belongs_to :author, class_name: "User", optional: true
  belongs_to :noteable, polymorphic: true, touch: true

  validates :content, :reason, presence: true

  def self.find_for_reports(feedback_message_ids)
    includes(:author).where(noteable_id: feedback_message_ids).order(:created_at)
  end
end
