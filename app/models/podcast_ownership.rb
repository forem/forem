#  @note When we destroy the related user, it's using dependent:
#        :delete for the relationship.  That means no before/after
#        destroy callbacks will be called on this object.
class PodcastOwnership < ApplicationRecord
  belongs_to :owner, class_name: "User", foreign_key: :user_id, inverse_of: :podcasts_owned
  belongs_to :podcast

  validates :podcast_id, uniqueness: { scope: :user_id }
  validates :podcast_id, :user_id, presence: true
end
