class DiscussionLock < ApplicationRecord
  belongs_to :article
  belongs_to :locking_user, class_name: "User"

  before_validation :nullify_notes_and_reason

  validates :article_id, presence: true, uniqueness: true
  validates :locking_user_id, presence: true

  private

  def nullify_notes_and_reason
    # Prevent empty strings from beings saved to the DB
    self.notes = nil if notes == ""
    self.reason = nil if reason == ""
  end
end
